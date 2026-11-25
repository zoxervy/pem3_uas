import 'package:intl/intl.dart';

final NumberFormat _rp =
    NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
final DateFormat _jam = DateFormat('dd/MM/yyyy HH:mm');
final DateFormat _tgl = DateFormat('dd/MM/yyyy');

/// 25000 -> "Rp 25.000"
String rupiah(num nilai) => _rp.format(nilai);

String tanggalJam(DateTime? d) => d == null ? '-' : _jam.format(d);

String tanggalSaja(DateTime d) => _tgl.format(d);
