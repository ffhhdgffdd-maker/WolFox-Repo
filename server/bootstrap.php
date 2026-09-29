<?php
declare(strict_types=1);

/**
 * Shared server bootstrap for the WolFox UDID API.
 * Keep secrets in environment variables; never commit them to the repository.
 */
const WOLFOX_UDID_DB = __DIR__ . '/data/wolfox.sqlite';

function wolfoxDb(): SQLite3
{
    static $db;
    if ($db instanceof SQLite3) {
        return $db;
    }

    $dataDir = dirname(WOLFOX_UDID_DB);
    if (!is_dir($dataDir) && !mkdir($dataDir, 0750, true) && !is_dir($dataDir)) {
        throw new RuntimeException('Unable to create database directory');
    }

    $db = new SQLite3(WOLFOX_UDID_DB);
    $db->enableExceptions(true);
    $db->busyTimeout(5000);
    $db->exec('PRAGMA journal_mode = WAL');
    $db->exec('PRAGMA foreign_keys = ON');
    $db->exec(<<<'SQL'
        CREATE TABLE IF NOT EXISTS udid_devices (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            udid TEXT NOT NULL UNIQUE,
            udid_hash TEXT NOT NULL UNIQUE,
            device_name TEXT NOT NULL DEFAULT '',
            source TEXT NOT NULL DEFAULT 'api',
            certificate_status TEXT NOT NULL DEFAULT 'unknown',
            certificate_expires_at TEXT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            last_checked_at TEXT NULL
        )
    SQL);
    $db->exec('CREATE INDEX IF NOT EXISTS idx_udid_devices_hash ON udid_devices (udid_hash)');

    return $db;
}

function wolfoxJson(array $payload, int $status = 200): never
{
    http_response_code($status);
    header('Content-Type: application/json; charset=utf-8');
    header('Cache-Control: no-store');
    echo json_encode($payload, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    exit;
}

function wolfoxRequireApiKey(): void
{
    $expected = trim((string) getenv('WOLFOX_UDID_API_KEY'));
    if ($expected === '') {
        wolfoxJson(['ok' => false, 'error' => 'server_not_configured'], 503);
    }

    $provided = trim((string) ($_SERVER['HTTP_X_WOLFOX_API_KEY'] ?? ''));
    if ($provided === '' && preg_match('/^Bearer\s+(.+)$/i', (string) ($_SERVER['HTTP_AUTHORIZATION'] ?? ''), $m)) {
        $provided = trim($m[1]);
    }

    if ($provided === '' || !hash_equals($expected, $provided)) {
        wolfoxJson(['ok' => false, 'error' => 'unauthorized'], 401);
    }
}

function wolfoxNormalizeUdid(mixed $value): string
{
    $udid = strtoupper(trim((string) $value));
    $udid = preg_replace('/\s+/', '', $udid) ?? '';
    if ($udid === '' || !preg_match('/^[A-F0-9-]{16,64}$/', $udid)) {
        wolfoxJson(['ok' => false, 'error' => 'invalid_udid'], 422);
    }
    return $udid;
}

function wolfoxUdidHash(string $udid): string
{
    return hash('sha256', $udid);
}

function wolfoxNow(): string
{
    return gmdate('c');
}

function wolfoxPublicDevice(array $row): array
{
    return [
        'registered' => true,
        'deviceName' => $row['device_name'],
        'source' => $row['source'],
        'certificateStatus' => $row['certificate_status'],
        'certificateExpiresAt' => $row['certificate_expires_at'],
        'createdAt' => $row['created_at'],
        'updatedAt' => $row['updated_at'],
        'lastCheckedAt' => $row['last_checked_at'],
    ];
}
