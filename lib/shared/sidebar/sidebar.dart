import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mbm_app/core/theme/app_theme.dart';

class Sidebar extends StatelessWidget {
  final bool isCollapsed;
  const Sidebar({super.key, required this.isCollapsed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final location = GoRouterState.of(context).uri.path;

    return Container(
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? AppTheme.darkSurface
            : Colors.white,
        border: Border(
          right: BorderSide(
            color: theme.dividerColor.withOpacity(0.05),
          ),
        ),
      ),
      child: Column(
        children: [
          // Logo Section
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
            child: Row(
              mainAxisAlignment: isCollapsed
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(LucideIcons.smartphone, color: Colors.white, size: 24),
                ),
                if (!isCollapsed) ...[
                  const SizedBox(width: 12),
                  Text(
                    'MBM',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Menu Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _SidebarItem(
                  icon: LucideIcons.layoutDashboard,
                  label: 'Dashboard',
                  route: '/dashboard',
                  isSelected: location == '/dashboard',
                  isCollapsed: isCollapsed,
                ),
                _SidebarItem(
                  icon: LucideIcons.shoppingCart,
                  label: 'Sales',
                  route: '/sales',
                  isSelected: location == '/sales',
                  isCollapsed: isCollapsed,
                ),
                _SidebarItem(
                  icon: LucideIcons.wrench,
                  label: 'Repairs',
                  route: '/repairs',
                  isSelected: location == '/repairs',
                  isCollapsed: isCollapsed,
                ),
                _SidebarItem(
                  icon: LucideIcons.box,
                  label: 'Inventory Hub',
                  route: '/inventory',
                  isSelected: location == '/inventory' || location == '/low-stock' || location == '/purchases',
                  isCollapsed: isCollapsed,
                ),
                const Divider(height: 32, indent: 8, endIndent: 8),
                _SidebarItem(
                  icon: LucideIcons.users,
                  label: 'Customers',
                  route: '/customers',
                  isSelected: location == '/customers',
                  isCollapsed: isCollapsed,
                ),
                _SidebarItem(
                  icon: LucideIcons.truck,
                  label: 'Suppliers',
                  route: '/suppliers',
                  isSelected: location == '/suppliers',
                  isCollapsed: isCollapsed,
                ),
                _SidebarItem(
                  icon: LucideIcons.refreshCcw,
                  label: 'Returns',
                  route: '/returns',
                  isSelected: location == '/returns',
                  isCollapsed: isCollapsed,
                ),
                const Divider(height: 32, indent: 8, endIndent: 8),
                _SidebarItem(
                  icon: LucideIcons.barChart2,
                  label: 'Analytics',
                  route: '/analytics',
                  isSelected: location == '/analytics',
                  isCollapsed: isCollapsed,
                ),
                _SidebarItem(
                  icon: LucideIcons.history,
                  label: 'Transactions',
                  route: '/transactions',
                  isSelected: location == '/transactions',
                  isCollapsed: isCollapsed,
                ),
                _SidebarItem(
                  icon: LucideIcons.calculator,
                  label: 'Accounts',
                  route: '/accounts',
                  isSelected: location == '/accounts',
                  isCollapsed: isCollapsed,
                ),
                _SidebarItem(
                  icon: LucideIcons.settings,
                  label: 'Settings',
                  route: '/settings',
                  isSelected: location == '/settings',
                  isCollapsed: isCollapsed,
                ),
              ],
            ),
          ),

          // User Profile Mini (Optional)
          if (!isCollapsed)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.brightness == Brightness.dark
                      ? Colors.white.withOpacity(0.03)
                      : Colors.black.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 16,
                      backgroundColor: AppTheme.primaryColor,
                      child: Text('A', style: TextStyle(color: Colors.white, fontSize: 12)),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Admin', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Text('Super User', style: TextStyle(color: Colors.grey, fontSize: 11)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(LucideIcons.logOut, size: 16, color: Colors.grey[600]),
                      onPressed: () => context.go('/login'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;
  final bool isSelected;
  final bool isCollapsed;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.isSelected,
    required this.isCollapsed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeColor = AppTheme.primaryColor;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: () => context.go(route),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(
            vertical: 12,
            horizontal: isCollapsed ? 0 : 16,
          ),
          decoration: BoxDecoration(
            color: isSelected 
                ? activeColor.withOpacity(0.1) 
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: isCollapsed 
                ? MainAxisAlignment.center 
                : MainAxisAlignment.start,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? activeColor : theme.textTheme.bodyLarge?.color?.withOpacity(0.6),
              ),
              if (!isCollapsed) ...[
                const SizedBox(width: 12),
                Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? activeColor : theme.textTheme.bodyLarge?.color?.withOpacity(0.7),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
