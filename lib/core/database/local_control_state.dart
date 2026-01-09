import 'package:isar_community/isar.dart';

part 'local_control_state.g.dart';

// ============================================================
// LOCAL CONTROL STATE PERSISTENCE
// ============================================================
/// Isar collection for offline tracking metadata.
/// 
/// This stores sync timestamps and offline usage counters.
/// The actual control document (sensitive data) remains in
/// FlutterSecureStorage with AES encryption.
/// 
/// Used by AccessGuardService to:
/// - Track offline days (offlineDaysUsed vs maxOfflineDays)
/// - Detect time tampering (lastServerTime check)
/// - Trigger forced sync when limits exceeded
@collection
class LocalControlStatePersistence {
  Id isarId = Isar.autoIncrement;

  /// Singleton key - always "current_user"
  @Index(unique: true, replace: true)
  late String id;

  /// Firebase UID of the current user
  late String userId;

  /// Cached status for quick offline checks
  /// Values: pending, active, expired, blocked
  late String status;

  /// Cached subscription end date for offline expiry checks
  late DateTime subscriptionEndDate;

  /// When the control document was last synced from Firebase
  late DateTime lastSyncedAt;

  /// Server timestamp from last successful sync (for anti-tampering)
  /// If device time < lastServerTime, tampering is detected
  late DateTime lastServerTime;

  /// Number of days the app has been used offline since last sync
  late int offlineDaysUsed;

  /// Maximum allowed offline days (from admin settings)
  late int maxOfflineDays;

  /// Last date when the app was online (for calculating offline days)
  late DateTime lastOnlineDate;

  /// Record creation timestamp
  late DateTime createdAt;

  /// Last update timestamp
  late DateTime updatedAt;

  // ========================================
  // COMPUTED PROPERTIES
  // ========================================

  /// Check if offline limit has been exceeded
  bool get isOfflineLimitExceeded => offlineDaysUsed > maxOfflineDays;

  /// Check if device time appears to be tampered with
  bool isTimeTampered(DateTime currentTime) => 
      currentTime.isBefore(lastServerTime);

  /// Check if subscription is expired based on cached data
  bool get isSubscriptionExpired => 
      DateTime.now().isAfter(subscriptionEndDate);

  /// Days remaining until subscription expires
  int get daysUntilExpiry => 
      subscriptionEndDate.difference(DateTime.now()).inDays;

  // ========================================
  // FACTORY CONSTRUCTORS
  // ========================================

  /// Create a new control state from a sync operation
  static LocalControlStatePersistence fromSync({
    required String userId,
    required String status,
    required DateTime subscriptionEndDate,
    required DateTime serverTime,
    required int maxOfflineDays,
  }) {
    final now = DateTime.now();
    return LocalControlStatePersistence()
      ..id = 'current_user'
      ..userId = userId
      ..status = status
      ..subscriptionEndDate = subscriptionEndDate
      ..lastSyncedAt = now
      ..lastServerTime = serverTime
      ..offlineDaysUsed = 0
      ..maxOfflineDays = maxOfflineDays
      ..lastOnlineDate = now
      ..createdAt = now
      ..updatedAt = now;
  }

  /// Update the control state for a new day offline
  LocalControlStatePersistence incrementOfflineDay() {
    offlineDaysUsed += 1;
    updatedAt = DateTime.now();
    return this;
  }

  /// Reset offline counter after successful sync
  LocalControlStatePersistence resetAfterSync(DateTime serverTime) {
    final now = DateTime.now();
    offlineDaysUsed = 0;
    lastSyncedAt = now;
    lastServerTime = serverTime;
    lastOnlineDate = now;
    updatedAt = now;
    return this;
  }

  @override
  String toString() => 
      'LocalControlState(userId: $userId, status: $status, '
      'offlineDays: $offlineDaysUsed/$maxOfflineDays, '
      'lastSync: $lastSyncedAt)';
}
