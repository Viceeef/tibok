import 'package:flutter/material.dart';

import '../services/food_log_service.dart';

class FoodLogPage extends StatefulWidget {
  const FoodLogPage({
    super.key,
  });

  @override
  State<FoodLogPage> createState() => _FoodLogPageState();
}

class _FoodLogPageState extends State<FoodLogPage> {
  final FoodLogService _service = FoodLogService();

  bool _isLoading = true;
  String? _errorMessage;

  List<Map<String, dynamic>> _logs = [];

  int get _totalSodium {
    var total = 0;

    for (final log in _logs) {
      final sodium = log['sodium_amount'];

      if (sodium is num) {
        total += sodium.toInt();
      }
    }

    return total;
  }

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final logs = await _service.getTodayLogs();

      if (!mounted) return;

      setState(() {
        _logs = logs;
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

  Future<void> _showEditDialog(
    Map<String, dynamic> log,
  ) async {
    final nameController = TextEditingController(
      text: log['food_name']?.toString() ?? '',
    );

    final sodiumPerServing = (log['sodium_per_serving_mg'] as num?)?.toInt() ??
        (log['sodium_amount'] as num?)?.toInt() ??
        0;

    final servings = (log['servings'] as num?)?.toDouble() ?? 1.0;

    final sodiumController = TextEditingController(
      text: sodiumPerServing.toString(),
    );

    final servingsController = TextEditingController(
      text: servings.toString(),
    );

    bool saving = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (
            context,
            setDialogState,
          ) {
            final sodium = int.tryParse(
              sodiumController.text.trim(),
            );

            final servingCount = double.tryParse(
              servingsController.text.trim(),
            );

            final total = sodium != null &&
                    sodium >= 0 &&
                    servingCount != null &&
                    servingCount > 0
                ? (sodium * servingCount).round()
                : null;

            return AlertDialog(
              title: const Text(
                'Edit Food Entry',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: nameController,
                      enabled: !saving,
                      decoration: const InputDecoration(
                        labelText: 'Food / Meal Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    TextField(
                      controller: sodiumController,
                      enabled: !saving,
                      keyboardType: TextInputType.number,
                      onChanged: (_) {
                        setDialogState(
                          () {},
                        );
                      },
                      decoration: const InputDecoration(
                        labelText: 'Sodium per Serving',
                        suffixText: 'mg',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    TextField(
                      controller: servingsController,
                      enabled: !saving,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      onChanged: (_) {
                        setDialogState(
                          () {},
                        );
                      },
                      decoration: const InputDecoration(
                        labelText: 'Servings Consumed',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(
                      height: 14,
                    ),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
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
                            total == null ? '-- mg' : '$total mg',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving
                      ? null
                      : () {
                          Navigator.pop(
                            dialogContext,
                          );
                        },
                  child: const Text(
                    'Cancel',
                  ),
                ),
                FilledButton(
                  onPressed: saving
                      ? null
                      : () async {
                          final name = nameController.text.trim();

                          final sodium = int.tryParse(
                            sodiumController.text.trim(),
                          );

                          final servings = double.tryParse(
                            servingsController.text.trim(),
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

                          if (servings == null || servings <= 0) {
                            _showMessage(
                              'Enter valid servings.',
                            );
                            return;
                          }

                          final total = (sodium * servings).round();

                          setDialogState(
                            () {
                              saving = true;
                            },
                          );

                          try {
                            await _service.updateFoodLog(
                              logId: log['id'].toString(),
                              foodName: name,
                              sodiumAmount: total,
                              servings: servings,
                              sodiumPerServingMg: sodium,
                            );

                            if (!dialogContext.mounted) {
                              return;
                            }

                            Navigator.pop(
                              dialogContext,
                            );

                            _showMessage(
                              'Food entry updated.',
                            );

                            await _loadLogs();
                          } catch (e) {
                            if (!dialogContext.mounted) {
                              return;
                            }

                            setDialogState(
                              () {
                                saving = false;
                              },
                            );

                            _showMessage(
                              'Could not update entry.',
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
                          'Save',
                        ),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    sodiumController.dispose();
    servingsController.dispose();
  }

  Future<void> _deleteLog(
    Map<String, dynamic> log,
  ) async {
    final name = log['food_name']?.toString() ?? 'this food entry';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Delete Food Entry',
          ),
          content: Text(
            'Remove "$name" from today\'s food log?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _service.deleteFoodLog(
        log['id'].toString(),
      );

      _showMessage(
        'Food entry deleted.',
      );

      await _loadLogs();
    } catch (e) {
      _showMessage(
        'Could not delete entry.',
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
    final date = _service.philippineNow;

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

    return '${months[date.month - 1]} '
        '${date.day}, ${date.year}';
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Food Log',
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadLogs,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(
            height: 350,
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),
        ],
      );
    }

    if (_errorMessage != null) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 100),
          const Icon(
            Icons.error_outline,
            size: 60,
            color: Colors.redAccent,
          ),
          const SizedBox(height: 14),
          const Text(
            'Unable to load your food log.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _loadLogs,
            icon: const Icon(
              Icons.refresh,
            ),
            label: const Text(
              'Try Again',
            ),
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        16,
        16,
        16,
        30,
      ),
      children: [
        Text(
          _formatToday(),
          style: TextStyle(
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(
              18,
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Total Sodium Today',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '$_totalSodium mg',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        if (_logs.isEmpty)
          _buildEmptyState()
        else
          ..._logs.map(
            _buildLogCard,
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 70,
      ),
      child: Column(
        children: [
          Icon(
            Icons.restaurant_menu,
            size: 58,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 14),
          const Text(
            'No food logged today',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogCard(
    Map<String, dynamic> log,
  ) {
    final sodium = (log['sodium_amount'] as num?)?.toInt() ?? 0;

    final servings = (log['servings'] as num?)?.toDouble() ?? 1;

    final entryType = log['entry_type']?.toString() ?? 'manual';

    return Card(
      margin: const EdgeInsets.only(
        bottom: 10,
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.redAccent.withValues(
            alpha: 0.10,
          ),
          child: Icon(
            entryType == 'scanned' ? Icons.qr_code_scanner : Icons.restaurant,
            color: Colors.redAccent,
          ),
        ),
        title: Text(
          log['food_name']?.toString() ?? 'Unnamed food',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          '${servings.toStringAsFixed(servings % 1 == 0 ? 0 : 1)} '
          '${servings == 1 ? 'serving' : 'servings'}'
          ' • ${entryType == 'scanned' ? 'Scanned' : 'Food entry'}',
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
                  _showEditDialog(log);
                }

                if (value == 'delete') {
                  _deleteLog(log);
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
  }
}
