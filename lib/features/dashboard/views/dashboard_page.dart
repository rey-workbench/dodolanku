import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dodolanku/features/scanner/repositories/product_repository.dart';
import 'package:dodolanku/features/dashboard/providers/dashboard_provider.dart';
import 'package:dodolanku/core/utils/currency_formatter.dart';
import 'package:dodolanku/core/widgets/app_widgets.dart';
import 'package:dodolanku/features/settings/providers/profile_provider.dart';

class _LowStockLimitNotifier extends Notifier<int> {
  @override
  int build() => 3;
  
  void setLimit(int value) => state = value;
}

final _lowStockLimitProvider = NotifierProvider<_LowStockLimitNotifier, int>(
  _LowStockLimitNotifier.new,
);

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: dashboardAsync.when(
          loading: () => SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).padding.bottom + 90),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const AppShimmer(width: 40, height: 40, borderRadius: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                AppShimmer(width: 100, height: 14),
                                SizedBox(height: 6),
                                AppShimmer(width: 160, height: 18),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                const AppShimmer(width: double.infinity, height: 120, borderRadius: 20),
                const SizedBox(height: 20),
                Row(
                  children: const [
                    Expanded(child: AppShimmer(width: double.infinity, height: 100, borderRadius: 20)),
                    SizedBox(width: 16),
                    Expanded(child: AppShimmer(width: double.infinity, height: 100, borderRadius: 20)),
                  ],
                ),
                const SizedBox(height: 28),
                const AppShimmer(width: 120, height: 20),
                const SizedBox(height: 16),
                Row(
                  children: const [
                    AppShimmer(width: 140, height: 160, borderRadius: 16),
                    SizedBox(width: 16),
                    AppShimmer(width: 140, height: 160, borderRadius: 16),
                  ],
                ),
              ],
            ),
          ),
          error: (err, stack) => Center(child: Text('Error: $err')),
          data: (data) {
            final percentageDiff = data.percentageDiff;
            final isIncrease = percentageDiff >= 0;

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).padding.bottom + 90),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.grey[300],
                              child: const Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ref.watch(profileProvider).storeName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    () {
                                      final hour = DateTime.now().hour;
                                      final name = ref.watch(profileProvider).storeName;
                                      if (hour >= 0 && hour < 5) {
                                        return 'Begadang?, $name';
                                      } else if (hour >= 5 && hour < 11) {
                                        return 'Semangat Pagi, $name';
                                      } else if (hour >= 11 && hour < 15) {
                                        return 'Sudah makan siang, $name?';
                                      } else if (hour >= 15 && hour < 18) {
                                        return 'Ngopi sore dulu, $name';
                                      } else {
                                        return 'Malam, $name! Tetap semangat!';
                                      }
                                    }(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          IconButton.filledTonal(
                            onPressed: () {},
                            icon: const Icon(Icons.search),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filledTonal(
                            onPressed: () {},
                            icon: const Icon(Icons.notifications_outlined),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Total Earnings Banner
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A), // Premium Dark Slate (slate-900)
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isIncrease
                                        ? Icons.trending_up
                                        : Icons.trending_down,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${isIncrease ? '+' : ''}${percentageDiff.toStringAsFixed(1)}%',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Total Pendapatan (Hari Ini)',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'Rp ${formatRupiah(data.totalToday)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Stats
                  Row(
                    children: [
                      Expanded(
                        child: AppStatCard(
                          title: 'Transaksi Hari Ini',
                          count: '${data.countToday}',
                          subtext: 'Kemarin: ${data.countYesterday} transaksi',
                          color: Theme.of(context).colorScheme.primary,
                          icon: Icons.shopping_bag_outlined,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: AppStatCard(
                          title: 'Total Omzet Kemarin',
                          count: 'Rp ${formatRupiah(data.totalYesterday)}',
                          subtext: 'Bandingkan dengan hari ini',
                          color: const Color(0xFF64748B), // Neutral Slate (slate-500)
                          icon: Icons.analytics_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Popular Products
                  AppSectionHeader(title: 'Produk Terlaris', onAction: () {}),
                  const SizedBox(height: 16),
                  if (data.topProducts.isEmpty)
                    Container(
                      height: 100,
                      width: double.infinity,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Text(
                        'Belum ada data penjualan hari ini',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    )
                  else
                    SizedBox(
                      height: 180,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: data.topProducts.length,
                        itemBuilder: (context, index) {
                          final prod = data.topProducts[index];
                          final name = prod.productName;
                          final totalQty = prod.totalQty;
                          return RepaintBoundary(
                            child: AppProductCard(
                              title: name,
                              price: '$totalQty terjual',
                              icon: Icons.shopping_bag,
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 28),

                  // Out of Stock / Low Stock
                  AppSectionHeader(title: 'Stok Hampir Habis', onAction: () {}),
                  const SizedBox(height: 16),
                  if (data.totalProducts == 0)
                    Container(
                      padding: const EdgeInsets.all(16),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: const Text(
                        'Belum ada produk di gudang.',
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else if (data.lowStockProducts.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, color: Colors.green, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Semua stok produk aman!',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    (() {
                      final limit = ref.watch(_lowStockLimitProvider);
                      final displayedProducts = data.lowStockProducts.take(limit).toList();
                      return Column(
                        children: [
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: displayedProducts.length,
                            itemBuilder: (context, index) {
                              final prod = displayedProducts[index];
                              final name = prod.name;
                              final stock = prod.stock;
                              final barcode = prod.barcode;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: RepaintBoundary(
                                  child: AppAlertCard(
                                    icon: Icons.warning_amber_rounded,
                                    title: name,
                                    subtitle: 'Tersisa $stock item di gudang',
                                    actionLabel: 'Isi Stok',
                                    onAction: () => showProductFormModal(
                                      context: context,
                                      initialBarcode: barcode,
                                      initialName: name,
                                      initialStock: stock,
                                      title: 'Update Stok Cepat',
                                      subtitle: 'Produk: $name (Stok saat ini: $stock)',
                                      onSave: ({
                                        required String barcode,
                                        required String name,
                                        required double price,
                                        required int stock,
                                      }) async {
                                        final productRepo = ref.read(productRepositoryProvider);
                                        await productRepo.updatePriceAndStock(
                                          barcode,
                                          price: price,
                                          stock: stock,
                                        );
                                        ref.invalidate(dashboardProvider);
                                        if (context.mounted) {
                                          AppToast.show(
                                            context,
                                            message: 'Stok $name berhasil diperbarui',
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                          if (data.lowStockProducts.length > 3)
                            Center(
                              child: TextButton.icon(
                                onPressed: () {
                                  if (limit >= data.lowStockProducts.length) {
                                    ref.read(_lowStockLimitProvider.notifier).setLimit(3);
                                  } else {
                                    ref.read(_lowStockLimitProvider.notifier).setLimit(data.lowStockProducts.length);
                                  }
                                },
                                icon: Icon(
                                  limit >= data.lowStockProducts.length
                                      ? Icons.keyboard_arrow_up
                                      : Icons.keyboard_arrow_down,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                label: Text(
                                  limit >= data.lowStockProducts.length
                                      ? 'Sembunyikan'
                                      : 'Tampilkan Lebih Banyak (${data.lowStockProducts.length - displayedProducts.length} lagi)',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    }()),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
