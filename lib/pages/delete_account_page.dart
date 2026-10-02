import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/supabase_service.dart';
import 'auth_gate.dart';

class DeleteAccountPage extends StatefulWidget {
  const DeleteAccountPage({super.key});

  @override
  State<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends State<DeleteAccountPage> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _busy = false;
  bool _deleted = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    if (!_deleted && !_formKey.currentState!.validate()) return;
    FocusManager.instance.primaryFocus?.unfocus();
    final navigator = Navigator.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      if (!_deleted) {
        if (SupabaseService.client.auth.currentSession == null) {
          throw StateError('No active session');
        }
        final result = await SupabaseService.client.functions.invoke(
          'tibok-delete-account',
          body: {
            'confirmation': 'DELETE',
            'password': _password.text,
          },
        );
        if (result.status != 200 ||
            result.data is! Map ||
            result.data['deleted'] != true) {
          throw StateError('Deletion was not confirmed');
        }
        _deleted = true;
        _password.clear();
        _confirmation.clear();
      }

      // Only clear this device after the server confirms account deletion.
      // The server deletes the Auth user; its FK cascades remove personal logs.
      await SupabaseService.client.auth.signOut(scope: SignOutScope.local);
      if (navigator.mounted) {
        navigator.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthGate()),
          (route) => false,
        );
      }
    } on FunctionException catch (e) {
      if (!mounted) return;
      final details = e.details;
      final code = details is Map ? details['code'] : null;
      setState(() {
        _error = code == 'invalid_password'
            ? 'Your current password is incorrect. Please try again.'
            : code == 'unauthorized'
                ? 'Your session has expired. Sign in again before deleting your account.'
                : code == 'verification_unavailable'
                    ? 'Password verification is temporarily unavailable. Try again later.'
                    : 'Account deletion could not be confirmed. Check your connection. '
                        'If it continues, contact the Tibok team before retrying.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = _deleted
            ? 'Your account was deleted, but this device could not finish signing out. '
                'Tap Finish Sign Out to retry.'
            : 'Account deletion could not be confirmed. Check your connection. '
                'If it continues, contact the Tibok team before retrying.';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_busy && !_deleted,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Delete Account'),
          automaticallyImplyLeading: !_busy && !_deleted,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _deleted ? 'Account deleted' : 'Permanently delete your account?',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'This removes your Tibok account, profile, health profile, '
                    'blood-pressure readings, food logs, and saved bookmarks '
                    'from the app database. This cannot be undone.',
                  ),
                  if (!_deleted) ...[
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _password,
                      enabled: !_busy,
                      obscureText: true,
                      autocorrect: false,
                      enableSuggestions: false,
                      decoration: const InputDecoration(labelText: 'Current password'),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Enter your current password'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmation,
                      enabled: !_busy,
                      autocorrect: false,
                      decoration: const InputDecoration(labelText: 'Type DELETE to confirm'),
                      validator: (value) => value?.trim() == 'DELETE'
                          ? null
                          : 'Type DELETE exactly to confirm',
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _busy ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error,
                      foregroundColor: Theme.of(context).colorScheme.onError,
                    ),
                    child: Text(_busy
                        ? 'Please wait...'
                        : _deleted ? 'Finish Sign Out' : 'Permanently Delete Account'),
                  ),
                  if (!_deleted)
                    TextButton(
                      onPressed: _busy ? null : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
