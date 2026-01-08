import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cellaris/core/models/app_models.dart';
import 'package:cellaris/core/repositories/customer_repository.dart';
import 'package:cellaris/core/repositories/supplier_repository.dart';
import 'package:cellaris/core/models/persistence_mappers.dart';

class CustomerNotifier extends StateNotifier<List<Customer>> {
  final CustomerRepository _repository;

  CustomerNotifier(this._repository) : super([]) {
    _init();
  }

  Future<void> _init() async {
    final persisted = await _repository.getCustomers();
    state = persisted.map((c) => c.toDomain()).toList();
  }

  Future<void> addCustomer(Customer customer) async {
    state = [...state, customer];
    await _repository.saveCustomer(customer.toPersistence());
  }

  Future<void> updateCustomer(Customer customer) async {
    state = [
      for (final c in state)
        if (c.id == customer.id) customer else c
    ];
    await _repository.saveCustomer(customer.toPersistence());
  }

  Future<void> deleteCustomer(String id) async {
    state = state.where((c) => c.id != id).toList();
    await _repository.deleteCustomer(id);
  }
}

final customerProvider = StateNotifierProvider<CustomerNotifier, List<Customer>>((ref) {
  return CustomerNotifier(ref.watch(customerRepositoryProvider));
});

class SupplierNotifier extends StateNotifier<List<Supplier>> {
  final SupplierRepository _repository;

  SupplierNotifier(this._repository) : super([]) {
    _init();
  }

  Future<void> _init() async {
    final persisted = await _repository.getSuppliers();
    state = persisted.map((s) => s.toDomain()).toList();
  }

  Future<void> addSupplier(Supplier supplier) async {
    state = [...state, supplier];
    await _repository.saveSupplier(supplier.toPersistence());
  }

  Future<void> updateSupplier(Supplier supplier) async {
    state = [
      for (final s in state)
        if (s.id == supplier.id) supplier else s
    ];
    await _repository.saveSupplier(supplier.toPersistence());
  }

  Future<void> deleteSupplier(String id) async {
    state = state.where((s) => s.id != id).toList();
    await _repository.deleteSupplier(id);
  }
}

final supplierProvider = StateNotifierProvider<SupplierNotifier, List<Supplier>>((ref) {
  return SupplierNotifier(ref.watch(supplierRepositoryProvider));
});

final clockProvider = StreamProvider<DateTime>((ref) {
  return Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now());
});
