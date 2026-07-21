import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dodolanku/features/scanner/providers/scanner_provider.dart';
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

  void _submitManual() async {
    final barcode = _manualController.text.trim();
    if (barcode.isEmpty) return;
    _manualController.clear();
    FocusScope.of(context).unfocus();
    _processBarcode(barcode);
  }

  void _processBarcode(String barcode) async {
    setState(() => _isScanning = false);

    final db = ref.read(databaseServiceProvider);
    final product = await db.getProductDetails(barcode);

    final nameController = TextEditingController(text: product?['name'] as String? ?? '');
    final barcodeController = TextEditingController(text: barcode);
    final priceController = TextEditingController(
      text: product != null ? (product['price'] as num).toStringAsFixed(0) : '',
    );
    final stockController = TextEditingController(
      text: product != null ? (product['stock'] as num).toString() : '',
    );
    final formKey = GlobalKey<FormState>();

    if (!mounted) return;

    showAppFormModal(
      context: context,
      title: product != null ? 'Update Stok & Harga' : 'Tambah Produk Baru',
      subtitle: product != null
          ? 'Barcode terdaftar. Edit detail barang di bawah.'
          : 'Barcode belum terdaftar. Isi detail barang baru.',
      formKey: formKey,
      fields: [
        AppFormField(
          controller: barcodeController,
          label: 'Barcode (Bisa diedit/sesuaikan)',
          keyboardType: TextInputType.number,
          validator: (val) => val == null || val.trim().isEmpty ? 'Barcode tidak boleh kosong' : null,
        ),
        AppFormField(
          controller: nameController,
          label: 'Nama Produk',
          hint: 'Contoh: Indomie Goreng Spesial',
          validator: (val) => val == null || val.trim().isEmpty ? 'Nama tidak boleh kosong' : null,
        ),
        AppFormField(
          controller: priceController,
          label: 'Harga Jual (Rp)',
          hint: 'Contoh: 3100',
          keyboardType: TextInputType.number,
          validator: (val) {
            if (val == null || val.trim().isEmpty) return 'Harga tidak boleh kosong';
            if (double.tryParse(val) == null) return 'Harga harus berupa angka';
            return null;
          },
        ),
        AppFormField(
          controller: stockController,
          label: 'Jumlah Stok Saat Ini',
          hint: 'Contoh: 120',
          keyboardType: TextInputType.number,
          validator: (val) {
            if (val == null || val.trim().isEmpty) return 'Stok tidak boleh kosong';
            if (int.tryParse(val) == null) return 'Stok harus berupa angka bulat';
            return null;
          },
        ),
      ],
      confirmLabel: 'Simpan Barang',
      onConfirm: () async {
        final finalBarcode = barcodeController.text.trim();
        final name = nameController.text.trim();
        final price = double.parse(priceController.text);
        final stock = int.parse(stockController.text);

        await db.insertProduct(finalBarcode, name, price, stock);
        ref.invalidate(dashboardProvider);

        setState(() {
          _sessionHistory.insert(0, {
            'barcode': finalBarcode,
            'name': name,
            'price': price,
            'stock': stock,
            'time': DateTime.now().toString().substring(11, 16),
            'is_new': product == null,
          });
        });

        if (mounted) {
          AppToast.show(context, message: 'Berhasil menyimpan: $name (Stok: $stock)', bottomMargin: 24);
        }
      },
    ).then((_) {
      if (mounted) {
        setState(() => _isScanning = true);
      }
    });
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

            // Manual Barcode Input
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
                      keyboardType: TextInputType.number,
                      onSubmitted: (_) => _submitManual(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FloatingActionButton.small(
                    onPressed: _submitManual,
                    elevation: 0,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    child: const Icon(Icons.send_rounded),
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

