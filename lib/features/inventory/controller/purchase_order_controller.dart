import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mbm_app/core/models/app_models.dart';
import 'package:mbm_app/core/repositories/purchase_order_repository.dart';
import 'package:mbm_app/core/repositories/product_repository.dart';
import 'package:uuid/uuid.dart';
import 'package:mbm_app/core/models/persistence_mappers.dart';
class PurchaseOrderNotifier extends StateNotifier<List<PurchaseOrder>> {
  final PurchaseOrderRepository _repository;

  PurchaseOrderNotifier(this._repository) : super([]) {
    _init();
  }

  Future<void> _init() async {
    final persisted = await _repository.getPurchaseOrders();
    state = persisted.map((p) => p.toDomain()).toList();
  }

  Future<void> addPurchaseOrder({
    required String supplierId,
    required String supplierName,
    required List<PurchaseOrderItem> items,
    String? notes,
  }) async {
    final double totalCost = items.fold(0, (sum, item) => sum + (item.costPrice * item.quantity));

    final newPO = PurchaseOrder(
      id: const Uuid().v4(),
      supplierId: supplierId,
      supplierName: supplierName,
      items: items,
      totalCost: totalCost,
      status: PurchaseOrderStatus.draft,
      notes: notes,
      createdAt: DateTime.now(),
    );

    // Optimistic Update
    state = [newPO, ...state];

    // Persist
    await _repository.savePurchaseOrder(newPO.toPersistence());
  }

  Future<void> updatePurchaseOrder(PurchaseOrder po) async {
    final double totalCost = po.items.fold(0, (sum, item) => sum + (item.costPrice * item.quantity));
    final updated = po.copyWith(totalCost: totalCost);
    
    state = [
      for (final item in state)
        if (item.id == po.id) updated else item
    ];
    await _repository.savePurchaseOrder(updated.toPersistence());
  }

  Future<void> updateStatus(String id, PurchaseOrderStatus status) async {
    final index = state.indexWhere((p) => p.id == id);
    if (index != -1) {
      final updated = state[index].copyWith(status: status);
      await updatePurchaseOrder(updated);
    }
  }

  Future<void> receivePurchaseOrder(String id, ProductRepository productRepo) async {
    final index = state.indexWhere((p) => p.id == id);
    if (index != -1) {
      final po = state[index];
      if (po.status == PurchaseOrderStatus.received) return;

      final updated = po.copyWith(
        status: PurchaseOrderStatus.received,
        receivedAt: DateTime.now(),
      );

      // Update Stock
      final existingProducts = await productRepo.getProducts(); 
      for (final item in po.items) {
          // Find the product in the returned list of Persistence objects
          try {
             final productPersistence = existingProducts.firstWhere((p) => p.id == item.productId);
             
             // Update stock directly on the persistence object
             productPersistence.stock = (productPersistence.stock ?? 0) + item.quantity;
             productPersistence.isSynced = false; // Mark for sync
             
             // Save back
             await productRepo.saveProduct(productPersistence);
          } catch (e) {
             // Product not found, ignore or log
          }
      }

      await updatePurchaseOrder(updated);
    }
  }

  Future<void> deletePurchaseOrder(String id) async {
    state = state.where((po) => po.id != id).toList();
    await _repository.deletePurchaseOrder(id);
  }
}

final purchaseOrderProvider = StateNotifierProvider<PurchaseOrderNotifier, List<PurchaseOrder>>((ref) {
  return PurchaseOrderNotifier(ref.watch(purchaseOrderRepositoryProvider));
});
