import 'package:flutter/material.dart';

import '../services/food_log_service.dart';
import '../utils/sodium_rating.dart';

class AddFoodPage extends StatefulWidget {
  const AddFoodPage({super.key});

  @override
  State<AddFoodPage> createState() => _AddFoodPageState();
}

class _AddFoodPageState extends State<AddFoodPage> {
  final FoodLogService _foodLogService = FoodLogService();

  final TextEditingController _searchController = TextEditingController();
  late Future<List<Map<String, dynamic>>> _addedFoodsFuture;

  String _selectedCategory = 'All';

  static const List<String> _categories = [
    'All',
    'Meals',
    'Snacks',
    'Fruits',
    'Packaged',
    'Fast Food',
    'Your Added Food',
  ];

  static const List<Map<String, dynamic>> _foods = [
    // Added unsalted preparations. Sodium is estimated mg per 100 g.
    // Sources and mixture calculations: FOOD_DATA_SOURCES.md in this update.
    // These are separate foods, not reduced values for existing salty dishes.
    {
      'name': 'Roasted Chicken Breast - Unsalted',
      'sodium': 74,
      'category': 'Meals',
      'preparation_note':
          'Plain skinless breast meat, roasted without brine, salt, marinade, or sauce. Estimate for cooked edible meat only.',
    },
    {
      'name': 'Baked Tilapia - Unsalted',
      'sodium': 56,
      'category': 'Meals',
      'preparation_note':
          'Plain tilapia cooked with dry heat, without salt, brine, seasoning mixes, or sauce. Weigh the cooked edible fish, excluding bones.',
    },
    {
      'name': 'Brown Rice - Unsalted',
      'sodium': 4,
      'category': 'Meals',
      'preparation_note':
          'Cooked long-grain brown rice with no salt, broth, or sauce added.',
    },
    {
      'name': 'Boiled Monggo - Unsalted',
      'sodium': 2,
      'category': 'Meals',
      'preparation_note':
          'Plain mung beans boiled without salt. This is not ginisang monggo with broth, fish sauce, or other ingredients.',
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
      'preparation_note':
          'Potatoes peeled before boiling, cooked without salt, and drained. No butter, milk, or sauce included.',
    },
    {
      'name': 'Boiled Summer Squash - Unsalted',
      'sodium': 1,
      'category': 'Meals',
      'preparation_note':
          'Summer squash boiled, drained, and prepared without salt or sauce. This entry is not for kalabasa or other winter squash.',
    },
    {
      'name': 'Chicken & Brown Rice Bowl - Unsalted',
      'sodium': 39,
      'category': 'Meals',
      'preparation_note':
          'Calculated estimate for equal cooked weights of plain roasted skinless chicken breast and long-grain brown rice (50 g each per 100 g). No salt, brine, broth, or sauce. Log ingredients separately if your proportions differ.',
    },
    {
      'name': 'Tilapia & Brown Rice Bowl - Unsalted',
      'sodium': 30,
      'category': 'Meals',
      'preparation_note':
          'Calculated estimate for equal cooked weights of plain baked tilapia and long-grain brown rice (50 g each per 100 g). No salt, brine, broth, or sauce. Log ingredients separately if your proportions differ.',
    },
    {
      'name': 'Monggo & Brown Rice Bowl - Unsalted',
      'sodium': 3,
      'category': 'Meals',
      'preparation_note':
          'Calculated estimate for equal cooked weights of plain boiled mung beans and long-grain brown rice (50 g each per 100 g). No salt, broth, or sauce. Log ingredients separately if your proportions differ.',
    },
    {
      'name': 'Lentil & Brown Rice Bowl - Unsalted',
      'sodium': 3,
      'category': 'Meals',
      'preparation_note':
          'Calculated estimate for equal cooked weights of plain boiled lentils and long-grain brown rice (50 g each per 100 g). No salt, broth, or sauce. Log ingredients separately if your proportions differ.',
    },
    {'name': 'Chicken Adobo', 'sodium': 720, 'category': 'Meals'},
    {'name': 'Pork Adobo', 'sodium': 680, 'category': 'Meals'},
    {'name': 'Sinigang na Baboy', 'sodium': 650, 'category': 'Meals'},
    {'name': 'Sinigang na Hipon', 'sodium': 610, 'category': 'Meals'},
    {'name': 'Beef Caldereta', 'sodium': 540, 'category': 'Meals'},
    {'name': 'Chicken Afritada', 'sodium': 480, 'category': 'Meals'},
    {'name': 'Pork Menudo', 'sodium': 520, 'category': 'Meals'},
    {'name': 'Beef Mechado', 'sodium': 510, 'category': 'Meals'},
    {'name': 'Chicken Tinola', 'sodium': 390, 'category': 'Meals'},
    {'name': 'Pinakbet', 'sodium': 430, 'category': 'Meals'},
    {'name': 'Kare-Kare', 'sodium': 420, 'category': 'Meals'},
    {'name': 'Bistek Tagalog', 'sodium': 760, 'category': 'Meals'},
    {'name': 'Pancit Canton', 'sodium': 560, 'category': 'Meals'},
    {'name': 'Pancit Bihon', 'sodium': 470, 'category': 'Meals'},
    {'name': 'Fried Chicken', 'sodium': 620, 'category': 'Meals'},
    {'name': 'Chicken Inasal', 'sodium': 590, 'category': 'Meals'},
    {'name': 'Lumpiang Shanghai', 'sodium': 610, 'category': 'Meals'},
    {'name': 'Tortang Talong', 'sodium': 210, 'category': 'Meals'},
    {'name': 'Ginisang Monggo', 'sodium': 360, 'category': 'Meals'},
    {'name': 'White Rice', 'sodium': 5, 'category': 'Meals'},
    {'name': 'Garlic Rice', 'sodium': 190, 'category': 'Meals'},
    {'name': 'Arroz Caldo', 'sodium': 410, 'category': 'Meals'},
    {'name': 'Champorado', 'sodium': 75, 'category': 'Meals'},
    {'name': 'Beef Tapa', 'sodium': 780, 'category': 'Meals'},
    {'name': 'Pork Tocino', 'sodium': 730, 'category': 'Meals'},
    {
      'name': 'Bulad (Salted Dried Fish)',
      'sodium': 3500,
      'category': 'Meals',
      'preparation_note':
          'Estimated sodium for salted dried herring, based on about 9% salt by weight. Bulad varies greatly by fish and salting method. Weigh the edible fish, not bones or added oil.',
    },
    {
      'name': 'Pork Humba',
      'sodium': 441,
      'category': 'Meals',
      'preparation_note':
          'Reference estimate from a ready-to-eat pork humba product. Home recipes vary with soy sauce, tausi, and serving proportions.',
    },
    {
      'name': 'Pork Sisig',
      'sodium': 412,
      'category': 'Meals',
      'preparation_note':
          'Reference estimate from a prepared pork sisig with chicken liver. Restaurant and home recipes vary with seasoning and added sauces.',
    },
    {'name': 'Potato Chips', 'sodium': 170, 'category': 'Snacks'},
    {'name': 'French Fries', 'sodium': 260, 'category': 'Snacks'},
    {'name': 'Cheese Crackers', 'sodium': 610, 'category': 'Snacks'},
    {'name': 'Salted Peanuts', 'sodium': 390, 'category': 'Snacks'},
    {'name': 'Popcorn - Salted', 'sodium': 320, 'category': 'Snacks'},
    {'name': 'Banana Cue', 'sodium': 8, 'category': 'Snacks'},
    {'name': 'Turon', 'sodium': 45, 'category': 'Snacks'},
    {'name': 'Pandesal', 'sodium': 390, 'category': 'Snacks'},
    {'name': 'Ensaymada', 'sodium': 280, 'category': 'Snacks'},
    {'name': 'Siopao', 'sodium': 520, 'category': 'Snacks'},
    {'name': 'Banana', 'sodium': 1, 'category': 'Fruits'},
    {'name': 'Apple', 'sodium': 1, 'category': 'Fruits'},
    {'name': 'Orange', 'sodium': 0, 'category': 'Fruits'},
    {'name': 'Mango', 'sodium': 1, 'category': 'Fruits'},
    {'name': 'Pineapple', 'sodium': 1, 'category': 'Fruits'},
    {'name': 'Watermelon', 'sodium': 1, 'category': 'Fruits'},
    {'name': 'Papaya', 'sodium': 8, 'category': 'Fruits'},
    {'name': 'Grapes', 'sodium': 2, 'category': 'Fruits'},
    {'name': 'Guava', 'sodium': 2, 'category': 'Fruits'},
    {'name': 'Dragon Fruit', 'sodium': 0, 'category': 'Fruits'},
    {'name': 'Instant Noodles', 'sodium': 900, 'category': 'Packaged'},
    // Packaged weight and sodium are from the manufacturer's 80 g labels.
    // See FOOD_DATA_SOURCES.md for the flavor-specific product pages.
    {
      'name': 'Lucky Me! Pancit Canton Original (80 g pack)',
      'sodium': 1137.5,
      'default_grams': 80,
      'category': 'Packaged',
      'preparation_note':
          '910 mg sodium per 80 g pack. Use dry pack weight, not cooked weight; check the label if size or formula differs.',
    },
    {
      'name': 'Lucky Me! Pancit Canton Kalamansi (80 g pack)',
      'sodium': 1247.5,
      'default_grams': 80,
      'category': 'Packaged',
      'preparation_note':
          '998 mg sodium per 80 g pack. Use dry pack weight, not cooked weight; check the label if size or formula differs.',
    },
    {
      'name': 'Lucky Me! Pancit Canton Chilimansi (80 g pack)',
      'sodium': 1336.25,
      'default_grams': 80,
      'category': 'Packaged',
      'preparation_note':
          '1,069 mg sodium per 80 g pack. Use dry pack weight, not cooked weight; check the label if size or formula differs.',
    },
    {
      'name': 'Lucky Me! Pancit Canton Sweet & Spicy (80 g pack)',
      'sodium': 1125,
      'default_grams': 80,
      'category': 'Packaged',
      'preparation_note':
          '900 mg sodium per 80 g pack. Use dry pack weight, not cooked weight; check the label if size or formula differs.',
    },
    {
      'name': 'Lucky Me! Pancit Canton Extra Hot Chili (80 g pack)',
      'sodium': 1296.25,
      'default_grams': 80,
      'category': 'Packaged',
      'preparation_note':
          '1,037 mg sodium per 80 g pack. Use dry pack weight, not cooked weight; check the label if size or formula differs.',
    },
    // Flavor-specific reference labels, converted to mg sodium per 100 g.
    // Sources, serving sizes, and calculations: FOOD_DATA_SOURCES.md.
    {
      'name': "Jack 'n Jill Chippy Barbecue",
      'sodium': 733.33,
      'default_grams': 30,
      'category': 'Packaged',
      'preparation_note':
          'Reference label: 220 mg sodium per 30 g. Check your pack if the flavor or formula differs.',
    },
    {
      'name': "Jack 'n Jill Piattos Cheese",
      'sodium': 566.67,
      'default_grams': 30,
      'category': 'Packaged',
      'preparation_note':
          'Reference label: 170 mg sodium per 30 g. Check your pack if the flavor or formula differs.',
    },
    {
      'name': "Jack 'n Jill Nova Country Cheddar",
      'sodium': 200,
      'default_grams': 30,
      'category': 'Packaged',
      'preparation_note':
          'Reference label: 60 mg sodium per 30 g. Check your pack if the flavor or formula differs.',
    },
    {
      'name': "Jack 'n Jill V-Cut Spicy Barbecue",
      'sodium': 533,
      'default_grams': 30,
      'category': 'Packaged',
      'preparation_note':
          'Reference label: 160 mg sodium per 30 g. Check your pack if the flavor or formula differs.',
    },
    {
      'name': "Jack 'n Jill Mang Juan Vinegar & Chili",
      'sodium': 933,
      'default_grams': 30,
      'category': 'Packaged',
      'preparation_note':
          'Reference label: 280 mg sodium per 30 g. Check your pack if the flavor or formula differs.',
    },
    {
      'name': "Jack 'n Jill Chiz Curls Cheese",
      'sodium': 1033.33,
      'default_grams': 30,
      'category': 'Packaged',
      'preparation_note':
          'Reference label: 310 mg sodium per 30 g. Check your pack if the flavor or formula differs.',
    },
    {
      'name': "Jack 'n Jill Cream-O Chocolate",
      'sodium': 383.33,
      'default_grams': 30,
      'category': 'Packaged',
      'preparation_note':
          'Reference label: 115 mg sodium per 30 g. Check your pack if the flavor or formula differs.',
    },
    {
      'name': "Jack 'n Jill Magic Flakes Premium",
      'sodium': 714.29,
      'default_grams': 28,
      'category': 'Packaged',
      'preparation_note':
          'Reference label: 200 mg sodium per 28 g pack. Check your pack if the formula differs.',
    },
    {
      'name': "Jack 'n Jill Presto Creams Peanut Butter",
      'sodium': 333.33,
      'default_grams': 30,
      'category': 'Packaged',
      'preparation_note':
          'Reference label: 100 mg sodium per 30 g. Check your pack if the flavor or formula differs.',
    },
    {
      'name': 'SkyFlakes Crackers Original',
      'sodium': 680,
      'default_grams': 25,
      'category': 'Packaged',
      'preparation_note':
          'Reference label: 170 mg sodium per 25 g. Check your pack if the flavor or formula differs.',
    },
    {
      'name': 'Fita Crackers Original',
      'sodium': 526.67,
      'default_grams': 30,
      'category': 'Packaged',
      'preparation_note':
          'Reference label: 158 mg sodium per 30 g. Check your pack if the formula differs.',
    },
    {
      'name': 'Nissin Butter Coconut',
      'sodium': 242.86,
      'default_grams': 14,
      'category': 'Packaged',
      'preparation_note':
          'Reference label: 34 mg sodium per 14 g. Check your pack if the size or formula differs.',
    },
    {
      'name': 'Rebisco Crackers Plain',
      'sodium': 454.55,
      'default_grams': 33,
      'category': 'Packaged',
      'preparation_note':
          'Reference label: 150 mg sodium per 33 g pack. Check your pack if the formula differs.',
    },
    {
      'name': 'Rebisco Hansel Crackers Plain',
      'sodium': 560,
      'default_grams': 32,
      'category': 'Packaged',
      'preparation_note':
          'Estimated from a reference label of 1.4 g salt per 100 g (about 560 mg sodium). Check your pack if the formula differs.',
    },
    {
      'name': 'Rebisco Fudgee Barr Chocolate',
      'sodium': 500,
      'default_grams': 42,
      'category': 'Packaged',
      'preparation_note':
          'Reference label: 210 mg sodium per 42 g bar. Check your pack if the flavor or formula differs.',
    },
    {
      'name': 'Oishi Prawn Crackers (60 g pack)',
      'sodium': 1166.67,
      'default_grams': 30,
      'category': 'Packaged',
      'preparation_note':
          'Reference label for a 60 g pack: 350 mg sodium per 30 g serving. Check your pack because Oishi prawn crackers have multiple formulas.',
    },
    {
      'name': "Oishi Marty's Cracklin' Plain Salted",
      'sodium': 566.67,
      'default_grams': 30,
      'category': 'Packaged',
      'preparation_note':
          'Reference label: 170 mg sodium per 30 g. Check your pack if the flavor or formula differs.',
    },
    {'name': 'Canned Sardines', 'sodium': 480, 'category': 'Packaged'},
    {'name': 'Corned Beef', 'sodium': 850, 'category': 'Packaged'},
    {'name': 'Hotdog', 'sodium': 900, 'category': 'Packaged'},
    {'name': 'Canned Tuna', 'sodium': 430, 'category': 'Packaged'},
    // Fast-food values are mg per listed item/order, not per 100 g.
    // Estimates and non-PH references are marked in the UI and source notes.
    {
      'name': 'KFC 1-pc Chicken (cut average)',
      'sodium': 810,
      'category': 'Fast Food',
      'sodium_basis': 'per_serving',
      'estimate': true,
      'source_note':
          'Estimate: midpoint of 430 mg (drumstick) and 1,190 mg (breast) in a US KFC nutrition reference. Cut and Philippine recipe may differ. Chicken only; rice and gravy are separate.'
    },
    {
      'name': 'KFC 2-pc Chicken & Rice',
      'sodium': 1884,
      'category': 'Fast Food',
      'sodium_basis': 'per_serving',
      'includes': 'Two pieces of chicken and rice'
    },
    {
      'name': 'KFC Spaghetti',
      'sodium': 903,
      'category': 'Fast Food',
      'sodium_basis': 'per_serving'
    },
    {
      'name': 'KFC Ala King Rice Bowl',
      'sodium': 975,
      'category': 'Fast Food',
      'sodium_basis': 'per_serving'
    },
    {
      'name': 'KFC Sisig Rice Bowl',
      'sodium': 1134,
      'category': 'Fast Food',
      'sodium_basis': 'per_serving'
    },
    {
      'name': 'KFC Original Recipe Snacker',
      'sodium': 333,
      'category': 'Fast Food',
      'sodium_basis': 'per_serving'
    },
    {
      'name': 'KFC Regular Hot Shots',
      'sodium': 420,
      'category': 'Fast Food',
      'sodium_basis': 'per_serving'
    },
    {
      'name': 'KFC Famous Bowl (Snack)',
      'sodium': 822,
      'category': 'Fast Food',
      'sodium_basis': 'per_serving'
    },
    {
      'name': 'KFC Regular Crispy Fries',
      'sodium': 167,
      'category': 'Fast Food',
      'sodium_basis': 'per_serving'
    },
    {
      'name': 'KFC Regular Mashed Potato',
      'sodium': 313,
      'category': 'Fast Food',
      'sodium_basis': 'per_serving'
    },
    {
      'name': 'KFC Regular Gravy',
      'sodium': 359,
      'category': 'Fast Food',
      'sodium_basis': 'per_serving'
    },
    {
      'name': 'KFC 1-pc Fully Loaded Box',
      'sodium': 2043,
      'category': 'Fast Food',
      'sodium_basis': 'per_serving',
      'includes': 'The full boxed meal'
    },
    {
      'name': 'Jollibee 1-pc Chickenjoy (cut average)',
      'sodium': 335,
      'category': 'Fast Food',
      'sodium_basis': 'per_serving',
      'estimate': true,
      'source_note':
          'Reference estimate: average of 270 mg for a drumstick and 400 mg for a thigh in Jollibee USA 2025 nutrition information. Philippine portions may differ. Chicken only; gravy and rice are separate.'
    },
    {
      'name': 'Jollibee Yumburger',
      'sodium': 630,
      'category': 'Fast Food',
      'sodium_basis': 'per_serving',
      'estimate': true,
      'source_note':
          'Reference from Jollibee USA 2025 nutrition information for the Yum burger. Philippine recipe and size may differ.'
    },
    {
      'name': 'Jollibee Jolly Spaghetti',
      'sodium': 1340,
      'category': 'Fast Food',
      'sodium_basis': 'per_serving',
      'estimate': true,
      'source_note':
          'Reference from Jollibee USA 2025 nutrition information for a 411 g order. Philippine portions may differ.'
    },
    {
      'name': 'McDo Chicken McDo (1-pc)',
      'sodium': 700,
      'category': 'Fast Food',
      'sodium_basis': 'per_serving',
      'estimate': true,
      'source_note':
          'Historical Philippine reference from a McDonald\'s nutrition flyer reported as correct in March 2010. Current recipe and serving may differ. Chicken only; check meal sides separately.'
    },
    {
      'name': 'McDo McSpaghetti',
      'sodium': 730,
      'category': 'Fast Food',
      'sodium_basis': 'per_serving',
      'estimate': true,
      'source_note':
          'Historical Philippine reference from a McDonald\'s nutrition flyer reported as correct in March 2010. Current recipe and serving may differ.'
    },
    {
      'name': 'McDo Burger McDo',
      'sodium': 760,
      'category': 'Fast Food',
      'sodium_basis': 'per_serving',
      'estimate': true,
      'source_note':
          'Historical Philippine reference from a McDonald\'s nutrition flyer reported as correct in March 2010. Current recipe and serving may differ.'
    },
  ];

