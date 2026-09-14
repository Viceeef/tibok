import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import 'main_dashboard_page.dart';

class OnboardingHealthPage extends StatefulWidget {
  const OnboardingHealthPage({super.key});

  @override
  State<OnboardingHealthPage> createState() => _OnboardingHealthPageState();
}

class _OnboardingHealthPageState extends State<OnboardingHealthPage> {
  final _formKey = GlobalKey<FormState>();
  final _ageController = TextEditingController();
  final _systolicController = TextEditingController(text: '120');
  final _diastolicController = TextEditingController(text: '80');
  bool _hasHypertension = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _ageController.dispose();
    _systolicController.dispose();
    _diastolicController.dispose();
    super.dispose();
  }

  Future<void> _submitHealthProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await SupabaseService.saveHealthProfile(
        age: int.parse(_ageController.text.trim()),
        hasHypertension: _hasHypertension,
        baselineSystolic: int.parse(_systolicController.text.trim()),
        baselineDiastolic: int.parse(_diastolicController.text.trim()),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile setup complete!')),
        );

        // Redirect to Main Dashboard and clear navigation history so user cannot go back
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainDashboardPage()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // PopScope prevents back gesture / physical back button
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Setup Health Profile'),
          automaticallyImplyLeading: false, // Removes the top back button/arrow
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Personalize your daily sodium limits and blood pressure targets.',
                  style: TextStyle(fontSize: 15, color: Colors.grey),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _ageController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Age',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.cake_outlined),
                  ),
                  validator: (val) =>
                      (val == null || val.isEmpty) ? 'Please enter age' : null,
                ),
                const SizedBox(height: 20),
                SwitchListTile(
                  title: const Text('Diagnosed with Hypertension?'),
                  subtitle: Text(_hasHypertension
                      ? 'Target: 1,500 mg/day (DASH)'
                      : 'Target: 2,000 mg/day'),
                  value: _hasHypertension,
                  activeThumbColor: Colors.redAccent,
                  onChanged: (val) => setState(() => _hasHypertension = val),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _systolicController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Systolic (mmHg)',
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) =>
                            (val == null || val.isEmpty) ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _diastolicController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Diastolic (mmHg)',
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) =>
                            (val == null || val.isEmpty) ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submitHealthProfile,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Complete Setup',
                          style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
