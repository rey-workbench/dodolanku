import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dodolanku/core/database_service.dart';
import 'package:dodolanku/core/models/transaction_model.dart';
import 'package:dodolanku/features/orders/repositories/transaction_repository.dart';

class TransactionWithItems {
  final TransactionModel transaction;
  final List<TransactionItemModel> items;

  TransactionWithItems({required this.transaction, required this.items});
}

class OrdersNotifier extends AsyncNotifier<List<TransactionWithItems>> {
  @override
  Future<List<TransactionWithItems>> build() async {
    
    ref.watch(salesDataVersionProvider);

    
    final dbService = ref.read(databaseServiceProvider);
    await dbService.initDb();

    final txRepo = ref.read(transactionRepositoryProvider);
    final txs = await txRepo.getTransactions(limit: 50);

    
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
