import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dodolanku/core/database_service.dart';
import 'package:dodolanku/core/models/product_model.dart';

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepositoryImpl(ref.read(databaseServiceProvider));
});

abstract class ProductRepository {
  Future<Product?> getProductDetails(String barcode);
  Future<void> insertProduct(Product product);
  Future<void> updatePriceAndStock(String barcode, {String? name, double? price, int? stock});
  Future<List<Product>> getLowStockProducts({int threshold = 5});
  Future<int> getTotalProductsCount();
  Future<String> getNextNonBarcodeCode();
  Future<List<Map<String, dynamic>>> searchProducts(String query);
  Future<int> getGlobalProductsCount();
  Future<int> syncMasterProductsFromTurso();
}

class ProductRepositoryImpl implements ProductRepository {
  final DatabaseService _dbService;

  ProductRepositoryImpl(this._dbService);

  @override
  Future<int> getGlobalProductsCount() => _dbService.getGlobalProductsCount();

  @override
  Future<int> syncMasterProductsFromTurso() => _dbService.syncMasterProductsFromTurso();

  @override
  Future<List<Map<String, dynamic>>> searchProducts(String query) => _dbService.searchProducts(query);

  @override
  Future<String> getNextNonBarcodeCode() => _dbService.getNextNonBarcodeCode();

  @override
  Future<int> getTotalProductsCount() => _dbService.getTotalProductsCount();

  @override
  Future<Product?> getProductDetails(String barcode) async {
    final map = await _dbService.getProductDetails(barcode);
    return map != null ? Product.fromMap(map) : null;
  }

  @override
  Future<void> insertProduct(Product product) => _dbService.insertProduct(
        product.barcode,
        product.name,
        product.price,
        product.stock,
      );

  @override
  Future<void> updatePriceAndStock(String barcode, {String? name, double? price, int? stock}) =>
      _dbService.updatePriceAndStock(barcode, name: name, price: price, stock: stock);

  @override
  Future<List<Product>> getLowStockProducts({int threshold = 5}) async {
    final list = await _dbService.getLowStockProducts(threshold: threshold);
    return list.map(Product.fromMap).toList();
  }
}
