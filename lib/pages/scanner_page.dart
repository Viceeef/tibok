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

  void _processBarcode(String rawCode) async {
    if (_isProcessing || rawCode.isEmpty) return;

    setState(() => _isProcessing = true);
    _controller.stop();

    // Show loading indicator dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Fetching product sodium data...'),
              ],
            ),
          ),
        ),
      ),
    );

    final product = await FoodApiService.fetchProductByBarcode(rawCode);

    if (mounted) {
      Navigator.pop(context); // Close loading dialog

      if (product != null) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductResultPage(product: product),
          ),
        );
      } else {
        // Show custom entry fallback if not found in database or API
        _showAddCustomProductDialog(rawCode);
      }
    }

    _isProcessing = false;
    _controller.start();
  }

  void _showManualEntryDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Enter Barcode Manually'),
        content: TextField(
          controller: _manualBarcodeController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: 'e.g. 3017620422003',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final code = _manualBarcodeController.text.trim();
              Navigator.pop(dialogContext);
              if (code.isNotEmpty) {
                _processBarcode(code);
              }
            },
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  void _showAddCustomProductDialog(String barcode) {
    final nameController = TextEditingController();
    final sodiumController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Product Not Found'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'This item isn\'t in the global database yet. Add its details to log it and save it for future scans!',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
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
                  labelText: 'Sodium per Serving (mg)',
                  border: OutlineInputBorder(),
                  suffixText: 'mg',
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
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final sodium = int.tryParse(sodiumController.text.trim()) ?? 0;

              if (name.isNotEmpty) {
                Navigator.pop(dialogContext);

                // Determine DASH rating locally
                SodiumRating rating = SodiumRating.green;
                if (sodium > 400) {
                  rating = SodiumRating.red;
                } else if (sodium > 140) {
                  rating = SodiumRating.amber;
                }

                final customProduct = ScannedProduct(
                  barcode: barcode,
                  name: name,
                  sodiumMg: sodium,
                  servingSize: '1 serving',
                  ingredientsText: 'User-generated entry',
                  hasHiddenSodium: false,
                  detectedHiddenIngredients: [],
                  rating: rating,
                );

                if (mounted) {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProductResultPage(product: customProduct),
                    ),
                  );
                }
              }
            },
            child: const Text('Save & View'),
          ),
        ],
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
            onPressed: _showManualEntryDialog,
          ),
          IconButton(
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
              if (capture.barcodes.isNotEmpty) {
                final code = capture.barcodes.first.rawValue;
                if (code != null) _processBarcode(code);
              }
            },
          ),
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.redAccent, width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Column(
              children: [
                const Text(
                  'Align barcode within frame',
                  style: TextStyle(
                    color: Colors.white,
                    backgroundColor: Colors.black54,
                  ),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _showManualEntryDialog,
                  icon: const Icon(Icons.edit, color: Colors.white),
                  label: const Text(
                    'Type Barcode Manually',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: TextButton.styleFrom(backgroundColor: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
