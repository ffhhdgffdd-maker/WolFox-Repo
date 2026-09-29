<?php
declare(strict_types=1);

/**
 * Include this file from bot.php on the same server.
 * Configure WOLFOX_UDID_API_URL and WOLFOX_UDID_API_KEY as environment variables.
 */
function wolfoxUdidApiRequest(string $method, array $payload = []): array
{
    $baseUrl = rtrim((string) getenv('WOLFOX_UDID_API_URL'), '/');
    $apiKey = trim((string) getenv('WOLFOX_UDID_API_KEY'));
    if ($baseUrl === '' || $apiKey === '') {
        throw new RuntimeException('UDID API is not configured');
    }

    $url = $baseUrl;
    $headers = [
        'Accept: application/json',
        'X-WolFox-Api-Key: ' . $apiKey,
    ];
    $ch = curl_init();
    if ($ch === false) throw new RuntimeException('Unable to initialize cURL');

    if ($method === 'GET') {
        $url .= '?' . http_build_query(['udid' => (string) ($payload['udid'] ?? '')]);
    } else {
        $headers[] = 'Content-Type: application/json';
        curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($payload, JSON_UNESCAPED_SLASHES));
    }

    curl_setopt_array($ch, [
        CURLOPT_URL => $url,
        CURLOPT_CUSTOMREQUEST => $method,
        CURLOPT_HTTPHEADER => $headers,
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_CONNECTTIMEOUT => 8,
        CURLOPT_TIMEOUT => 20,
        CURLOPT_SSL_VERIFYPEER => true,
        CURLOPT_SSL_VERIFYHOST => 2,
    ]);
    $body = curl_exec($ch);
    $status = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $error = curl_error($ch);
    curl_close($ch);
    if ($body === false || $error !== '') throw new RuntimeException('UDID API request failed');

    $data = json_decode($body, true);
    if (!is_array($data)) throw new RuntimeException('UDID API returned invalid JSON');
    if ($status < 200 || $status >= 300) {
        throw new RuntimeException((string) ($data['error'] ?? 'UDID API error'));
    }
    return $data;
}

function wolfoxRegisterUdid(string $udid, string $deviceName = '', string $source = 'telegram'): array
{
    return wolfoxUdidApiRequest('POST', [
        'udid' => $udid,
        'deviceName' => $deviceName,
        'source' => $source,
    ]);
}

function wolfoxCheckUdid(string $udid): array
{
    return wolfoxUdidApiRequest('GET', ['udid' => $udid]);
}
