import 'package:sqflite/sqflite.dart';

class DatabaseSeeders {
  static Future<void> runSeeders(Database db) async {
    // Seed default receipt config
    await db.execute('''
      INSERT OR IGNORE INTO receipt_config (id, store_name, store_address, footer_msg)
      VALUES (1, 'dodolanku', 'Jl. Raya dodolanku No. 1', 'Terima Kasih')
    ''');
  }
}
