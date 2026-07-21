import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dodolanku/features/scanner/providers/scanner_provider.dart';
import 'package:dodolanku/core/utils/currency_formatter.dart';
import 'package:dodolanku/core/widgets/app_widgets.dart';
import 'package:dodolanku/features/scanner/widgets/print_dialog.dart';
import 'package:dodolanku/core/utils/qris_generator.dart';

class ScannerPage extends ConsumerStatefulWidget {
  const ScannerPage({super.key});

  @override
  ConsumerState<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends ConsumerState<ScannerPage> {
  final TextEditingController _manualController = TextEditingController();

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

    final found = await ref
        .read(scannerProvider.notifier)
        .lookupBarcode(barcode);
    if (!found && mounted) {
      _showRegistrationDialog(barcode);
    } else if (found && mounted) {
      final state = ref.read(scannerProvider);
      if (state.productPrice == 0 || state.productStock == 0) {
        _showSetPriceStockDialog(
          barcode,
          state.productName,
          state.productPrice,
          state.productStock,
        );
      }
    }
  }

  void _showRegistrationDialog(String barcode) {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final stockController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showAppFormModal(
      context: context,
      title: 'Produk Baru Terdeteksi',
      subtitle: 'Barcode: $barcode',
      formKey: formKey,
      fields: [
        AppFormField(
          controller: nameController,
          label: 'Nama Produk',
          hint: 'Masukkan nama produk...',
          validator: (val) => val == null || val.trim().isEmpty
              ? 'Nama tidak boleh kosong'
              : null,
        ),
        AppFormField(
          controller: priceController,
          label: 'Harga Jual (Rp)',
          hint: 'Contoh: 15000',
          keyboardType: TextInputType.number,
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return 'Harga tidak boleh kosong';
            }
            if (double.tryParse(val) == null) return 'Harga harus berupa angka';
            return null;
          },
        ),
        AppFormField(
          controller: stockController,
          label: 'Jumlah Stok Saat Ini',
          hint: 'Contoh: 50',
          keyboardType: TextInputType.number,
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return 'Stok tidak boleh kosong';
            }
            if (int.tryParse(val) == null) {
              return 'Stok harus berupa angka bulat';
            }
            return null;
          },
        ),
      ],
      onConfirm: () async {
        final name = nameController.text.trim();
        final price = double.parse(priceController.text);
        final stock = int.parse(stockController.text);
        await ref
            .read(scannerProvider.notifier)
            .addProduct(
              barcode: barcode,
              name: name,
              price: price,
              stock: stock,
            );
      },
    );
  }

  /// Muncul saat produk ditemukan tapi harga atau stok belum diset (== 0).
  void _showSetPriceStockDialog(
    String barcode,
    String productName,
    double currentPrice,
    int currentStock,
  ) {
    final priceController = TextEditingController(
      text: currentPrice > 0 ? currentPrice.toStringAsFixed(0) : '',
    );
    final stockController = TextEditingController(
      text: currentStock > 0 ? currentStock.toString() : '',
    );
    final formKey = GlobalKey<FormState>();

    final needPrice = currentPrice == 0;
    final needStock = currentStock == 0;

    final fields = <AppFormField>[
      if (needPrice)
        AppFormField(
          controller: priceController,
          label: 'Harga Jual (Rp)',
          hint: 'Contoh: 15000',
          keyboardType: TextInputType.number,
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return 'Harga tidak boleh kosong';
            }
            final v = double.tryParse(val.trim());
            if (v == null || v <= 0) return 'Harga harus lebih dari 0';
            return null;
          },
        ),
      if (needStock)
        AppFormField(
          controller: stockController,
          label: 'Jumlah Stok Saat Ini',
          hint: 'Contoh: 50',
          keyboardType: TextInputType.number,
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return 'Stok tidak boleh kosong';
            }
            final v = int.tryParse(val.trim());
            if (v == null || v < 0) return 'Stok harus berupa angka ≥ 0';
            return null;
          },
        ),
    ];

    showAppFormModal(
      context: context,
      title: 'Lengkapi Data Produk',
      subtitle:
          '$productName\n'
          '${needPrice && needStock
              ? 'Harga dan stok'
              : needPrice
              ? 'Harga'
              : 'Stok'} '
          'belum diatur. Isi sekarang agar produk dapat dijual.',
      formKey: formKey,
      fields: fields,
      confirmLabel: 'Simpan & Lanjutkan',
      onConfirm: () async {
        final newPrice = needPrice
            ? double.parse(priceController.text.trim())
            : currentPrice;
        final newStock = needStock
            ? int.parse(stockController.text.trim())
            : currentStock;
        await ref
            .read(scannerProvider.notifier)
            .updateProductDetails(
              barcode: barcode,
              price: newPrice,
              stock: newStock,
            );
      },
    );
  }

  void _showPaymentDialog(BuildContext context, double total) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PaymentBottomSheet(
        total: total,
        onConfirm: (selectedMethod, paid) async {
          Navigator.pop(ctx);

          if (selectedMethod == 'qris') {
            final db = ref.read(databaseServiceProvider);
            final config = await db.getReceiptConfig();
            final qrisData = config['qris_data'] ?? '';
            if (qrisData.isEmpty) {
              if (context.mounted) {
                AppToast.show(
                  context,
                  message: 'QRIS belum dikonfigurasi. Atur QRIS di Pengaturan terlebih dahulu.',
                  isError: true,
                  bottomMargin: 24,
                );
              }
              return CheckoutResult(total: 0, amountPaid: 0, change: 0, paymentMethod: 'qris', items: []);
            }

            final dynamicQris = QrisGenerator.makeDynamic(
              staticQris: qrisData,
              amount: total,
            );

            if (!context.mounted) return CheckoutResult(total: 0, amountPaid: 0, change: 0, paymentMethod: 'qris', items: []);

            final proceed = await showDialog<bool>(
              context: context,
              barrierDismissible: false,
              builder: (dialogCtx) => Dialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Scan QRIS Dinamis',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Total: Rp ${formatRupiah(total)}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          width: 220,
                          height: 220,
                          child: Image.network(
                            'https://api.qrserver.com/v1/create-qr-code/?size=250x250&data=${Uri.encodeComponent(dynamicQris)}',
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(child: CircularProgressIndicator());
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Text(
                                  'Gagal memuat QR Code. Cek koneksi internet.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 12),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(dialogCtx, false),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: const Text('Batal'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(dialogCtx, true),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: const Text('Sudah Bayar'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );

            if (proceed != true) {
              return CheckoutResult(total: 0, amountPaid: 0, change: 0, paymentMethod: 'qris', items: []);
            }
          }

          final result = await ref
              .read(scannerProvider.notifier)
              .checkout(paymentMethod: selectedMethod, amountPaid: paid);
          if (!context.mounted) return result;
          final msg = selectedMethod == 'tunai'
              ? 'Transaksi selesai! Kembalian: Rp ${formatRupiah(paid - total)}'
              : 'Transaksi selesai!';
          AppToast.show(context, message: msg);
          showPrintDialog(context, result);
          return result;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(scannerProvider);
    final notifier = ref.read(scannerProvider.notifier);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Kasir'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (state.cart.isNotEmpty)
            TextButton.icon(
              onPressed: () {
                showAppConfirmModal(
                  context: context,
                  title: 'Kosongkan Keranjang?',
                  message:
                      'Semua item belanjaan di dalam keranjang akan dihapus.',
                  confirmLabel: 'Hapus Semua',
                  isDestructive: true,
                  onConfirm: () => notifier.clearCart(),
                );
              },
              icon: const Icon(
                Icons.delete_outline,
                size: 18,
                color: Color(0xFFDC2626),
              ),
              label: const Text(
                'Kosongkan',
                style: TextStyle(color: Color(0xFFDC2626), fontSize: 13),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                children: [
                  // ── Camera / Scan Area (Always Active) ──
                  AppBarcodeScanner(
                    onScan: (rawValue) async {
                      final notifier = ref.read(scannerProvider.notifier);
                      final found = await notifier.lookupBarcode(rawValue);
                      if (!found && mounted) {
                        _showRegistrationDialog(rawValue);
                      } else if (found && mounted) {
                        final st = ref.read(scannerProvider);
                        if (st.productPrice == 0 || st.productStock == 0) {
                          _showSetPriceStockDialog(
                            rawValue,
                            st.productName,
                            st.productPrice,
                            st.productStock,
                          );
                        }
                      }
                    },
                  ),

                  // ── Manual Input ────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _manualController,
                            decoration: InputDecoration(
                              hintText: 'Ketik barcode manual...',
                              prefixIcon: const Icon(Icons.keyboard, size: 20),
                              fillColor: Colors.white,
                              filled: true,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 12,
                              ),
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
                        Hero(
                          tag: 'scan_fab',
                          child: FloatingActionButton.small(
                            onPressed: _submitManual,
                            heroTag: null,
                            elevation: 0,
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                            foregroundColor: Colors.white,
                            child: const Icon(Icons.send_rounded),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── Cart Header ─────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.shopping_cart_outlined,
                              size: 18,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Keranjang',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[700],
                              ),
                            ),
                            if (state.cartCount > 0) ...[
                              const SizedBox(width: 8),
                              AppStatusBadge(
                                label: '${state.cartCount} item',
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ],
                          ],
                        ),
                        if (state.productName.isNotEmpty &&
                            state.productName != 'Produk belum terdaftar')
                          Flexible(
                            child: AppInfoBadge(
                              label: state.productName,
                              color: Colors.grey[700],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // ── Cart List ───────────────────────────
                  Expanded(
                    child: state.cart.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.shopping_cart_outlined,
                                  size: 48,
                                  color: Colors.grey[300],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Keranjang kosong',
                                  style: TextStyle(color: Colors.grey[400]),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Scan atau ketik barcode untuk mulai',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            itemCount: state.cart.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final item = state.cart[index];
                              return AppCard(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                child: Row(
                                  children: [
                                    AppIconAvatar(
                                      icon: Icons.inventory_2_outlined,
                                      radius: 18,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            'Rp ${formatRupiah(item.price)}',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Qty controls
                                    Row(
                                      children: [
                                        _QtyButton(
                                          icon: Icons.remove,
                                          onTap: () => notifier.updateQty(
                                            item.barcode,
                                            item.qty - 1,
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                          ),
                                          child: Text(
                                            '${item.qty}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ),
                                        _QtyButton(
                                          icon: Icons.add,
                                          onTap: () => notifier.updateQty(
                                            item.barcode,
                                            item.qty + 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Rp ${formatRupiah(item.subtotal)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),

                  // ── Checkout Bar ─────────────────────────
                  if (state.cart.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          top: BorderSide(color: Colors.grey.shade200),
                        ),
                      ),
                      child: Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Total',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                'Rp ${formatRupiah(state.cartTotal)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () =>
                                  _showPaymentDialog(context, state.cartTotal),
                              icon: const Icon(Icons.payment_rounded),
                              label: const Text('Bayar Sekarang'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Icon(icon, size: 16, color: Colors.grey[700]),
      ),
    );
  }
}

// ── Payment Bottom Sheet ──────────────────────────────────────────────────────

class _PaymentBottomSheet extends StatefulWidget {
  final double total;
  final Future<CheckoutResult> Function(String method, double paid) onConfirm;

  const _PaymentBottomSheet({required this.total, required this.onConfirm});

  @override
  State<_PaymentBottomSheet> createState() => _PaymentBottomSheetState();
}

class _PaymentBottomSheetState extends State<_PaymentBottomSheet> {
  final _amountController = TextEditingController();
  String _selectedMethod = 'tunai';
  double _change = 0;
  bool _isProcessing = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomInset + safeBottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Pembayaran',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            // Total card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Belanja',
                    style: TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'Rp ${formatRupiah(widget.total)}',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Metode bayar
            const Text(
              'Metode Bayar',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: ['tunai', 'qris', 'transfer'].map((method) {
                final labels = {
                  'tunai': 'Tunai',
                  'qris': 'QRIS',
                  'transfer': 'Transfer',
                };
                final icons = {
                  'tunai': Icons.payments_outlined,
                  'qris': Icons.qr_code,
                  'transfer': Icons.account_balance_outlined,
                };
                final selected = _selectedMethod == method;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _selectedMethod = method;
                      _change = 0;
                      _amountController.clear();
                    }),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: selected
                            ? primary.withValues(alpha: 0.08)
                            : Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected ? primary : Colors.grey.shade300,
                          width: selected ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            icons[method],
                            size: 22,
                            color: selected ? primary : Colors.grey,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            labels[method]!,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: selected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: selected ? primary : Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Input nominal (tunai only)
            if (_selectedMethod == 'tunai') ...[
              const Text(
                'Nominal Diterima (Rp)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                autofocus: true,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: 'Masukkan nominal...',
                  filled: true,
                  fillColor: Colors.grey[50],
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: primary, width: 1.5),
                  ),
                ),
                onChanged: (val) {
                  final paid = double.tryParse(val) ?? 0;
                  setState(() => _change = paid - widget.total);
                },
              ),
              if (_change >= 0) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF86EFAC)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Kembalian',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        'Rp ${formatRupiah(_change)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Color(0xFF16A34A),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 4),
            ],
            const SizedBox(height: 16),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isProcessing
                        ? null
                        : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Batal',
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isProcessing
                        ? null
                        : () async {
                            double paid =
                                double.tryParse(_amountController.text) ?? 0;
                            if (_selectedMethod != 'tunai') paid = widget.total;
                            if (_selectedMethod == 'tunai' &&
                                paid < widget.total) {
                              AppToast.show(
                                context,
                                message: 'Nominal kurang dari total belanja',
                                isError: true,
                                bottomMargin: bottomInset + 300,
                              );
                              return;
                            }
                            setState(() => _isProcessing = true);
                            await widget.onConfirm(_selectedMethod, paid);
                          },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isProcessing
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Konfirmasi',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
