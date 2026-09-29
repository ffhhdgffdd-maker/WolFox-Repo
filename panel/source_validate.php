<?php
declare(strict_types=1);

function wolfoxValidateApp(array $app): array {
    $errors = [];
    $platform = strtolower(trim((string)($app['platform'] ?? 'android')));
    if ($platform !== 'android') $errors[] = 'Only Android applications are accepted';
    foreach (['name','applicationId','version','apkURL'] as $key) {
        if (trim((string)($app[$key] ?? '')) === '') $errors[] = "Missing {$key}";
    }
    $url = (string)($app['apkURL'] ?? '');
    if ($url !== '' && filter_var($url, FILTER_VALIDATE_URL) === false) $errors[] = 'Invalid apkURL';
    if ($url !== '' && !preg_match('/^https:\/\//i', $url)) $errors[] = 'apkURL must use HTTPS';
    $icon = (string)($app['iconURL'] ?? '');
    if ($icon !== '' && filter_var($icon, FILTER_VALIDATE_URL) === false) $errors[] = 'Invalid iconURL';
    return $errors;
}
