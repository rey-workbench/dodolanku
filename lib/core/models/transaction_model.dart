class TransactionModel {
  final int? id;
  final String createdAt;
  final double totalAmount;
  final String paymentMethod;
  final double amountPaid;
  final double changeAmount;
  final String status;

  TransactionModel({
    this.id,
    required this.createdAt,
    required this.totalAmount,
    required this.paymentMethod,
    required this.amountPaid,
    required this.changeAmount,
    this.status = 'selesai',
  });

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as int?,
      createdAt: map['created_at'] as String? ?? '',
      totalAmount: (map['total_amount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: map['payment_method'] as String? ?? 'tunai',
      amountPaid: (map['amount_paid'] as num?)?.toDouble() ?? 0.0,
      changeAmount: (map['change_amount'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] as String? ?? 'selesai',
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'created_at': createdAt,
      'total_amount': totalAmount,
      'payment_method': paymentMethod,
      'amount_paid': amountPaid,
      'change_amount': changeAmount,
      'status': status,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }
}

class TransactionItemModel {
  final int? id;
  final int? transactionId;
  final String barcode;
  final String productName;
  final double price;
  final int qty;
  final double subtotal;

  TransactionItemModel({
    this.id,
    this.transactionId,
    required this.barcode,
    required this.productName,
    required this.price,
    required this.qty,
    required this.subtotal,
  });

  factory TransactionItemModel.fromMap(Map<String, dynamic> map) {
    return TransactionItemModel(
      id: map['id'] as int?,
      transactionId: map['transaction_id'] as int?,
      barcode: map['barcode'] as String? ?? '',
      productName: map['product_name'] as String? ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      qty: (map['qty'] as num?)?.toInt() ?? 1,
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'barcode': barcode,
      'product_name': productName,
      'price': price,
      'qty': qty,
      'subtotal': subtotal,
    };
    if (id != null) map['id'] = id;
    if (transactionId != null) map['transaction_id'] = transactionId;
    return map;
  }
}
