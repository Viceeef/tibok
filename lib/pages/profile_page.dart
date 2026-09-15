import 'package:flutter/material.dart';

import '../services/supabase_service.dart';
import 'accessibility_settings_page.dart';

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
    if (_username.isEmpty) {
      return 'T';
    }

    return _username[0].toUpperCase();
  }

  Future<void> _openAccessibilitySettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AccessibilitySettingsPage(),
      ),
    );
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
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall,
                    ),
                    if (dialogError != null) ...[
                      const SizedBox(
                        height: 12,
                      ),
                      Text(
                        dialogError!,
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.error,
                          fontWeight: FontWeight.w600,
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

                          final confirmation = confirmPasswordController.text;

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
                                    'Choose a different new password.';
                              },
                            );
                            return;
                          }

                          if (newPassword != confirmation) {
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
          'invalid login credentials',
        ) ||
        text.contains(
          'current password',
        ) ||
        text.contains(
          'invalid password',
        )) {
      return 'The current password is incorrect.';
    }

    return 'The password could not be changed. Please try again.';
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

    final hypertension = profile['has_hypertension'] == true ? 'Yes' : 'No';

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
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildInfoBlock(
                  'Age',
                  age,
                ),
                _buildInfoBlock(
                  'Hypertension',
                  hypertension,
                ),
                _buildInfoBlock(
                  'Baseline Blood Pressure',
                  '$systolic / $diastolic mmHg',
                ),
                _buildInfoBlock(
                  'Daily Sodium Limit',
                  '$sodiumLimit mg',
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

  Widget _buildInfoBlock(
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(
            height: 3,
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium,
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
            'Notifications',
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
                  height: 5,
                ),
                Text(
                  'Use Scan Food for packaged products or Add Food for common meals and manual entries.',
                ),
                SizedBox(
                  height: 18,
                ),
                Text(
                  'How do I record blood pressure?',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(
                  height: 5,
                ),
                Text(
                  'Open Blood Pressure and use Log BP to record systolic, diastolic, and heart-rate values.',
                ),
                SizedBox(
                  height: 18,
                ),
                Text(
                  'Can I make Tibok easier to read?',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(
                  height: 5,
                ),
                Text(
                  'Yes. Open Profile → Accessibility & Display and choose Standard, Large, or Extra Large text.',
                ),
                SizedBox(
                  height: 18,
                ),
                Text(
                  'Where are health resources?',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(
                  height: 5,
                ),
                Text(
                  'Open Health Resources to browse, bookmark, and visit trusted external health information.',
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
                  'Tibok is a mobile health application designed to help users monitor daily sodium intake and blood pressure, identify sodium in foods, and access educational heart-health resources.',
                ),
                SizedBox(
                  height: 18,
                ),
                Text(
                  'The application was developed by students from Silliman University under the Bachelor of Science in Information Technology (BSIT-III) program.',
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

    if (!mounted) {
      return;
    }

    if (Navigator.canPop(
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
              Icon(
                Icons.error_outline,
                size: 58,
                color: Theme.of(
                  context,
                ).colorScheme.error,
              ),
              const SizedBox(
                height: 14,
              ),
              Text(
                'Unable to load your profile.',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(
                height: 18,
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

    final colors = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        18,
        12,
        18,
        32,
      ),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(
              22,
            ),
            child: Column(
              children: [
                Container(
                  width: 92,
                  height: 92,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    _initial,
                    style: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w800,
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 14,
                ),
                Semantics(
                  header: true,
                  child: Text(
                    _username,
                    textAlign: TextAlign.center,
                    style: Theme.of(
                      context,
                    ).textTheme.headlineSmall,
                  ),
                ),
                const SizedBox(
                  height: 4,
                ),
                Text(
                  _email,
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                ),
                const SizedBox(
                  height: 16,
                ),
                OutlinedButton.icon(
                  onPressed: _showEditProfileDialog,
                  icon: const Icon(
                    Icons.edit_outlined,
                  ),
                  label: const Text(
                    'Edit Profile',
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(
          height: 26,
        ),
        _sectionTitle(
          'Account & Health',
        ),
        const SizedBox(
          height: 9,
        ),
        Card(
          child: Column(
            children: [
              _profileTile(
                icon: Icons.favorite_outline,
                title: 'Health Profile',
                subtitle: 'Health details and sodium target',
                onTap: _showHealthProfile,
              ),
              const Divider(),
              _profileTile(
                icon: Icons.lock_outline,
                title: 'Change Password',
                subtitle: 'Update your account password',
                onTap: _showChangePasswordDialog,
              ),
            ],
          ),
        ),
        const SizedBox(
          height: 24,
        ),
        _sectionTitle(
          'Preferences',
        ),
        const SizedBox(
          height: 9,
        ),
        Card(
          child: Column(
            children: [
              _profileTile(
                icon: Icons.accessibility_new_rounded,
                title: 'Accessibility & Display',
                subtitle: 'Text size and readability',
                onTap: _openAccessibilitySettings,
              ),
              const Divider(),
              _profileTile(
                icon: Icons.notifications_outlined,
                title: 'Notifications',
                subtitle: 'Notification preferences',
                onTap: _showNotifications,
              ),
            ],
          ),
        ),
        const SizedBox(
          height: 24,
        ),
        _sectionTitle(
          'Support',
        ),
        const SizedBox(
          height: 9,
        ),
        Card(
          child: Column(
            children: [
              _profileTile(
                icon: Icons.help_outline,
                title: 'Help & Support',
                subtitle: 'How to use Tibok',
                onTap: _showHelp,
              ),
              const Divider(),
              _profileTile(
                icon: Icons.info_outline,
                title: 'About Tibok',
                subtitle: 'Project and development team',
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
            foregroundColor: colors.error,
            side: BorderSide(
              color: colors.error,
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(
    String title,
  ) {
    return Semantics(
      header: true,
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }

  Widget _profileTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(
            12,
          ),
        ),
        child: Icon(
          icon,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: const Icon(
        Icons.chevron_right,
      ),
      onTap: onTap,
    );
  }
}
