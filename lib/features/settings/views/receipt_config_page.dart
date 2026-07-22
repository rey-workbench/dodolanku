import 'package:dodolanku/core/widgets/app_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dodolanku/features/settings/repositories/settings_repository.dart';
import 'package:dodolanku/features/settings/providers/profile_provider.dart';

class ReceiptConfigPage extends ConsumerStatefulWidget {
  const ReceiptConfigPage({super.key});

  @override
  ConsumerState<ReceiptConfigPage> createState() => _ReceiptConfigPageState();
}

class _ReceiptConfigPageState extends ConsumerState<ReceiptConfigPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _headerController = TextEditingController();
  final _footerController = TextEditingController();
  String _selectedPaperSize = '58';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final settingsRepo = ref.read(settingsRepositoryProvider);
    final config = await settingsRepo.getReceiptConfig();
    setState(() {
      _nameController.text = config['store_name'] ?? 'dodolanku';
      _addressController.text = config['store_address'] ?? 'Jl. Raya dodolanku No. 1';
      _phoneController.text = config['store_phone'] ?? '';
      _selectedPaperSize = settingsRepo.getPaperSize();
      _headerController.text = config['header_msg'] ?? '';
      _footerController.text = config['footer_msg'] ?? 'Terima Kasih';
      _isLoading = false;
    });
  }

  Future<void> _saveConfig() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final settingsRepo = ref.read(settingsRepositoryProvider);

    try {
      settingsRepo.setPaperSize(_selectedPaperSize);

      final currentConfig = await settingsRepo.getReceiptConfig();
      await settingsRepo.updateReceiptConfig(
        storeName: _nameController.text,
        storeAddress: _addressController.text,
        storePhone: _phoneController.text,
        qrisData: currentConfig['qris_data'] ?? '',
        headerMsg: _headerController.text,
        footerMsg: _footerController.text,
      );
      
      ref.invalidate(profileProvider);
      
      if (mounted) {
        AppToast.show(context, message: 'Konfigurasi struk berhasil disimpan!', bottomMargin: 24);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(
          context,
          message: 'Gagal menyimpan konfigurasi: $e',
          isError: true,
          bottomMargin: 24,
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _headerController.dispose();
    _footerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Konfigurasi Struk'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).padding.bottom + 24),
                children: [
                  AppCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Desain & Informasi Struk',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Nama Toko
                        const Text(
                          'Nama Toko',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _nameController,
                          style: const TextStyle(fontSize: 14),
                          decoration: _inputDecoration('Contoh: Jaya Mart'),
                        ),
                        const SizedBox(height: 16),

                        // Alamat Toko
                        const Text(
                          'Alamat Toko',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _addressController,
                          maxLines: 2,
                          style: const TextStyle(fontSize: 14),
                          decoration: _inputDecoration(
                            'Contoh: Jl. Raya No. 10',
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Nomor HP
                        const Text(
                          'Nomor HP',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(fontSize: 14),
                          decoration: _inputDecoration('Contoh: 081234567890'),
                        ),
                        const SizedBox(height: 16),

                        // Ukuran Kertas
                        const Text(
                          'Ukuran Kertas Thermal',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedPaperSize,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black,
                          ),
                          decoration: _inputDecoration('Pilih ukuran kertas'),
                          items: const [
                            DropdownMenuItem(
                              value: '58',
                              child: Text('58 mm (EDC / Portable)'),
                            ),
                            DropdownMenuItem(
                              value: '80',
                              child: Text('80 mm (Supermarket / Resto)'),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedPaperSize = val);
                            }
                          },
                        ),
                        const SizedBox(height: 16),

                        // Pesan Header (Opsional)
                        const Text(
                          'Pesan Header (Opsional)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _headerController,
                          style: const TextStyle(fontSize: 14),
                          decoration: _inputDecoration(
                            'Contoh: Kasir: Admin / No. Telp',
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Pesan Footer
                        const Text(
                          'Pesan Footer',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _footerController,
                          style: const TextStyle(fontSize: 14),
                          validator: (val) => val == null || val.trim().isEmpty
                              ? 'Pesan footer wajib diisi'
                              : null,
                          decoration: _inputDecoration(
                            'Contoh: Terima Kasih Sudah Belanja!',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Info Lock Footer
                  AppCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.lock_outline, color: primary, size: 20),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Footer Sistem (Default)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'powered by : reynaldsilva.my.id',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 11,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  ElevatedButton(
                    onPressed: _saveConfig,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Simpan Konfigurasi',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.grey[50],
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 1.5,
        ),
      ),
    );
  }
}
