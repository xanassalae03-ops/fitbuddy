<?php
error_reporting(E_ALL);
ini_set('display_errors', '0');
ini_set('log_errors', '1');
date_default_timezone_set('Asia/Bangkok');
mysqli_report(MYSQLI_REPORT_ERROR | MYSQLI_REPORT_STRICT);

$config = require __DIR__ . '/config.php';

header('Content-Type: application/json; charset=UTF-8');
header('Cache-Control: no-store');
header('Access-Control-Allow-Origin: ' . $config['allowed_origin']);
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if (($_SERVER['REQUEST_METHOD'] ?? '') === 'OPTIONS') {
    http_response_code(204);
    exit;
}

if (stripos($_SERVER['CONTENT_TYPE'] ?? '', 'application/json') === 0) {
    $jsonBody = json_decode(file_get_contents('php://input'), true);
    if (is_array($jsonBody)) {
        $_POST = $jsonBody + $_POST;
    }
}

class ApiException extends Exception {
    public $status;
    public function __construct($message, $status = 400) {
        parent::__construct($message);
        $this->status = $status;
    }
}

function fail($message, $status = 400) {
    throw new ApiException($message, $status);
}

function respond($payload, $status = 200) {
    http_response_code($status);
    echo json_encode($payload, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    exit;
}

function requireMethod($method) {
    if (($_SERVER['REQUEST_METHOD'] ?? '') !== $method) {
        fail('Method not allowed', 405);
    }
}

function postStr($key, $trim = true) {
    $value = $_POST[$key] ?? '';
    if (!is_scalar($value)) return '';
    $value = (string)$value;
    return $trim ? trim($value) : $value;
}

function validDate($s) {
    $d = DateTime::createFromFormat('Y-m-d', $s);
    return $d && $d->format('Y-m-d') === $s;
}

function normalizeTime($s) {
    if (preg_match('/^([01]\d|2[0-3]):([0-5]\d)(:([0-5]\d))?$/', $s, $m)) {
        return $m[1] . ':' . $m[2] . ':' . ($m[4] ?? '00');
    }
    return null;
}

function withTransaction($conn, $fn) {
    $conn->begin_transaction();
    try {
        $result = $fn();
        $conn->commit();
        return $result;
    } catch (Throwable $e) {
        $conn->rollback();
        throw $e;
    }
}

function userExists($conn, $userId) {
    $stmt = $conn->prepare("SELECT id FROM users WHERE id = ? LIMIT 1");
    $stmt->bind_param('i', $userId);
    $stmt->execute();
    return $stmt->get_result()->num_rows > 0;
}

function isApprovedParticipant($conn, $eventId, $userId) {
    $stmt = $conn->prepare("
        SELECT 1 FROM event_participants
        WHERE event_id = ? AND user_id = ? AND status = 'APPROVED'
        LIMIT 1
    ");
    $stmt->bind_param('ii', $eventId, $userId);
    $stmt->execute();
    return $stmt->get_result()->num_rows > 0;
}

function handleLogin($conn) {
    requireMethod('POST');
    $email = strtolower(postStr('email'));
    $password = postStr('password', false);

    if ($email === '' || $password === '') {
        fail('กรุณากรอก Email และ Password');
    }

    $stmt = $conn->prepare("
        SELECT id, email, password_hash, full_name, nickname, phone_number,
               bio, avatar_url, role, trust_score, total_completed_events,
               is_verified, pdpa_consent
        FROM users WHERE email = ? LIMIT 1
    ");
    $stmt->bind_param('s', $email);
    $stmt->execute();
    $user = $stmt->get_result()->fetch_assoc();

    $dummyHash = '$2y$10$' . str_repeat('a', 21) . 'u' . str_repeat('a', 31);
    $hash = $user ? $user['password_hash'] : $dummyHash;
    $passwordOk = password_verify($password, $hash);

    if (!$user || !$passwordOk) {
        fail('อีเมลหรือรหัสผ่านไม่ถูกต้อง', 401);
    }

    unset($user['password_hash']);
    respond(['success' => true, 'message' => 'เข้าสู่ระบบสำเร็จ', 'data' => $user]);
}

function handleRegister($conn) {
    requireMethod('POST');
    $fullName = postStr('full_name');
    $nickname = postStr('nickname');
    $phone = preg_replace('/[\s-]/', '', postStr('phone_number'));
    $email = strtolower(postStr('email'));
    $password = postStr('password', false);
    $consent = in_array(strtolower(postStr('pdpa_consent')), ['1', 'true', 'yes'], true);

    if ($fullName === '' || $nickname === '' || $phone === '' || $email === '' || $password === '') {
        fail('กรุณากรอกข้อมูลให้ครบ');
    }
    if (!$consent) {
        fail('กรุณายอมรับนโยบายข้อมูลส่วนบุคคล (PDPA) ก่อนสมัครสมาชิก');
    }

    $passwordHash = password_hash($password, PASSWORD_DEFAULT);
    $stmt = $conn->prepare("
        INSERT INTO users (email, password_hash, full_name, nickname, phone_number, role, pdpa_consent)
        VALUES (?, ?, ?, ?, ?, 'USER', 1)
    ");
    $stmt->bind_param('sssss', $email, $passwordHash, $fullName, $nickname, $phone);
    $stmt->execute();

    respond(['success' => true, 'message' => 'สมัครสมาชิกสำเร็จ', 'user_id' => $stmt->insert_id], 201);
}

function handleGetCategories($conn) {
    $result = $conn->query("
        SELECT sc.id, sc.name_th, sc.name_en, sc.icon_name,
               CAST(COUNT(e.id) AS UNSIGNED) AS event_count
        FROM sports_categories sc
        LEFT JOIN events e ON e.sport_id = sc.id AND e.status = 'UPCOMING'
        WHERE sc.is_active = 1
        GROUP BY sc.id, sc.name_th, sc.name_en, sc.icon_name
        ORDER BY sc.display_order ASC
    ");
    $data = [];
    while ($row = $result->fetch_assoc()) {
        $data[] = [
            'id' => (int)$row['id'],
            'name_th' => $row['name_th'],
            'name_en' => $row['name_en'],
            'icon_name' => $row['icon_name'],
            'event_count' => (int)$row['event_count'],
        ];
    }
    respond(['success' => true, 'data' => $data]);
}

function handleGetEvents($conn) {
    $sportId = (int)($_GET['sport_id'] ?? 0);
    $sql = "
        SELECT e.id, e.title, e.description, e.location_name, e.latitude, e.longitude,
               e.event_date, e.start_time, e.end_time, e.max_participants,
               e.current_participants, e.cost_type, e.cost_amount, e.status,
               e.banner_image_url, sc.name_th AS sport_name_th,
               u.id AS host_id, u.full_name AS host_name, u.nickname AS host_nickname,
               u.avatar_url AS host_avatar, u.trust_score AS host_trust_score
        FROM events e
        INNER JOIN sports_categories sc ON e.sport_id = sc.id
        INNER JOIN users u ON e.host_id = u.id
        WHERE 1=1
    ";
    if ($sportId > 0) $sql .= " AND e.sport_id = ?";
    $sql .= " ORDER BY e.event_date ASC, e.start_time ASC";

    $stmt = $conn->prepare($sql);
    if ($sportId > 0) $stmt->bind_param('i', $sportId);
    $stmt->execute();
    $result = $stmt->get_result();

    $data = [];
    while ($row = $result->fetch_assoc()) {
        $data[] = [
            'id' => (int)$row['id'],
            'title' => $row['title'],
            'description' => $row['description'],
            'location_name' => $row['location_name'],
            'latitude' => (float)$row['latitude'],
            'longitude' => (float)$row['longitude'],
            'event_date' => $row['event_date'],
            'start_time' => substr($row['start_time'], 0, 5),
            'end_time' => substr((string)$row['end_time'], 0, 5),
            'max_participants' => (int)$row['max_participants'],
            'current_participants' => (int)$row['current_participants'],
            'cost_type' => $row['cost_type'],
            'cost_amount' => (float)$row['cost_amount'],
            'status' => $row['status'],
            'banner_image_url' => $row['banner_image_url'],
            'sport_name' => $row['sport_name_th'],
            'host' => [
                'id' => (int)$row['host_id'],
                'name' => $row['host_name'],
                'nickname' => $row['host_nickname'],
                'avatar' => $row['host_avatar'],
                'trust_score' => (float)$row['host_trust_score'],
            ],
        ];
    }
    respond(['success' => true, 'data' => $data]);
}

function handleGetMyEvents($conn) {
    $userId = (int)($_GET['user_id'] ?? 0);
    if ($userId <= 0) fail('ต้องระบุ User ID');

    $stmt = $conn->prepare("
        SELECT e.id, e.title, e.description, e.location_name, e.latitude, e.longitude,
               e.event_date, e.start_time, e.end_time, e.max_participants,
               e.current_participants, e.cost_type, e.cost_amount, e.status,
               e.banner_image_url, p.participant_role, sc.name_th AS sport_name_th,
               u.id AS host_id, u.full_name AS host_name, u.nickname AS host_nickname,
               u.avatar_url AS host_avatar, u.trust_score AS host_trust_score
        FROM event_participants p
        INNER JOIN events e ON p.event_id = e.id
        INNER JOIN sports_categories sc ON e.sport_id = sc.id
        INNER JOIN users u ON e.host_id = u.id
        WHERE p.user_id = ? AND p.status = 'APPROVED'
        ORDER BY e.event_date ASC, e.start_time ASC
    ");
    $stmt->bind_param('i', $userId);
    $stmt->execute();
    $result = $stmt->get_result();

    $data = [];
    while ($row = $result->fetch_assoc()) {
        $data[] = [
            'id' => (int)$row['id'],
            'title' => $row['title'],
            'description' => $row['description'],
            'location_name' => $row['location_name'],
            'latitude' => (float)$row['latitude'],
            'longitude' => (float)$row['longitude'],
            'event_date' => $row['event_date'],
            'start_time' => substr($row['start_time'], 0, 5),
            'end_time' => substr((string)$row['end_time'], 0, 5),
            'max_participants' => (int)$row['max_participants'],
            'current_participants' => (int)$row['current_participants'],
            'cost_type' => $row['cost_type'],
            'cost_amount' => (float)$row['cost_amount'],
            'status' => $row['status'],
            'banner_image_url' => $row['banner_image_url'],
            'sport_name' => $row['sport_name_th'],
            'participant_role' => $row['participant_role'],
            'host' => [
                'id' => (int)$row['host_id'],
                'name' => $row['host_name'],
                'nickname' => $row['host_nickname'],
                'avatar' => $row['host_avatar'],
                'trust_score' => (float)$row['host_trust_score'],
            ],
        ];
    }
    respond(['success' => true, 'data' => $data]);
}

function handleGetEventDetail($conn) {
    $id = (int)($_GET['id'] ?? 0);
    $userId = (int)($_GET['user_id'] ?? 0);
    if ($id <= 0) fail('ต้องระบุ Event ID');

    $stmt = $conn->prepare("
        SELECT e.*, s.name_th AS sport_name,
               u.full_name AS host_name, u.nickname AS host_nickname,
               u.avatar_url AS host_avatar, u.trust_score AS host_trust_score
        FROM events e
        INNER JOIN sports_categories s ON e.sport_id = s.id
        INNER JOIN users u ON e.host_id = u.id
        WHERE e.id = ?
    ");
    $stmt->bind_param('i', $id);
    $stmt->execute();
    $event = $stmt->get_result()->fetch_assoc();
    if (!$event) fail('ไม่พบกิจกรรมนี้', 404);

    $stmtPart = $conn->prepare("
        SELECT p.participant_role, p.ticket_code,
               u.id AS user_id, u.full_name, u.nickname, u.avatar_url
        FROM event_participants p
        INNER JOIN users u ON p.user_id = u.id
        WHERE p.event_id = ? AND p.status = 'APPROVED'
    ");
    $stmtPart->bind_param('i', $id);
    $stmtPart->execute();
    $partRes = $stmtPart->get_result();

    $participants = [];
    $event['my_ticket_code'] = null;

    while ($p = $partRes->fetch_assoc()) {
        if ($userId > 0 && (int)$p['user_id'] === $userId) {
            $event['my_ticket_code'] = $p['ticket_code'];
        }
        $participants[] = [
            'user_id' => (int)$p['user_id'],
            'name' => $p['full_name'],
            'nickname' => $p['nickname'],
            'avatar' => $p['avatar_url'],
            'participant_role' => $p['participant_role'],
        ];
    }
    $event['participants'] = $participants;
    respond(['success' => true, 'data' => $event]);
}

function handleCreateEvent($conn) {
    requireMethod('POST');
    $hostId = (int)postStr('host_id');
    $sportId = (int)postStr('sport_id');
    $title = postStr('title');
    $description = postStr('description');
    $locationName = postStr('location_name');
    $latitude = is_numeric(postStr('latitude')) ? (float)postStr('latitude') : 13.736717;
    $longitude = is_numeric(postStr('longitude')) ? (float)postStr('longitude') : 100.523186;
    $eventDate = postStr('event_date');
    $startTime = normalizeTime(postStr('start_time'));
    $endTime = normalizeTime(postStr('end_time'));
    $maxParticipants = (int)(postStr('max_participants') !== '' ? postStr('max_participants') : 8);
    $costType = strtoupper(postStr('cost_type') !== '' ? postStr('cost_type') : 'FREE');
    $costAmount = is_numeric(postStr('cost_amount')) ? (float)postStr('cost_amount') : 0.0;

    $newEventId = withTransaction($conn, function () use (
        $conn, $hostId, $sportId, $title, $description, $locationName, $latitude,
        $longitude, $eventDate, $startTime, $endTime, $maxParticipants, $costType, $costAmount
    ) {
        $stmt = $conn->prepare("
            INSERT INTO events (
                host_id, sport_id, title, description, location_name,
                latitude, longitude, event_date, start_time, end_time,
                max_participants, current_participants, cost_type, cost_amount, status
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 1, ?, ?, 'UPCOMING')
        ");
        $stmt->bind_param('iisssddsssisd', $hostId, $sportId, $title, $description, $locationName, $latitude, $longitude, $eventDate, $startTime, $endTime, $maxParticipants, $costType, $costAmount);
        $stmt->execute();
        $eventId = $stmt->insert_id;

        $ticketCode = '#HOST-' . strtoupper(bin2hex(random_bytes(4)));
        $stmtHost = $conn->prepare("
            INSERT INTO event_participants (event_id, user_id, participant_role, status, ticket_code)
            VALUES (?, ?, 'HOST', 'APPROVED', ?)
        ");
        $stmtHost->bind_param('iis', $eventId, $hostId, $ticketCode);
        $stmtHost->execute();

        return $eventId;
    });

    respond(['success' => true, 'message' => 'สร้างกิจกรรมสำเร็จ', 'event_id' => $newEventId], 201);
}

function handleGetChatMessages($conn) {
    $eventId = (int)($_GET['event_id'] ?? 0);
    $afterId = (int)($_GET['after_id'] ?? 0);

    $stmt = $conn->prepare("
        SELECT c.id, c.sender_id, c.message_type, c.content,
               c.latitude AS lat, c.longitude AS lng, c.created_at,
               u.full_name AS sender_name, u.nickname AS sender_nickname,
               u.avatar_url AS sender_avatar
        FROM chat_messages c
        INNER JOIN users u ON c.sender_id = u.id
        WHERE c.event_id = ? AND c.id > ?
        ORDER BY c.id ASC LIMIT 500
    ");
    $stmt->bind_param('ii', $eventId, $afterId);
    $stmt->execute();
    $result = $stmt->get_result();

    $messages = [];
    while ($row = $result->fetch_assoc()) {
        $messages[] = [
            'id' => (int)$row['id'],
            'sender_id' => (int)$row['sender_id'],
            'sender_name' => $row['sender_nickname'] ?: $row['sender_name'],
            'avatar' => $row['sender_avatar'],
            'message_type' => $row['message_type'],
            'content' => $row['content'],
            'lat' => $row['lat'] !== null ? (float)$row['lat'] : null,
            'lng' => $row['lng'] !== null ? (float)$row['lng'] : null,
            'created_at' => $row['created_at'],
        ];
    }
    respond(['success' => true, 'data' => $messages]);
}

function handleSendMessage($conn) {
    requireMethod('POST');
    $eventId = (int)postStr('event_id');
    $senderId = (int)postStr('sender_id');
    $content = postStr('content');

    $stmt = $conn->prepare("
        INSERT INTO chat_messages (event_id, sender_id, message_type, content)
        VALUES (?, ?, 'TEXT', ?)
    ");
    $stmt->bind_param('iis', $eventId, $senderId, $content);
    $stmt->execute();

    respond(['success' => true, 'message_id' => $stmt->insert_id], 201);
}

try {
    $conn = new mysqli($config['db_host'], $config['db_user'], $config['db_pass'], $config['db_name']);
    $conn->set_charset('utf8mb4');
    $action = $_GET['action'] ?? '';

    switch ($action) {
        case 'login': handleLogin($conn); break;
        case 'register': handleRegister($conn); break;
        case 'getCategories': handleGetCategories($conn); break;
        case 'getEvents': handleGetEvents($conn); break;
        case 'getMyEvents': handleGetMyEvents($conn); break;
        case 'getEventDetail': handleGetEventDetail($conn); break;
        case 'createEvent': handleCreateEvent($conn); break;
        case 'getChatMessages': handleGetChatMessages($conn); break;
        case 'sendMessage': handleSendMessage($conn); break;
        default: fail('Invalid action', 404);
    }
} catch (ApiException $e) {
    respond(['success' => false, 'message' => $e->getMessage()], $e->status);
} catch (Throwable $e) {
    respond(['success' => false, 'message' => 'เกิดข้อผิดพลาดที่เซิร์ฟเวอร์'], 500);
}