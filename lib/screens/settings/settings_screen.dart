import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/settings.dart';

class SettingsScreen extends StatelessWidget {
  static const routeName = '/settings';

  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<Settings>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Налаштування')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Мова'),
            trailing: DropdownButton<AppLocale>(
              value: settings.locale,
              items: const [
                DropdownMenuItem(value: AppLocale.uk, child: Text('Українська')),
                DropdownMenuItem(value: AppLocale.en, child: Text('English')),
              ],
              onChanged: (value) {
                if (value != null) settings.setLocale(value);
              },
            ),
          ),
          ListTile(
            title: const Text('Тема'),
            trailing: DropdownButton<AppTheme>(
              value: settings.theme,
              items: const [
                DropdownMenuItem(value: AppTheme.light, child: Text('Світла')),
                DropdownMenuItem(value: AppTheme.dark, child: Text('Темна')),
              ],
              onChanged: (value) {
                if (value != null) settings.setTheme(value);
              },
            ),
          ),
        ],
      ),
    );
  }
}