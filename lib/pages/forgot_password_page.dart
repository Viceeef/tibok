import 'package:flutter/material.dart';

import '../services/supabase_service.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({
    super.key,
  });

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _emailController = TextEditingController();

  bool _isLoading = false;
  bool _emailSent = false;

  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();

    super.dispose();
  }

  bool _looksLikeEmail(
    String value,
  ) {
    final email = value.trim();

    return email.contains('@') && email.contains('.') && email.length >= 5;
  }

  Future<void> _sendResetEmail() async {
    FocusManager.instance.primaryFocus?.unfocus();

    final email = _emailController.text.trim();

    if (!_looksLikeEmail(
      email,
    )) {
      setState(() {
        _errorMessage = 'Enter a valid email address.';
      });

      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await SupabaseService.sendPasswordResetEmail(
        email: email,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _emailSent = true;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = _friendlyError(
          e,
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _friendlyError(
    Object error,
  ) {
    final text = error.toString().toLowerCase();

    if (text.contains(
          'rate limit',
        ) ||
        text.contains(
          'email rate limit exceeded',
        )) {
      return 'Too many reset requests were sent. Wait a while before trying again.';
    }

    if (text.contains(
          'network',
        ) ||
        text.contains(
          'socket',
        )) {
      return 'Check your internet connection and try again.';
    }

    return 'The password reset email could not be sent. Please try again.';
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Forgot Password',
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.all(
            24,
          ),
          child: _emailSent ? _buildSuccessState() : _buildRequestForm(),
        ),
      ),
    );
  }

  Widget _buildRequestForm() {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(
          height: 24,
        ),
        Center(
          child: Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.lock_reset_rounded,
              color: colors.onPrimaryContainer,
              size: 42,
            ),
          ),
        ),
        const SizedBox(
          height: 22,
        ),
        Text(
          'Reset Your Password',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(
          height: 8,
        ),
        Text(
          'Enter the email address connected to your Tibok account.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(
          height: 28,
        ),
        TextField(
          controller: _emailController,
          enabled: !_isLoading,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          autofillHints: const [
            AutofillHints.email,
          ],
          decoration: const InputDecoration(
            labelText: 'Email Address',
            prefixIcon: Icon(
              Icons.email_outlined,
            ),
          ),
          onSubmitted: (_) {
            if (!_isLoading) {
              _sendResetEmail();
            }
          },
        ),
        if (_errorMessage != null) ...[
          const SizedBox(
            height: 14,
          ),
          _buildErrorBox(
            _errorMessage!,
          ),
        ],
        const SizedBox(
          height: 22,
        ),
        FilledButton.icon(
          onPressed: _isLoading ? null : _sendResetEmail,
          icon: _isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
              : const Icon(
                  Icons.send_outlined,
                ),
          label: Text(
            _isLoading ? 'Sending...' : 'Send Reset Email',
          ),
        ),
        const SizedBox(
          height: 10,
        ),
        TextButton(
          onPressed: _isLoading
              ? null
              : () {
                  Navigator.pop(
                    context,
                  );
                },
          child: const Text(
            'Back to Login',
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessState() {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(
          height: 30,
        ),
        Icon(
          Icons.mark_email_read_outlined,
          color: colors.primary,
          size: 72,
        ),
        const SizedBox(
          height: 20,
        ),
        Text(
          'Check Your Email',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(
          height: 10,
        ),
        Text(
          'If an account is associated with ${_emailController.text.trim()}, '
          'a password recovery email has been requested.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(
          height: 22,
        ),
        Container(
          padding: const EdgeInsets.all(
            16,
          ),
          decoration: BoxDecoration(
            color: colors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(
              16,
            ),
            border: Border.all(
              color: colors.outlineVariant,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline,
                color: colors.primary,
              ),
              const SizedBox(
                width: 11,
              ),
              const Expanded(
                child: Text(
                  'Open the recovery email and tap the Reset Password link. '
                  'Tibok will open so you can create a new password.',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(
          height: 24,
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(
              context,
            );
          },
          child: const Text(
            'Return to Login',
          ),
        ),
        const SizedBox(
          height: 8,
        ),
        TextButton(
          onPressed: _isLoading
              ? null
              : () {
                  setState(() {
                    _emailSent = false;
                    _errorMessage = null;
                  });
                },
          child: const Text(
            'Send Again',
          ),
        ),
      ],
    );
  }

  Widget _buildErrorBox(
    String message,
  ) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(
        12,
      ),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(
          12,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.error_outline,
            color: colors.onErrorContainer,
          ),
          const SizedBox(
            width: 10,
          ),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: colors.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
