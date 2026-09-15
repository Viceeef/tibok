import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'pages/auth_gate.dart';
import 'pages/reset_password_page.dart';
import 'services/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

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
      scaffoldMessengerKey: _scaffoldMessengerKey,
      title: 'Tibok',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.redAccent,
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}
