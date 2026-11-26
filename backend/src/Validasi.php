<?php

declare(strict_types=1);

/**
 * Validasi input. Aturan per field dipisah "|", contoh:
 *   ['nama' => 'wajib|teks:100', 'harga' => 'wajib|bulat:0', 'foto' => 'opsional|teks:255', 'aktif' => 'boolean']
 * wajib    = harus ada dan tidak kosong
 * opsional = boleh kosong (dikirim kosong -> disimpan null)
 * tanpa keduanya = hanya diperiksa kalau dikirim
 */
final class V
{
    public static function cek(array $data, array $aturan, array $label = []): array
    {
        $hasil = [];
        $errors = [];
        foreach ($aturan as $field => $spek) {
            $atur = explode('|', $spek);
            $nilai = $data[$field] ?? null;
            if (is_string($nilai)) {
                $nilai = trim($nilai);
            }
            $nama = ucfirst($label[$field] ?? str_replace('_', ' ', $field));

            if ($nilai === null || $nilai === '') {
                if (in_array('wajib', $atur, true)) {
                    $errors[$field][] = "$nama wajib diisi.";
                } elseif (in_array('opsional', $atur, true) && array_key_exists($field, $data)) {
                    $hasil[$field] = null;
                }
                continue;
            }

            foreach ($atur as $a) {
                [$jenis, $arg] = array_pad(explode(':', $a, 2), 2, null);
                $pesan = self::periksa($jenis, $arg, $nilai, $nama);
                if ($pesan !== null) {
                    $errors[$field][] = $pesan;
                    continue 2;
                }
            }
            $hasil[$field] = self::ubahTipe($nilai, $atur);
        }
        if ($errors) {
            gagal(422, reset($errors)[0], $errors);
        }

        return $hasil;
    }

    private static function periksa(string $jenis, ?string $arg, mixed $v, string $nama): ?string
    {
        $bulat = is_int($v) || (is_string($v) && preg_match('/^-?\d+$/', $v));

        return match ($jenis) {
            'teks' => !is_string($v) ? "$nama harus berupa teks."
                : (mb_strlen($v) > (int) $arg ? "$nama maksimal $arg karakter." : null),
            'minteks' => is_string($v) && mb_strlen($v) < (int) $arg ? "$nama minimal $arg karakter." : null,
            'bulat' => !$bulat ? "$nama harus berupa angka bulat."
                : ($arg !== null && (int) $v < (int) $arg ? "$nama minimal $arg." : null),
            'maks' => (int) $v > (int) $arg ? "$nama maksimal $arg." : null,
            'boolean' => in_array($v, [true, false, 0, 1, '0', '1'], true) ? null : "$nama harus benar/salah.",
            'pilihan' => in_array($v, explode(',', (string) $arg), true) ? null : "$nama tidak valid.",
            'tanggal' => is_string($v) && preg_match('/^\d{4}-\d{2}-\d{2}$/', $v) && strtotime($v) !== false
                ? null : "$nama harus berupa tanggal (YYYY-MM-DD).",
            default => null,
        };
    }

    private static function ubahTipe(mixed $v, array $atur): mixed
    {
        foreach ($atur as $a) {
            $jenis = explode(':', $a, 2)[0];
            if ($jenis === 'bulat') {
                return (int) $v;
            }
            if ($jenis === 'boolean') {
                return (int) (bool) $v;
            }
        }

        return $v;
    }
}

/** Validasi daftar item pesanan [{menu_id, jumlah, catatan}]. */
function validasiItems(array $body): array
{
    $items = $body['items'] ?? null;
    if (!is_array($items) || !array_is_list($items) || count($items) < 1) {
        salahInput('items', 'Pilih minimal satu menu.');
    }
    if (count($items) > 50) {
        salahInput('items', 'Maksimal 50 item per pesanan.');
    }
    $hasil = [];
    foreach ($items as $item) {
        if (!is_array($item)) {
            salahInput('items', 'Item pesanan tidak valid.');
        }
        $hasil[] = V::cek($item, ['menu_id' => 'wajib|bulat:1', 'jumlah' => 'wajib|bulat:1|maks:99', 'catatan' => 'opsional|teks:255'],
            ['menu_id' => 'menu']);
    }
    $ids = array_values(array_unique(array_column($hasil, 'menu_id')));
    $tanda = implode(',', array_fill(0, count($ids), '?'));
    if ((int) Db::nilai("SELECT COUNT(*) FROM menu WHERE id IN ($tanda)", $ids) !== count($ids)) {
        salahInput('items', 'Ada menu yang tidak ditemukan.');
    }

    return $hasil;
}
