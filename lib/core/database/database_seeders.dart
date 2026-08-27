import 'package:sqflite/sqflite.dart';
import 'package:dodolanku/core/config/app_config.dart';

class DatabaseSeeders {
  static Future<void> runSeeders(Database db) async {
    
    await db.execute('''
      INSERT OR IGNORE INTO receipt_config (id, store_name, store_address, footer_msg)
      VALUES (1, '${DatabaseConfig.defaultStoreName}', '${DatabaseConfig.defaultStoreAddress}', '${DatabaseConfig.defaultFooterMsg}')
    ''');
  }
}
