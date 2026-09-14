import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../services/food_api_service.dart';
import 'product_result_page.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  final MobileScannerController _controller = MobileScannerController();

  final TextEditingController _manualBarcodeController =
      TextEditingController();

  bool _isProcessing = false;

  @override
  void dispose() {
    _controller.dispose();
    _manualBarcodeController.dispose();
    super.dispose();
  }

  bool _isValidBarcode(String value) {
    final code = value.trim();

    if (code.isEmpty) return false;

    return RegExp(r'^\d{6,18}$').hasMatch(code);
  }

  Future<void> _processBarcode(String rawCode) async {
    final code = rawCode.trim();

    if (_isProcessing) return;

    if (!_isValidBarcode(code)) {
      _showMessage(
        'Please enter a valid numeric barcode.',
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    await _controller.stop();

    if (!mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return const PopScope(
          canPop: false,
          child: Center(
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Fetching product information...',
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    try {
      final product = await FoodApiService.fetchProductByBarcode(code);

      if (!mounted) return;

      Navigator.of(context, rootNavigator: true).pop();

      if (product != null) {
        final wasLogged = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => ProductResultPage(
              product: product,
            ),
          ),
        );

        if (!mounted) return;

        if (wasLogged == true) {
          Navigator.pop(context, true);
          return;
        }
      } else {
        await _showAddCustomProductDialog(code);
      }
    } catch (e) {
      if (!mounted) return;

      Navigator.of(context, rootNavigator: true).pop();

      _showMessage(
        'Could not retrieve this product. '
        'Check your internet connection or try manual entry.',
      );
    } finally {
      _isProcessing = false;

      if (mounted && ModalRoute.of(context)?.isCurrent == true) {
        await _controller.start();
      }
    }
  }

  Future<void> _showManualEntryDialog() async {
    _manualBarcodeController.clear();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Enter Barcode Manually'),
          content: TextField(
            controller: _manualBarcodeController,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: 'e.g. 3017620422003',
              labelText: 'Barcode',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final code = _manualBarcodeController.text.trim();

                if (!_isValidBarcode(code)) {
                  _showMessage(
                    'Please enter a valid numeric barcode.',
                  );
                  return;
                }

                Navigator.pop(dialogContext);

                _processBarcode(code);
              },
              child: const Text('Search'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAddCustomProductDialog(
    String barcode,
  ) async {
    final nameController = TextEditingController();
    final sodiumController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Product Not Found'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'This barcode was not found. '
                  'You can enter the product information manually.',
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Food / Product Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: sodiumController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Sodium per Serving',
                    border: OutlineInputBorder(),
                    suffixText: 'mg',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter sodium from the nutrition label. '
                  'Do not leave it blank if the amount is unknown.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final name = nameController.text.trim();

                final sodium = int.tryParse(
                  sodiumController.text.trim(),
                );

                if (name.isEmpty) {
                  _showMessage(
                    'Please enter a product name.',
                  );
                  return;
                }

                if (sodium == null || sodium < 0) {
                  _showMessage(
                    'Please enter a valid sodium amount.',
                  );
                  return;
                }

                Navigator.pop(dialogContext);

                final rating = _getSodiumRating(sodium);

                final customProduct = ScannedProduct(
                  barcode: barcode,
                  name: name,
                  sodiumMg: sodium,
                  servingSize: '1 serving',
                  ingredientsText: 'Manually entered product',
                  hasHiddenSodium: false,
                  detectedHiddenIngredients: const [],
                  rating: rating,
                );

                if (!mounted) return;

                final wasLogged = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProductResultPage(
                      product: customProduct,
                    ),
                  ),
                );

                if (!mounted) return;

                if (wasLogged == true) {
                  Navigator.pop(context, true);
                }
              },
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );

    nameController.dispose();
    sodiumController.dispose();
  }

  SodiumRating _getSodiumRating(int sodiumMg) {
    if (sodiumMg > 400) {
      return SodiumRating.red;
    }

    if (sodiumMg > 140) {
      return SodiumRating.amber;
    }

    return SodiumRating.green;
  }

  void _showMessage(String message) {
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Food Barcode'),
        actions: [
          IconButton(
            icon: const Icon(Icons.keyboard),
            tooltip: 'Type Barcode',
            onPressed: _isProcessing ? null : _showManualEntryDialog,
          ),
          IconButton(
            tooltip: 'Flashlight',
            icon: ValueListenableBuilder(
              valueListenable: _controller,
              builder: (context, state, child) {
                return Icon(
                  state.torchState == TorchState.on
                      ? Icons.flash_on
                      : Icons.flash_off,
                );
              },
            ),
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              if (_isProcessing || capture.barcodes.isEmpty) {
                return;
              }

              final code = capture.barcodes.first.rawValue;

              if (code != null) {
                _processBarcode(code);
              }
            },
          ),
          IgnorePointer(
            child: Center(
              child: Container(
                width: 260,
                height: 180,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.redAccent,
                    width: 3,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: SafeArea(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Align the barcode inside the frame',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _isProcessing ? null : _showManualEntryDialog,
                    icon: const Icon(Icons.keyboard),
                    label: const Text('Type Barcode'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
