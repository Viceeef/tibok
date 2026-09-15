import 'package:flutter/material.dart';

import '../services/supabase_service.dart';
import 'auth_gate.dart';
import 'login_page.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({
    super.key,
  });

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final TextEditingController _newPasswordController = TextEditingController();

  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isLoading = false;
  bool _hidePassword = true;
  bool _hideConfirmPassword = true;

  String? _errorMessage;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    final newPassword = _newPasswordController.text;

    final confirmPassword = _confirmPasswordController.text;

    if (newPassword.length < 8) {
      setState(() {
        _errorMessage = 'Password must contain at least 8 characters.';
      });

      return;
    }

    if (newPassword != confirmPassword) {
      setState(() {
        _errorMessage = 'The passwords do not match.';
      });

      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      //
      // Change the password using the authenticated
      // recovery session.
      //
      await SupabaseService.updateRecoveredPassword(
        newPassword: newPassword,
      );

      //
      // End the temporary recovery session.
      //
      await SupabaseService.signOut();

      if (!mounted) {
        return;
      }

      //
      // IMPORTANT:
      //
      // Restore AuthGate as the ROOT route.
      //
      // LoginPage expects AuthGate to exist underneath it.
      // After a successful login, LoginPage pops back to
      // the first route. AuthGate will then detect the
      // authenticated session and show the dashboard.
      //
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const AuthGate(),
        ),
        (route) => false,
      );

      //
      // Wait for AuthGate to become the root route.
      //
      await Future<void>.delayed(
        const Duration(
          milliseconds: 150,
        ),
      );

      if (!mounted) {
        return;
      }

      //
      // Put LoginPage above AuthGate.
      //
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const LoginPage(),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = _friendlyError(e);
      });
    }
  }

  String _friendlyError(
    Object error,
  ) {
    final text = error.toString().toLowerCase();

    if (text.contains('session') ||
        text.contains('jwt') ||
        text.contains('expired')) {
      return 'The recovery link is invalid or has expired. '
          'Please request a new password reset email.';
    }

    if (text.contains('weak') || text.contains('password should')) {
      return 'The password does not meet the account password requirements.';
    }

    if (text.contains('same password')) {
      return 'Choose a password different from your previous password.';
    }

    return 'The password could not be updated. '
        'Please request a new recovery email and try again.';
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text(
            'Reset Password',
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(
              24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(
                  height: 30,
                ),
                Center(
                  child: Container(
                    width: 82,
                    height: 82,
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(
                        alpha: 0.10,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_reset,
                      size: 42,
                      color: Colors.redAccent,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 24,
                ),
                const Text(
                  'Create New Password',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(
                  height: 8,
                ),
                Text(
                  'Your recovery link has been verified. '
                  'Choose a new password for your Tibok account.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(
                  height: 30,
                ),
                TextField(
                  controller: _newPasswordController,
                  enabled: !_isLoading,
                  obscureText: _hidePassword,
                  autofillHints: const [
                    AutofillHints.newPassword,
                  ],
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    prefixIcon: const Icon(
                      Icons.lock_outline,
                    ),
                    suffixIcon: IconButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              setState(
                                () {
                                  _hidePassword = !_hidePassword;
                                },
                              );
                            },
                      icon: Icon(
                        _hidePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(
                  height: 14,
                ),
                TextField(
                  controller: _confirmPasswordController,
                  enabled: !_isLoading,
                  obscureText: _hideConfirmPassword,
                  autofillHints: const [
                    AutofillHints.newPassword,
                  ],
                  decoration: InputDecoration(
                    labelText: 'Confirm New Password',
                    prefixIcon: const Icon(
                      Icons.lock_outline,
                    ),
                    suffixIcon: IconButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              setState(
                                () {
                                  _hideConfirmPassword = !_hideConfirmPassword;
                                },
                              );
                            },
                      icon: Icon(
                        _hideConfirmPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(
                  height: 8,
                ),
                Text(
                  'Use at least 8 characters.',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(
                    height: 14,
                  ),
                  Container(
                    padding: const EdgeInsets.all(
                      12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(
                        alpha: 0.08,
                      ),
                      borderRadius: BorderRadius.circular(
                        10,
                      ),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
                const SizedBox(
                  height: 24,
                ),
                FilledButton.icon(
                  onPressed: _isLoading ? null : _changePassword,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
                          Icons.check,
                        ),
                  label: Text(
                    _isLoading ? 'Updating...' : 'Set New Password',
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
