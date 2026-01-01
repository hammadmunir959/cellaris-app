import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mbm_app/core/models/app_models.dart';
import 'package:mbm_app/core/repositories/product_repository.dart';
import 'package:mbm_app/core/services/sync_service.dart';
import 'package:mbm_app/core/models/persistence_mappers.dart';

class ProductNotifier extends StateNotifier<List<Product>> {
  final ProductRepository _repository;
  final SyncService _syncService;

  ProductNotifier(this._repository, this._syncService) : super([]) {
    _init();
  }

  Future<void> _init() async {
    final persisted = await _repository.getProducts();
    if (persisted.isEmpty) {
      // Seed initial data for demo/first run
      for (final p in _initialProducts) {
        await _repository.saveProduct(p.toPersistence(synced: true));
      }
      state = _initialProducts;
    } else {
      state = persisted.map((p) => p.toDomain()).toList();
    }
  }

  static final List<Product> _initialProducts = [
    Product(
      id: '1',
      name: 'iPhone 15 Pro Max',
      sku: 'IP15PM-256-BLU',
      brand: 'Apple',
      category: 'Smartphones',
      purchasePrice: 400000,
      sellingPrice: 450000,
      stock: 24,
      variant: '256GB - Blue Titanium',
      lowStockThreshold: 10,
    ),
    Product(
      id: '2',
      name: 'Samsung S24 Ultra',
      sku: 'S24U-512-GRY',
      brand: 'Samsung',
      category: 'Smartphones',
      purchasePrice: 350000,
      sellingPrice: 390000,
      stock: 12,
      variant: '512GB - Titanium Gray',
      lowStockThreshold: 10,
    ),
    Product(
      id: '3',
      name: 'Google Pixel 8 Pro',
      sku: 'PX8P-128-BLK',
      brand: 'Google',
      category: 'Smartphones',
      purchasePrice: 200000,
      sellingPrice: 230000,
      stock: 5,
      variant: '128GB - Obsidian',
      lowStockThreshold: 15,
    ),
    Product(
      id: '4',
      name: 'iPad Air M2',
      sku: 'IPAM2-128-PUR',
      brand: 'Apple',
      category: 'Tablets',
      purchasePrice: 150000,
      sellingPrice: 175000,
      stock: 3,
      variant: '128GB - Purple',
      lowStockThreshold: 5,
    ),
  ];

  Future<void> addProduct(Product product) async {
    // UI Update (Optimistic)
    state = [...state, product];
    
    // Local Persistence
    await _repository.saveProduct(product.toPersistence(synced: false));
    
    // Trigger Sync
    _syncService.syncNow();
  }

  Future<void> updateStock(String id, int quantityChange) async {
    final index = state.indexWhere((p) => p.id == id);
    if (index != -1) {
      final updated = state[index].copyWith(stock: state[index].stock + quantityChange);
      
      // Update UI
      state = [
        for (final p in state)
          if (p.id == id) updated else p
      ];
      
      // Persist locally
      await _repository.saveProduct(updated.toPersistence(synced: false));
      
      // Trigger Sync
      _syncService.syncNow();
    }
  }

  Future<void> updateProduct(Product product) async {
    // UI Update (Optimistic)
    state = [
      for (final p in state)
        if (p.id == product.id) product else p
    ];
    
    // Local Persistence
    await _repository.saveProduct(product.toPersistence(synced: false));
    
    // Trigger Sync
    _syncService.syncNow();
  }

  Future<void> deleteProduct(String id) async {
    state = state.where((p) => p.id != id).toList();
    await _repository.deleteProduct(id);
    
    // Note: Delete sync would typically involve a "soft delete" flag 
    // or a dedicated delete-sync queue.
  }
}

final productProvider = StateNotifierProvider<ProductNotifier, List<Product>>((ref) {
  return ProductNotifier(
    ref.watch(productRepositoryProvider),
    ref.watch(syncServiceProvider),
  );
});

// Filtered products provider
final searchQueryProvider = StateProvider<String>((ref) => '');
final categoryFilterProvider = StateProvider<String>((ref) => 'All');
final inventorySortByProvider = StateProvider<String>((ref) => 'name');
final inventorySortOrderProvider = StateProvider<bool>((ref) => true); // true = asc

final filteredProductsProvider = Provider<List<Product>>((ref) {
  final products = ref.watch(productProvider);
  final query = ref.watch(searchQueryProvider).toLowerCase();
  final category = ref.watch(categoryFilterProvider);
  final sortBy = ref.watch(inventorySortByProvider);
  final isAsc = ref.watch(inventorySortOrderProvider);

  var list = products.where((p) {
    final matchesSearch = p.name.toLowerCase().contains(query) ||
           p.sku.toLowerCase().contains(query) ||
           (p.imei?.toLowerCase().contains(query) ?? false);
    
    final matchesCategory = category == 'All' || p.category == category;
    
    return matchesSearch && matchesCategory;
  }).toList();

  list.sort((a, b) {
    int cmp = 0;
    if (sortBy == 'name') cmp = a.name.compareTo(b.name);
    else if (sortBy == 'stock') cmp = a.stock.compareTo(b.stock);
    else if (sortBy == 'price') cmp = a.sellingPrice.compareTo(b.sellingPrice);
    
    return isAsc ? cmp : -cmp;
  });

  return list;
});
