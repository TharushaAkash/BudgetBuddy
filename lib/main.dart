import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'providers/finance_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/language_provider.dart';
import 'screens/biometric_lock_screen.dart';
import 'screens/root_shell.dart';
import 'utils/app_theme.dart';
import 'services/notification_service.dart';
import 'services/backup_service.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == "dailyBackupTask") {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now().toIso8601String().split('T')[0];
      final lastBackup = prefs.getString('last_daily_backup') ?? '';
      
      if (lastBackup != today) {
        final authProvider = AuthProvider();
        await Future.delayed(const Duration(seconds: 3)); // Wait for silent sign in
        
        if (authProvider.isSignedIn) {
          final client = await authProvider.getAuthenticatedClient();
          if (client != null) {
            final success = await BackupService.performBackup(client);
            if (success) {
              await prefs.setString('last_daily_backup', today);
            }
          }
        }
      }
    }
    return Future.value(true);
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().init();
  
  Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: false,
  );
  Workmanager().registerPeriodicTask(
    "daily-backup-id",
    "dailyBackupTask",
    frequency: const Duration(hours: 24),
    constraints: Constraints(
      networkType: NetworkType.connected,
      requiresBatteryNotLow: true,
    ),
  );

  runApp(const FinanceTrackerApp());
}

class FinanceTrackerApp extends StatefulWidget {
  const FinanceTrackerApp({super.key});

  @override
  State<FinanceTrackerApp> createState() => _FinanceTrackerAppState();
}

class _FinanceTrackerAppState extends State<FinanceTrackerApp> with WidgetsBindingObserver {
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      if (_isAuthenticated) {
        setState(() {
          _isAuthenticated = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FinanceProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ],
      child: Consumer<FinanceProvider>(
        builder: (context, provider, _) {
          Widget home;

          if (!provider.isLoaded) {
            home = const Scaffold(body: Center(child: CircularProgressIndicator()));
          } else if (provider.isBiometricEnabled && !_isAuthenticated) {
            home = BiometricLockScreen(
              onUnlocked: () {
                setState(() => _isAuthenticated = true);
              },
            );
          } else {
            home = const RootShell();
          }

          return MaterialApp(
            title: 'BudgetBuddy',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: provider.themeMode,
            home: home,
          );
        },
      ),
    );
  }
}

