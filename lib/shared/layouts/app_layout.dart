import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mbm_app/core/theme/app_theme.dart';
import 'package:mbm_app/shared/sidebar/sidebar.dart';
import 'package:mbm_app/shared/navbar/navbar.dart';

class AppLayout extends ConsumerStatefulWidget {
  final Widget child;
  const AppLayout({super.key, required this.child});

  @override
  ConsumerState<AppLayout> createState() => _AppLayoutState();
}

class _AppLayoutState extends ConsumerState<AppLayout> {
  bool isSidebarCollapsed = false;

  void toggleSidebar() {
    setState(() {
      isSidebarCollapsed = !isSidebarCollapsed;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sidebarWidth = isSidebarCollapsed 
        ? theme.collapsedSidebarWidth 
        : theme.sidebarWidth;

    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: sidebarWidth,
            child: Sidebar(isCollapsed: isSidebarCollapsed),
          ),
          
          // Main Content Area
          Expanded(
            child: Column(
              children: [
                // Top Navbar
                Navbar(onToggleSidebar: toggleSidebar),
                
                // Content
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: theme.brightness == Brightness.dark
                          ? AppTheme.darkBg
                          : AppTheme.lightBg,
                    ),
                    child: widget.child,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
