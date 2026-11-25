<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\LogAktivitas;
use App\Models\Pesanan;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;
use Illuminate\Validation\ValidationException;

/**
 * Pesanan dari sisi staf.
 * Kasir: menerima & menugaskan waitress, membatalkan.
 * Waitress: ambil tugas, validasi di meja (bisa ubah item), tampilkan QR bayar, antar.
 */
class PesananController extends Controller
{
    private const RELASI = ['meja', 'waiter:id,nama', 'kasir:id,nama', 'detail.menu'];

    /** Pesanan yang masih berjalan. Waitress hanya melihat tugasnya + yang belum ditugaskan. */
    public function index(Request $request)
    {
        $user = $request->user();

        return Pesanan::with(self::RELASI)
            ->whereIn('status', Pesanan::STATUS_AKTIF)
            ->when($user->isWaitress(), fn ($q) => $q->where(fn ($w) => $w->where('waiter_id', $user->id)
                ->orWhere(fn ($b) => $b->whereNull('waiter_id')->where('status', 'menunggu_konfirmasi'))))
            ->orderBy('tanggal')
            ->get()
            ->each(fn ($p) => $user->isWaitress() || $user->isAdmin() ? $p->makeVisible('kode_bayar') : null);
    }

    public function show(Request $request, Pesanan $pesanan)
    {
        $p = $pesanan->load(self::RELASI);

        return $request->user()->isKasir() ? $p : $p->makeVisible('kode_bayar');
    }

    /** Daftar waitress aktif (untuk pilihan penugasan di layar kasir). */
    public function daftarWaitress()
    {
        return User::where('role', 'waitress')->where('aktif', true)->orderBy('nama')->get(['id', 'nama']);
    }

    /** Kasir menugaskan pesanan ke waitress tertentu. */
    public function tugaskan(Request $request, Pesanan $pesanan)
    {
        $waiterId = $request->validate([
            'waiter_id' => ['required', Rule::exists('users', 'id')->where('role', 'waitress')->where('aktif', true)],
        ])['waiter_id'];

        $p = $this->ubah($pesanan, function (Pesanan $p) use ($waiterId, $request) {
            if ($p->status !== 'menunggu_konfirmasi') {
                throw ValidationException::withMessages(['status' => 'Pesanan ini sudah divalidasi, tidak bisa dipindah tugas.']);
            }
            $p->update(['waiter_id' => $waiterId]);
            $nama = User::find($waiterId)->nama;
            LogAktivitas::catat($request->user()->id, 'tugaskan', "Kasir {$request->user()->nama} menugaskan {$p->kode_pesanan} (meja {$p->meja->nomor_meja}) ke {$nama}", $p->id);
        });

        return $p;
    }

    /** Waitress mengambil sendiri pesanan yang belum ditugaskan kasir. */
    public function ambil(Request $request, Pesanan $pesanan)
    {
        return $this->ubah($pesanan, function (Pesanan $p) use ($request) {
            if ($p->status !== 'menunggu_konfirmasi' || $p->waiter_id !== null) {
                throw ValidationException::withMessages(['status' => 'Pesanan ini sudah ditangani waitress lain.']);
            }
            $p->update(['waiter_id' => $request->user()->id]);
            LogAktivitas::catat($request->user()->id, 'ambil_tugas', "{$request->user()->nama} mengambil pesanan {$p->kode_pesanan} (meja {$p->meja->nomor_meja})", $p->id);
        });
    }

    /** Waitress mengubah item saat memvalidasi di meja (sebelum QR bayar muncul). */
    public function ubahItems(Request $request, Pesanan $pesanan)
    {
        $data = $request->validate(Pesanan::aturanItems());

        return $this->ubah($pesanan, function (Pesanan $p) use ($data, $request) {
            $this->pastikanTugasSaya($request, $p);
            if (! $p->bisaDiubah()) {      // NF-02
                throw ValidationException::withMessages(['status' => 'Pesanan yang sudah divalidasi tidak bisa diubah.']);
            }
            [$baris, $total] = Pesanan::bangunItems($data['items']);
            $p->detail()->delete();
            $p->detail()->createMany($baris);
            $p->update(['total' => $total]);
            LogAktivitas::catat($request->user()->id, 'ubah_pesanan', "{$request->user()->nama} mengubah item pesanan {$p->kode_pesanan}", $p->id);
        });
    }

    /** Waitress memvalidasi pesanan di meja: QR pembayaran dibuat. */
    public function konfirmasi(Request $request, Pesanan $pesanan)
    {
        return $this->ubah($pesanan, function (Pesanan $p) use ($request) {
            $this->pastikanTugasSaya($request, $p);
            $this->pindahStatus($p, 'menunggu_pembayaran');
            $p->update(['waktu_konfirmasi' => now(), 'kode_bayar' => Str::random(40)]);
            LogAktivitas::catat($request->user()->id, 'konfirmasi_pesanan', "{$request->user()->nama} memvalidasi pesanan {$p->kode_pesanan}, menunggu pembayaran", $p->id);
        }, tampilkanKodeBayar: true);
    }

    /** Waitress mengantar pesanan yang sudah lunas. */
    public function antar(Request $request, Pesanan $pesanan)
    {
        return $this->ubah($pesanan, function (Pesanan $p) use ($request) {
            $this->pastikanTugasSaya($request, $p);
            $this->pindahStatus($p, 'disajikan');
            $p->update(['waktu_antar' => now()]);
            $p->meja->perbaruiStatus();
            LogAktivitas::catat($request->user()->id, 'antar_pesanan', "{$request->user()->nama} mengantar pesanan {$p->kode_pesanan} ke meja {$p->meja->nomor_meja}", $p->id);
        });
    }

    /** Kasir (atau waitress yang bertugas) membatalkan pesanan yang belum dibayar. */
    public function batal(Request $request, Pesanan $pesanan)
    {
        return $this->ubah($pesanan, function (Pesanan $p) use ($request) {
            if ($request->user()->isWaitress()) {
                $this->pastikanTugasSaya($request, $p);
            }
            $this->pindahStatus($p, 'batal');
            $p->meja->perbaruiStatus();
            LogAktivitas::catat($request->user()->id, 'batal', "{$request->user()->nama} membatalkan pesanan {$p->kode_pesanan}", $p->id);
        });
    }

    /** Jalankan perubahan dalam transaksi dengan baris pesanan dikunci. */
    private function ubah(Pesanan $pesanan, callable $aksi, bool $tampilkanKodeBayar = false)
    {
        DB::transaction(function () use ($pesanan, $aksi) {
            $aksi(Pesanan::with('meja')->lockForUpdate()->findOrFail($pesanan->id));
        });
        $p = $pesanan->fresh()->load(self::RELASI);

        return $tampilkanKodeBayar ? $p->makeVisible('kode_bayar') : $p;
    }

    private function pindahStatus(Pesanan $p, string $baru): void
    {
        if (! $p->bisaPindahKe($baru)) {
            throw ValidationException::withMessages(['status' => "Status tidak bisa berubah dari {$p->status} ke {$baru}."]);
        }
        $p->update(['status' => $baru]);
    }

    private function pastikanTugasSaya(Request $request, Pesanan $p): void
    {
        abort_if((int) $p->waiter_id !== (int) $request->user()->id, 403, 'Pesanan ini bukan tugas Anda.');
    }
}
