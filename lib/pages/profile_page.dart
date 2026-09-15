import 'package:flutter/material.dart';

import '../services/supabase_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isLoading = true;

  String? _errorMessage;

  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _healthProfile;

  @override
  void initState() {
    super.initState();

    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final user = SupabaseService.currentUser;

      if (user == null) {
        throw Exception(
          'You must be logged in.',
        );
      }

      final profileResponse = await SupabaseService.client
          .from('profiles')
          .select()
          .eq(
            'id',
            user.id,
          )
          .maybeSingle();

      final healthProfile = await SupabaseService.getHealthProfile();

      if (!mounted) {
        return;
      }

      setState(() {
        _profile = profileResponse;
        _healthProfile = healthProfile;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  String get _username {
    final username = _profile?['username']?.toString().trim();

    if (username != null && username.isNotEmpty) {
      return username;
    }

    return 'Tibok User';
  }

  String get _email {
    final profileEmail = _profile?['email']?.toString().trim();

    if (profileEmail != null && profileEmail.isNotEmpty) {
      return profileEmail;
    }

    return SupabaseService.currentUser?.email ?? 'No email available';
  }

  String get _initial {
    final name = _username.trim();

    if (name.isEmpty) {
      return 'T';
    }

    return name[0].toUpperCase();
  }

  Future<void> _showEditProfileDialog() async {
    final usernameController = TextEditingController(
      text: _username,
    );

    bool saving = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (
        dialogContext,
      ) {
        return StatefulBuilder(
          builder: (
            context,
            setDialogState,
          ) {
            return AlertDialog(
              title: const Text(
                'Edit Profile',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: usernameController,
                      enabled: !saving,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(
                      height: 14,
                    ),
                    InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        helperText:
                            'Email changes require account verification.',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(_email),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving
                      ? null
                      : () {
                          Navigator.of(
                            dialogContext,
                          ).pop();
                        },
                  child: const Text(
                    'Cancel',
                  ),
                ),
                FilledButton(
                  onPressed: saving
                      ? null
                      : () async {
                          final username = usernameController.text.trim();

                          if (username.isEmpty) {
                            _showMessage(
                              'Username cannot be empty.',
                            );
                            return;
                          }

                          setDialogState(
                            () {
                              saving = true;
                            },
                          );

                          try {
                            final user = SupabaseService.currentUser;

                            if (user == null) {
                              throw Exception(
                                'You must be logged in.',
                              );
                            }

                            await SupabaseService.client
                                .from(
                              'profiles',
                            )
                                .update({
                              'username': username,
                            }).eq(
                              'id',
                              user.id,
                            );

                            if (!dialogContext.mounted) {
                              return;
                            }

                            Navigator.of(
                              dialogContext,
                            ).pop();

                            _showMessage(
                              'Profile updated.',
                            );

                            await _loadProfile();
                          } catch (_) {
                            if (!dialogContext.mounted) {
                              return;
                            }

                            setDialogState(
                              () {
                                saving = false;
                              },
                            );

                            _showMessage(
                              'Could not update profile.',
                            );
                          }
                        },
                  child: saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Save Changes',
                        ),
                ),
              ],
            );
          },
        );
      },
    );

    await Future<void>.delayed(
      const Duration(
        milliseconds: 350,
      ),
    );

    usernameController.dispose();
  }

  Future<void> _showChangePasswordDialog() async {
    final currentPasswordController = TextEditingController();

    final newPasswordController = TextEditingController();

    final confirmPasswordController = TextEditingController();

    bool saving = false;

    bool hideCurrent = true;
    bool hideNew = true;
    bool hideConfirm = true;

    String? dialogError;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (
        dialogContext,
      ) {
        return StatefulBuilder(
          builder: (
            context,
            setDialogState,
          ) {
            return AlertDialog(
              title: const Text(
                'Change Password',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: currentPasswordController,
                      enabled: !saving,
                      obscureText: hideCurrent,
                      decoration: InputDecoration(
                        labelText: 'Current Password',
                        prefixIcon: const Icon(
                          Icons.lock_outline,
                        ),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setDialogState(
                              () {
                                hideCurrent = !hideCurrent;
                              },
                            );
                          },
                          icon: Icon(
                            hideCurrent
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
                      controller: newPasswordController,
                      enabled: !saving,
                      obscureText: hideNew,
                      decoration: InputDecoration(
                        labelText: 'New Password',
                        prefixIcon: const Icon(
                          Icons.lock_reset,
                        ),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setDialogState(
                              () {
                                hideNew = !hideNew;
                              },
                            );
                          },
                          icon: Icon(
                            hideNew
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
                      controller: confirmPasswordController,
                      enabled: !saving,
                      obscureText: hideConfirm,
                      decoration: InputDecoration(
                        labelText: 'Confirm New Password',
                        prefixIcon: const Icon(
                          Icons.lock_reset,
                        ),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setDialogState(
                              () {
                                hideConfirm = !hideConfirm;
                              },
                            );
                          },
                          icon: Icon(
                            hideConfirm
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
                    if (dialogError != null) ...[
                      const SizedBox(
                        height: 12,
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(
                            alpha: 0.08,
                          ),
                          borderRadius: BorderRadius.circular(
                            8,
                          ),
                        ),
                        child: Text(
                          dialogError!,
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving
                      ? null
                      : () {
                          Navigator.of(
                            dialogContext,
                          ).pop();
                        },
                  child: const Text(
                    'Cancel',
                  ),
                ),
                FilledButton(
                  onPressed: saving
                      ? null
                      : () async {
                          final currentPassword =
                              currentPasswordController.text;

                          final newPassword = newPasswordController.text;

                          final confirmPassword =
                              confirmPasswordController.text;

                          if (currentPassword.isEmpty) {
                            setDialogState(
                              () {
                                dialogError = 'Enter your current password.';
                              },
                            );
                            return;
                          }

                          if (newPassword.length < 8) {
                            setDialogState(
                              () {
                                dialogError =
                                    'New password must contain at least 8 characters.';
                              },
                            );
                            return;
                          }

                          if (newPassword == currentPassword) {
                            setDialogState(
                              () {
                                dialogError =
                                    'Choose a new password different from your current password.';
                              },
                            );
                            return;
                          }

                          if (newPassword != confirmPassword) {
                            setDialogState(
                              () {
                                dialogError = 'New passwords do not match.';
                              },
                            );
                            return;
                          }

                          setDialogState(
                            () {
                              saving = true;
                              dialogError = null;
                            },
                          );

                          try {
                            await SupabaseService.changePassword(
                              currentPassword: currentPassword,
                              newPassword: newPassword,
                            );

                            if (!dialogContext.mounted) {
                              return;
                            }

                            Navigator.of(
                              dialogContext,
                            ).pop();

                            _showMessage(
                              'Password changed successfully.',
                            );
                          } catch (e) {
                            if (!dialogContext.mounted) {
                              return;
                            }

                            setDialogState(
                              () {
                                saving = false;
                                dialogError = _passwordError(
                                  e,
                                );
                              },
                            );
                          }
                        },
                  child: saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Change Password',
                        ),
                ),
              ],
            );
          },
        );
      },
    );

    await Future<void>.delayed(
      const Duration(
        milliseconds: 350,
      ),
    );

    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
  }

  String _passwordError(
    Object error,
  ) {
    final text = error.toString().toLowerCase();

    if (text.contains(
          'current password',
        ) ||
        text.contains(
          'invalid password',
        )) {
      return 'The current password is incorrect.';
    }

    if (text.contains(
      'same password',
    )) {
      return 'Choose a password different from your current password.';
    }

    if (text.contains(
          'weak',
        ) ||
        text.contains(
          'password should',
        )) {
      return 'The new password does not meet the account password requirements.';
    }

    return 'The password could not be changed. Check your current password and try again.';
  }

  Future<void> _showHealthProfile() async {
    final profile = _healthProfile;

    if (profile == null) {
      _showMessage(
        'No health profile is available.',
      );
      return;
    }

    final age = profile['age']?.toString() ?? '—';

    final hasHypertension = profile['has_hypertension'] == true;

    final systolic = profile['baseline_systolic']?.toString() ?? '—';

    final diastolic = profile['baseline_diastolic']?.toString() ?? '—';

    final sodiumLimit = profile['daily_sodium_limit']?.toString() ?? '—';

    await showDialog<void>(
      context: context,
      builder: (
        dialogContext,
      ) {
        return AlertDialog(
          title: const Text(
            'Health Profile',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInfoRow(
                'Age',
                age,
              ),
              _buildInfoRow(
                'Hypertension',
                hasHypertension ? 'Yes' : 'No',
              ),
              _buildInfoRow(
                'Baseline BP',
                '$systolic / $diastolic mmHg',
              ),
              _buildInfoRow(
                'Daily Sodium Limit',
                '$sodiumLimit mg',
              ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop();
              },
              child: const Text(
                'Close',
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoRow(
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 8,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showNotifications() async {
    await showDialog<void>(
      context: context,
      builder: (
        dialogContext,
      ) {
        return AlertDialog(
          title: const Text(
            'Notification Settings',
          ),
          content: const Text(
            'Notification preferences are not enabled in this version of Tibok.',
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop();
              },
              child: const Text(
                'Close',
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showHelp() async {
    await showDialog<void>(
      context: context,
      builder: (
        dialogContext,
      ) {
        return AlertDialog(
          title: const Text(
            'Help & Support',
          ),
          content: const SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How do I track sodium?',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(
                  height: 4,
                ),
                Text(
                  'Use Scan Food for packaged products or Add Food '
                  'for common meals and manual entries.',
                ),
                SizedBox(
                  height: 16,
                ),
                Text(
                  'How do I record blood pressure?',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(
                  height: 4,
                ),
                Text(
                  'Open Blood Pressure and use Log BP to record '
                  'systolic, diastolic, and heart-rate values.',
                ),
                SizedBox(
                  height: 16,
                ),
                Text(
                  'Where are health resources?',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(
                  height: 4,
                ),
                Text(
                  'Open Health Resources to browse, bookmark, and '
                  'visit trusted external health information.',
                ),
              ],
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop();
              },
              child: const Text(
                'Close',
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAbout() async {
    await showDialog<void>(
      context: context,
      builder: (
        dialogContext,
      ) {
        return AlertDialog(
          title: const Text(
            'About Tibok',
          ),
          content: const SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tibok is a mobile health application designed to help '
                  'users monitor daily sodium intake and blood pressure, '
                  'identify sodium in foods, and access educational '
                  'heart-health resources.',
                ),
                SizedBox(
                  height: 18,
                ),
                Text(
                  'The application was developed by students from '
                  'Silliman University under the Bachelor of Science '
                  'in Information Technology (BSIT-III) program.',
                ),
                SizedBox(
                  height: 22,
                ),
                Text(
                  'Lead Developer',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Seth Vicef Somoza',
                ),
                SizedBox(
                  height: 14,
                ),
                Text(
                  'Technical Lead',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Dan Joseph Sarabia',
                ),
                SizedBox(
                  height: 14,
                ),
                Text(
                  'Project Manager',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Jaelica Fabian',
                ),
                SizedBox(
                  height: 20,
                ),
                Text(
                  'Bachelor of Science in Information Technology (BSIT-III)\n'
                  'Silliman University',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop();
              },
              child: const Text(
                'Close',
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (
        dialogContext,
      ) {
        return AlertDialog(
          title: const Text(
            'Logout',
          ),
          content: const Text(
            'Are you sure you want to log out of Tibok?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(
                  false,
                );
              },
              child: const Text(
                'Cancel',
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(
                  true,
                );
              },
              child: const Text(
                'Logout',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await SupabaseService.signOut();

    if (mounted &&
        Navigator.canPop(
          context,
        )) {
      Navigator.popUntil(
        context,
        (route) => route.isFirst,
      );
    }
  }

  void _showMessage(
    String message,
  ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile',
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(
            24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 60,
                color: Colors.redAccent,
              ),
              const SizedBox(
                height: 16,
              ),
              const Text(
                'Unable to load your profile.',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(
                height: 8,
              ),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(
                height: 16,
              ),
              FilledButton.icon(
                onPressed: _loadProfile,
                icon: const Icon(
                  Icons.refresh,
                ),
                label: const Text(
                  'Try Again',
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        20,
        24,
        20,
        30,
      ),
      children: [
        Center(
          child: CircleAvatar(
            radius: 52,
            backgroundColor: Colors.redAccent.withValues(
              alpha: 0.12,
            ),
            child: Text(
              _initial,
              style: const TextStyle(
                fontSize: 38,
                fontWeight: FontWeight.bold,
                color: Colors.redAccent,
              ),
            ),
          ),
        ),
        const SizedBox(
          height: 16,
        ),
        Text(
          _username,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(
          height: 4,
        ),
        Text(
          _email,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(
          height: 18,
        ),
        Center(
          child: OutlinedButton.icon(
            onPressed: _showEditProfileDialog,
            icon: const Icon(
              Icons.edit_outlined,
            ),
            label: const Text(
              'Edit Profile',
            ),
          ),
        ),
        const SizedBox(
          height: 28,
        ),
        const Text(
          'Account & Health',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(
          height: 8,
        ),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(
                  Icons.favorite_outline,
                ),
                title: const Text(
                  'Health Profile',
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                ),
                onTap: _showHealthProfile,
              ),
              const Divider(
                height: 1,
              ),
              ListTile(
                leading: const Icon(
                  Icons.lock_outline,
                ),
                title: const Text(
                  'Change Password',
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                ),
                onTap: _showChangePasswordDialog,
              ),
              const Divider(
                height: 1,
              ),
              ListTile(
                leading: const Icon(
                  Icons.notifications_outlined,
                ),
                title: const Text(
                  'Notification Settings',
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                ),
                onTap: _showNotifications,
              ),
            ],
          ),
        ),
        const SizedBox(
          height: 22,
        ),
        const Text(
          'Support',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(
          height: 8,
        ),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(
                  Icons.help_outline,
                ),
                title: const Text(
                  'Help & Support',
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                ),
                onTap: _showHelp,
              ),
              const Divider(
                height: 1,
              ),
              ListTile(
                leading: const Icon(
                  Icons.info_outline,
                ),
                title: const Text(
                  'About Tibok',
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                ),
                onTap: _showAbout,
              ),
            ],
          ),
        ),
        const SizedBox(
          height: 28,
        ),
        OutlinedButton.icon(
          onPressed: _handleLogout,
          icon: const Icon(
            Icons.logout,
          ),
          label: const Text(
            'Logout',
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.redAccent,
            side: const BorderSide(
              color: Colors.redAccent,
            ),
            padding: const EdgeInsets.symmetric(
              vertical: 15,
            ),
          ),
        ),
      ],
    );
  }
}
