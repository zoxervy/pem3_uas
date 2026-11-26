<?php

declare(strict_types=1);

/** Akses database lewat PDO. Semua query memakai prepared statement (aman dari SQL injection). */
final class Db
{
    private static ?PDO $pdo = null;
    private static int $level = 0;

    public static function pdo(): PDO
    {
        if (self::$pdo === null) {
            $nama = env('DB_DATABASE', 'resto');
            $socket = env('DB_SOCKET', '');
            $dsn = $socket !== ''
                ? "mysql:unix_socket=$socket;dbname=$nama;charset=utf8mb4"
                : 'mysql:host=' . env('DB_HOST', '127.0.0.1') . ';port=' . env('DB_PORT', '3306') . ";dbname=$nama;charset=utf8mb4";
            self::$pdo = new PDO($dsn, env('DB_USERNAME', 'root'), env('DB_PASSWORD', ''), [
                PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                PDO::ATTR_EMULATE_PREPARES => false,     // angka dikembalikan sebagai angka, bukan teks
            ]);
        }

        return self::$pdo;
    }

    public static function semua(string $sql, array $param = []): array
    {
        $st = self::pdo()->prepare($sql);
        $st->execute($param);

        return $st->fetchAll();
    }

    public static function satu(string $sql, array $param = []): ?array
    {
        return self::semua($sql, $param)[0] ?? null;
    }

    public static function nilai(string $sql, array $param = []): mixed
    {
        $st = self::pdo()->prepare($sql);
        $st->execute($param);
        $v = $st->fetchColumn();

        return $v === false ? null : $v;
    }

    public static function jalankan(string $sql, array $param = []): int
    {
        $st = self::pdo()->prepare($sql);
        $st->execute($param);

        return $st->rowCount();
    }

    public static function sisip(string $tabel, array $data): int
    {
        $kolom = implode(', ', array_map(fn ($k) => "`$k`", array_keys($data)));
        $tanda = implode(', ', array_fill(0, count($data), '?'));
        self::jalankan("INSERT INTO `$tabel` ($kolom) VALUES ($tanda)", array_values($data));

        return (int) self::pdo()->lastInsertId();
    }

    public static function ubah(string $tabel, array $data, int $id): void
    {
        $set = implode(', ', array_map(fn ($k) => "`$k` = ?", array_keys($data)));
        self::jalankan("UPDATE `$tabel` SET $set WHERE id = ?", [...array_values($data), $id]);
    }

    /** Baris dengan id tertentu, atau 404. */
    public static function cari(string $tabel, int $id, bool $kunci = false): array
    {
        return self::satu("SELECT * FROM `$tabel` WHERE id = ?" . ($kunci ? ' FOR UPDATE' : ''), [$id])
            ?? gagal(404, 'Data tidak ditemukan.');
    }

    /** Hapus baris; kalau masih dipakai tabel lain (foreign key), balas 409 dengan pesan [$pesan]. */
    public static function hapus(string $tabel, int $id, string $pesan): void
    {
        try {
            self::jalankan("DELETE FROM `$tabel` WHERE id = ?", [$id]);
        } catch (PDOException $e) {
            if ($e->getCode() === '23000') {
                gagal(409, $pesan);
            }
            throw $e;
        }
    }

    /** Jalankan [$aksi] dalam transaksi. Bisa bersarang (memakai SAVEPOINT). */
    public static function transaksi(callable $aksi): mixed
    {
        $pdo = self::pdo();
        $bersarang = $pdo->inTransaction();
        $titik = 'sp' . ++self::$level;
        $bersarang ? $pdo->exec("SAVEPOINT $titik") : $pdo->beginTransaction();
        try {
            $hasil = $aksi();
            $bersarang ? $pdo->exec("RELEASE SAVEPOINT $titik") : $pdo->commit();

            return $hasil;
        } catch (Throwable $e) {
            $bersarang ? $pdo->exec("ROLLBACK TO SAVEPOINT $titik") : $pdo->rollBack();
            throw $e;
        } finally {
            self::$level--;
        }
    }
}
