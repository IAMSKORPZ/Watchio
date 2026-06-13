import 'package:flutter/material.dart';
import 'sidebar_item.dart';
import 'universal_top_bar.dart';

class AppShell extends StatefulWidget {
  final List<Widget>? pages;
  final Widget? body;
  final List<({IconData icon, String label})>? navItems;
  final int currentIndex;
  final Function(int)? onIndexChanged;
  final VoidCallback? onSearchTap;
  final VoidCallback? onProfileTap;
  final VoidCallback? onRefreshTap;
  final VoidCallback? onSettingsTap;
  final String? title;
  final Widget? floatingActionButton;
  final VoidCallback? onRefresh;

  const AppShell({
    super.key,
    this.pages,
    this.body,
    this.navItems,
    this.currentIndex = 0,
    this.onIndexChanged,
    this.onSearchTap,
    this.onProfileTap,
    this.onRefreshTap,
    this.onSettingsTap,
    this.title,
    this.floatingActionButton,
    this.onRefresh,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  bool _isSidebarCollapsed = true;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
        final isLargeDesktop = constraints.maxWidth >= 1200;
        
        // Only show global sidebar if on a very large screen and not on dashboard
        final bool showSidebar = isLargeDesktop && widget.navItems != null && widget.currentIndex != 0;

        return PopScope(
          canPop: widget.currentIndex == 0,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            // If not on home, go back to home instead of exiting
            if (widget.currentIndex != 0) {
              widget.onIndexChanged?.call(0);
            }
          },
          child: Scaffold(
            body: Row(
              children: [
                if (showSidebar)
                  MouseRegion(
                    onEnter: (_) => setState(() => _isSidebarCollapsed = false),
                    onExit: (_) => setState(() => _isSidebarCollapsed = true),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: _isSidebarCollapsed ? 70 : 200,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        border: Border(
                          right: BorderSide(
                            color: Colors.white.withValues(alpha: 0.05),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          const Icon(Icons.tv, color: Colors.blue, size: 30),
                          const SizedBox(height: 30),
                          Expanded(
                            child: ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              itemCount: widget.navItems!.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 4),
                              itemBuilder: (context, index) {
                                final item = widget.navItems![index];
                                return SidebarItem(
                                  icon: item.icon,
                                  label: item.label,
                                  selected: widget.currentIndex == index,
                                  isCollapsed: _isSidebarCollapsed,
                                  onTap: () => widget.onIndexChanged?.call(index),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                Expanded(
                  child: Column(
                    children: [
                      if (widget.currentIndex != 0 && widget.currentIndex != 2) // Hide for Home and Live TV
                        SafeArea(
                          bottom: false,
                          child: UniversalTopBar(
                            title: widget.title,
                            onSearchTap: widget.onSearchTap,
                            onProfileTap: widget.onProfileTap,
                            onRefreshTap: widget.onRefreshTap ?? widget.onRefresh,
                            onSettingsTap: widget.onSettingsTap,
                          ),
                        ),
                      Expanded(
                        child: widget.pages != null
                            ? IndexedStack(
                                index: widget.currentIndex,
                                children: widget.pages!,
                              )
                            : (widget.body ?? const SizedBox.shrink()),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            floatingActionButton: widget.floatingActionButton,
            // Hide bottom navigation bar completely in landscape or on specific pages (Home/Live TV)
            bottomNavigationBar: (!isLandscape && widget.navItems != null && widget.currentIndex != 0 && widget.currentIndex != 2)
                ? BottomNavigationBar(
                    currentIndex: widget.currentIndex,
                    onTap: widget.onIndexChanged,
                    type: BottomNavigationBarType.fixed,
                    selectedFontSize: 10,
                    unselectedFontSize: 10,
                    iconSize: 20,
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    selectedItemColor: Theme.of(context).primaryColor,
                    unselectedItemColor: Colors.white.withValues(alpha: 0.5),
                    items: widget.navItems!
                        .map((item) => BottomNavigationBarItem(
                              icon: Icon(item.icon),
                              label: item.label,
                            ))
                        .toList(),
                  )
                : null,
          ),
        );
      },
    );
  }
}
