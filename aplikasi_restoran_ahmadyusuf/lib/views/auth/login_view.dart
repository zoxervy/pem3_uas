import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../ui.dart';
import '../../widgets/state_views.dart';

/// Halaman 1: login. Setelah berhasil, AuthGate otomatis menampilkan
/// dashboard sesuai role.
class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _lihat = false;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _masuk() async {
    await context.read<AuthController>().login(_username.text, _password.text);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final tema = Theme.of(context);
    return Scaffold(
      backgroundColor: tema.colorScheme.surfaceContainerLow,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: AutofillGroup(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.restaurant, size: 56, color: tema.colorScheme.primary),
                    const SizedBox(height: 8),
                    Text('Aplikasi Restoran',
                        style: tema.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('Silakan login untuk melanjutkan', style: TextStyle(color: tema.hintColor)),
                    const SizedBox(height: 20),
                    ErrorBanner(auth.error),
                    TextField(
                      controller: _username,
                      enabled: !auth.loading,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.username],
                      decoration: const InputDecoration(
                          labelText: 'Username', prefixIcon: Icon(Icons.person_outline)),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _password,
                      enabled: !auth.loading,
                      obscureText: !_lihat,
                      autofillHints: const [AutofillHints.password],
                      onSubmitted: (_) => _masuk(),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          tooltip: _lihat ? 'Sembunyikan password' : 'Tampilkan password',
                          icon: Icon(_lihat ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _lihat = !_lihat),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton(
                        onPressed: auth.loading ? null : _masuk,
                        child: auth.loading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Masuk'),
                      ),
                    ),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
