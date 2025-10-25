import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/biometric_service.dart';

class RegistrationScreen extends StatefulWidget {
  static const routeName = '/registration';

  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final BiometricService _biometricService = BiometricService();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _error;
  bool _busy = false;

  void _showPasswordTemporary() async {
    setState(() {
      _obscurePassword = false;
      _obscureConfirm = false;
    });
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() {
      _obscurePassword = true;
      _obscureConfirm = true;
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _error = null;
      _busy = true;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // register returns a token string on success, null on failure
    final String? token = await Provider.of<AuthService>(context, listen: false).register(email, password);

    if (!mounted) return;
    if (token != null) {
      // Offer to enable biometrics immediately (only if device supports it)
      final bool canBiometric = await _biometricService.canCheckBiometrics();
      if (!mounted) return;

      if (canBiometric) {
        final enable = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Увімкнути біометричний вхід?'),
            content: const Text(
              'Ви можете зберегти захищений токен на цьому пристрої і входити швидко за допомогою біометрії. '
                  'Це зручно тільки на вашому приватному пристрої.',
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Ні')),
              TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Так')),
            ],
          ),
        );

        if (!mounted) return;
        if (enable == true) {
          // confirm biometric right now to secure token
          final confirmed = await _biometricService.authenticate(reason: 'Підтвердіть, щоб увімкнути біометрію');
          if (!mounted) return;
          if (confirmed) {
            await _biometricService.storeToken(token);
            // also update AuthService internal state
            Provider.of<AuthService>(context, listen: false).enableBiometricsForCurrentUser(token);
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Біометрія увімкнена. Тепер можна входити швидко.')));
          } else {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Не вдалося підтвердити біометрію.')));
          }
        }
      }

      // After registration go to login (or you might auto-login — here we go to login for clarity)
      if (!mounted) return;
      setState(() => _busy = false);
      Navigator.pushReplacementNamed(context, '/login');
    } else {
      setState(() {
        _error = "Користувач вже існує або некоректні дані.";
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Реєстрація')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Екран реєстрації',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 32),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(_error!, style: const TextStyle(color: Colors.red)),
                  ),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty || !value.contains('@') || !value.contains('.')) {
                      return 'Введіть коректний email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Пароль',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.visibility),
                      tooltip: 'Показати пароль на 2 секунди',
                      onPressed: _showPasswordTemporary,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.length < 6) {
                      return 'Мінімальна довжина паролю — 6 символів';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmController,
                  obscureText: _obscureConfirm,
                  decoration: InputDecoration(
                    labelText: 'Підтвердження паролю',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.visibility),
                      tooltip: 'Показати пароль на 2 секунди',
                      onPressed: _showPasswordTemporary,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.length < 6) {
                      return 'Мінімальна довжина паролю — 6 символів';
                    }
                    if (value != _passwordController.text) {
                      return 'Паролі не співпадають';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _busy ? null : _submit,
                    child: _busy ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Зареєструватися'),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Назад'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}