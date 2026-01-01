import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Types of transactions in the system
enum TransactionType {
  sale,
  purchase,
  buyback,
  repair,
  return_,
  stockAdjustment,
  purchaseOrder,
}

/// Status of a transaction
enum TransactionStatus {
  pending,
  completed,
  cancelled,
  refunded,
}

/// Unified transaction log entry for audit trail
class TransactionLog {
  final String id;
  final TransactionType type;
  final TransactionStatus status;
  final DateTime timestamp;
  final String referenceId; // ID of sale, purchase, repair, etc.
  final String? referenceNumber; // Invoice/PO/Receipt number
  
  // Parties
  final String? customerId;
  final String? customerName;
  final String? supplierId;
  final String? supplierName;
  
  // Financial
  final double amount;
  final String? paymentMethod;
  
  // Items
  final List<TransactionItem> items;
  
  // Metadata
  final String? notes;
  final String? createdBy;
  final Map<String, dynamic>? metadata; // Extra data like images, etc.
  
  TransactionLog({
    required this.id,
    required this.type,
    required this.status,
    required this.timestamp,
    required this.referenceId,
    this.referenceNumber,
    this.customerId,
    this.customerName,
    this.supplierId,
    this.supplierName,
    required this.amount,
    this.paymentMethod,
    this.items = const [],
    this.notes,
    this.createdBy,
    this.metadata,
  });
  
  String get typeLabel {
    switch (type) {
      case TransactionType.sale: return 'Sale';
      case TransactionType.purchase: return 'Purchase';
      case TransactionType.buyback: return 'Buyback';
      case TransactionType.repair: return 'Repair';
      case TransactionType.return_: return 'Return';
      case TransactionType.stockAdjustment: return 'Stock Adjustment';
      case TransactionType.purchaseOrder: return 'Purchase Order';
    }
  }
  
  String get partyName => customerName ?? supplierName ?? 'N/A';
  
  bool get isIncome => type == TransactionType.sale || type == TransactionType.repair;
  bool get isExpense => type == TransactionType.purchase || type == TransactionType.buyback || type == TransactionType.purchaseOrder;
}

/// Individual item in a transaction
class TransactionItem {
  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final String? imei;
  
  TransactionItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    this.imei,
  });
  
  double get total => quantity * unitPrice;
}

/// State notifier for managing transaction logs
class TransactionLogNotifier extends StateNotifier<List<TransactionLog>> {
  TransactionLogNotifier() : super([]);
  
  /// Add a new transaction log
  void addLog(TransactionLog log) {
    state = [log, ...state]; // Newest first
  }
  
  /// Update a transaction's status
  void updateStatus(String id, TransactionStatus newStatus) {
    state = state.map((log) {
      if (log.id == id) {
        return TransactionLog(
          id: log.id,
          type: log.type,
          status: newStatus,
          timestamp: log.timestamp,
          referenceId: log.referenceId,
          referenceNumber: log.referenceNumber,
          customerId: log.customerId,
          customerName: log.customerName,
          supplierId: log.supplierId,
          supplierName: log.supplierName,
          amount: log.amount,
          paymentMethod: log.paymentMethod,
          items: log.items,
          notes: log.notes,
          createdBy: log.createdBy,
          metadata: log.metadata,
        );
      }
      return log;
    }).toList();
  }
  
  /// Get logs filtered by type
  List<TransactionLog> getByType(TransactionType type) {
    return state.where((log) => log.type == type).toList();
  }
  
  /// Get logs for a specific date range
  List<TransactionLog> getByDateRange(DateTime start, DateTime end) {
    return state.where((log) => 
      log.timestamp.isAfter(start) && log.timestamp.isBefore(end)
    ).toList();
  }
  
  /// Get logs for today
  List<TransactionLog> getToday() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    return state.where((log) => log.timestamp.isAfter(startOfDay)).toList();
  }
  
  /// Get logs for this week
  List<TransactionLog> getThisWeek() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final start = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    return state.where((log) => log.timestamp.isAfter(start)).toList();
  }
  
  /// Get logs for this month
  List<TransactionLog> getThisMonth() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    return state.where((log) => log.timestamp.isAfter(start)).toList();
  }
  
  /// Delete a log
  void deleteLog(String id) {
    state = state.where((log) => log.id != id).toList();
  }
  
  /// Clear all logs (for testing)
  void clearAll() {
    state = [];
  }
}

/// Provider for transaction logs
final transactionLogProvider = StateNotifierProvider<TransactionLogNotifier, List<TransactionLog>>((ref) {
  return TransactionLogNotifier();
});

/// Computed providers for filtered views
final todayTransactionsProvider = Provider<List<TransactionLog>>((ref) {
  final logs = ref.watch(transactionLogProvider);
  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);
  return logs.where((log) => log.timestamp.isAfter(startOfDay)).toList();
});

final salesTransactionsProvider = Provider<List<TransactionLog>>((ref) {
  return ref.watch(transactionLogProvider).where((log) => log.type == TransactionType.sale).toList();
});

final purchaseTransactionsProvider = Provider<List<TransactionLog>>((ref) {
  return ref.watch(transactionLogProvider).where((log) => 
    log.type == TransactionType.purchase || 
    log.type == TransactionType.buyback ||
    log.type == TransactionType.purchaseOrder
  ).toList();
});

final repairTransactionsProvider = Provider<List<TransactionLog>>((ref) {
  return ref.watch(transactionLogProvider).where((log) => log.type == TransactionType.repair).toList();
});
