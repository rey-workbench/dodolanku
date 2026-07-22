import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dodolanku/core/widgets/app_widgets.dart';
import 'package:dodolanku/core/utils/currency_formatter.dart';
import 'package:dodolanku/core/models/product_model.dart';
import 'package:dodolanku/features/scanner/repositories/product_repository.dart';

class ProductListPage extends ConsumerStatefulWidget {
  const ProductListPage({super.key});

  @override
  ConsumerState<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends ConsumerState<ProductListPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadAllProducts() async {
    setState(() => _isLoading = true);
    final productRepo = ref.read(productRepositoryProvider);
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      final results = await productRepo.searchProducts("");
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isLoading = false;
        });
      }
    } else {
      final results = await productRepo.searchProducts(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isLoading = false;
        });
      }
    }
  }

  void _editProduct(Map<String, dynamic> product) {
    showProductFormModal(
      context: context,
      initialBarcode: product['barcode'] as String,
      initialName: product['name'] as String,
      initialPrice: (product['price'] as num).toDouble(),
      initialStock: (product['stock'] as num).toInt(),
      onSave: ({
        required String barcode,
        required String name,
        required double price,
        required int stock,
      }) async {
        final productRepo = ref.read(productRepositoryProvider);
        await productRepo.insertProduct(Product(
          barcode: barcode,
          name: name,
          price: price,
          stock: stock,
        ));
        if (mounted) {
          AppToast.show(context, message: 'Data produk berhasil diperbarui');
          _loadAllProducts(); // Refresh
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Katalog Produk'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari nama atau barcode...',
                prefixIcon: const Icon(Icons.search, size: 20),
                fillColor: Colors.white,
                filled: true,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) {
                // Debounce simple
                Future.delayed(const Duration(milliseconds: 300), () {
                  if (val == _searchController.text) {
                    _loadAllProducts();
                  }
                });
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _searchResults.isEmpty
                    ? Center(
                        child: Text(
                          'Tidak ada produk ditemukan',
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        itemCount: _searchResults.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final p = _searchResults[index];
                          return AppCard(
                            onTap: () => _editProduct(p),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            child: Row(
                              children: [
                                const AppIconAvatar(
                                  icon: Icons.inventory_2_outlined,
                                  radius: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        p['name'] as String,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        p['barcode'] as String,
                                        style: TextStyle(color: Colors.grey[500], fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Rp ${formatRupiah((p['price'] as num).toDouble())}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    AppStatusBadge(
                                      label: 'Stok: ${p['stock']}',
                                      color: (p['stock'] as num) < 5
                                          ? Colors.red
                                          : Colors.grey,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
