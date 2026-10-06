<?php
/**
 * FitBuddy API (ไม่ใช้ token / ไม่ต้องเพิ่มตารางใหม่)
 *
 * ใช้เฉพาะตารางที่มีอยู่แล้ว: users, sports_categories, events,
 * event_participants, chat_messages
 *
 * หมายเหตุ: แอปเป็นคนส่ง host_id / user_id / sender_id มาเอง
 * ดังนั้นระบบนี้ยังไม่ป้องกันการสวมรอยเป็นผู้ใช้คนอื่น
 */

error_reporting(E_ALL);
ini_set('display_errors', '0');   // ไม่ให้ error หลุดไปปนกับ JSON
ini_set('log_errors', '1');
date_default_timezone_set('Asia/Bangkok');
mysqli_report(MYSQLI_REPORT_ERROR | MYSQLI_REPORT_STRICT); // ให้ mysqli โยน exception

$config = require __DIR__ . '/config.php';

header('Content-Type: application/json; charset=UTF-8');
header('Cache-Control: no-store');
header('Access-Control-Allow-Origin: ' . $config['allowed_origin']);
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

// Preflight ของเบราว์เซอร์ (Flutter Web)
if (($_SERVER['REQUEST_METHOD'] ?? '') === 'OPTIONS') {
    http_response_code(204);
    exit;
}

// รองรับ body แบบ JSON ด้วย (เช่น ทดสอบผ่าน Postman) นอกจาก form-urlencoded
if (stripos($_SERVER['CONTENT_TYPE'] ?? '', 'application/json') === 0) {
    $jsonBody = json_decode(file_get_contents('php://input'), true);
    if (is_array($jsonBody)) {
        $_POST = $jsonBody + $_POST;
    }
}

/* =====================================================================
 * Helpers
 * ===================================================================*/

class ApiException extends Exception
{
    public $status;

    public function __construct($message, $status = 400)
    {
        parent::__construct($message);
        $this->status = $status;
    }
}

function fail($message, $status = 400)
{
    throw new ApiException($message, $status);
}

