import '../utils/password_policy.dart';

import 'package:flutter/material.dart';

import '../services/supabase_service.dart';
import 'onboarding_health_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({
    super.key,
  });

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _usernameController = TextEditingController();

  final TextEditingController _emailController = TextEditingController();

  final TextEditingController _passwordController = TextEditingController();

  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isLoading = false;

  bool _hidePassword = true;
  bool _hideConfirmPassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    super.dispose();
  }

  Future<void> _handleRegister() async {
    FocusManager.instance.primaryFocus?.unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await SupabaseService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        username: _usernameController.text.trim(),
      );

      if (!mounted) {
        return;
      }

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const OnboardingHealthPage(),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              _friendlyRegisterError(
                e,
              ),
            ),
          ),
        );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _friendlyRegisterError(
    Object error,
  ) {
    final text = error.toString().toLowerCase();

    if (text.contains(
          'already registered',
        ) ||
        text.contains(
          'already exists',
        )) {
      return 'An account with this email already exists.';
    }

    if (text.contains('password')) {
      return PasswordPolicy.requirements;
    }

    if (text.contains('network') || text.contains('socket')) {
      return 'Check your internet connection and try again.';
    }

    return 'Unable to create the account. Please try again.';
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Create Account',
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(
            24,
            14,
            24,
            32,
          ),
          child: Form(
            key: _formKey,
            child: AutofillGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: colors.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.person_add_alt_1_rounded,
                        size: 38,
                        color: colors.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 18,
                  ),
                  Text(
                    'Create Your Tibok Account',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(
                    height: 6,
                  ),
                  Text(
                    'Set up your account to begin tracking your health information.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(
                    height: 26,
                  ),
                  TextFormField(
                    controller: _usernameController,
                    enabled: !_isLoading,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [
                      AutofillHints.username,
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      prefixIcon: Icon(
                        Icons.person_outline,
                      ),
                    ),
                    validator: (
                      value,
                    ) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Enter username';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  TextFormField(
                    controller: _emailController,
                    enabled: !_isLoading,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [
                      AutofillHints.email,
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(
                        Icons.email_outlined,
                      ),
                    ),
                    validator: (
                      value,
                    ) {
                      final email = value?.trim() ?? '';

                      if (email.isEmpty) {
                        return 'Enter email';
                      }

                      if (!email.contains('@') || !email.contains('.')) {
                        return 'Enter a valid email';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  TextFormField(
                    controller: _passwordController,
                    enabled: !_isLoading,
                    obscureText: _hidePassword,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [
                      AutofillHints.newPassword,
                    ],
                    decoration: InputDecoration(
                      labelText: 'Password',
                      helperText: PasswordPolicy.requirements,
                      helperMaxLines: 3,
                      errorMaxLines: 3,
                      prefixIcon: const Icon(
                        Icons.lock_outline,
                      ),
                      suffixIcon: IconButton(
                        tooltip:
                            _hidePassword ? 'Show password' : 'Hide password',
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
                    ),
                    validator: (
                      value,
                    ) {
                      return PasswordPolicy.validate(value);
                    },
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  TextFormField(
                    controller: _confirmPasswordController,
                    enabled: !_isLoading,
                    obscureText: _hideConfirmPassword,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [
                      AutofillHints.newPassword,
                    ],
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      prefixIcon: const Icon(
                        Icons.lock_reset_outlined,
                      ),
                      suffixIcon: IconButton(
                        tooltip: _hideConfirmPassword
                            ? 'Show password'
                            : 'Hide password',
                        onPressed: _isLoading
                            ? null
                            : () {
                                setState(
                                  () {
                                    _hideConfirmPassword =
                                        !_hideConfirmPassword;
                                  },
                                );
                              },
                        icon: Icon(
                          _hideConfirmPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                    validator: (
                      value,
                    ) {
                      if (value == null || value.isEmpty) {
                        return 'Confirm password';
                      }

                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }

                      return null;
                    },
                    onFieldSubmitted: (_) {
                      if (!_isLoading) {
                        _handleRegister();
                      }
                    },
                  ),
                  const SizedBox(
                    height: 24,
                  ),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleRegister,
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Create Account',
                          ),
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
