import '../routes.dart';
import '../ui.dart';

/// Memanggil [onRefresh] setiap kali pengguna kembali ke halaman ini
/// (mis. dari halaman buat pesanan), supaya data selalu terbaru.
class RefreshOnReturn extends StatefulWidget {
  const RefreshOnReturn({super.key, required this.onRefresh, required this.child});

  final VoidCallback onRefresh;
  final Widget child;

  @override
  State<RefreshOnReturn> createState() => _RefreshOnReturnState();
}

class _RefreshOnReturnState extends State<RefreshOnReturn> with RouteAware {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) routeObserver.subscribe(this, route);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() => widget.onRefresh();

  @override
  Widget build(BuildContext context) => widget.child;
}
