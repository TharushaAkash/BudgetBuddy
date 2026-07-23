import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/finance_provider.dart';
import 'screens/biometric_lock_screen.dart';
import 'screens/root_shell.dart';
import 'utils/app_theme.dart';

import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().init();
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
    return ChangeNotifierProvider(
      create: (_) => FinanceProvider(),
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

