import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:animate_do/animate_do.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as flutter_firestore;
import 'package:firebase_dart/firebase_dart.dart' as fb_dart;
import 'package:cellaris/core/theme/app_theme.dart';
import 'package:cellaris/core/widgets/glass_card.dart';
import 'package:cellaris/core/widgets/primary_button.dart';
import 'package:cellaris/core/models/user_model.dart';
import 'package:cellaris/core/services/firestore_rest_client.dart';
import '../controller/auth_controller.dart';

/// Check if running on desktop
bool get _isDesktop {
  if (kIsWeb) return false;
  return Platform.isLinux || Platform.isWindows || Platform.isMacOS;
}

/// Subscription Package Model
class SubscriptionPackage {
  final String id;
  final String name;
  final String description;
  final double price;
  final int durationDays;
  final List<String> features;
  final bool isPopular;
  final bool isActive;

  const SubscriptionPackage({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.durationDays,
    this.features = const [],
    this.isPopular = false,
    this.isActive = true,
  });

  factory SubscriptionPackage.fromMap(String id, Map<String, dynamic> data) {
    return SubscriptionPackage(
      id: id,
      name: data['name'] ?? 'Package',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      durationDays: data['durationDays'] ?? 30,
      features: List<String>.from(data['features'] ?? []),
      isPopular: data['isPopular'] ?? false,
      isActive: data['isActive'] ?? true,
    );
  }

  String get durationLabel {
    if (durationDays == 30) return '/month';
    if (durationDays == 90) return '/3 months';
    if (durationDays == 365) return '/year';
    return '/$durationDays days';
  }
}

/// Payment Account Model
class PaymentAccount {
  final String id;
  final String bankName;
  final String accountTitle;
  final String accountNumber;
  final String? iban;
  final String paymentMethod;
  final bool isActive;

  const PaymentAccount({
    required this.id,
    required this.bankName,
    required this.accountTitle,
    required this.accountNumber,
    this.iban,
    required this.paymentMethod,
    this.isActive = true,
  });

  factory PaymentAccount.fromMap(String id, Map<String, dynamic> data) {
    return PaymentAccount(
      id: id,
      bankName: data['bankName'] ?? data['paymentMethod'] ?? 'Bank',
      accountTitle: data['accountHolderName'] ?? data['accountTitle'] ?? '',
      accountNumber: data['accountNumber'] ?? '',
      iban: data['iban'],
      paymentMethod: data['paymentMethod'] ?? 'Bank Transfer',
      isActive: data['isActive'] ?? true,
    );
  }

  String get displayName => '$paymentMethod - $accountTitle';
}

/// Subscription Expired Screen with full package selection and payment form
class SubscriptionExpiredScreen extends ConsumerStatefulWidget {
  const SubscriptionExpiredScreen({super.key});

  @override
  ConsumerState<SubscriptionExpiredScreen> createState() => _SubscriptionExpiredScreenState();
}

class _SubscriptionExpiredScreenState extends ConsumerState<SubscriptionExpiredScreen> {
  // Form controllers
  final _transactionIdController = TextEditingController();
  final _senderAccountController = TextEditingController();
  final _senderNameController = TextEditingController();
  final _amountController = TextEditingController();
  
  // State
  List<SubscriptionPackage> _packages = [];
  List<PaymentAccount> _paymentAccounts = [];
  SubscriptionPackage? _selectedPackage;
  PaymentAccount? _selectedPaymentAccount;
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _submitSuccess = false;
  String? _error;
  int _currentStep = 0; // 0: Select Package, 1: Payment Form

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      Map<String, dynamic>? settingsData;
      
      if (_isDesktop) {
        // Get current user token for auth
        final client = FirestoreRestClient(projectId: 'cellaris-959');
        try {
          // Try to get auth token
          final user = fb_dart.FirebaseAuth.instance.currentUser;
          if (user != null) {
            final token = await user.getIdToken();
            client.setAuthToken(token);
          }
        } catch (e) {
          debugPrint('Could not get auth token: $e');
        }
        settingsData = await client.getDocument('settings', 'subscription');
      } else {
        final doc = await flutter_firestore.FirebaseFirestore.instance
            .doc('settings/subscription')
            .get();
        settingsData = doc.data();
      }

