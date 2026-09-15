import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppTextSize {
  standard,
  large,
  extraLarge,
}

extension AppTextSizeDetails on AppTextSize {
  String get label {
    switch (this) {
      case AppTextSize.standard:
        return 'Standard';
      case AppTextSize.large:
        return 'Large';
      case AppTextSize.extraLarge:
        return 'Extra Large';
    }
  }

  String get description {
    switch (this) {
      case AppTextSize.standard:
        return 'Default Tibok text size';
      case AppTextSize.large:
        return 'Easier to read';
      case AppTextSize.extraLarge:
        return 'Largest and most readable';
    }
  }

  double get scaleFactor {
    switch (this) {
      case AppTextSize.standard:
        return 1.0;
      case AppTextSize.large:
        return 1.15;
      case AppTextSize.extraLarge:
        return 1.30;
    }
  }

  String get percentageLabel {
    return '${(scaleFactor * 100).round()}%';
  }
}

class AppSettingsController extends ChangeNotifier {
  AppSettingsController._();

  static final AppSettingsController instance = AppSettingsController._();

  static const String _textSizeKey = 'tibok_text_size';

  AppTextSize _textSize = AppTextSize.standard;

  AppTextSize get textSize => _textSize;

  double get textScaleFactor => _textSize.scaleFactor;

  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();

    final storedValue = preferences.getString(
      _textSizeKey,
    );

    if (storedValue == null) {
      return;
    }

    _textSize = AppTextSize.values.firstWhere(
      (value) => value.name == storedValue,
      orElse: () => AppTextSize.standard,
    );

    notifyListeners();
  }

  Future<void> setTextSize(
    AppTextSize size,
  ) async {
    if (_textSize == size) {
      return;
    }

    _textSize = size;

    notifyListeners();

    final preferences = await SharedPreferences.getInstance();

    await preferences.setString(
      _textSizeKey,
      size.name,
    );
  }

  Future<void> resetTextSize() async {
    await setTextSize(
      AppTextSize.standard,
    );
  }
}
