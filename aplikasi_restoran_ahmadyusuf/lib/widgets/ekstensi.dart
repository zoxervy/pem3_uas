import 'dart:async';

import 'package:material_ui/material_ui.dart' hide MenuController;

extension SetelahBuild on State {
  /// Jalankan [aksi] setelah frame pertama selesai (aman memanggil controller yang memberi notifikasi).
  void setelahBuild(void Function() aksi) => WidgetsBinding.instance.addPostFrameCallback((_) => aksi());
}

/// Memanggil ulang sebuah fungsi secara berkala; timer dimatikan otomatis saat halaman ditutup.
mixin PollingMixin<T extends StatefulWidget> on State<T> {
  Timer? _timer;

  void mulaiPolling(Duration jeda, void Function() aksi) {
    _timer?.cancel();
    _timer = Timer.periodic(jeda, (_) => aksi());
  }

  void hentikanPolling() => _timer?.cancel();

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
