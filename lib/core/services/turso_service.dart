import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:dodolanku/core/utils/barcode_validator.dart';

class TursoService {
  TursoService._();
  static final TursoService instance = TursoService._();

  bool get isConfigured {
    final url = dotenv.env['TURSO_DATABASE_URL'];
    final token = dotenv.env['TURSO_AUTH_TOKEN'];
    return url != null &&
        url.isNotEmpty &&
        token != null &&
        token.isNotEmpty;
  }

  Uri get _pipelineEndpoint {
    final url = dotenv.env['TURSO_DATABASE_URL']!;
    return Uri.parse(
      '${url.replaceFirst('libsql://', 'https://')}/v2/pipeline',
    );
  }

  Map<String, String> get _headers => {
        'Authorization': 'Bearer ${dotenv.env['TURSO_AUTH_TOKEN']}',
        'Content-Type': 'application/json',
      };

  Future<void> _postPipeline(List<Map<String, dynamic>> requests) async {
    try {
      await http
          .post(
            _pipelineEndpoint,
            headers: _headers,
            body: jsonEncode({"requests": requests}),
          )
          .timeout(const Duration(seconds: 60));
    } catch (e) {
      throw Exception('Gagal mengirim data ke Turso Cloud ($e)');
    }
  }

  /// Menarik seluruh master produk dari Turso Cloud.
  /// Hanya mengembalikan barcode ritel standar yang valid dan nama yang tersanitasi.
  Future<List<Map<String, String>>> pullProducts() async {
    try {
      final response = await http.post(
        _pipelineEndpoint,
        headers: _headers,
        body: jsonEncode({
          "requests": [
            {"type": "execute", "stmt": {"sql": "SELECT barcode, name FROM masterproduct"}},
            {"type": "close"},
          ],
        }),
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode != 200) {
        throw Exception(
          'Turso API mengembalikan status ${response.statusCode}',
        );
      }

      final data = jsonDecode(response.body);
      final results = data['results'] as List?;
      if (results == null || results.isEmpty) return [];
      final rows = (results.first['response']?['result']?['rows']) as List?;
      if (rows == null) return [];

      final cleanList = <Map<String, String>>[];
      for (final row in rows) {
        final barcode = row[0]?['value']?.toString().trim() ?? '';
        final name = BarcodeValidator.cleanProductName(row[1]?['value']?.toString());
        if (BarcodeValidator.isValidMasterProduct(barcode, name)) {
          cleanList.add({
            'barcode': barcode,
            'name': name,
          });
        }
      }
      return cleanList;
    } catch (e) {
      throw Exception('Gagal mengunduh dari Turso: ${e.toString().replaceAll("Exception: ", "")}');
    }
  }

  /// Mengirim/memperbarui 1 produk ke master katalog Turso Cloud.
  Future<void> pushProduct(String barcode, String name) async {
    await pushProducts([{'barcode': barcode, 'name': name}]);
  }

  /// Mengirim kumpulan produk lokal ke master katalog Turso Cloud secara batch.
  /// Menyaring hanya produk yang memenuhi standar ritel GTIN.
  Future<void> pushProducts(List<Map<String, String>> products) async {
    if (!isConfigured || products.isEmpty) return;

    final validProducts = products.where((p) {
      final bc = p['barcode']?.trim() ?? '';
      final nm = BarcodeValidator.cleanProductName(p['name']);
      return BarcodeValidator.isValidMasterProduct(bc, nm);
    }).map((p) => {
      'barcode': p['barcode']!.trim(),
      'name': BarcodeValidator.cleanProductName(p['name']),
    }).toList();

    if (validProducts.isEmpty) return;

    const batchSize = 200;
    for (var i = 0; i < validProducts.length; i += batchSize) {
      final chunk = validProducts.skip(i).take(batchSize).toList();
      final requests = chunk.map((p) {
        return {
          "type": "execute",
          "stmt": {
            "sql":
                "INSERT INTO masterproduct (barcode, name) VALUES (?, ?) ON CONFLICT(barcode) DO UPDATE SET name = excluded.name",
            "args": [
              {"type": "text", "value": p['barcode']},
              {"type": "text", "value": p['name']},
            ],
          },
        };
      }).toList();
      requests.add({"type": "close"});
      await _postPipeline(requests);
    }
  }
}
