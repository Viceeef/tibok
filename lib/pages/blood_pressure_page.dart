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
  bool _showTrends = false;
  bool _show30Days = false;

  String? _errorMessage;

  List<Map<String, dynamic>> _readings = [];

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

  Future<void> _showAddReadingDialog() async {
    final systolicController = TextEditingController();
    final diastolicController = TextEditingController();
    final heartRateController = TextEditingController();
    final notesController = TextEditingController();

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
            return AlertDialog(
              title: const Text(
                'Log Blood Pressure',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Enter your blood pressure and heart rate reading.',
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: systolicController,
                            enabled: !saving,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Systolic',
                              hintText: '120',
                              suffixText: 'mmHg',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: diastolicController,
                            enabled: !saving,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Diastolic',
                              hintText: '80',
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
                        hintText: '72',
                        suffixText: 'bpm',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesController,
                      enabled: !saving,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Notes (optional)',
                        hintText: 'e.g. After breakfast',
                        border: OutlineInputBorder(),
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
                          Navigator.pop(dialogContext);
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
                            _showMessage(
                              'Please enter valid systolic, diastolic, and heart rate values.',
                            );
                            return;
                          }

                          setDialogState(() {
                            saving = true;
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

                            Navigator.pop(dialogContext);

                            _showMessage(
                              'Blood pressure reading saved.',
                            );

                            await _loadReadings();
                          } catch (e) {
                            if (!dialogContext.mounted) {
                              return;
                            }

                            setDialogState(() {
                              saving = false;
                            });

                            _showMessage(
                              e.toString().replaceFirst(
                                    'Exception: ',
                                    '',
                                  ),
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
                      : const Text('Save Reading'),
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
          title: const Text('Delete Reading'),
          content: const Text(
            'Are you sure you want to delete this blood pressure reading?',
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

      _showMessage(
        'Blood pressure reading deleted.',
      );

      await _loadReadings();
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

  DateTime? _parsePhilippineTime(
    dynamic value,
  ) {
    if (value == null) return null;

    final parsed = DateTime.tryParse(
      value.toString(),
    );

    if (parsed == null) return null;

    return parsed.toUtc().add(
          const Duration(hours: 8),
        );
  }

  String _formatDateTime(
    dynamic value,
  ) {
    final date = _parsePhilippineTime(value);

    if (date == null) {
      return '';
    }

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

    return '${months[date.month - 1]} '
        '${date.day}, ${date.year}, '
        '$hour:$minute $period';
  }

  Color _categoryColor(
    String category,
  ) {
    switch (category.toLowerCase()) {
      case 'normal':
        return Colors.green;

      case 'elevated':
        return Colors.orange;

      default:
        return Colors.redAccent;
    }
  }

  List<Map<String, dynamic>> get _filteredChartReadings {
    final now = DateTime.now().toUtc().add(
          const Duration(hours: 8),
        );

    final days = _show30Days ? 30 : 7;

    final cutoff = now.subtract(
      Duration(days: days),
    );

    final filtered = _readings.where((reading) {
      final date = _parsePhilippineTime(
        reading['logged_at'],
      );

      if (date == null) return false;

      return date.isAfter(cutoff);
    }).toList();

    filtered.sort((a, b) {
      final aDate = _parsePhilippineTime(
        a['logged_at'],
      );

      final bDate = _parsePhilippineTime(
        b['logged_at'],
      );

      if (aDate == null || bDate == null) {
        return 0;
      }

      return aDate.compareTo(bDate);
    });

    return filtered;
  }

  Map<String, dynamic>? get _latestReading {
    if (_readings.isEmpty) {
      return null;
    }

    return _readings.first;
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _showTrends ? 'Blood Pressure Trends' : 'Blood Pressure History',
        ),
        actions: [
          IconButton(
            tooltip: 'Add Reading',
            icon: const Icon(
              Icons.add,
            ),
            onPressed: _showAddReadingDialog,
          ),
        ],
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
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 120),
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.redAccent,
          ),
          const SizedBox(height: 16),
          const Text(
            'Unable to load blood pressure records.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
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
        16,
        16,
        16,
        100,
      ),
      children: [
        _buildModeSelector(),
        const SizedBox(height: 20),
        if (_showTrends) _buildTrendsView() else _buildHistoryView(),
      ],
    );
  }

  Widget _buildModeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: FilledButton(
              onPressed: () {
                setState(() {
                  _showTrends = false;
                });
              },
              style: FilledButton.styleFrom(
                elevation: 0,
                backgroundColor:
                    !_showTrends ? Colors.redAccent : Colors.transparent,
                foregroundColor: !_showTrends ? Colors.white : Colors.black87,
              ),
              child: const Text('List'),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: FilledButton(
              onPressed: () {
                setState(() {
                  _showTrends = true;
                });
              },
              style: FilledButton.styleFrom(
                elevation: 0,
                backgroundColor:
                    _showTrends ? Colors.redAccent : Colors.transparent,
                foregroundColor: _showTrends ? Colors.white : Colors.black87,
              ),
              child: const Text('Trends'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryView() {
    if (_readings.isEmpty) {
      return Column(
        children: [
          const SizedBox(height: 100),
          Icon(
            Icons.favorite_border,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          const Text(
            'No blood pressure readings yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first reading to begin monitoring your blood pressure.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _showAddReadingDialog,
            icon: const Icon(Icons.add),
            label: const Text(
              'Log New Reading',
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        ..._readings.map(
          (reading) {
            final systolic = (reading['systolic'] as num?)?.toInt() ?? 0;

            final diastolic = (reading['diastolic'] as num?)?.toInt() ?? 0;

            final heartRate = (reading['heart_rate'] as num?)?.toInt() ?? 0;

            final category = reading['category']?.toString() ?? 'Unknown';

            final notes = reading['notes']?.toString();

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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _formatDateTime(
                              reading['logged_at'],
                            ),
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
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
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'delete') {
                              _deleteReading(
                                reading,
                              );
                            }
                          },
                          itemBuilder: (_) => const [
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
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$systolic / $diastolic',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Padding(
                          padding: EdgeInsets.only(
                            bottom: 4,
                          ),
                          child: Text(
                            'mmHg',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.favorite,
                          size: 18,
                          color: Colors.redAccent,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$heartRate bpm',
                        ),
                      ],
                    ),
                    if (notes != null && notes.trim().isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        notes,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _showAddReadingDialog,
          icon: const Icon(Icons.add),
          label: const Text(
            'Log New Reading',
          ),
        ),
      ],
    );
  }

  Widget _buildTrendsView() {
    final readings = _filteredChartReadings;

    final latest = _latestReading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildRangeSelector(),
        const SizedBox(height: 24),
        if (readings.length < 2)
          _buildNotEnoughChartData()
        else
          _buildChart(readings),
        const SizedBox(height: 24),
        if (latest != null) _buildLatestReadingCard(latest),
      ],
    );
  }

  Widget _buildRangeSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ChoiceChip(
          label: const Text('7D'),
          selected: !_show30Days,
          onSelected: (_) {
            setState(() {
              _show30Days = false;
            });
          },
        ),
        const SizedBox(width: 12),
        ChoiceChip(
          label: const Text('30D'),
          selected: _show30Days,
          onSelected: (_) {
            setState(() {
              _show30Days = true;
            });
          },
        ),
      ],
    );
  }

  Widget _buildNotEnoughChartData() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            Icon(
              Icons.show_chart,
              size: 52,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            const Text(
              'More readings needed',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Add at least two blood pressure readings to display a trend chart.',
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

  Widget _buildChart(
    List<Map<String, dynamic>> readings,
  ) {
    final systolicSpots = <FlSpot>[];
    final diastolicSpots = <FlSpot>[];

    for (var index = 0; index < readings.length; index++) {
      final reading = readings[index];

      final systolic = (reading['systolic'] as num?)?.toDouble();

      final diastolic = (reading['diastolic'] as num?)?.toDouble();

      if (systolic == null || diastolic == null) {
        continue;
      }

      systolicSpots.add(
        FlSpot(
          index.toDouble(),
          systolic,
        ),
      );

      diastolicSpots.add(
        FlSpot(
          index.toDouble(),
          diastolic,
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          16,
          20,
          16,
          16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Blood Pressure Trend',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildLegend(
                  Colors.redAccent,
                  'Systolic',
                ),
                const SizedBox(width: 20),
                _buildLegend(
                  Colors.blue,
                  'Diastolic',
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  minY: 40,
                  maxY: 200,
                  gridData: const FlGridData(
                    show: true,
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(
                      color: Colors.black12,
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
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 42,
                        interval: 40,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        interval: 1,
                        getTitlesWidget: (
                          value,
                          meta,
                        ) {
                          final index = value.toInt();

                          if (index < 0 || index >= readings.length) {
                            return const SizedBox.shrink();
                          }

                          final date = _parsePhilippineTime(
                            readings[index]['logged_at'],
                          );

                          if (date == null) {
                            return const SizedBox.shrink();
                          }

                          return Padding(
                            padding: const EdgeInsets.only(
                              top: 8,
                            ),
                            child: Text(
                              '${date.day}',
                              style: const TextStyle(
                                fontSize: 11,
                              ),
                            ),
                          );
                        },
                      ),
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
                    ),
                    LineChartBarData(
                      spots: diastolicSpots,
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      dotData: const FlDotData(
                        show: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(
    Color color,
    String label,
  ) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
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

  Widget _buildLatestReadingCard(
    Map<String, dynamic> reading,
  ) {
    final systolic = (reading['systolic'] as num?)?.toInt() ?? 0;

    final diastolic = (reading['diastolic'] as num?)?.toInt() ?? 0;

    final heartRate = (reading['heart_rate'] as num?)?.toInt() ?? 0;

    final category = reading['category']?.toString() ?? 'Unknown';

    final color = _categoryColor(
      category,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(
          18,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Latest Reading',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$systolic / $diastolic mmHg',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$heartRate bpm',
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDateTime(
                          reading['logged_at'],
                        ),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
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
                      fontWeight: FontWeight.bold,
                    ),
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
