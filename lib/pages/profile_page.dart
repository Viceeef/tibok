import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/supabase_service.dart';
import 'accessibility_settings_page.dart';
import 'change_password_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _account;
  Map<String, dynamic>? _health;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final user = SupabaseService.currentUser;
      if (user == null) throw Exception('You must be logged in.');
      final account = await SupabaseService.client
          .from('user_profile')
          .select()
          .eq('id', user.id)
          .maybeSingle();
      final health = await SupabaseService.getHealthProfile();
      if (!mounted) return;
      setState(() {
        _account = account;
        _health = health;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String get _username {
    final value = _account?['username']?.toString().trim() ?? '';
    return value.isEmpty ? 'Tibok User' : value;
  }

  String get _email {
    final value = _account?['email']?.toString().trim() ?? '';
    return value.isEmpty
        ? (SupabaseService.currentUser?.email ?? 'No email available')
        : value;
  }

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _editAccount() async {
    final controller = TextEditingController(text: _username);
    var saving = false;
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Profile'),
          scrollable: true,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: controller,
                enabled: !saving,
                maxLength: 50,
                decoration: const InputDecoration(labelText: 'Username'),
              ),
              const SizedBox(height: 8),
              Text('Email: $_email'),
              const Text('Email changes require account verification.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed:
                  saving ? null : () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      final username = controller.text.trim();
                      if (username.isEmpty) {
                        _message('Username cannot be empty.');
                        return;
                      }
                      setDialogState(() => saving = true);
                      try {
                        final user = SupabaseService.currentUser;
                        if (user == null) {
                          throw Exception('You must be logged in.');
                        }
                        await SupabaseService.client
                            .from('user_profile')
                            .update({'username': username}).eq('id', user.id);
                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext, true);
                        }
                      } catch (e) {
                        if (dialogContext.mounted) {
                          setDialogState(() => saving = false);
                        }
                        _message('Could not update profile: $e');
                      }
                    },
              child: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    if (saved == true) {
      _message('Profile updated.');
      await _load();
    }
  }

  Future<void> _editHealth() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => _HealthProfileEditor(initial: _health)),
    );
    if (saved == true) {
      _message('Health profile updated.');
      await _load();
    }
  }

  Future<void> _showInfo(String title, String body) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Text(body)),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out of Tibok?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await SupabaseService.signOut();
      if (mounted && Navigator.canPop(context)) {
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    } catch (e) {
      _message('Could not log out: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Unable to load your profile: $_error'),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _load,
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 30),
                    children: [
                      Center(
                        child: CircleAvatar(
                          radius: 48,
                          child: Text(
                            _username[0].toUpperCase(),
                            style: const TextStyle(fontSize: 36),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _username,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      Text(_email, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      Center(
                        child: OutlinedButton.icon(
                          onPressed: _editAccount,
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Edit Profile'),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Account & Health',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Card(
                        child: Column(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.lock_outline),
                              title: const Text('Change Password'),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => Navigator.push<bool>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ChangePasswordPage(),
                                ),
                              ),
                            ),
                            const Divider(height: 1),
                            ListTile(
                              leading: const Icon(Icons.favorite_outline),
                              title: const Text('Edit Health Profile'),
                              subtitle: Text(
                                _health == null
                                    ? 'Add your health details'
                                    : 'Edit age, hypertension, baseline BP, and sodium limit',
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: _editHealth,
                            ),
                            const Divider(height: 1),
                            ListTile(
                              leading: const Icon(Icons.accessibility_new_rounded),
                              title: const Text('Accessibility Settings'),
                              subtitle: const Text('Normal, Large, or Extra Large text'),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => Navigator.push<void>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AccessibilitySettingsPage(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Support',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Card(
                        child: Column(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.help_outline),
                              title: const Text('Help & Support'),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => _showInfo(
                                'Help & Support',
                                'LOG FOOD\n1. From Home, tap Add Food. Search for a food or select a category, then tap the food.\n2. Enter the Amount Consumed in grams. Check the sodium total, then save the entry.\n3. If the food is missing, tap Enter Food Manually. Enter its name, sodium per 100 g in milligrams, and the amount eaten in grams. Check the product label carefully: sodium per serving is not the same as sodium per 100 g.\n\n'
                                'SCAN PACKAGED FOOD\nOpen Scan Food from Home and allow camera access. Point the camera at the barcode. Review the product and available sodium information, enter the amount consumed as requested, and confirm adding it to your log. If the product or sodium information is unavailable, use Enter Food Manually with information from the label.\n\n'
                                'REVIEW OR CORRECT YOUR FOOD LOG\nOpen Food Log. Use the date arrows to review another day. Tap Edit on an entry to correct its details and Save Changes. Tap Delete and confirm to remove an entry.\n\n'
                                'LOG BLOOD PRESSURE\nOpen the BP tab and tap Log Blood Pressure. Enter your monitor readings for Systolic, Diastolic, and Heart Rate. Add notes if needed and tap Save Reading. Review your readings and trends on the BP page. Use the delete icon and confirm if you recorded a reading incorrectly. Tibok records readings; it does not measure blood pressure.\n\n'
                                'USE RESOURCES\nOpen Resources. Search or choose All, Articles, Recipes, or Bookmarks. Tap a resource to see its preview, then tap Open Resource to visit the source. Use the bookmark icon or Save to Bookmarks to save it for later. Use Bookmarks to find saved resources; tap the bookmark again to remove it.\n\n'
                                'EDIT YOUR HEALTH PROFILE\nOpen Profile > Edit Health Profile. Update your age, hypertension answer, baseline blood pressure, or daily sodium limit in mg. Tap Save Health Profile. Changing the hypertension answer here does not automatically change your saved sodium limit. Return to Home to see your updated target.\n\n'
                                'MAKE TEXT EASIER TO READ\nOpen Profile > Accessibility Settings and choose Normal, Large, or Extra Large. The change applies throughout Tibok and is saved on this device. Your phone\'s text-size setting also affects the final size. Use Reset to Normal to restore the default Tibok size.\n\n'
                                'ACCOUNT AND TROUBLESHOOTING\nUse Edit Profile to change your username. To change your password while logged in, open Profile > Change Password and enter your current password, new password, and confirmation. If you forget your password, use the password-reset option on the login screen and follow the email link. New passwords need at least 8 characters, including a letter and a number. If a page fails to load or save, check your internet connection and use its refresh or retry control. Check the log before resubmitting to avoid duplicates.',
                              ),
                            ),
                            const Divider(height: 1),
                            ListTile(
                              leading: const Icon(Icons.info_outline),
                              title: const Text('About Tibok'),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => _showInfo(
                                'About Tibok',
                                'Tibok helps you keep track of daily sodium intake and blood pressure in one place. It is designed to make everyday health tracking easier, including for older adults who benefit from larger text.\n\n'
                                'FOOD AND SODIUM TRACKING\nSearch the built-in food list, enter food manually, or scan packaged-food barcodes. Record how much you eat, review your daily food log, and compare your intake with your saved sodium limit. Sodium totals depend on the food information and portions entered; ingredients, brands, and preparation can change the actual amount.\n\n'
                                'BLOOD PRESSURE RECORDS\nSave readings from your blood pressure monitor, add notes, and review your history and trends over time.\n\n'
                                'LEARNING RESOURCES\nBrowse articles and recipes, open their original sources, and bookmark resources you want to revisit. Content on external websites is provided by those publishers.\n\n'
                                'YOUR PREFERENCES\nUpdate your details and sodium limit in Edit Health Profile. Choose Normal, Large, or Extra Large text in Accessibility Settings for more comfortable reading.\n\n'
                                'Tibok supports tracking and health awareness. It does not diagnose conditions or replace advice from your healthcare professional.\n\n'
                                'Developed by students from Silliman University, BSIT-III.\n\n'
                                'Lead Developer: Somoza\nTechnical Lead: Dan\nProject Manager: Jae',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      OutlinedButton.icon(
                        onPressed: _logout,
                        icon: const Icon(Icons.logout),
                        label: const Text('Logout'),
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _HealthProfileEditor extends StatefulWidget {
  const _HealthProfileEditor({required this.initial});
  final Map<String, dynamic>? initial;

  @override
  State<_HealthProfileEditor> createState() => _HealthProfileEditorState();
}

class _HealthProfileEditorState extends State<_HealthProfileEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _age;
  late final TextEditingController _systolic;
  late final TextEditingController _diastolic;
  late final TextEditingController _sodiumLimit;
  late bool _hypertension;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final profile = widget.initial;
    _hypertension = profile?['has_hypertension'] == true;
    _age = TextEditingController(text: profile?['age']?.toString() ?? '');
    _systolic = TextEditingController(
      text: profile?['baseline_systolic']?.toString() ?? '',
    );
    _diastolic = TextEditingController(
      text: profile?['baseline_diastolic']?.toString() ?? '',
    );
    _sodiumLimit = TextEditingController(
      text: profile?['daily_sodium_limit']?.toString() ??
          (_hypertension ? '1500' : '2000'),
    );
  }

  @override
  void dispose() {
    _age.dispose();
    _systolic.dispose();
    _diastolic.dispose();
    _sodiumLimit.dispose();
    super.dispose();
  }

  String? _range(String? value, String label, int min, int max) {
    final number = int.tryParse(value?.trim() ?? '');
    if (number == null || number < min || number > max) {
      return 'Enter $label from $min to $max';
    }
    return null;
  }

  Widget _numberField(
    TextEditingController controller,
    String label,
    int min,
    int max, {
    String? suffix,
  }) {
    return TextFormField(
      controller: controller,
      enabled: !_saving,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(5),
      ],
      decoration: InputDecoration(labelText: label, suffixText: suffix),
      validator: (value) => _range(value, label.toLowerCase(), min, max),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final systolic = int.parse(_systolic.text);
    final diastolic = int.parse(_diastolic.text);
    if (systolic <= diastolic) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Systolic pressure should be higher than diastolic pressure.',
          ),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final user = SupabaseService.currentUser;
      if (user == null) throw Exception('You must be logged in.');
      await SupabaseService.client.from('health_profile').upsert({
        'user_id': user.id,
        'age': int.parse(_age.text),
        'has_hypertension': _hypertension,
        'baseline_systolic': systolic,
        'baseline_diastolic': diastolic,
        'daily_sodium_limit': int.parse(_sodiumLimit.text),
      }, onConflict: 'user_id');
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save health profile: $e')),
      );
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Health Profile')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _numberField(_age, 'Age', 1, 120),
                const SizedBox(height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Diagnosed with hypertension?'),
                  value: _hypertension,
                  onChanged: _saving
                      ? null
                      : (value) => setState(() => _hypertension = value),
                ),
                const SizedBox(height: 16),
                Text(
                  'Baseline blood pressure',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                _numberField(_systolic, 'Systolic', 50, 250, suffix: 'mmHg'),
                const SizedBox(height: 16),
                _numberField(_diastolic, 'Diastolic', 30, 150, suffix: 'mmHg'),
                const SizedBox(height: 16),
                _numberField(
                  _sodiumLimit,
                  'Daily sodium limit',
                  1,
                  10000,
                  suffix: 'mg',
                ),
                const SizedBox(height: 8),
                const Text(
                  'Changing the hypertension answer does not overwrite your sodium limit. Adjust the limit above if needed.',
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save Health Profile'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
