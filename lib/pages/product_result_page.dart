import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../services/food_api_service.dart';
import '../services/supabase_service.dart';

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
  bool _isLogging = false;

  Color _getRatingColor(SodiumRating rating) {
    switch (rating) {
      case SodiumRating.green:
        return Colors.green;
      case SodiumRating.amber:
        return Colors.orange;
      case SodiumRating.red:
        return Colors.red;
    }
  }

  String _getRatingText(SodiumRating rating) {
    switch (rating) {
      case SodiumRating.green:
        return 'LOW SODIUM (DASH Safe)';
      case SodiumRating.amber:
        return 'MODERATE SODIUM (Eat in moderation)';
      case SodiumRating.red:
        return 'HIGH SODIUM (Limit consumption)';
    }
  }

  Future<void> _logFoodItem() async {
    if (_isLogging) return;

    setState(() => _isLogging = true);

    try {
      final user = SupabaseService.currentUser;

      if (user == null) {
        throw Exception('You must be logged in to add a food entry.');
      }

      if (widget.product.sodiumMg < 0) {
        throw Exception('Invalid sodium amount.');
      }

      final requestId = const Uuid().v4();

      await SupabaseService.client.from('daily_sodium_logs').insert({
        'user_id': user.id,

        // Do NOT use barcode_id here.
        //
        // barcode_id is tied to the products table.
        // source_barcode stores the external scanned barcode without
        // requiring us to insert the product into products first.
        'source_barcode': widget.product.barcode,

        'food_name': widget.product.name,
        'sodium_amount': widget.product.sodiumMg,
        'entry_type': 'scanned',

        // Added by our daily logging migration.
        'servings': 1,
        'sodium_per_serving_mg': widget.product.sodiumMg,
        'client_request_id': requestId,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${widget.product.name} added to today\'s sodium intake.',
          ),
        ),
      );

      // Return true so the previous page knows logging succeeded.
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_friendlyError(e)),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLogging = false);
      }
    }
  }

  String _friendlyError(Object error) {
    final text = error.toString();

    if (text.contains('row-level security')) {
      return 'The food could not be saved because of a database permission issue.';
    }

    if (text.contains('duplicate key')) {
      return 'This food entry was already added.';
    }

    return 'Unable to add food to your daily intake. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final color = _getRatingColor(product.rating);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Details'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: color,
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.circle,
                      color: color,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _getRatingText(product.rating),
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                product.name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Serving Size: ${product.servingSize}',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
              const Divider(height: 32),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Sodium Content',
                        style: TextStyle(fontSize: 16),
                      ),
                      Text(
                        '${product.sodiumMg} mg',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (product.hasHiddenSodium)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(12),
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
                          const SizedBox(width: 8),
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
                      const SizedBox(height: 8),
                      Text(
                        'Contains: '
                        '${product.detectedHiddenIngredients.join(", ")}',
                        style: const TextStyle(
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),
              const Text(
                'Ingredients',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                product.ingredientsText,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _isLogging ? null : _logFoodItem,
                icon: _isLogging
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.add_task),
                label: Text(
                  _isLogging ? 'Adding...' : 'Log to Daily Sodium Intake',
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                  ),
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
