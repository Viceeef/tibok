import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../services/food_api_service.dart';
import 'product_result_page.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({
    super.key,
  });

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

  bool _isValidBarcode(
    String value,
  ) {
    final code = value.trim();

    if (code.isEmpty) {
      return false;
    }

    return RegExp(
      r'^\d{6,18}$',
    ).hasMatch(code);
  }

  Future<void> _processBarcode(
    String rawCode,
  ) async {
    final code = rawCode.trim();

    if (_isProcessing) {
      return;
    }

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

    if (!mounted) {
      return;
    }

    var loadingDialogOpen = true;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return const PopScope(
          canPop: false,
          child: Center(
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(
                  24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(
                      height: 16,
                    ),
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
      final product = await FoodApiService.fetchProductByBarcode(
        code,
      );

      if (!mounted) {
        return;
      }

      if (loadingDialogOpen) {
        Navigator.of(
          context,
          rootNavigator: true,
        ).pop();

        loadingDialogOpen = false;
      }

      if (product != null) {
        final wasLogged = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => ProductResultPage(
              product: product,
            ),
          ),
        );

        if (!mounted) {
          return;
        }

        if (wasLogged == true) {
          Navigator.pop(
            context,
            true,
          );
          return;
        }
      } else {
        final customProduct = await _showAddCustomProductDialog(
          code,
        );

        if (!mounted) {
          return;
        }

        if (customProduct != null) {
          final wasLogged = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => ProductResultPage(
                product: customProduct,
              ),
            ),
          );

          if (!mounted) {
            return;
          }

          if (wasLogged == true) {
            Navigator.pop(
              context,
              true,
            );
            return;
          }
        }
      }
    } catch (_) {
      if (!mounted) {
        return;
      }

      if (loadingDialogOpen) {
        Navigator.of(
          context,
          rootNavigator: true,
        ).pop();

        loadingDialogOpen = false;
      }

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
      builder: (
        dialogContext,
      ) {
        return AlertDialog(
          title: const Text(
            'Enter Barcode Manually',
          ),
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
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop();
              },
              child: const Text(
                'Cancel',
              ),
            ),
            FilledButton(
              onPressed: () {
                final code = _manualBarcodeController.text.trim();

                if (!_isValidBarcode(
                  code,
                )) {
                  _showMessage(
                    'Please enter a valid numeric barcode.',
                  );
                  return;
                }

                Navigator.of(
                  dialogContext,
                ).pop();

                _processBarcode(
                  code,
                );
              },
              child: const Text(
                'Search',
              ),
            ),
          ],
        );
      },
    );
  }

  Future<ScannedProduct?> _showAddCustomProductDialog(
    String barcode,
  ) async {
    final nameController = TextEditingController();

    final sodiumController = TextEditingController();

    final servingSizeController = TextEditingController(
      text: '1 serving',
    );

    var selectedBasis = 'per_100g';

    final product = await showDialog<ScannedProduct>(
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
            return AlertDialog(
              title: const Text(
                'Product Not Found',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'This barcode was not found. '
                      'You can enter the nutrition information from the product label.',
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    TextField(
                      controller: nameController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Food / Product Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(
                      height: 14,
                    ),
                    const Text(
                      'Nutrition label basis',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'per_100g',
                          label: Text(
                            'Per 100 g',
                          ),
                        ),
                        ButtonSegment(
                          value: 'per_serving',
                          label: Text(
                            'Per Serving',
                          ),
                        ),
                      ],
                      selected: {
                        selectedBasis,
                      },
                      onSelectionChanged: (selection) {
                        setDialogState(
                          () {
                            selectedBasis = selection.first;
                          },
                        );
                      },
                    ),
                    const SizedBox(
                      height: 14,
                    ),
                    TextField(
                      controller: sodiumController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: selectedBasis == 'per_100g'
                            ? 'Sodium per 100 g'
                            : 'Sodium per Serving',
                        border: const OutlineInputBorder(),
                        suffixText: 'mg',
                      ),
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    if (selectedBasis == 'per_serving')
                      TextField(
                        controller: servingSizeController,
                        decoration: const InputDecoration(
                          labelText: 'Serving Size',
                          hintText: 'e.g. 30 g, 1 pack, 110 mL',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    const SizedBox(
                      height: 10,
                    ),
                    Text(
                      selectedBasis == 'per_100g'
                          ? 'Tibok can calculate a traffic-light rating because this value is per 100 g.'
                          : 'Serving-based sodium can be logged, but Tibok will not assign a traffic-light rating without a per-100 g value.',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(
                      dialogContext,
                    ).pop();
                  },
                  child: const Text(
                    'Cancel',
                  ),
                ),
                FilledButton(
                  onPressed: () {
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

                    final servingSize = servingSizeController.text.trim();

                    final customProduct = ScannedProduct(
                      barcode: barcode,
                      name: name,
                      sodiumPer100gMg:
                          selectedBasis == 'per_100g' ? sodium : null,
                      sodiumPerServingMg:
                          selectedBasis == 'per_serving' ? sodium : null,
                      servingSize: selectedBasis == 'per_serving' &&
                              servingSize.isNotEmpty
                          ? servingSize
                          : selectedBasis == 'per_100g'
                              ? '100 g'
                              : '1 serving',
                      ingredientsText: 'Manually entered product',
                      hasHiddenSodium: false,
                      detectedHiddenIngredients: const [],
                    );

                    Navigator.of(
                      dialogContext,
                    ).pop(
                      customProduct,
                    );
                  },
                  child: const Text(
                    'Continue',
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
    servingSizeController.dispose();

    return product;
  }

  void _showMessage(
    String message,
  ) {
    if (!mounted) {
      return;
    }

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
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Scan Food Barcode',
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.keyboard,
            ),
            tooltip: 'Type Barcode',
            onPressed: _isProcessing ? null : _showManualEntryDialog,
          ),
          IconButton(
            tooltip: 'Flashlight',
            icon: ValueListenableBuilder(
              valueListenable: _controller,
              builder: (
                context,
                state,
                child,
              ) {
                return Icon(
                  state.torchState == TorchState.on
                      ? Icons.flash_on
                      : Icons.flash_off,
                );
              },
            ),
            onPressed: () {
              _controller.toggleTorch();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (
              capture,
            ) {
              if (_isProcessing || capture.barcodes.isEmpty) {
                return;
              }

              final code = capture.barcodes.first.rawValue;

              if (code != null) {
                _processBarcode(
                  code,
                );
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
                      borderRadius: BorderRadius.circular(
                        12,
                      ),
                    ),
                    child: const Text(
                      'Align the barcode inside the frame',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 12,
                  ),
                  FilledButton.icon(
                    onPressed: _isProcessing ? null : _showManualEntryDialog,
                    icon: const Icon(
                      Icons.keyboard,
                    ),
                    label: const Text(
                      'Type Barcode',
                    ),
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
