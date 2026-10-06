<?php
header("Content-Type: application/json; charset=UTF-8");
$host = "172.18.111.42";
$user = "6620310242";   //PSU_PASSPORT_ID
$pass = "6620310242";   //PSU_PASSPORT_ID
$db   = "6620310242_shop"; //PSU_PASSPORT_ID

$conn = new mysqli($host, $user, $pass, $db);

if ($conn->connect_error) {
    die(json_encode(["error" => $conn->connect_error]));
}

$action = $_POST['action'] ?? $_GET['action'] ?? '';

switch ($action) {

    // ---------- CATEGORY ----------
    case "create_category":
        $name = $_POST['name'] ?? '';

        if ($name) {
            $stmt = $conn->prepare("INSERT INTO categories (name) VALUES (?)");
            $stmt->bind_param("s", $name);
            if ($stmt->execute()) {
                echo json_encode(["status" => "success", "id" => $stmt->insert_id]);
            } else {
                echo json_encode(["status" => "error", "message" => $stmt->error]);
            }
            $stmt->close();
        } else {
            echo json_encode(["status" => "error", "message" => "Missing fields"]);
        }
        break;

    case "read_categories":
        $result = $conn->query("SELECT * FROM categories ORDER BY id ASC");
        $rows = [];
        while ($r = $result->fetch_assoc()) {
            $rows[] = $r;
        }
        echo json_encode($rows);
        break;

    // ---------- PRODUCT ----------
    case "create_product":
        $name        = $_POST['name'] ?? '';
        $category_id = $_POST['category_id'] ?? '';

        if ($name && $category_id) {
            $stmt = $conn->prepare("INSERT INTO products (name, category_id) VALUES (?, ?)");
            $stmt->bind_param("si", $name, $category_id);
            if ($stmt->execute()) {
                echo json_encode(["status" => "success", "id" => $stmt->insert_id]);
            } else {
                echo json_encode(["status" => "error", "message" => $stmt->error]);
            }
            $stmt->close();
        } else {
            echo json_encode(["status" => "error", "message" => "Missing fields"]);
        }
        break;

    case "read_products":
        $result = $conn->query("
            SELECT products.id, products.name, categories.name AS category_name
            FROM products
            INNER JOIN categories ON products.category_id = categories.id
        ");
        $rows = [];
        while ($r = $result->fetch_assoc()) {
            $rows[] = $r;
        }
        echo json_encode($rows);
        break;

    case "delete_product":
        $id = $_POST['id'] ?? '';
        if ($id) {
            $stmt = $conn->prepare("DELETE FROM products WHERE id=?");
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