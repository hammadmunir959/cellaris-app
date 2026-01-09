import 'package:isar_community/isar.dart';
import 'package:cellaris/core/database/isar_schemas.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cellaris/core/database/isar_service.dart';

class CustomerRepository {
  final Isar _isar;
  CustomerRepository(this._isar);

  Future<List<CustomerPersistence>> getCustomers() async {
    return _isar.customerPersistences.where().findAll();
  }

  Future<List<CustomerPersistence>> getUnsyncedCustomers() async {
    return _isar.customerPersistences.filter().isSyncedEqualTo(false).findAll();
  }

  Future<void> saveCustomer(CustomerPersistence customer) async {
    await _isar.writeTxn(() async {
      customer.updatedAt = DateTime.now();
      await _isar.customerPersistences.put(customer);
    });
  }

  Future<void> markAsSynced(String id) async {
    final customer = await _isar.customerPersistences.filter().idEqualTo(id).findFirst();
    if (customer != null) {
      await _isar.writeTxn(() async {
        customer.isSynced = true;
        await _isar.customerPersistences.put(customer);
      });
    }
  }
  Future<void> deleteCustomer(String id) async {
    await _isar.writeTxn(() async {
      await _isar.customerPersistences.filter().idEqualTo(id).deleteFirst();
    });
  }
}

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  final isar = ref.watch(isarServiceProvider).isar;
  return CustomerRepository(isar);
});
