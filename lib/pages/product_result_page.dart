import 'package:flutter/material.dart';
import '../services/food_api_service.dart';
import '../services/supabase_service.dart';

class ProductResultPage extends StatefulWidget {
  final ScannedProduct product;

  const ProductResultPage({super.key, required this.product});

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
    setState(() => _isLogging = true);
    try {
      final user = SupabaseService.client.auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      // 1. Cache/upsert product in public.products
      await SupabaseService.client.from('products').upsert({
        'barcode_id': widget.product.barcode,
        'product_name': widget.product.name,
        'ingredient_list': widget.product.ingredientsText,
        'total_sodium': widget.product.sodiumMg,
        'serving_size': widget.product.servingSize,
        'hidden_sodium': widget.product.hasHiddenSodium,
      });

      // 2. Add entry to public.daily_sodium_logs
      await SupabaseService.client.from('daily_sodium_logs').insert({
        'user_id': user.id,
        'barcode_id': widget.product.barcode,
        'food_name': widget.product.name,
        'sodium_amount': widget.product.sodiumMg,
        'entry_type': 'scanned',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Log added to your daily intake!')),
        );
        Navigator.pop(context); // Return to scanner/dashboard
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLogging = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getRatingColor(widget.product.rating);

    return Scaffold(
      appBar: AppBar(title: const Text('Product Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Traffic Light Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color, width: 2),
              ),
              child: Row(
                children: [
                  Icon(Icons.circle, color: color, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _getRatingText(widget.product.rating),
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
              widget.product.name,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Serving Size: ${widget.product.servingSize}',
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const Divider(height: 32),

            // Sodium Info Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Sodium Content',
                        style: TextStyle(fontSize: 16)),
                    Text(
                      '${widget.product.sodiumMg} mg',
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

            // Hidden Sodium Warning Box
            if (widget.product.hasHiddenSodium)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade700),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            color: Colors.amber.shade900),
                        const SizedBox(width: 8),
                        Text(
                          'Hidden Sodium Additives Detected',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Contains: ${widget.product.detectedHiddenIngredients.join(", ")}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),

            // Ingredients
            const Text('Ingredients',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 6),
            Text(
              widget.product.ingredientsText,
              style: const TextStyle(
                  color: Colors.black87, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 32),

            // Log Button
            ElevatedButton.icon(
              onPressed: _isLogging ? null : _logFoodItem,
              icon: const Icon(Icons.add_task),
              label: _isLogging
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Log to Daily Sodium Intake'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
