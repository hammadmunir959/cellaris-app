import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../controller/auth_controller.dart';
import '../../../core/models/user_model.dart';

/// A widget that monitors the user's subscription status in real-time.
/// If the status becomes invalid (not active or valid trial), it automatically
/// redirects the user to the subscription page.
/// 
/// It relies on AuthController's real-time stream subscription to user data.
class SubscriptionGuard extends ConsumerStatefulWidget {
  final Widget child;
  
  const SubscriptionGuard({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<SubscriptionGuard> createState() => _SubscriptionGuardState();
}

class _SubscriptionGuardState extends ConsumerState<SubscriptionGuard> {
  bool _isRedirecting = false;
  
  @override
  void initState() {
    super.initState();
    // Check status immediately after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAccess();
    });
  }
  
  void _checkAccess() {
    if (!mounted || _isRedirecting) return;
    
    final authState = ref.read(authControllerProvider);
    
    if (authState.isAuthenticated && authState.user != null) {
      final user = authState.user!;
      final canAccess = _canUserAccessApp(user);
      
      if (!canAccess) {
        _forceRedirect(user.status);
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    
    // Only check if user is authenticated
    if (authState.isAuthenticated && authState.user != null) {
      final user = authState.user!;
      
      // Check if user can access the app
      final canAccess = _canUserAccessApp(user);
      
      // If user cannot access, redirect immediately
      if (!canAccess && !_isRedirecting) {
        // Use post-frame callback to avoid build-during-build errors
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _forceRedirect(user.status);
          }
        });
        
        // Show a loading/redirect indicator instead of the child
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 24),
                Text(
                  'Your subscription status has changed',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Redirecting to subscription page...',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        );
      }
    }
    
    return widget.child;
  }

  /// Check if user can access the main app
  /// ONLY active (with valid date) or trial (with valid date) can access
  bool _canUserAccessApp(AppUser user) {
    final now = DateTime.now();
    
    // Active users can access if subscription hasn't expired
    if (user.status == UserStatus.active) {
      return user.subscriptionExpiry.isAfter(now);
    }
    
    // Trial users can access if trial hasn't expired
    if (user.status == UserStatus.trial) {
      return user.subscriptionExpiry.isAfter(now);
    }
    
    // ALL other statuses (pending, pendingVerification, expired, canceled, blocked) -> NO ACCESS
    return false;
  }

  /// Force redirect to subscription page
  void _forceRedirect(UserStatus status) {
    if (!mounted || _isRedirecting) return;
    
    try {
      final currentRoute = GoRouterState.of(context).matchedLocation;
      
      // Only redirect if not already on auth/subscription pages
      if (currentRoute != '/subscription-expired' && 
          currentRoute != '/login' && 
          currentRoute != '/register' &&
          currentRoute != '/forgot-password') {
        
        _isRedirecting = true;
        debugPrint('SubscriptionGuard: Forcing redirect from $currentRoute to /subscription-expired (status: ${status.name})');
        
        // Navigate to subscription expired page
        context.go('/subscription-expired');
        
        // Reset flag after a delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            _isRedirecting = false;
          }
        });
      }
    } catch (e) {
      debugPrint('SubscriptionGuard: Error during redirect: $e');
      _isRedirecting = false;
    }
  }
}
