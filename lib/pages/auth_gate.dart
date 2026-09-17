import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/supabase_service.dart';
import 'landing_page.dart';
import 'main_dashboard_page.dart';
import 'onboarding_health_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({
    super.key,
  });

  Future<Widget> _getDestinationPage(
    User user,
  ) async {
    try {
      final profile = await SupabaseService.client
          .from('health_profile')
          .select('id')
          .eq(
            'user_id',
            user.id,
          )
          .maybeSingle();

      if (profile != null) {
        return const MainDashboardPage();
      }

      return const OnboardingHealthPage();
    } catch (e) {
      debugPrint(
        'Session validation failed: $e',
      );

      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 56,
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  const Text(
                    'Unable to load your Tibok account.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  const Text(
                    'Please check your connection and reopen the app.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return StreamBuilder<AuthState>(
      stream: SupabaseService.client.auth.onAuthStateChange,
      builder: (
        context,
        snapshot,
      ) {
        final session = SupabaseService.client.auth.currentSession;

        if (session == null) {
          return const LandingPage();
        }

        return FutureBuilder<Widget>(
          future: _getDestinationPage(
            session.user,
          ),
          builder: (
            context,
            destinationSnapshot,
          ) {
            if (destinationSnapshot.connectionState ==
                ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            return destinationSnapshot.data ?? const LandingPage();
          },
        );
      },
    );
  }
}
