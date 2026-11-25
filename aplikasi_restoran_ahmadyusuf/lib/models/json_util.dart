/// Helper kecil untuk membaca JSON dari Laravel dengan aman.
int toInt(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse('$v') ?? 0;
}

int? toIntOrNull(dynamic v) => v == null ? null : toInt(v);

bool toBool(dynamic v) => v == true || v == 1 || v == '1' || v == 'true';

/// Server mengirim waktu dalam UTC (...Z); ditampilkan sebagai waktu lokal.
DateTime? toDate(dynamic v) =>
    v == null ? null : DateTime.tryParse('$v')?.toLocal();

String toStr(dynamic v) => v == null ? '' : '$v';
