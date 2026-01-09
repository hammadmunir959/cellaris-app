import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../database/isar_service.dart';
import '../database/isar_schemas.dart';
import '../models/stock_entry.dart';

/// Repository for unified stock ledger operations
/// Handles both serialized (IMEI-tracked) and non-serialized (quantity-tracked) inventory
class StockLedgerRepository {
  final IsarService _isarService;

  StockLedgerRepository(this._isarService);

  Isar get _isar => _isarService.isar;

  // ============================================================
  // QUERY OPERATIONS
  // ============================================================

  /// Get all stock entries
  Future<List<StockEntry>> getAll({String? companyId}) async {
    var query = _isar.stockEntryPersistences.where();
    if (companyId != null) {
      final persistence = await _isar.stockEntryPersistences
          .filter()
          .companyIdEqualTo(companyId)
          .findAll();
      return persistence.map(_mapFromPersistence).toList();
    }
    final persistence = await query.findAll();
    return persistence.map(_mapFromPersistence).toList();
  }

  /// Get stock entry by stockId
  Future<StockEntry?> getById(String stockId) async {
    final persistence = await _isar.stockEntryPersistences
        .filter()
        .stockIdEqualTo(stockId)
        .findFirst();
    return persistence != null ? _mapFromPersistence(persistence) : null;
  }

  /// Get stock entry by identifier (IMEI or BatchID)
  Future<StockEntry?> getByIdentifier(String identifier) async {
    final persistence = await _isar.stockEntryPersistences
        .filter()
        .identifierEqualTo(identifier)
        .findFirst();
    return persistence != null ? _mapFromPersistence(persistence) : null;
  }

  /// Get all stock entries for a product
  Future<List<StockEntry>> getByProduct(String productId) async {
    final persistence = await _isar.stockEntryPersistences
        .filter()
        .productIdEqualTo(productId)
        .findAll();
    return persistence.map(_mapFromPersistence).toList();
  }

  /// Get available stock entries for a product (available or reserved)
  Future<List<StockEntry>> getAvailableStock(String productId) async {
    final persistence = await _isar.stockEntryPersistences
        .filter()
        .productIdEqualTo(productId)
        .group((q) => q
            .statusEqualTo(StockStatus.available.name)
            .or()
            .statusEqualTo(StockStatus.reserved.name))
        .sortByCreatedAt() // FIFO ordering
        .findAll();
    return persistence.map(_mapFromPersistence).toList();
  }

  /// Get total available quantity for a product
  Future<double> getAvailableQuantity(String productId) async {
    final entries = await getAvailableStock(productId);
    double total = 0.0;
    for (final entry in entries) {
      total += entry.quantity;
    }
    return total;
  }

  /// Get stock by status
  Future<List<StockEntry>> getByStatus(StockStatus status) async {
    final persistence = await _isar.stockEntryPersistences
        .filter()
        .statusEqualTo(status.name)
        .findAll();
    return persistence.map(_mapFromPersistence).toList();
  }

  /// Get stock by location
  Future<List<StockEntry>> getByLocation(String locationId) async {
    final persistence = await _isar.stockEntryPersistences
        .filter()
        .locationIdEqualTo(locationId)
        .findAll();
    return persistence.map(_mapFromPersistence).toList();
  }

  /// Get stock by purchase bill
  Future<List<StockEntry>> getByPurchaseBill(String billNo) async {
    final persistence = await _isar.stockEntryPersistences
        .filter()
        .purchaseBillNoEqualTo(billNo)
        .findAll();
    return persistence.map(_mapFromPersistence).toList();
  }

  /// Search stock by identifier (partial match)
  Future<List<StockEntry>> search(String query) async {
    final persistence = await _isar.stockEntryPersistences
        .filter()
        .identifierContains(query)
        .findAll();
    return persistence.map(_mapFromPersistence).toList();
  }

  /// Get total inventory value (sum of quantity * purchasePrice for available stock)
  Future<double> getTotalInventoryValue({String? companyId}) async {
    List<StockEntryPersistence> persistence;
    if (companyId != null) {
      persistence = await _isar.stockEntryPersistences
          .filter()
          .companyIdEqualTo(companyId)
          .statusEqualTo(StockStatus.available.name)
          .findAll();
    } else {
      persistence = await _isar.stockEntryPersistences
          .filter()
          .statusEqualTo(StockStatus.available.name)
          .findAll();
    }
    double total = 0.0;
    for (final entry in persistence) {
      total += entry.quantity * entry.purchasePrice;
    }
    return total;
  }

  // ============================================================
  // WRITE OPERATIONS
  // ============================================================

  /// Save a single stock entry
  Future<void> save(StockEntry entry) async {
    final persistence = _mapToPersistence(entry);
    await _isar.writeTxn(() async {
      await _isar.stockEntryPersistences.put(persistence);
    });
  }

  /// Save multiple stock entries (bulk import)
  Future<void> saveAll(List<StockEntry> entries) async {
    final persistences = entries.map(_mapToPersistence).toList();
    await _isar.writeTxn(() async {
      await _isar.stockEntryPersistences.putAll(persistences);
    });
  }

