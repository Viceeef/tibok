import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import 'landing_page.dart';
import 'main_dashboard_page.dart';
import 'onboarding_health_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  Future<Widget> _getDestinationPage(User user) async {
    try {
      final profile = await SupabaseService.client
          .from('health_profiles')
          .select('id')
          .eq('user_id', user.id)
          .maybeSingle();

      if (profile != null) {
        return const MainDashboardPage();
      } else {
        return const OnboardingHealthPage();
      }
    } catch (e) {
      debugPrint('Session error/user deleted: $e');
      // Clear orphan token and return to LandingPage
      await SupabaseService.signOut();
      return const LandingPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: SupabaseService.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = SupabaseService.client.auth.currentSession;

        if (session == null) {
          return const LandingPage();
        }

        return FutureBuilder<Widget>(
          future: _getDestinationPage(session.user),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            return snapshot.data ?? const LandingPage();
          },
        );
      },
    );
  }
}
