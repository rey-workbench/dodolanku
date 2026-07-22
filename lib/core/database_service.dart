import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:dodolanku/core/config/app_config.dart';
import 'package:dodolanku/core/services/network_service.dart';

import 'package:dodolanku/core/database/database_schema.dart';
import 'package:dodolanku/core/database/database_migrations.dart';
import 'package:dodolanku/core/database/database_seeders.dart';

class DatabaseService {
  Database? _db;
  Database? _globalDb;

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
          // BUG-005 fix: log error agar bisa dideteksi saat debugging
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

      // 1. Create tables & indexes from Schema (must run BEFORE migrations)
      for (final query in DatabaseSchema.createTablesQueries) {
        await db.execute(query);
      }
      for (final query in DatabaseSchema.createIndexesQueries) {
        await db.execute(query);
      }

      // 2. Run migrations (ALTER TABLE, etc) — tables must exist first
      await DatabaseMigrations.runMigrations(db);

      // 3. Seed default data
      await DatabaseSeeders.runSeeders(db);

      // Only assign the global _db instance when ALL migrations are successfully applied
      _db = db;

      // Inisialisasi pendengar otomatis koneksi internet
      _initAutoNetworkSync();
    } catch (e) {
      throw Exception('Gagal memuat database: $e');
    }
  }

  void _initAutoNetworkSync() {
    NetworkService.instance.listenConnectionChange((hasConnection) async {
      if (hasConnection) {
        // Otomatis jalankan sinkronisasi 2 arah saat HP mendapatkan paket data / WiFi
        try {
          await syncMasterProductsFromTurso();
        } catch (_) {}
      }
    });
  }

  // ─────────────────────────────────────────────
  // RECEIPT CONFIG
  // ─────────────────────────────────────────────

  Future<Map<String, dynamic>> getReceiptConfig() async {
    if (_db == null) {
      return {
        'store_name': 'dodolanku',
        'store_address': 'Jl. Raya dodolanku No. 1',
        'store_phone': '',
        'qris_data': '',
        'header_msg': '',
        'footer_msg': 'Terima Kasih',
      };
    }
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
    if (rows.isNotEmpty) {
      return rows.first;
    }
    return {
      'store_name': 'dodolanku',
      'store_address': 'Jl. Raya dodolanku No. 1',
      'store_phone': '',
      'qris_data': '',
      'header_msg': '',
      'footer_msg': 'Terima Kasih',
    };
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

  // ─────────────────────────────────────────────
  // PRODUCTS
  // ─────────────────────────────────────────────

  Future<Map<String, dynamic>?> getProductDetails(String barcode) async {
    if (_db == null || _globalDb == null) return null;
    final clean = barcode.trim();
    if (clean.isEmpty) return null;

    // Check local db first
    final localRows = await _db!.query(
      'products',
      columns: ['barcode', 'name', 'price', 'stock'],
      where: 'barcode = ?',
      whereArgs: [clean],
    );
    if (localRows.isNotEmpty) {
      return localRows.first;
    }

    // Check global db if not found
    final globalRows = await _globalDb!.query(
      'products',
      columns: ['barcode', 'name'],
      where: 'barcode = ?',
      whereArgs: [clean],
    );
    if (globalRows.isNotEmpty) {
      return globalRows.first;
    }

    return null;
  }

  /// Mengirim (push) 1 produk baru secara async ke Turso Cloud tanpa menghambat UI.
  Future<void> _pushSingleProductToTurso(String barcode, String name) async {
    try {
      final tursoUrl = dotenv.env['TURSO_DATABASE_URL'];
      final tursoToken = dotenv.env['TURSO_AUTH_TOKEN'];
      if (tursoUrl == null ||
          tursoUrl.isEmpty ||
          tursoToken == null ||
          tursoToken.isEmpty) {
        return;
      }

      final httpUrl =
          '${tursoUrl.replaceFirst('libsql://', 'https://')}/v2/pipeline';
      final cleanBc = barcode.trim();
      final cleanName = name.trim();
      if (cleanBc.isEmpty || cleanName.isEmpty) return;

      await http
          .post(
            Uri.parse(httpUrl),
            headers: {
              'Authorization': 'Bearer $tursoToken',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              "requests": [
                {
                  "type": "execute",
                  "stmt": {
                    "sql":
                        "INSERT INTO masterproduct (barcode, name) VALUES (?, ?) ON CONFLICT(barcode) DO UPDATE SET name = excluded.name",
                    "args": [
                      {"type": "text", "value": cleanBc},
                      {"type": "text", "value": cleanName},
                    ],
                  },
                },
                {"type": "close"},
              ],
            }),
          )
          .timeout(const Duration(seconds: 20));
    } catch (_) {
      // Abaikan error jaringan secara silent agar input lokal pengguna tidak terganggu
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

    // Otomatis PUSH ke Turso Cloud di background saat user tambah produk baru
    _pushSingleProductToTurso(cleanBc, cleanName);
  }

  /// Update nama, harga, dan/atau stok produk yang sudah terdaftar.
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

    // Jika nama diperbarui, otomatis update ke Turso Cloud di background
    if (data.containsKey('name')) {
      _pushSingleProductToTurso(cleanBc, data['name']);
    }
  }

  /// Produk dengan stok <= [threshold], hanya yang sudah dikonfigurasi (price > 0).
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

  /// Generate kode otomatis untuk produk tanpa barcode (misal NOBC-0001, NOBC-0002).
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

  // ─────────────────────────────────────────────
  // TRANSACTIONS
  // ─────────────────────────────────────────────

  /// Simpan transaksi beserta item-itemnya.
  /// Returns id transaksi yang baru dibuat.
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
        'status': 'selesai',
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

  /// Daftar transaksi terbaru (newest first).
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

  /// Item-item dalam satu transaksi.
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

  // ─────────────────────────────────────────────
  // DASHBOARD ANALYTICS
  // ─────────────────────────────────────────────

  /// Ringkasan dashboard hari ini vs kemarin.
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
      "SELECT COALESCE(SUM(total_amount),0) AS total, COUNT(*) AS cnt FROM transactions WHERE created_at LIKE ? AND status='selesai'",
      ['$todayStr%'],
    );
    final yestRows = await _db!.rawQuery(
      "SELECT COALESCE(SUM(total_amount),0) AS total, COUNT(*) AS cnt FROM transactions WHERE created_at LIKE ? AND status='selesai'",
      ['$yestStr%'],
    );

    return {
      'totalToday': (todayRows.first['total'] as num?)?.toDouble() ?? 0.0,
      'countToday': (todayRows.first['cnt'] as num?)?.toInt() ?? 0,
      'totalYesterday': (yestRows.first['total'] as num?)?.toDouble() ?? 0.0,
      'countYesterday': (yestRows.first['cnt'] as num?)?.toInt() ?? 0,
    };
  }

  /// Produk terlaris berdasarkan total qty terjual.
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

  // ─────────────────────────────────────────────
  // DEBT NOTES
  // ─────────────────────────────────────────────

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

  // ─────────────────────────────────────────────

  /// Menyinkronkan data Dua Arah (Two-Way Sync):
  /// 1. Ambil dari Turso -> Merge ke Lokal HP (yang belum ada di lokal)
  /// 2. Ambil dari Lokal HP -> Upload & Insert ke Turso (yang belum ada di Turso Cloud)
  Future<int> syncMasterProductsFromTurso() async {
    final tursoUrl = dotenv.env['TURSO_DATABASE_URL'];
    final tursoToken = dotenv.env['TURSO_AUTH_TOKEN'];

    if (tursoUrl == null ||
        tursoUrl.isEmpty ||
        tursoToken == null ||
        tursoToken.isEmpty) {
      // Jika kredensial Turso di .env belum diisi, fallback ke offline sync
      return await syncMasterProductsToLocal();
    }

    final httpUrl = tursoUrl.replaceFirst('libsql://', 'https://');
    final pipelineEndpoint = '$httpUrl/v2/pipeline';

    // ── ARAH 1: PULL DARI TURSO -> MERGE KE LOKAL ──
    final response = await http
        .post(
          Uri.parse(pipelineEndpoint),
          headers: {
            'Authorization': 'Bearer $tursoToken',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            "requests": [
              {
                "type": "execute",
                "stmt": {"sql": "SELECT barcode, name FROM masterproduct"},
              },
              {"type": "close"},
            ],
          }),
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw Exception(
        'Gagal menghubungi Turso API (${response.statusCode}): ${response.body}',
      );
    }

    final data = jsonDecode(response.body);
    final results = data['results'] as List?;
    if (results == null || results.isEmpty) return 0;

    final firstResult = results.first;
    final responseBody = firstResult['response'];
    final resultObj = responseBody?['result'];
    final rows = resultObj?['rows'] as List?;

    final tursoBarcodes = <String>{};
    int newFromTursoCount = 0;

    if (rows != null && rows.isNotEmpty && _db != null) {
      await _db!.transaction((txn) async {
        final batch = txn.batch();
        for (final row in rows) {
          final barcode = row[0]?['value']?.toString().trim();
          final name = row[1]?['value']?.toString().trim();
          if (barcode != null &&
              barcode.isNotEmpty &&
              name != null &&
              name.isNotEmpty) {
            tursoBarcodes.add(barcode);
            batch.rawInsert(
              '''
              INSERT OR IGNORE INTO products (barcode, name, price, stock)
              VALUES (?, ?, 0.0, 0)
              ''',
              [barcode, name],
            );
          }
        }
        final batchRes = await batch.commit(noResult: false);
        newFromTursoCount = batchRes.where((r) => r is int && r > 0).length;
      });
    }

    // ── ARAH 2: PUSH DARI LOKAL -> MERGE KE TURSO CLOUD ──
    if (_db != null) {
      final localProducts = await _db!.query(
        'products',
        columns: ['barcode', 'name'],
        where:
            'barcode IS NOT NULL AND barcode != "" AND name IS NOT NULL AND name != ""',
      );

      final toPush = <Map<String, String>>[];
      for (final p in localProducts) {
        final barcode = (p['barcode'] as String?)?.trim();
        final name = (p['name'] as String?)?.trim();
        if (barcode != null &&
            barcode.isNotEmpty &&
            name != null &&
            name.isNotEmpty) {
          if (!tursoBarcodes.contains(barcode)) {
            toPush.add({'barcode': barcode, 'name': name});
          }
        }
      }

      if (toPush.isNotEmpty) {
        // Batch upload ke Turso Cloud (maksimal 200 items per request HTTP)
        const batchSize = 200;
        for (var i = 0; i < toPush.length; i += batchSize) {
          final chunk = toPush.skip(i).take(batchSize).toList();
          final pushRequests = chunk.map((item) {
            return {
              "type": "execute",
              "stmt": {
                "sql":
                    "INSERT OR IGNORE INTO masterproduct (barcode, name) VALUES (?, ?)",
                "args": [
                  {"type": "text", "value": item['barcode']},
                  {"type": "text", "value": item['name']},
                ],
              },
            };
          }).toList();

          pushRequests.add({"type": "close"});

          await http
              .post(
                Uri.parse(pipelineEndpoint),
                headers: {
                  'Authorization': 'Bearer $tursoToken',
                  'Content-Type': 'application/json',
                },
                body: jsonEncode({"requests": pushRequests}),
              )
              .timeout(const Duration(seconds: 20));
        }
      }
    }

    return newFromTursoCount;
  }

  /// Menyinkronkan produk dari Global Master DB (Assets) ke Local DB
  /// Hanya memasukkan (merge) produk dari master yang barcodenya BELUM ada di Local DB.
  Future<int> syncMasterProductsToLocal() async {
    if (_db == null || _globalDb == null) return 0;

    // Ambil semua barcode yang ada di database master
    final globalProducts = await _globalDb!.query(
      'products',
      columns: ['barcode', 'name'],
    );

    if (globalProducts.isEmpty) return 0;

    int newItemsCount = 0;

    // Gunakan transaksi batch untuk kecepatan tinggi (Insert Ribuan Data dalam beberapa milidetik)
    await _db!.transaction((txn) async {
      final batch = txn.batch();

      for (final item in globalProducts) {
        final barcode = (item['barcode'] as String?)?.trim();
        final name = (item['name'] as String?)?.trim();

        if (barcode == null || barcode.isEmpty || name == null || name.isEmpty) {
          continue;
        }

        // INSERT OR IGNORE: memasukkan data HANYA jika barcode belum ada di local db
        batch.rawInsert(
          '''
          INSERT OR IGNORE INTO products (barcode, name, price, stock)
          VALUES (?, ?, 0.0, 0)
          ''',
          [barcode, name],
        );
      }

      final results = await batch.commit(noResult: false);
      // Hitung jumlah baris yang berhasil di-insert (result > 0)
      newItemsCount = results.where((r) => r is int && r > 0).length;
    });

    return newItemsCount;
  }

  /// Mendapatkan jumlah item di Master Database Global (global_product.db asset)
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
    NetworkService.instance.dispose();
    _db?.close();
    _globalDb?.close();
  }
}
