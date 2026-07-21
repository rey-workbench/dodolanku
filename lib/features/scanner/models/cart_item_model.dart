class CartItem {
  final String barcode;
  final String name;
  final double price;
  int qty;

  CartItem({
    required this.barcode,
    required this.name,
    required this.price,
    this.qty = 1,
  });

  double get subtotal => price * qty;

  CartItem copyWith({String? name, double? price, int? qty}) => CartItem(
        barcode: barcode,
        name: name ?? this.name,
        price: price ?? this.price,
        qty: qty ?? this.qty,
      );
}

class ScanHistoryItem {
  final String barcode;
  final String name;
  final double price;
  final int stock;
  final String time;

  ScanHistoryItem({
    required this.barcode,
    required this.name,
    required this.price,
    required this.stock,
    required this.time,
  });
}
