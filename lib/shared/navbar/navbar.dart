import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mbm_app/core/theme/app_theme.dart';
import 'package:mbm_app/main.dart';
import 'package:intl/intl.dart';
import 'package:mbm_app/shared/controller/shared_controller.dart';
import 'package:mbm_app/shared/controller/notification_controller.dart';
import 'package:mbm_app/core/models/app_models.dart';

class Navbar extends ConsumerWidget {
  final VoidCallback onToggleSidebar;
  const Navbar({super.key, required this.onToggleSidebar});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeModeProvider);
    final currentTime = ref.watch(clockProvider).value ?? DateTime.now();
    final notifications = ref.watch(notificationProvider);
    final unreadCount = ref.watch(unreadNotificationsCountProvider);

    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? AppTheme.darkBg
            : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor.withOpacity(0.05),
          ),
        ),
      ),
      child: Row(
        children: [
          // Sidebar Toggle
          IconButton(
            onPressed: onToggleSidebar,
            icon: const Icon(LucideIcons.menu, size: 20),
            color: theme.textTheme.bodyLarge?.color?.withOpacity(0.6),
          ),
          const SizedBox(width: 16),

          // Search Bar
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              height: 40,
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.dark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.black.withOpacity(0.03),
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search products, transactions, repairs...',
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: theme.textTheme.bodyLarge?.color?.withOpacity(0.4),
                  ),
                  prefixIcon: const Icon(LucideIcons.search, size: 16),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),

          const Spacer(),

          // Theme Toggle
          IconButton(
            onPressed: () {
              ref.read(themeModeProvider.notifier).state =
                  themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
            },
            icon: Icon(
              themeMode == ThemeMode.dark ? LucideIcons.sun : LucideIcons.moon,
              size: 20,
            ),
          ),

          // Notifications
          _NotificationBell(unreadCount: unreadCount, notifications: notifications),

          const SizedBox(width: 16),

          // Vertical Divider
          Container(
            height: 24,
            width: 1,
            color: theme.dividerColor.withOpacity(0.1),
          ),

          const SizedBox(width: 16),

          // Date Display
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                DateFormat('EEEE, MMM dd').format(currentTime),
                style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              Text(
                DateFormat('hh:mm:ss a').format(currentTime),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.grey,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NotificationBell extends ConsumerWidget {
  final int unreadCount;
  final List<AppNotification> notifications;

  const _NotificationBell({required this.unreadCount, required this.notifications});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Stack(
      children: [
        IconButton(
          onPressed: () => _showNotificationPanel(context, ref),
          icon: const Icon(LucideIcons.bell, size: 20),
        ),
        if (unreadCount > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 12,
                minHeight: 12,
              ),
              child: Text(
                unreadCount > 9 ? '9+' : unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 7,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  void _showNotificationPanel(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final notifications = ref.watch(notificationProvider);

    showDialog(
      context: context,
      barrierColor: Colors.black26,
      builder: (context) => Stack(
        children: [
          Positioned(
            top: 70,
            right: 24,
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 350,
                constraints: const BoxConstraints(maxHeight: 500),
                decoration: BoxDecoration(
                  color: theme.brightness == Brightness.dark
                      ? AppTheme.darkSurface
                      : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                  border: Border.all(
                    color: theme.dividerColor.withOpacity(0.05),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Notifications',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          TextButton(
                            onPressed: () {
                              ref.read(notificationProvider.notifier).markAllAsRead();
                            },
                            child: const Text('Mark all as read', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    if (notifications.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(32),
                        child: Text('No notifications yet', style: TextStyle(color: Colors.grey)),
                      )
                    else
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: notifications.length,
                          itemBuilder: (context, index) {
                            final n = notifications[index];
                            return _NotificationCard(notification: n);
                          },
                        ),
                      ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends ConsumerWidget {
  final AppNotification notification;
  const _NotificationCard({required this.notification});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    return InkWell(
      onTap: () {
        ref.read(notificationProvider.notifier).markAsRead(notification.id);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: notification.isRead 
            ? Colors.transparent 
            : AppTheme.primaryColor.withOpacity(0.03),
          border: Border(bottom: BorderSide(color: theme.dividerColor.withOpacity(0.05))),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                notification.icon ?? LucideIcons.bell,
                size: 16,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        notification.title,
                        style: TextStyle(
                          fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        _formatTimestamp(notification.timestamp),
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.message,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.textTheme.bodyLarge?.color?.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat('MMM dd').format(dt);
  }
}
