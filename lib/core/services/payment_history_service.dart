import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as flutter_firestore;
import 'package:firebase_dart/firebase_dart.dart' as fb_dart;
import '../models/payment_model.dart';
import 'firestore_rest_client.dart';

/// Check if running on desktop platform
bool get _isDesktop {
  if (kIsWeb) return false;
  return Platform.isLinux || Platform.isWindows || Platform.isMacOS;
}

/// Service for fetching payment and subscription history
class PaymentHistoryService {
  // FlutterFire for web/mobile
  flutter_firestore.FirebaseFirestore? _flutterFirestore;
  
  // REST client for desktop
  FirestoreRestClient? _firestoreClient;

  PaymentHistoryService() {
    if (_isDesktop) {
      _firestoreClient = FirestoreRestClient(projectId: 'cellaris-959');
      
      // Listen to auth state changes to update REST client token
      fb_dart.FirebaseAuth.instance.idTokenChanges().listen((user) async {
        if (user != null) {
          try {
            final token = await user.getIdToken();
            _firestoreClient?.setAuthToken(token);
          } catch (e) {
            debugPrint('PaymentHistoryService: Failed to get auth token: $e');
          }
        } else {
          _firestoreClient?.setAuthToken(null);
        }
      });
    } else {
      _flutterFirestore = flutter_firestore.FirebaseFirestore.instance;
    }
  }

  /// Get payment history for a user
  Future<List<PaymentRecord>> getPaymentHistory(String userId) async {
    try {
      if (_isDesktop) {
        // Use REST API for desktop - query subcollection
        final payments = await _getPaymentsFromRest(userId);
        return payments;
      } else {
        // Use FlutterFire for web/mobile
        final querySnapshot = await _flutterFirestore!
            .collection('users')
            .doc(userId)
            .collection('payments')
            .orderBy('createdAt', descending: true)
            .get();
        
        return querySnapshot.docs
            .map((doc) => PaymentRecord.fromFirestore(doc))
            .toList();
      }
    } catch (e) {
      debugPrint('PaymentHistoryService: Error fetching payments: $e');
      return [];
    }
  }

  /// Get payments from REST API (for desktop)
  Future<List<PaymentRecord>> _getPaymentsFromRest(String userId) async {
    // Note: Firestore REST API subcollection queries are complex
    // For now, we'll try to get from a top-level payments collection filtered by userId
    // or return empty if the subcollection approach isn't working
    try {
      // Try the user document to see if there's embedded payment info
      final userData = await _firestoreClient?.getDocument('users', userId);
      if (userData == null) return [];
      
      // Check if payments are embedded in user document
      if (userData['payments'] != null && userData['payments'] is List) {
        final paymentsList = userData['payments'] as List;
        return paymentsList.asMap().entries.map((entry) {
          final data = Map<String, dynamic>.from(entry.value);
          return PaymentRecord.fromMap('payment_${entry.key}', data);
        }).toList();
      }
      
      // Check for subscription history in user doc
      if (userData['subscriptionHistory'] != null && userData['subscriptionHistory'] is List) {
        final historyList = userData['subscriptionHistory'] as List;
        return historyList.asMap().entries.map((entry) {
          final data = Map<String, dynamic>.from(entry.value);
          return PaymentRecord.fromMap('sub_${entry.key}', data);
        }).toList();
      }
      
      return [];
    } catch (e) {
      debugPrint('PaymentHistoryService: REST query error: $e');
      return [];
    }
  }

  /// Get subscription periods (derived from successful payments)
  Future<List<SubscriptionPeriod>> getSubscriptionPeriods(String userId) async {
    final payments = await getPaymentHistory(userId);
    
    // Filter to successful payments and convert to periods
    return payments
        .where((p) => p.isSuccessful && p.subscriptionStartDate != null && p.subscriptionEndDate != null)
        .map((p) => SubscriptionPeriod(
          startDate: p.subscriptionStartDate!,
          endDate: p.subscriptionEndDate!,
          amountPaid: p.amount,
          paymentMethod: p.method,
          transactionId: p.transactionId,
          isActive: p.subscriptionEndDate!.isAfter(DateTime.now()),
        ))
        .toList();
  }

  /// Get total amount spent on subscriptions
  Future<double> getTotalSpent(String userId) async {
    final payments = await getPaymentHistory(userId);
    return payments
        .where((p) => p.isSuccessful)
        .fold<double>(0.0, (sum, p) => sum + p.amount);
  }
}

/// Provider for PaymentHistoryService
final paymentHistoryServiceProvider = Provider<PaymentHistoryService>((ref) {
  return PaymentHistoryService();
});

/// Provider for user's payment history
final paymentHistoryProvider = FutureProvider.family<List<PaymentRecord>, String>((ref, userId) async {
  return ref.watch(paymentHistoryServiceProvider).getPaymentHistory(userId);
});

/// Provider for subscription periods
final subscriptionPeriodsProvider = FutureProvider.family<List<SubscriptionPeriod>, String>((ref, userId) async {
  return ref.watch(paymentHistoryServiceProvider).getSubscriptionPeriods(userId);
});

/// Provider for total spent
final totalSpentProvider = FutureProvider.family<double, String>((ref, userId) async {
  return ref.watch(paymentHistoryServiceProvider).getTotalSpent(userId);
});
