import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dodolanku/core/database_service.dart';
import 'package:dodolanku/core/models/transaction_model.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepositoryImpl(ref.read(databaseServiceProvider));
});

abstract class TransactionRepository {
  Future<int> insertTransaction({
    required double totalAmount,
    required String paymentMethod,
    required double amountPaid,
    required double changeAmount,
    required List<TransactionItemModel> items,
  });
  Future<List<TransactionModel>> getTransactions({int limit = 50});
  Future<List<TransactionItemModel>> getTransactionItems(int transactionId);
  Future<Map<String, dynamic>> getDashboardStats();
  Future<List<Map<String, dynamic>>> getTopProducts({int limit = 5});
  Future<void> deleteTransaction(int transactionId, {bool restoreStock = true});
}

class TransactionRepositoryImpl implements TransactionRepository {
  final DatabaseService _dbService;

  TransactionRepositoryImpl(this._dbService);

  @override
  Future<void> deleteTransaction(int transactionId, {bool restoreStock = true}) async {
    await _dbService.deleteTransaction(transactionId, restoreStock: restoreStock);
  }

  @override
  Future<int> insertTransaction({
    required double totalAmount,
    required String paymentMethod,
    required double amountPaid,
    required double changeAmount,
    required List<TransactionItemModel> items,
  }) async {
    final rawItems = items.map((item) => item.toMap()).toList();
    return await _dbService.insertTransaction(
      totalAmount: totalAmount,
      paymentMethod: paymentMethod,
      amountPaid: amountPaid,
      changeAmount: changeAmount,
      items: rawItems,
    );
  }

  @override
  Future<List<TransactionModel>> getTransactions({int limit = 50}) async {
    final list = await _dbService.getTransactions(limit: limit);
    return list.map((m) => TransactionModel.fromMap(m)).toList();
  }

  @override
  Future<List<TransactionItemModel>> getTransactionItems(int transactionId) async {
    final list = await _dbService.getTransactionItems(transactionId);
    return list.map((m) => TransactionItemModel.fromMap(m)).toList();
  }

  @override
  Future<Map<String, dynamic>> getDashboardStats() async {
    return await _dbService.getDashboardStats();
  }

  @override
  Future<List<Map<String, dynamic>>> getTopProducts({int limit = 5}) async {
    return await _dbService.getTopProducts(limit: limit);
  }
}
