<?php
header("Content-Type: application/json; charset=UTF-8");
$host = "172.18.111.42";
$user = "6620310242";   //PSU_PASSPORT_ID
$pass = "6620310242";   //PSU_PASSPORT_ID
$db   = "6620310242_BMI"; //PSU_PASSPORT_ID

$conn = new mysqli($host, $user, $pass, $db);

if ($conn->connect_error) {
    die(json_encode(["error" => $conn->connect_error]));
}

$action = $_POST['action'] ?? $_GET['action'] ?? '';

/**
 * คำนวณเกณฑ์ BMI ตามมาตรฐานเอเชีย
 * รับ BMI แล้วคืนชื่อหมวด (ภาษาไทย)
 */
function bmiCategory($bmi) {
    if ($bmi < 18.5)  return "น้ำหนักน้อย";
    if ($bmi < 23)    return "ปกติ";
    if ($bmi < 25)    return "น้ำหนักเกิน";
    if ($bmi < 30)    return "อ้วน";
    return "อ้วนมาก";
}

switch ($action) {

    // ---------- CREATE ----------
    case "create_record":
        $name      = trim($_POST['name'] ?? '');
        $height_cm = $_POST['height_cm'] ?? '';
        $weight_kg = $_POST['weight_kg'] ?? '';

        if ($height_cm === '' || $weight_kg === '' ||
            !is_numeric($height_cm) || !is_numeric($weight_kg) ||
            $height_cm <= 0 || $weight_kg <= 0) {
            echo json_encode(["status" => "error", "message" => "กรุณากรอกส่วนสูงและน้ำหนักให้ถูกต้อง"]);
            break;
        }

        $height_m = $height_cm / 100;
        $bmi = round($weight_kg / ($height_m * $height_m), 2);
        $category = bmiCategory($bmi);

        $stmt = $conn->prepare(
            "INSERT INTO bmi_records (name, height_cm, weight_kg, bmi, category) VALUES (?, ?, ?, ?, ?)"
        );
        $stmt->bind_param("sddds", $name, $height_cm, $weight_kg, $bmi, $category);

        if ($stmt->execute()) {
            echo json_encode([
                "status"   => "success",
                "id"       => $stmt->insert_id,
                "bmi"      => $bmi,
                "category" => $category,
            ]);
        } else {
            echo json_encode(["status" => "error", "message" => $stmt->error]);
        }
        $stmt->close();
        break;

    // ---------- READ ----------
    case "read_records":
        $result = $conn->query("SELECT * FROM bmi_records ORDER BY created_at DESC");
        $rows = [];
        while ($r = $result->fetch_assoc()) {
            $rows[] = $r;
        }
        echo json_encode($rows);
        break;

    // ---------- DELETE ----------
    case "delete_record":
        $id = $_POST['id'] ?? '';
        if ($id) {
            $stmt = $conn->prepare("DELETE FROM bmi_records WHERE id=?");
            $stmt->bind_param("i", $id);
            if ($stmt->execute()) {
                echo json_encode(["status" => "success"]);
            } else {
                echo json_encode(["status" => "error", "message" => $stmt->error]);
            }
            $stmt->close();
        } else {
            echo json_encode(["status" => "error", "message" => "Missing ID"]);
        }
        break;

    default:
        echo json_encode(["status" => "error", "message" => "Invalid action"]);
        break;
}

$conn->close();