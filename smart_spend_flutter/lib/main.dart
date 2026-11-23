import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/constants.dart';
import 'providers/app_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard/dashboard_shell.dart';
import 'screens/quick_add/quick_add_screen.dart';
import 'screens/quick_add/quick_add_debt_screen.dart';
import 'services/storage_service.dart';
import 'services/sync_service.dart';
import 'services/widget_sync_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize essential storage, orientation, and Supabase client concurrently
  await Future.wait([
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]),
    StorageService().init(),
    _initSupabase(),
  ]);

  // Non-blocking background sync and widget service init
  unawaited(SyncService().init());
  WidgetSyncService().init();

  runApp(const SmartSpendApp());
}

Future<void> _initSupabase() async {
  try {
    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      publishableKey: AppConstants.supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
  } catch (e) {
    debugPrint('[Main] Supabase initialization warning (e.g. offline): $e');
  }
}

class SmartSpendApp extends StatelessWidget {
  const SmartSpendApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AppProvider()),
      ],
      child: Consumer<AppProvider>(
        builder: (context, appProvider, _) {
          return MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode:
                appProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: const RootGatekeeper(),
            onGenerateRoute: (settings) {
              final uri = Uri.parse(settings.name ?? '/');
              final path = uri.path;
              if (path == '/quick-add' || path.contains('quick-add')) {
                final type = uri.queryParameters['type'] ?? 'EXPENSE';
                return PageRouteBuilder(
                  opaque: false,
                  barrierColor: Colors.black45,
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      QuickAddScreen(initialType: type),
                );
              }
              if (path == '/quick-add-debt' || path.contains('quick-add-debt')) {
                final type = uri.queryParameters['type'] ?? 'LENT';
                return PageRouteBuilder(
                  opaque: false,
                  barrierColor: Colors.black45,
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      QuickAddDebtScreen(initialType: type),
                );
              }
              return MaterialPageRoute(
                builder: (_) => const RootGatekeeper(),
              );
            },
          );
        },
      ),
    );
  }
}

class RootGatekeeper extends StatelessWidget {
  const RootGatekeeper({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // Seamlessly launch directly into Dashboard if user session or cached profile exists!
    if (auth.isAuthenticated) {
      return const DashboardShell();
    }
    return const LoginScreen();
  }
}
