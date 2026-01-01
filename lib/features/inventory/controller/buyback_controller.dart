import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

/// Represents a complete Used Phone Buyback record with seller and phone details
class BuybackRecord {
  final String id;
  final String productId; // Links to Product in inventory
  
  // Seller Information
  final String sellerName;
  final String sellerPhone;
  final String sellerCnic;
  final String? cnicFrontPath;
  final String? cnicBackPath;
  
  // Phone Information
  final String brand;
  final String model;
  final String imei;
  final String? imei2; // For dual-SIM phones
  final String? variant;
  final String condition;
  final double purchasePrice;
  final String? phoneImage1Path;
  final String? phoneImage2Path;
  
  // Timestamps
  final DateTime createdAt;
  final String? notes;
  
  BuybackRecord({
    required this.id,
    required this.productId,
    required this.sellerName,
    required this.sellerPhone,
    required this.sellerCnic,
    this.cnicFrontPath,
    this.cnicBackPath,
    required this.brand,
    required this.model,
    required this.imei,
    this.imei2,
    this.variant,
    required this.condition,
    required this.purchasePrice,
    this.phoneImage1Path,
    this.phoneImage2Path,
    DateTime? createdAt,
    this.notes,
  }) : createdAt = createdAt ?? DateTime.now();
  
  String get fullPhoneName => '$brand $model';
  String get displayImei => imei2 != null ? '$imei / $imei2' : imei;
  
  BuybackRecord copyWith({
    String? sellerName,
    String? sellerPhone,
    String? sellerCnic,
    String? cnicFrontPath,
    String? cnicBackPath,
    String? notes,
    String? phoneImage1Path,
    String? phoneImage2Path,
  }) {
    return BuybackRecord(
      id: id,
      productId: productId,
      sellerName: sellerName ?? this.sellerName,
      sellerPhone: sellerPhone ?? this.sellerPhone,
      sellerCnic: sellerCnic ?? this.sellerCnic,
      cnicFrontPath: cnicFrontPath ?? this.cnicFrontPath,
      cnicBackPath: cnicBackPath ?? this.cnicBackPath,
      brand: brand,
      model: model,
      imei: imei,
      imei2: imei2,
      variant: variant,
      condition: condition,
      purchasePrice: purchasePrice,
      phoneImage1Path: phoneImage1Path ?? this.phoneImage1Path,
      phoneImage2Path: phoneImage2Path ?? this.phoneImage2Path,
      createdAt: createdAt,
      notes: notes ?? this.notes,
    );
  }
}

/// State notifier for managing buyback records
class BuybackNotifier extends StateNotifier<List<BuybackRecord>> {
  BuybackNotifier() : super([]);
  
  void addRecord(BuybackRecord record) {
    state = [...state, record];
  }
  
  void deleteRecord(String id) {
    state = state.where((r) => r.id != id).toList();
  }
  
  BuybackRecord? getByProductId(String productId) {
    try {
      return state.firstWhere((r) => r.productId == productId);
    } catch (_) {
      return null;
    }
  }
  
  BuybackRecord? getById(String id) {
    try {
      return state.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }
}

/// Provider for buyback records
final buybackProvider = StateNotifierProvider<BuybackNotifier, List<BuybackRecord>>((ref) {
  return BuybackNotifier();
});
