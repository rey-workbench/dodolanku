import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dodolanku/features/scanner/repositories/product_repository.dart';
import 'package:dodolanku/core/models/product_model.dart';

import 'package:dodolanku/features/dashboard/providers/dashboard_provider.dart';
import 'package:dodolanku/core/utils/currency_formatter.dart';
import 'package:dodolanku/core/widgets/app_widgets.dart';

class StockOpnamePage extends ConsumerStatefulWidget {
  const StockOpnamePage({super.key});

  @override
  ConsumerState<StockOpnamePage> createState() => _StockOpnamePageState();
}

class _StockOpnamePageState extends ConsumerState<StockOpnamePage> {
  final TextEditingController _manualController = TextEditingController();
  bool _isScanning = true;
  final List<Map<String, dynamic>> _sessionHistory = [];

  @override
  void dispose() {
    _manualController.dispose();
    super.dispose();
  }

  void _addNewNonBarcode() async {
    final productRepo = ref.read(productRepositoryProvider);
    final autoCode = await productRepo.getNextNonBarcodeCode();
    _processBarcode(autoCode);
  }

  void _submitManual() async {
    final barcode = _manualController.text.trim();
    if (barcode.isEmpty) return;
    _manualController.clear();
    FocusScope.of(context).unfocus();
    _processBarcode(barcode);
  }

  void _processBarcode(String barcode) async {
    setState(() => _isScanning = false);

    final productRepo = ref.read(productRepositoryProvider);
    final product = await productRepo.getProductDetails(barcode);

    if (!mounted) return;

    await showProductFormModal(
      context: context,
      initialBarcode: barcode,
      initialName: product?.name,
      initialPrice: product?.price,
      initialStock: product?.stock,
      onSave: ({
        required String barcode,
        required String name,
        required double price,
        required int stock,
      }) async {
        await productRepo.insertProduct(Product(barcode: barcode, name: name, price: price, stock: stock));
        ref.invalidate(dashboardProvider);

        setState(() {
          _sessionHistory.insert(0, {
            'barcode': barcode,
            'name': name,
            'price': price,
            'stock': stock,
            'time': DateTime.now().toString().substring(11, 16),
            'is_new': product == null,
          });
        });

        if (mounted) {
          AppToast.show(
            context,
            message: 'Berhasil menyimpan: $name (Stok: $stock)',
            bottomMargin: 24,
          );
        }
      },
    );

    if (mounted) {
      setState(() => _isScanning = true);
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Stock Opname Scanner'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            AppBarcodeScanner(
              isScanning: _isScanning,
              onScan: (barcode) {
                _processBarcode(barcode);
              },
            ),

            // Manual Barcode Input & Add Non-Barcode
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _manualController,
                      decoration: InputDecoration(
                        hintText: 'Ketik barcode barang...',
                        prefixIcon: const Icon(Icons.keyboard, size: 20),
                        fillColor: Colors.white,
                        filled: true,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      keyboardType: TextInputType.text,
                      onSubmitted: (_) => _submitManual(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FloatingActionButton.small(
                    onPressed: _submitManual,
                    elevation: 0,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    tooltip: 'Cari/Scan Kode',
                    child: const Icon(Icons.send_rounded),
                  ),
                  const SizedBox(width: 6),
                  Material(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _addNewNonBarcode,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        child: Icon(
                          Icons.add_box_rounded,
                          color: Theme.of(context).colorScheme.onSecondaryContainer,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // History Header
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(Icons.history, size: 18, color: Colors.grey),
                  SizedBox(width: 6),
                  Text(
                    'Riwayat Input Sesi Ini',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // History List
            Expanded(
              child: _sessionHistory.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey[300]),
                          const SizedBox(height: 12),
                          Text('Belum ada produk di-input', style: TextStyle(color: Colors.grey[400])),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: _sessionHistory.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = _sessionHistory[index];
                        final name = item['name'] as String;
                        final price = item['price'] as double;
                        final stock = item['stock'] as int;
                        final time = item['time'] as String;
                        final isNew = item['is_new'] as bool;

                        return RepaintBoundary(
                          child: AppCard(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            child: Row(
                              children: [
                                AppIconAvatar(
                                  icon: isNew ? Icons.add_business_outlined : Icons.inventory_2_outlined,
                                  radius: 18,
                                  backgroundColor: isNew ? Colors.green[50] : null,
                                  iconColor: isNew ? Colors.green : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Text('Rp ${formatRupiah(price)}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                          const SizedBox(width: 8),
                                          AppStatusBadge(
                                            label: '$stock pcs',
                                            color: Theme.of(context).colorScheme.primary,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Text(time, style: TextStyle(color: Colors.grey[400], fontSize: 11)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

