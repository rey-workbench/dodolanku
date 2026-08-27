import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dodolanku/core/config/app_config.dart';
import 'package:dodolanku/core/models/transaction_model.dart';
import 'package:dodolanku/core/services/network_service.dart';
import 'package:dodolanku/core/services/turso_service.dart';

import 'package:dodolanku/core/database/database_schema.dart';
import 'package:dodolanku/core/database/database_migrations.dart';
import 'package:dodolanku/core/database/database_seeders.dart';


final databaseServiceProvider = Provider<DatabaseService>((ref) {
  final service = DatabaseService();
  ref.onDispose(() => service.dispose());
  return service;
});




class SalesDataVersionNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void increment() => state++;
}

final salesDataVersionProvider =
    NotifierProvider<SalesDataVersionNotifier, int>(SalesDataVersionNotifier.new);

class DatabaseService {
  Database? _db;
  Database? _globalDb;
  final TursoService _turso = TursoService.instance;

  Future<void> initDb() async {
    if (_db != null) return;
    try {
      var databasesPath = await getDatabasesPath();
      var globalPath = join(databasesPath, DatabaseConfig.globalDbName);
      var localPath = join(databasesPath, DatabaseConfig.localDbName);

      Future<void> copyGlobalDb() async {
        try {
          await Directory(dirname(globalPath)).create(recursive: true);
          ByteData data = await rootBundle.load(DatabaseConfig.assetDbPath);
          List<int> bytes = data.buffer.asUint8List(
            data.offsetInBytes,
            data.lengthInBytes,
          );
          await File(globalPath).writeAsBytes(bytes, flush: true);
        } catch (e) {
          
          debugPrint('[DatabaseService] Gagal menyalin global_product.db dari asset: $e');
        }
      }

      if (!await databaseExists(globalPath)) {
        await copyGlobalDb();
      }

      if (await databaseExists(globalPath)) {
        try {
          _globalDb = await openDatabase(globalPath);
        } catch (_) {}
      }

      Database db = await openDatabase(localPath);
      try {
        await db.rawQuery('PRAGMA journal_mode = WAL;');
      } catch (_) {}

      
      for (final query in DatabaseSchema.createTablesQueries) {
        await db.execute(query);
      }
      for (final query in DatabaseSchema.createIndexesQueries) {
        await db.execute(query);
      }

      
      await DatabaseMigrations.runMigrations(db);

      
      await DatabaseSeeders.runSeeders(db);

      
      _db = db;

      
      _initAutoNetworkSync();
    } catch (e) {
      throw Exception('Gagal memuat database: $e');
    }
  }

  void _initAutoNetworkSync() {
    NetworkService.instance.listenConnectionChange((hasConnection) async {
      if (hasConnection) {
        
        try {
          await syncMasterProductsFromTurso();
        } catch (_) {}
      }
    });
  }

  
  
  

