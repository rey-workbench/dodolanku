import 'package:dodolanku/core/models/product_model.dart';

class TopProduct {
  final String productName;
  final String barcode;
  final int totalQty;
  final double totalRevenue;

  TopProduct({
    required this.productName,
    required this.barcode,
    required this.totalQty,
    required this.totalRevenue,
  });

  factory TopProduct.fromMap(Map<String, dynamic> map) {
    return TopProduct(
      productName: map['product_name'] as String? ?? '',
      barcode: map['barcode'] as String? ?? '',
      totalQty: (map['total_qty'] as num?)?.toInt() ?? 0,
      totalRevenue: (map['total_revenue'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class DashboardData {
  final double totalToday;
  final int countToday;
  final double totalYesterday;
  final int countYesterday;
  final List<TopProduct> topProducts;
  final List<Product> lowStockProducts;
  final int totalProducts;

  DashboardData({
    required this.totalToday,
    required this.countToday,
    required this.totalYesterday,
    required this.countYesterday,
    required this.topProducts,
    required this.lowStockProducts,
    this.totalProducts = 0,
  });

  double get percentageDiff {
    if (totalYesterday == 0) return totalToday > 0 ? 100.0 : 0.0;
    return ((totalToday - totalYesterday) / totalYesterday) * 100.0;
  }
}
