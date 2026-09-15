import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/blood_pressure_service.dart';

class BloodPressurePage extends StatefulWidget {
  const BloodPressurePage({
    super.key,
  });

  @override
  State<BloodPressurePage> createState() => _BloodPressurePageState();
}

class _BloodPressurePageState extends State<BloodPressurePage> {
  final BloodPressureService _service = BloodPressureService();

  bool _isLoading = true;
  String? _errorMessage;

  List<Map<String, dynamic>> _readings = [];

  String _viewMode = 'List';
  int _trendDays = 7;

  @override
  void initState() {
    super.initState();

    _loadReadings();
  }

  Future<void> _loadReadings() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final readings = await _service.getRecentReadings();

      if (!mounted) {
        return;
      }

      setState(() {
        _readings = readings;
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

  DateTime? _readingDate(
    Map<String, dynamic> reading,
  ) {
    final value = reading['logged_at']?.toString();

    if (value == null) {
      return null;
    }

    return DateTime.tryParse(
      value,
    )?.toLocal();
  }

  List<Map<String, dynamic>> get _filteredTrendReadings {
    final cutoff = DateTime.now().subtract(
      Duration(
        days: _trendDays,
      ),
    );

    final filtered = _readings.where(
      (reading) {
        final date = _readingDate(reading);

        if (date == null) {
          return false;
        }

        return date.isAfter(cutoff) ||
            _isSameDay(
              date,
              cutoff,
            );
      },
    ).toList();

    filtered.sort(
      (
        a,
        b,
      ) {
        final aDate = _readingDate(a) ??
            DateTime.fromMillisecondsSinceEpoch(
              0,
            );

        final bDate = _readingDate(b) ??
            DateTime.fromMillisecondsSinceEpoch(
              0,
            );

        return aDate.compareTo(
          bDate,
        );
      },
    );

    return filtered;
  }

  bool _isSameDay(
    DateTime a,
    DateTime b,
  ) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Map<String, dynamic>? get _latestReading {
    if (_readings.isEmpty) {
      return null;
    }

    return _readings.first;
  }

  Future<void> _showAddReadingDialog() async {
    final systolicController = TextEditingController();

    final diastolicController = TextEditingController();

    final heartRateController = TextEditingController();

    final notesController = TextEditingController();

    bool saving = false;
    String? dialogError;

    final saved = await showDialog<bool>(
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
                'Log Blood Pressure',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Enter the values shown on your blood pressure monitor.',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium,
                    ),
                    const SizedBox(
                      height: 18,
                    ),
                    TextField(
                      controller: systolicController,
                      enabled: !saving,
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
                    ),
                    const SizedBox(
                      height: 14,
                    ),
                    TextField(
                      controller: diastolicController,
                      enabled: !saving,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
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
                    ),
                    const SizedBox(
                      height: 14,
                    ),
                    TextField(
                      controller: heartRateController,
                      enabled: !saving,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(
                          3,
                        ),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Heart Rate',
                        hintText: 'Example: 72',
                        suffixText: 'bpm',
                        prefixIcon: Icon(
                          Icons.monitor_heart_outlined,
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 14,
                    ),
                    TextField(
                      controller: notesController,
                      enabled: !saving,
                      minLines: 2,
                      maxLines: 4,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        labelText: 'Notes (optional)',
                        hintText: 'How were you feeling?',
                        prefixIcon: Icon(
                          Icons.notes_outlined,
                        ),
                        alignLabelWithHint: true,
                      ),
                    ),
                    if (dialogError != null) ...[
                      const SizedBox(
                        height: 14,
                      ),
                      Container(
                        padding: const EdgeInsets.all(
                          12,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(
                            12,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Theme.of(
                                context,
                              ).colorScheme.onErrorContainer,
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                            Expanded(
                              child: Text(
                                dialogError!,
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onErrorContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
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
                        ).colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(
                          14,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 22,
                            color: Theme.of(
                              context,
                            ).colorScheme.primary,
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          const Expanded(
                            child: Text(
                              'Blood pressure categories are provided for tracking purposes. '
                              'A single reading does not establish a diagnosis.',
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
                          FocusManager.instance.primaryFocus?.unfocus();

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
                FilledButton.icon(
                  onPressed: saving
                      ? null
                      : () async {
                          final systolic = int.tryParse(
                            systolicController.text.trim(),
                          );

                          final diastolic = int.tryParse(
                            diastolicController.text.trim(),
                          );

                          final heartRate = int.tryParse(
                            heartRateController.text.trim(),
                          );

                          if (systolic == null ||
                              diastolic == null ||
                              heartRate == null) {
                            setDialogState(
                              () {
                                dialogError =
                                    'Enter valid numeric values for systolic, diastolic, and heart rate.';
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
                            await _service.addReading(
                              systolic: systolic,
                              diastolic: diastolic,
                              heartRate: heartRate,
                              notes: notesController.text.trim(),
                            );

                            if (!dialogContext.mounted) {
                              return;
                            }

                            FocusManager.instance.primaryFocus?.unfocus();

                            Navigator.of(
                              dialogContext,
                            ).pop(
                              true,
                            );
                          } catch (e) {
                            if (!dialogContext.mounted) {
                              return;
                            }

                            setDialogState(
                              () {
                                saving = false;

                                dialogError = e.toString().replaceFirst(
                                      'Exception: ',
                                      '',
                                    );
                              },
                            );
                          }
                        },
                  icon: saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
                          Icons.check_rounded,
                        ),
                  label: Text(
                    saving ? 'Saving...' : 'Save Reading',
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    //
    // IMPORTANT:
    // Let the keyboard, dialog route, focus nodes,
    // MediaQuery dependents, and TextFields completely
    // detach before disposing these controllers.
    //
    await Future<void>.delayed(
      const Duration(
        milliseconds: 350,
      ),
    );

    systolicController.dispose();
    diastolicController.dispose();
    heartRateController.dispose();
    notesController.dispose();

    if (!mounted) {
      return;
    }

    if (saved == true) {
      await _loadReadings();

      if (!mounted) {
        return;
      }

      _showMessage(
        'Blood pressure saved.',
      );
    }
  }

  Future<void> _deleteReading(
    Map<String, dynamic> reading,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (
        dialogContext,
      ) {
        return AlertDialog(
          title: const Text(
            'Delete Reading',
          ),
          content: const Text(
            'Remove this blood pressure reading?',
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
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.error,
                foregroundColor: Theme.of(
                  context,
                ).colorScheme.onError,
              ),
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(
                  true,
                );
              },
              icon: const Icon(
                Icons.delete_outline,
              ),
              label: const Text(
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
      await _service.deleteReading(
        reading['id'].toString(),
      );

      await _loadReadings();

      _showMessage(
        'Reading deleted.',
      );
    } catch (e) {
      _showMessage(
        'Could not delete reading.',
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

  Color _categoryColor(
    String category,
  ) {
    switch (category) {
      case 'Normal':
        return Colors.green.shade700;

      case 'Elevated':
        return Colors.amber.shade800;

      case 'Stage 1 Hypertension':
        return Colors.orange.shade800;

      case 'Stage 2 Hypertension':
        return Colors.deepOrange.shade700;

      case 'Severe Hypertension':
        return Colors.red.shade800;

      default:
        return Colors.grey.shade700;
    }
  }

  IconData _categoryIcon(
    String category,
  ) {
    switch (category) {
      case 'Normal':
        return Icons.check_circle_outline;

      case 'Elevated':
        return Icons.info_outline;

      case 'Stage 1 Hypertension':
      case 'Stage 2 Hypertension':
        return Icons.warning_amber_rounded;

      case 'Severe Hypertension':
        return Icons.error_outline;

      default:
        return Icons.help_outline;
    }
  }

  String _shortDate(
    DateTime date,
  ) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${months[date.month - 1]} ${date.day}';
  }

  String _fullDate(
    DateTime date,
  ) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final hour = date.hour == 0
        ? 12
        : date.hour > 12
            ? date.hour - 12
            : date.hour;

    final minute = date.minute.toString().padLeft(
          2,
          '0',
        );

    final period = date.hour >= 12 ? 'PM' : 'AM';

    return '${months[date.month - 1]} ${date.day}, '
        '${date.year} • $hour:$minute $period';
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Blood Pressure',
        ),
        actions: [
          IconButton(
            tooltip: 'Log Blood Pressure',
            onPressed: _showAddReadingDialog,
            icon: const Icon(
              Icons.add_rounded,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddReadingDialog,
        icon: const Icon(
          Icons.add_rounded,
        ),
        label: const Text(
          'Log BP',
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadReadings,
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
        padding: const EdgeInsets.all(
          24,
        ),
        children: [
          const SizedBox(
            height: 100,
          ),
          Icon(
            Icons.error_outline,
            size: 60,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(
            height: 14,
          ),
          Text(
            'Unable to load blood pressure history.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(
            height: 16,
          ),
          FilledButton.icon(
            onPressed: _loadReadings,
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
        18,
        12,
        18,
        100,
      ),
      children: [
        if (_latestReading != null)
          _buildLatestCard(
            _latestReading!,
          ),
        if (_latestReading != null)
          const SizedBox(
            height: 18,
          ),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(
              value: 'List',
              icon: Icon(
                Icons.list_alt,
              ),
              label: Text(
                'History',
              ),
            ),
            ButtonSegment(
              value: 'Trends',
              icon: Icon(
                Icons.show_chart,
              ),
              label: Text(
                'Trends',
              ),
            ),
          ],
          selected: {
            _viewMode,
          },
          onSelectionChanged: (
            selection,
          ) {
            setState(() {
              _viewMode = selection.first;
            });
          },
        ),
        const SizedBox(
          height: 20,
        ),
        if (_viewMode == 'List') _buildHistory() else _buildTrends(),
      ],
    );
  }

  Widget _buildLatestCard(
    Map<String, dynamic> reading,
  ) {
    final systolic = (reading['systolic'] as num?)?.toInt() ?? 0;

    final diastolic = (reading['diastolic'] as num?)?.toInt() ?? 0;

    final heartRate = (reading['heart_rate'] as num?)?.toInt() ?? 0;

    final category = reading['category']?.toString() ??
        _service.classifyReading(
          systolic: systolic,
          diastolic: diastolic,
        );

    final date = _readingDate(
      reading,
    );

    final color = _categoryColor(
      category,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(
          20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Latest Reading',
              style: Theme.of(
                context,
              ).textTheme.titleLarge,
            ),
            const SizedBox(
              height: 12,
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: color.withValues(
                  alpha: 0.12,
                ),
                borderRadius: BorderRadius.circular(
                  999,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _categoryIcon(
                      category,
                    ),
                    size: 19,
                    color: color,
                  ),
                  const SizedBox(
                    width: 6,
                  ),
                  Flexible(
                    child: Text(
                      category,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(
              height: 18,
            ),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.end,
              spacing: 8,
              runSpacing: 4,
              children: [
                Text(
                  '$systolic/$diastolic',
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(
                    bottom: 6,
                  ),
                  child: Text(
                    'mmHg',
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 10,
            ),
            Row(
              children: [
                Icon(
                  Icons.monitor_heart_outlined,
                  size: 21,
                  color: Theme.of(
                    context,
                  ).colorScheme.primary,
                ),
                const SizedBox(
                  width: 8,
                ),
                Expanded(
                  child: Text(
                    'Heart rate: $heartRate bpm',
                  ),
                ),
              ],
            ),
            if (date != null) ...[
              const SizedBox(
                height: 8,
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.schedule_outlined,
                    size: 20,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  Expanded(
                    child: Text(
                      _fullDate(
                        date,
                      ),
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(
              height: 16,
            ),
            Text(
              'Category is based on the recorded reading. '
              'A single measurement does not establish a diagnosis.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistory() {
    if (_readings.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: _readings
          .map(
            _buildReadingCard,
          )
          .toList(),
    );
  }

  Widget _buildReadingCard(
    Map<String, dynamic> reading,
  ) {
    final systolic = (reading['systolic'] as num?)?.toInt() ?? 0;

    final diastolic = (reading['diastolic'] as num?)?.toInt() ?? 0;

    final heartRate = (reading['heart_rate'] as num?)?.toInt() ?? 0;

    final category = reading['category']?.toString() ??
        _service.classifyReading(
          systolic: systolic,
          diastolic: diastolic,
        );

    final notes = reading['notes']?.toString();

    final date = _readingDate(
      reading,
    );

    final color = _categoryColor(
      category,
    );

    return Card(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      child: Padding(
        padding: const EdgeInsets.all(
          16,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 6,
              constraints: const BoxConstraints(
                minHeight: 92,
              ),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(
                  10,
                ),
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
                    '$systolic/$diastolic mmHg',
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge,
                  ),
                  const SizedBox(
                    height: 6,
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        _categoryIcon(
                          category,
                        ),
                        size: 19,
                        color: color,
                      ),
                      const SizedBox(
                        width: 6,
                      ),
                      Expanded(
                        child: Text(
                          '$category • $heartRate bpm',
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (date != null) ...[
                    const SizedBox(
                      height: 6,
                    ),
                    Text(
                      _fullDate(
                        date,
                      ),
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall,
                    ),
                  ],
                  if (notes != null && notes.trim().isNotEmpty) ...[
                    const SizedBox(
                      height: 8,
                    ),
                    Text(
                      notes,
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              tooltip: 'Delete reading',
              onPressed: () {
                _deleteReading(
                  reading,
                );
              },
              icon: const Icon(
                Icons.delete_outline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrends() {
    final readings = _filteredTrendReadings;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Blood Pressure Trends',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(
          height: 6,
        ),
        Text(
          'Systolic and diastolic pressure over time',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(
          height: 14,
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: SegmentedButton<int>(
            segments: const [
              ButtonSegment(
                value: 7,
                label: Text(
                  '7 Days',
                ),
              ),
              ButtonSegment(
                value: 30,
                label: Text(
                  '30 Days',
                ),
              ),
            ],
            selected: {
              _trendDays,
            },
            onSelectionChanged: (
              selection,
            ) {
              setState(() {
                _trendDays = selection.first;
              });
            },
          ),
        ),
        const SizedBox(
          height: 22,
        ),
        if (readings.length < 2)
          _buildNotEnoughChartData()
        else
          _buildChart(
            readings,
          ),
        const SizedBox(
          height: 18,
        ),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 22,
          runSpacing: 12,
          children: [
            _buildLegend(
              color: Colors.redAccent,
              label: 'Systolic',
            ),
            _buildLegend(
              color: Colors.blueAccent,
              label: 'Diastolic',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLegend({
    required Color color,
    required String label,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(
          width: 7,
        ),
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildChart(
    List<Map<String, dynamic>> readings,
  ) {
    final systolicSpots = <FlSpot>[];

    final diastolicSpots = <FlSpot>[];

    var minPressure = 300.0;

    var maxPressure = 0.0;

    for (var i = 0; i < readings.length; i++) {
      final systolic = (readings[i]['systolic'] as num).toDouble();

      final diastolic = (readings[i]['diastolic'] as num).toDouble();

      systolicSpots.add(
        FlSpot(
          i.toDouble(),
          systolic,
        ),
      );

      diastolicSpots.add(
        FlSpot(
          i.toDouble(),
          diastolic,
        ),
      );

      if (diastolic < minPressure) {
        minPressure = diastolic;
      }

      if (systolic > maxPressure) {
        maxPressure = systolic;
      }
    }

    var minY = ((minPressure - 20) / 10).floor() * 10.0;

    var maxY = ((maxPressure + 20) / 10).ceil() * 10.0;

    if (minY < 30) {
      minY = 30;
    }

    if (maxY <= minY) {
      maxY = minY + 40;
    }

    final interval = readings.length > 8 ? 2 : 1;

    final textScale = MediaQuery.of(context)
        .textScaler
        .scale(
          1.0,
        )
        .clamp(
          1.0,
          1.5,
        );

    final chartHeight = 330.0 + ((textScale - 1.0) * 100.0);

    final leftReserved = 42.0 + ((textScale - 1.0) * 26.0);

    final bottomReserved = 44.0 + ((textScale - 1.0) * 28.0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          12,
          20,
          18,
          14,
        ),
        child: SizedBox(
          height: chartHeight,
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: (readings.length - 1).toDouble(),
              minY: minY,
              maxY: maxY,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 20,
              ),
              borderData: FlBorderData(
                show: true,
                border: const Border(
                  left: BorderSide(
                    color: Colors.black26,
                  ),
                  bottom: BorderSide(
                    color: Colors.black26,
                  ),
                ),
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: false,
                  ),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: false,
                  ),
                ),
                leftTitles: AxisTitles(
                  axisNameWidget: const Padding(
                    padding: EdgeInsets.only(
                      bottom: 6,
                    ),
                    child: Text(
                      'mmHg',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  axisNameSize: 28,
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: leftReserved,
                    interval: 20,
                    getTitlesWidget: (
                      value,
                      meta,
                    ) {
                      return SideTitleWidget(
                        meta: meta,
                        child: Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            fontSize: 10,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  axisNameWidget: const Padding(
                    padding: EdgeInsets.only(
                      top: 8,
                    ),
                    child: Text(
                      'Date',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  axisNameSize: 34,
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: bottomReserved,
                    interval: interval.toDouble(),
                    getTitlesWidget: (
                      value,
                      meta,
                    ) {
                      final index = value.round();

                      if (index < 0 || index >= readings.length) {
                        return const SizedBox.shrink();
                      }

                      if (index % interval != 0) {
                        return const SizedBox.shrink();
                      }

                      final date = _readingDate(
                        readings[index],
                      );

                      if (date == null) {
                        return const SizedBox.shrink();
                      }

                      return SideTitleWidget(
                        meta: meta,
                        child: Text(
                          _shortDate(
                            date,
                          ),
                          style: const TextStyle(
                            fontSize: 9,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              lineTouchData: LineTouchData(
                enabled: true,
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (
                    touchedSpots,
                  ) {
                    return touchedSpots.map(
                      (
                        spot,
                      ) {
                        final index = spot.x.round();

                        if (index < 0 || index >= readings.length) {
                          return null;
                        }

                        final date = _readingDate(
                          readings[index],
                        );

                        final prefix = spot.barIndex == 0 ? 'SYS' : 'DIA';

                        final dateText =
                            date == null ? '' : '${_shortDate(date)}\n';

                        return LineTooltipItem(
                          '$dateText$prefix ${spot.y.toInt()} mmHg',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      },
                    ).toList();
                  },
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: systolicSpots,
                  isCurved: true,
                  color: Colors.redAccent,
                  barWidth: 3,
                  dotData: const FlDotData(
                    show: true,
                  ),
                  belowBarData: BarAreaData(
                    show: false,
                  ),
                ),
                LineChartBarData(
                  spots: diastolicSpots,
                  isCurved: true,
                  color: Colors.blueAccent,
                  barWidth: 3,
                  dotData: const FlDotData(
                    show: true,
                  ),
                  belowBarData: BarAreaData(
                    show: false,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotEnoughChartData() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 45,
          horizontal: 24,
        ),
        child: Column(
          children: [
            Icon(
              Icons.show_chart,
              size: 52,
              color: Theme.of(
                context,
              ).colorScheme.outline,
            ),
            const SizedBox(
              height: 12,
            ),
            Text(
              'Not enough data yet',
              style: Theme.of(
                context,
              ).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(
              height: 8,
            ),
            Text(
              'Add at least two blood pressure readings within this period to display a trend.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 70,
        horizontal: 12,
      ),
      child: Column(
        children: [
          Icon(
            Icons.favorite_outline,
            size: 58,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(
            height: 14,
          ),
          Text(
            'No blood pressure readings yet',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(
            height: 8,
          ),
          Text(
            'Log your first reading to start tracking trends.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}
