import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/biometric_service.dart';
import '../home/home_screen.dart';
import 'registration_screen.dart';

class LoginScreen extends StatefulWidget {
  static const routeName = '/login';
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final BiometricService _biometricService = BiometricService();
  String _email = '';
  String _password = '';
  String? _error;
  bool _biometricAvailable = false;
  bool _hasToken = false;
  bool _checkingBiometric = true;

  // NEW: control to temporarily show password
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _initBiometricState();
  }

  Future<void> _initBiometricState() async {
    try {
      final can = await _biometricService.canCheckBiometrics();
      final token = await _biometricService.readToken();
      if (!mounted) return;
      setState(() {
        _biometricAvailable = can;
        _hasToken = token != null;
        _checkingBiometric = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _biometricAvailable = false;
        _hasToken = false;
        _checkingBiometric = false;
      });
    }
  }

  // NEW: temporarily reveal password for 1 second
  void _showPasswordTemporary() async {
    if (!_obscurePassword) return;
    setState(() => _obscurePassword = false);
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() => _obscurePassword = true);
  }

  Future<void> _login() async {
    setState(() => _error = null);
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      bool ok = await Provider.of<AuthService>(context, listen: false).login(_email, _password);
      if (ok) {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, HomeScreen.routeName);
      } else {
        if (!mounted) return;
        setState(() => _error = "Неправильний email або пароль");
      }
    }
  }

  Future<void> _onBiometricPressed() async {
    setState(() => _error = null);

    final can = await _biometricService.canCheckBiometrics();
    if (!can) {
      if (!mounted) return;
      setState(() => _error = 'Біометрія недоступна на цьому пристрої');
      return;
    }

    final didAuth = await _biometricService.authenticate(reason: 'Підтвердіть вхід біометрією');
    if (!didAuth) {
      if (!mounted) return;
      setState(() => _error = 'Біометрична автентифікація не вдалася або була скасована');
      return;
    }

    final token = await _biometricService.readToken();
    if (token != null) {
      final authOk = await Provider.of<AuthService>(context, listen: false).loginWithToken(token);
      if (authOk) {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, HomeScreen.routeName);
      } else {
        if (!mounted) return;
        setState(() => _error = 'Помилка відновлення сесії з токеном. Спробуйте увійти через email/пароль.');
      }
    } else {
      if (!mounted) return;
      final doAction = await showDialog<_BiometricNoTokenAction>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Біометрія доступна, але не увімкнена'),
          content: const Text(
            'На цьому пристрої ще не збережено токен для біометричного входу. '
                'Щоб увімкнути біометрію, потрібно спочатку зареєструватися або увійти через email/пароль і дозволити збереження токену.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(_BiometricNoTokenAction.cancel), child: const Text('Закрити')),
            TextButton(onPressed: () => Navigator.of(ctx).pop(_BiometricNoTokenAction.register), child: const Text('Зареєструватися')),
            TextButton(onPressed: () => Navigator.of(ctx).pop(_BiometricNoTokenAction.login), child: const Text('Увійти')),
          ],
        ),
      );

      if (!mounted) return;
      if (doAction == _BiometricNoTokenAction.register) {
        Navigator.pushNamed(context, RegistrationScreen.routeName);
      } else if (doAction == _BiometricNoTokenAction.login) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Введіть email і пароль, щоб увімкнути біометрію.')));
      }
    }

    final tokenNow = await _biometricService.readToken();
    if (!mounted) return;
    setState(() {
      _hasToken = tokenNow != null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Вхід')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            children: [
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(_error!, style: const TextStyle(color: Colors.red)),
                ),
              Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Email'),
                      onSaved: (val) => _email = val!.trim(),
                      validator: (val) =>
                      val == null || val.isEmpty || !val.contains('@') || !val.contains('.') ? "Введіть коректний email" : null,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Пароль',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.remove_red_eye),
                          tooltip: 'Показати пароль на 1 секунду',
                          onPressed: _showPasswordTemporary,
                        ),
                      ),
                      obscureText: _obscurePassword,
                      onSaved: (val) => _password = val!.trim(),
                      validator: (val) => val == null || val.length < 6 ? "Мінімум 6 символів" : null,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _login,
                      child: const Text("Увійти"),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, RegistrationScreen.routeName),
                      child: const Text("Реєстрація"),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Biometric area
              Card(
                elevation: 0,
                color: Colors.transparent,
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.fingerprint),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _checkingBiometric
                              ? const Text('Перевірка можливості біометрії...')
                              : _biometricAvailable
                              ? Text(_hasToken ? 'Біометричний вхід готовий' : 'Біометрія доступна (не налаштована)')
                              : const Text('Біометрія недоступна на цьому пристрої'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.fingerprint),
                      label: Text(_hasToken ? 'Увійти біометрією' : 'Перевірити біометрію / Увімкнути'),
                      onPressed: _biometricAvailable ? _onBiometricPressed : null,
                    ),
                    if (_biometricAvailable && !_hasToken)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Після реєстрації або першого входу ви зможете зберегти токен для швидкого біометричного входу.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _BiometricNoTokenAction { cancel, register, login }