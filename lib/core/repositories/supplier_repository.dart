import 'package:isar/isar.dart';
import 'package:mbm_app/core/database/isar_schemas.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mbm_app/core/database/isar_service.dart';

class SupplierRepository {
  final Isar _isar;
  SupplierRepository(this._isar);

  Future<List<SupplierPersistence>> getSuppliers() async {
    return _isar.supplierPersistences.where().findAll();
  }

  Future<void> saveSupplier(SupplierPersistence supplier) async {
    await _isar.writeTxn(() async {
      supplier.updatedAt = DateTime.now();
      await _isar.supplierPersistences.put(supplier);
    });
  }

  Future<void> markAsSynced(String id) async {
    final supplier = await _isar.supplierPersistences.filter().idEqualTo(id).findFirst();
    if (supplier != null) {
      await _isar.writeTxn(() async {
        supplier.isSynced = true;
        await _isar.supplierPersistences.put(supplier);
      });
    }
  }
  Future<void> deleteSupplier(String id) async {
    await _isar.writeTxn(() async {
      await _isar.supplierPersistences.filter().idEqualTo(id).deleteFirst();
    });
  }
}

final supplierRepositoryProvider = Provider<SupplierRepository>((ref) {
  final isar = ref.watch(isarServiceProvider).isar;
  return SupplierRepository(isar);
});
