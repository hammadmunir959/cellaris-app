/// Location model for physical inventory tracking
/// Supports warehouse, shop floor, and bin/shelf level tracking

enum LocationType {
  warehouse,
  shopFloor,
  bin,
  shelf,
  other,
}

class Location {
  final String id;
  final String name;
  final String? code;
  final LocationType type;
  final String? companyId;
  final String? parentLocationId; // For hierarchical locations (e.g., Bin within Warehouse)
  final String? address;
  final bool isActive;
  final DateTime createdAt;

  const Location({
    required this.id,
    required this.name,
    this.code,
    required this.type,
    this.companyId,
    this.parentLocationId,
    this.address,
    this.isActive = true,
    required this.createdAt,
  });

  /// User-friendly type name
  String get typeName {
    switch (type) {
      case LocationType.warehouse:
        return 'Warehouse';
      case LocationType.shopFloor:
        return 'Shop Floor';
      case LocationType.bin:
        return 'Bin';
      case LocationType.shelf:
        return 'Shelf';
      case LocationType.other:
        return 'Other';
    }
  }

  Location copyWith({
    String? id,
    String? name,
    String? code,
    LocationType? type,
    String? companyId,
    String? parentLocationId,
    String? address,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return Location(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      type: type ?? this.type,
      companyId: companyId ?? this.companyId,
      parentLocationId: parentLocationId ?? this.parentLocationId,
      address: address ?? this.address,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Stock Issuance record for tracking internal inventory movements
class StockIssuance {
  final String id;
  final String fromLocationId;
  final String toLocationId;
  final List<String> imeis; // List of IMEIs being moved
  final DateTime issuedAt;
  final String issuedBy;
  final String? notes;
  final String? companyId;

  const StockIssuance({
    required this.id,
    required this.fromLocationId,
    required this.toLocationId,
    required this.imeis,
    required this.issuedAt,
    required this.issuedBy,
    this.notes,
    this.companyId,
  });

  int get quantity => imeis.length;

  StockIssuance copyWith({
    String? id,
    String? fromLocationId,
    String? toLocationId,
    List<String>? imeis,
    DateTime? issuedAt,
    String? issuedBy,
    String? notes,
    String? companyId,
  }) {
    return StockIssuance(
      id: id ?? this.id,
      fromLocationId: fromLocationId ?? this.fromLocationId,
      toLocationId: toLocationId ?? this.toLocationId,
      imeis: imeis ?? this.imeis,
      issuedAt: issuedAt ?? this.issuedAt,
      issuedBy: issuedBy ?? this.issuedBy,
      notes: notes ?? this.notes,
      companyId: companyId ?? this.companyId,
    );
  }
}
