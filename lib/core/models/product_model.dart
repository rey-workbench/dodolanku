class Product {
  final String barcode;
  final String name;
  final double price;
  final int stock;

  Product({
    required this.barcode,
    required this.name,
    required this.price,
    required this.stock,
  });

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      barcode: map['barcode'] as String? ?? '',
      name: map['name'] as String? ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      stock: (map['stock'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'barcode': barcode,
      'name': name,
      'price': price,
      'stock': stock,
    };
  }

  Product copyWith({
    String? barcode,
    String? name,
    double? price,
    int? stock,
  }) {
    return Product(
      barcode: barcode ?? this.barcode,
      name: name ?? this.name,
      price: price ?? this.price,
      stock: stock ?? this.stock,
    );
  }
}
