import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/supabase_service.dart';

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
                        if (user == null)
                          throw Exception('You must be logged in.');
                        await SupabaseService.client
                            .from('user_profile')
                            .update({'username': username}).eq('id', user.id);
                        if (dialogContext.mounted)
                          Navigator.pop(dialogContext, true);
                      } catch (e) {
                        if (dialogContext.mounted)
                          setDialogState(() => saving = false);
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
                              leading: const Icon(Icons.favorite_outline),
                              title: const Text('Health Profile'),
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
                              leading: const Icon(Icons.notifications_outlined),
                              title: const Text('Notification Settings'),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => _showInfo(
                                'Notification Settings',
                                'Notification preferences are planned for a later Tibok update.',
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
                                'Use Scan Food or Add Food to record sodium. Open Food Log and use the date arrows to review past entries. Open Blood Pressure to record readings.',
                              ),
                            ),
                            const Divider(height: 1),
                            ListTile(
                              leading: const Icon(Icons.info_outline),
                              title: const Text('About Tibok'),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => _showInfo(
                                'About Tibok',
                                'Tibok helps users track daily sodium intake and blood pressure and access heart-health resources.\n\nDeveloped by students from Silliman University, BSIT-III.\n\nLead Developer: Somoza\nTechnical Lead: Dan\nProject Manager: Jae',
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