      if (settingsData != null) {
        // Load packages
        if (settingsData['packages'] != null) {
          final packagesList = settingsData['packages'] as List;
          _packages = packagesList.asMap().entries
              .map((e) => SubscriptionPackage.fromMap('pkg_${e.key}', Map<String, dynamic>.from(e.value)))
              .where((p) => p.isActive)
              .toList();
        }
        
        // Load payment accounts
        if (settingsData['paymentAccounts'] != null) {
          final accountsList = settingsData['paymentAccounts'] as List;
          _paymentAccounts = accountsList.asMap().entries
              .map((e) => PaymentAccount.fromMap('acc_${e.key}', Map<String, dynamic>.from(e.value)))
              .where((a) => a.isActive)
              .toList();
        }
      }

      // Use defaults if nothing loaded
      if (_packages.isEmpty) {
        _packages = [
          const SubscriptionPackage(
            id: 'monthly',
            name: 'Monthly',
            description: 'Perfect for getting started',
            price: 5000,
            durationDays: 30,
            features: ['Full POS access', 'Inventory management', 'Sales reports', 'Customer management'],
          ),
          const SubscriptionPackage(
            id: 'quarterly',
            name: 'Quarterly',
            description: 'Save 15% with 3-month plan',
            price: 12750,
            durationDays: 90,
            features: ['All Monthly features', 'Priority support', 'Advanced analytics'],
            isPopular: true,
          ),
          const SubscriptionPackage(
            id: 'yearly',
            name: 'Yearly',
            description: 'Best value - Save 25%',
            price: 45000,
            durationDays: 365,
            features: ['All Quarterly features', 'Dedicated support', 'Custom integrations'],
          ),
        ];
      }

      if (_paymentAccounts.isEmpty) {
        _paymentAccounts = [
          const PaymentAccount(
            id: 'easypaisa',
            bankName: 'EasyPaisa',
            accountTitle: 'Hammad Munir',
            accountNumber: '0311-9771180',
            paymentMethod: 'EasyPaisa',
          ),
          const PaymentAccount(
            id: 'jazzcash',
            bankName: 'JazzCash',
            accountTitle: 'Hammad Munir',
            accountNumber: '0311-9771180',
            paymentMethod: 'JazzCash',
          ),
        ];
      }