  /// Add serialized unit (single unit with IMEI, quantity = 1)
  Future<void> addSerializedUnit(StockEntry entry) async {
    if (entry.quantity != 1) {
      throw ArgumentError('Serialized units must have quantity = 1');
    }
    if (entry.identifier == null || entry.identifier!.isEmpty) {
      throw ArgumentError('Serialized units must have an identifier (IMEI)');
    }
    await save(entry);
  }

  /// Add non-serialized batch (quantity > 0)
  Future<void> addBatch(StockEntry entry) async {
    if (entry.quantity <= 0) {
      throw ArgumentError('Batch quantity must be greater than 0');
    }
    await save(entry);
  }

  /// Save entries from a stock batch (for purchase import)
  Future<void> saveBatch(StockBatch batch) async {
    final entries = batch.toStockEntries();
    await saveAll(entries);
  }

  // ============================================================
  // SALE OPERATIONS
  // ============================================================

  /// Mark a specific stock entry as sold
  Future<void> markAsSold({
    required String stockId,
    required String saleBillNo,
    required double soldPrice,
    required DateTime saleDate,
    double? qtySold,
  }) async {
    await _isar.writeTxn(() async {
      final persistence = await _isar.stockEntryPersistences
          .filter()
          .stockIdEqualTo(stockId)
          .findFirst();
      if (persistence != null) {
        persistence.status = StockStatus.sold.name;
        persistence.saleBillNo = saleBillNo;
        persistence.soldPrice = soldPrice;
        persistence.saleDate = saleDate;
        if (qtySold != null) {
          persistence.quantity = qtySold;
        }
        persistence.updatedAt = DateTime.now();
        await _isar.stockEntryPersistences.put(persistence);
      }
    });
  }

  /// Deduct stock using FIFO (for non-serialized items)
  /// Returns list of affected stockIds
  Future<List<String>> deductStockFifo({
    required String productId,
    required double quantity,
    required String saleBillNo,
    required double soldPrice,
    required DateTime saleDate,
  }) async {
    final affectedIds = <String>[];
    var remainingQty = quantity;

    await _isar.writeTxn(() async {
      // Get available stock ordered by createdAt (FIFO)
      final available = await _isar.stockEntryPersistences
          .filter()
          .productIdEqualTo(productId)
          .statusEqualTo(StockStatus.available.name)
          .sortByCreatedAt()
          .findAll();

      for (final entry in available) {
        if (remainingQty <= 0) break;

        final availableQty = entry.quantity;

        if (availableQty <= remainingQty) {
          // Consume entire entry
          entry.status = StockStatus.sold.name;
          entry.saleBillNo = saleBillNo;
          entry.soldPrice = soldPrice;
          entry.saleDate = saleDate;
          entry.updatedAt = DateTime.now();
          remainingQty -= availableQty;
          affectedIds.add(entry.stockId);
          await _isar.stockEntryPersistences.put(entry);
        } else {
          // Partial consumption - split the entry
          final consumeQty = remainingQty;
          entry.quantity = availableQty - consumeQty;
          entry.updatedAt = DateTime.now();
          await _isar.stockEntryPersistences.put(entry);

          // Create sold entry for consumed quantity
          final soldEntry = StockEntryPersistence()
            ..stockId =
                'STK_${DateTime.now().millisecondsSinceEpoch}_SPLIT_${entry.stockId}'
            ..productId = entry.productId
            ..identifier = entry.identifier
            ..quantity = consumeQty
            ..purchasePrice = entry.purchasePrice
            ..locationId = entry.locationId
            ..status = StockStatus.sold.name
            ..purchaseBillNo = entry.purchaseBillNo
            ..saleBillNo = saleBillNo
            ..purchaseDate = entry.purchaseDate
            ..saleDate = saleDate
            ..soldPrice = soldPrice
            ..color = entry.color
            ..warranty = entry.warranty
            ..activationStatus = entry.activationStatus
            ..companyId = entry.companyId
            ..notes = entry.notes
            ..createdAt = entry.createdAt
            ..updatedAt = DateTime.now()
            ..isSynced = false;

          await _isar.stockEntryPersistences.put(soldEntry);
          affectedIds.add(soldEntry.stockId);
          remainingQty = 0;
        }
      }
    });

    if (remainingQty > 0) {
      throw StateError(
          'Insufficient stock. Requested: $quantity, Available: ${quantity - remainingQty}');
    }

    return affectedIds;
  }

  /// Mark stock entry as reserved
  Future<void> reserve(String stockId) async {
    await _isar.writeTxn(() async {
      final persistence = await _isar.stockEntryPersistences
          .filter()
          .stockIdEqualTo(stockId)
          .findFirst();
      if (persistence != null) {
        persistence.status = StockStatus.reserved.name;
        persistence.updatedAt = DateTime.now();
        await _isar.stockEntryPersistences.put(persistence);
      }
    });
  }

