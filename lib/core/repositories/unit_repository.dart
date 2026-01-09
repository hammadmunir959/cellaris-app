import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../database/isar_service.dart';
import '../database/isar_schemas.dart';
import '../models/unit_imei.dart';

/// Repository for IMEI/Unit tracking operations
class UnitRepository {
  final IsarService _isarService;

  UnitRepository(this._isarService);

  Isar get _isar => _isarService.isar;

  // ============================================================
  // QUERY OPERATIONS
  // ============================================================

  /// Get all units
  Future<List<Unit>> getAll({String? companyId}) async {
    var query = _isar.unitPersistences.where();
    if (companyId != null) {
      final persistence = await _isar.unitPersistences
          .filter()
          .companyIdEqualTo(companyId)
          .findAll();
      return persistence.map(_mapFromPersistence).toList();
    }
    final persistence = await query.findAll();
    return persistence.map(_mapFromPersistence).toList();
  }

  /// Get unit by IMEI
  Future<Unit?> getByImei(String imei) async {
    final persistence = await _isar.unitPersistences
        .filter()
        .imeiEqualTo(imei)
        .findFirst();
    return persistence != null ? _mapFromPersistence(persistence) : null;
  }

  /// Get units by product
  Future<List<Unit>> getByProduct(String productId) async {
    final persistence = await _isar.unitPersistences
        .filter()
        .productIdEqualTo(productId)
        .findAll();
    return persistence.map(_mapFromPersistence).toList();
  }

  /// Get units by status
  Future<List<Unit>> getByStatus(UnitStatus status) async {
    final persistence = await _isar.unitPersistences
        .filter()
        .statusEqualTo(status.name)
        .findAll();
    return persistence.map(_mapFromPersistence).toList();
  }

  /// Get units available for sale (in stock or issued)
  Future<List<Unit>> getAvailableForSale({String? locationId}) async {
    var query = _isar.unitPersistences
        .filter()
        .statusEqualTo(UnitStatus.inStock.name)
        .or()
        .statusEqualTo(UnitStatus.issued.name);
    
    final persistence = await query.findAll();
    var units = persistence.map(_mapFromPersistence).toList();
    
    if (locationId != null) {
      units = units.where((u) => u.locationId == locationId).toList();
    }
    
    return units;
  }

  /// Get units by location
  Future<List<Unit>> getByLocation(String locationId) async {
    final persistence = await _isar.unitPersistences
        .filter()
        .locationIdEqualTo(locationId)
        .findAll();
    return persistence.map(_mapFromPersistence).toList();
  }

  /// Get units by purchase bill
  Future<List<Unit>> getByPurchaseBill(String billNo) async {
    final persistence = await _isar.unitPersistences
        .filter()
        .purchaseBillNoEqualTo(billNo)
        .findAll();
    return persistence.map(_mapFromPersistence).toList();
  }

  /// Get units available for return to supplier
  Future<List<Unit>> getAvailableForPurchaseReturn() async {
    final persistence = await _isar.unitPersistences
        .filter()
        .statusEqualTo(UnitStatus.inStock.name)
        .saleBillNoIsNull()
        .findAll();
    return persistence.map(_mapFromPersistence).toList();
  }

  /// Search units by IMEI (partial match)
  Future<List<Unit>> search(String query) async {
    final persistence = await _isar.unitPersistences
        .filter()
        .imeiContains(query)
        .findAll();
    return persistence.map(_mapFromPersistence).toList();
  }

  // ============================================================
  // WRITE OPERATIONS
  // ============================================================

  /// Save a single unit
  Future<void> save(Unit unit) async {
    final persistence = _mapToPersistence(unit);
    await _isar.writeTxn(() async {
      await _isar.unitPersistences.put(persistence);
    });
  }

  /// Save multiple units (bulk import)
  Future<void> saveAll(List<Unit> units) async {
    final persistences = units.map(_mapToPersistence).toList();
    await _isar.writeTxn(() async {
      await _isar.unitPersistences.putAll(persistences);
    });
  }

  /// Save units from a batch (for purchase import)
  Future<void> saveBatch(UnitBatch batch) async {
    final units = batch.toUnits();
    await saveAll(units);
  }

  /// Mark unit as sold
  Future<void> markAsSold({
    required String imei,
    required String saleBillNo,
    required double soldPrice,
    required DateTime saleDate,
  }) async {
    await _isar.writeTxn(() async {
      final persistence = await _isar.unitPersistences
          .filter()
          .imeiEqualTo(imei)
          .findFirst();
      if (persistence != null) {
        persistence.status = UnitStatus.sold.name;
        persistence.saleBillNo = saleBillNo;
        persistence.soldPrice = soldPrice;
        persistence.saleDate = saleDate;
        persistence.updatedAt = DateTime.now();
        await _isar.unitPersistences.put(persistence);
      }
    });
  }

