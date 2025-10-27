import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/biometric_service.dart';
import '../services/auth_service.dart';

class ShowPasswordButton extends StatelessWidget {
  const ShowPasswordButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Показати пароль (1 сек.)',
      icon: const Icon(Icons.remove_red_eye),
      onPressed: () async {
        final auth = Provider.of<AuthService>(context, listen: false);
        final bio = BiometricService();

        // First, require biometric auth for security
        final can = await bio.canCheckBiometrics();
        if (!can) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Біометрія недоступна на цьому пристрої')));
          return;
        }

        final ok = await bio.authenticate(reason: 'Підтвердіть, щоб побачити пароль');
        if (!ok) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Біометрична автентифікація не пройдена')));
          return;
        }

        final pwd = await auth.readSavedPlainPassword();
        if (pwd == null) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Пароль не збережено або опція не активована')));
          return;
        }

        final snack = SnackBar(
          content: Text('Пароль: $pwd'),
          duration: const Duration(seconds: 1),
        );
        ScaffoldMessenger.of(context).showSnackBar(snack);
      },
    );
  }
}