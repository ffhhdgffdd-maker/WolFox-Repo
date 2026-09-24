<?php
declare(strict_types=1);

function wolfoxValidateApp(array $app): array {
    $errors = [];
    foreach (['name','bundleIdentifier','version','downloadURL'] as $key) {
        if (trim((string)($app[$key] ?? '')) === '') $errors[] = "Missing {$key}";
    }
    $url = (string)($app['downloadURL'] ?? '');
    if ($url !== '' && filter_var($url, FILTER_VALIDATE_URL) === false) $errors[] = 'Invalid downloadURL';
    $icon = (string)($app['iconURL'] ?? '');
    if ($icon !== '' && filter_var($icon, FILTER_VALIDATE_URL) === false) $errors[] = 'Invalid iconURL';
    return $errors;
}