      // Select defaults
      _selectedPackage = _packages.firstWhere((p) => p.isPopular, orElse: () => _packages.first);
      _selectedPaymentAccount = _paymentAccounts.first;
      _amountController.text = _selectedPackage!.price.toStringAsFixed(0);

      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Error loading subscription data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitPayment() async {
    // Validate
    if (_selectedPackage == null) {
      setState(() => _error = 'Please select a subscription package');
      return;
    }
    if (_selectedPaymentAccount == null) {
      setState(() => _error = 'Please select a payment account');
      return;
    }
    if (_transactionIdController.text.trim().isEmpty) {
      setState(() => _error = 'Please enter the transaction ID');
      return;
    }
    if (_transactionIdController.text.trim().length < 6) {
      setState(() => _error = 'Transaction ID seems too short');
      return;
    }
    if (_senderAccountController.text.trim().isEmpty) {
      setState(() => _error = 'Please enter your account number/IBAN');
      return;
    }
    if (_senderNameController.text.trim().isEmpty) {
      setState(() => _error = 'Please enter your account holder name');
      return;
    }

    final user = ref.read(authControllerProvider).user;
    if (user == null) return;

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final paymentData = {
        'status': 'pendingVerification',
        'payment': {
          'packageId': _selectedPackage!.id,
          'packageName': _selectedPackage!.name,
          'packagePrice': _selectedPackage!.price,
          'packageDuration': _selectedPackage!.durationDays,
          'receiverAccountId': _selectedPaymentAccount!.id,
          'receiverAccountTitle': _selectedPaymentAccount!.accountTitle,
          'receiverAccountNumber': _selectedPaymentAccount!.accountNumber,
          'receiverMethod': _selectedPaymentAccount!.paymentMethod,
          'senderAccountNumber': _senderAccountController.text.trim(),
          'senderAccountName': _senderNameController.text.trim(),
          'transactionId': _transactionIdController.text.trim(),
          'amountPaid': double.tryParse(_amountController.text.trim()) ?? _selectedPackage!.price,
          'submittedAt': DateTime.now().toIso8601String(),
        },
        'updatedAt': DateTime.now().toIso8601String(),
      };

      if (_isDesktop) {
        final client = FirestoreRestClient(projectId: 'cellaris-959');
        await client.updateDocument('users', user.id, paymentData);
      } else {
        await flutter_firestore.FirebaseFirestore.instance
            .collection('users')
            .doc(user.id)
            .update({
          ...paymentData,
          'payment': {
            ...paymentData['payment'] as Map<String, dynamic>,
            'submittedAt': flutter_firestore.FieldValue.serverTimestamp(),
          },
          'updatedAt': flutter_firestore.FieldValue.serverTimestamp(),
        });
      }

      setState(() {
        _submitSuccess = true;
        _isSubmitting = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to submit: ${e.toString()}';
        _isSubmitting = false;
      });
    }
  }

  Future<void> _refreshStatus() async {
    await ref.read(authControllerProvider.notifier).refreshSubscription();
    
    final authState = ref.read(authControllerProvider);
    if (authState.isSubscriptionValid && mounted) {
      context.go('/dashboard');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Subscription not yet verified. Please wait for admin approval.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  void dispose() {
    _transactionIdController.dispose();
    _senderAccountController.dispose();
    _senderNameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Check for pending states
    final isPendingVerification = user?.status == UserStatus.pendingVerification;
    final isPending = user?.status == UserStatus.pending;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryColor.withValues(alpha: 0.15),
              Colors.black,
              Colors.black,
              AppTheme.accentColor.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : isPendingVerification || isPending
                  ? _buildPendingView(user, isDark)
                  : _submitSuccess
                      ? _buildSuccessView()
                      : _buildMainView(user, isDark),
        ),
      ),
    );
  }

  Widget _buildPendingView(AppUser? user, bool isDark) {
    // Check if user has submitted payment details
    final hasPaymentDetails = user?.paymentDetails != null;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              // Header
              FadeInDown(
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.amber.withValues(alpha: 0.15), Colors.orange.withValues(alpha: 0.05)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(LucideIcons.clock, size: 32, color: Colors.amber),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Payment Pending Verification',
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Hello ${user?.name ?? "User"}, your payment is being reviewed. You can edit details below if needed.',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          OutlinedButton.icon(
                            onPressed: _refreshStatus,
                            icon: const Icon(LucideIcons.refreshCw, size: 16),
                            label: const Text('Check Status'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.amber,
                              side: const BorderSide(color: Colors.amber),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: () async {
                              await ref.read(authControllerProvider.notifier).logout();
                              if (mounted) context.go('/login');
                            },
                            icon: const Icon(LucideIcons.logOut, size: 16),
                            label: const Text('Logout'),
                            style: TextButton.styleFrom(foregroundColor: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Edit payment form or submit new payment
              if (hasPaymentDetails)
                FadeInUp(
                  delay: const Duration(milliseconds: 100),
                  child: _buildEditablePaymentCard(user!, isDark),
                )
              else
                FadeInUp(
                  delay: const Duration(milliseconds: 100),
                  child: _buildMainView(user, isDark),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditablePaymentCard(AppUser user, bool isDark) {
    final payment = user.paymentDetails;
    
    // Pre-fill controllers with existing data if not already set
    if (_transactionIdController.text.isEmpty && payment?['transactionId'] != null) {
      _transactionIdController.text = payment!['transactionId'] ?? '';
    }
    if (_senderAccountController.text.isEmpty && payment?['senderAccountNumber'] != null) {
      _senderAccountController.text = payment!['senderAccountNumber'] ?? '';
    }
    if (_senderNameController.text.isEmpty && payment?['senderAccountName'] != null) {
      _senderNameController.text = payment!['senderAccountName'] ?? '';
    }
    if (_amountController.text.isEmpty && payment?['amountPaid'] != null) {
      _amountController.text = (payment!['amountPaid'] ?? 0).toString();
    }
    
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(LucideIcons.edit, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Edit Payment Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('Update your payment information if needed', style: TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Current submission summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(LucideIcons.checkCircle, color: Colors.green, size: 18),
                    const SizedBox(width: 10),
                    const Text('Submitted Payment', style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    if (payment?['submittedAt'] != null)
                      Text(
                        _formatDate(payment!['submittedAt']),
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                _detailRowCompact('Package', payment?['packageName'] ?? '-'),
                _detailRowCompact('Amount', 'Rs. ${NumberFormat('#,###').format(payment?['amountPaid'] ?? 0)}'),
                _detailRowCompact('Transaction ID', payment?['transactionId'] ?? '-'),
                _detailRowCompact('Paid via', payment?['receiverMethod'] ?? '-'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Error message
          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.alertCircle, color: Colors.red, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13))),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Editable fields in a grid
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: [
                    TextField(
                      controller: _transactionIdController,
                      decoration: InputDecoration(
                        labelText: 'Transaction ID',
                        prefixIcon: const Icon(LucideIcons.hash),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _amountController,
                      decoration: InputDecoration(
                        labelText: 'Amount Paid',
                        prefixIcon: const Icon(LucideIcons.banknote),
                        prefixText: 'Rs. ',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: [
                    TextField(
                      controller: _senderAccountController,
                      decoration: InputDecoration(
                        labelText: 'Your Account Number',
                        prefixIcon: const Icon(LucideIcons.wallet),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _senderNameController,
                      decoration: InputDecoration(
                        labelText: 'Account Holder Name',
                        prefixIcon: const Icon(LucideIcons.user),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Paid to account selector
          if (_paymentAccounts.isNotEmpty) ...[
            const Text('Paid to Account:', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _paymentAccounts.map((account) {
                final isSelected = _selectedPaymentAccount?.id == account.id;
                return GestureDetector(
                  onTap: () => setState(() => _selectedPaymentAccount = account),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.15) : Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: isSelected ? AppTheme.primaryColor : Colors.grey.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          account.paymentMethod.contains('EasyPaisa') ? LucideIcons.smartphone : LucideIcons.building,
                          size: 18,
                          color: isSelected ? AppTheme.primaryColor : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(account.displayName, style: TextStyle(color: isSelected ? AppTheme.primaryColor : null)),
                        if (isSelected) ...[
                          const SizedBox(width: 8),
                          const Icon(LucideIcons.check, size: 16, color: AppTheme.primaryColor),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],
          
          // Update button
          Row(
            children: [
              Expanded(
                child: PrimaryButton(
                  label: _isSubmitting ? 'Updating...' : 'Update Payment Details',
                  onPressed: _isSubmitting ? null : _submitPayment,
                  isLoading: _isSubmitting,
                  icon: LucideIcons.save,
                ),
              ),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                onPressed: () {
                  // Reset to start new payment
                  setState(() {
                    _transactionIdController.clear();
                    _senderAccountController.clear();
                    _senderNameController.clear();
                    _amountController.text = _selectedPackage?.price.toStringAsFixed(0) ?? '';
                    _currentStep = 0;
                    _submitSuccess = false;
                  });
                },
                icon: const Icon(LucideIcons.plus, size: 18),
                label: const Text('New Payment'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailRowCompact(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  String _formatDate(dynamic dateValue) {
    if (dateValue == null) return '';
    DateTime? date;
    if (dateValue is DateTime) date = dateValue;
    if (dateValue is String) date = DateTime.tryParse(dateValue);
    if (date == null) return '';
    return DateFormat('MMM dd, yyyy HH:mm').format(date);
  }

  Widget _buildSuccessView() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: FadeIn(
          child: SizedBox(
            width: 550,
            child: GlassCard(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Pending verification icon
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(LucideIcons.clock, size: 48, color: Colors.amber),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Pending Verification',
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Your payment details have been submitted successfully!\nOur team will verify within 24 hours.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    const SizedBox(height: 32),
                    
                    // Payment summary card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(LucideIcons.receipt, color: AppTheme.primaryColor, size: 18),
                              const SizedBox(width: 10),
                              const Text('Payment Summary', style: TextStyle(fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _summaryRow('Package', _selectedPackage?.name ?? '-'),
                          _summaryRow('Amount', 'Rs. ${NumberFormat('#,###').format(_selectedPackage?.price ?? 0)}'),
                          _summaryRow('Transaction ID', _transactionIdController.text),
                          _summaryRow('Your Account', _senderAccountController.text),
                          _summaryRow('Paid To', _selectedPaymentAccount?.displayName ?? '-'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // What happens next info
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(LucideIcons.info, color: Colors.blue, size: 18),
                              SizedBox(width: 10),
                              Text('What happens next?', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w600)),
                            ],
                          ),
                          SizedBox(height: 10),
                          Text(
                            '1. Our admin will review your payment details\n'
                            '2. Once verified, your subscription will be activated\n'
                            '3. You will gain full access to the app',
                            style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.6),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    
                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: PrimaryButton(
                            label: 'Check Status',
                            onPressed: _refreshStatus,
                            icon: LucideIcons.refreshCw,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              setState(() {
                                _submitSuccess = false;
                                _currentStep = 1; // Go back to payment form
                              });
                            },
                            icon: const Icon(LucideIcons.edit, size: 18),
                            label: const Text('Edit Details'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(color: AppTheme.primaryColor.withValues(alpha: 0.5)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Logout button
                    TextButton.icon(
                      onPressed: () async {
                        await ref.read(authControllerProvider.notifier).logout();
                        if (mounted) context.go('/login');
                      },
                      icon: const Icon(LucideIcons.logOut, size: 16),
                      label: const Text('Logout'),
                      style: TextButton.styleFrom(foregroundColor: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildMainView(AppUser? user, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              FadeInDown(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(LucideIcons.crown, color: Colors.white, size: 32),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Renew Subscription',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          const Text(
                            'Choose a plan and complete payment to continue',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        await ref.read(authControllerProvider.notifier).logout();
                        if (mounted) context.go('/login');
                      },
                      icon: const Icon(LucideIcons.logOut, size: 18),
                      label: const Text('Logout'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Stepper indicator
              FadeInUp(
                delay: const Duration(milliseconds: 100),
                child: _buildStepIndicator(),
              ),
              const SizedBox(height: 32),

              // Step Content
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _currentStep == 0
                    ? _buildPackageSelection(isDark)
                    : _buildPaymentForm(isDark),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      children: [
        _buildStepItem(0, 'Select Package', LucideIcons.package),
        Expanded(
          child: Container(
            height: 2,
            color: _currentStep >= 1 ? AppTheme.primaryColor : Colors.grey.withValues(alpha: 0.3),
          ),
        ),
        _buildStepItem(1, 'Payment Details', LucideIcons.creditCard),
      ],
    );
  }

  Widget _buildStepItem(int step, String label, IconData icon) {
    final isActive = _currentStep >= step;
    return GestureDetector(
      onTap: step < _currentStep ? () => setState(() => _currentStep = step) : null,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: isActive ? const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]) : null,
              color: isActive ? null : Colors.grey.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: isActive ? Colors.white : Colors.grey, size: 20),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              color: isActive ? Colors.white : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageSelection(bool isDark) {
    return FadeInUp(
      key: const ValueKey('packages'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Choose Your Plan',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Select the subscription package that suits your business',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          
          // Package Cards
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 600;
              return isWide
                  ? Row(
                      children: _packages.map((pkg) => 
                        Expanded(child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: _buildPackageCard(pkg, isDark),
                        ))).toList(),
                    )
                  : Column(
                      children: _packages.map((pkg) => 
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildPackageCard(pkg, isDark),
                        )).toList(),
                    );
            },
          ),
          const SizedBox(height: 32),
          
          // Continue button
          Align(
            alignment: Alignment.centerRight,
            child: PrimaryButton(
              label: 'Continue to Payment',
              icon: LucideIcons.arrowRight,
              onPressed: _selectedPackage != null ? () {
                _amountController.text = _selectedPackage!.price.toStringAsFixed(0);
                setState(() => _currentStep = 1);
              } : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageCard(SubscriptionPackage package, bool isDark) {
    final isSelected = _selectedPackage?.id == package.id;
    
    return GestureDetector(
      onTap: () => setState(() {
        _selectedPackage = package;
        _amountController.text = package.price.toStringAsFixed(0);
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [AppTheme.primaryColor.withValues(alpha: 0.15), AppTheme.primaryColor.withValues(alpha: 0.05)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : (isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: AppTheme.primaryColor.withValues(alpha: 0.2), blurRadius: 20)]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Popular badge
            if (package.isPopular)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFEF4444)]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('POPULAR', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            if (package.isPopular) const SizedBox(height: 12),
            
            // Package name
            Text(
              package.name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(package.description, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
            const SizedBox(height: 16),
            
            // Price
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Rs. ${NumberFormat('#,###').format(package.price)}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? AppTheme.primaryColor : null,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2, left: 4),
                    child: Text(package.durationLabel, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Features
            ...package.features.take(4).map((f) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(LucideIcons.check, size: 16, color: isSelected ? AppTheme.primaryColor : Colors.green),
                  const SizedBox(width: 8),
                  Expanded(child: Text(f, style: const TextStyle(fontSize: 13))),
                ],
              ),
            )),
            
            const SizedBox(height: 16),
            // Selection indicator
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryColor : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  isSelected ? 'Selected' : 'Select Plan',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : Colors.grey,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentForm(bool isDark) {
    return FadeInUp(
      key: const ValueKey('payment'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button
          TextButton.icon(
            onPressed: () => setState(() => _currentStep = 0),
            icon: const Icon(LucideIcons.arrowLeft, size: 18),
            label: const Text('Back to packages'),
          ),
          const SizedBox(height: 16),
          
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: Payment Accounts
              Expanded(
                flex: 1,
                child: _buildPaymentAccountsCard(isDark),
              ),
              const SizedBox(width: 24),
              
              // Right: Payment Form
              Expanded(
                flex: 1,
                child: _buildPaymentFormCard(isDark),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentAccountsCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(LucideIcons.building, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              const Text('Pay to Account', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Select where you sent the payment', style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 20),
          
          // Account selection
          ..._paymentAccounts.map((account) => _buildAccountOption(account, isDark)),
          
          if (_selectedPaymentAccount != null) ...[
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 16),
            
            // Selected account details
            _detailRow('Bank/Method', _selectedPaymentAccount!.bankName),
            _detailRow('Account Title', _selectedPaymentAccount!.accountTitle),
            _detailRow('Account Number', _selectedPaymentAccount!.accountNumber),
            if (_selectedPaymentAccount!.iban != null)
              _detailRow('IBAN', _selectedPaymentAccount!.iban!),
          ],
          
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryColor.withValues(alpha: 0.1), AppTheme.primaryColor.withValues(alpha: 0.05)],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_selectedPackage?.name ?? 'Package', style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text(
                      'Rs. ${NumberFormat('#,###').format(_selectedPackage?.price ?? 0)}',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _selectedPackage?.durationLabel.replaceFirst('/', '') ?? '',
                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountOption(PaymentAccount account, bool isDark) {
    final isSelected = _selectedPaymentAccount?.id == account.id;
    return GestureDetector(
      onTap: () => setState(() => _selectedPaymentAccount = account),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(
              account.paymentMethod.contains('EasyPaisa') ? LucideIcons.smartphone :
              account.paymentMethod.contains('JazzCash') ? LucideIcons.smartphone :
              LucideIcons.building,
              color: isSelected ? AppTheme.primaryColor : Colors.grey,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(account.paymentMethod, style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(account.accountNumber, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            if (isSelected)
              const Icon(LucideIcons.checkCircle, color: AppTheme.primaryColor),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          SelectableText(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildPaymentFormCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(LucideIcons.fileText, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              const Text('Payment Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Enter your payment information', style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 24),
          
          // Error
          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.alertCircle, color: Colors.red, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13))),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Amount Paid
          TextField(
            controller: _amountController,
            decoration: InputDecoration(
              labelText: 'Amount Paid',
              prefixIcon: const Icon(LucideIcons.banknote),
              prefixText: 'Rs. ',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 16),
          
          // Sender Account Number
          TextField(
            controller: _senderAccountController,
            decoration: InputDecoration(
              labelText: 'Your Account Number / IBAN',
              hintText: 'Account you sent payment from',
              prefixIcon: const Icon(LucideIcons.wallet),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
          
          // Sender Name
          TextField(
            controller: _senderNameController,
            decoration: InputDecoration(
              labelText: 'Account Holder Name',
              hintText: 'Name on your account',
              prefixIcon: const Icon(LucideIcons.user),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 16),
          
          // Transaction ID
          TextField(
            controller: _transactionIdController,
            decoration: InputDecoration(
              labelText: 'Transaction ID / Receipt Number',
              hintText: 'e.g., TXN123456789',
              prefixIcon: const Icon(LucideIcons.hash),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              suffixIcon: IconButton(
                icon: const Icon(LucideIcons.copy, size: 18),
                tooltip: 'Paste from clipboard',
                onPressed: () async {
                  final data = await Clipboard.getData('text/plain');
                  if (data?.text != null) {
                    _transactionIdController.text = data!.text!;
                  }
                },
              ),
            ),
            textCapitalization: TextCapitalization.characters,
          ),
          const SizedBox(height: 24),
          
          // Submit
          PrimaryButton(
            label: _isSubmitting ? 'Submitting...' : 'Submit for Verification',
            onPressed: _isSubmitting ? null : _submitPayment,
            isLoading: _isSubmitting,
            width: double.infinity,
          ),
        ],
      ),
    );
  }
}
