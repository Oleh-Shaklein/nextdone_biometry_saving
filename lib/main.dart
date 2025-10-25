import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'services/task_service.dart';
import 'services/auth_service.dart';
import 'models/settings.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/registration_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/calendar/day_view_screen.dart';
import 'screens/task/task_details_screen.dart';
import 'screens/task/create_reminder_screen.dart';
import 'screens/task/create_checklist_screen.dart';
import 'screens/task/create_habit_screen.dart';
import 'screens/task/edit_reminder_screen.dart';
import 'screens/task/edit_checklist_screen.dart';
import 'screens/task/edit_habit_screen.dart';
import 'screens/archive/archive_screen.dart';
import 'screens/settings/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('uk_UA', null);

  // Create and initialize services before runApp to avoid race conditions
  final authService = AuthService();
  await authService.tryAutoLogin();
  if (kDebugMode) print('[main] authService instance hash=${authService.hashCode}, authenticated=${authService.isAuthenticated}');

  final settings = Settings();
  await settings.load();
  if (kDebugMode) print('[main] settings instance hash=${settings.hashCode} theme=${settings.theme} locale=${settings.locale}');

  final taskService = TaskService();
  await taskService.loadFromStorage();
  if (kDebugMode) print('[main] taskService instance hash=${taskService.hashCode}');

  runApp(
    MultiProvider(
      providers: [
        // Provide pre-initialized instances so there aren't duplicate instances
        ChangeNotifierProvider.value(value: authService),
        ChangeNotifierProvider.value(value: taskService),
        ChangeNotifierProvider.value(value: settings),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<Settings>(context);
    // We will always start at LoginScreen; LoginScreen will offer biometric quick-login.
    return MaterialApp(
      title: 'Tasker',
      theme: settings.theme == AppTheme.dark
          ? ThemeData.dark(useMaterial3: true)
          : ThemeData.light(useMaterial3: true),
      supportedLocales: const [
        Locale('en'),
        Locale('uk'),
      ],
      locale: settings.locale == AppLocale.uk ? const Locale('uk') : const Locale('en'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      initialRoute: LoginScreen.routeName,
      routes: {
        LoginScreen.routeName: (context) => const LoginScreen(),
        RegistrationScreen.routeName: (context) => const RegistrationScreen(),
        HomeScreen.routeName: (context) => const HomeScreen(),
        DayViewScreen.routeName: (context) => const DayViewScreen(),
        TaskDetailsScreen.routeName: (context) => const TaskDetailsScreen(),
        CreateReminderScreen.routeName: (context) => const CreateReminderScreen(),
        CreateChecklistScreen.routeName: (context) => const CreateChecklistScreen(),
        CreateHabitScreen.routeName: (context) => const CreateHabitScreen(),
        EditReminderScreen.routeName: (context) => const EditReminderScreen(),
        EditChecklistScreen.routeName: (context) => const EditChecklistScreen(),
        EditHabitScreen.routeName: (context) => const EditHabitScreen(),
        ArchiveScreen.routeName: (context) => const ArchiveScreen(),
        SettingsScreen.routeName: (context) => const SettingsScreen(),
      },
    );
  }
}