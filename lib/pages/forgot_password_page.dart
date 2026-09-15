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

  bool _looksLikeEmail(String value) {
    final email = value.trim();

    return email.contains('@') && email.contains('.') && email.length >= 5;
  }

  Future<void> _sendResetEmail() async {
    final email = _emailController.text.trim();

    if (!_looksLikeEmail(email)) {
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
        _errorMessage = _friendlyError(e);
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
      return 'Unable to reach Supabase. Check your internet connection.';
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
          padding: const EdgeInsets.all(
            24,
          ),
          child: _emailSent ? _buildSuccessState() : _buildRequestForm(),
        ),
      ),
    );
  }

  Widget _buildRequestForm() {
    return Column(
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
              color: Colors.redAccent,
              size: 42,
            ),
          ),
        ),
        const SizedBox(
          height: 24,
        ),
        const Text(
          'Reset Your Password',
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
          'Enter the email address associated with your Tibok account. '
          'Supabase will send you a password recovery email.',
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
            border: OutlineInputBorder(),
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
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              vertical: 16,
            ),
          ),
        ),
        const SizedBox(
          height: 12,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(
          height: 36,
        ),
        const Icon(
          Icons.mark_email_read_outlined,
          color: Colors.green,
          size: 72,
        ),
        const SizedBox(
          height: 22,
        ),
        const Text(
          'Check Your Email',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(
          height: 10,
        ),
        Text(
          'If an account is associated with '
          '${_emailController.text.trim()}, '
          'a password recovery email has been requested.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey.shade700,
            height: 1.5,
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
            color: Colors.blueGrey.withValues(
              alpha: 0.08,
            ),
            borderRadius: BorderRadius.circular(
              14,
            ),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline,
              ),
              SizedBox(
                width: 12,
              ),
              Expanded(
                child: Text(
                  'Open the email from Supabase and use the Reset Password link. '
                  'We will test where that link opens before connecting it '
                  'directly back to the Tibok Android app.',
                  style: TextStyle(
                    height: 1.4,
                  ),
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
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              vertical: 16,
            ),
          ),
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
}
