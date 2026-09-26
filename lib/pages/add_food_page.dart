import 'package:flutter/material.dart';

import '../services/food_log_service.dart';
import '../utils/sodium_rating.dart';

class AddFoodPage extends StatefulWidget {
  const AddFoodPage({
    super.key,
  });

  @override
  State<AddFoodPage> createState() => _AddFoodPageState();
}

class _AddFoodPageState extends State<AddFoodPage> {
  final FoodLogService _foodLogService = FoodLogService();

  final TextEditingController _searchController = TextEditingController();

  String _selectedCategory = 'All';

  static const List<String> _categories = [
    'All',
    'Meals',
    'Snacks',
    'Fruits',
    'Packaged',
  ];

  static const List<Map<String, dynamic>> _foods = [
    // Added unsalted preparations. Sodium is estimated mg per 100 g.
    // Sources and mixture calculations: FOOD_DATA_SOURCES.md in this update.
    // These are separate foods, not reduced values for existing salty dishes.
    {
      'name': 'Roasted Chicken Breast - Unsalted',
      'sodium': 74,
      'category': 'Meals',
      'preparation_note': 'Plain skinless breast meat, roasted without brine, salt, marinade, or sauce. Estimate for cooked edible meat only.',
    },
    {
      'name': 'Baked Tilapia - Unsalted',
      'sodium': 56,
      'category': 'Meals',
      'preparation_note': 'Plain tilapia cooked with dry heat, without salt, brine, seasoning mixes, or sauce. Weigh the cooked edible fish, excluding bones.',
    },
    {
      'name': 'Brown Rice - Unsalted',
      'sodium': 4,
      'category': 'Meals',
      'preparation_note': 'Cooked long-grain brown rice with no salt, broth, or sauce added.',
    },
    {
      'name': 'Boiled Monggo - Unsalted',
      'sodium': 2,
      'category': 'Meals',
      'preparation_note': 'Plain mung beans boiled without salt. This is not ginisang monggo with broth, fish sauce, or other ingredients.',
    },
    {
      'name': 'Boiled Lentils - Unsalted',
      'sodium': 2,
      'category': 'Meals',
      'preparation_note': 'Plain lentils boiled without salt, broth, or sauce.',
    },
    {
      'name': 'Boiled Potatoes - Unsalted',
      'sodium': 5,
      'category': 'Meals',
      'preparation_note': 'Potatoes peeled before boiling, cooked without salt, and drained. No butter, milk, or sauce included.',
    },
    {
      'name': 'Boiled Summer Squash - Unsalted',
      'sodium': 1,
      'category': 'Meals',
      'preparation_note': 'Summer squash boiled, drained, and prepared without salt or sauce. This entry is not for kalabasa or other winter squash.',
    },
    {
      'name': 'Chicken & Brown Rice Bowl - Unsalted',
      'sodium': 39,
      'category': 'Meals',
      'preparation_note': 'Calculated estimate for equal cooked weights of plain roasted skinless chicken breast and long-grain brown rice (50 g each per 100 g). No salt, brine, broth, or sauce. Log ingredients separately if your proportions differ.',
    },
    {
      'name': 'Tilapia & Brown Rice Bowl - Unsalted',
      'sodium': 30,
      'category': 'Meals',
      'preparation_note': 'Calculated estimate for equal cooked weights of plain baked tilapia and long-grain brown rice (50 g each per 100 g). No salt, brine, broth, or sauce. Log ingredients separately if your proportions differ.',
    },
    {
      'name': 'Monggo & Brown Rice Bowl - Unsalted',
      'sodium': 3,
      'category': 'Meals',
      'preparation_note': 'Calculated estimate for equal cooked weights of plain boiled mung beans and long-grain brown rice (50 g each per 100 g). No salt, broth, or sauce. Log ingredients separately if your proportions differ.',
    },
    {
      'name': 'Lentil & Brown Rice Bowl - Unsalted',
      'sodium': 3,
      'category': 'Meals',
      'preparation_note': 'Calculated estimate for equal cooked weights of plain boiled lentils and long-grain brown rice (50 g each per 100 g). No salt, broth, or sauce. Log ingredients separately if your proportions differ.',
    },
    {
      'name': 'Chicken Adobo',
      'sodium': 720,
      'category': 'Meals',
    },
    {
      'name': 'Pork Adobo',
      'sodium': 680,
      'category': 'Meals',
    },
    {
      'name': 'Sinigang na Baboy',
      'sodium': 650,
      'category': 'Meals',
    },
    {
      'name': 'Sinigang na Hipon',
      'sodium': 610,
      'category': 'Meals',
    },
    {
      'name': 'Beef Caldereta',
      'sodium': 540,
      'category': 'Meals',
    },
    {
      'name': 'Chicken Afritada',
      'sodium': 480,
      'category': 'Meals',
    },
    {
      'name': 'Pork Menudo',
      'sodium': 520,
      'category': 'Meals',
    },
    {
      'name': 'Beef Mechado',
      'sodium': 510,
      'category': 'Meals',
    },
    {
      'name': 'Chicken Tinola',
      'sodium': 390,
      'category': 'Meals',
    },
    {
      'name': 'Pinakbet',
      'sodium': 430,
      'category': 'Meals',
    },
    {
      'name': 'Kare-Kare',
      'sodium': 420,
      'category': 'Meals',
    },
    {
      'name': 'Bistek Tagalog',
      'sodium': 760,
      'category': 'Meals',
    },
    {
      'name': 'Pancit Canton',
      'sodium': 560,
      'category': 'Meals',
    },
    {
      'name': 'Pancit Bihon',
      'sodium': 470,
      'category': 'Meals',
    },
    {
      'name': 'Fried Chicken',
      'sodium': 620,
      'category': 'Meals',
    },
    {
      'name': 'Chicken Inasal',
      'sodium': 590,
      'category': 'Meals',
    },
    {
      'name': 'Lumpiang Shanghai',
      'sodium': 610,
      'category': 'Meals',
    },
    {
      'name': 'Tortang Talong',
      'sodium': 210,
      'category': 'Meals',
    },
    {
      'name': 'Ginisang Monggo',
      'sodium': 360,
      'category': 'Meals',
    },
    {
      'name': 'White Rice',
      'sodium': 5,
      'category': 'Meals',
    },
    {
      'name': 'Garlic Rice',
      'sodium': 190,
      'category': 'Meals',
    },
    {
      'name': 'Arroz Caldo',
      'sodium': 410,
      'category': 'Meals',
    },
    {
      'name': 'Champorado',
      'sodium': 75,
      'category': 'Meals',
    },
    {
      'name': 'Beef Tapa',
      'sodium': 780,
      'category': 'Meals',
    },
    {
      'name': 'Pork Tocino',
      'sodium': 730,
      'category': 'Meals',
    },
    {
      'name': 'Potato Chips',
      'sodium': 170,
      'category': 'Snacks',
    },
    {
      'name': 'French Fries',
      'sodium': 260,
      'category': 'Snacks',
    },
    {
      'name': 'Cheese Crackers',
      'sodium': 610,
      'category': 'Snacks',
    },
    {
      'name': 'Salted Peanuts',
      'sodium': 390,
      'category': 'Snacks',
    },
    {
      'name': 'Popcorn - Salted',
      'sodium': 320,
      'category': 'Snacks',
    },
    {
      'name': 'Banana Cue',
      'sodium': 8,
      'category': 'Snacks',
    },
    {
      'name': 'Turon',
      'sodium': 45,
      'category': 'Snacks',
    },
    {
      'name': 'Pandesal',
      'sodium': 390,
      'category': 'Snacks',
    },
    {
      'name': 'Ensaymada',
      'sodium': 280,
      'category': 'Snacks',
    },
    {
      'name': 'Siopao',
      'sodium': 520,
      'category': 'Snacks',
    },
    {
      'name': 'Banana',
      'sodium': 1,
      'category': 'Fruits',
    },
    {
      'name': 'Apple',
      'sodium': 1,
      'category': 'Fruits',
    },
    {
      'name': 'Orange',
      'sodium': 0,
      'category': 'Fruits',
    },
    {
      'name': 'Mango',
      'sodium': 1,
      'category': 'Fruits',
    },
    {
      'name': 'Pineapple',
      'sodium': 1,
      'category': 'Fruits',
    },
    {
      'name': 'Watermelon',
      'sodium': 1,
      'category': 'Fruits',
    },
    {
      'name': 'Papaya',
      'sodium': 8,
      'category': 'Fruits',
    },
    {
      'name': 'Grapes',
      'sodium': 2,
      'category': 'Fruits',
    },
    {
      'name': 'Guava',
      'sodium': 2,
      'category': 'Fruits',
    },
    {
      'name': 'Dragon Fruit',
      'sodium': 0,
      'category': 'Fruits',
    },
    {
      'name': 'Instant Noodles',
      'sodium': 900,
      'category': 'Packaged',
    },
    {
      'name': 'Canned Sardines',
      'sodium': 480,
      'category': 'Packaged',
    },
    {
      'name': 'Corned Beef',
      'sodium': 850,
      'category': 'Packaged',
    },
    {
      'name': 'Hotdog',
      'sodium': 900,
      'category': 'Packaged',
    },
    {
      'name': 'Canned Tuna',
      'sodium': 430,
      'category': 'Packaged',
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredFoods {
    final query = _searchController.text.trim().toLowerCase();

    return _foods.where(
      (food) {
        final matchesCategory =
            _selectedCategory == 'All' || food['category'] == _selectedCategory;

        final name = food['name']?.toString().toLowerCase() ?? '';

        final matchesSearch = query.isEmpty || name.contains(query);

        return matchesCategory && matchesSearch;
      },
    ).toList();
  }

  Future<void> _showFoodDialog(
    Map<String, dynamic> food,
  ) async {
    final sodiumPer100g = (food['sodium'] as num).toDouble();

    final gramsController = TextEditingController(
      text: '100',
    );

    bool saving = false;
    String? dialogError;

    final added = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (
        dialogContext,
      ) {
        return StatefulBuilder(
          builder: (
            context,
            setDialogState,
          ) {
            final grams = double.tryParse(
              gramsController.text.trim(),
            );

            final totalSodium = grams != null && grams > 0
                ? (sodiumPer100g * grams / 100).round()
                : null;

            return AlertDialog(
              title: Text(
                food['name'].toString(),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTrafficLight(
                      sodiumPer100g,
                    ),
                    const SizedBox(
                      height: 18,
                    ),
                    _buildValueRow(
                      context,
                      label: 'Sodium per 100 g',
                      value: '${sodiumPer100g.round()} mg',
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    if (food['preparation_note'] != null) ...[
                      Text(
                        food['preparation_note'].toString(),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 16),
                    ],
                    TextField(
                      controller: gramsController,
                      enabled: !saving,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textInputAction: TextInputAction.done,
                      onChanged: (_) {
                        setDialogState(
                          () {
                            dialogError = null;
                          },
                        );
                      },
                      decoration: const InputDecoration(
                        labelText: 'Amount Consumed',
                        suffixText: 'g',
                        prefixIcon: Icon(
                          Icons.scale_outlined,
                        ),
                        helperText: 'Enter the approximate weight you ate.',
                      ),
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    _buildTotalSodiumBox(
                      context,
                      totalSodium,
                    ),
                    if (dialogError != null) ...[
                      const SizedBox(
                        height: 12,
                      ),
                      _buildDialogError(
                        context,
                        dialogError!,
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving
                      ? null
                      : () {
                          FocusManager.instance.primaryFocus?.unfocus();

                          Navigator.of(
                            dialogContext,
                          ).pop(
                            false,
                          );
                        },
                  child: const Text(
                    'Cancel',
                  ),
                ),
                FilledButton(
                  onPressed: saving
                      ? null
                      : () async {
                          final grams = double.tryParse(
                            gramsController.text.trim(),
                          );

                          if (grams == null || grams <= 0) {
                            setDialogState(
                              () {
                                dialogError = 'Enter a valid amount consumed.';
                              },
                            );
                            return;
                          }

                          final total = (sodiumPer100g * grams / 100).round();

                          setDialogState(
                            () {
                              saving = true;
                              dialogError = null;
                            },
                          );

                          try {
                            await _foodLogService.addFoodLog(
                              requestId: _foodLogService.createRequestId(),
                              foodName: food['name'].toString(),
                              sodiumAmount: total,
                              logDate: _foodLogService.philippineNow,
                              entryType: 'searched',
                              servings: grams / 100,
                              sodiumPerServingMg: sodiumPer100g.round(),
                              sodiumBasis: 'per_100g',
                            );

                            if (!dialogContext.mounted) {
                              return;
                            }

                            FocusManager.instance.primaryFocus?.unfocus();

                            Navigator.of(
                              dialogContext,
                            ).pop(
                              true,
                            );
                          } catch (_) {
                            if (!dialogContext.mounted) {
                              return;
                            }

                            setDialogState(
                              () {
                                saving = false;
                                dialogError =
                                    'Could not add this food. Please try again.';
                              },
                            );
                          }
                        },
                  child: saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Add to Log',
                        ),
                ),
              ],
            );
          },
        );
      },
    );

    await Future<void>.delayed(
      const Duration(
        milliseconds: 350,
      ),
    );

    gramsController.dispose();

    if (!mounted) {
      return;
    }

    if (added == true) {
      Navigator.pop(
        context,
        true,
      );
    }
  }

  Future<void> _showManualFoodDialog() async {
    final nameController = TextEditingController();

    final sodiumController = TextEditingController();

    final gramsController = TextEditingController(
      text: '100',
    );

    bool saving = false;
    String? dialogError;

    final added = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (
        dialogContext,
      ) {
        return StatefulBuilder(
          builder: (
            context,
            setDialogState,
          ) {
            final sodiumPer100g = double.tryParse(
              sodiumController.text.trim(),
            );

            final grams = double.tryParse(
              gramsController.text.trim(),
            );

            final totalSodium = sodiumPer100g != null &&
                    sodiumPer100g >= 0 &&
                    grams != null &&
                    grams > 0
                ? (sodiumPer100g * grams / 100).round()
                : null;

            return AlertDialog(
              title: const Text(
                'Enter Food Manually',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: nameController,
                      enabled: !saving,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Food Name',
                        prefixIcon: Icon(
                          Icons.restaurant_outlined,
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 14,
                    ),
                    TextField(
                      controller: sodiumController,
                      enabled: !saving,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textInputAction: TextInputAction.next,
                      onChanged: (_) {
                        setDialogState(
                          () {
                            dialogError = null;
                          },
                        );
                      },
                      decoration: const InputDecoration(
                        labelText: 'Sodium per 100 g',
                        suffixText: 'mg',
                        prefixIcon: Icon(
                          Icons.water_drop_outlined,
                        ),
                        helperText:
                            'Use the nutrition label or recipe estimate.',
                      ),
                    ),
                    const SizedBox(
                      height: 14,
                    ),
                    TextField(
                      controller: gramsController,
                      enabled: !saving,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textInputAction: TextInputAction.done,
                      onChanged: (_) {
                        setDialogState(
                          () {
                            dialogError = null;
                          },
                        );
                      },
                      decoration: const InputDecoration(
                        labelText: 'Amount Consumed',
                        suffixText: 'g',
                        prefixIcon: Icon(
                          Icons.scale_outlined,
                        ),
                      ),
                    ),
                    if (sodiumPer100g != null && sodiumPer100g >= 0) ...[
                      const SizedBox(
                        height: 16,
                      ),
                      _buildTrafficLight(
                        sodiumPer100g,
                      ),
                    ],
                    const SizedBox(
                      height: 16,
                    ),
                    _buildTotalSodiumBox(
                      context,
                      totalSodium,
                    ),
                    if (dialogError != null) ...[
                      const SizedBox(
                        height: 12,
                      ),
                      _buildDialogError(
                        context,
                        dialogError!,
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving
                      ? null
                      : () {
                          FocusManager.instance.primaryFocus?.unfocus();

                          Navigator.of(
                            dialogContext,
                          ).pop(
                            false,
                          );
                        },
                  child: const Text(
                    'Cancel',
                  ),
                ),
                FilledButton(
                  onPressed: saving
                      ? null
                      : () async {
                          final foodName = nameController.text.trim();

                          final sodium = double.tryParse(
                            sodiumController.text.trim(),
                          );

                          final grams = double.tryParse(
                            gramsController.text.trim(),
                          );

                          if (foodName.isEmpty) {
                            setDialogState(
                              () {
                                dialogError = 'Enter a food name.';
                              },
                            );
                            return;
                          }

                          if (sodium == null || sodium < 0) {
                            setDialogState(
                              () {
                                dialogError = 'Enter a valid sodium amount.';
                              },
                            );
                            return;
                          }

                          if (grams == null || grams <= 0) {
                            setDialogState(
                              () {
                                dialogError = 'Enter a valid amount consumed.';
                              },
                            );
                            return;
                          }

                          final total = (sodium * grams / 100).round();

                          setDialogState(
                            () {
                              saving = true;
                              dialogError = null;
                            },
                          );

                          try {
                            await _foodLogService.addFoodLog(
                              requestId: _foodLogService.createRequestId(),
                              foodName: foodName,
                              sodiumAmount: total,
                              logDate: _foodLogService.philippineNow,
                              entryType: 'manual',
                              servings: grams / 100,
                              sodiumPerServingMg: sodium.round(),
                              sodiumBasis: 'per_100g',
                            );

                            if (!dialogContext.mounted) {
                              return;
                            }

                            FocusManager.instance.primaryFocus?.unfocus();

                            Navigator.of(
                              dialogContext,
                            ).pop(
                              true,
                            );
                          } catch (_) {
                            if (!dialogContext.mounted) {
                              return;
                            }

                            setDialogState(
                              () {
                                saving = false;
                                dialogError =
                                    'Could not add this food. Please try again.';
                              },
                            );
                          }
                        },
                  child: saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Add Food',
                        ),
                ),
              ],
            );
          },
        );
      },
    );

    await Future<void>.delayed(
      const Duration(
        milliseconds: 350,
      ),
    );

    nameController.dispose();
    sodiumController.dispose();
    gramsController.dispose();

    if (!mounted) {
      return;
    }

    if (added == true) {
      Navigator.pop(
        context,
        true,
      );
    }
  }

  Widget _buildTrafficLight(
    double sodiumPer100g,
  ) {
    final color = SodiumRating.colorFor(
      sodiumPer100g,
    );

    final label = SodiumRating.labelFor(
      sodiumPer100g,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        14,
      ),
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: 0.09,
        ),
        borderRadius: BorderRadius.circular(
          14,
        ),
        border: Border.all(
          color: color.withValues(
            alpha: 0.30,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            SodiumRating.iconFor(
              sodiumPer100g,
            ),
            color: color,
            size: 24,
          ),
          const SizedBox(
            width: 11,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(
                  height: 2,
                ),
                Text(
                  '${sodiumPer100g.round()} mg per 100 g',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(
                        color: color,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValueRow(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium,
          ),
        ),
        const SizedBox(
          width: 12,
        ),
        Text(
          value,
          style: theme.textTheme.titleMedium,
        ),
      ],
    );
  }

  Widget _buildTotalSodiumBox(
    BuildContext context,
    int? total,
  ) {
    final colors = Theme.of(context).colorScheme;

    return Container(
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
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogError(
    BuildContext context,
    String message,
  ) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(
        12,
      ),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(
          12,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.error_outline,
            color: colors.onErrorContainer,
          ),
          const SizedBox(
            width: 10,
          ),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: colors.onErrorContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _clearSearch() {
    _searchController.clear();

    setState(() {});
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final foods = _filteredFoods;

    final theme = Theme.of(context);

    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Add Food',
        ),
      ),
      body: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(
          18,
          10,
          18,
          30,
        ),
        children: [
          TextField(
            controller: _searchController,
            onChanged: (_) {
              setState(() {});
            },
            decoration: InputDecoration(
              hintText: 'Search common foods',
              prefixIcon: const Icon(
                Icons.search_rounded,
              ),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      onPressed: _clearSearch,
                      icon: const Icon(
                        Icons.close_rounded,
                      ),
                    ),
            ),
          ),
          const SizedBox(
            height: 12,
          ),
          SizedBox(
            width: double.infinity,
            height: 58,
            child: OutlinedButton.icon(
              onPressed: _showManualFoodDialog,
              icon: const Icon(
                Icons.edit_note_rounded,
                size: 25,
              ),
              label: const Text(
                'Enter Food Manually',
              ),
            ),
          ),
          const SizedBox(
            height: 16,
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _categories.map(
                (category) {
                  return Padding(
                    padding: const EdgeInsets.only(
                      right: 8,
                    ),
                    child: ChoiceChip(
                      label: Text(
                        category,
                      ),
                      selected: _selectedCategory == category,
                      onSelected: (_) {
                        setState(
                          () {
                            _selectedCategory = category;
                          },
                        );
                      },
                    ),
                  );
                },
              ).toList(),
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Common Foods',
                  style: theme.textTheme.titleLarge,
                ),
              ),
              Text(
                '${foods.length}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 5,
          ),
          Text(
            'Values are per 100 g. Prepared foods may vary by recipe.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(
            height: 12,
          ),
          if (foods.isEmpty)
            _buildEmptyState()
          else
            ...foods.map(
              _buildFoodCard,
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);

    final colors = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 38,
          horizontal: 24,
        ),
        child: Column(
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 50,
              color: colors.outline,
            ),
            const SizedBox(
              height: 12,
            ),
            Text(
              'No matching foods',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(
              height: 5,
            ),
            Text(
              'Try another search or enter the food manually.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFoodCard(
    Map<String, dynamic> food,
  ) {
    final sodium = (food['sodium'] as num).toDouble();

    final color = SodiumRating.colorFor(
      sodium,
    );

    final label = SodiumRating.labelFor(
      sodium,
    );

    final theme = Theme.of(context);

    final colors = theme.colorScheme;

    final textScale = MediaQuery.of(context).textScaler.scale(
          1.0,
        );

    final largeText = textScale >= 1.25;

    return Card(
      elevation: 1,
      shadowColor: Colors.black.withValues(
        alpha: 0.05,
      ),
      margin: const EdgeInsets.only(
        bottom: 10,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(
          20,
        ),
        onTap: () {
          _showFoodDialog(
            food,
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(
            14,
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color.withValues(
                        alpha: 0.10,
                      ),
                      borderRadius: BorderRadius.circular(
                        13,
                      ),
                    ),
                    child: Icon(
                      SodiumRating.iconFor(
                        sodium,
                      ),
                      color: color,
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
                          food['name'].toString(),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(
                          height: 3,
                        ),
                        Wrap(
                          spacing: 5,
                          runSpacing: 2,
                          children: [
                            Text(
                              food['category'].toString(),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              '•',
                              style: theme.textTheme.bodySmall,
                            ),
                            Text(
                              label,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: color,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (!largeText) ...[
                    const SizedBox(
                      width: 10,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${sodium.round()} mg',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'per 100 g',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      width: 2,
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: colors.onSurfaceVariant,
                    ),
                  ],
                ],
              ),
              if (largeText) ...[
                const SizedBox(
                  height: 10,
                ),
                Padding(
                  padding: const EdgeInsets.only(
                    left: 60,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${sodium.round()} mg per 100 g',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: colors.onSurfaceVariant,
                      ),
                    ],
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
