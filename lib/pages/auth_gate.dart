import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/supabase_service.dart';
import 'landing_page.dart';
import 'main_dashboard_page.dart';
import 'onboarding_health_page.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({
    super.key,
  });

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  String? _destinationUserId;
  Future<Widget>? _destination;

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
          _destinationUserId = null;
          _destination = null;
          return const LandingPage();
        }

        // Password verification/update emits auth events for the same user.
        // Keep their dashboard (and selected Profile tab) mounted throughout.
        if (_destinationUserId != session.user.id || _destination == null) {
          _destinationUserId = session.user.id;
          _destination = _getDestinationPage(session.user);
        }

        return FutureBuilder<Widget>(
          future: _destination,
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
