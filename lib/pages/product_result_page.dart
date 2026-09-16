import 'package:flutter/material.dart';

import '../services/food_api_service.dart';
import '../services/food_log_service.dart';
import '../utils/sodium_rating.dart';

class ProductResultPage extends StatefulWidget {
  const ProductResultPage({
    super.key,
    required this.product,
  });

  final ScannedProduct product;

  @override
  State<ProductResultPage> createState() => _ProductResultPageState();
}

class _ProductResultPageState extends State<ProductResultPage> {
  final FoodLogService _foodLogService = FoodLogService();

  late final TextEditingController _quantityController;

  bool _isLogging = false;

  @override
  void initState() {
    super.initState();

    _quantityController = TextEditingController(
      text: widget.product.hasPer100gSodium ? '100' : '1',
    );
  }

  @override
  void dispose() {
    _quantityController.dispose();

    super.dispose();
  }

  bool get _usesPer100g => widget.product.hasPer100gSodium;

  bool get _usesPerServing =>
      !_usesPer100g && widget.product.hasPerServingSodium;

  String get _basis => widget.product.preferredSodiumBasis;

  int? get _basisSodiumMg {
    if (_usesPer100g) {
      return widget.product.sodiumPer100gMg;
    }

    if (_usesPerServing) {
      return widget.product.sodiumPerServingMg;
    }

    return null;
  }

  double? get _enteredQuantity {
    return double.tryParse(
      _quantityController.text.trim(),
    );
  }

  int? get _calculatedTotal {
    final sodium = _basisSodiumMg;

    final quantity = _enteredQuantity;

    if (sodium == null || quantity == null || quantity <= 0) {
      return null;
    }

    if (_usesPer100g) {
      return (sodium * quantity / 100).round();
    }

    if (_usesPerServing) {
      return (sodium * quantity).round();
    }

    return null;
  }

