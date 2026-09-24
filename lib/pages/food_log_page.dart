import 'package:flutter/material.dart';

import '../services/food_log_service.dart';
import '../utils/sodium_rating.dart';

class FoodLogPage extends StatefulWidget {
  const FoodLogPage({super.key});

  @override
  State<FoodLogPage> createState() => _FoodLogPageState();
}

class _FoodLogPageState extends State<FoodLogPage> {
  final FoodLogService _service = FoodLogService();

  final DateTime _earliestDate = DateTime(2000);
  late DateTime _selectedDate;
  int _loadVersion = 0;

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
    final today = _service.philippineNow;
    _selectedDate = DateTime(today.year, today.month, today.day);
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    final version = ++_loadVersion;
    final date = _selectedDate;
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final logs = await _service.getLogsForDate(date);

      if (!mounted || version != _loadVersion) {
        return;
      }

      setState(() {
        _logs = logs;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted || version != _loadVersion) {
        return;
      }

      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _changeDate(int days) {
    final today = _service.philippineNow;
    final next = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day + days,
    );
    final currentDay = DateTime(today.year, today.month, today.day);
    if (next.isAfter(currentDay) || next.isBefore(_earliestDate)) return;
    setState(() => _selectedDate = next);
    _loadLogs();
  }

  Future<void> _pickDate() async {
    final today = _service.philippineNow;
    final selected = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: _earliestDate,
      lastDate: DateTime(today.year, today.month, today.day),
    );
    if (selected == null || !mounted) return;
    setState(() => _selectedDate = selected);
    _loadLogs();
  }

  Future<void> _showEditDialog(Map<String, dynamic> log) async {
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

    final updated = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final sodiumPer100g = double.tryParse(sodiumController.text.trim());

            final grams = double.tryParse(gramsController.text.trim());

            final total = sodiumPer100g != null &&
                    sodiumPer100g >= 0 &&
                    grams != null &&
                    grams > 0
                ? (sodiumPer100g * grams / 100).round()
                : null;

            return AlertDialog(
              title: const Text('Edit Food Entry'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (existingBasis != 'per_100g') ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline, color: Colors.orange),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'This entry does not have a confirmed per-100 g basis. '
                                'Enter the correct values below. Saving will convert it '
                                'to the current Tibok format.',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    TextField(
                      controller: nameController,
                      enabled: !saving,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Food Name',
                        prefixIcon: Icon(Icons.restaurant_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: sodiumController,
                      enabled: !saving,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textInputAction: TextInputAction.next,
                      onChanged: (_) {
                        setDialogState(() {});
                      },
                      decoration: const InputDecoration(
                        labelText: 'Sodium per 100 g',
                        suffixText: 'mg',
                        helperText: 'Use the nutrition label or food estimate.',
                        prefixIcon: Icon(Icons.water_drop_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: gramsController,
                      enabled: !saving,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textInputAction: TextInputAction.done,
                      onChanged: (_) {
                        setDialogState(() {});
                      },
                      decoration: const InputDecoration(
                        labelText: 'Amount Consumed',
                        suffixText: 'g',
                        prefixIcon: Icon(Icons.scale_outlined),
                      ),
                    ),
                    if (sodiumPer100g != null && sodiumPer100g >= 0) ...[
                      const SizedBox(height: 16),
                      _buildTrafficLight(sodiumPer100g),
                    ],
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color:
                            Theme.of(context).colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Total Sodium',
                              style: TextStyle(fontWeight: FontWeight.w600),
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
                      const SizedBox(height: 12),
                      Text(
                        dialogError!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
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
                          FocusManager.instance.primaryFocus?.unfocus();

                          Navigator.of(dialogContext).pop(false);
                        },
                  child: const Text('Cancel'),
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
                            setDialogState(() {
                              dialogError = 'Food name cannot be empty.';
                            });
                            return;
                          }

                          if (sodium == null || sodium < 0) {
                            setDialogState(() {
                              dialogError = 'Enter a valid sodium amount.';
                            });
                            return;
                          }

                          if (grams == null || grams <= 0) {
                            setDialogState(() {
                              dialogError = 'Enter a valid amount consumed.';
                            });
                            return;
                          }

                          final total = (sodium * grams / 100).round();

                          setDialogState(() {
                            saving = true;
                            dialogError = null;
                          });

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

                            FocusManager.instance.primaryFocus?.unfocus();

                            Navigator.of(dialogContext).pop(true);
                          } catch (e) {
                            if (!dialogContext.mounted) {
                              return;
                            }

                            setDialogState(() {
                              saving = false;
                              dialogError = 'Could not update food entry.';
                            });
                          }
                        },
                  child: saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save Changes'),
                ),
              ],
            );
          },
        );
      },
    );

    await Future<void>.delayed(const Duration(milliseconds: 350));

    nameController.dispose();
    sodiumController.dispose();
    gramsController.dispose();

    if (!mounted) {
      return;
    }

    if (updated == true) {
      await _loadLogs();

      if (!mounted) {
        return;
      }

      _showMessage('Food entry updated.');
    }
  }

  Future<void> _deleteLog(Map<String, dynamic> log) async {
    final name = log['food_name']?.toString() ?? 'this food entry';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Food Entry'),
          content: Text('Remove "$name" from this day\'s food log?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              icon: const Icon(Icons.delete_outline),
              label: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await _service.deleteFoodLog(log['id'].toString());

      await _loadLogs();

      if (!mounted) {
        return;
      }

      _showMessage('Food entry deleted.');
    } catch (e) {
      _showMessage('Could not delete entry.');
    }
  }

  Widget _buildTrafficLight(double sodiumPer100g) {
    final color = SodiumRating.colorFor(sodiumPer100g);

    final label = SodiumRating.labelFor(sodiumPer100g);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(SodiumRating.iconFor(sodiumPer100g), color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 3),
                Text(
                  '${sodiumPer100g.round()} mg per 100 g',
                  style: TextStyle(color: color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatSelectedDate() {
    final date = _selectedDate;

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

  String _entryTypeLabel(String entryType) {
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Food Log')),
      body: RefreshIndicator(onRefresh: _loadLogs, child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(
            height: 350,
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 30),
      children: [
        _buildDateNavigation(),
        const SizedBox(height: 12),
        _buildSummaryCard(),
        const SizedBox(height: 20),
        if (_logs.isNotEmpty)
          Text(
            '${_logs.length} food ${_logs.length == 1 ? 'entry' : 'entries'} on this day',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        if (_logs.isNotEmpty) const SizedBox(height: 10),
        if (_logs.isEmpty) _buildEmptyState() else ..._logs.map(_buildLogCard),
      ],
    );
  }

  Widget _buildDateNavigation() {
    final today = _service.philippineNow;
    final currentDay = DateTime(today.year, today.month, today.day);
    final isToday = !_selectedDate.isBefore(currentDay);
    final isEarliest = !_selectedDate.isAfter(_earliestDate);
    return Row(
      children: [
        IconButton(
          tooltip: 'Previous day',
          onPressed: isEarliest ? null : () => _changeDate(-1),
          icon: const Icon(Icons.chevron_left),
        ),
        Expanded(
          child: TextButton(
            onPressed: _pickDate,
            child: Text(
              _formatSelectedDate(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
        IconButton(
          tooltip: 'Next day',
          onPressed: isToday ? null : () => _changeDate(1),
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }

  Widget _buildSummaryCard() {
    final theme = Theme.of(context);

    final colors = theme.colorScheme;

    return Card(
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.07),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: colors.primary.withValues(alpha: 0.15)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.water_drop_outlined,
                color: colors.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Sodium on This Day',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$_totalSodium mg',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);

    final colors = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 42, horizontal: 24),
        child: Column(
          children: [
            Icon(
              Icons.restaurant_menu_rounded,
              size: 54,
              color: colors.outline,
            ),
            const SizedBox(height: 14),
            Text(
              'No food logged on this day',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            Text(
              'Choose another date to check your food history.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogCard(Map<String, dynamic> log) {
    final theme = Theme.of(context);

    final colors = theme.colorScheme;

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

      quantityText =
          '${grams.toStringAsFixed(grams % 1 == 0 ? 0 : 1)} g consumed';
    } else if (sodiumBasis == 'per_serving' && storedServings != null) {
      quantityText =
          '${storedServings.toStringAsFixed(storedServings % 1 == 0 ? 0 : 1)} serving${storedServings == 1 ? '' : 's'}';
    } else {
      quantityText = 'Quantity basis unavailable';
    }

    final indicatorColor = sodiumPer100g != null
        ? SodiumRating.colorFor(sodiumPer100g)
        : colors.onSurfaceVariant;

    final statusLabel = sodiumPer100g != null
        ? SodiumRating.labelFor(sodiumPer100g)
        : 'Sodium basis unavailable';

    final statusIcon = sodiumPer100g != null
        ? SodiumRating.iconFor(sodiumPer100g)
        : entryType == 'scanned'
            ? Icons.qr_code_scanner_rounded
            : Icons.info_outline;

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: indicatorColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(statusIcon, color: indicatorColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        log['food_name']?.toString() ?? 'Unnamed food',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$quantityText • '
                        '${_entryTypeLabel(entryType)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '$sodium mg',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(statusIcon, size: 18, color: indicatorColor),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    sodiumPer100g != null
                        ? '$statusLabel • ${sodiumPer100g.round()} mg per 100 g'
                        : statusLabel,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: indicatorColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () {
                    _showEditDialog(log);
                  },
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  label: const Text('Edit'),
                ),
                const SizedBox(width: 4),
                TextButton.icon(
                  onPressed: () {
                    _deleteLog(log);
                  },
                  style: TextButton.styleFrom(foregroundColor: colors.error),
                  icon: const Icon(Icons.delete_outline, size: 20),
                  label: const Text('Delete'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    final theme = Theme.of(context);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 100),
        Icon(Icons.error_outline, size: 60, color: theme.colorScheme.error),
        const SizedBox(height: 14),
        Text(
          'Unable to load your food log.',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: _loadLogs,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Try Again'),
        ),
      ],
    );
  }
}
