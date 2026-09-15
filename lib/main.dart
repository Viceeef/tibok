import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'pages/auth_gate.dart';
import 'pages/reset_password_page.dart';
import 'services/app_settings_service.dart';
import 'services/supabase_service.dart';
import 'theme/tibok_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await AppSettingsController.instance.load();
  } catch (e) {
    debugPrint(
      'App settings initialization error: $e',
    );
  }

  try {
    await SupabaseService.initialize();
  } catch (e) {
    debugPrint(
      'Supabase Initialization Error: $e',
    );
  }

  runApp(
    const TibokApp(),
  );
}

class TibokApp extends StatefulWidget {
  const TibokApp({
    super.key,
  });

  @override
  State<TibokApp> createState() => _TibokAppState();
}

class _TibokAppState extends State<TibokApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  StreamSubscription<AuthState>? _authSubscription;

  bool _showingRecoveryPage = false;

  @override
  void initState() {
    super.initState();

    _listenForAuthEvents();
  }

  void _listenForAuthEvents() {
    _authSubscription = SupabaseService.client.auth.onAuthStateChange.listen(
      (data) {
        debugPrint(
          'Tibok auth event: ${data.event}',
        );

        if (data.event == AuthChangeEvent.passwordRecovery) {
          _openPasswordRecoveryPage();
        }

        if (data.event == AuthChangeEvent.signedOut) {
          _showingRecoveryPage = false;
        }
      },
      onError: (
        Object error,
        StackTrace stackTrace,
      ) {
        debugPrint(
          'Auth state error: $error',
        );
      },
    );
  }

  void _openPasswordRecoveryPage() {
    if (_showingRecoveryPage) {
      return;
    }

    _showingRecoveryPage = true;

    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        if (!mounted) {
          return;
        }

        final navigator = _navigatorKey.currentState;

        if (navigator == null) {
          _showingRecoveryPage = false;
          return;
        }

        navigator.pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => const ResetPasswordPage(),
          ),
          (route) => false,
        );
      },
    );
  }

  @override
  void dispose() {
    _authSubscription?.cancel();

    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'Tibok',
      debugShowCheckedModeBanner: false,
      theme: TibokTheme.light,
      builder: (
        context,
        child,
      ) {
        return AnimatedBuilder(
          animation: AppSettingsController.instance,

          // Keep the Navigator/widget tree stable.
          child: child,

          builder: (
            context,
            stableChild,
          ) {
            final mediaQuery = MediaQuery.of(context);

            final settings = AppSettingsController.instance;

            final systemScale = mediaQuery.textScaler.scale(
              1.0,
            );

            final combinedScale = systemScale * settings.textScaleFactor;

            return MediaQuery(
              data: mediaQuery.copyWith(
                textScaler: TextScaler.linear(
                  combinedScale,
                ),
              ),
              child: stableChild ?? const SizedBox.shrink(),
            );
          },
        );
      },
      home: const AuthGate(),
    );
  }
}
