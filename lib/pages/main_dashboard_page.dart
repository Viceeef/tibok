import 'package:flutter/material.dart';

import '../services/food_log_service.dart';
import '../services/supabase_service.dart';
import 'scanner_page.dart';

class MainDashboardPage extends StatefulWidget {
  const MainDashboardPage({super.key});

  @override
  State<MainDashboardPage> createState() => _MainDashboardPageState();
}

class _MainDashboardPageState extends State<MainDashboardPage> {
  final FoodLogService _foodLogService = FoodLogService();

  bool _isLoading = true;
  String? _errorMessage;

  Map<String, dynamic>? _healthProfile;
  List<Map<String, dynamic>> _todayLogs = [];

  int _todaySodium = 0;

  int get _dailyLimit {
    final value = _healthProfile?['daily_sodium_limit'];

    if (value is num) {
      return value.toInt();
    }

    return 2000;
  }

  bool get _hasHypertension => _healthProfile?['has_hypertension'] == true;

  int get _remainingSodium => _dailyLimit - _todaySodium;

  double get _progress {
    if (_dailyLimit <= 0) return 0;

    return (_todaySodium / _dailyLimit).clamp(0.0, 1.0);
  }

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final profile = await SupabaseService.getHealthProfile();
      final logs = await _foodLogService.getTodayLogs();

      var total = 0;

      for (final log in logs) {
        final sodium = log['sodium_amount'];

        if (sodium is num) {
          total += sodium.toInt();
        }
      }

      if (!mounted) return;

