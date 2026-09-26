import 'package:flutter/material.dart';

import '../services/supabase_service.dart';
import '../utils/password_policy.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentPassword = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmation = TextEditingController();
  final _hidden = [true, true, true];
  bool _saving = false;
  bool _success = false;
  String? _error;

  @override
  void dispose() {
    _currentPassword.dispose();
    _newPassword.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  String _friendlyError(Object error) {
    final message = error.toString().toLowerCase();
    if (message.contains('invalid login credentials') ||
        message.contains('invalid_credentials') ||
        message.contains('current password is incorrect')) {
      return 'Your current password is incorrect. Please try again.';
    }
    if (message.contains('same_password') ||
        message.contains('different from')) {
      return 'Choose a new password different from your current password.';
    }
    if (message.contains('weak_password') ||
        message.contains('password should') ||
        message.contains('password is too weak')) {
      return 'Choose a stronger password. ${PasswordPolicy.requirements}';
    }
    if (message.contains('reauthentication') || message.contains('nonce')) {
      return 'Please log out, log in again, and retry the password change.';
    }
    if (message.contains('rate limit') || message.contains('too many')) {
      return 'Too many attempts. Please wait a little before trying again.';
    }
    if (message.contains('logged in') ||
        message.contains('session') ||
        message.contains('account verification failed')) {
      return 'Please log in again before changing your password.';
    }
    if (message.contains('network') ||
        message.contains('socket') ||
        message.contains('fetch') ||
        message.contains('timeout')) {
      return 'Could not confirm the password change. Check your connection. '
          'If you retry and the old password no longer works, try logging in '
          'with your new password.';
    }
    return 'Could not change your password. Please try again. '
        'You can also use Forgot Password on the login screen.';
  }

  Future<void> _save() async {
    if (_saving || _success || !_formKey.currentState!.validate()) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await SupabaseService.changePassword(
        currentPassword: _currentPassword.text,
        newPassword: _newPassword.text,
      );
      if (!mounted) return;
      _currentPassword.clear();
      _newPassword.clear();
      _confirmation.clear();
      setState(() => _success = true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = _friendlyError(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    required int index,
    required String? Function(String?) validator,
    String? helper,
  }) {
    return TextFormField(
      controller: controller,
      enabled: !_saving,
      obscureText: _hidden[index],
      autocorrect: false,
      enableSuggestions: false,
      keyboardType: TextInputType.visiblePassword,
      textInputAction: index == 2 ? TextInputAction.done : TextInputAction.next,
      onFieldSubmitted: index == 2 ? (_) => _save() : null,
      autofillHints: [
        index == 0 ? AutofillHints.password : AutofillHints.newPassword,
      ],
      decoration: InputDecoration(
        labelText: label,
        helperText: helper,
        helperMaxLines: 4,
        errorMaxLines: 4,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          tooltip: _hidden[index] ? 'Show password' : 'Hide password',
          onPressed: _saving
              ? null
              : () => setState(() => _hidden[index] = !_hidden[index]),
          icon: Icon(_hidden[index]
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined),
        ),
      ),
      validator: validator,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_saving,
      child: Scaffold(
        appBar: AppBar(title: const Text('Change Password')),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: _success
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(Icons.check_circle_outline,
                          size: 56,
                          color: Theme.of(context).colorScheme.primary),
                      const SizedBox(height: 16),
                      Text('Password updated',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      const Text(
                        'Use your new password the next time you log in.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Back to Profile'),
                      ),
                    ],
                  )
                : AutofillGroup(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Enter your current password, then choose a new one.',
                          ),
                          const SizedBox(height: 24),
                          _passwordField(
                            controller: _currentPassword,
                            label: 'Current Password',
                            index: 0,
                            validator: (value) => value == null || value.isEmpty
                                ? 'Enter your current password.'
                                : null,
                          ),
                          const SizedBox(height: 20),
                          _passwordField(
                            controller: _newPassword,
                            label: 'New Password',
                            index: 1,
                            helper: PasswordPolicy.requirements,
                            validator: (value) {
                              final error = PasswordPolicy.validate(value);
                              if (error != null) return error;
                              if (value == _currentPassword.text) {
                                return 'Choose a different password.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          _passwordField(
                            controller: _confirmation,
                            label: 'Confirm New Password',
                            index: 2,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Confirm your new password.';
                              }
                              return value == _newPassword.text
                                  ? null
                                  : 'The passwords do not match.';
                            },
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 16),
                            Semantics(
                              liveRegion: true,
                              child: Text(_error!,
                                  style: TextStyle(
                                      color: Theme.of(context).colorScheme.error)),
                            ),
                          ],
                          const SizedBox(height: 24),
                          FilledButton.icon(
                            onPressed: _saving ? null : _save,
                            icon: _saving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.lock_reset),
                            label: Text(_saving ? 'Updating...' : 'Update Password'),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
