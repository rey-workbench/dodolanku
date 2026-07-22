import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dodolanku/core/database_service.dart';
import 'package:dodolanku/core/services/print_service.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepositoryImpl(ref.read(databaseServiceProvider));
});

abstract class SettingsRepository {
  Future<Map<String, dynamic>> getReceiptConfig();
  Future<void> updateReceiptConfig({
    required String storeName,
    required String storeAddress,
    String? storePhone,
    String? qrisData,
    String? headerMsg,
    String? footerMsg,
  });

  bool getIsAutoPrint();
  void setAutoPrint(bool value);
  String getPaperSize();
  void setPaperSize(String value);
}

class SettingsRepositoryImpl implements SettingsRepository {
  final DatabaseService _dbService;

  SettingsRepositoryImpl(this._dbService);

  @override
  Future<Map<String, dynamic>> getReceiptConfig() async {
    await _dbService.initDb();
    return await _dbService.getReceiptConfig();
  }

  @override
  Future<void> updateReceiptConfig({
    required String storeName,
    required String storeAddress,
    String? storePhone,
    String? qrisData,
    String? headerMsg,
    String? footerMsg,
  }) async {
    await _dbService.initDb();
    await _dbService.updateReceiptConfig(
      storeName: storeName,
      storeAddress: storeAddress,
      storePhone: storePhone,
      qrisData: qrisData,
      headerMsg: headerMsg,
      footerMsg: footerMsg ?? 'Terima Kasih',
    );
  }

  @override
  bool getIsAutoPrint() => PrintService.instance.isAutoPrintEnabled;

  @override
  void setAutoPrint(bool value) => PrintService.instance.setAutoPrint(value);

  @override
  String getPaperSize() => PrintService.instance.paperSize;

  @override
  void setPaperSize(String value) => PrintService.instance.setPaperSize(value);
}
