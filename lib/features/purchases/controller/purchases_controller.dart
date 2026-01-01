import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mbm_app/core/models/app_models.dart';
import 'package:mbm_app/features/inventory/controller/inventory_controller.dart';
import 'package:mbm_app/core/repositories/purchase_order_repository.dart';
import 'package:mbm_app/core/models/persistence_mappers.dart';
import 'package:mbm_app/core/repositories/unit_repository.dart';
import 'package:mbm_app/core/models/unit_imei.dart';


class PurchasesNotifier extends StateNotifier<List<PurchaseOrder>> {
  final Ref ref;
  final PurchaseOrderRepository _repository;
  final UnitRepository _unitRepository;

  PurchasesNotifier(this.ref, this._repository, this._unitRepository) : super([]) {
    _init();
  }

  Future<void> _init() async {
    final persisted = await _repository.getPurchaseOrders();
    state = persisted.map((p) => p.toDomain()).toList();
  }

  Future<void> addPurchaseOrder(PurchaseOrder po) async {
    state = [po, ...state];
    await _repository.savePurchaseOrder(po.toPersistence());
  }

  Future<void> updatePOStatus(String id, PurchaseOrderStatus status) async {
    state = state.map((po) {
      if (po.id == id) {
        final updatedPo = po.copyWith(
          status: status,
          receivedAt: status == PurchaseOrderStatus.received ? DateTime.now() : null,
        );
        
        // If received, update inventory
        if (status == PurchaseOrderStatus.received) {
          _createUnitsFromPO(updatedPo);
          _updateInventoryFromPO(updatedPo); // Keep updating the aggregate stock count
        }
        
        // Persist change
        _repository.savePurchaseOrder(updatedPo.toPersistence());
        
        return updatedPo;
      }
      return po;
    }).toList();
  }

  Future<void> _createUnitsFromPO(PurchaseOrder po) async {
    final units = <Unit>[];
    for (final item in po.items) {
      if (item.imeis != null && item.imeis!.isNotEmpty) {
        for (final imei in item.imeis!) {
          units.add(Unit(
            imei: imei,
            productId: item.productId,
            color: 'Unknown', // Could add Color to PurchaseOrderItem if needed in future
            locationId: null, // Default location or 'Warehouse'
            status: UnitStatus.inStock,
            purchaseBillNo: po.id,
            purchasePrice: item.costPrice,
            purchaseDate: DateTime.now(),
            companyId: null, // Should ideally come from PO/Settings
          ));
        }
      }
    }
    
    if (units.isNotEmpty) {
      await _unitRepository.saveAll(units);
    }
  }

  void _updateInventoryFromPO(PurchaseOrder po) {
    for (final item in po.items) {
      ref.read(productProvider.notifier).updateStock(item.productId, item.quantity);
    }
  }

  Future<void> deletePO(String id) async {
    state = state.where((po) => po.id != id).toList();
    await _repository.deletePurchaseOrder(id);
  }
}

final purchasesProvider = StateNotifierProvider<PurchasesNotifier, List<PurchaseOrder>>((ref) {
  return PurchasesNotifier(
    ref,
    ref.watch(purchaseOrderRepositoryProvider),
    ref.watch(unitRepositoryProvider),
  );
});