  /// Mark unit as issued to location
  Future<void> issueToLocation(String imei, String locationId) async {
    await _isar.writeTxn(() async {
      final persistence = await _isar.unitPersistences
          .filter()
          .imeiEqualTo(imei)
          .findFirst();
      if (persistence != null) {
        persistence.status = UnitStatus.issued.name;
        persistence.locationId = locationId;
        persistence.updatedAt = DateTime.now();
        await _isar.unitPersistences.put(persistence);
      }
    });
  }

  /// Restock unit (after sale return)
  Future<void> restock(String imei) async {
    await _isar.writeTxn(() async {
      final persistence = await _isar.unitPersistences
          .filter()
          .imeiEqualTo(imei)
          .findFirst();
      if (persistence != null) {
        persistence.status = UnitStatus.inStock.name;
        persistence.saleBillNo = null;
        persistence.soldPrice = null;
        persistence.saleDate = null;
        persistence.updatedAt = DateTime.now();
        await _isar.unitPersistences.put(persistence);
      }
    });
  }

  /// Delete unit by IMEI
  Future<void> delete(String imei) async {
    await _isar.writeTxn(() async {
      await _isar.unitPersistences.filter().imeiEqualTo(imei).deleteFirst();
    });
  }

  // ============================================================
  // VALIDATION
  // ============================================================

  /// Check if IMEI exists
  Future<bool> exists(String imei) async {
    final count = await _isar.unitPersistences
        .filter()
        .imeiEqualTo(imei)
        .count();
    return count > 0;
  }

  /// Check if IMEI is available for sale
  Future<bool> isAvailableForSale(String imei) async {
    final unit = await getByImei(imei);
    return unit?.isAvailableForSale ?? false;
  }

  /// Validate list of IMEIs for sale
  Future<List<String>> validateImeisForSale(List<String> imeis) async {
    final invalid = <String>[];
    for (final imei in imeis) {
      if (!await isAvailableForSale(imei)) {
        invalid.add(imei);
      }
    }
    return invalid;
  }

  // ============================================================
  // STATISTICS
  // ============================================================

  /// Count units by status
  Future<int> countByStatus(UnitStatus status) async {
    return await _isar.unitPersistences
        .filter()
        .statusEqualTo(status.name)
        .count();
  }

  /// Get stock count by product
  Future<int> getStockCount(String productId) async {
    return await _isar.unitPersistences
        .filter()
        .productIdEqualTo(productId)
        .statusEqualTo(UnitStatus.inStock.name)
        .or()
        .productIdEqualTo(productId)
        .statusEqualTo(UnitStatus.issued.name)
        .count();
  }

  // ============================================================
  // MAPPERS
  // ============================================================

  Unit _mapFromPersistence(UnitPersistence p) {
    return Unit(
      imei: p.imei,
      productId: p.productId,
      color: p.color,
      locationId: p.locationId,
      status: _parseStatus(p.status),
      purchaseBillNo: p.purchaseBillNo,
      saleBillNo: p.saleBillNo,
      purchasePrice: p.purchasePrice,
      soldPrice: p.soldPrice,
      purchaseDate: p.purchaseDate,
      saleDate: p.saleDate,
      warranty: p.warranty,
      activationStatus: p.activationStatus,
      companyId: p.companyId,
      notes: p.notes,
    );
  }

  UnitPersistence _mapToPersistence(Unit u) {
    return UnitPersistence()
      ..imei = u.imei
      ..productId = u.productId
      ..color = u.color
      ..locationId = u.locationId
      ..status = u.status.name
      ..purchaseBillNo = u.purchaseBillNo
      ..saleBillNo = u.saleBillNo
      ..purchasePrice = u.purchasePrice
      ..soldPrice = u.soldPrice
      ..purchaseDate = u.purchaseDate
      ..saleDate = u.saleDate
      ..warranty = u.warranty
      ..activationStatus = u.activationStatus
      ..companyId = u.companyId
      ..notes = u.notes
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now()
      ..isSynced = false;
  }

  UnitStatus _parseStatus(String status) {
    switch (status) {
      case 'inStock':
        return UnitStatus.inStock;
      case 'issued':
        return UnitStatus.issued;
      case 'sold':
        return UnitStatus.sold;
      case 'returned':
        return UnitStatus.returned;
      default:
        return UnitStatus.inStock;
    }
  }
}

/// Provider for UnitRepository
final unitRepositoryProvider = Provider<UnitRepository>((ref) {
  final isarService = ref.watch(isarServiceProvider);
  return UnitRepository(isarService);
});
