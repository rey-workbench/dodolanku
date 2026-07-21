import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dodolanku/core/models/transaction_model.dart';
import 'package:dodolanku/features/orders/repositories/transaction_repository.dart';
import 'package:dodolanku/features/scanner/providers/scanner_provider.dart';

class TransactionWithItems {
  final TransactionModel transaction;
  final List<TransactionItemModel> items;

  TransactionWithItems({required this.transaction, required this.items});
}

class OrdersNotifier extends AsyncNotifier<List<TransactionWithItems>> {
  @override
  Future<List<TransactionWithItems>> build() async {
    final scannerState = ref.watch(scannerProvider);
    if (scannerState.isLoading) {
      return [];
    }

    final txRepo = ref.read(transactionRepositoryProvider);
    final txs = await txRepo.getTransactions(limit: 50);
    
    // Gunakan Future.wait agar query items berjalan paralel (Fix N+1 sequential bottleneck)
    final results = await Future.wait(txs.map((tx) async {
      final id = tx.id;
      if (id != null) {
        final items = await txRepo.getTransactionItems(id);
        return TransactionWithItems(transaction: tx, items: items);
      }
      return TransactionWithItems(transaction: tx, items: []);
    }));
    
    return results.where((r) => r.transaction.id != null).toList();
  }
}

final ordersProvider = AsyncNotifierProvider.autoDispose<OrdersNotifier, List<TransactionWithItems>>(() {
  return OrdersNotifier();
});
