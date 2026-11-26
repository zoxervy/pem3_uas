<?php

declare(strict_types=1);

/**
 * Token login, disimpan di tabel personal_access_tokens.
 * Format token "id|rahasia"; database hanya menyimpan hash SHA-256 dari bagian rahasia,
 * sama dengan Laravel Sanctum, jadi token lama tetap berlaku.
 */
final class Auth
{
    public static function buatToken(int $userId): string
    {
        $acak = acak(40);
        $rahasia = $acak . hash('crc32b', $acak);
        $id = Db::sisip('personal_access_tokens', [
            'tokenable_type' => 'App\\Models\\User', 'tokenable_id' => $userId, 'name' => 'flutter',
            'token' => hash('sha256', $rahasia), 'abilities' => '["*"]', 'created_at' => sekarang(), 'updated_at' => sekarang(),
        ]);

        return "$id|$rahasia";
    }

    /** User pemilik token, atau null kalau token salah/kedaluwarsa. */
    public static function userDariToken(?string $token): ?array
    {
        if ($token === null || !str_contains($token, '|')) {
            return null;
        }
        [$id, $rahasia] = explode('|', $token, 2);
        $baris = Db::satu('SELECT * FROM personal_access_tokens WHERE id = ?', [(int) $id]);
        if ($baris === null || !hash_equals($baris['token'], hash('sha256', $rahasia))) {
            return null;
        }
        if ($baris['expires_at'] !== null && strtotime($baris['expires_at']) < time()) {
            return null;
        }
        Db::jalankan('UPDATE personal_access_tokens SET last_used_at = ? WHERE id = ?', [sekarang(), $baris['id']]);
        $user = Db::satu('SELECT * FROM users WHERE id = ?', [$baris['tokenable_id']]);
        if ($user !== null) {
            $user['id_token'] = (int) $baris['id'];
        }

        return $user;
    }

    public static function hapusSemua(int $userId): void
    {
        Db::jalankan('DELETE FROM personal_access_tokens WHERE tokenable_id = ?', [$userId]);
    }
}
