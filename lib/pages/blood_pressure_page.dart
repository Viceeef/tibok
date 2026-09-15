import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

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

      if (!mounted) return;

      setState(() {
        _readings = readings;
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

  DateTime? _readingDate(
    Map<String, dynamic> reading,
  ) {
    final value = reading['logged_at']?.toString();

    if (value == null) return null;

    return DateTime.tryParse(value)?.toLocal();
  }

  List<Map<String, dynamic>> get _filteredTrendReadings {
    final cutoff = DateTime.now().subtract(
      Duration(days: _trendDays),
    );

    final filtered = _readings.where(
      (reading) {
        final date = _readingDate(reading);

        if (date == null) return false;

        return date.isAfter(cutoff) || _isSameDay(date, cutoff);
      },
    ).toList();

    filtered.sort(
      (a, b) {
        final aDate = _readingDate(a) ?? DateTime.fromMillisecondsSinceEpoch(0);

        final bDate = _readingDate(b) ?? DateTime.fromMillisecondsSinceEpoch(0);

        return aDate.compareTo(bDate);
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

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
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
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: systolicController,
                            enabled: !saving,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Systolic',
                              suffixText: 'mmHg',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        Expanded(
                          child: TextField(
                            controller: diastolicController,
                            enabled: !saving,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Diastolic',
                              suffixText: 'mmHg',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: heartRateController,
                      enabled: !saving,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Heart Rate',
                        suffixText: 'bpm',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesController,
                      enabled: !saving,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Notes (optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    if (dialogError != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        dialogError!,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 13,
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Text(
                      'Blood pressure categories are provided for '
                      'tracking purposes and a single reading does '
                      'not establish a diagnosis.',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                        height: 1.35,
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
                  child: const Text('Cancel'),
                ),
                FilledButton(
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
                            setDialogState(() {
                              dialogError =
                                  'Enter valid numeric values for all required fields.';
                            });
                            return;
                          }

                          setDialogState(() {
                            saving = true;
                            dialogError = null;
                          });

                          try {
                            await _service.addReading(
                              systolic: systolic,
                              diastolic: diastolic,
                              heartRate: heartRate,
                              notes: notesController.text,
                            );

                            if (!dialogContext.mounted) {
                              return;
                            }

                            Navigator.pop(
                              dialogContext,
                            );

                            await _loadReadings();

                            _showMessage(
                              'Blood pressure saved.',
                            );
                          } catch (e) {
                            if (!dialogContext.mounted) {
                              return;
                            }

                            setDialogState(() {
                              saving = false;
                              dialogError = e.toString().replaceFirst(
                                    'Exception: ',
                                    '',
                                  );
                            });
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
                          'Save Reading',
                        ),
                ),
              ],
            );
          },
        );
      },
    );

    systolicController.dispose();
    diastolicController.dispose();
    heartRateController.dispose();
    notesController.dispose();
  }

  Future<void> _deleteReading(
    Map<String, dynamic> reading,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
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
    if (!mounted) return;

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
        return Colors.green;

      case 'Elevated':
        return Colors.amber.shade700;

      case 'Stage 1 Hypertension':
        return Colors.orange;

      case 'Stage 2 Hypertension':
        return Colors.deepOrange;

      case 'Severe Hypertension':
        return Colors.red.shade800;

      default:
        return Colors.grey;
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
              Icons.add,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddReadingDialog,
        icon: const Icon(
          Icons.add,
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
            'Unable to load blood pressure history.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _loadReadings,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        16,
        12,
        16,
        90,
      ),
      children: [
        if (_latestReading != null)
          _buildLatestCard(
            _latestReading!,
          ),
        if (_latestReading != null) const SizedBox(height: 16),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(
              value: 'List',
              icon: Icon(
                Icons.list_alt,
              ),
              label: Text('History'),
            ),
            ButtonSegment(
              value: 'Trends',
              icon: Icon(
                Icons.show_chart,
              ),
              label: Text('Trends'),
            ),
          ],
          selected: {
            _viewMode,
          },
          onSelectionChanged: (selection) {
            setState(() {
              _viewMode = selection.first;
            });
          },
        ),
        const SizedBox(height: 18),
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

    final date = _readingDate(reading);

    final color = _categoryColor(category);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Latest Reading',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(
                      alpha: 0.12,
                    ),
                    borderRadius: BorderRadius.circular(
                      20,
                    ),
                  ),
                  child: Text(
                    category,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
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
                    left: 6,
                    bottom: 5,
                  ),
                  child: Text(
                    'mmHg',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Heart rate: $heartRate bpm',
            ),
            if (date != null) ...[
              const SizedBox(height: 5),
              Text(
                _fullDate(date),
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              'Category is based on the recorded reading. '
              'A single measurement does not establish a diagnosis.',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 11,
                height: 1.35,
              ),
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

    final date = _readingDate(reading);

    final color = _categoryColor(category);

    return Card(
      margin: const EdgeInsets.only(
        bottom: 10,
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 6,
              height: 75,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(
                  10,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$systolic/$diastolic mmHg',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$category • $heartRate bpm',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (date != null) ...[
                    const SizedBox(
                      height: 4,
                    ),
                    Text(
                      _fullDate(date),
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  if (notes != null && notes.trim().isNotEmpty) ...[
                    const SizedBox(
                      height: 6,
                    ),
                    Text(
                      notes,
                      style: const TextStyle(
                        fontSize: 13,
                      ),
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
        Row(
          children: [
            const Expanded(
              child: Text(
                'Blood Pressure Trends',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(
                  value: 7,
                  label: Text('7D'),
                ),
                ButtonSegment(
                  value: 30,
                  label: Text('30D'),
                ),
              ],
              selected: {
                _trendDays,
              },
              onSelectionChanged: (selection) {
                setState(() {
                  _trendDays = selection.first;
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Systolic and diastolic pressure over time',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 20),
        if (readings.length < 2)
          _buildNotEnoughChartData()
        else
          _buildChart(readings),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegend(
              color: Colors.redAccent,
              label: 'Systolic',
            ),
            const SizedBox(width: 20),
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
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(label),
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          12,
          20,
          18,
          12,
        ),
        child: SizedBox(
          height: 330,
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
                  axisNameSize: 24,
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 42,
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
                  axisNameSize: 30,
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 44,
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
                      (spot) {
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
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            const Text(
              'Not enough data yet',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Add at least two blood pressure readings '
              'within this period to display a trend.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
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
      ),
      child: Column(
        children: [
          Icon(
            Icons.favorite_outline,
            size: 58,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 14),
          const Text(
            'No blood pressure readings yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Log your first reading to start tracking trends.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
