import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dodolanku/features/debt/providers/debt_provider.dart';
import 'package:dodolanku/core/utils/currency_formatter.dart';
import 'package:dodolanku/core/widgets/app_widgets.dart';

class DebtPage extends ConsumerWidget {
  const DebtPage({super.key});

  void _showAddDebtDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final dueCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showAppFormModal(
      context: context,
      title: 'Tambah Catatan Hutang',
      formKey: formKey,
      fields: [
        AppFormField(
          controller: nameCtrl,
          label: 'Nama Pelanggan / Debitur',
          hint: 'Contoh: Pak Budi',
          validator: (v) => v == null || v.trim().isEmpty ? 'Nama tidak boleh kosong' : null,
        ),
        AppFormField(
          controller: amountCtrl,
          label: 'Jumlah Hutang (Rp)',
          hint: 'Contoh: 50000',
          keyboardType: TextInputType.number,
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Jumlah tidak boleh kosong';
            if (double.tryParse(v) == null) return 'Harus berupa angka';
            return null;
          },
        ),
        AppFormField(
          controller: descCtrl,
          label: 'Keterangan Barang',
          hint: 'Contoh: Beli beras 5kg & minyak',
        ),
        AppFormField(
          controller: dueCtrl,
          label: 'Tanggal Jatuh Tempo (Opsional)',
          hint: 'Contoh: 27/07/2026',
        ),
      ],
      onConfirm: () {
        ref.read(debtProvider.notifier).addDebt(
              name: nameCtrl.text,
              amount: double.parse(amountCtrl.text),
              description: descCtrl.text.isNotEmpty ? descCtrl.text : null,
              dueDate: dueCtrl.text.isNotEmpty ? dueCtrl.text : null,
            );
        AppToast.show(context, message: 'Catatan hutang berhasil ditambahkan');
      },
    );
  }

  void _showPaymentDialog(BuildContext context, WidgetRef ref, int id, double remaining) {
    final amountCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showAppFormModal(
      context: context,
      title: 'Bayar Hutang',
      subtitle: 'Sisa hutang: Rp ${formatRupiah(remaining)}',
      formKey: formKey,
      fields: [
        AppFormField(
          controller: amountCtrl,
          label: 'Nominal Pembayaran (Rp)',
          keyboardType: TextInputType.number,
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Nominal tidak boleh kosong';
            final val = double.tryParse(v);
            if (val == null || val <= 0) return 'Harus angka positif';
            if (val > remaining) return 'Melebihi sisa hutang';
            return null;
          },
        ),
      ],
      confirmLabel: 'Bayar',
      onConfirm: () {
        ref.read(debtProvider.notifier).payDebt(id, double.parse(amountCtrl.text));
        AppToast.show(context, message: 'Pembayaran hutang berhasil dicatat');
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final debtAsync = ref.watch(debtProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Catatan Hutang'),
        actions: [
          IconButton(
            onPressed: () => _showAddDebtDialog(context, ref),
            icon: Icon(Icons.add_circle_outline, color: Theme.of(context).colorScheme.primary, size: 28),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).padding.bottom + 90),
        child: Column(
          children: [
            AppSearchBar(hintText: 'Cari nama debitur...'),
            const SizedBox(height: 20),
            Expanded(
              child: debtAsync.when(
                loading: () => ListView.builder(
                  itemCount: 5,
                  itemBuilder: (context, index) {
                    return const AppCard(
                      margin: EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          AppShimmer(width: 40, height: 40, borderRadius: 20),
                          SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppShimmer(width: 120, height: 15),
                              SizedBox(height: 6),
                              AppShimmer(width: 160, height: 13),
                            ],
                          ),
                          Spacer(),
                          AppShimmer(width: 24, height: 24, borderRadius: 12),
                        ],
                      ),
                    );
                  },
                ),
                error: (err, stack) => Center(child: Text('Error: $err')),
                data: (list) {
                  if (list.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.assignment_outlined, size: 48, color: Colors.grey[300]),
                          const SizedBox(height: 12),
                          Text('Belum ada catatan hutang', style: TextStyle(color: Colors.grey[500])),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final item = list[index];
                      final id = item.id ?? 0;
                      final name = item.debtorName;
                      final total = item.amount;
                      final paid = item.paid;
                      final remaining = item.remainingAmount;
                      final desc = item.description;
                      final due = item.dueDate;
                      final isSettled = item.isSettled;

                      return RepaintBoundary(
                        child: AppCard(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ExpansionTile(
                            leading: AppInitialAvatar(name: name),
                            title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(
                              isSettled ? 'LUNAS' : 'Belum Lunas: Rp ${formatRupiah(remaining)}',
                              style: TextStyle(
                                fontSize: 12,
                              color: isSettled ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Divider(),
                                    if (desc != null) ...[
                                      Text('Keterangan: $desc', style: const TextStyle(fontSize: 13)),
                                      const SizedBox(height: 4),
                                    ],
                                    Text('Total Hutang: Rp ${formatRupiah(total)}', style: const TextStyle(fontSize: 13)),
                                    Text('Sudah Dibayar: Rp ${formatRupiah(paid)}', style: const TextStyle(fontSize: 13)),
                                    if (due != null) ...[
                                      const SizedBox(height: 4),
                                      Text('Jatuh Tempo: $due', style: const TextStyle(fontSize: 13, color: Color(0xFFB45309), fontWeight: FontWeight.bold)),
                                    ],
                                    const SizedBox(height: 12),
                                    if (!isSettled)
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          TextButton(
                                            onPressed: () {
                                              showAppConfirmModal(
                                                context: context,
                                                title: 'Tandai Lunas?',
                                                message: 'Apakah Anda yakin ingin menandai catatan hutang ini lunas sepenuhnya?',
                                                confirmLabel: 'Tandai Lunas',
                                                onConfirm: () => ref.read(debtProvider.notifier).settleDebt(id),
                                              );
                                            },
                                            child: const Text('Tandai Lunas'),
                                          ),
                                          const SizedBox(width: 8),
                                          ElevatedButton(
                                            onPressed: () => _showPaymentDialog(context, ref, id, remaining),
                                            child: const Text('Bayar Cicil'),
                                          ),
                                        ],
                                      )
                                    else
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          TextButton(
                                            onPressed: () {
                                              showAppConfirmModal(
                                                context: context,
                                                title: 'Hapus Catatan?',
                                                message: 'Apakah Anda yakin ingin menghapus catatan hutang yang telah lunas ini?',
                                                confirmLabel: 'Hapus Catatan',
                                                isDestructive: true,
                                                onConfirm: () => ref.read(debtProvider.notifier).deleteDebt(id),
                                              );
                                            },
                                            child: const Text('Hapus Catatan', style: TextStyle(color: Color(0xFFDC2626))),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
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
