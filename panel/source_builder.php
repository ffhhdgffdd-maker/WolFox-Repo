<?php
declare(strict_types=1);

function wolfoxBuildSource(array $settings, array $apps): array {
    $publicApps = [];
    foreach ($apps as $app) {
        if (!empty($app['hidden'])) continue;

        $version = [
            'version' => (string)($app['version'] ?? '1.0.0'),
            'buildVersion' => (string)($app['buildVersion'] ?? '1'),
            'date' => (string)($app['date'] ?? date('Y-m-d')),
            'localizedDescription' => (string)($app['versionDescription'] ?? ''),
            'downloadURL' => (string)($app['downloadURL'] ?? ''),
            'size' => (int)($app['size'] ?? 0),
            'minOSVersion' => (string)($app['minOSVersion'] ?? '16.0'),
        ];

        $publicApps[] = [
            'name' => (string)($app['name'] ?? ''),
            'bundleIdentifier' => (string)($app['bundleIdentifier'] ?? ''),
            'developerName' => (string)($app['developerName'] ?? 'WolFox'),
            'subtitle' => (string)($app['subtitle'] ?? ''),
            'localizedDescription' => (string)($app['description'] ?? ''),
            'iconURL' => (string)($app['iconURL'] ?? ''),
            'tintColor' => (string)($app['tintColor'] ?? '007AFF'),
            'category' => (string)($app['category'] ?? 'utilities'),
            'versions' => [$version],
            'appPermissions' => ['entitlements' => [], 'privacy' => (object)[]],
        ];
    }

    return [
        'name' => 'WolFox Repo',
        'identifier' => 'fun.repo.p3nd.wolfoxrepo',
        'subtitle' => 'WolFox application repository',
        'description' => 'Application source for WolFox Repo.',
        'website' => 'https://github.com/ffhhdgffdd-maker/WolFox-Repo',
        'tintColor' => '007AFF',
        'apps' => $publicApps,
        'news' => [],
    ];
}

function wolfoxWriteSource(string $path, array $settings, array $apps): void {
    $json = json_encode(wolfoxBuildSource($settings, $apps), JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);
    if ($json === false) throw new RuntimeException('Failed to encode source JSON');
    if (file_put_contents($path, $json . PHP_EOL, LOCK_EX) === false) {
        throw new RuntimeException('Failed to write source JSON');
    }
}
