import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dodolanku/core/database_service.dart';
import 'package:dodolanku/core/models/product_model.dart';
import 'package:dodolanku/core/models/transaction_model.dart';
import 'package:dodolanku/features/scanner/models/cart_item_model.dart';
import 'package:dodolanku/features/scanner/repositories/product_repository.dart';
import 'package:dodolanku/features/orders/repositories/transaction_repository.dart';

final databaseServiceProvider = Provider<DatabaseService>((ref) {
  final service = DatabaseService();
  ref.onDispose(() => service.dispose());
  return service;
});

// ─────────────────────────────────────────────
// STATE
// ─────────────────────────────────────────────

class ScannerState {
  final bool isLoading;
  final String scanResult;
  final String productName;
  final double productPrice;
  final int productStock;
  final List<ScanHistoryItem> history;
  final bool isCameraActive;

  // Cart
  final List<CartItem> cart;
  final bool checkoutSuccess;

  ScannerState({
    this.isLoading = true,
    this.scanResult = "Belum ada barcode",
    this.productName = "",
    this.productPrice = 0.0,
    this.productStock = 0,
    this.history = const [],
    this.isCameraActive = true,
    this.cart = const [],
    this.checkoutSuccess = false,
  });

  double get cartTotal => cart.fold(0.0, (sum, item) => sum + item.subtotal);
  int get cartCount => cart.fold(0, (sum, item) => sum + item.qty);

  ScannerState copyWith({
    bool? isLoading,
    String? scanResult,
    String? productName,
    double? productPrice,
    int? productStock,
    List<ScanHistoryItem>? history,
    bool? isCameraActive,
    List<CartItem>? cart,
    bool? checkoutSuccess,
  }) {
    return ScannerState(
      isLoading: isLoading ?? this.isLoading,
      scanResult: scanResult ?? this.scanResult,
      productName: productName ?? this.productName,
      productPrice: productPrice ?? this.productPrice,
      productStock: productStock ?? this.productStock,
      history: history ?? this.history,
      isCameraActive: isCameraActive ?? this.isCameraActive,
      cart: cart ?? this.cart,
      checkoutSuccess: checkoutSuccess ?? this.checkoutSuccess,
    );
  }
}

// ─────────────────────────────────────────────
// NOTIFIER (CONTROLLER)
// ─────────────────────────────────────────────

class ScannerNotifier extends Notifier<ScannerState> {
  ProductRepository get _productRepo => ref.read(productRepositoryProvider);
  TransactionRepository get _transactionRepo => ref.read(transactionRepositoryProvider);

  @override
  ScannerState build() {
    Future.microtask(() => _init());
    return ScannerState(isLoading: true);
  }

