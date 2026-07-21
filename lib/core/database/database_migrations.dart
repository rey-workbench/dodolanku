import 'package:sqflite/sqflite.dart';

class DatabaseMigrations {
  /// Daftar script migrasi. Mengecek keberadaan kolom terlebih dahulu
  static Future<void> runMigrations(Database db) async {
    // Ambil info kolom dari tabel products
    final List<Map<String, dynamic>> tableInfo = await db.rawQuery("PRAGMA table_info(products)");
    
    final bool hasPrice = tableInfo.any((column) => column['name'] == 'price');
    final bool hasStock = tableInfo.any((column) => column['name'] == 'stock');

    if (!hasPrice) {
      try {
        await db.execute("ALTER TABLE products ADD COLUMN price REAL DEFAULT 0.0");
      } catch (_) {}
    }
    if (!hasStock) {
      try {
        await db.execute("ALTER TABLE products ADD COLUMN stock INTEGER DEFAULT 0");
      } catch (_) {}
    }

    final List<Map<String, dynamic>> rcInfo = await db.rawQuery("PRAGMA table_info(receipt_config)");
    final bool hasPhone = rcInfo.any((column) => column['name'] == 'store_phone');
    if (!hasPhone) {
      try {
        await db.execute("ALTER TABLE receipt_config ADD COLUMN store_phone TEXT DEFAULT ''");
      } catch (_) {}
    }
    final bool hasQris = rcInfo.any((column) => column['name'] == 'qris_data');
    if (!hasQris) {
      try {
        await db.execute("ALTER TABLE receipt_config ADD COLUMN qris_data TEXT DEFAULT ''");
      } catch (_) {}
    }
  }
}