      setState(() {
        _healthProfile = profile;
        _todayLogs = logs;
        _todaySodium = total;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _handleSignOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Sign Out'),
          content: const Text(
            'Are you sure you want to log out? '
            'You will return to the welcome screen.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Sign Out'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await SupabaseService.signOut();
    }
  }

  Future<void> _openScanner() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ScannerPage(),
      ),
    );

    if (mounted) {
      await _loadDashboard();
    }
  }

  Future<void> _showManualFoodDialog() async {
    final foodController = TextEditingController();
    final sodiumController = TextEditingController();
    final servingsController = TextEditingController(text: '1');

    String? requestId;
    bool saving = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final sodiumPerServing = int.tryParse(
              sodiumController.text.trim(),
            );

            final servings = double.tryParse(
              servingsController.text.trim(),
            );

            int? calculatedTotal;

            if (sodiumPerServing != null &&
                sodiumPerServing >= 0 &&
                servings != null &&
                servings > 0) {
              calculatedTotal = (sodiumPerServing * servings).round();
            }

            return AlertDialog(
              title: const Text('Add Food'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Enter the food and sodium information from '
                      'its nutrition label.',
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: foodController,
                      enabled: !saving,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Food / Meal Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: sodiumController,
                      enabled: !saving,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      onChanged: (_) {
                        setDialogState(() {});
                      },
                      decoration: const InputDecoration(
                        labelText: 'Sodium per Serving',
                        suffixText: 'mg',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: servingsController,
                      enabled: !saving,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      onChanged: (_) {
                        setDialogState(() {});
                      },
                      decoration: const InputDecoration(
                        labelText: 'Servings Consumed',
                        hintText: 'e.g. 1, 1.5, 2',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Total Sodium',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            calculatedTotal == null
                                ? '-- mg'
                                : '$calculatedTotal mg',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Total sodium is calculated as sodium per serving '
                      '× servings consumed.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: saving
                      ? null
                      : () async {
                          final foodName = foodController.text.trim();

                          final sodiumPerServing = int.tryParse(
                            sodiumController.text.trim(),
                          );

                          final servings = double.tryParse(
                            servingsController.text.trim(),
                          );

                          if (foodName.isEmpty) {
                            _showMessage(
                              'Please enter a food name.',
                            );
                            return;
                          }

                          if (sodiumPerServing == null ||
                              sodiumPerServing < 0) {
                            _showMessage(
                              'Please enter a valid sodium amount '
                              'per serving.',
                            );
                            return;
                          }

                          if (servings == null || servings <= 0) {
                            _showMessage(
                              'Please enter a valid number of servings.',
                            );
                            return;
                          }

                          final totalSodium =
                              (sodiumPerServing * servings).round();

                          setDialogState(() {
                            saving = true;
                          });

                          requestId ??= _foodLogService.createRequestId();

                          try {
                            await _foodLogService.addFoodLog(
                              requestId: requestId!,
                              foodName: foodName,
                              sodiumAmount: totalSodium,
                              logDate: _foodLogService.philippineNow,
                              entryType: 'manual',
                              servings: servings,
                              sodiumPerServingMg: sodiumPerServing,
                            );

                            if (!dialogContext.mounted) return;

                            Navigator.pop(dialogContext);

                            _showMessage(
                              '$foodName added: '
                              '$totalSodium mg sodium.',
                            );

                            await _loadDashboard();
                          } catch (e) {
                            if (!dialogContext.mounted) return;

                            setDialogState(() {
                              saving = false;
                            });

                            _showMessage(
                              'Could not save food: $e',
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
                      : const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );

    foodController.dispose();
    sodiumController.dispose();
    servingsController.dispose();
  }

  Future<void> _showEditFoodDialog(
    Map<String, dynamic> log,
  ) async {
    final foodController = TextEditingController(
      text: log['food_name']?.toString() ?? '',
    );

    final sodiumController = TextEditingController(
      text: log['sodium_amount']?.toString() ?? '',
    );

    bool saving = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Food Entry'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: foodController,
                      enabled: !saving,
                      decoration: const InputDecoration(
                        labelText: 'Food / Meal Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: sodiumController,
                      enabled: !saving,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Sodium',
                        suffixText: 'mg',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: saving
                      ? null
                      : () async {
                          final name = foodController.text.trim();

                          final sodium = int.tryParse(
                            sodiumController.text.trim(),
                          );

                          if (name.isEmpty) {
                            _showMessage(
                              'Food name cannot be empty.',
                            );
                            return;
                          }

                          if (sodium == null || sodium < 0) {
                            _showMessage(
                              'Enter a valid sodium amount.',
                            );
                            return;
                          }

                          setDialogState(() {
                            saving = true;
                          });

                          try {
                            await _foodLogService.updateFoodLog(
                              logId: log['id'].toString(),
                              foodName: name,
                              sodiumAmount: sodium,
                              servings: 1,
                              sodiumPerServingMg: sodium,
                            );

                            if (!dialogContext.mounted) return;

                            Navigator.pop(dialogContext);

                            _showMessage(
                              'Food entry updated.',
                            );

                            await _loadDashboard();
                          } catch (e) {
                            if (!dialogContext.mounted) return;

                            setDialogState(() {
                              saving = false;
                            });

                            _showMessage(
                              'Could not update entry: $e',
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
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    foodController.dispose();
    sodiumController.dispose();
  }

  Future<void> _deleteFoodLog(
    Map<String, dynamic> log,
  ) async {
    final foodName = log['food_name']?.toString() ?? 'this food entry';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Food Entry'),
          content: Text(
            'Remove "$foodName" from today\'s sodium log?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      await _foodLogService.deleteFoodLog(
        log['id'].toString(),
      );

      _showMessage('Food entry deleted.');

      await _loadDashboard();
    } catch (e) {
      _showMessage(
        'Could not delete entry: $e',
      );
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
  }

  String _formatToday() {
    final date = _foodLogService.philippineNow;

    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tibok'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _isLoading ? null : _loadDashboard,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: _handleSignOut,
          ),
        ],
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
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 16),
              const Text(
                'Unable to load your dashboard.',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _loadDashboard,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDashboard,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          20,
          20,
          20,
          100,
        ),
        children: [
          _buildWelcomeSection(),
          const SizedBox(height: 20),
          _buildSodiumCard(),
          const SizedBox(height: 20),
          _buildQuickActions(),
          const SizedBox(height: 28),
          _buildTodayHeader(),
          const SizedBox(height: 12),
          _buildFoodLogs(),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Welcome to Tibok',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _formatToday(),
          style: TextStyle(
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildSodiumCard() {
    final isOver = _remainingSodium < 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.favorite,
                  color: isOver ? Colors.redAccent : Colors.green,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Daily Sodium',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  _hasHypertension ? 'DASH target' : 'Daily target',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              '$_todaySodium mg',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'of $_dailyLimit mg',
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: _progress,
              minHeight: 12,
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(height: 12),
            Text(
              isOver
                  ? '${_remainingSodium.abs()} mg over your daily target'
                  : '$_remainingSodium mg remaining today',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isOver ? Colors.redAccent : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: _openScanner,
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Scan Food'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                vertical: 16,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _showManualFoodDialog,
            icon: const Icon(Icons.add),
            label: const Text('Add Food'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                vertical: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTodayHeader() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Today\'s Food Log',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Text(
          '${_todayLogs.length} ${_todayLogs.length == 1 ? 'entry' : 'entries'}',
          style: TextStyle(
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildFoodLogs() {
    if (_todayLogs.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              Icon(
                Icons.restaurant_menu,
                size: 48,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 12),
              const Text(
                'No food logged today',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Scan a product or add a food manually.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: _todayLogs.map((log) {
        final sodium = (log['sodium_amount'] as num?)?.toInt() ?? 0;

        final entryType = log['entry_type']?.toString() ?? 'manual';

        final isScanned = entryType == 'scanned';

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: CircleAvatar(
              child: Icon(
                isScanned ? Icons.qr_code_scanner : Icons.restaurant,
              ),
            ),
            title: Text(
              log['food_name']?.toString() ?? 'Unnamed food',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              isScanned ? 'Scanned product' : 'Manual entry',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$sodium mg',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showEditFoodDialog(log);
                    } else if (value == 'delete') {
                      _deleteFoodLog(log);
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline,
                            color: Colors.redAccent,
                          ),
                          SizedBox(width: 8),
                          Text('Delete'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
