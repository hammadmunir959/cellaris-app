import 'package:isar_community/isar.dart';
import 'package:cellaris/core/database/isar_schemas.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cellaris/core/database/isar_service.dart';

class PurchaseOrderRepository {
  final Isar _isar;
  PurchaseOrderRepository(this._isar);

  Future<List<PurchaseOrderPersistence>> getPurchaseOrders() async {
    return _isar.purchaseOrderPersistences.where().sortByCreatedAtDesc().findAll();
  }

  Future<void> savePurchaseOrder(PurchaseOrderPersistence po) async {
    await _isar.writeTxn(() async {
      po.updatedAt = DateTime.now();
      await _isar.purchaseOrderPersistences.put(po);
    });
  }

  Future<void> deletePurchaseOrder(String id) async {
    await _isar.writeTxn(() async {
      await _isar.purchaseOrderPersistences.filter().idEqualTo(id).deleteAll();
    });
  }

  Future<List<PurchaseOrderPersistence>> getBySupplierId(String supplierId) async {
    return _isar.purchaseOrderPersistences
        .filter()
        .supplierIdEqualTo(supplierId)
        .sortByCreatedAtDesc()
        .findAll();
  }
}

final purchaseOrderRepositoryProvider = Provider<PurchaseOrderRepository>((ref) {
  final isar = ref.watch(isarServiceProvider).isar;
  return PurchaseOrderRepository(isar);
});
