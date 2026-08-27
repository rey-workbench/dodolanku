import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;



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
    await http
        .post(
          _pipelineEndpoint,
          headers: _headers,
          body: jsonEncode({"requests": requests}),
        )
        .timeout(const Duration(seconds: 20));
  }

  
  
  Future<List<Map<String, String>>> pullProducts() async {
    final response = await http.post(
      _pipelineEndpoint,
      headers: _headers,
      body: jsonEncode({
        "requests": [
          {"type": "execute", "stmt": {"sql": "SELECT barcode, name FROM masterproduct"}},
          {"type": "close"},
        ],
      }),
    ).timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw Exception(
        'Gagal menghubungi Turso API (${response.statusCode}): ${response.body}',
      );
    }

    final data = jsonDecode(response.body);
    final results = data['results'] as List?;
    if (results == null || results.isEmpty) return [];
    final rows = (results.first['response']?['result']?['rows']) as List?;
    if (rows == null) return [];

    return rows.map((row) {
      final barcode = row[0]?['value']?.toString().trim();
      final name = row[1]?['value']?.toString().trim();
      return {
        'barcode': barcode ?? '',
        'name': name ?? '',
      };
    }).where((p) => p['barcode']!.isNotEmpty && p['name']!.isNotEmpty).toList();
  }

  
  Future<void> pushProduct(String barcode, String name) async {
    if (!isConfigured) return;
    await _postPipeline([
      {
        "type": "execute",
        "stmt": {
          "sql":
              "INSERT INTO masterproduct (barcode, name) VALUES (?, ?) ON CONFLICT(barcode) DO UPDATE SET name = excluded.name",
          "args": [
            {"type": "text", "value": barcode},
            {"type": "text", "value": name},
          ],
        },
      },
      {"type": "close"},
    ]);
  }

  
  
  Future<void> pushProducts(List<Map<String, String>> products) async {
    if (!isConfigured || products.isEmpty) return;
    const batchSize = 200;
    for (var i = 0; i < products.length; i += batchSize) {
      final chunk = products.skip(i).take(batchSize).toList();
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
