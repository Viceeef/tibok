import 'package:flutter/material.dart';
import 'pages/auth_gate.dart';
import 'services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await SupabaseService.initialize();
  } catch (e) {
    debugPrint('Supabase Initialization Error: $e');
  }

  runApp(const TibokApp());
}

class TibokApp extends StatelessWidget {
  const TibokApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tibok',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.red,
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}