  /// Restock entry (after sale return)
  Future<void> restock(String stockId) async {
    await _isar.writeTxn(() async {
      final persistence = await _isar.stockEntryPersistences
          .filter()
          .stockIdEqualTo(stockId)
          .findFirst();
      if (persistence != null) {
        persistence.status = StockStatus.available.name;
        persistence.saleBillNo = null;
        persistence.soldPrice = null;
        persistence.saleDate = null;
        persistence.updatedAt = DateTime.now();
        await _isar.stockEntryPersistences.put(persistence);
      }
    });
  }

  /// Issue stock to a new location
  Future<void> issueToLocation(String stockId, String locationId) async {
    await _isar.writeTxn(() async {
      final persistence = await _isar.stockEntryPersistences
          .filter()
          .stockIdEqualTo(stockId)
          .findFirst();
      if (persistence != null) {
        persistence.locationId = locationId;
        persistence.updatedAt = DateTime.now();
        await _isar.stockEntryPersistences.put(persistence);
      }
    });
  }

  /// Delete stock entry by stockId
  Future<void> delete(String stockId) async {
    await _isar.writeTxn(() async {
      await _isar.stockEntryPersistences
          .filter()
          .stockIdEqualTo(stockId)
          .deleteFirst();
    });
  }

  // ============================================================
  // VALIDATION
  // ============================================================

  /// Check if identifier (IMEI/BatchID) exists
  Future<bool> identifierExists(String identifier) async {
    final count = await _isar.stockEntryPersistences
        .filter()
        .identifierEqualTo(identifier)
        .count();
    return count > 0;
  }

  /// Check if stock is available for sale
  Future<bool> isAvailableForSale(String stockId) async {
    final entry = await getById(stockId);
    return entry?.isAvailableForSale ?? false;
  }

  /// Validate if a sale can be made
  Future<bool> validateForSale({
    required String productId,
    required bool isSerialized,
    required double quantity,
  }) async {
    if (isSerialized && quantity != 1) {
      return false; // Serialized items must have quantity = 1
    }
    final availableQty = await getAvailableQuantity(productId);
    return availableQty >= quantity;
  }

  /// Validate list of identifiers (IMEIs) for sale
  Future<List<String>> validateIdentifiersForSale(
      List<String> identifiers) async {
    final invalid = <String>[];
    for (final id in identifiers) {
      final entry = await getByIdentifier(id);
      if (entry == null || !entry.isAvailableForSale) {
        invalid.add(id);
      }
    }
    return invalid;
  }

  // ============================================================
  // STATISTICS
  // ============================================================

  /// Count entries by status
  Future<int> countByStatus(StockStatus status) async {
    return await _isar.stockEntryPersistences
        .filter()
        .statusEqualTo(status.name)
        .count();
  }

  /// Get stock count (quantity sum) by product
  Future<double> getStockQuantity(String productId) async {
    return await getAvailableQuantity(productId);
  }

  // ============================================================
  // MAPPERS
  // ============================================================

  StockEntry _mapFromPersistence(StockEntryPersistence p) {
    return StockEntry(
      stockId: p.stockId,
      productId: p.productId,
      identifier: p.identifier,
      quantity: p.quantity,
      purchasePrice: p.purchasePrice,
      locationId: p.locationId,
      status: _parseStatus(p.status),
      purchaseBillNo: p.purchaseBillNo,
      saleBillNo: p.saleBillNo,
      purchaseDate: p.purchaseDate,
      saleDate: p.saleDate,
      soldPrice: p.soldPrice,
      color: p.color,
      warranty: p.warranty,
      activationStatus: p.activationStatus,
      companyId: p.companyId,
      notes: p.notes,
      createdAt: p.createdAt,
      updatedAt: p.updatedAt,
    );
  }

  StockEntryPersistence _mapToPersistence(StockEntry e) {
    return StockEntryPersistence()
      ..stockId = e.stockId
      ..productId = e.productId
      ..identifier = e.identifier
      ..quantity = e.quantity
      ..purchasePrice = e.purchasePrice
      ..locationId = e.locationId
      ..status = e.status.name
      ..purchaseBillNo = e.purchaseBillNo
      ..saleBillNo = e.saleBillNo
      ..purchaseDate = e.purchaseDate
      ..saleDate = e.saleDate
      ..soldPrice = e.soldPrice
      ..color = e.color
      ..warranty = e.warranty
      ..activationStatus = e.activationStatus
      ..companyId = e.companyId
      ..notes = e.notes
      ..createdAt = e.createdAt
      ..updatedAt = e.updatedAt
      ..isSynced = false;
  }

  StockStatus _parseStatus(String status) {
    switch (status) {
      case 'available':
        return StockStatus.available;
      case 'sold':
        return StockStatus.sold;
      case 'reserved':
        return StockStatus.reserved;
      case 'returned':
        return StockStatus.returned;
      default:
        return StockStatus.available;
    }
  }
}

/// Provider for StockLedgerRepository
final stockLedgerRepositoryProvider = Provider<StockLedgerRepository>((ref) {
  final isarService = ref.watch(isarServiceProvider);
  return StockLedgerRepository(isarService);
});
