import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/supabase_service.dart';
import 'auth_gate.dart';

class OnboardingHealthPage extends StatefulWidget {
  const OnboardingHealthPage({
    super.key,
  });

  @override
  State<OnboardingHealthPage> createState() => _OnboardingHealthPageState();
}

class _OnboardingHealthPageState extends State<OnboardingHealthPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _ageController = TextEditingController();

  final TextEditingController _systolicController = TextEditingController();

  final TextEditingController _diastolicController = TextEditingController();

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
    FocusManager.instance.primaryFocus?.unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final age = int.tryParse(
      _ageController.text.trim(),
    );

    final systolic = int.tryParse(
      _systolicController.text.trim(),
    );

    final diastolic = int.tryParse(
      _diastolicController.text.trim(),
    );

    if (age == null || systolic == null || diastolic == null) {
      _showMessage(
        'Check the health information you entered.',
      );
      return;
    }

    if (systolic <= diastolic) {
      _showMessage(
        'Systolic pressure should be higher than diastolic pressure.',
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await SupabaseService.saveHealthProfile(
        age: age,
        hasHypertension: _hasHypertension,
        baselineSystolic: systolic,
        baselineDiastolic: diastolic,
      );

      if (!mounted) {
        return;
      }

      // IMPORTANT:
      // Restore AuthGate as the root route instead of making
      // MainDashboardPage the root.
      //
      // AuthGate will see the authenticated user + completed
      // health profile and display the dashboard.
      //
      // Keeping AuthGate alive also allows logout to react
      // correctly to Supabase's signedOut event.
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const AuthGate(),
        ),
        (route) => false,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Could not save your health profile. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
          content: Text(
            message,
          ),
        ),
      );
  }

  String? _validateAge(
    String? value,
  ) {
    final age = int.tryParse(
      value?.trim() ?? '',
    );

    if (age == null) {
      return 'Enter a valid age';
    }

    if (age < 1 || age > 120) {
      return 'Enter an age from 1 to 120';
    }

    return null;
  }

  String? _validateSystolic(
    String? value,
  ) {
    final number = int.tryParse(
      value?.trim() ?? '',
    );

    if (number == null) {
      return 'Enter systolic';
    }

    if (number < 50 || number > 250) {
      return 'Use 50–250';
    }

    return null;
  }

  String? _validateDiastolic(
    String? value,
  ) {
    final number = int.tryParse(
      value?.trim() ?? '',
    );

    if (number == null) {
      return 'Enter diastolic';
    }

    if (number < 30 || number > 150) {
      return 'Use 30–150';
    }

    return null;
  }

  Widget _buildBloodPressureFields() {
    final textScale = MediaQuery.of(context).textScaler.scale(
          1.0,
        );

    final stackFields =
        textScale >= 1.25 || MediaQuery.sizeOf(context).width < 360;

    final systolicField = TextFormField(
      controller: _systolicController,
      enabled: !_isLoading,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.next,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(
          3,
        ),
      ],
      decoration: const InputDecoration(
        labelText: 'Systolic',
        hintText: 'Example: 120',
        suffixText: 'mmHg',
        prefixIcon: Icon(
          Icons.arrow_upward_rounded,
        ),
      ),
      validator: _validateSystolic,
    );

    final diastolicField = TextFormField(
      controller: _diastolicController,
      enabled: !_isLoading,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.done,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(
          3,
        ),
      ],
      decoration: const InputDecoration(
        labelText: 'Diastolic',
        hintText: 'Example: 80',
        suffixText: 'mmHg',
        prefixIcon: Icon(
          Icons.arrow_downward_rounded,
        ),
      ),
      validator: _validateDiastolic,
      onFieldSubmitted: (_) {
        if (!_isLoading) {
          _submitHealthProfile();
        }
      },
    );

    if (stackFields) {
      return Column(
        children: [
          systolicField,
          const SizedBox(
            height: 14,
          ),
          diastolicField,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: systolicField,
        ),
        const SizedBox(
          width: 12,
        ),
        Expanded(
          child: diastolicField,
        ),
      ],
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final sodiumTarget = _hasHypertension ? 1500 : 2000;

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text(
            'Health Setup',
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(
              18,
              10,
              18,
              32,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    elevation: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(
                        18,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: colors.primaryContainer,
                              borderRadius: BorderRadius.circular(
                                14,
                              ),
                            ),
                            child: Icon(
                              Icons.favorite_outline_rounded,
                              color: colors.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(
                            width: 14,
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Set Up Your Health Profile',
                                  style: theme.textTheme.titleLarge,
                                ),
                                const SizedBox(
                                  height: 5,
                                ),
                                Text(
                                  'These details help Tibok personalize your '
                                  'sodium tracking and starting blood pressure information.',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 22,
                  ),
                  Text(
                    'Age',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(
                    height: 9,
                  ),
                  TextFormField(
                    controller: _ageController,
                    enabled: !_isLoading,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(
                        3,
                      ),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Age',
                      prefixIcon: Icon(
                        Icons.cake_outlined,
                      ),
                    ),
                    validator: _validateAge,
                  ),
                  const SizedBox(
                    height: 22,
                  ),
                  Text(
                    'Hypertension',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(
                    height: 9,
                  ),
                  Card(
                    child: SwitchListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 7,
                      ),
                      title: const Text(
                        'Diagnosed with hypertension?',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(
                          top: 4,
                        ),
                        child: Text(
                          'Tibok daily sodium target: $sodiumTarget mg',
                        ),
                      ),
                      value: _hasHypertension,
                      onChanged: _isLoading
                          ? null
                          : (
                              value,
                            ) {
                              setState(() {
                                _hasHypertension = value;
                              });
                            },
                    ),
                  ),
                  const SizedBox(
                    height: 22,
                  ),
                  Text(
                    'Starting Blood Pressure',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  Text(
                    'Enter a recent blood pressure reading to use as your starting reference.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(
                    height: 12,
                  ),
                  _buildBloodPressureFields(),
                  const SizedBox(
                    height: 14,
                  ),
                  Container(
                    padding: const EdgeInsets.all(
                      14,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(
                        14,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 21,
                          color: colors.primary,
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        const Expanded(
                          child: Text(
                            'This reading is stored for tracking purposes. '
                            'A single blood pressure reading does not establish a diagnosis.',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 26,
                  ),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submitHealthProfile,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Complete Setup',
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
