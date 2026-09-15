import 'package:flutter/material.dart';

enum SodiumLevel {
  green,
  yellow,
  red,
}

class SodiumRating {
  const SodiumRating._();

  static SodiumLevel levelFor(double sodiumPer100g) {
    if (sodiumPer100g <= 120) {
      return SodiumLevel.green;
    }

    if (sodiumPer100g <= 600) {
      return SodiumLevel.yellow;
    }

    return SodiumLevel.red;
  }

  static String labelFor(double sodiumPer100g) {
    switch (levelFor(sodiumPer100g)) {
      case SodiumLevel.green:
        return 'Low Sodium';

      case SodiumLevel.yellow:
        return 'Moderate Sodium';

      case SodiumLevel.red:
        return 'High Sodium';
    }
  }

  static Color colorFor(double sodiumPer100g) {
    switch (levelFor(sodiumPer100g)) {
      case SodiumLevel.green:
        return Colors.green;

      case SodiumLevel.yellow:
        return Colors.amber.shade700;

      case SodiumLevel.red:
        return Colors.red;
    }
  }

  static IconData iconFor(double sodiumPer100g) {
    switch (levelFor(sodiumPer100g)) {
      case SodiumLevel.green:
        return Icons.check_circle;

      case SodiumLevel.yellow:
        return Icons.warning_amber_rounded;

      case SodiumLevel.red:
        return Icons.error;
    }
  }
}
