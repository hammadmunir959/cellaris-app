import 'package:cloud_firestore/cloud_firestore.dart';

/// User status for subscription management
enum UserStatus {
  /// Just registered, waiting for admin approval
  pending,
  /// Trial period active
  trial,
  /// Subscription active
  active,
  /// Subscription expired
  expired,
  /// User canceled subscription
  canceled,
  /// Account blocked by admin
  blocked,
  /// Payment verification pending
  pendingVerification,
}

/// User roles for access control
enum UserRole {
  administrator,
  stockManager,
  salesProfessional,
  accountant,
}

/// App User model with subscription and role information
class AppUser {
  final String id;
  final String email;
  final String name;
  final UserRole role;
  final DateTime subscriptionExpiry;
  final UserStatus status;
  final String? screenshotURL;
  final String? companyId;
  final String? locationId;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final Map<String, dynamic>? paymentDetails;

  AppUser({
    required this.id,
    required this.email,
    required this.name,
    this.role = UserRole.salesProfessional,
    required this.subscriptionExpiry,
    required this.status,
    this.screenshotURL,
    this.companyId,
    this.locationId,
    required this.createdAt,
    this.lastLoginAt,
    this.paymentDetails,
  });

  /// Check if subscription is currently valid
  bool get isSubscriptionValid =>
      status == UserStatus.active &&
      DateTime.now().isBefore(subscriptionExpiry);

  /// Check if user has pending payment verification
  bool get isPendingVerification => status == UserStatus.pendingVerification;

  /// Check if subscription is expired
  bool get isExpired =>
      status == UserStatus.expired ||
      DateTime.now().isAfter(subscriptionExpiry);

  /// Days until subscription expires (negative if expired)
  int get daysUntilExpiry =>
      subscriptionExpiry.difference(DateTime.now()).inDays;

  /// Create user from Firestore document
  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppUser.fromMap(doc.id, data);
  }

  /// Create user from Map data (used by firebase_dart for desktop)
  factory AppUser.fromMap(String id, Map<String, dynamic> data) {
    return AppUser(
      id: id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.name == data['role'],
        orElse: () => UserRole.salesProfessional,
      ),
      subscriptionExpiry: _parseDateTime(data['subscriptionExpiry'] ?? 
          data['subscription']?['endDate']) ?? DateTime.now(),
      status: UserStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => UserStatus.expired,
      ),
      screenshotURL: data['screenshotURL'],
      companyId: data['companyId'],
      locationId: data['locationId'],
      createdAt: _parseDateTime(data['createdAt']) ?? DateTime.now(),
      lastLoginAt: _parseDateTime(data['lastLoginAt']),
      paymentDetails: data['payment'] != null 
          ? Map<String, dynamic>.from(data['payment']) 
          : null,
    );
  }

  /// Helper to parse DateTime from various formats
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  /// Convert user to Firestore document
  Map<String, dynamic> toFirestore() => {
        'email': email,
        'name': name,
        'role': role.name,
        'subscriptionExpiry': Timestamp.fromDate(subscriptionExpiry),
        'status': status.name,
        'screenshotURL': screenshotURL,
        'companyId': companyId,
        'locationId': locationId,
        'createdAt': Timestamp.fromDate(createdAt),
        'lastLoginAt':
            lastLoginAt != null ? Timestamp.fromDate(lastLoginAt!) : null,
        if (paymentDetails != null) 'payment': paymentDetails,
      };

  /// Create a copy with modified fields
  AppUser copyWith({
    String? name,
    UserRole? role,
    DateTime? subscriptionExpiry,
    UserStatus? status,
    String? screenshotURL,
    String? companyId,
    String? locationId,
    DateTime? lastLoginAt,
    Map<String, dynamic>? paymentDetails,
  }) {
    return AppUser(
      id: id,
      email: email,
      name: name ?? this.name,
      role: role ?? this.role,
      subscriptionExpiry: subscriptionExpiry ?? this.subscriptionExpiry,
      status: status ?? this.status,
      screenshotURL: screenshotURL ?? this.screenshotURL,
      companyId: companyId ?? this.companyId,
      locationId: locationId ?? this.locationId,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      paymentDetails: paymentDetails ?? this.paymentDetails,
    );
  }

  @override
  String toString() =>
      'AppUser(id: $id, email: $email, name: $name, role: $role, status: $status)';
}
