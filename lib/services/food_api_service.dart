import 'dart:convert';

import 'package:http/http.dart' as http;

class ScannedProduct {
  final String barcode;
  final String name;

  /// Sodium value specifically reported/derived per 100 g.
  ///
  /// Null means Open Food Facts did not provide enough information
  /// to establish a per-100 g sodium value.
  final int? sodiumPer100gMg;

  /// Sodium value specifically reported/derived per serving.
  ///
  /// Null means Open Food Facts did not provide enough information
  /// to establish a per-serving sodium value.
  final int? sodiumPerServingMg;

  final String servingSize;
  final String ingredientsText;

  final bool hasHiddenSodium;
  final List<String> detectedHiddenIngredients;

  const ScannedProduct({
    required this.barcode,
    required this.name,
    required this.sodiumPer100gMg,
    required this.sodiumPerServingMg,
    required this.servingSize,
    required this.ingredientsText,
    required this.hasHiddenSodium,
    required this.detectedHiddenIngredients,
  });

  bool get hasPer100gSodium => sodiumPer100gMg != null;

  bool get hasPerServingSodium => sodiumPerServingMg != null;

  bool get hasAnySodiumData => hasPer100gSodium || hasPerServingSodium;

  /// Preferred logging basis.
  ///
  /// We prefer per-100 g because Tibok's traffic-light system
  /// is defined using sodium per 100 g.
  String get preferredSodiumBasis {
    if (hasPer100gSodium) {
      return 'per_100g';
    }

    if (hasPerServingSodium) {
      return 'per_serving';
    }

    return 'unknown';
  }

  int? get preferredSodiumMg {
    if (hasPer100gSodium) {
      return sodiumPer100gMg;
    }

    if (hasPerServingSodium) {
      return sodiumPerServingMg;
    }

    return null;
  }
}

class FoodApiService {
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

  static num? _readNumber(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value;
    }

    return num.tryParse(
      value.toString(),
    );
  }

  static int? _sodiumGramsToMg(
    dynamic value,
  ) {
    final grams = _readNumber(value);

    if (grams == null || grams < 0) {
      return null;
    }

    return (grams * 1000).round();
  }

  static int? _saltGramsToSodiumMg(
    dynamic value,
  ) {
    final saltGrams = _readNumber(value);

    if (saltGrams == null || saltGrams < 0) {
      return null;
    }

    // Approximate relationship:
    // salt = sodium × 2.5
    final sodiumGrams = saltGrams / 2.5;

    return (sodiumGrams * 1000).round();
  }

  static int? _extractSodiumPer100g(
    Map<String, dynamic> nutriments,
  ) {
    final direct = _sodiumGramsToMg(
      nutriments['sodium_100g'],
    );

    if (direct != null) {
      return direct;
    }

    return _saltGramsToSodiumMg(
      nutriments['salt_100g'],
    );
  }

  static int? _extractSodiumPerServing(
    Map<String, dynamic> nutriments,
  ) {
    final direct = _sodiumGramsToMg(
      nutriments['sodium_serving'],
    );

    if (direct != null) {
      return direct;
    }

    return _saltGramsToSodiumMg(
      nutriments['salt_serving'],
    );
  }

  static Future<ScannedProduct?> fetchProductByBarcode(
    String barcode,
  ) async {
    final url = Uri.parse(
      'https://world.openfoodfacts.org/api/v2/product/$barcode.json',
    );

    try {
      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'Tibok-HypertensionApp - Android - Version 1.0',
        },
      );

      if (response.statusCode != 200) {
        return null;
      }

      final decoded = jsonDecode(
        response.body,
      );

      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      if (decoded['status'] != 1 || decoded['product'] == null) {
        return null;
      }

      final rawProduct = decoded['product'];

      if (rawProduct is! Map<String, dynamic>) {
        return null;
      }

      final rawNutriments = rawProduct['nutriments'];

      final nutriments = rawNutriments is Map<String, dynamic>
          ? rawNutriments
          : <String, dynamic>{};

      final rawName = rawProduct['product_name']?.toString().trim();

      final name =
          rawName != null && rawName.isNotEmpty ? rawName : 'Unknown Product';

      final rawServingSize = rawProduct['serving_size']?.toString().trim();

      final servingSize = rawServingSize != null && rawServingSize.isNotEmpty
          ? rawServingSize
          : 'Serving size unavailable';

      final ingredientsText =
          rawProduct['ingredients_text']?.toString().trim() ?? '';

      final sodiumPer100g = _extractSodiumPer100g(
        nutriments,
      );

      final sodiumPerServing = _extractSodiumPerServing(
        nutriments,
      );

      final detectedHidden = <String>[];

      final lowerIngredients = ingredientsText.toLowerCase();

      for (final term in _hiddenSodiumTerms) {
        if (lowerIngredients.contains(term)) {
          detectedHidden.add(
            term,
          );
        }
      }

      return ScannedProduct(
        barcode: barcode,
        name: name,
        sodiumPer100gMg: sodiumPer100g,
        sodiumPerServingMg: sodiumPerServing,
        servingSize: servingSize,
        ingredientsText: ingredientsText.isEmpty
            ? 'No ingredient list provided.'
            : ingredientsText,
        hasHiddenSodium: detectedHidden.isNotEmpty,
        detectedHiddenIngredients: detectedHidden,
      );
    } catch (_) {
      return null;
    }
  }
}
