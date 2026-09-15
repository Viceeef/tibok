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

  // Working sodium estimates per 100 g.
  // Prepared-food sodium varies depending on recipe,
  // ingredients, sauces, seasonings, and brand.
  static const List<Map<String, dynamic>> _foods = [
    // =========================
    // MEALS — 25
    // =========================
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

    // =========================
    // SNACKS — 10
    // =========================
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

    // =========================
    // FRUITS — 10
    // =========================
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

    // =========================
    // PACKAGED — 5
    // =========================
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

    return _foods.where((food) {
      final matchesCategory =
          _selectedCategory == 'All' || food['category'] == _selectedCategory;

      final name = food['name']?.toString().toLowerCase() ?? '';

      final matchesSearch = query.isEmpty || name.contains(query);

      return matchesCategory && matchesSearch;
    }).toList();
  }

  Future<void> _showFoodDialog(
    Map<String, dynamic> food,
  ) async {
    final sodiumPer100g = (food['sodium'] as num).toDouble();

    final gramsController = TextEditingController(
      text: '100',
    );

    bool saving = false;

    await showDialog<void>(
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

            final color = SodiumRating.colorFor(
              sodiumPer100g,
            );

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
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Sodium per 100 g',
                          ),
                        ),
                        Text(
                          '${sodiumPer100g.round()} mg',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    TextField(
                      controller: gramsController,
                      enabled: !saving,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      onChanged: (_) {
                        setDialogState(
                          () {},
                        );
                      },
                      decoration: const InputDecoration(
                        labelText: 'Amount Consumed',
                        suffixText: 'g',
                        helperText: 'Enter the approximate weight consumed.',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: color.withValues(
                          alpha: 0.08,
                        ),
                        borderRadius: BorderRadius.circular(14),
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
                            totalSodium == null ? '-- mg' : '$totalSodium mg',
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
              actions: [
                TextButton(
                  onPressed: saving
                      ? null
                      : () {
                          Navigator.of(
                            dialogContext,
                          ).pop();
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
                            _showMessage(
                              'Enter a valid amount in grams.',
                            );
                            return;
                          }

                          final total = (sodiumPer100g * grams / 100).round();

                          setDialogState(
                            () {
                              saving = true;
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

                            Navigator.of(
                              dialogContext,
                            ).pop();

                            if (!mounted) {
                              return;
                            }

                            Navigator.pop(
                              context,
                              true,
                            );
                          } catch (e) {
                            if (!dialogContext.mounted) {
                              return;
                            }

                            setDialogState(
                              () {
                                saving = false;
                              },
                            );

                            _showMessage(
                              'Could not add food.',
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
  }

  Future<void> _showManualFoodDialog() async {
    final nameController = TextEditingController();

    final sodiumController = TextEditingController();

    final gramsController = TextEditingController(
      text: '100',
    );

    bool saving = false;

    await showDialog<void>(
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
                      decoration: const InputDecoration(
                        labelText: 'Food Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    TextField(
                      controller: sodiumController,
                      enabled: !saving,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      onChanged: (_) {
                        setDialogState(
                          () {},
                        );
                      },
                      decoration: const InputDecoration(
                        labelText: 'Sodium per 100 g',
                        suffixText: 'mg',
                        helperText:
                            'Use the nutrition label or recipe estimate.',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    TextField(
                      controller: gramsController,
                      enabled: !saving,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      onChanged: (_) {
                        setDialogState(
                          () {},
                        );
                      },
                      decoration: const InputDecoration(
                        labelText: 'Amount Consumed',
                        suffixText: 'g',
                        border: OutlineInputBorder(),
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
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
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
                            totalSodium == null ? '-- mg' : '$totalSodium mg',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving
                      ? null
                      : () {
                          Navigator.of(
                            dialogContext,
                          ).pop();
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
                            _showMessage(
                              'Food name cannot be empty.',
                            );
                            return;
                          }

                          if (sodium == null || sodium < 0) {
                            _showMessage(
                              'Enter a valid sodium amount.',
                            );
                            return;
                          }

                          if (grams == null || grams <= 0) {
                            _showMessage(
                              'Enter a valid amount consumed.',
                            );
                            return;
                          }

                          final total = (sodium * grams / 100).round();

                          setDialogState(
                            () {
                              saving = true;
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

                            Navigator.of(
                              dialogContext,
                            ).pop();

                            if (!mounted) {
                              return;
                            }

                            Navigator.pop(
                              context,
                              true,
                            );
                          } catch (e) {
                            if (!dialogContext.mounted) {
                              return;
                            }

                            setDialogState(
                              () {
                                saving = false;
                              },
                            );

                            _showMessage(
                              'Could not add food.',
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: 0.10,
        ),
        borderRadius: BorderRadius.circular(14),
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
            width: 12,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(
                  height: 3,
                ),
                Text(
                  '${sodiumPer100g.round()} mg per 100 g',
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showMessage(
    String message,
  ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final foods = _filteredFoods;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Add Food',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          16,
          14,
          16,
          30,
        ),
        children: [
          TextField(
            controller: _searchController,
            onChanged: (_) {
              setState(() {});
            },
            decoration: InputDecoration(
              hintText: 'Search common foods...',
              prefixIcon: const Icon(
                Icons.search,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  14,
                ),
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
                      label: Text(category),
                      selected: _selectedCategory == category,
                      onSelected: (_) {
                        setState(() {
                          _selectedCategory = category;
                        });
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
              const Expanded(
                child: Text(
                  'Common Foods',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '${foods.length} foods',
                style: TextStyle(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 4,
          ),
          Text(
            'Sodium values are shown per 100 g. '
            'Prepared-food values are estimates and can vary by recipe.',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 11,
              height: 1.3,
            ),
          ),
          const SizedBox(
            height: 12,
          ),
          if (foods.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 50,
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.search_off,
                    size: 52,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(
                    height: 12,
                  ),
                  const Text(
                    'No matching foods found',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )
          else
            ...foods.map(
              _buildFoodCard,
            ),
          const SizedBox(
            height: 16,
          ),
          OutlinedButton.icon(
            onPressed: _showManualFoodDialog,
            icon: const Icon(
              Icons.edit_note,
            ),
            label: const Text(
              'Enter Food Manually',
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                vertical: 16,
              ),
            ),
          ),
        ],
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

    return Card(
      margin: const EdgeInsets.only(
        bottom: 9,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          _showFoodDialog(food);
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withValues(
                    alpha: 0.10,
                  ),
                  borderRadius: BorderRadius.circular(12),
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
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(
                      height: 3,
                    ),
                    Text(
                      '${food['category']} • $label',
                      style: TextStyle(
                        fontSize: 12,
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${sodium.round()} mg',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'per 100 g',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              const SizedBox(
                width: 4,
              ),
              const Icon(
                Icons.chevron_right,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
