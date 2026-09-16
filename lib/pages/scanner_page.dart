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
              margin: EdgeInsets.symmetric(
                horizontal: 40,
              ),
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
                      'Checking product...',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
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
        'Could not retrieve this product. Check your connection or enter it manually.',
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

    final code = await showDialog<String>(
      context: context,
      builder: (
        dialogContext,
      ) {
        String? errorMessage;

        return StatefulBuilder(
          builder: (
            context,
            setDialogState,
          ) {
            return AlertDialog(
              title: const Text(
                'Type Barcode',
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Enter the numbers printed below the barcode.',
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  TextField(
                    controller: _manualBarcodeController,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    onChanged: (_) {
                      if (errorMessage != null) {
                        setDialogState(
                          () {
                            errorMessage = null;
                          },
                        );
                      }
                    },
                    onSubmitted: (_) {
                      final value = _manualBarcodeController.text.trim();

                      if (!_isValidBarcode(
                        value,
                      )) {
                        setDialogState(
                          () {
                            errorMessage = 'Enter a valid numeric barcode.';
                          },
                        );
                        return;
                      }

                      FocusManager.instance.primaryFocus?.unfocus();

                      Navigator.of(
                        dialogContext,
                      ).pop(
                        value,
                      );
                    },
                    decoration: const InputDecoration(
                      labelText: 'Barcode',
                      hintText: 'Example: 3017620422003',
                      prefixIcon: Icon(
                        Icons.qr_code_2_rounded,
                      ),
                    ),
                  ),
                  if (errorMessage != null) ...[
                    const SizedBox(
                      height: 12,
                    ),
                    Text(
                      errorMessage!,
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    FocusManager.instance.primaryFocus?.unfocus();

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
                    final value = _manualBarcodeController.text.trim();

                    if (!_isValidBarcode(
                      value,
                    )) {
                      setDialogState(
                        () {
                          errorMessage = 'Enter a valid numeric barcode.';
                        },
                      );
                      return;
                    }

                    FocusManager.instance.primaryFocus?.unfocus();

                    Navigator.of(
                      dialogContext,
                    ).pop(
                      value,
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
      },
    );

    if (code != null && mounted) {
      await _processBarcode(
        code,
      );
    }
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

    String? dialogError;

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
                    Text(
                      'Barcode $barcode was not found.',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium,
                    ),
                    const SizedBox(
                      height: 6,
                    ),
                    Text(
                      'You can enter the sodium information from the package.',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(
                      height: 18,
                    ),
                    TextField(
                      controller: nameController,
                      textInputAction: TextInputAction.next,
                      onChanged: (_) {
                        setDialogState(
                          () {
                            dialogError = null;
                          },
                        );
                      },
                      decoration: const InputDecoration(
                        labelText: 'Product Name',
                        prefixIcon: Icon(
                          Icons.inventory_2_outlined,
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 14,
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: selectedBasis,
                      decoration: const InputDecoration(
                        labelText: 'Nutrition Label Basis',
                        prefixIcon: Icon(
                          Icons.description_outlined,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'per_100g',
                          child: Text(
                            'Per 100 g',
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'per_serving',
                          child: Text(
                            'Per Serving',
                          ),
                        ),
                      ],
                      onChanged: (
                        value,
                      ) {
                        if (value == null) {
                          return;
                        }

                        setDialogState(
                          () {
                            selectedBasis = value;
                            dialogError = null;
                          },
                        );
                      },
                    ),
                    const SizedBox(
                      height: 14,
                    ),
                    TextField(
                      controller: sodiumController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: false,
                      ),
                      textInputAction: selectedBasis == 'per_serving'
                          ? TextInputAction.next
                          : TextInputAction.done,
                      onChanged: (_) {
                        setDialogState(
                          () {
                            dialogError = null;
                          },
                        );
                      },
                      decoration: InputDecoration(
                        labelText: selectedBasis == 'per_100g'
                            ? 'Sodium per 100 g'
                            : 'Sodium per Serving',
                        suffixText: 'mg',
                        prefixIcon: const Icon(
                          Icons.water_drop_outlined,
                        ),
                      ),
                    ),
                    if (selectedBasis == 'per_serving') ...[
                      const SizedBox(
                        height: 14,
                      ),
                      TextField(
                        controller: servingSizeController,
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          labelText: 'Serving Size',
                          hintText: 'Example: 1 pack or 30 g',
                          prefixIcon: Icon(
                            Icons.straighten_outlined,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(
                      height: 14,
                    ),
                    Container(
                      padding: const EdgeInsets.all(
                        12,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(
                          12,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 21,
                            color: Theme.of(
                              context,
                            ).colorScheme.primary,
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          Expanded(
                            child: Text(
                              selectedBasis == 'per_100g'
                                  ? 'Per-100 g values can receive a Low, Moderate, or High Sodium rating.'
                                  : 'Per-serving values can be logged, but will not receive a traffic-light rating.',
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (dialogError != null) ...[
                      const SizedBox(
                        height: 12,
                      ),
                      Text(
                        dialogError!,
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    FocusManager.instance.primaryFocus?.unfocus();

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
                      setDialogState(
                        () {
                          dialogError = 'Enter a product name.';
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

                    FocusManager.instance.primaryFocus?.unfocus();

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
          content: Text(
            message,
          ),
        ),
      );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Scan Food',
        ),
        backgroundColor: colors.surface,
        actions: [
          IconButton(
            tooltip: 'Type Barcode',
            onPressed: _isProcessing ? null : _showManualEntryDialog,
            icon: const Icon(
              Icons.keyboard_alt_outlined,
            ),
          ),
          ValueListenableBuilder(
            valueListenable: _controller,
            builder: (
              context,
              state,
              child,
            ) {
              final torchOn = state.torchState == TorchState.on;

              return IconButton(
                tooltip: torchOn ? 'Turn Flashlight Off' : 'Turn Flashlight On',
                onPressed: () {
                  _controller.toggleTorch();
                },
                icon: Icon(
                  torchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                ),
              );
            },
          ),
          const SizedBox(
            width: 4,
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
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
                width: 280,
                height: 180,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.white,
                    width: 3,
                  ),
                  borderRadius: BorderRadius.circular(
                    18,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: 0.30,
                      ),
                      blurRadius: 12,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 18,
            child: SafeArea(
              top: false,
              child: Card(
                elevation: 4,
                shadowColor: Colors.black.withValues(
                  alpha: 0.18,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(
                    16,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: colors.primaryContainer,
                              borderRadius: BorderRadius.circular(
                                12,
                              ),
                            ),
                            child: Icon(
                              Icons.qr_code_scanner_rounded,
                              color: colors.onPrimaryContainer,
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
                                  'Scan the barcode',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                const SizedBox(
                                  height: 3,
                                ),
                                Text(
                                  'Place the barcode inside the frame.',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 14,
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed:
                              _isProcessing ? null : _showManualEntryDialog,
                          icon: const Icon(
                            Icons.keyboard_alt_outlined,
                          ),
                          label: const Text(
                            'Type Barcode Instead',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_isProcessing)
            Positioned(
              top: 18,
              left: 18,
              right: 18,
              child: SafeArea(
                bottom: false,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(
                        999,
                      ),
                    ),
                    child: const Text(
                      'Barcode detected',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
