import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cellaris/core/models/app_models.dart';
import 'package:cellaris/core/repositories/product_repository.dart';
import 'package:cellaris/core/services/sync_service.dart';
import 'package:cellaris/core/models/persistence_mappers.dart';

class ProductNotifier extends StateNotifier<List<Product>> {
  final ProductRepository _repository;
  final SyncService _syncService;

  ProductNotifier(this._repository, this._syncService) : super([]) {
    _init();
  }

  Future<void> _init() async {
    final persisted = await _repository.getProducts();
    state = persisted.map((p) => p.toDomain()).toList();
  }

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
