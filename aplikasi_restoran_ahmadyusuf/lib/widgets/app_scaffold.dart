import '../ui.dart';
import 'app_drawer.dart';

/// Kerangka halaman utama (punya menu samping). Isi dibatasi lebarnya
/// supaya tetap enak dibaca di layar lebar.
class HalamanScaffold extends StatelessWidget {
  const HalamanScaffold({
    super.key,
    required this.judul,
    required this.body,
    this.aksi,
    this.fab,
    this.maxLebar = 1000,
  });

  final String judul;
  final Widget body;
  final List<Widget>? aksi;
  final Widget? fab;
  final double maxLebar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(judul), actions: aksi),
      drawer: const AppDrawer(),
      floatingActionButton: fab,
      body: Center(
        child: ConstrainedBox(constraints: BoxConstraints(maxWidth: maxLebar), child: body),
      ),
    );
  }
}