  Future<String?> getSetting(String key) async {
    if (_db == null) return null;
    final rows = await _db!.query(
      'app_settings',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
    );
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  Future<void> setSetting(String key, String value) async {
    if (_db == null) return;
    await _db!.insert(
      'app_settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  
  
  

  Future<Map<String, dynamic>> getReceiptConfig() async {
    final Map<String, dynamic> fallback = {
      'store_name': DatabaseConfig.defaultStoreName,
      'store_address': DatabaseConfig.defaultStoreAddress,
      'store_phone': DatabaseConfig.defaultStorePhone,
      'qris_data': DatabaseConfig.defaultQrisData,
      'header_msg': DatabaseConfig.defaultHeaderMsg,
      'footer_msg': DatabaseConfig.defaultFooterMsg,
    };
    if (_db == null) return fallback;
    final rows = await _db!.query(
      'receipt_config',
      columns: [
        'store_name',
        'store_address',
        'store_phone',
        'qris_data',
        'header_msg',
        'footer_msg',
      ],
      where: 'id = 1',
    );
    return rows.isNotEmpty ? rows.first : fallback;
  }

  Future<void> updateReceiptConfig({
    required String storeName,
    required String storeAddress,
    String? storePhone,
    String? qrisData,
    String? headerMsg,
    required String footerMsg,
  }) async {
    if (_db == null) throw Exception('Database belum siap');
    await _db!.insert('receipt_config', {
      'id': 1,
      'store_name': storeName.trim(),
      'store_address': storeAddress.trim(),
      'store_phone': storePhone?.trim() ?? '',
      'qris_data': qrisData?.trim() ?? '',
      'header_msg': headerMsg?.trim() ?? '',
      'footer_msg': footerMsg.trim(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  
  
  

  Future<Map<String, dynamic>?> getProductDetails(String barcode) async {
    
    if (_db == null) return null;
    final clean = barcode.trim();
    if (clean.isEmpty) return null;

    
    final localRows = await _db!.query(
      'products',
      columns: ['barcode', 'name', 'price', 'stock'],
      where: 'barcode = ?',
      whereArgs: [clean],
    );
    if (localRows.isNotEmpty) {
      return localRows.first;
    }

    
    if (_globalDb != null) {
      final globalRows = await _globalDb!.query(
        'products',
        columns: ['barcode', 'name'],
        where: 'barcode = ?',
        whereArgs: [clean],
      );
      if (globalRows.isNotEmpty) {
        return globalRows.first;
      }
    }

    return null;
  }

  
  Future<void> _tryPushToTurso(String barcode, String name) async {
    final cleanBc = barcode.trim();
    final cleanName = name.trim();
    if (cleanBc.isEmpty || cleanName.isEmpty) return;
    try {
      await _turso.pushProduct(cleanBc, cleanName);
    } catch (_) {
      
    }
  }

  Future<void> insertProduct(
    String barcode,
    String name,
    double price,
    int stock,
  ) async {
    if (_db == null) throw Exception('Database belum siap');
    final cleanBc = barcode.trim();
    final cleanName = name.trim();
    await _db!.insert('products', {
      'barcode': cleanBc,
      'name': cleanName,
      'price': price,
      'stock': stock,
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    
    _tryPushToTurso(cleanBc, cleanName);
  }

  
  Future<void> updatePriceAndStock(
    String barcode, {
    String? name,
    double? price,
    int? stock,
  }) async {
    if (_db == null) throw Exception('Database belum siap');
    final cleanBc = barcode.trim();
    final data = <String, dynamic>{};
    if (name != null && name.trim().isNotEmpty) {
      data['name'] = name.trim();
    }
    if (price != null) data['price'] = price;
    if (stock != null) data['stock'] = stock;
    if (data.isEmpty) return;

    await _db!.update(
      'products',
      data,
      where: 'barcode = ?',
      whereArgs: [cleanBc],
    );

    
    if (data.containsKey('name')) {
      _tryPushToTurso(cleanBc, data['name']);
    }
  }

  
  Future<List<Map<String, dynamic>>> getLowStockProducts({
    int threshold = 5,
  }) async {
    if (_db == null) return [];
    return await _db!.query(
      'products',
      columns: ['barcode', 'name', 'price', 'stock'],
      where: 'stock <= ? AND price > 0 AND name IS NOT NULL AND name != ""',
      whereArgs: [threshold],
      orderBy: 'stock ASC',
      limit: 10,
    );
  }

  Future<int> getTotalProductsCount() async {
    await initDb();
    if (_db == null) return 0;
    try {
      final result = await _db!.rawQuery('SELECT COUNT(*) FROM products');
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  
  Future<String> getNextNonBarcodeCode() async {
    await initDb();
    if (_db == null) return 'NOBC-0001';
    try {
      final result = await _db!.rawQuery(
        "SELECT barcode FROM products WHERE barcode LIKE 'NOBC-%' ORDER BY LENGTH(barcode) DESC, barcode DESC LIMIT 1",
      );
      if (result.isNotEmpty) {
        final lastBarcode = result.first['barcode'] as String? ?? '';
        final parts = lastBarcode.split('-');
        if (parts.length == 2) {
          final lastNum = int.tryParse(parts[1]) ?? 0;
          final nextNum = lastNum + 1;
          return 'NOBC-${nextNum.toString().padLeft(4, '0')}';
        }
      }
      return 'NOBC-0001';
    } catch (_) {
      return 'NOBC-0001';
    }
  }

  
  
  

  
  
  Future<int> insertTransaction({
    required double totalAmount,
    required String paymentMethod,
    required double amountPaid,
    required double changeAmount,
    required List<Map<String, dynamic>> items,
  }) async {
    if (_db == null) throw Exception('Database belum siap');

    final now = DateTime.now().toIso8601String();

    return await _db!.transaction((txn) async {
      final txId = await txn.insert('transactions', {
        'created_at': now,
        'total_amount': totalAmount,
        'payment_method': paymentMethod,
        'amount_paid': amountPaid,
        'change_amount': changeAmount,
        'status': TransactionModel.statusSelesai,
      });

      final batch = txn.batch();
      for (final item in items) {
        batch.insert('transaction_items', {
          'transaction_id': txId,
          'barcode': item['barcode'],
          'product_name': item['product_name'],
          'price': item['price'],
          'qty': item['qty'],
          'subtotal': item['subtotal'],
        });

        final cleanBarcode = (item['barcode'] as String).trim();
        final qty = item['qty'] as int;
        batch.rawUpdate(
          'UPDATE products SET stock = MAX(0, stock - ?) WHERE barcode = ?',
          [qty, cleanBarcode],
        );
      }
      await batch.commit(noResult: true);

      return txId;
    });
  }

  
  Future<List<Map<String, dynamic>>> getTransactions({int limit = 50}) async {
    if (_db == null) return [];
    return await _db!.query(
      'transactions',
      columns: [
        'id',
        'created_at',
        'total_amount',
        'payment_method',
        'amount_paid',
        'change_amount',
        'status',
      ],
      orderBy: 'created_at DESC',
      limit: limit,
    );
  }

  
  Future<List<Map<String, dynamic>>> getTransactionItems(
    int transactionId,
  ) async {
    if (_db == null) return [];
    return await _db!.query(
      'transaction_items',
      columns: [
        'id',
        'transaction_id',
        'barcode',
        'product_name',
        'price',
        'qty',
        'subtotal',
      ],
      where: 'transaction_id = ?',
      whereArgs: [transactionId],
    );
  }

  
  Future<List<Map<String, dynamic>>> searchProducts(String query) async {
    if (_db == null) return [];
    final q = '%$query%';
    return await _db!.query(
      'products',
      columns: ['barcode', 'name', 'price', 'stock'],
      where: 'name LIKE ? OR barcode LIKE ?',
      whereArgs: [q, q],
      orderBy: 'name ASC',
      limit: 50,
    );
  }

  
  Future<void> deleteTransaction(int transactionId, {bool restoreStock = true}) async {
    if (_db == null) return;
    
    await _db!.transaction((txn) async {
      final batch = txn.batch();

      if (restoreStock) {
        
        final items = await txn.query(
          'transaction_items',
          columns: ['barcode', 'qty'],
          where: 'transaction_id = ?',
          whereArgs: [transactionId],
        );
        
        
        for (final item in items) {
          final barcode = item['barcode'] as String;
          final qty = item['qty'] as int;
          batch.rawUpdate(
            'UPDATE products SET stock = stock + ? WHERE barcode = ?',
            [qty, barcode]
          );
        }
      }
      
      
      batch.delete('transaction_items', where: 'transaction_id = ?', whereArgs: [transactionId]);
      batch.delete('transactions', where: 'id = ?', whereArgs: [transactionId]);
      
      await batch.commit(noResult: true);
    });
  }

  
  
  

  
  Future<Map<String, dynamic>> getDashboardStats() async {
    if (_db == null) {
      return {
        'totalToday': 0.0,
        'countToday': 0,
        'totalYesterday': 0.0,
        'countYesterday': 0,
      };
    }

    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final yesterday = today.subtract(const Duration(days: 1));
    final yestStr =
        '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';

    final todayRows = await _db!.rawQuery(
      "SELECT COALESCE(SUM(total_amount),0) AS total, COUNT(*) AS cnt FROM transactions WHERE created_at LIKE ? AND status='${TransactionModel.statusSelesai}'",
      ['$todayStr%'],
    );
    final yestRows = await _db!.rawQuery(
      "SELECT COALESCE(SUM(total_amount),0) AS total, COUNT(*) AS cnt FROM transactions WHERE created_at LIKE ? AND status='${TransactionModel.statusSelesai}'",
      ['$yestStr%'],
    );

    return {
      'totalToday': (todayRows.first['total'] as num?)?.toDouble() ?? 0.0,
      'countToday': (todayRows.first['cnt'] as num?)?.toInt() ?? 0,
      'totalYesterday': (yestRows.first['total'] as num?)?.toDouble() ?? 0.0,
      'countYesterday': (yestRows.first['cnt'] as num?)?.toInt() ?? 0,
    };
  }

  
  Future<List<Map<String, dynamic>>> getTopProducts({int limit = 5}) async {
    if (_db == null) return [];
    return await _db!.rawQuery(
      '''
      SELECT product_name, barcode, SUM(qty) AS total_qty, SUM(subtotal) AS total_revenue
      FROM transaction_items
      GROUP BY barcode
      ORDER BY total_qty DESC
      LIMIT ?
    ''',
      [limit],
    );
  }

  
  
  

  Future<List<Map<String, dynamic>>> getDebtNotes() async {
    if (_db == null) return [];
    return await _db!.query(
      'debt_notes',
      columns: [
        'id',
        'debtor_name',
        'description',
        'amount',
        'paid',
        'created_at',
        'due_date',
        'is_settled',
      ],
      orderBy: 'is_settled ASC, created_at DESC',
    );
  }

  Future<int> insertDebtNote({
    required String debtorName,
    required double amount,
    String? description,
    String? dueDate,
  }) async {
    if (_db == null) throw Exception('Database belum siap');
    return await _db!.insert('debt_notes', {
      'debtor_name': debtorName.trim(),
      'description': description?.trim(),
      'amount': amount,
      'paid': 0.0,
      'created_at': DateTime.now().toIso8601String(),
      'due_date': dueDate,
      'is_settled': 0,
    });
  }

  Future<void> addDebtPayment(int id, double payment) async {
    if (_db == null) return;
    final rows = await _db!.query(
      'debt_notes',
      columns: ['paid', 'amount'],
      where: 'id = ?',
      whereArgs: [id],
    );
    if (rows.isEmpty) return;
    final current = rows.first;
    final paid = ((current['paid'] as num?)?.toDouble() ?? 0.0) + payment;
    final amount = (current['amount'] as num?)?.toDouble() ?? 0.0;
    await _db!.update(
      'debt_notes',
      {'paid': paid, 'is_settled': paid >= amount ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> settleDebt(int id) async {
    if (_db == null) return;
    await _db!.update(
      'debt_notes',
      {'is_settled': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteDebtNote(int id) async {
    if (_db == null) return;
    await _db!.delete('debt_notes', where: 'id = ?', whereArgs: [id]);
  }

  

  
  
  
  
  Future<int> syncMasterProductsFromTurso() async {
    if (!_turso.isConfigured) {
      
      return await syncMasterProductsToLocal();
    }

    final remote = await _turso.pullProducts(); 
    if (remote.isEmpty || _db == null) return 0;

    final tursoBarcodes = remote.map((p) => p['barcode']!).toSet();
    int newFromTursoCount = 0;

    
    await _db!.transaction((txn) async {
      final batch = txn.batch();
      for (final p in remote) {
        batch.rawInsert(
          '''
          INSERT OR IGNORE INTO products (barcode, name, price, stock)
          VALUES (?, ?, 0.0, 0)
          ''',
          [p['barcode'], p['name']],
        );
      }
      final batchRes = await batch.commit(noResult: false);
      newFromTursoCount = batchRes.where((r) => r is int && r > 0).length;
    });

    
    final localProducts = await _db!.query(
      'products',
      columns: ['barcode', 'name'],
      where:
          'barcode IS NOT NULL AND barcode != "" AND name IS NOT NULL AND name != ""',
    );
    final toPush = localProducts
        .where((p) => !tursoBarcodes.contains(p['barcode']))
        .map((p) => {
              'barcode': p['barcode'] as String,
              'name': p['name'] as String,
            })
        .toList();
    if (toPush.isNotEmpty) {
      await _turso.pushProducts(toPush);
    }

    return newFromTursoCount;
  }

  
  
  Future<int> syncMasterProductsToLocal() async {
    if (_db == null || _globalDb == null) return 0;

    
    final globalProducts = await _globalDb!.query(
      'products',
      columns: ['barcode', 'name'],
    );

    if (globalProducts.isEmpty) return 0;

    int newItemsCount = 0;

    
    await _db!.transaction((txn) async {
      final batch = txn.batch();

      for (final item in globalProducts) {
        final barcode = (item['barcode'] as String?)?.trim();
        final name = (item['name'] as String?)?.trim();

        if (barcode == null || barcode.isEmpty || name == null || name.isEmpty) {
          continue;
        }

        
        batch.rawInsert(
          '''
          INSERT OR IGNORE INTO products (barcode, name, price, stock)
          VALUES (?, ?, 0.0, 0)
          ''',
          [barcode, name],
        );
      }

      final results = await batch.commit(noResult: false);
      
      newItemsCount = results.where((r) => r is int && r > 0).length;
    });

    return newItemsCount;
  }

  
  Future<int> getGlobalProductsCount() async {
    await initDb();
    if (_globalDb == null) return 0;
    try {
      final result = await _globalDb!.rawQuery('SELECT COUNT(*) FROM products');
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  void dispose() {
    
    
    _db?.close();
    _globalDb?.close();
  }

  
  
  Future<void> forceCheckpoint() async {
    if (_db != null) {
      try {
        await _db!.rawQuery('PRAGMA wal_checkpoint(TRUNCATE);');
      } catch (_) {}
    }
  }
}
