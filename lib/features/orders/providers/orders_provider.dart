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
    
    final List<TransactionWithItems> results = [];
    for (final tx in txs) {
      final id = tx.id;
      if (id != null) {
        final items = await txRepo.getTransactionItems(id);
        results.add(TransactionWithItems(transaction: tx, items: items));
      }
    }
    return results;
  }
}

final ordersProvider = AsyncNotifierProvider.autoDispose<OrdersNotifier, List<TransactionWithItems>>(() {
  return OrdersNotifier();
});