function respond($payload, $status = 200)
{
    http_response_code($status);
    echo json_encode($payload, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    exit;
}

function requireMethod($method)
{
    if (($_SERVER['REQUEST_METHOD'] ?? '') !== $method) {
        fail('Method not allowed', 405);
    }
}

/** อ่านค่าจาก body (POST) เป็นสตริง; $trim = false สำหรับรหัสผ่าน */
function postStr($key, $trim = true)
{
    $value = $_POST[$key] ?? '';
    if (!is_scalar($value)) {
        return '';
    }
    $value = (string)$value;
    return $trim ? trim($value) : $value;
}

function validDate($s)
{
    $d = DateTime::createFromFormat('Y-m-d', $s);
    return $d && $d->format('Y-m-d') === $s;
}

/** รับ H:i หรือ H:i:s แล้วคืน H:i:s (ถ้าผิดรูปแบบคืน null) */
function normalizeTime($s)
{
    if (preg_match('/^([01]\d|2[0-3]):([0-5]\d)(:([0-5]\d))?$/', $s, $m)) {
        return $m[1] . ':' . $m[2] . ':' . ($m[4] ?? '00');
    }
    return null;
}

function withTransaction($conn, $fn)
{
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

function userExists($conn, $userId)
{
    $stmt = $conn->prepare("SELECT id FROM users WHERE id = ? LIMIT 1");
    $stmt->bind_param('i', $userId);
    $stmt->execute();
    return $stmt->get_result()->num_rows > 0;
}

function isApprovedParticipant($conn, $eventId, $userId)
{
    $stmt = $conn->prepare("
        SELECT 1 FROM event_participants
        WHERE event_id = ? AND user_id = ? AND status = 'APPROVED'
        LIMIT 1
    ");
    $stmt->bind_param('ii', $eventId, $userId);
    $stmt->execute();
    return $stmt->get_result()->num_rows > 0;
}

/* =====================================================================
 * Handlers: Auth
 * ===================================================================*/

function handleLogin($conn)
{
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
        FROM users
        WHERE email = ?
        LIMIT 1
    ");
    $stmt->bind_param('s', $email);
    $stmt->execute();
    $user = $stmt->get_result()->fetch_assoc();

    // ถ้าไม่พบอีเมล ก็ยังตรวจกับ hash หลอก เพื่อให้เวลาตอบใกล้เคียงกัน (กันเดาว่ามีอีเมลนี้ไหม)
    $dummyHash = '$2y$10$' . str_repeat('a', 21) . 'u' . str_repeat('a', 31);
    $hash = $user ? $user['password_hash'] : $dummyHash;
    $passwordOk = password_verify($password, $hash);

    if (!$user || !$passwordOk) {
        $msg = 'อีเมลหรือรหัสผ่านไม่ถูกต้อง'; // ข้อความเดียว ไม่บอกว่าผิดที่ไหน
        global $config;
        if (!empty($config['debug'])) {
            // เฉพาะตอนเปิด debug เพื่อหาสาเหตุ (ก่อนใช้งานจริงต้องปิด)
            $msg .= $user
                ? ' [DEBUG: พบอีเมลนี้ แต่รหัสผ่านไม่ตรงกับ hash | hash ขึ้นต้น "'
                    . substr($user['password_hash'], 0, 4) . '" ยาว ' . strlen($user['password_hash']) . ' ตัว]'
                : ' [DEBUG: ไม่พบอีเมล "' . $email . '" ในตาราง users]';
        }
        fail($msg, 401);
    }

    // อัปเกรด hash อัตโนมัติถ้าอัลกอริทึมเริ่มเก่า
    if (password_needs_rehash($user['password_hash'], PASSWORD_DEFAULT)) {
        $newHash = password_hash($password, PASSWORD_DEFAULT);
        $upd = $conn->prepare("UPDATE users SET password_hash = ? WHERE id = ?");
        $upd->bind_param('si', $newHash, $user['id']);
        $upd->execute();
    }

    unset($user['password_hash']);

    respond([
        'success' => true,
        'message' => 'เข้าสู่ระบบสำเร็จ',
        'data' => $user,
    ]);
}

function handleRegister($conn)
{
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
    if (!preg_match('/^\+?[0-9]{9,15}$/', $phone)) {
        fail('รูปแบบเบอร์โทรศัพท์ไม่ถูกต้อง');
    }
    if (mb_strlen($fullName) > 100) {
        fail('ชื่อ-นามสกุลต้องไม่เกิน 100 ตัวอักษร');
    }
    if (mb_strlen($nickname) > 50) {
        fail('ชื่อเล่นต้องไม่เกิน 50 ตัวอักษร');
    }
    if (strlen($email) > 191 || !filter_var($email, FILTER_VALIDATE_EMAIL)) {
        fail('รูปแบบอีเมลไม่ถูกต้อง');
    }
    if (strlen($password) < 8) {
        fail('รหัสผ่านต้องมีอย่างน้อย 8 ตัวอักษร');
    }
    if (strlen($password) > 72) { // bcrypt ใช้ได้แค่ 72 ไบต์แรก
        fail('รหัสผ่านต้องไม่เกิน 72 ตัวอักษร');
    }
    if (!$consent) {
        fail('กรุณายอมรับนโยบายข้อมูลส่วนบุคคล (PDPA) ก่อนสมัครสมาชิก');
    }

    $check = $conn->prepare("SELECT email, phone_number FROM users WHERE email = ? OR phone_number = ?");
    $check->bind_param('ss', $email, $phone);
    $check->execute();
    $dupes = $check->get_result();
    while ($d = $dupes->fetch_assoc()) {
        if (strtolower($d['email']) === $email) {
            fail('Email นี้ถูกใช้งานแล้ว', 409);
        }
        fail('เบอร์โทรศัพท์นี้ถูกใช้งานแล้ว', 409);
    }

    $passwordHash = password_hash($password, PASSWORD_DEFAULT);

    try {
        // role ใช้ค่า enum ที่มีจริง (USER) ส่วน trust_score / is_verified ฯลฯ ใช้ค่า default ของตาราง
        $stmt = $conn->prepare("
            INSERT INTO users (email, password_hash, full_name, nickname, phone_number, role, pdpa_consent)
            VALUES (?, ?, ?, ?, ?, 'USER', 1)
        ");
        $stmt->bind_param('sssss', $email, $passwordHash, $fullName, $nickname, $phone);
        $stmt->execute();
    } catch (mysqli_sql_exception $e) {
        // 1062 = duplicate key (สมัครพร้อมกันสองครั้ง)
        if ((int)$e->getCode() === 1062) {
            $key = preg_match("/for key '([^']*)'/", $e->getMessage(), $km) ? $km[1] : '';
            fail(stripos($key, 'phone') !== false
                ? 'เบอร์โทรศัพท์นี้ถูกใช้งานแล้ว'
                : 'Email นี้ถูกใช้งานแล้ว', 409);
        }
        throw $e;
    }

    respond([
        'success' => true,
        'message' => 'สมัครสมาชิกสำเร็จ',
        'user_id' => $stmt->insert_id,
    ], 201);
}

/* =====================================================================
 * Handlers: Categories / Events
 * ===================================================================*/

function handleGetCategories($conn)
{
    $result = $conn->query("
        SELECT sc.id, sc.name_th, sc.name_en, sc.icon_name,
               CAST(COUNT(e.id) AS UNSIGNED) AS event_count
        FROM sports_categories sc
        LEFT JOIN events e
            ON e.sport_id = sc.id AND e.status = 'UPCOMING'
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

function handleGetEvents($conn)
{
    $sportId = (int)($_GET['sport_id'] ?? 0);

    $sql = "
        SELECT e.id, e.title, e.description, e.location_name, e.latitude, e.longitude,
               e.event_date, e.start_time, e.end_time, e.max_participants,
               e.current_participants, e.cost_type, e.cost_amount, e.status,
               e.banner_image_url,
               sc.name_th AS sport_name_th,
               u.id AS host_id, u.full_name AS host_name, u.nickname AS host_nickname,
               u.avatar_url AS host_avatar, u.trust_score AS host_trust_score
        FROM events e
        INNER JOIN sports_categories sc ON e.sport_id = sc.id
        INNER JOIN users u ON e.host_id = u.id
        WHERE 1=1
    ";
    if ($sportId > 0) {
        $sql .= " AND e.sport_id = ?";
    }
    $sql .= " ORDER BY e.event_date ASC, e.start_time ASC";

    $stmt = $conn->prepare($sql);
    if ($sportId > 0) {
        $stmt->bind_param('i', $sportId);
    }
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

function handleGetMyEvents($conn)
{
    $userId = (int)($_GET['user_id'] ?? 0);

    if ($userId <= 0) {
        fail('ต้องระบุ User ID');
    }

    $stmt = $conn->prepare("
        SELECT
            e.id,
            e.title,
            e.description,
            e.location_name,
            e.latitude,
            e.longitude,
            e.event_date,
            e.start_time,
            e.end_time,
            e.max_participants,
            e.current_participants,
            e.cost_type,
            e.cost_amount,
            e.status,
            e.banner_image_url,
            p.participant_role,
            sc.name_th AS sport_name_th,
            u.id AS host_id,
            u.full_name AS host_name,
            u.nickname AS host_nickname,
            u.avatar_url AS host_avatar,
            u.trust_score AS host_trust_score
        FROM event_participants p
        INNER JOIN events e ON p.event_id = e.id
        INNER JOIN sports_categories sc ON e.sport_id = sc.id
        INNER JOIN users u ON e.host_id = u.id
        WHERE p.user_id = ?
          AND p.status = 'APPROVED'
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

function handleGetEventDetail($conn)
{
    $id = (int)($_GET['id'] ?? 0);
    $userId = (int)($_GET['user_id'] ?? 0); // ไม่บังคับ: ถ้าส่งมา จะได้ตั๋วของคนนั้นกลับไปด้วย

    if ($id <= 0) {
        fail('ต้องระบุ Event ID');
    }

    $stmt = $conn->prepare("
        SELECT e.*,
               s.name_th AS sport_name,
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

    if (!$event) {
        fail('ไม่พบกิจกรรมนี้', 404);
    }

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
        // ไม่ส่ง ticket_code ของคนอื่นออกไป
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

function handleCreateEvent($conn)
{
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

    if ($hostId <= 0 || $sportId <= 0 || $title === '' || $eventDate === '') {
        fail('ต้องระบุผู้จัด ชนิดกีฬา ชื่อกิจกรรม และวันที่');
    }
    if (mb_strlen($title) > 255) {
        fail('ชื่อกิจกรรมยาวเกินไป');
    }
    if (!validDate($eventDate)) {
        fail('รูปแบบวันที่ไม่ถูกต้อง (ต้องเป็น YYYY-MM-DD)');
    }
    if ($eventDate < date('Y-m-d')) {
        fail('ไม่สามารถสร้างกิจกรรมย้อนหลังได้');
    }
    if ($startTime === null || $endTime === null) {
        fail('ต้องระบุเวลาเริ่มและเวลาสิ้นสุด (รูปแบบ HH:MM)');
    }
    if ($maxParticipants < 2 || $maxParticipants > 100) {
        fail('จำนวนผู้เข้าร่วมต้องอยู่ระหว่าง 2 - 100 คน');
    }
    if ($latitude < -90 || $latitude > 90 || $longitude < -180 || $longitude > 180) {
        fail('พิกัดไม่ถูกต้อง');
    }
    if (!in_array($costType, ['FREE', 'SPLIT_EQUALLY', 'FIXED_PRICE'], true)) {
        fail('ประเภทค่าใช้จ่ายไม่ถูกต้อง (FREE, SPLIT_EQUALLY, FIXED_PRICE)');
    }
    if ($costType === 'FREE') {
        $costAmount = 0.0;
    }
    if ($costAmount < 0 || $costAmount > 100000) {
        fail('ค่าใช้จ่ายไม่ถูกต้อง');
    }
    if (!userExists($conn, $hostId)) {
        fail('ไม่พบผู้ใช้ที่เป็นผู้จัด', 404);
    }

    $sportCheck = $conn->prepare("SELECT id FROM sports_categories WHERE id = ? AND is_active = 1");
    $sportCheck->bind_param('i', $sportId);
    $sportCheck->execute();
    if ($sportCheck->get_result()->num_rows === 0) {
        fail('ไม่พบชนิดกีฬานี้');
    }

    $newEventId = withTransaction($conn, function () use (
        $conn, $hostId, $sportId, $title, $description, $locationName, $latitude,
        $longitude, $eventDate, $startTime, $endTime, $maxParticipants, $costType, $costAmount
    ) {
        $stmt = $conn->prepare("
            INSERT INTO events (
                host_id, sport_id, title, description, location_name,
                latitude, longitude, event_date, start_time, end_time,
                max_participants, current_participants, cost_type, cost_amount, status
            )
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 1, ?, ?, 'UPCOMING')
        ");
        // i i s s s d d s s s i s d  = 13 ตัว ตรงกับ ? 13 ตัว
        $stmt->bind_param(
            'iisssddsssisd',
            $hostId, $sportId, $title, $description, $locationName,
            $latitude, $longitude, $eventDate, $startTime, $endTime,
            $maxParticipants, $costType, $costAmount
        );
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

    respond([
        'success' => true,
        'message' => 'สร้างกิจกรรมสำเร็จ',
        'event_id' => $newEventId,
    ], 201);
}

function handleJoinEvent($conn)
{
    requireMethod('POST');

    $eventId = (int)postStr('event_id');
    $userId = (int)postStr('user_id');

    if ($eventId <= 0 || $userId <= 0) {
        fail('ต้องระบุ Event ID และ User ID');
    }
    if (!userExists($conn, $userId)) {
        fail('ไม่พบผู้ใช้', 404);
    }

    $ticketCode = withTransaction($conn, function () use ($conn, $eventId, $userId) {
        // ล็อกแถวของกิจกรรม กันคนกดเข้าร่วมพร้อมกันจนเกินจำนวน
        $stmt = $conn->prepare("
            SELECT status, max_participants, current_participants
            FROM events WHERE id = ? FOR UPDATE
        ");
        $stmt->bind_param('i', $eventId);
        $stmt->execute();
        $event = $stmt->get_result()->fetch_assoc();

        if (!$event) {
            fail('ไม่พบกิจกรรมนี้', 404);
        }
        if ($event['status'] !== 'UPCOMING') {
            fail('กิจกรรมนี้ปิดรับสมัครแล้ว');
        }

        $check = $conn->prepare("SELECT id FROM event_participants WHERE event_id = ? AND user_id = ?");
        $check->bind_param('ii', $eventId, $userId);
        $check->execute();
        if ($check->get_result()->num_rows > 0) {
            fail('คุณเข้าร่วมกิจกรรมนี้แล้ว', 409);
        }

        if ((int)$event['current_participants'] >= (int)$event['max_participants']) {
            fail('กิจกรรมนี้เต็มแล้ว', 409);
        }

        $code = '#RUN-' . strtoupper(bin2hex(random_bytes(4)));
        $ins = $conn->prepare("
            INSERT INTO event_participants (event_id, user_id, participant_role, status, ticket_code)
            VALUES (?, ?, 'MEMBER', 'APPROVED', ?)
        ");
        $ins->bind_param('iis', $eventId, $userId, $code);
        $ins->execute();

        $upd = $conn->prepare("UPDATE events SET current_participants = current_participants + 1 WHERE id = ?");
        $upd->bind_param('i', $eventId);
        $upd->execute();

        return $code;
    });

    respond([
        'success' => true,
        'message' => 'เข้าร่วมกิจกรรมสำเร็จ',
        'ticket_code' => $ticketCode,
    ]);
}

/* =====================================================================
 * Handlers: Chat
 * ===================================================================*/

function handleGetChatMessages($conn)
{
    $eventId = (int)($_GET['event_id'] ?? 0);
    $afterId = (int)($_GET['after_id'] ?? 0); // ใส่เพื่อดึงเฉพาะข้อความใหม่ (polling)

    if ($eventId <= 0) {
        fail('ต้องระบุ Event ID');
    }

    $stmt = $conn->prepare("
        SELECT c.id, c.sender_id, c.message_type, c.content,
               c.latitude AS lat, c.longitude AS lng, c.created_at,
               u.full_name AS sender_name, u.nickname AS sender_nickname,
               u.avatar_url AS sender_avatar
        FROM chat_messages c
        INNER JOIN users u ON c.sender_id = u.id
        WHERE c.event_id = ? AND c.id > ?
        ORDER BY c.id ASC
        LIMIT 500
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

function handleSendMessage($conn)
{
    requireMethod('POST');

    $eventId = (int)postStr('event_id');
    $senderId = (int)postStr('sender_id');
    $content = postStr('content');
    $messageType = strtoupper(postStr('message_type') !== '' ? postStr('message_type') : 'TEXT');
    $lat = is_numeric(postStr('lat')) ? (float)postStr('lat') : null;
    $lng = is_numeric(postStr('lng')) ? (float)postStr('lng') : null;

    if ($eventId <= 0 || $senderId <= 0 || $content === '') {
        fail('ต้องระบุ Event ID, Sender ID และข้อความ');
    }
    if (mb_strlen($content) > 1000) {
        fail('ข้อความยาวเกิน 1000 ตัวอักษร');
    }
    if (!in_array($messageType, ['TEXT', 'LOCATION'], true)) {
        fail('ประเภทข้อความไม่ถูกต้อง');
    }
    if ($messageType === 'LOCATION' && ($lat === null || $lng === null)) {
        fail('ข้อความแบบตำแหน่งต้องมี lat และ lng');
    }
    if (!isApprovedParticipant($conn, $eventId, $senderId)) {
        fail('เฉพาะผู้เข้าร่วมกิจกรรมเท่านั้นที่ส่งข้อความได้', 403);
    }

    $stmt = $conn->prepare("
        INSERT INTO chat_messages (event_id, sender_id, message_type, content, latitude, longitude)
        VALUES (?, ?, ?, ?, ?, ?)
    ");
    $stmt->bind_param('iissdd', $eventId, $senderId, $messageType, $content, $lat, $lng);
    $stmt->execute();

    respond(['success' => true, 'message_id' => $stmt->insert_id], 201);
}

/* =====================================================================
 * Handlers: Profile
 * ===================================================================*/

/** ดึงข้อมูลโปรไฟล์ของผู้ใช้ (ไม่รวม password_hash) คืน null ถ้าไม่พบ */
function fetchUserProfile($conn, $userId)
{
    $stmt = $conn->prepare("
        SELECT id, email, full_name, nickname, phone_number,
               bio, avatar_url, role, trust_score, total_completed_events,
               is_verified, pdpa_consent
        FROM users
        WHERE id = ?
        LIMIT 1
    ");
    $stmt->bind_param('i', $userId);
    $stmt->execute();
    $row = $stmt->get_result()->fetch_assoc();
    return $row ?: null;
}

function handleGetProfile($conn)
{
    $userId = (int)($_GET['user_id'] ?? 0);
    if ($userId <= 0) {
        fail('ต้องระบุ User ID');
    }

    $user = fetchUserProfile($conn, $userId);
    if (!$user) {
        fail('ไม่พบผู้ใช้', 404);
    }

    respond(['success' => true, 'data' => $user]);
}

/** แก้ไข full_name / nickname / bio (ส่งมาเฉพาะช่องที่ต้องการแก้ก็ได้) */
function handleUpdateProfile($conn)
{
    requireMethod('POST');

    $userId = (int)postStr('user_id');
    if ($userId <= 0) {
        fail('ต้องระบุ User ID');
    }

    $sets = [];
    $types = '';
    $values = [];

    if (array_key_exists('full_name', $_POST)) {
        $fullName = postStr('full_name');
        if ($fullName === '') {
            fail('กรุณากรอกชื่อ-นามสกุล');
        }
        if (mb_strlen($fullName) > 100) {
            fail('ชื่อ-นามสกุลต้องไม่เกิน 100 ตัวอักษร');
        }
        $sets[] = 'full_name = ?';
        $types .= 's';
        $values[] = $fullName;
    }

    if (array_key_exists('nickname', $_POST)) {
        $nickname = postStr('nickname');
        if ($nickname === '') {
            fail('กรุณากรอกชื่อเล่น');
        }
        if (mb_strlen($nickname) > 50) {
            fail('ชื่อเล่นต้องไม่เกิน 50 ตัวอักษร');
        }
        $sets[] = 'nickname = ?';
        $types .= 's';
        $values[] = $nickname;
    }

    if (array_key_exists('bio', $_POST)) {
        $bio = postStr('bio'); // ปล่อยว่างได้
        if (mb_strlen($bio) > 150) {
            fail('Bio ต้องไม่เกิน 150 ตัวอักษร');
        }
        $sets[] = 'bio = ?';
        $types .= 's';
        $values[] = $bio;
    }

    if (!$sets) {
        fail('ไม่มีข้อมูลที่ต้องการแก้ไข');
    }
    if (!userExists($conn, $userId)) {
        fail('ไม่พบผู้ใช้', 404);
    }

    $types .= 'i';
    $values[] = $userId;

    $stmt = $conn->prepare('UPDATE users SET ' . implode(', ', $sets) . ' WHERE id = ?');
    $stmt->bind_param($types, ...$values);
    $stmt->execute();

    respond([
        'success' => true,
        'message' => 'บันทึกข้อมูลสำเร็จ',
        'data' => fetchUserProfile($conn, $userId),
    ]);
}

function handleChangePhone($conn)
{
    requireMethod('POST');

    $userId = (int)postStr('user_id');
    $phone = preg_replace('/[\s-]/', '', postStr('phone_number'));

    if ($userId <= 0 || $phone === '') {
        fail('ต้องระบุ User ID และเบอร์โทรศัพท์ใหม่');
    }
    if (!preg_match('/^\+?[0-9]{9,15}$/', $phone)) {
        fail('รูปแบบเบอร์โทรศัพท์ไม่ถูกต้อง');
    }
    if (!userExists($conn, $userId)) {
        fail('ไม่พบผู้ใช้', 404);
    }

    $check = $conn->prepare("SELECT id FROM users WHERE phone_number = ? AND id <> ? LIMIT 1");
    $check->bind_param('si', $phone, $userId);
    $check->execute();
    if ($check->get_result()->num_rows > 0) {
        fail('เบอร์โทรศัพท์นี้ถูกใช้งานแล้ว', 409);
    }

    try {
        $stmt = $conn->prepare("UPDATE users SET phone_number = ? WHERE id = ?");
        $stmt->bind_param('si', $phone, $userId);
        $stmt->execute();
    } catch (mysqli_sql_exception $e) {
        if ((int)$e->getCode() === 1062) { // duplicate key (เปลี่ยนพร้อมกัน)
            fail('เบอร์โทรศัพท์นี้ถูกใช้งานแล้ว', 409);
        }
        throw $e;
    }

    respond([
        'success' => true,
        'message' => 'เปลี่ยนเบอร์โทรศัพท์สำเร็จ',
        'data' => fetchUserProfile($conn, $userId),
    ]);
}

function handleChangePassword($conn)
{
    requireMethod('POST');

    $userId = (int)postStr('user_id');
    $current = postStr('current_password', false);
    $new = postStr('new_password', false);

    if ($userId <= 0 || $current === '' || $new === '') {
        fail('กรุณากรอกข้อมูลให้ครบ');
    }
    if (strlen($new) < 8) {
        fail('รหัสผ่านใหม่ต้องมีอย่างน้อย 8 ตัวอักษร');
    }
    if (strlen($new) > 72) { // bcrypt ใช้ได้แค่ 72 ไบต์แรก
        fail('รหัสผ่านต้องไม่เกิน 72 ตัวอักษร');
    }

    $stmt = $conn->prepare("SELECT password_hash FROM users WHERE id = ? LIMIT 1");
    $stmt->bind_param('i', $userId);
    $stmt->execute();
    $row = $stmt->get_result()->fetch_assoc();

    if (!$row) {
        fail('ไม่พบผู้ใช้', 404);
    }
    if (!password_verify($current, $row['password_hash'])) {
        fail('รหัสผ่านปัจจุบันไม่ถูกต้อง', 401);
    }
    if (hash_equals($current, $new)) {
        fail('รหัสผ่านใหม่ต้องไม่ซ้ำกับรหัสผ่านเดิม');
    }

    $hash = password_hash($new, PASSWORD_DEFAULT);
    $upd = $conn->prepare("UPDATE users SET password_hash = ? WHERE id = ?");
    $upd->bind_param('si', $hash, $userId);
    $upd->execute();

    respond(['success' => true, 'message' => 'เปลี่ยนรหัสผ่านสำเร็จ']);
}

/* =====================================================================
 * Handlers: Avatar (อัปโหลดรูปโปรไฟล์)
 * ===================================================================*/

/** โฟลเดอร์เก็บรูปโปรไฟล์ (ต้องเปิดผ่านเว็บได้ และ PHP ต้องเขียนไฟล์ได้) */
function avatarDir()
{
    return __DIR__ . '/uploads/avatars';
}

/** URL สาธารณะของรูป (ตั้ง 'avatar_base_url' ใน config.php ได้ถ้าต้องการกำหนดเอง) */
function avatarPublicUrl($fileName)
{
    global $config;
    if (!empty($config['avatar_base_url'])) {
        return rtrim($config['avatar_base_url'], '/') . '/' . $fileName;
    }

    $https = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off')
        || (($_SERVER['HTTP_X_FORWARDED_PROTO'] ?? '') === 'https');
    $host = $_SERVER['HTTP_HOST'] ?? 'localhost';
    $basePath = rtrim(str_replace('\\', '/', dirname($_SERVER['SCRIPT_NAME'] ?? '/')), '/');

    return ($https ? 'https' : 'http') . '://' . $host . $basePath . '/uploads/avatars/' . $fileName;
}

/** ลบไฟล์รูปเก่า (เฉพาะไฟล์ที่ระบบนี้สร้างเอง ชื่อตรงตามรูปแบบเท่านั้น) */
function deleteOldAvatarFile($oldUrl)
{
    if (!is_string($oldUrl) || $oldUrl === '') {
        return;
    }
    $name = basename((string)parse_url($oldUrl, PHP_URL_PATH));
    if (preg_match('/^u\d+_[a-f0-9]{16}\.(jpg|png|webp)$/', $name)) {
        $path = avatarDir() . '/' . $name;
        if (is_file($path)) {
            @unlink($path);
        }
    }
}

/** รับไฟล์จากฟิลด์ 'avatar' (multipart/form-data) + user_id */
function handleUploadAvatar($conn)
{
    requireMethod('POST');

    $userId = (int)postStr('user_id');
    if ($userId <= 0) {
        fail('ต้องระบุ User ID');
    }

    $stmt = $conn->prepare("SELECT avatar_url FROM users WHERE id = ? LIMIT 1");
    $stmt->bind_param('i', $userId);
    $stmt->execute();
    $row = $stmt->get_result()->fetch_assoc();
    if (!$row) {
        fail('ไม่พบผู้ใช้', 404);
    }
    $oldUrl = $row['avatar_url'];

    if (!isset($_FILES['avatar']) || !is_array($_FILES['avatar'])) {
        fail('ไม่พบไฟล์รูปภาพ');
    }
    $file = $_FILES['avatar'];
    $err = $file['error'] ?? UPLOAD_ERR_NO_FILE;

    if ($err === UPLOAD_ERR_INI_SIZE || $err === UPLOAD_ERR_FORM_SIZE) {
        fail('ไฟล์รูปใหญ่เกินไป (ไม่เกิน 2 MB)');
    }
    if ($err !== UPLOAD_ERR_OK || !is_uploaded_file($file['tmp_name'])) {
        fail('อัปโหลดรูปไม่สำเร็จ กรุณาลองใหม่');
    }
    if ((int)$file['size'] > 2 * 1024 * 1024) {
        fail('ไฟล์รูปใหญ่เกินไป (ไม่เกิน 2 MB)');
    }

    // ตรวจชนิดจากเนื้อไฟล์จริง ไม่เชื่อนามสกุลหรือชนิดที่ผู้ใช้ส่งมา
    $info = @getimagesize($file['tmp_name']);
    $allowed = [IMAGETYPE_JPEG => 'jpg', IMAGETYPE_PNG => 'png'];
    if (defined('IMAGETYPE_WEBP')) {
        $allowed[IMAGETYPE_WEBP] = 'webp';
    }
    if (!$info || !isset($allowed[$info[2]])) {
        fail('รองรับเฉพาะไฟล์ JPG, PNG หรือ WebP');
    }
    if ($info[0] > 6000 || $info[1] > 6000) {
        fail('ขนาดรูปใหญ่เกินไป');
    }
    $ext = $allowed[$info[2]];

    $dir = avatarDir();
    if (!is_dir($dir) && !@mkdir($dir, 0755, true) && !is_dir($dir)) {
        error_log('[FitBuddy] สร้างโฟลเดอร์ไม่ได้: ' . $dir);
        fail('สร้างโฟลเดอร์เก็บรูปไม่ได้ ตรวจสอบสิทธิ์การเขียนไฟล์บนเซิร์ฟเวอร์', 500);
    }

    // ตั้งชื่อไฟล์เองทั้งหมด (ไม่ใช้ชื่อจากผู้ใช้)
    $fileName = 'u' . $userId . '_' . bin2hex(random_bytes(8)) . '.' . $ext;
    $target = $dir . '/' . $fileName;
    if (!@move_uploaded_file($file['tmp_name'], $target)) {
        error_log('[FitBuddy] move_uploaded_file ล้มเหลว: ' . $target);
        fail('บันทึกไฟล์รูปไม่สำเร็จ ตรวจสอบสิทธิ์การเขียนไฟล์บนเซิร์ฟเวอร์', 500);
    }
    @chmod($target, 0644);

    $url = avatarPublicUrl($fileName);
    try {
        $upd = $conn->prepare("UPDATE users SET avatar_url = ? WHERE id = ?");
        $upd->bind_param('si', $url, $userId);
        $upd->execute();
    } catch (Throwable $e) {
        @unlink($target); // อัปเดตฐานข้อมูลไม่สำเร็จ ลบไฟล์ที่เพิ่งบันทึกทิ้ง
        throw $e;
    }

    deleteOldAvatarFile($oldUrl);

    respond([
        'success' => true,
        'message' => 'อัปเดตรูปโปรไฟล์สำเร็จ',
        'data' => fetchUserProfile($conn, $userId),
    ]);
}

/* =====================================================================
 * Handlers: Admin
 * ===================================================================*/

function handleGetAdminStats($conn)
{
    $totalUsers = (int)$conn->query("SELECT COUNT(*) AS c FROM users")->fetch_assoc()['c'];
    $totalEvents = (int)$conn->query("SELECT COUNT(*) AS c FROM events")->fetch_assoc()['c'];

    $result = $conn->query("
        SELECT s.name_th, COUNT(e.id) AS event_count
        FROM sports_categories s
        LEFT JOIN events e ON s.id = e.sport_id
        GROUP BY s.id, s.name_th
        ORDER BY event_count DESC
    ");

    $distribution = [];
    while ($row = $result->fetch_assoc()) {
        $distribution[] = ['name' => $row['name_th'], 'count' => (int)$row['event_count']];
    }

    respond([
        'success' => true,
        'data' => [
            'total_users' => $totalUsers,
            'total_events' => $totalEvents,
            'sports_distribution' => $distribution,
        ],
    ]);
}

/* =====================================================================
 * Router
 * ===================================================================*/

try {
    $conn = new mysqli(
        $config['db_host'],
        $config['db_user'],
        $config['db_pass'],
        $config['db_name']
    );
    $conn->set_charset('utf8mb4');

    $action = isset($_GET['action']) && is_string($_GET['action']) ? $_GET['action'] : '';

    switch ($action) {
        case 'login':           handleLogin($conn);           break;
        case 'register':        handleRegister($conn);        break;
        case 'getCategories':   handleGetCategories($conn);   break;
        case 'getEvents':       handleGetEvents($conn);       break;
        case 'getMyEvents':     handleGetMyEvents($conn);     break;
        case 'getEventDetail':  handleGetEventDetail($conn);  break;
        case 'createEvent':     handleCreateEvent($conn);     break;
        case 'joinEvent':       handleJoinEvent($conn);       break;
        case 'getChatMessages': handleGetChatMessages($conn); break;
        case 'sendMessage':     handleSendMessage($conn);     break;
        case 'getAdminStats':   handleGetAdminStats($conn);   break;
        case 'getProfile':      handleGetProfile($conn);      break;
        case 'updateProfile':   handleUpdateProfile($conn);   break;
        case 'changePhone':     handleChangePhone($conn);     break;
        case 'changePassword':  handleChangePassword($conn);  break;
        case 'uploadAvatar':    handleUploadAvatar($conn);    break;
        default:
            fail('Invalid action', 404);
    }
} catch (ApiException $e) {
    respond(['success' => false, 'message' => $e->getMessage()], $e->status);
} catch (Throwable $e) {
    // รายละเอียดจริงลง log ของเซิร์ฟเวอร์
    error_log('[FitBuddy] ' . $e->getMessage() . ' @ ' . $e->getFile() . ':' . $e->getLine());
    $msg = 'เกิดข้อผิดพลาดที่เซิร์ฟเวอร์ กรุณาลองใหม่อีกครั้ง';
    if (!empty($config['debug'])) {
        $msg .= ' [DEBUG: ' . $e->getMessage() . ']';
    }
    respond(['success' => false, 'message' => $msg], 500);
}