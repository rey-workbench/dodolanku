import 'package:dodolanku/core/widgets/app_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dodolanku/features/settings/repositories/settings_repository.dart';
import 'package:dodolanku/features/settings/providers/profile_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:dodolanku/core/utils/qris_generator.dart';

class PaymentMethodPage extends ConsumerStatefulWidget {
  const PaymentMethodPage({super.key});

  @override
  ConsumerState<PaymentMethodPage> createState() => _PaymentMethodPageState();
}

class _PaymentMethodPageState extends ConsumerState<PaymentMethodPage> {
  final _qrisController = TextEditingController();
  String _qrisMerchantName = '';
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadQris();
  }

  @override
  void dispose() {
    _qrisController.dispose();
    super.dispose();
  }

  Future<void> _loadQris() async {
    try {
      final settingsRepo = ref.read(settingsRepositoryProvider);
      final config = await settingsRepo.getReceiptConfig();
      final qris = config['qris_data'] ?? '';
      String merchantName = '';
      if (qris.isNotEmpty) {
        try {
          merchantName = QrisGenerator.extractMerchantName(qris);
        } catch (_) {}
      }
      if (mounted) {
        setState(() {
          _qrisController.text = qris;
          _qrisMerchantName = merchantName;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveQris() async {
    setState(() => _isSaving = true);
    final settingsRepo = ref.read(settingsRepositoryProvider);
    try {
      final config = await settingsRepo.getReceiptConfig();
      await settingsRepo.updateReceiptConfig(
        storeName: config['store_name'] ?? '',
        storeAddress: config['store_address'] ?? '',
        storePhone: config['store_phone'] ?? '',
        qrisData: _qrisController.text,
        headerMsg: config['header_msg'] ?? '',
        footerMsg: config['footer_msg'] ?? 'Terima Kasih',
      );

      ref.invalidate(profileProvider);

      if (mounted) {
        AppToast.show(
          context,
          message: 'Pengaturan QRIS berhasil disimpan!',
          bottomMargin: 24,
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(
          context,
          message: 'Gagal menyimpan: $e',
          isError: true,
          bottomMargin: 24,
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _handleQrisResult(String qrisRaw) {
    if (!qrisRaw.startsWith('000201')) {
      if (mounted) {
        AppToast.show(
          context,
          message: 'Bukan kode QRIS yang valid!',
          isError: true,
          bottomMargin: 24,
        );
      }
      return;
    }

    final merchantName = QrisGenerator.extractMerchantName(qrisRaw);

    setState(() {
      _qrisController.text = qrisRaw;
      _qrisMerchantName = merchantName;
    });
    if (mounted) {
      AppToast.show(
        context,
        message: 'QRIS berhasil diverifikasi: $merchantName',
        bottomMargin: 24,
      );
    }
  }

  Future<void> _scanQrisFromGallery() async {
    MobileScannerController? controller;
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      controller = MobileScannerController();
      final barcodeCapture = await controller.analyzeImage(image.path);

      final qrisRaw = barcodeCapture?.barcodes.firstOrNull?.rawValue;
      if (qrisRaw != null) {
        _handleQrisResult(qrisRaw);
      } else {
        if (mounted) {
          AppToast.show(
            context,
            message: 'Tidak ada kode QR ditemukan di gambar!',
            isError: true,
            bottomMargin: 24,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(
          context,
          message: 'Gagal menganalisis gambar: $e',
          isError: true,
          bottomMargin: 24,
        );
      }
    } finally {
      controller?.dispose();
    }
  }

  void _openQrisCameraScanner() {
    bool scanned = false;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.55,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Arahkan Kamera ke QRIS',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                'Scan QR Code QRIS statis dari struk/poster merchant',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: AppBarcodeScanner(
                  onScan: (rawValue) {
                    if (scanned) return;
                    scanned = true;
                    Navigator.of(ctx).pop();
                    _handleQrisResult(rawValue);
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final hasQris = _qrisController.text.isNotEmpty;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Metode Pembayaran'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Cash
                AppCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.money_rounded,
                          color: Colors.green.shade700,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tunai (Cash)',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Selalu aktif, tidak perlu konfigurasi.',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.check_circle_rounded,
                        color: Colors.green.shade600,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // QRIS
                AppCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: hasQris
                                  ? const Color(0xFFF0FDF4)
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.qr_code_2_rounded,
                              color: hasQris
                                  ? const Color(0xFF16A34A)
                                  : Colors.grey,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'QRIS',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  hasQris
                                      ? _qrisMerchantName
                                      : 'Belum dikonfigurasi',
                                  style: TextStyle(
                                    color: hasQris
                                        ? const Color(0xFF16A34A)
                                        : Colors.grey,
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          if (hasQris)
                            Icon(
                              Icons.check_circle_rounded,
                              color: Colors.green.shade600,
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Nonaktif',
                                style: TextStyle(
                                  color: Colors.orange.shade800,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(height: 1),
                      const SizedBox(height: 16),
                      Text(
                        'Upload gambar atau scan kamera QRIS statis Anda. Sistem akan otomatis menghasilkan QRIS dinamis dengan nominal saat checkout.',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _scanQrisFromGallery,
                              icon: const Icon(
                                Icons.image_search_rounded,
                                size: 18,
                              ),
                              label: const Text('Upload'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 11,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _openQrisCameraScanner,
                              icon: const Icon(
                                Icons.qr_code_scanner_rounded,
                                size: 18,
                              ),
                              label: const Text('Kamera'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 11,
                                ),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                          if (hasQris) ...[
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () => setState(() {
                                _qrisController.clear();
                                _qrisMerchantName = '';
                              }),
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                color: Colors.red,
                              ),
                              tooltip: 'Hapus QRIS',
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: _isSaving ? null : _saveQris,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _isSaving ? 'Menyimpan...' : 'Simpan Pengaturan',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
    );
  }
}
