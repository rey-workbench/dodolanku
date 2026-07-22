import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dodolanku/features/orders/providers/orders_provider.dart';
import 'package:dodolanku/core/utils/currency_formatter.dart';
import 'package:dodolanku/core/widgets/app_widgets.dart';
import 'package:dodolanku/features/orders/repositories/transaction_repository.dart';

class OrdersPage extends ConsumerWidget {
  const OrdersPage({super.key});

  String _formatDateTime(String isoString) {
    try {
      final dt = DateTime.parse(isoString);
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return isoString;
    }
  }

  void _showDetailDialog(
    BuildContext context,
    WidgetRef ref,
    TransactionWithItems tx,
  ) {
    showAppDetailModal(
      context: context,
      title: 'Detail Transaksi #${tx.transaction.id}',
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Waktu: ${_formatDateTime(tx.transaction.createdAt)}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            Text(
              'Metode Pembayaran: ${tx.transaction.paymentMethod.toUpperCase()}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            const Divider(height: 20),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: tx.items
                    .map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.productName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    '${item.qty} x Rp ${formatRupiah(item.price)}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              'Rp ${formatRupiah(item.subtotal)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Belanja',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Rp ${formatRupiah(tx.transaction.totalAmount)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Bayar',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                Text(
                  'Rp ${formatRupiah(tx.transaction.amountPaid)}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Kembalian',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                Text(
                  'Rp ${formatRupiah(tx.transaction.changeAmount)}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context); // Tutup dialog detail

                  final itemListStr = tx.items
                      .map(
                        (i) =>
                            '- Stok ${i.productName} dikembalikan ke persediaan sebanyak ${i.qty}',
                      )
                      .join('\n');

                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text(
                        'Hapus Transaksi',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      content: Text(
                        'Apakah Anda yakin ingin menghapus transaksi ini?\n\n$itemListStr\n\nPilih tindakan untuk stok barang:',
                        style: const TextStyle(fontSize: 14),
                      ),
                      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                      actionsPadding: const EdgeInsets.all(16),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Batal'),
                        ),
                        TextButton(
                          onPressed: () async {
                            Navigator.pop(ctx);
                            final txRepo = ref.read(transactionRepositoryProvider);
                            await txRepo.deleteTransaction(
                              tx.transaction.id!,
                              restoreStock: false,
                            );
                            ref.invalidate(ordersProvider); // Refresh daftar
                            if (context.mounted) {
                              AppToast.show(
                                context,
                                message: 'Transaksi dihapus (Stok hangus)',
                              );
                            }
                          },
                          child: const Text(
                            'Hapus TANPA Kembali Stok',
                            style: TextStyle(color: Colors.red, fontSize: 13),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            Navigator.pop(ctx);
                            final txRepo = ref.read(transactionRepositoryProvider);
                            await txRepo.deleteTransaction(
                              tx.transaction.id!,
                              restoreStock: true,
                            );
                            ref.invalidate(ordersProvider); // Refresh daftar
                            if (context.mounted) {
                              AppToast.show(
                                context,
                                message:
                                    'Transaksi dihapus (Stok dikembalikan)',
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Hapus & Kembalikan Stok'),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Hapus Transaksi'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(ordersProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(title: const Text('Riwayat Transaksi')),
      body: transactionsAsync.when(
        loading: () => ListView.separated(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            MediaQuery.of(context).padding.bottom + 90,
          ),
          itemCount: 5,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            return const AppCard(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          AppShimmer(width: 100, height: 15),
                          SizedBox(width: 8),
                          AppShimmer(width: 50, height: 15, borderRadius: 6),
                        ],
                      ),
                      SizedBox(height: 8),
                      AppShimmer(width: 160, height: 13),
                    ],
                  ),
                  AppShimmer(width: 80, height: 16),
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
                  Icon(
                    Icons.history_rounded,
                    size: 48,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Belum ada riwayat transaksi',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Semua transaksi kasir akan tercatat di sini',
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              MediaQuery.of(context).padding.bottom + 90,
            ),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final tx = list[index];
              final total = tx.transaction.totalAmount;
              final count = tx.items.fold(0, (sum, i) => sum + i.qty);
              final dateStr = _formatDateTime(tx.transaction.createdAt);
              final method = tx.transaction.paymentMethod.toUpperCase();

              return RepaintBoundary(
                child: AppCard(
                  onTap: () => _showDetailDialog(context, ref, tx),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Transaksi #${tx.transaction.id}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                AppStatusBadge(
                                  label: method,
                                  color: method == 'TUNAI'
                                      ? Colors.green
                                      : const Color(0xFF0F172A),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '$count Item • $dateStr',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'Rp ${formatRupiah(total)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.primary,
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
    );
  }
}
