import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dodolanku/core/widgets/app_widgets.dart';
import 'package:dodolanku/features/settings/providers/profile_provider.dart';
import 'package:dodolanku/features/scanner/providers/scanner_provider.dart';
import 'stock_opname_page.dart';
import 'printer_settings_page.dart';
import 'payment_method_page.dart';
import 'receipt_config_page.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  void _showEditProfileDialog(
    BuildContext context,
    WidgetRef ref,
    String currentName,
    String currentAddress,
  ) {
    final nameCtrl = TextEditingController(text: currentName);
    final addressCtrl = TextEditingController(text: currentAddress);
    final formKey = GlobalKey<FormState>();

    showAppFormModal(
      context: context,
      title: 'Ubah Profil Toko',
      formKey: formKey,
      fields: [
        AppFormField(
          controller: nameCtrl,
          label: 'Nama Toko',
          hint: 'Contoh: dodolanku',
          validator: (v) => v == null || v.trim().isEmpty
              ? 'Nama toko tidak boleh kosong'
              : null,
        ),
        AppFormField(
          controller: addressCtrl,
          label: 'Alamat Toko',
          hint: 'Contoh: Jl. Raya No. 10',
          validator: (v) => v == null || v.trim().isEmpty
              ? 'Alamat toko tidak boleh kosong'
              : null,
        ),
      ],
      onConfirm: () async {
        await ref
            .read(profileProvider.notifier)
            .updateProfile(name: nameCtrl.text, address: addressCtrl.text);
        if (context.mounted) {
          AppToast.show(context, message: 'Profil toko berhasil diperbarui!');
        }
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).padding.bottom + 90),
        children: [
          // Profile Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  AppIconAvatar(
                    icon: Icons.store,
                    radius: 30,
                    iconColor: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.storeName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          profile.storeAddress,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _showEditProfileDialog(
                      context,
                      ref,
                      profile.storeName,
                      profile.storeAddress,
                    ),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          AppSettingsSection(
            title: 'Pengaturan Toko',
            tiles: [
              AppSettingsTile(
                icon: Icons.inventory_2_outlined,
                title: 'Stock Opname (Input Stok)',
                subtitle: 'Scan & update stok/harga barang',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const StockOpnamePage(),
                    ),
                  );
                },
              ),
              AppSettingsTile(
                icon: Icons.print_outlined,
                title: 'Pengaturan Printer',
                subtitle: 'Scan, hubungkan, & kelola bluetooth thermal printer',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PrinterSettingsPage(),
                    ),
                  );
                },
              ),
              AppSettingsTile(
                icon: Icons.receipt_long_outlined,
                title: 'Konfigurasi Struk',
                subtitle: 'Atur nama toko, alamat, header & footer struk',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ReceiptConfigPage(),
                    ),
                  );
                },
              ),
              AppSettingsTile(
                icon: Icons.payment_outlined,
                title: 'Metode Pembayaran',
                subtitle: 'Atur QRIS & metode pembayaran kasir',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PaymentMethodPage(),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 20),

          AppSettingsSection(
            title: 'Database & Sinkronisasi',
            tiles: [
              FutureBuilder<int>(
                future: ref.read(databaseServiceProvider).getTotalProductsCount(),
                builder: (context, snapshot) {
                  final count = snapshot.data ?? 0;
                  return AppSettingsTile(
                    icon: Icons.storage_outlined,
                    title: 'Info Database Barcode Lokal',
                    subtitle: '${count.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} item master termuat',
                  );
                },
              ),
              AppSettingsTile(
                icon: Icons.sync_outlined,
                title: 'Sinkronkan Katalog Produk',
                subtitle: 'Gabungkan data barcode master ke katalog produk lokal',
                onTap: () async {
                  AppToast.show(context, message: 'Menyinkronkan data katalog produk dari Turso...');
                  try {
                    final newItems = await ref.read(databaseServiceProvider).syncMasterProductsFromTurso();
                    if (context.mounted) {
                      if (newItems > 0) {
                        AppToast.show(context, message: 'Berhasil menyinkronkan $newItems produk!');
                      } else {
                        AppToast.show(context, message: 'Semua produk master sudah tersinkronisasi.');
                      }
                    }
                  } catch (e) {
                    if (context.mounted) {
                      AppToast.show(context, message: 'Gagal sinkronisasi: $e');
                    }
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
