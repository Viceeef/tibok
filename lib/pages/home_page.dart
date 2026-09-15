import 'package:flutter/material.dart';

import '../services/food_log_service.dart';
import '../services/supabase_service.dart';
import 'add_food_page.dart';
import 'scanner_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.onOpenFoodLog,
    required this.onOpenBloodPressure,
  });

  final VoidCallback onOpenFoodLog;
  final VoidCallback onOpenBloodPressure;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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

  Future<void> _openAddFood() async {
    final added = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const AddFoodPage(),
      ),
    );

    if (!mounted) return;

    if (added == true) {
      await _loadDashboard();
    }
  }

  String _formatToday() {
    final date = _foodLogService.philippineNow;

    const weekdays = [
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun',
    ];

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

    return '${weekdays[date.weekday - 1]}, '
        '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'TIBOK',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _isLoading ? null : _loadDashboard,
            icon: const Icon(Icons.refresh),
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
                size: 58,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 14),
              const Text(
                'Unable to load your dashboard.',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
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
          18,
          8,
          18,
          28,
        ),
        children: [
          Text(
            _formatToday(),
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 18),
          _buildSodiumCard(),
          const SizedBox(height: 18),
          _buildQuickActions(),
          const SizedBox(height: 14),
          _buildBloodPressureShortcut(),
          const SizedBox(height: 26),
          _buildFoodLogHeader(),
          const SizedBox(height: 10),
          _buildRecentFoodLogs(),
        ],
      ),
    );
  }

  Widget _buildSodiumCard() {
    final isOver = _remainingSodium < 0;

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.water_drop_outlined,
                    color: Colors.redAccent,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Today\'s Sodium Intake',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  _hasHypertension ? 'DASH target' : 'Daily target',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$_todaySodium mg',
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text: ' / $_dailyLimit mg',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: _progress,
              minHeight: 12,
              borderRadius: BorderRadius.circular(10),
            ),
            const SizedBox(height: 12),
            Text(
              isOver
                  ? '${_remainingSodium.abs()} mg over your daily target'
                  : '$_remainingSodium mg remaining',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isOver ? Colors.redAccent : Colors.grey.shade700,
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
            icon: const Icon(
              Icons.qr_code_scanner,
            ),
            label: const Text(
              'Scan Food',
            ),
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
            onPressed: _openAddFood,
            icon: const Icon(
              Icons.add_circle_outline,
            ),
            label: const Text(
              'Add Food',
            ),
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

  Widget _buildBloodPressureShortcut() {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: widget.onOpenBloodPressure,
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.black12,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          children: [
            CircleAvatar(
              backgroundColor: Color(0xFFFFEBEE),
              child: Icon(
                Icons.favorite_outline,
                color: Colors.redAccent,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Blood Pressure',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'View history and health trends',
                    style: TextStyle(
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFoodLogHeader() {
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
        TextButton(
          onPressed: widget.onOpenFoodLog,
          child: const Text(
            'See All',
          ),
        ),
      ],
    );
  }

  Widget _buildRecentFoodLogs() {
    if (_todayLogs.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              Icon(
                Icons.restaurant_menu,
                size: 46,
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
              Text(
                'Scan a product or add a food to begin tracking.',
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

    final recent = _todayLogs.take(3).toList();

    return Card(
      child: Column(
        children: [
          for (var i = 0; i < recent.length; i++) ...[
            _buildFoodRow(recent[i]),
            if (i < recent.length - 1) const Divider(height: 1),
          ],
        ],
      ),
    );
  }

  Widget _buildFoodRow(
    Map<String, dynamic> log,
  ) {
    final sodium = (log['sodium_amount'] as num?)?.toInt() ?? 0;

    final entryType = log['entry_type']?.toString() ?? 'manual';

    return ListTile(
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
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        entryType == 'scanned' ? 'Scanned product' : 'Food entry',
      ),
      trailing: Text(
        '$sodium mg',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
