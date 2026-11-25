import '../ui.dart';

/// Membungkus isi halaman: tampilkan loading / error / kosong / isi.
class AsyncBody extends StatelessWidget {
  const AsyncBody({
    super.key,
    required this.loading,
    required this.error,
    required this.onRetry,
    required this.isEmpty,
    required this.child,
    this.emptyText = 'Belum ada data.',
  });

  final bool loading;
  final String? error;
  final VoidCallback onRetry;
  final bool isEmpty;
  final String emptyText;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (loading && isEmpty) return const Center(child: CircularProgressIndicator());
    if (error != null && isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 12),
            Text(error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.icon(
                onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Coba lagi')),
          ]),
        ),
      );
    }
    if (isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.inbox_outlined, size: 48, color: Theme.of(context).disabledColor),
            const SizedBox(height: 8),
            Text(emptyText, textAlign: TextAlign.center),
          ]),
        ),
      );
    }
    return Stack(children: [
      child,
      if (loading)
        const Positioned(top: 0, left: 0, right: 0, child: LinearProgressIndicator()),
    ]);
  }
}

/// Banner pesan error kecil di dalam form.
class ErrorBanner extends StatelessWidget {
  const ErrorBanner(this.pesan, {super.key});

  final String? pesan;

  @override
  Widget build(BuildContext context) {
    if (pesan == null) return const SizedBox.shrink();
    final c = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: c.errorContainer, borderRadius: BorderRadius.circular(8)),
      child: Row(children: [
        Icon(Icons.error_outline, color: c.onErrorContainer, size: 20),
        const SizedBox(width: 8),
        Expanded(child: Text(pesan!, style: TextStyle(color: c.onErrorContainer))),
      ]),
    );
  }
}
