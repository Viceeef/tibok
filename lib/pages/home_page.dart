import 'package:flutter/material.dart';

import '../services/food_log_service.dart';
import '../services/supabase_service.dart';
import '../utils/sodium_rating.dart';
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
    if (_dailyLimit <= 0) {
      return 0;
    }

    return (_todaySodium / _dailyLimit).clamp(
      0.0,
      1.0,
    );
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

      if (!mounted) {
        return;
      }

      setState(() {
        _healthProfile = profile;
        _todayLogs = logs;
        _todaySodium = total;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      debugPrint('TIBOK DASHBOARD ERROR: $e');
      debugPrintStack(
        label: 'TIBOK DASHBOARD STACK',
        stackTrace: stackTrace,
      );

      if (!mounted) {
        return;
      }

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

    if (!mounted) {
      return;
    }

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
        '${months[date.month - 1]} '
        '${date.day}, ${date.year}';
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'TIBOK',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _isLoading ? null : _loadDashboard,
            icon: const Icon(
              Icons.refresh_rounded,
            ),
          ),
          const SizedBox(
            width: 4,
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
      return _buildErrorState();
    }

    return RefreshIndicator(
      onRefresh: _loadDashboard,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          18,
          4,
          18,
          24,
        ),
        children: [
          Text(
            _formatToday(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(
            height: 12,
          ),
          _buildSodiumCard(),
          const SizedBox(
            height: 14,
          ),
          _buildQuickActions(),
          const SizedBox(
            height: 14,
          ),
          _buildBloodPressureShortcut(),
          const SizedBox(
            height: 18,
          ),
          _buildFoodLogHeader(),
          const SizedBox(
            height: 8,
          ),
          _buildRecentFoodLogs(),
        ],
      ),
    );
  }

  Widget _buildSodiumCard() {
    final theme = Theme.of(context);

    final colors = theme.colorScheme;

    final isOver = _remainingSodium < 0;

    final progressColor = isOver ? colors.error : colors.primary;

    return Card(
      elevation: 2,
      shadowColor: Colors.black.withValues(
        alpha: 0.08,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          18,
        ),
        side: BorderSide(
          color: colors.primary.withValues(
            alpha: 0.16,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(
          18,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(
                      13,
                    ),
                  ),
                  child: Icon(
                    Icons.water_drop_outlined,
                    color: colors.onPrimaryContainer,
                  ),
                ),
                const SizedBox(
                  width: 12,
                ),
                Expanded(
                  child: Text(
                    'Today\'s Sodium Intake',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 14,
            ),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.end,
              children: [
                Text(
                  '$_todaySodium mg',
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
                Text(
                  '/ $_dailyLimit mg',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 14,
            ),
            LinearProgressIndicator(
              value: _progress,
              minHeight: 11,
              color: progressColor,
              backgroundColor: colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(
                20,
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  isOver
                      ? Icons.warning_amber_rounded
                      : Icons.check_circle_outline_rounded,
                  size: 20,
                  color: progressColor,
                ),
                const SizedBox(
                  width: 7,
                ),
                Expanded(
                  child: Text(
                    isOver
                        ? '${_remainingSodium.abs()} mg over your daily target'
                        : '$_remainingSodium mg remaining',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isOver ? colors.error : colors.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            if (_hasHypertension) ...[
              const SizedBox(
                height: 5,
              ),
              Padding(
                padding: const EdgeInsets.only(
                  left: 27,
                ),
                child: Text(
                  'Hypertension sodium target',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    final textScale = MediaQuery.of(context).textScaler.scale(
          1.0,
        );

    if (textScale >= 1.25) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 66,
            child: FilledButton.icon(
              onPressed: _openScanner,
              icon: const Icon(
                Icons.qr_code_scanner_rounded,
                size: 25,
              ),
              label: const Text(
                'Scan Food',
              ),
              style: FilledButton.styleFrom(
                textStyle: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          SizedBox(
            width: double.infinity,
            height: 66,
            child: OutlinedButton.icon(
              onPressed: _openAddFood,
              icon: const Icon(
                Icons.add_circle_outline_rounded,
                size: 25,
              ),
              label: const Text(
                'Add Food',
              ),
              style: OutlinedButton.styleFrom(
                textStyle: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return SizedBox(
      height: 64,
      child: Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: _openScanner,
              icon: const Icon(
                Icons.qr_code_scanner_rounded,
                size: 24,
              ),
              label: const Text(
                'Scan Food',
              ),
              style: FilledButton.styleFrom(
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(
            width: 10,
          ),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _openAddFood,
              icon: const Icon(
                Icons.add_circle_outline_rounded,
                size: 24,
              ),
              label: const Text(
                'Add Food',
              ),
              style: OutlinedButton.styleFrom(
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBloodPressureShortcut() {
    final theme = Theme.of(context);

    final colors = theme.colorScheme;

    return Card(
      elevation: 1.5,
      shadowColor: Colors.black.withValues(
        alpha: 0.06,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(
          20,
        ),
        onTap: widget.onOpenBloodPressure,
        child: Padding(
          padding: const EdgeInsets.all(
            15,
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: colors.errorContainer,
                  borderRadius: BorderRadius.circular(
                    13,
                  ),
                ),
                child: Icon(
                  Icons.favorite_outline_rounded,
                  color: colors.onErrorContainer,
                ),
              ),
              const SizedBox(
                width: 12,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Blood Pressure',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(
                      height: 2,
                    ),
                    Text(
                      'View history and trends',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: colors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFoodLogHeader() {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Today\'s Food Log',
            style: Theme.of(context).textTheme.titleLarge,
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
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 22,
            horizontal: 18,
          ),
          child: Column(
            children: [
              Icon(
                Icons.restaurant_menu_rounded,
                size: 38,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(
                height: 8,
              ),
              Text(
                'No food logged today',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(
                height: 4,
              ),
              Text(
                'Scan or add a food to begin tracking.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      );
    }

    final textScale = MediaQuery.of(context).textScaler.scale(
          1.0,
        );

    final maxItems = textScale >= 1.25 ? 1 : 2;

    final recent = _todayLogs.take(maxItems).toList();

    return Card(
      elevation: 1,
      child: Column(
        children: [
          for (var i = 0; i < recent.length; i++) ...[
            _buildFoodRow(
              recent[i],
            ),
            if (i < recent.length - 1)
              const Divider(
                height: 1,
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildFoodRow(
    Map<String, dynamic> log,
  ) {
    final theme = Theme.of(context);

    final colors = theme.colorScheme;

    final sodium = (log['sodium_amount'] as num?)?.toInt() ?? 0;

    final entryType = log['entry_type']?.toString() ?? 'manual';

    final sodiumBasis = log['sodium_basis']?.toString() ?? 'unknown';

    final sodiumPer100g = sodiumBasis == 'per_100g'
        ? (log['sodium_per_serving_mg'] as num?)?.toDouble()
        : null;

    final indicatorColor = sodiumPer100g != null
        ? SodiumRating.colorFor(
            sodiumPer100g,
          )
        : colors.onSurfaceVariant;

    String neutralLabel;

    switch (entryType) {
      case 'scanned':
        neutralLabel = 'Scanned food';
        break;

      case 'searched':
        neutralLabel = 'Common food';
        break;

      case 'manual':
      default:
        neutralLabel = 'Manual entry';
    }

    final label = sodiumPer100g != null
        ? SodiumRating.labelFor(
            sodiumPer100g,
          )
        : neutralLabel;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 13,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: indicatorColor.withValues(
                alpha: 0.10,
              ),
              borderRadius: BorderRadius.circular(
                12,
              ),
            ),
            child: Icon(
              sodiumPer100g != null
                  ? SodiumRating.iconFor(
                      sodiumPer100g,
                    )
                  : entryType == 'scanned'
                      ? Icons.qr_code_scanner
                      : Icons.restaurant,
              color: indicatorColor,
            ),
          ),
          const SizedBox(
            width: 12,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log['food_name']?.toString() ?? 'Unnamed food',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(
                  height: 2,
                ),
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: indicatorColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(
            width: 10,
          ),
          Text(
            '$sodium mg',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    final theme = Theme.of(context);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(
        24,
      ),
      children: [
        const SizedBox(
          height: 100,
        ),
        Icon(
          Icons.error_outline,
          size: 58,
          color: theme.colorScheme.error,
        ),
        const SizedBox(
          height: 14,
        ),
        Text(
          'Unable to load your dashboard.',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(
          height: 18,
        ),
        FilledButton.icon(
          onPressed: _loadDashboard,
          icon: const Icon(
            Icons.refresh_rounded,
          ),
          label: const Text(
            'Try Again',
          ),
        ),
      ],
    );
  }
}