  @override
  void initState() {
    super.initState();
    _addedFoodsFuture = _foodLogService.getPreviouslyLoggedFoods();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredFoods {
    final query = _searchController.text.trim().toLowerCase();

    return _foods.where((food) {
      final matchesCategory = _selectedCategory == 'All'
          ? food['category'] != 'Fast Food'
          : food['category'] == _selectedCategory;

      final name = food['name']?.toString().toLowerCase() ?? '';

      final matchesSearch = query.isEmpty || name.contains(query);

      return matchesCategory && matchesSearch;
    }).toList();
  }

  Future<void> _showFoodDialog(Map<String, dynamic> food) async {
    final sodiumPer100g = (food['sodium'] as num).toDouble();

    final gramsController = TextEditingController(
      text: (food['default_grams'] ?? 100).toString(),
    );

    bool saving = false;
    String? dialogError;

    final added = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final grams = double.tryParse(gramsController.text.trim());

            final totalSodium = grams != null && grams > 0
                ? (sodiumPer100g * grams / 100).round()
                : null;

            return AlertDialog(
              title: Text(food['name'].toString()),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTrafficLight(sodiumPer100g),
                    const SizedBox(height: 18),
                    _buildValueRow(
                      context,
                      label: 'Sodium per 100 g',
                      value: '${sodiumPer100g.round()} mg',
                    ),
                    const SizedBox(height: 16),
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
                        setDialogState(() {
                          dialogError = null;
                        });
                      },
                      decoration: const InputDecoration(
                        labelText: 'Amount Consumed',
                        suffixText: 'g',
                        prefixIcon: Icon(Icons.scale_outlined),
                        helperText: 'Enter the approximate weight you ate.',
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTotalSodiumBox(context, totalSodium),
                    if (dialogError != null) ...[
                      const SizedBox(height: 12),
                      _buildDialogError(context, dialogError!),
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

                          Navigator.of(dialogContext).pop(false);
                        },
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: saving
                      ? null
                      : () async {
                          final grams = double.tryParse(
                            gramsController.text.trim(),
                          );

                          if (grams == null || grams <= 0) {
                            setDialogState(() {
                              dialogError = 'Enter a valid amount consumed.';
                            });
                            return;
                          }

                          final total = (sodiumPer100g * grams / 100).round();

                          setDialogState(() {
                            saving = true;
                            dialogError = null;
                          });

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

                            Navigator.of(dialogContext).pop(true);
                          } catch (_) {
                            if (!dialogContext.mounted) {
                              return;
                            }

                            setDialogState(() {
                              saving = false;
                              dialogError =
                                  'Could not add this food. Please try again.';
                            });
                          }
                        },
                  child: saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Add to Log'),
                ),
              ],
            );
          },
        );
      },
    );

    await Future<void>.delayed(const Duration(milliseconds: 350));

    gramsController.dispose();

    if (!mounted) {
      return;
    }

    if (added == true) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _showFastFoodDialog(Map<String, dynamic> food) async {
    final sodiumPerOrder = (food['sodium'] as num).toInt();
    final ordersController = TextEditingController(text: '1');
    bool saving = false;
    String? dialogError;

    final added = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final orders = double.tryParse(ordersController.text.trim());
          final total =
              orders != null && orders.isFinite && orders > 0 && orders <= 20
                  ? (sodiumPerOrder * orders).round()
                  : null;
          return AlertDialog(
            title: Text(food['name'].toString()),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildValueRow(context,
                      label: 'Sodium per order', value: '$sodiumPerOrder mg'),
                  const SizedBox(height: 12),
                  Text(food['source_note']?.toString() ??
                      (food['category'] == 'Your Added Food'
                          ? 'This is the value from your previous food log. Serving size and sodium may differ from what you eat now.'
                          : 'Based on published restaurant nutrition information. Portions may vary.')),
                  if (food['includes'] != null) ...[
                    const SizedBox(height: 8),
                    Text('Includes: ${food['includes']}.'),
                  ],
                  const SizedBox(height: 16),
                  TextField(
                    controller: ordersController,
                    enabled: !saving,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setDialogState(() => dialogError = null),
                    decoration: InputDecoration(
                      labelText: food['category'] == 'Your Added Food'
                          ? 'Servings Consumed'
                          : 'Orders Consumed',
                      prefixIcon: const Icon(Icons.numbers_rounded),
                      helperText: food['category'] == 'Your Added Food'
                          ? 'Use 0.5 if you had half a serving.'
                          : 'Use 0.5 if you ate half an order.',
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                      'Add sides, sauces, and drinks separately unless the order already includes them.'),
                  const SizedBox(height: 16),
                  _buildTotalSodiumBox(context, total),
                  if (dialogError != null) ...[
                    const SizedBox(height: 12),
                    _buildDialogError(context, dialogError!),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: saving
                    ? null
                    : () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: saving
                    ? null
                    : () async {
                        final orders =
                            double.tryParse(ordersController.text.trim());
                        if (orders == null ||
                            !orders.isFinite ||
                            orders <= 0 ||
                            orders > 20) {
                          setDialogState(() => dialogError =
                              'Enter an amount greater than 0 and no more than 20 orders.');
                          return;
                        }
                        setDialogState(() {
                          saving = true;
                          dialogError = null;
                        });
                        try {
                          await _foodLogService.addFoodLog(
                            requestId: _foodLogService.createRequestId(),
                            foodName: food['name'].toString(),
                            sodiumAmount: (sodiumPerOrder * orders).round(),
                            logDate: _foodLogService.philippineNow,
                            entryType: 'searched',
                            servings: orders,
                            sodiumPerServingMg: sodiumPerOrder,
                            sodiumBasis: 'per_serving',
                          );
                          if (dialogContext.mounted) {
                            Navigator.of(dialogContext).pop(true);
                          }
                        } catch (_) {
                          if (dialogContext.mounted) {
                            setDialogState(() {
                              saving = false;
                              dialogError =
                                  'Could not add this food. Please try again.';
                            });
                          }
                        }
                      },
                child: saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Add to Log'),
              ),
            ],
          );
        },
      ),
    );

    await Future<void>.delayed(const Duration(milliseconds: 350));
    ordersController.dispose();
    if (mounted && added == true) {
      Navigator.pop(context, true);
    }
  }

  Widget _buildTrafficLight(double sodiumPer100g) {
    final color = SodiumRating.colorFor(sodiumPer100g);

    final label = SodiumRating.labelFor(sodiumPer100g);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(SodiumRating.iconFor(sodiumPer100g), color: color, size: 24),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: color, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  '${sodiumPer100g.round()} mg per 100 g',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: color),
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
        Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
        const SizedBox(width: 12),
        Text(value, style: theme.textTheme.titleMedium),
      ],
    );
  }

  Widget _buildTotalSodiumBox(BuildContext context, int? total) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Total Sodium',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            total == null ? '-- mg' : '$total mg',
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogError(BuildContext context, String message) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: colors.onErrorContainer),
          const SizedBox(width: 10),
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
  Widget build(BuildContext context) {
    final foods = _filteredFoods;
    final query = _searchController.text.trim().toLowerCase();
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Add Food')),
      body: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 30),
        children: [
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: _selectedCategory == 'Your Added Food'
                  ? 'Search your added foods'
                  : 'Search foods',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      onPressed: _clearSearch,
                      icon: const Icon(Icons.close_rounded),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _categories
                  .map((category) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(category),
                          selected: _selectedCategory == category,
                          onSelected: (_) =>
                              setState(() => _selectedCategory = category),
                        ),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 20),
          if (_selectedCategory == 'Your Added Food')
            _buildAddedFoodSection(query)
          else ...[
            Row(children: [
              Expanded(
                  child: Text(
                      _selectedCategory == 'Fast Food'
                          ? 'Fast Food'
                          : 'Common Foods',
                      style: theme.textTheme.titleLarge)),
              Text('${foods.length}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 5),
            Text(
                _selectedCategory == 'Fast Food'
                    ? 'Values are per order. Estimates from other countries or older sources are marked.'
                    : 'Values are per 100 g. Prepared foods may vary by recipe.',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: colors.onSurfaceVariant)),
            const SizedBox(height: 12),
            if (foods.isEmpty)
              _buildEmptyState()
            else
              ...foods.map(_buildFoodCard),
          ],
        ],
      ),
    );
  }

  Widget _buildAddedFoodSection(String query) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _addedFoodsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          return Card(
              child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(children: [
              const Text('Could not load your added foods.'),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => setState(() {
                  _addedFoodsFuture =
                      _foodLogService.getPreviouslyLoggedFoods();
                }),
                child: const Text('Try Again'),
              ),
            ]),
          ));
        }
        final foods = (snapshot.data ?? [])
            .where(
                (food) => food['name'].toString().toLowerCase().contains(query))
            .toList();
        if (foods.isEmpty) {
          return Card(
              child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
                query.isEmpty
                    ? 'Foods you log will appear here so you can add them again.'
                    : 'No matching added foods.',
                textAlign: TextAlign.center),
          ));
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Your Added Food', style: theme.textTheme.titleLarge),
            const SizedBox(height: 5),
            Text('Foods from your previous logs. Tap one to add it again.',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: colors.onSurfaceVariant)),
            const SizedBox(height: 12),
            ...foods.map(_buildFoodCard),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);

    final colors = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 38, horizontal: 24),
        child: Column(
          children: [
            Icon(Icons.search_off_rounded, size: 50, color: colors.outline),
            const SizedBox(height: 12),
            Text(
              'No matching foods',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 5),
            Text(
              'Try another search or choose a different category.',
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

  Widget _buildFoodCard(Map<String, dynamic> food) {
    final sodium = (food['sodium'] as num).toDouble();
    final perServing = food['sodium_basis'] == 'per_serving';
    final estimate = food['estimate'] == true;

    final color = perServing
        ? Theme.of(context).colorScheme.onSurfaceVariant
        : SodiumRating.colorFor(sodium);

    final label = estimate
        ? 'Estimate'
        : perServing
            ? 'Per order'
            : SodiumRating.labelFor(sodium);

    final theme = Theme.of(context);

    final colors = theme.colorScheme;

    final textScale = MediaQuery.of(context).textScaler.scale(1.0);

    final largeText = textScale >= 1.25;

    return Card(
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.05),
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          if (perServing) {
            _showFastFoodDialog(food);
          } else {
            _showFoodDialog(food);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(
                      perServing
                          ? Icons.restaurant_rounded
                          : SodiumRating.iconFor(sodium),
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 12),
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
                        const SizedBox(height: 3),
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
                            Text('•', style: theme.textTheme.bodySmall),
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
                    const SizedBox(width: 10),
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
                          perServing ? 'per order' : 'per 100 g',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: colors.onSurfaceVariant,
                    ),
                  ],
                ],
              ),
              if (largeText) ...[
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.only(left: 60),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${sodium.round()} mg ${perServing ? 'per order' : 'per 100 g'}',
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
