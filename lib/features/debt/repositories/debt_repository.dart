import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dodolanku/core/database_service.dart';
import 'package:dodolanku/features/debt/models/debt_model.dart';

final debtRepositoryProvider = Provider<DebtRepository>((ref) {
  return DebtRepositoryImpl(ref.read(databaseServiceProvider));
});

abstract class DebtRepository {
  Future<List<DebtNote>> getDebtNotes();
  Future<int> insertDebtNote({
    required String debtorName,
    required double amount,
    String? description,
    String? dueDate,
  });
  Future<void> addDebtPayment(int id, double payment);
  Future<void> settleDebt(int id);
  Future<void> deleteDebtNote(int id);
}

class DebtRepositoryImpl implements DebtRepository {
  final DatabaseService _dbService;

  DebtRepositoryImpl(this._dbService);

  @override
  Future<List<DebtNote>> getDebtNotes() async {
    final list = await _dbService.getDebtNotes();
    return list.map((m) => DebtNote.fromMap(m)).toList();
  }

  @override
  Future<int> insertDebtNote({
    required String debtorName,
    required double amount,
    String? description,
    String? dueDate,
  }) async {
    return await _dbService.insertDebtNote(
      debtorName: debtorName,
      amount: amount,
      description: description,
      dueDate: dueDate,
    );
  }

  @override
  Future<void> addDebtPayment(int id, double payment) async {
    await _dbService.addDebtPayment(id, payment);
  }

  @override
  Future<void> settleDebt(int id) async {
    await _dbService.settleDebt(id);
  }

  @override
  Future<void> deleteDebtNote(int id) async {
    await _dbService.deleteDebtNote(id);
  }
}
