import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import '../database/local_control_state.dart';
import '../database/isar_service.dart';

// ============================================================
// LOCAL CONTROL STATE REPOSITORY
// ============================================================
/// Repository for managing local control state in Isar.
/// 
/// This handles offline tracking metadata only:
/// - Offline days used vs max allowed
/// - Last sync timestamps
/// - Server time for anti-tampering
/// 
/// The actual control document (sensitive data) remains encrypted
/// in FlutterSecureStorage via AccessGuardService.
class LocalControlStateRepository {
  final IsarService _isarService;

  LocalControlStateRepository(this._isarService);

  Isar get _isar => _isarService.isar;

  // ========================================
  // READ OPERATIONS
  // ========================================

  /// Get the current control state (singleton record)
  Future<LocalControlStatePersistence?> getControlState() async {
    return await _isar.localControlStatePersistences
        .where()
        .idEqualTo('current_user')
        .findFirst();
  }

  /// Check if control state exists
  Future<bool> hasControlState() async {
    return await getControlState() != null;
  }

  // ========================================
  // WRITE OPERATIONS
  // ========================================

  /// Save or update the control state
  Future<void> saveControlState(LocalControlStatePersistence state) async {
    await _isar.writeTxn(() async {
      await _isar.localControlStatePersistences.put(state);
    });
  }

  /// Create initial control state after successful sync
  Future<void> initControlState({
    required String userId,
    required String status,
    required DateTime subscriptionEndDate,
    required DateTime serverTime,
    required int maxOfflineDays,
  }) async {
    final state = LocalControlStatePersistence.fromSync(
      userId: userId,
      status: status,
      subscriptionEndDate: subscriptionEndDate,
      serverTime: serverTime,
      maxOfflineDays: maxOfflineDays,
    );
    await saveControlState(state);
  }

  /// Update control state after a successful online sync
  Future<void> updateAfterSync({
    required String status,
    required DateTime subscriptionEndDate,
    required DateTime serverTime,
    required int maxOfflineDays,
  }) async {
    final existing = await getControlState();
    if (existing == null) return;

    existing
      ..status = status
      ..subscriptionEndDate = subscriptionEndDate
      ..maxOfflineDays = maxOfflineDays
      ..resetAfterSync(serverTime);

    await saveControlState(existing);
  }

  /// Increment offline days counter
  /// Called when app launches while offline
  Future<void> incrementOfflineDays() async {
    final state = await getControlState();
    if (state == null) return;

    final now = DateTime.now();
    final lastOnline = state.lastOnlineDate;
    
    // Only increment if it's a new day
    if (now.difference(lastOnline).inDays >= 1) {
      state.offlineDaysUsed += 1;
      state.updatedAt = now;
      await saveControlState(state);
    }
  }

  /// Update offline days used directly
  Future<void> updateOfflineDaysUsed(int days) async {
    final state = await getControlState();
    if (state == null) return;

    state.offlineDaysUsed = days;
    state.updatedAt = DateTime.now();
    await saveControlState(state);
  }

  /// Mark as online (reset offline tracking)
  Future<void> markAsOnline() async {
    final state = await getControlState();
    if (state == null) return;

    final now = DateTime.now();
    state
      ..offlineDaysUsed = 0
      ..lastOnlineDate = now
      ..updatedAt = now;
    await saveControlState(state);
  }

  /// Clear control state (on logout)
  Future<void> clearControlState() async {
    await _isar.writeTxn(() async {
      await _isar.localControlStatePersistences.clear();
    });
  }

  // ========================================
  // VALIDATION CHECKS
  // ========================================

  /// Check if offline limit has been exceeded
  Future<bool> isOfflineLimitExceeded() async {
    final state = await getControlState();
    if (state == null) return true; // No state = need to sync
    return state.isOfflineLimitExceeded;
  }

  /// Check if device time appears tampered
  Future<bool> isTimeTampered() async {
    final state = await getControlState();
    if (state == null) return false;
    return state.isTimeTampered(DateTime.now());
  }

  /// Get current offline status info
  Future<OfflineStatus?> getOfflineStatus() async {
    final state = await getControlState();
    if (state == null) return null;

    return OfflineStatus(
      offlineDaysUsed: state.offlineDaysUsed,
      maxOfflineDays: state.maxOfflineDays,
      lastSyncedAt: state.lastSyncedAt,
      isLimitExceeded: state.isOfflineLimitExceeded,
      daysRemaining: state.maxOfflineDays - state.offlineDaysUsed,
    );
  }
}

// ============================================================
// OFFLINE STATUS MODEL
// ============================================================
/// Summary of current offline tracking status
class OfflineStatus {
  final int offlineDaysUsed;
  final int maxOfflineDays;
  final DateTime lastSyncedAt;
  final bool isLimitExceeded;
  final int daysRemaining;

  const OfflineStatus({
    required this.offlineDaysUsed,
    required this.maxOfflineDays,
    required this.lastSyncedAt,
    required this.isLimitExceeded,
    required this.daysRemaining,
  });

  @override
  String toString() => 
      'OfflineStatus(used: $offlineDaysUsed/$maxOfflineDays, '
      'remaining: $daysRemaining, exceeded: $isLimitExceeded)';
}

// ============================================================
// RIVERPOD PROVIDERS
// ============================================================

/// Provider for LocalControlStateRepository
final localControlStateRepositoryProvider = Provider<LocalControlStateRepository>((ref) {
  final isarService = ref.watch(isarServiceProvider);
  return LocalControlStateRepository(isarService);
});

/// Provider for current control state
final localControlStateProvider = FutureProvider<LocalControlStatePersistence?>((ref) async {
  return ref.watch(localControlStateRepositoryProvider).getControlState();
});

/// Provider for offline status
final offlineStatusProvider = FutureProvider<OfflineStatus?>((ref) async {
  return ref.watch(localControlStateRepositoryProvider).getOfflineStatus();
});

/// Provider to check if offline limit exceeded
final isOfflineLimitExceededProvider = FutureProvider<bool>((ref) async {
  return ref.watch(localControlStateRepositoryProvider).isOfflineLimitExceeded();
});

/// Provider to check if time is tampered
final isTimeTamperedProvider = FutureProvider<bool>((ref) async {
  return ref.watch(localControlStateRepositoryProvider).isTimeTampered();
});
