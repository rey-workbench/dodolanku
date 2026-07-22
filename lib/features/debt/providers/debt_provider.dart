import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dodolanku/features/debt/models/debt_model.dart';
import 'package:dodolanku/features/debt/repositories/debt_repository.dart';
import 'package:dodolanku/features/scanner/providers/scanner_provider.dart';

class DebtNotifier extends AsyncNotifier<List<DebtNote>> {
  @override
  Future<List<DebtNote>> build() async {
    // BUG-007 fix: tidak perlu watch scannerProvider hanya untuk tunggu DB init.
    // Gunakan databaseServiceProvider langsung — initDb() bersifat idempotent.
    final dbService = ref.read(databaseServiceProvider);
    await dbService.initDb();

    final repo = ref.read(debtRepositoryProvider);
    return await repo.getDebtNotes();
  }

  Future<void> addDebt({
    required String name,
    required double amount,
    String? description,
    String? dueDate,
  }) async {
    final repo = ref.read(debtRepositoryProvider);
    await repo.insertDebtNote(
      debtorName: name,
      amount: amount,
      description: description,
      dueDate: dueDate,
    );
    ref.invalidateSelf();
  }

  Future<void> payDebt(int id, double amount) async {
    final repo = ref.read(debtRepositoryProvider);
    await repo.addDebtPayment(id, amount);
    ref.invalidateSelf();
  }

  Future<void> settleDebt(int id) async {
    final repo = ref.read(debtRepositoryProvider);
    await repo.settleDebt(id);
    ref.invalidateSelf();
  }

  Future<void> deleteDebt(int id) async {
    final repo = ref.read(debtRepositoryProvider);
    await repo.deleteDebtNote(id);
    ref.invalidateSelf();
  }
}

final debtProvider = AsyncNotifierProvider.autoDispose<DebtNotifier, List<DebtNote>>(() {
  return DebtNotifier();
});
