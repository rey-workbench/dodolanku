import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dodolanku/core/database_service.dart';
import 'package:dodolanku/core/models/product_model.dart';
import 'package:dodolanku/features/scanner/providers/scanner_provider.dart';

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
}

class ProductRepositoryImpl implements ProductRepository {
  final DatabaseService _dbService;

  ProductRepositoryImpl(this._dbService);

  @override
  Future<String> getNextNonBarcodeCode() async {
    return await _dbService.getNextNonBarcodeCode();
  }

  @override
  Future<int> getTotalProductsCount() async {
    return await _dbService.getTotalProductsCount();
  }

  @override
  Future<Product?> getProductDetails(String barcode) async {
    final map = await _dbService.getProductDetails(barcode);
    if (map == null) return null;
    return Product.fromMap(map);
  }

  @override
  Future<void> insertProduct(Product product) async {
    await _dbService.insertProduct(
      product.barcode,
      product.name,
      product.price,
      product.stock,
    );
  }

  @override
  Future<void> updatePriceAndStock(String barcode, {String? name, double? price, int? stock}) async {
    await _dbService.updatePriceAndStock(barcode, name: name, price: price, stock: stock);
  }

  @override
  Future<List<Product>> getLowStockProducts({int threshold = 5}) async {
    final list = await _dbService.getLowStockProducts(threshold: threshold);
    return list.map((m) => Product.fromMap(m)).toList();
  }
}
