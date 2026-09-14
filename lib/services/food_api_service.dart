import 'dart:convert';
import 'package:http/http.dart' as http;

enum SodiumRating { green, amber, red }

class ScannedProduct {
  final String barcode;
  final String name;
  final int sodiumMg; // Sodium per serving in mg
  final String servingSize;
  final String ingredientsText;
  final bool hasHiddenSodium;
  final List<String> detectedHiddenIngredients;
  final SodiumRating rating;

  ScannedProduct({
    required this.barcode,
    required this.name,
    required this.sodiumMg,
    required this.servingSize,
    required this.ingredientsText,
    required this.hasHiddenSodium,
    required this.detectedHiddenIngredients,
    required this.rating,
  });
}

class FoodApiService {
  // Known hidden sodium additives
  static const List<String> _hiddenSodiumTerms = [
    'msg',
    'monosodium glutamate',
    'sodium benzoate',
    'sodium nitrate',
    'sodium nitrite',
    'disodium',
    'trisodium',
    'sodium bicarbonate',
    'baking soda',
    'sodium phosphate',
    'sodium alginate',
    'sodium citrate',
  ];

  static Future<ScannedProduct?> fetchProductByBarcode(String barcode) async {
    final url = Uri.parse(
        'https://world.openfoodfacts.org/api/v2/product/$barcode.json');

    try {
      final response = await http.get(url, headers: {
        'User-Agent': 'Tibok-HypertensionApp - Android - Version 1.0',
      });

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body);
      if (data['status'] != 1 || data['product'] == null) return null;

      final productData = data['product'];
      final nutriments = productData['nutriments'] ?? {};

      // Parse product name & serving size
      final name = productData['product_name'] ?? 'Unknown Product';
      final servingSize = productData['serving_size'] ?? '1 serving';
      final ingredientsText =
          (productData['ingredients_text'] ?? '').toString();

      // Extract Sodium in grams and convert to milligrams
      num sodiumGrams =
          nutriments['sodium_serving'] ?? nutriments['sodium_100g'] ?? 0;
      int sodiumMg = (sodiumGrams * 1000).round();

      // Fallback: Check 'salt' if sodium field is absent (Salt = Sodium * 2.5)
      if (sodiumMg == 0 &&
          (nutriments['salt_serving'] != null ||
              nutriments['salt_100g'] != null)) {
        num saltGrams =
            nutriments['salt_serving'] ?? nutriments['salt_100g'] ?? 0;
        sodiumMg = ((saltGrams / 2.5) * 1000).round();
      }

      // Check for hidden sodium ingredients
      final detectedHidden = <String>[];
      final lowerIngredients = ingredientsText.toLowerCase();
      for (final term in _hiddenSodiumTerms) {
        if (lowerIngredients.contains(term)) {
          detectedHidden.add(term);
        }
      }

      // Calculate DASH Traffic Light Rating based on sodium per serving
      // Green: <= 140mg (Low sodium)
      // Amber: 141mg - 400mg (Moderate)
      // Red: > 400mg (High sodium)
      SodiumRating rating = SodiumRating.green;
      if (sodiumMg > 400) {
        rating = SodiumRating.red;
      } else if (sodiumMg > 140) {
        rating = SodiumRating.amber;
      }

      return ScannedProduct(
        barcode: barcode,
        name: name,
        sodiumMg: sodiumMg,
        servingSize: servingSize,
        ingredientsText: ingredientsText.isEmpty
            ? 'No ingredient list provided.'
            : ingredientsText,
        hasHiddenSodium: detectedHidden.isNotEmpty,
        detectedHiddenIngredients: detectedHidden,
        rating: rating,
      );
    } catch (e) {
      return null;
    }
  }
}
