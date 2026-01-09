import 'package:isar_community/isar.dart';
import 'package:cellaris/core/database/isar_schemas.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cellaris/core/database/isar_service.dart';

class ProductRepository {
  final Isar _isar;
  ProductRepository(this._isar);

  // Offline-first: Get all products from local DB
  Future<List<ProductPersistence>> getProducts() async {
    return _isar.productPersistences.where().findAll();
  }

  // Get only unsynced products for the SyncService
  Future<List<ProductPersistence>> getUnsyncedProducts() async {
    return _isar.productPersistences.filter().isSyncedEqualTo(false).findAll();
  }

  // Save/Update local product
  Future<void> saveProduct(ProductPersistence product) async {
    await _isar.writeTxn(() async {
      product.updatedAt = DateTime.now();
      await _isar.productPersistences.put(product);
    });
  }

  // Mark as synced after successful API call
  Future<void> markAsSynced(String id) async {
    final product = await _isar.productPersistences.filter().idEqualTo(id).findFirst();
    if (product != null) {
      await _isar.writeTxn(() async {
        product.isSynced = true;
        await _isar.productPersistences.put(product);
      });
    }
  }

  // Delete product
  Future<void> deleteProduct(String id) async {
    await _isar.writeTxn(() async {
      await _isar.productPersistences.filter().idEqualTo(id).deleteAll();
    });
  }
}

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  final isar = ref.watch(isarServiceProvider).isar;
  return ProductRepository(isar);
});
