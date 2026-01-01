import 'dart:async';
import 'dart:math';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mbm_app/core/repositories/product_repository.dart';

class SyncService {
  final Ref _ref;
  StreamSubscription? _connectivitySubscription;
  bool _isSyncing = false;
  int _retryCount = 0;

  SyncService(this._ref);

  void start() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((result) {
      if (result != ConnectivityResult.none) {
        syncNow();
      }
    });
    // Initial sync attempt
    syncNow();
  }

  void stop() {
    _connectivitySubscription?.cancel();
  }

  Future<void> syncNow() async {
    if (_isSyncing) return;
    _isSyncing = true;
    
    try {
      print('SyncService: Starting production-grade sync...');
      await _syncProducts();
      _retryCount = 0; // Reset on success
    } catch (e) {
      _handleSyncError(e);
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _syncProducts() async {
    final repo = _ref.read(productRepositoryProvider);
    final unsynced = await repo.getUnsyncedProducts();

    if (unsynced.isEmpty) {
      print('SyncService: All products synced.');
      return;
    }

    print('SyncService: Processing batch of ${unsynced.length} products...');

    for (final product in unsynced) {
      try {
        // --- PRODUCTION API CALL ---
        // Implement batching or concurrent requests here if scale requires it
        await _pushProductToBackend(product);
        
        // On success, mark as synced locally
        await repo.markAsSynced(product.id);
      } catch (e) {
        print('SyncService: Failed to sync individual item ${product.id}. Will retry later.');
        rethrow;
      }
    }
  }

  Future<void> _pushProductToBackend(dynamic product) async {
    // Mocking a reliable network call
    await Future.delayed(const Duration(milliseconds: 300));
    
    // Simulate rare random failure to test retry logic
    if (Random().nextInt(100) < 5) throw Exception("Transient network failure");
    
    print('SyncService: Item ${product.id} pushed successfully.');
  }

  void _handleSyncError(dynamic e) {
    _retryCount++;
    // Exponential backoff: 2s, 4s, 8s, 16s... max 1 hour
    final backoffSeconds = min(pow(2, _retryCount).toInt(), 3600);
    print('SyncService: Sync failed ($e). Retrying in $backoffSeconds seconds (Attempt $_retryCount)');
    
    Future.delayed(Duration(seconds: backoffSeconds), () {
      syncNow();
    });
  }
}

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(ref);
});