  Future<void> _logFoodItem() async {
    if (_isLogging) {
      return;
    }

    final sodium = _basisSodiumMg;

    final quantity = _enteredQuantity;

    final total = _calculatedTotal;

    if (sodium == null || total == null || quantity == null || quantity <= 0) {
      _showMessage(
        widget.product.hasAnySodiumData
            ? 'Enter a valid amount consumed.'
            : 'This product does not have enough sodium information to log safely.',
      );

      return;
    }

    setState(() {
      _isLogging = true;
    });

    try {
      await _foodLogService.addFoodLog(
        requestId: _foodLogService.createRequestId(),
        foodName: widget.product.name,
        sodiumAmount: total,
        logDate: _foodLogService.philippineNow,
        entryType: 'scanned',
        sourceBarcode: widget.product.barcode,
        servings: _usesPer100g ? quantity / 100 : quantity,
        sodiumPerServingMg: sodium,
        sodiumBasis: _basis,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(
            '${widget.product.name} added to today\'s sodium intake.',
          ),
        ),
      );

      Navigator.pop(
        context,
        true,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(
        _friendlyError(
          e,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLogging = false;
        });
      }
    }
  }

  String _friendlyError(
    Object error,
  ) {
    final text = error.toString();

    if (text.contains(
      'row-level security',
    )) {
      return 'The food could not be saved because of a database permission issue.';
    }

    if (text.contains(
      'duplicate key',
    )) {
      return 'This food entry was already added.';
    }

    if (text.contains(
      'Sodium total does not match quantity',
    )) {
      return 'The sodium calculation could not be verified. Check the amount consumed.';
    }

    return 'Unable to add food to your daily intake. Please try again.';
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

  Widget _buildSodiumStatus() {
    final product = widget.product;

    final theme = Theme.of(context);

    final colors = theme.colorScheme;

    if (product.sodiumPer100gMg != null) {
      final sodium = product.sodiumPer100gMg!.toDouble();

      final color = SodiumRating.colorFor(
        sodium,
      );

      final label = SodiumRating.labelFor(
        sodium,
      );

      return Card(
        elevation: 2,
        shadowColor: Colors.black.withValues(
          alpha: 0.07,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            18,
          ),
          side: BorderSide(
            color: color.withValues(
              alpha: 0.28,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(
            18,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withValues(
                    alpha: 0.11,
                  ),
                  borderRadius: BorderRadius.circular(
                    14,
                  ),
                ),
                child: Icon(
                  SodiumRating.iconFor(
                    sodium,
                  ),
                  color: color,
                  size: 29,
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
                      label,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: color,
                      ),
                    ),
                    const SizedBox(
                      height: 4,
                    ),
                    Text(
                      '${product.sodiumPer100gMg} mg sodium per 100 g',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
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

    if (product.sodiumPerServingMg != null) {
      return Card(
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.all(
            18,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: colors.secondaryContainer,
                  borderRadius: BorderRadius.circular(
                    14,
                  ),
                ),
                child: Icon(
                  Icons.info_outline,
                  color: colors.onSecondaryContainer,
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
                      'Per-Serving Sodium',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(
                      height: 4,
                    ),
                    Text(
                      '${product.sodiumPerServingMg} mg per serving',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    Text(
                      'A Low, Moderate, or High rating requires a per-100 g value.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(
          18,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(
                  14,
                ),
              ),
              child: Icon(
                Icons.help_outline,
                color: colors.onSurfaceVariant,
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
                    'Sodium Information Unavailable',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  Text(
                    'This product does not provide enough sodium information to calculate or safely log an amount.',
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
    );
  }

  Widget _buildProductHeader() {
    final theme = Theme.of(context);

    final colors = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.product.name,
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(
          height: 6,
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.qr_code_2_rounded,
              size: 19,
              color: colors.onSurfaceVariant,
            ),
            const SizedBox(
              width: 7,
            ),
            Expanded(
              child: Text(
                widget.product.barcode,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNutritionCard() {
    final product = widget.product;

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(
          18,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sodium Information',
              style: Theme.of(
                context,
              ).textTheme.titleMedium,
            ),
            const SizedBox(
              height: 12,
            ),
            _buildNutritionRow(
              label: 'Per 100 g',
              value: product.sodiumPer100gMg == null
                  ? 'Unavailable'
                  : '${product.sodiumPer100gMg} mg',
            ),
            const Divider(),
            _buildNutritionRow(
              label: 'Per serving',
              value: product.sodiumPerServingMg == null
                  ? 'Unavailable'
                  : '${product.sodiumPerServingMg} mg',
            ),
            const Divider(),
            _buildNutritionRow(
              label: 'Serving size',
              value: product.servingSize,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionRow({
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);

    final colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 7,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(
            width: 12,
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsumptionCard() {
    if (!widget.product.hasAnySodiumData) {
      return const SizedBox.shrink();
    }

    final total = _calculatedTotal;

    final theme = Theme.of(context);

    final colors = theme.colorScheme;

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(
          18,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Amount Consumed',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(
              height: 14,
            ),
            TextField(
              controller: _quantityController,
              enabled: !_isLogging,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textInputAction: TextInputAction.done,
              onChanged: (_) {
                setState(() {});
              },
              decoration: InputDecoration(
                labelText: _usesPer100g ? 'Amount' : 'Servings',
                suffixText: _usesPer100g ? 'g' : null,
                prefixIcon: Icon(
                  _usesPer100g
                      ? Icons.scale_outlined
                      : Icons.restaurant_outlined,
                ),
                helperText: _usesPer100g
                    ? 'Enter the approximate weight you consumed.'
                    : 'Enter the number of servings you consumed.',
              ),
            ),
            const SizedBox(
              height: 16,
            ),
            Container(
              padding: const EdgeInsets.all(
                15,
              ),
              decoration: BoxDecoration(
                color: colors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(
                  14,
                ),
                border: Border.all(
                  color: colors.outlineVariant,
                ),
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
                  const SizedBox(
                    width: 10,
                  ),
                  Text(
                    total == null ? '-- mg' : '$total mg',
                    style: theme.textTheme.titleLarge?.copyWith(
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

  Widget _buildHiddenSodiumCard() {
    final product = widget.product;

    if (!product.hasHiddenSodium) {
      return const SizedBox.shrink();
    }

    final warningColor = Colors.amber.shade900;

    return Container(
      padding: const EdgeInsets.all(
        16,
      ),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(
          alpha: 0.10,
        ),
        borderRadius: BorderRadius.circular(
          16,
        ),
        border: Border.all(
          color: Colors.amber.shade700,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: warningColor,
          ),
          const SizedBox(
            width: 11,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sodium-Containing Additives Found',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: warningColor,
                  ),
                ),
                const SizedBox(
                  height: 5,
                ),
                Text(
                  product.detectedHiddenIngredients.join(
                    ', ',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientsCard() {
    final colors = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      child: ExpansionTile(
        leading: Icon(
          Icons.format_list_bulleted_rounded,
          color: colors.primary,
        ),
        title: const Text(
          'Ingredients',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: const Text(
          'Tap to view ingredient information',
        ),
        childrenPadding: const EdgeInsets.fromLTRB(
          18,
          0,
          18,
          18,
        ),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              widget.product.ingredientsText,
              style: const TextStyle(
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final product = widget.product;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Product Details',
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(
            18,
            10,
            18,
            30,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildProductHeader(),
              const SizedBox(
                height: 18,
              ),
              _buildSodiumStatus(),
              const SizedBox(
                height: 14,
              ),
              _buildNutritionCard(),
              if (product.hasAnySodiumData) ...[
                const SizedBox(
                  height: 14,
                ),
                _buildConsumptionCard(),
              ],
              if (product.hasHiddenSodium) ...[
                const SizedBox(
                  height: 14,
                ),
                _buildHiddenSodiumCard(),
              ],
              const SizedBox(
                height: 14,
              ),
              _buildIngredientsCard(),
              const SizedBox(
                height: 20,
              ),
              SizedBox(
                width: double.infinity,
                height: 58,
                child: FilledButton.icon(
                  onPressed: _isLogging || !product.hasAnySodiumData
                      ? null
                      : _logFoodItem,
                  icon: _isLogging
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
                          Icons.add_task_rounded,
                        ),
                  label: Text(
                    !product.hasAnySodiumData
                        ? 'Sodium Data Required'
                        : _isLogging
                            ? 'Adding...'
                            : 'Add to Food Log',
                  ),
                ),
              ),
              if (!product.hasAnySodiumData) ...[
                const SizedBox(
                  height: 10,
                ),
                Text(
                  'If you have the nutrition label, use Add Food → Enter Food Manually.',
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
