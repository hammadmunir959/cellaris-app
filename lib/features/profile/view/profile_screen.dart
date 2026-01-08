import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:cellaris/core/theme/app_theme.dart';
import 'package:cellaris/features/auth/controller/auth_controller.dart';
import 'package:cellaris/core/models/user_model.dart';
import 'package:cellaris/core/models/payment_model.dart';
import 'package:cellaris/core/services/payment_history_service.dart';

/// Profile Screen - Shows user details and subscription information
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isSyncing = false;

  Future<void> _syncAccount() async {
    if (_isSyncing) return;
    
    setState(() => _isSyncing = true);
    
    try {
      await ref.read(authControllerProvider.notifier).refreshSubscription();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(LucideIcons.checkCircle, color: Colors.white, size: 18),
                const SizedBox(width: 12),
                const Text('Account synced successfully!'),
              ],
            ),
            backgroundColor: AppTheme.accentColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(LucideIcons.alertCircle, color: Colors.white, size: 18),
                const SizedBox(width: 12),
                Expanded(child: Text('Sync failed: ${e.toString()}')),
              ],
            ),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;

    if (user == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.userX,
              size: 64,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Please log in to view your profile',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.go('/login'),
              icon: const Icon(LucideIcons.logIn),
              label: const Text('Go to Login'),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ═══════════════════════════════════════════════════════════════
            // HEADER
            // ═══════════════════════════════════════════════════════════════
            FadeInDown(
              duration: const Duration(milliseconds: 400),
              child: _buildProfileHeader(user, isDark),
            ),
            const SizedBox(height: 32),

            // ═══════════════════════════════════════════════════════════════
            // MAIN CONTENT
            // ═══════════════════════════════════════════════════════════════
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 800;
                return isWide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: FadeInUp(
                              delay: const Duration(milliseconds: 100),
                              child: _buildAccountInfo(user, isDark),
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: FadeInUp(
                              delay: const Duration(milliseconds: 200),
                              child: _buildSubscriptionInfo(user, isDark),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          FadeInUp(
                            delay: const Duration(milliseconds: 100),
                            child: _buildAccountInfo(user, isDark),
                          ),
                          const SizedBox(height: 24),
                          FadeInUp(
                            delay: const Duration(milliseconds: 200),
                            child: _buildSubscriptionInfo(user, isDark),
                          ),
                        ],
                      );
              },
            ),
            const SizedBox(height: 24),

            // ═══════════════════════════════════════════════════════════════
            // PAYMENT HISTORY
            // ═══════════════════════════════════════════════════════════════
            FadeInUp(
              delay: const Duration(milliseconds: 300),
              child: _buildPaymentHistory(user, isDark),
            ),
            const SizedBox(height: 24),

            // ═══════════════════════════════════════════════════════════════
            // ACCOUNT ACTIONS
            // ═══════════════════════════════════════════════════════════════
            FadeInUp(
              delay: const Duration(milliseconds: 400),
              child: _buildAccountActions(isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(AppUser user, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [Colors.white, const Color(0xFFF8FAFC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Text(
              user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 24),
          
          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      LucideIcons.mail,
                      size: 14,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      user.email,
                      style: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildRoleBadge(user.role),
                    const SizedBox(width: 12),
                    _buildStatusBadge(user.status),
                  ],
                ),
              ],
            ),
          ),
          
          // Sync button
          _buildSyncButton(),
        ],
      ),
    );
  }

  Widget _buildSyncButton() {
    return Tooltip(
      message: 'Sync account data from server',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isSyncing ? null : _syncAccount,
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: _isSyncing
                  ? null
                  : const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    ),
              color: _isSyncing ? Colors.grey.withValues(alpha: 0.3) : null,
              borderRadius: BorderRadius.circular(14),
              boxShadow: _isSyncing
                  ? null
                  : [
                      BoxShadow(
                        color: AppTheme.primaryColor.withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: _isSyncing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(
                    LucideIcons.refreshCw,
                    size: 20,
                    color: Colors.white,
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleBadge(UserRole role) {
    final (color, text) = switch (role) {
      UserRole.administrator => (Colors.purple, 'Administrator'),
      UserRole.stockManager => (Colors.blue, 'Stock Manager'),
      UserRole.salesProfessional => (Colors.green, 'Sales Professional'),
      UserRole.accountant => (Colors.orange, 'Accountant'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.briefcase, size: 12, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(UserStatus status) {
    final (color, text, icon) = switch (status) {
      UserStatus.active => (Colors.green, 'Active', LucideIcons.checkCircle),
      UserStatus.trial => (Colors.blue, 'Trial', LucideIcons.clock),
      UserStatus.expired => (Colors.orange, 'Expired', LucideIcons.alertTriangle),
      UserStatus.canceled => (Colors.grey, 'Canceled', LucideIcons.xCircle),
      UserStatus.pending => (Colors.amber, 'Pending', LucideIcons.clock),
      UserStatus.blocked => (Colors.red, 'Blocked', LucideIcons.ban),
      UserStatus.pendingVerification => (Colors.amber, 'Pending Verification', LucideIcons.fileCheck),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountInfo(AppUser user, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
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
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(LucideIcons.userCircle, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                'Account Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildInfoRow(LucideIcons.user, 'Full Name', user.name, isDark),
          _buildInfoRow(LucideIcons.mail, 'Email', user.email, isDark),
          _buildInfoRow(LucideIcons.fingerprint, 'User ID', user.id, isDark),
          _buildInfoRow(
            LucideIcons.calendar,
            'Member Since',
            DateFormat('MMMM dd, yyyy').format(user.createdAt),
            isDark,
          ),
          if (user.lastLoginAt != null)
            _buildInfoRow(
              LucideIcons.logIn,
              'Last Login',
              DateFormat('MMM dd, yyyy • HH:mm').format(user.lastLoginAt!),
              isDark,
            ),
          if (user.companyId != null)
            _buildInfoRow(LucideIcons.building, 'Company ID', user.companyId!, isDark),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: AppTheme.primaryColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionInfo(AppUser user, bool isDark) {
    final isActive = user.status == UserStatus.active;
    final isTrial = user.status == UserStatus.trial;
    final daysRemaining = user.subscriptionExpiry.difference(DateTime.now()).inDays;
    final isExpiringSoon = daysRemaining <= 7 && daysRemaining > 0;
    final isExpired = daysRemaining < 0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
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
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(LucideIcons.crown, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                'Subscription',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const Spacer(),
              if (isTrial)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'FREE TRIAL',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),

          // Status card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isExpired
                    ? [Colors.red.withValues(alpha: 0.1), Colors.red.withValues(alpha: 0.05)]
                    : isExpiringSoon
                        ? [Colors.orange.withValues(alpha: 0.1), Colors.orange.withValues(alpha: 0.05)]
                        : [Colors.green.withValues(alpha: 0.1), Colors.green.withValues(alpha: 0.05)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isExpired
                    ? Colors.red.withValues(alpha: 0.3)
                    : isExpiringSoon
                        ? Colors.orange.withValues(alpha: 0.3)
                        : Colors.green.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isExpired
                        ? Colors.red.withValues(alpha: 0.2)
                        : isExpiringSoon
                            ? Colors.orange.withValues(alpha: 0.2)
                            : Colors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isExpired
                        ? LucideIcons.xCircle
                        : isExpiringSoon
                            ? LucideIcons.alertTriangle
                            : LucideIcons.checkCircle,
                    color: isExpired
                        ? Colors.red
                        : isExpiringSoon
                            ? Colors.orange
                            : Colors.green,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isExpired
                            ? 'Subscription Expired'
                            : isActive
                                ? 'Subscription Active'
                                : isTrial
                                    ? 'Free Trial Active'
                                    : 'Subscription Inactive',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isExpired
                              ? Colors.red
                              : isExpiringSoon
                                  ? Colors.orange
                                  : Colors.green,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isExpired
                            ? 'Please renew to continue using Cellaris'
                            : 'Expires ${DateFormat('MMMM dd, yyyy').format(user.subscriptionExpiry)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isExpired)
                  Column(
                    children: [
                      Text(
                        '$daysRemaining',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: isExpiringSoon ? Colors.orange : AppTheme.primaryColor,
                        ),
                      ),
                      Text(
                        'days left',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Quick stats
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: LucideIcons.calendar,
                  label: 'Started',
                  value: DateFormat('MMM dd').format(
                    user.subscriptionExpiry.subtract(const Duration(days: 30)),
                  ),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: LucideIcons.calendarCheck,
                  label: 'Expires',
                  value: DateFormat('MMM dd, yyyy').format(user.subscriptionExpiry),
                  isDark: isDark,
                ),
              ),
            ],
          ),

          if (isExpiringSoon || isExpired) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryColor.withValues(alpha: 0.1),
                    AppTheme.primaryColor.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.creditCard, size: 18, color: AppTheme.primaryColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isExpired
                          ? 'Your subscription has expired. Contact support to renew.'
                          : 'Your subscription expires soon. Consider renewing now.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[300] : Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.primaryColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentHistory(AppUser user, bool isDark) {
    final paymentHistory = ref.watch(paymentHistoryProvider(user.id));
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(LucideIcons.receipt, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payment & Subscription History',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    Text(
                      'Your transaction records',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              // Refresh button
              IconButton(
                onPressed: () => ref.refresh(paymentHistoryProvider(user.id)),
                icon: Icon(
                  LucideIcons.refreshCw,
                  size: 18,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
                tooltip: 'Refresh history',
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Payment list
          paymentHistory.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (error, _) => _buildPaymentError(isDark, error.toString()),
            data: (payments) {
              if (payments.isEmpty) {
                return _buildEmptyPaymentHistory(isDark);
              }
              return _buildPaymentList(payments, isDark);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPaymentHistory(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              LucideIcons.fileText,
              size: 48,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No payment history yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your subscription payments and transactions will appear here once you make a payment.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.grey[500] : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentError(bool isDark, String error) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.alertCircle, color: Colors.red, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Failed to load payment history: $error',
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentList(List<PaymentRecord> payments, bool isDark) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: payments.length,
      separatorBuilder: (_, __) => Divider(
        height: 24,
        color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08),
      ),
      itemBuilder: (context, index) {
        final payment = payments[index];
        return _buildPaymentItem(payment, isDark);
      },
    );
  }

  Widget _buildPaymentItem(PaymentRecord payment, bool isDark) {
    final statusColor = switch (payment.status) {
      PaymentStatus.completed => Colors.green,
      PaymentStatus.pending => Colors.orange,
      PaymentStatus.failed => Colors.red,
      PaymentStatus.refunded => Colors.blue,
      PaymentStatus.cancelled => Colors.grey,
    };

    final methodIcon = switch (payment.method) {
      PaymentMethod.easypaisa => LucideIcons.smartphone,
      PaymentMethod.jazzcash => LucideIcons.smartphone,
      PaymentMethod.bankTransfer => LucideIcons.building,
      PaymentMethod.cash => LucideIcons.banknote,
      PaymentMethod.card => LucideIcons.creditCard,
      PaymentMethod.other => LucideIcons.wallet,
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main row
          Row(
            children: [
              // Status icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  payment.isSuccessful ? LucideIcons.checkCircle : 
                  payment.isPending ? LucideIcons.clock : LucideIcons.xCircle,
                  color: statusColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Rs. ${NumberFormat('#,###').format(payment.amount)}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            payment.statusText.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(methodIcon, size: 14, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                        const SizedBox(width: 6),
                        Text(
                          payment.methodName,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                        if (payment.transactionId != null) ...[
                          Text(
                            ' • ',
                            style: TextStyle(color: isDark ? Colors.grey[600] : Colors.grey[400]),
                          ),
                          Text(
                            payment.transactionId!,
                            style: TextStyle(
                              fontSize: 12,
                              fontFamily: 'monospace',
                              color: isDark ? Colors.grey[500] : Colors.grey[500],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              
              // Date
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    DateFormat('MMM dd, yyyy').format(payment.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  Text(
                    DateFormat('HH:mm').format(payment.createdAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.grey[500] : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Extended details (if available)
          if (payment.accountNumber != null || payment.subscriptionEndDate != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  if (payment.accountNumber != null)
                    _buildDetailRow(
                      'Account',
                      '${payment.accountTitle ?? ''} (${payment.accountNumber})',
                      isDark,
                    ),
                  if (payment.subscriptionStartDate != null && payment.subscriptionEndDate != null)
                    _buildDetailRow(
                      'Subscription Period',
                      '${DateFormat('MMM dd').format(payment.subscriptionStartDate!)} - ${DateFormat('MMM dd, yyyy').format(payment.subscriptionEndDate!)}',
                      isDark,
                    ),
                  if (payment.verifiedAt != null)
                    _buildDetailRow(
                      'Verified',
                      DateFormat('MMM dd, yyyy HH:mm').format(payment.verifiedAt!),
                      isDark,
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[500] : Colors.grey[500],
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.grey[300] : Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountActions(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
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
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(LucideIcons.settings, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildActionTile(
                icon: LucideIcons.refreshCw,
                label: 'Sync Account',
                gradient: const [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                onTap: _syncAccount,
                isLoading: _isSyncing,
                isDark: isDark,
              ),
              _buildActionTile(
                icon: LucideIcons.settings,
                label: 'Settings',
                gradient: const [Color(0xFF6B7280), Color(0xFF4B5563)],
                onTap: () => context.go('/settings'),
                isDark: isDark,
              ),
              _buildActionTile(
                icon: LucideIcons.helpCircle,
                label: 'Get Help',
                gradient: const [Color(0xFFF59E0B), Color(0xFFD97706)],
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Contact support@cellaris.app for help'),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                },
                isDark: isDark,
              ),
              _buildActionTile(
                icon: LucideIcons.logOut,
                label: 'Logout',
                gradient: const [Color(0xFFEF4444), Color(0xFFDC2626)],
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      title: const Text('Logout'),
                      content: const Text('Are you sure you want to logout?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.errorColor,
                          ),
                          child: const Text('Logout'),
                        ),
                      ],
                    ),
                  );
                  
                  if (confirm == true && mounted) {
                    await ref.read(authControllerProvider.notifier).logout();
                    if (mounted) {
                      context.go('/login');
                    }
                  }
                },
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String label,
    required List<Color> gradient,
    required VoidCallback onTap,
    required bool isDark,
    bool isLoading = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 160,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                gradient[0].withValues(alpha: 0.15),
                gradient[1].withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: gradient[0].withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradient),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Icon(icon, size: 16, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: gradient[0],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
