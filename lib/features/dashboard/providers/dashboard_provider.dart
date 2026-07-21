import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dodolanku/features/dashboard/models/dashboard_stats_model.dart';
import 'package:dodolanku/features/scanner/providers/scanner_provider.dart';
import 'package:dodolanku/features/scanner/repositories/product_repository.dart';
import 'package:dodolanku/features/orders/repositories/transaction_repository.dart';

class DashboardNotifier extends AsyncNotifier<DashboardData> {
  @override
  Future<DashboardData> build() async {
    // Re-fetch statistics when checkout completes or DB updates
    final scannerState = ref.watch(scannerProvider);
    if (scannerState.isLoading) {
      return DashboardData(
        totalToday: 0.0,
        countToday: 0,
        totalYesterday: 0.0,
        countYesterday: 0,
        topProducts: [],
        lowStockProducts: [],
      );
    }

    final productRepo = ref.read(productRepositoryProvider);
    final txRepo = ref.read(transactionRepositoryProvider);

    final stats = await txRepo.getDashboardStats();
    final topRaw = await txRepo.getTopProducts(limit: 5);
    final lowRaw = await productRepo.getLowStockProducts(threshold: 5);
    final totalProducts = await productRepo.getTotalProductsCount();

    return DashboardData(
      totalToday: stats['totalToday'] as double,
      countToday: stats['countToday'] as int,
      totalYesterday: stats['totalYesterday'] as double,
      countYesterday: stats['countYesterday'] as int,
      topProducts: topRaw.map((m) => TopProduct.fromMap(m)).toList(),
      lowStockProducts: lowRaw,
      totalProducts: totalProducts,
    );
  }
}

final dashboardProvider = AsyncNotifierProvider.autoDispose<DashboardNotifier, DashboardData>(() {
  return DashboardNotifier();
});
