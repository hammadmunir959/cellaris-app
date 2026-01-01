/// Unit (IMEI) tracking model for serialized inventory
/// Tracks individual mobile devices throughout their lifecycle

enum UnitStatus {
  inStock,    // Available for sale
  issued,     // Issued to a location/shop floor
  sold,       // Sold to customer
  returned,   // Returned from customer
}

/// Represents a specific physical instance of a Product, tracked by IMEI
class Unit {
  final String imei; // Unique serial number (Primary Key)
  final String productId;
  final String color;
  final String? locationId;
  final UnitStatus status;
  final String? purchaseBillNo; // Origin invoice
  final String? saleBillNo; // Destination invoice (null if not sold)
  final double? purchasePrice;
  final double? soldPrice;
  final DateTime? purchaseDate;
  final DateTime? saleDate;
  final String? warranty;
  final String? activationStatus;
  final String? companyId;
  final String? notes;

  const Unit({
    required this.imei,
    required this.productId,
    required this.color,
    this.locationId,
    this.status = UnitStatus.inStock,
    this.purchaseBillNo,
    this.saleBillNo,
    this.purchasePrice,
    this.soldPrice,
    this.purchaseDate,
    this.saleDate,
    this.warranty,
    this.activationStatus,
    this.companyId,
    this.notes,
  });

  /// Check if this unit can be sold
  bool get isAvailableForSale => 
      status == UnitStatus.inStock || status == UnitStatus.issued;

  /// Check if this unit can be returned to supplier
  bool get canReturnToSupplier => 
      status == UnitStatus.inStock && saleBillNo == null;

  Unit copyWith({
    String? imei,
    String? productId,
    String? color,
    String? locationId,
    UnitStatus? status,
    String? purchaseBillNo,
    String? saleBillNo,
    double? purchasePrice,
    double? soldPrice,
    DateTime? purchaseDate,
    DateTime? saleDate,
    String? warranty,
    String? activationStatus,
    String? companyId,
    String? notes,
  }) {
    return Unit(
      imei: imei ?? this.imei,
      productId: productId ?? this.productId,
      color: color ?? this.color,
      locationId: locationId ?? this.locationId,
      status: status ?? this.status,
      purchaseBillNo: purchaseBillNo ?? this.purchaseBillNo,
      saleBillNo: saleBillNo ?? this.saleBillNo,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      soldPrice: soldPrice ?? this.soldPrice,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      saleDate: saleDate ?? this.saleDate,
      warranty: warranty ?? this.warranty,
      activationStatus: activationStatus ?? this.activationStatus,
      companyId: companyId ?? this.companyId,
      notes: notes ?? this.notes,
    );
  }

  /// Create a copy with status updated to sold
  Unit markAsSold({
    required String saleBillNo,
    required double soldPrice,
    required DateTime saleDate,
  }) {
    return copyWith(
      status: UnitStatus.sold,
      saleBillNo: saleBillNo,
      soldPrice: soldPrice,
      saleDate: saleDate,
    );
  }

  /// Create a copy with status updated to returned
  Unit markAsReturned() {
    return copyWith(
      status: UnitStatus.returned,
    );
  }

  /// Create a copy with status updated to issued to location
  Unit issueToLocation(String locationId) {
    return copyWith(
      status: UnitStatus.issued,
      locationId: locationId,
    );
  }

  /// Re-stock this unit (after a sale return)
  Unit restock() {
    return Unit(
      imei: imei,
      productId: productId,
      color: color,
      locationId: locationId,
      status: UnitStatus.inStock,
      purchaseBillNo: purchaseBillNo,
      saleBillNo: null, // Clear sale reference
      purchasePrice: purchasePrice,
      soldPrice: null,
      purchaseDate: purchaseDate,
      saleDate: null,
      warranty: warranty,
      activationStatus: activationStatus,
      companyId: companyId,
      notes: notes,
    );
  }
}

/// Bulk operation helper for IMEI import
class UnitBatch {
  final List<String> imeis;
  final String productId;
  final String color;
  final String purchaseBillNo;
  final double purchasePrice;
  final DateTime purchaseDate;
  final String? warranty;
  final String? companyId;

  const UnitBatch({
    required this.imeis,
    required this.productId,
    required this.color,
    required this.purchaseBillNo,
    required this.purchasePrice,
    required this.purchaseDate,
    this.warranty,
    this.companyId,
  });

  /// Generate Unit objects from this batch
  List<Unit> toUnits() {
    return imeis.map((imei) => Unit(
      imei: imei,
      productId: productId,
      color: color,
      status: UnitStatus.inStock,
      purchaseBillNo: purchaseBillNo,
      purchasePrice: purchasePrice,
      purchaseDate: purchaseDate,
      warranty: warranty,
      companyId: companyId,
    )).toList();
  }
}
