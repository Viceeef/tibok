import 'package:flutter/material.dart';

import '../services/food_api_service.dart';
import '../services/food_log_service.dart';
import '../utils/sodium_rating.dart';

class ProductResultPage extends StatefulWidget {
  final ScannedProduct product;

  const ProductResultPage({
    super.key,
    required this.product,
  });

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

  int? get _basisSodiumMg => _usesPer100g
      ? widget.product.sodiumPer100gMg
      : _usesPerServing
          ? widget.product.sodiumPerServingMg
          : null;

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

        // For per-100 g:
        // servings means number of 100-g units.
        //
        // For per-serving:
        // servings means actual servings consumed.
        servings: _usesPer100g ? quantity / 100 : quantity,

        sodiumPerServingMg: sodium,

        sodiumBasis: _basis,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
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
        _friendlyError(e),
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
      return 'The sodium calculation could not be verified. Please check the amount consumed.';
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
          content: Text(message),
        ),
      );
  }

  Widget _buildSodiumStatus() {
    final product = widget.product;

    if (product.sodiumPer100gMg != null) {
      final sodium = product.sodiumPer100gMg!.toDouble();

      final color = SodiumRating.colorFor(
        sodium,
      );

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(
          16,
        ),
        decoration: BoxDecoration(
          color: color.withValues(
            alpha: 0.10,
          ),
          borderRadius: BorderRadius.circular(
            14,
          ),
          border: Border.all(
            color: color.withValues(
              alpha: 0.40,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              SodiumRating.iconFor(
                sodium,
              ),
              color: color,
              size: 28,
            ),
            const SizedBox(
              width: 12,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    SodiumRating.labelFor(
                      sodium,
                    ),
                    style: TextStyle(
                      color: color,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(
                    height: 3,
                  ),
                  Text(
                    '${product.sodiumPer100gMg} mg per 100 g',
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (product.sodiumPerServingMg != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(
          16,
        ),
        decoration: BoxDecoration(
          color: Colors.blueGrey.withValues(
            alpha: 0.09,
          ),
          borderRadius: BorderRadius.circular(
            14,
          ),
          border: Border.all(
            color: Colors.blueGrey.withValues(
              alpha: 0.30,
            ),
          ),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.info_outline,
              color: Colors.blueGrey,
            ),
            SizedBox(
              width: 12,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Traffic-light rating unavailable',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(
                    height: 4,
                  ),
                  Text(
                    'This product provides sodium per serving, but Tibok requires sodium per 100 g for its traffic-light rating.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        16,
      ),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(
          alpha: 0.10,
        ),
        borderRadius: BorderRadius.circular(
          14,
        ),
        border: Border.all(
          color: Colors.grey.withValues(
            alpha: 0.30,
          ),
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.help_outline,
            color: Colors.grey,
          ),
          SizedBox(
            width: 12,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sodium information unavailable',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(
                  height: 4,
                ),
                Text(
                  'Open Food Facts does not provide enough sodium information for this product. Tibok will not treat missing data as zero sodium.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionCard() {
    final product = widget.product;

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(
          16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sodium Information',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(
              height: 14,
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
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 7,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
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

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(
          16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Amount Consumed',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
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
              onChanged: (_) {
                setState(() {});
              },
              decoration: InputDecoration(
                labelText:
                    _usesPer100g ? 'Amount Consumed' : 'Servings Consumed',
                suffixText: _usesPer100g ? 'g' : null,
                helperText: _usesPer100g
                    ? 'Traffic-light rating is based on sodium per 100 g.'
                    : 'Sodium will be calculated from the product\'s serving value.',
                border: const OutlineInputBorder(),
              ),
            ),
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
                borderRadius: BorderRadius.circular(
                  12,
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
                  Text(
                    total == null ? '-- mg' : '$total mg',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
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
          padding: const EdgeInsets.all(
            20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSodiumStatus(),
              const SizedBox(
                height: 20,
              ),
              Text(
                product.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(
                height: 6,
              ),
              Text(
                'Barcode: ${product.barcode}',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              _buildNutritionCard(),
              const SizedBox(
                height: 16,
              ),
              _buildConsumptionCard(),
              if (product.hasHiddenSodium) ...[
                const SizedBox(
                  height: 16,
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(
                      12,
                    ),
                    border: Border.all(
                      color: Colors.amber.shade700,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.amber.shade900,
                          ),
                          const SizedBox(
                            width: 8,
                          ),
                          Expanded(
                            child: Text(
                              'Hidden Sodium Additives Detected',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.amber.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 8,
                      ),
                      Text(
                        'Contains: ${product.detectedHiddenIngredients.join(", ")}',
                        style: const TextStyle(
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(
                height: 22,
              ),
              const Text(
                'Ingredients',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(
                height: 6,
              ),
              Text(
                product.ingredientsText,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(
                height: 32,
              ),
              FilledButton.icon(
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
                        Icons.add_task,
                      ),
                label: Text(
                  !product.hasAnySodiumData
                      ? 'Sodium Data Required'
                      : _isLogging
                          ? 'Adding...'
                          : 'Log to Daily Sodium Intake',
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                  ),
                ),
              ),
              if (!product.hasAnySodiumData) ...[
                const SizedBox(
                  height: 10,
                ),
                Text(
                  'Use Tibok\'s Add Food → Enter Food Manually option if you have the product\'s nutrition label.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
