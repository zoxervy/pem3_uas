<?php

declare(strict_types=1);

/** Error yang dikirim ke aplikasi sebagai JSON {message, errors?} dengan kode status HTTP. */
final class HttpError extends RuntimeException
{
    public function __construct(public readonly int $status, string $pesan, public readonly array $errors = [])
    {
        parent::__construct($pesan);
    }
}

function gagal(int $status, string $pesan, array $errors = []): never
{
    throw new HttpError($status, $pesan, $errors);
}

/** Error validasi (422) untuk satu field, format sama seperti Laravel. */
function salahInput(string $field, string $pesan): never
{
    gagal(422, $pesan, [$field => [$pesan]]);
}

/** Jawaban dengan kode status selain 200 (mis. 201 Created). */
final class Respon
{
    public function __construct(public readonly mixed $data, public readonly int $status = 200)
    {
    }
}

final class Req
{
    public ?array $user = null;
    public array $param = [];

    public function __construct(
        public readonly string $method,
        public readonly string $path,
        public readonly array $query = [],
        public readonly array $body = [],
        public readonly ?string $token = null,
        public readonly string $ip = '',
    ) {
    }

    /** Request dari web server (Apache/Laragon atau Caddy). Path dihitung mulai setelah "/api". */
    public static function dariGlobal(): self
    {
        $uri = parse_url($_SERVER['REQUEST_URI'] ?? '/', PHP_URL_PATH) ?: '/';
        $pos = strpos($uri, '/api/');
        $path = $pos === false ? '/' : substr($uri, $pos + 4);

        $body = json_decode(file_get_contents('php://input') ?: '', true);
        $auth = $_SERVER['HTTP_AUTHORIZATION'] ?? $_SERVER['REDIRECT_HTTP_AUTHORIZATION'] ?? '';

        return new self(
            strtoupper($_SERVER['REQUEST_METHOD'] ?? 'GET'),
            rtrim($path, '/') ?: '/',
            $_GET,
            is_array($body) ? $body : $_POST,
            str_starts_with($auth, 'Bearer ') ? substr($auth, 7) : null,
            $_SERVER['REMOTE_ADDR'] ?? '',
        );
    }

    public function id(): int
    {
        return (int) $this->param['id'];
    }
}
