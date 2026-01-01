import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mbm_app/core/models/app_models.dart';
import 'package:lucide_icons/lucide_icons.dart';

class NotificationNotifier extends StateNotifier<List<AppNotification>> {
  NotificationNotifier() : super([
    AppNotification(
      id: '1',
      title: 'Low Stock Alert',
      message: 'Google Pixel 8 Pro is below threshold.',
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      icon: LucideIcons.alertTriangle,
    ),
    AppNotification(
      id: '2',
      title: 'New Repair Ticket',
      message: 'Customer Ahmed submitted a new repair request.',
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      icon: LucideIcons.wrench,
    ),
  ]);

  void addNotification(AppNotification notification) {
    state = [notification, ...state];
  }

  void markAsRead(String id) {
    state = [
      for (final n in state)
        if (n.id == id) n.copyWith(isRead: true) else n
    ];
  }

  void markAllAsRead() {
    state = [
      for (final n in state) n.copyWith(isRead: true)
    ];
  }

  void clearAll() {
    state = [];
  }
}

final notificationProvider = StateNotifierProvider<NotificationNotifier, List<AppNotification>>((ref) {
  return NotificationNotifier();
});

final unreadNotificationsCountProvider = Provider<int>((ref) {
  return ref.watch(notificationProvider).where((n) => !n.isRead).length;
});
