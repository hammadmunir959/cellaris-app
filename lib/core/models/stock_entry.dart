/// Unified stock entry model
/// Handles both serialized items (IMEI-tracked) and non-serialized items (quantity-tracked)
///
/// For Mobiles: Each entry represents one device with a unique IMEI (quantity = 1)
/// For Accessories: Each entry represents a batch of items (quantity = N)

/// Stock status lifecycle
enum StockStatus {
  available,  // In stock, ready for sale
  sold,       // Sold to customer
  reserved,   // Reserved for pending order
  returned,   // Returned from customer
}

/// Represents a stock entry in the unified stock ledger
class StockEntry {
  final String stockId;          // Unique ID for this stock entry
  final String productId;        // FK to Product
  final String? identifier;      // IMEI for serialized, BatchID for non-serialized (optional)
  final double quantity;         // Always 1 for serialized, N for non-serialized
  final double purchasePrice;    // Landed cost per unit (essential for P&L)
  final String? locationId;      // Warehouse, Shop Floor, or Bin
  final StockStatus status;      // Current stock status
  final String? purchaseBillNo;  // Origin purchase invoice
  final String? saleBillNo;      // Destination sale invoice (null if not sold)
  final DateTime? purchaseDate;
  final DateTime? saleDate;
  final double? soldPrice;       // Actual sale price per unit
  final String? color;
  final String? warranty;
  final String? activationStatus;
  final String? companyId;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const StockEntry({
    required this.stockId,
    required this.productId,
    this.identifier,
    required this.quantity,
    required this.purchasePrice,
    this.locationId,
    this.status = StockStatus.available,
    this.purchaseBillNo,
    this.saleBillNo,
    this.purchaseDate,
    this.saleDate,
    this.soldPrice,
    this.color,
    this.warranty,
    this.activationStatus,
    this.companyId,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Total value of this stock entry
  double get totalValue => quantity * purchasePrice;

  /// Check if this stock entry is available for sale
  bool get isAvailableForSale =>
      status == StockStatus.available || status == StockStatus.reserved;

  /// Check if this is a serialized entry (single unit with identifier)
  bool get isSerialized => quantity == 1 && identifier != null;

  /// Calculate profit for this entry (if sold)
  double? get profit {
    if (soldPrice == null || status != StockStatus.sold) return null;
    return (soldPrice! - purchasePrice) * quantity;
  }

  StockEntry copyWith({
    String? stockId,
    String? productId,
    String? identifier,
    double? quantity,
    double? purchasePrice,
    String? locationId,
    StockStatus? status,
    String? purchaseBillNo,
    String? saleBillNo,
    DateTime? purchaseDate,
    DateTime? saleDate,
    double? soldPrice,
    String? color,
    String? warranty,
    String? activationStatus,
    String? companyId,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StockEntry(
      stockId: stockId ?? this.stockId,
      productId: productId ?? this.productId,
      identifier: identifier ?? this.identifier,
      quantity: quantity ?? this.quantity,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      locationId: locationId ?? this.locationId,
      status: status ?? this.status,
      purchaseBillNo: purchaseBillNo ?? this.purchaseBillNo,
      saleBillNo: saleBillNo ?? this.saleBillNo,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      saleDate: saleDate ?? this.saleDate,
      soldPrice: soldPrice ?? this.soldPrice,
      color: color ?? this.color,
      warranty: warranty ?? this.warranty,
      activationStatus: activationStatus ?? this.activationStatus,
      companyId: companyId ?? this.companyId,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Create a copy marked as sold
  StockEntry markAsSold({
    required String saleBillNo,
    required double soldPrice,
    required DateTime saleDate,
    double? qtySold,
  }) {
    return copyWith(
      status: StockStatus.sold,
      saleBillNo: saleBillNo,
      soldPrice: soldPrice,
      saleDate: saleDate,
      quantity: qtySold ?? quantity,
      updatedAt: DateTime.now(),
    );
  }

  /// Create a copy marked as returned
  StockEntry markAsReturned() {
    return copyWith(
      status: StockStatus.returned,
      updatedAt: DateTime.now(),
    );
  }

  /// Create a copy with reserved status
  StockEntry reserve() {
    return copyWith(
      status: StockStatus.reserved,
      updatedAt: DateTime.now(),
    );
  }

  /// Restock this entry (after a sale return)
  StockEntry restock() {
    return StockEntry(
      stockId: stockId,
      productId: productId,
      identifier: identifier,
      quantity: quantity,
      purchasePrice: purchasePrice,
      locationId: locationId,
      status: StockStatus.available,
      purchaseBillNo: purchaseBillNo,
      saleBillNo: null,
      purchaseDate: purchaseDate,
      saleDate: null,
      soldPrice: null,
      color: color,
      warranty: warranty,
      activationStatus: activationStatus,
      companyId: companyId,
      notes: notes,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  /// Issue this entry to a new location
  StockEntry issueToLocation(String newLocationId) {
    return copyWith(
      locationId: newLocationId,
      updatedAt: DateTime.now(),
    );
  }
}

/// Batch operation helper for stock import
class StockBatch {
  final String productId;
  final List<String>? identifiers;  // IMEIs for serialized items
  final double quantity;            // Total quantity for non-serialized
  final double purchasePrice;
  final String purchaseBillNo;
  final DateTime purchaseDate;
  final String? color;
  final String? warranty;
  final String? locationId;
  final String? companyId;
  final bool isSerialized;

  const StockBatch({
    required this.productId,
    this.identifiers,
    required this.quantity,
    required this.purchasePrice,
    required this.purchaseBillNo,
    required this.purchaseDate,
    this.color,
    this.warranty,
    this.locationId,
    this.companyId,
    required this.isSerialized,
  });

  /// Generate StockEntry objects from this batch
  List<StockEntry> toStockEntries() {
    final now = DateTime.now();
    
    if (isSerialized && identifiers != null) {
      // Create one entry per IMEI
      return identifiers!.map((imei) => StockEntry(
        stockId: 'STK_${DateTime.now().millisecondsSinceEpoch}_$imei',
        productId: productId,
        identifier: imei,
        quantity: 1,
        purchasePrice: purchasePrice,
        locationId: locationId,
        status: StockStatus.available,
        purchaseBillNo: purchaseBillNo,
        purchaseDate: purchaseDate,
        color: color,
        warranty: warranty,
        companyId: companyId,
        createdAt: now,
        updatedAt: now,
      )).toList();
    } else {
      // Create a single batch entry for non-serialized items
      return [
        StockEntry(
          stockId: 'STK_${DateTime.now().millisecondsSinceEpoch}_BATCH',
          productId: productId,
          identifier: 'BATCH_${DateTime.now().millisecondsSinceEpoch}',
          quantity: quantity,
          purchasePrice: purchasePrice,
          locationId: locationId,
          status: StockStatus.available,
          purchaseBillNo: purchaseBillNo,
          purchaseDate: purchaseDate,
          color: color,
          warranty: warranty,
          companyId: companyId,
          createdAt: now,
          updatedAt: now,
        ),
      ];
    }
  }
}
