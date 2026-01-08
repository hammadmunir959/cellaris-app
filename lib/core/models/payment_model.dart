import 'package:cloud_firestore/cloud_firestore.dart';

/// Payment status for transactions
enum PaymentStatus {
  pending,
  completed,
  failed,
  refunded,
  cancelled,
}

/// Payment method types
enum PaymentMethod {
  easypaisa,
  jazzcash,
  bankTransfer,
  cash,
  card,
  other,
}

/// Subscription payment/transaction record
class PaymentRecord {
  final String id;
  final String userId;
  final double amount;
  final PaymentStatus status;
  final PaymentMethod method;
  final String? transactionId;
  final String? accountNumber;
  final String? accountTitle;
  final DateTime createdAt;
  final DateTime? verifiedAt;
  final String? verifiedBy;
  final String? notes;
  final String? screenshotUrl;
  final int durationDays;
  final DateTime? subscriptionStartDate;
  final DateTime? subscriptionEndDate;

  const PaymentRecord({
    required this.id,
    required this.userId,
    required this.amount,
    required this.status,
    required this.method,
    this.transactionId,
    this.accountNumber,
    this.accountTitle,
    required this.createdAt,
    this.verifiedAt,
    this.verifiedBy,
    this.notes,
    this.screenshotUrl,
    this.durationDays = 30,
    this.subscriptionStartDate,
    this.subscriptionEndDate,
  });

  /// Create from Firestore document
  factory PaymentRecord.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PaymentRecord.fromMap(doc.id, data);
  }

  /// Create from Map (for REST API)
  factory PaymentRecord.fromMap(String id, Map<String, dynamic> data) {
    return PaymentRecord(
      id: id,
      userId: data['userId'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      status: PaymentStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => PaymentStatus.pending,
      ),
      method: PaymentMethod.values.firstWhere(
        (e) => e.name == data['method'],
        orElse: () => PaymentMethod.other,
      ),
      transactionId: data['transactionId'],
      accountNumber: data['accountNumber'],
      accountTitle: data['accountTitle'],
      createdAt: _parseDateTime(data['createdAt']) ?? DateTime.now(),
      verifiedAt: _parseDateTime(data['verifiedAt']),
      verifiedBy: data['verifiedBy'],
      notes: data['notes'],
      screenshotUrl: data['screenshotUrl'],
      durationDays: data['durationDays'] ?? 30,
      subscriptionStartDate: _parseDateTime(data['subscriptionStartDate']),
      subscriptionEndDate: _parseDateTime(data['subscriptionEndDate']),
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() => {
    'userId': userId,
    'amount': amount,
    'status': status.name,
    'method': method.name,
    'transactionId': transactionId,
    'accountNumber': accountNumber,
    'accountTitle': accountTitle,
    'createdAt': Timestamp.fromDate(createdAt),
    'verifiedAt': verifiedAt != null ? Timestamp.fromDate(verifiedAt!) : null,
    'verifiedBy': verifiedBy,
    'notes': notes,
    'screenshotUrl': screenshotUrl,
    'durationDays': durationDays,
    'subscriptionStartDate': subscriptionStartDate != null 
        ? Timestamp.fromDate(subscriptionStartDate!) : null,
    'subscriptionEndDate': subscriptionEndDate != null 
        ? Timestamp.fromDate(subscriptionEndDate!) : null,
  };

  /// Get formatted method name
  String get methodName => switch (method) {
    PaymentMethod.easypaisa => 'EasyPaisa',
    PaymentMethod.jazzcash => 'JazzCash',
    PaymentMethod.bankTransfer => 'Bank Transfer',
    PaymentMethod.cash => 'Cash',
    PaymentMethod.card => 'Card',
    PaymentMethod.other => 'Other',
  };

  /// Get status display text
  String get statusText => switch (status) {
    PaymentStatus.pending => 'Pending',
    PaymentStatus.completed => 'Completed',
    PaymentStatus.failed => 'Failed',
    PaymentStatus.refunded => 'Refunded',
    PaymentStatus.cancelled => 'Cancelled',
  };

  /// Check if payment is successful
  bool get isSuccessful => status == PaymentStatus.completed;

  /// Check if payment is pending
  bool get isPending => status == PaymentStatus.pending;
}

/// Subscription history entry (aggregated from payments)
class SubscriptionPeriod {
  final DateTime startDate;
  final DateTime endDate;
  final double amountPaid;
  final PaymentMethod? paymentMethod;
  final String? transactionId;
  final bool isActive;

  const SubscriptionPeriod({
    required this.startDate,
    required this.endDate,
    required this.amountPaid,
    this.paymentMethod,
    this.transactionId,
    this.isActive = false,
  });

  /// Duration in days
  int get durationDays => endDate.difference(startDate).inDays;

  /// Check if currently active
  bool get isCurrent {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate);
  }
}
