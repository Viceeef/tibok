import 'package:flutter/material.dart';

import '../services/food_log_service.dart';
import '../utils/sodium_rating.dart';

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

    final existingBasis = log['sodium_basis']?.toString() ?? 'unknown';

    final existingSodium = (log['sodium_per_serving_mg'] as num?)?.toDouble() ??
        (log['sodium_amount'] as num?)?.toDouble() ??
        0;

    final existingServings = (log['servings'] as num?)?.toDouble() ?? 1;

    final initialGrams =
        existingBasis == 'per_100g' ? existingServings * 100 : 100.0;

    final sodiumController = TextEditingController(
      text: existingSodium.round().toString(),
    );

    final gramsController = TextEditingController(
      text: initialGrams % 1 == 0
          ? initialGrams.round().toString()
          : initialGrams.toStringAsFixed(1),
    );

    bool saving = false;
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
            final sodiumPer100g = double.tryParse(
              sodiumController.text.trim(),
            );

            final grams = double.tryParse(
              gramsController.text.trim(),
            );

            final total = sodiumPer100g != null &&
                    sodiumPer100g >= 0 &&
                    grams != null &&
                    grams > 0
                ? (sodiumPer100g * grams / 100).round()
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
                    if (existingBasis != 'per_100g') ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(
                            alpha: 0.10,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'This older entry does not have a confirmed '
                          'per-100 g nutrition basis. Enter the correct '
                          'values below. Saving will update it to the '
                          'current Tibok format.',
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.35,
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 14,
                      ),
                    ],
                    TextField(
                      controller: nameController,
                      enabled: !saving,
                      decoration: const InputDecoration(
                        labelText: 'Food Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    TextField(
                      controller: sodiumController,
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
                        labelText: 'Sodium per 100 g',
                        suffixText: 'mg',
                        helperText: 'Use the nutrition label or food estimate.',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    TextField(
                      controller: gramsController,
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
                        labelText: 'Amount Consumed',
                        suffixText: 'g',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    if (sodiumPer100g != null && sodiumPer100g >= 0) ...[
                      const SizedBox(
                        height: 16,
                      ),
                      _buildTrafficLight(
                        sodiumPer100g,
                      ),
                    ],
                    const SizedBox(
                      height: 16,
                    ),
                    Container(
                      padding: const EdgeInsets.all(
                        14,
                      ),
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
                    if (dialogError != null) ...[
                      const SizedBox(
                        height: 12,
                      ),
                      Text(
                        dialogError!,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 12,
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
                          final name = nameController.text.trim();

                          final sodium = double.tryParse(
                            sodiumController.text.trim(),
                          );

                          final grams = double.tryParse(
                            gramsController.text.trim(),
                          );

                          if (name.isEmpty) {
                            setDialogState(
                              () {
                                dialogError = 'Food name cannot be empty.';
                              },
                            );
                            return;
                          }

                          if (sodium == null || sodium < 0) {
                            setDialogState(
                              () {
                                dialogError = 'Enter a valid sodium amount.';
                              },
                            );
                            return;
                          }

                          if (grams == null || grams <= 0) {
                            setDialogState(
                              () {
                                dialogError = 'Enter a valid amount consumed.';
                              },
                            );
                            return;
                          }

                          final total = (sodium * grams / 100).round();

                          setDialogState(
                            () {
                              saving = true;
                              dialogError = null;
                            },
                          );

                          try {
                            await _service.updateFoodLog(
                              logId: log['id'].toString(),
                              foodName: name,
                              sodiumAmount: total,
                              servings: grams / 100,
                              sodiumPerServingMg: sodium.round(),
                              sodiumBasis: 'per_100g',
                            );

                            if (!dialogContext.mounted) {
                              return;
                            }

                            Navigator.of(
                              dialogContext,
                            ).pop();

                            await _loadLogs();

                            _showMessage(
                              'Food entry updated.',
                            );
                          } catch (e) {
                            if (!dialogContext.mounted) {
                              return;
                            }

                            setDialogState(
                              () {
                                saving = false;
                                dialogError = 'Could not update food entry.';
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

    nameController.dispose();
    sodiumController.dispose();
    gramsController.dispose();
  }

  Future<void> _deleteLog(
    Map<String, dynamic> log,
  ) async {
    final name = log['food_name']?.toString() ?? 'this food entry';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (
        dialogContext,
      ) {
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
                Navigator.of(
                  dialogContext,
                ).pop(false);
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
                ).pop(true);
              },
              child: const Text(
                'Delete',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

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

  Widget _buildTrafficLight(
    double sodiumPer100g,
  ) {
    final color = SodiumRating.colorFor(
      sodiumPer100g,
    );

    final label = SodiumRating.labelFor(
      sodiumPer100g,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: 0.10,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withValues(
            alpha: 0.30,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            SodiumRating.iconFor(
              sodiumPer100g,
            ),
            color: color,
          ),
          const SizedBox(
            width: 12,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(
                  height: 3,
                ),
                Text(
                  '${sodiumPer100g.round()} mg per 100 g',
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showMessage(
    String message,
  ) {
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

  String _entryTypeLabel(
    String entryType,
  ) {
    switch (entryType) {
      case 'searched':
        return 'Common Food';

      case 'scanned':
        return 'Scanned';

      case 'manual':
      default:
        return 'Manual';
    }
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
          const SizedBox(
            height: 100,
          ),
          const Icon(
            Icons.error_outline,
            size: 60,
            color: Colors.redAccent,
          ),
          const SizedBox(
            height: 14,
          ),
          const Text(
            'Unable to load your food log.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(
            height: 16,
          ),
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
        const SizedBox(
          height: 12,
        ),
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
        const SizedBox(
          height: 18,
        ),
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
          const SizedBox(
            height: 14,
          ),
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

    final entryType = log['entry_type']?.toString() ?? 'manual';

    final sodiumBasis = log['sodium_basis']?.toString() ?? 'unknown';

    final sodiumPer100g = sodiumBasis == 'per_100g'
        ? (log['sodium_per_serving_mg'] as num?)?.toDouble()
        : null;

    final storedServings = (log['servings'] as num?)?.toDouble();

    String quantityText;

    if (sodiumBasis == 'per_100g' && storedServings != null) {
      final grams = storedServings * 100;

      quantityText = '${grams.toStringAsFixed(
        grams % 1 == 0 ? 0 : 1,
      )} g consumed';
    } else if (sodiumBasis == 'per_serving' && storedServings != null) {
      quantityText = '${storedServings.toStringAsFixed(
        storedServings % 1 == 0 ? 0 : 1,
      )} serving${storedServings == 1 ? '' : 's'}';
    } else {
      quantityText = 'Quantity basis unavailable';
    }

    final indicatorColor = sodiumPer100g != null
        ? SodiumRating.colorFor(
            sodiumPer100g,
          )
        : Colors.grey;

    return Card(
      margin: const EdgeInsets.only(
        bottom: 10,
      ),
      child: ListTile(
        isThreeLine: true,
        leading: CircleAvatar(
          backgroundColor: indicatorColor.withValues(
            alpha: 0.12,
          ),
          child: Icon(
            sodiumPer100g != null
                ? SodiumRating.iconFor(
                    sodiumPer100g,
                  )
                : entryType == 'scanned'
                    ? Icons.qr_code_scanner
                    : Icons.help_outline,
            color: indicatorColor,
          ),
        ),
        title: Text(
          log['food_name']?.toString() ?? 'Unnamed food',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(
              height: 2,
            ),
            Text(
              '$quantityText • '
              '${_entryTypeLabel(entryType)}',
            ),
            const SizedBox(
              height: 3,
            ),
            if (sodiumPer100g != null)
              Text(
                '${SodiumRating.labelFor(sodiumPer100g)}'
                ' • ${sodiumPer100g.round()} mg/100 g',
                style: TextStyle(
                  color: SodiumRating.colorFor(
                    sodiumPer100g,
                  ),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              )
            else
              Text(
                'Sodium basis unavailable',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 11,
                ),
              ),
          ],
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
                  _showEditDialog(
                    log,
                  );
                }

                if (value == 'delete') {
                  _deleteLog(
                    log,
                  );
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(
                        Icons.edit,
                      ),
                      SizedBox(
                        width: 8,
                      ),
                      Text(
                        'Edit',
                      ),
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
                      SizedBox(
                        width: 8,
                      ),
                      Text(
                        'Delete',
                      ),
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
