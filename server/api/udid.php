<?php
declare(strict_types=1);

require_once dirname(__DIR__) . '/bootstrap.php';

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

if (!in_array($_SERVER['REQUEST_METHOD'], ['GET', 'POST'], true)) {
    header('Allow: GET, POST, OPTIONS');
    wolfoxJson(['ok' => false, 'error' => 'method_not_allowed'], 405);
}

wolfoxRequireApiKey();
$db = wolfoxDb();

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    $udid = wolfoxNormalizeUdid($_GET['udid'] ?? '');
    $stmt = $db->prepare('SELECT * FROM udid_devices WHERE udid_hash = :hash LIMIT 1');
    $stmt->bindValue(':hash', wolfoxUdidHash($udid), SQLITE3_TEXT);
    $result = $stmt->execute();
    $row = $result->fetchArray(SQLITE3_ASSOC);

    if (!$row) {
        wolfoxJson(['ok' => true, 'registered' => false, 'certificateStatus' => 'unknown']);
    }

    $now = wolfoxNow();
    $update = $db->prepare('UPDATE udid_devices SET last_checked_at = :now WHERE id = :id');
    $update->bindValue(':now', $now, SQLITE3_TEXT);
    $update->bindValue(':id', (int) $row['id'], SQLITE3_INTEGER);
    $update->execute();
    $row['last_checked_at'] = $now;
    wolfoxJson(['ok' => true] + wolfoxPublicDevice($row));
}

$raw = file_get_contents('php://input');
if ($raw === false || strlen($raw) > 16384) {
    wolfoxJson(['ok' => false, 'error' => 'invalid_request_body'], 413);
}
$input = json_decode($raw, true);
if (!is_array($input)) {
    wolfoxJson(['ok' => false, 'error' => 'invalid_json'], 400);
}

$udid = wolfoxNormalizeUdid($input['udid'] ?? '');
$deviceName = trim((string) ($input['deviceName'] ?? ''));
$source = trim((string) ($input['source'] ?? 'api'));
$deviceName = substr($deviceName, 0, 120);
$source = preg_replace('/[^A-Za-z0-9_.:-]/', '', substr($source, 0, 40)) ?: 'api';
$now = wolfoxNow();
$hash = wolfoxUdidHash($udid);

$stmt = $db->prepare(<<<'SQL'
    INSERT INTO udid_devices
        (udid, udid_hash, device_name, source, certificate_status, created_at, updated_at)
    VALUES (:udid, :hash, :device_name, :source, 'pending', :created_at, :updated_at)
    ON CONFLICT(udid_hash) DO UPDATE SET
        device_name = CASE WHEN excluded.device_name <> '' THEN excluded.device_name ELSE udid_devices.device_name END,
        source = excluded.source,
        updated_at = excluded.updated_at
SQL);
$stmt->bindValue(':udid', $udid, SQLITE3_TEXT);
$stmt->bindValue(':hash', $hash, SQLITE3_TEXT);
$stmt->bindValue(':device_name', $deviceName, SQLITE3_TEXT);
$stmt->bindValue(':source', $source, SQLITE3_TEXT);
$stmt->bindValue(':created_at', $now, SQLITE3_TEXT);
$stmt->bindValue(':updated_at', $now, SQLITE3_TEXT);
$stmt->execute();

$lookup = $db->prepare('SELECT * FROM udid_devices WHERE udid_hash = :hash LIMIT 1');
$lookup->bindValue(':hash', $hash, SQLITE3_TEXT);
$result = $lookup->execute();
$row = $result->fetchArray(SQLITE3_ASSOC);
if (!$row) {
    wolfoxJson(['ok' => false, 'error' => 'registration_failed'], 500);
}

wolfoxJson(['ok' => true, 'registered' => true, 'created' => $row['created_at'] === $now] + wolfoxPublicDevice($row), 201);