  Future<void> _init() async {
    try {
      final dbService = ref.read(databaseServiceProvider);
      await dbService.initDb();
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        scanResult: "Error loading DB",
        productName: e.toString(),
      );
    }
  }

  void setCameraActive(bool active) {
    state = state.copyWith(isCameraActive: active);
  }

  // ── Barcode Lookup ──────────────────────────

  Future<bool> lookupBarcode(String barcode, {bool isUpdate = false}) async {
    final clean = barcode.trim();
    if (clean.isEmpty) return false;

    final product = await _productRepo.getProductDetails(clean);

    if (product != null) {
      final name = product.name;
      final price = product.price;
      final stock = product.stock;

      // Update info display
      final newItem = ScanHistoryItem(
        barcode: clean,
        name: name,
        price: price,
        stock: stock,
        time: DateTime.now().toString().substring(11, 19),
      );
      final newHistory = List<ScanHistoryItem>.from(state.history);
      if (newHistory.isEmpty || newHistory.first.barcode != clean) {
        newHistory.insert(0, newItem);
      }

      // Add to cart
      addToCart(barcode: clean, name: name, price: price, increment: !isUpdate);

      state = state.copyWith(
        scanResult: clean,
        productName: name,
        productPrice: price,
        productStock: stock,
        history: newHistory,
        isCameraActive: false,
      );
      return true;
    } else {
      state = state.copyWith(
        scanResult: clean,
        productName: "Produk belum terdaftar",
        productPrice: 0.0,
        productStock: 0,
        isCameraActive: false,
      );
      return false;
    }
  }

  Future<String> generateNonBarcodeCode() async {
    return await _productRepo.getNextNonBarcodeCode();
  }

  Future<void> addProduct({
    required String barcode,
    required String name,
    required double price,
    required int stock,
  }) async {
    final product = Product(
      barcode: barcode,
      name: name,
      price: price,
      stock: stock,
    );
    await _productRepo.insertProduct(product);
    await lookupBarcode(barcode, isUpdate: true);
  }

  Future<void> updateProductDetails({
    required String barcode,
    required double price,
    required int stock,
  }) async {
    await _productRepo.updatePriceAndStock(barcode, price: price, stock: stock);
    await lookupBarcode(barcode, isUpdate: true);
  }

  // ── Cart Management ─────────────────────────

  void addToCart({required String barcode, required String name, required double price, bool increment = true}) {
    final cart = List<CartItem>.from(state.cart);
    final idx = cart.indexWhere((c) => c.barcode == barcode);
    if (idx >= 0) {
      cart[idx] = cart[idx].copyWith(
        qty: increment ? cart[idx].qty + 1 : cart[idx].qty,
        price: price,
        name: name,
      );
    } else {
      cart.insert(0, CartItem(barcode: barcode, name: name, price: price));
    }
    state = state.copyWith(cart: cart);
  }

  void removeFromCart(String barcode) {
    final cart = state.cart.where((c) => c.barcode != barcode).toList();
    state = state.copyWith(cart: cart);
  }

  void updateQty(String barcode, int qty) {
    if (qty <= 0) {
      removeFromCart(barcode);
      return;
    }
    final cart = List<CartItem>.from(state.cart);
    final idx = cart.indexWhere((c) => c.barcode == barcode);
    if (idx >= 0) {
      cart[idx] = cart[idx].copyWith(qty: qty);
      state = state.copyWith(cart: cart);
    }
  }

  void clearCart() {
    state = state.copyWith(
      cart: [],
      scanResult: "Belum ada barcode",
      productName: "",
      productPrice: 0.0,
      productStock: 0,
      checkoutSuccess: false,
    );
  }

  // ── Checkout ────────────────────────────────

  /// Melakukan checkout dan mengembalikan [CheckoutResult] berisi data
  /// yang dibutuhkan UI untuk menawarkan cetak struk.
  Future<CheckoutResult> checkout({
    required String paymentMethod,
    required double amountPaid,
  }) async {
    if (state.cart.isEmpty) {
      return CheckoutResult(
        total: 0,
        amountPaid: 0,
        change: 0,
        paymentMethod: paymentMethod,
        items: [],
      );
    }

    final total = state.cartTotal;
    final change = amountPaid - total;
    final cartSnapshot = List<CartItem>.from(state.cart);

    final items = state.cart
        .map((c) => TransactionItemModel(
              barcode: c.barcode,
              productName: c.name,
              price: c.price,
              qty: c.qty,
              subtotal: c.subtotal,
            ))
        .toList();

    await _transactionRepo.insertTransaction(
      totalAmount: total,
      paymentMethod: paymentMethod,
      amountPaid: amountPaid,
      changeAmount: change,
      items: items,
    );

    state = state.copyWith(
      cart: [],
      checkoutSuccess: true,
      scanResult: "Belum ada barcode",
      productName: "",
      productPrice: 0.0,
      productStock: 0,
      history: [],
    );

    return CheckoutResult(
      total: total,
      amountPaid: amountPaid,
      change: change,
      paymentMethod: paymentMethod,
      items: cartSnapshot,
    );
  }
}

// ─────────────────────────────────────────────
// CHECKOUT RESULT
// ─────────────────────────────────────────────

class CheckoutResult {
  final double total;
  final double amountPaid;
  final double change;
  final String paymentMethod;
  final List<CartItem> items;

  const CheckoutResult({
    required this.total,
    required this.amountPaid,
    required this.change,
    required this.paymentMethod,
    required this.items,
  });
}

final scannerProvider = NotifierProvider<ScannerNotifier, ScannerState>(() {
  return ScannerNotifier();
});
