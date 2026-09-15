import 'package:flutter/material.dart';

import '../services/food_log_service.dart';

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

  final List<_CommonFood> _foods = const [
    _CommonFood(
      name: 'Chicken Adobo',
      servingSize: '1 serving (100 g)',
      sodiumPerServingMg: 720,
      category: 'Meals',
    ),
    _CommonFood(
      name: 'Sinigang',
      servingSize: '1 serving (100 g)',
      sodiumPerServingMg: 650,
      category: 'Meals',
    ),
    _CommonFood(
      name: 'Pork Adobo',
      servingSize: '1 serving (100 g)',
      sodiumPerServingMg: 680,
      category: 'Meals',
    ),
    _CommonFood(
      name: 'Pancit Canton',
      servingSize: '1 serving (100 g)',
      sodiumPerServingMg: 560,
      category: 'Meals',
    ),
    _CommonFood(
      name: 'Fried Chicken',
      servingSize: '1 serving (100 g)',
      sodiumPerServingMg: 620,
      category: 'Meals',
    ),
    _CommonFood(
      name: 'White Rice',
      servingSize: '1 serving (100 g)',
      sodiumPerServingMg: 5,
      category: 'Meals',
    ),
    _CommonFood(
      name: 'Canned Sardines',
      servingSize: '1 serving',
      sodiumPerServingMg: 480,
      category: 'Packaged',
    ),
    _CommonFood(
      name: 'Instant Noodles',
      servingSize: '1 pack',
      sodiumPerServingMg: 900,
      category: 'Packaged',
    ),
    _CommonFood(
      name: 'Potato Chips',
      servingSize: '1 serving',
      sodiumPerServingMg: 170,
      category: 'Snacks',
    ),
    _CommonFood(
      name: 'Banana',
      servingSize: '1 medium',
      sodiumPerServingMg: 1,
      category: 'Fruits',
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_CommonFood> get _filteredFoods {
    final query = _searchController.text.trim().toLowerCase();

    return _foods.where((food) {
      final matchesCategory =
          _selectedCategory == 'All' || food.category == _selectedCategory;

      final matchesSearch =
          query.isEmpty || food.name.toLowerCase().contains(query);

      return matchesCategory && matchesSearch;
    }).toList();
  }

  Future<void> _showFoodDialog(
    _CommonFood food,
  ) async {
    final servingsController = TextEditingController(text: '1');

    bool saving = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (
            context,
            setDialogState,
          ) {
            final servings = double.tryParse(
              servingsController.text.trim(),
            );

            final total = servings != null && servings > 0
                ? (food.sodiumPerServingMg * servings).round()
                : null;

            return AlertDialog(
              title: Text(food.name),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      height: 110,
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.restaurant,
                        size: 52,
                        color: Colors.redAccent,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Default Serving Size',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      food.servingSize,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Estimated Sodium per Serving',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${food.sodiumPerServingMg} mg',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: servingsController,
                      enabled: !saving,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      onChanged: (_) {
                        setDialogState(() {});
                      },
                      decoration: const InputDecoration(
                        labelText: 'Servings Consumed',
                        hintText: 'e.g. 1, 1.5, 2',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
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
                            total == null ? '-- mg' : '$total mg',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Nutrition values are estimated for the MVP '
                      'and may vary by recipe, brand, and serving size.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
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
                          Navigator.pop(
                            dialogContext,
                          );
                        },
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: saving
                      ? null
                      : () async {
                          final servings = double.tryParse(
                            servingsController.text.trim(),
                          );

                          if (servings == null || servings <= 0) {
                            _showMessage(
                              'Please enter a valid number of servings.',
                            );
                            return;
                          }

                          final totalSodium =
                              (food.sodiumPerServingMg * servings).round();

                          setDialogState(() {
                            saving = true;
                          });

                          try {
                            await _foodLogService.addFoodLog(
                              requestId: _foodLogService.createRequestId(),
                              foodName: food.name,
                              sodiumAmount: totalSodium,
                              logDate: _foodLogService.philippineNow,

                              // The RPC currently accepts
                              // "searched" and stores it
                              // compatibly in the database.
                              entryType: 'searched',

                              servings: servings,
                              sodiumPerServingMg: food.sodiumPerServingMg,
                            );

                            if (!dialogContext.mounted) {
                              return;
                            }

                            Navigator.pop(
                              dialogContext,
                            );

                            if (!mounted) {
                              return;
                            }

                            _showMessage(
                              '${food.name} added: '
                              '$totalSodium mg sodium.',
                            );

                            Navigator.pop(
                              context,
                              true,
                            );
                          } catch (e) {
                            if (!dialogContext.mounted) {
                              return;
                            }

                            setDialogState(() {
                              saving = false;
                            });

                            _showMessage(
                              'Could not save food: $e',
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
                          'Add to Today\'s Log',
                        ),
                ),
              ],
            );
          },
        );
      },
    );

    servingsController.dispose();
  }

  Future<void> _showManualFoodDialog() async {
    final foodController = TextEditingController();

    final sodiumController = TextEditingController();

    final servingsController = TextEditingController(text: '1');

    bool saving = false;
    String? requestId;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (
            context,
            setDialogState,
          ) {
            final sodiumPerServing = int.tryParse(
              sodiumController.text.trim(),
            );

            final servings = double.tryParse(
              servingsController.text.trim(),
            );

            int? total;

            if (sodiumPerServing != null &&
                sodiumPerServing >= 0 &&
                servings != null &&
                servings > 0) {
              total = (sodiumPerServing * servings).round();
            }

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
                      controller: foodController,
                      enabled: !saving,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Food / Meal Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: sodiumController,
                      enabled: !saving,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      onChanged: (_) {
                        setDialogState(() {});
                      },
                      decoration: const InputDecoration(
                        labelText: 'Sodium per Serving',
                        suffixText: 'mg',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: servingsController,
                      enabled: !saving,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      onChanged: (_) {
                        setDialogState(() {});
                      },
                      decoration: const InputDecoration(
                        labelText: 'Servings Consumed',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
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
                            total == null ? '-- mg' : '$total mg',
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
                          Navigator.pop(
                            dialogContext,
                          );
                        },
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: saving
                      ? null
                      : () async {
                          final foodName = foodController.text.trim();

                          final sodium = int.tryParse(
                            sodiumController.text.trim(),
                          );

                          final servings = double.tryParse(
                            servingsController.text.trim(),
                          );

                          if (foodName.isEmpty) {
                            _showMessage(
                              'Please enter a food name.',
                            );
                            return;
                          }

                          if (sodium == null || sodium < 0) {
                            _showMessage(
                              'Please enter a valid sodium amount.',
                            );
                            return;
                          }

                          if (servings == null || servings <= 0) {
                            _showMessage(
                              'Please enter valid servings.',
                            );
                            return;
                          }

                          final total = (sodium * servings).round();

                          requestId ??= _foodLogService.createRequestId();

                          setDialogState(() {
                            saving = true;
                          });

                          try {
                            await _foodLogService.addFoodLog(
                              requestId: requestId!,
                              foodName: foodName,
                              sodiumAmount: total,
                              logDate: _foodLogService.philippineNow,
                              entryType: 'manual',
                              servings: servings,
                              sodiumPerServingMg: sodium,
                            );

                            if (!dialogContext.mounted) {
                              return;
                            }

                            Navigator.pop(
                              dialogContext,
                            );

                            if (!mounted) {
                              return;
                            }

                            _showMessage(
                              '$foodName added: '
                              '$total mg sodium.',
                            );

                            Navigator.pop(
                              context,
                              true,
                            );
                          } catch (e) {
                            if (!dialogContext.mounted) {
                              return;
                            }

                            setDialogState(() {
                              saving = false;
                            });

                            _showMessage(
                              'Could not save food: $e',
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
                      : const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );

    foodController.dispose();
    sodiumController.dispose();
    servingsController.dispose();
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
        title: const Text('Add Food'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          16,
          16,
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
              hintText: 'Search foods or meals...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Common Foods',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                'All',
                'Meals',
                'Snacks',
                'Fruits',
                'Packaged',
              ].map(
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
          const SizedBox(height: 16),
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
                  const SizedBox(height: 12),
                  const Text(
                    'No foods found',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )
          else
            ...foods.map(
              (food) {
                return Card(
                  margin: const EdgeInsets.only(
                    bottom: 10,
                  ),
                  child: ListTile(
                    onTap: () {
                      _showFoodDialog(food);
                    },
                    leading: CircleAvatar(
                      backgroundColor: Colors.redAccent.withValues(
                        alpha: 0.10,
                      ),
                      child: const Icon(
                        Icons.restaurant,
                        color: Colors.redAccent,
                      ),
                    ),
                    title: Text(
                      food.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      '${food.servingSize}\n'
                      'Estimated sodium',
                    ),
                    isThreeLine: true,
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${food.sodiumPerServingMg} mg',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(
                          height: 4,
                        ),
                        const Icon(
                          Icons.chevron_right,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          const SizedBox(height: 14),
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
          const SizedBox(height: 10),
          Text(
            'Common-food nutrition values are estimates for the MVP. '
            'Actual sodium content varies by recipe and serving size.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

class _CommonFood {
  const _CommonFood({
    required this.name,
    required this.servingSize,
    required this.sodiumPerServingMg,
    required this.category,
  });

  final String name;
  final String servingSize;
  final int sodiumPerServingMg;
  final String category;
}
