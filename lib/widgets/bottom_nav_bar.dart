import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:physiq/utils/design_system.dart';

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8.0,
      color: Colors.white, // Pure white
      elevation: 20, // Higher elevation for shadow
      shadowColor: Colors.black.withOpacity(0.1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          _buildNavItem(context,
              activeIcon: Icons.home_filled, // Filled icon for active
              inactiveIcon: Icons.home_outlined,
              label: 'Home',
              route: '/home'),
          _buildNavItem(context,
              activeIcon: Icons.bar_chart_rounded,
              inactiveIcon: Icons.bar_chart_outlined,
              label: 'Progress',
              route: '/progress'),
          const SizedBox(width: 48), // The space for the FAB
          _buildNavItem(context,
              activeIcon: Icons.fitness_center,
              inactiveIcon: Icons.fitness_center_outlined,
              label: 'Exercise',
              route: '/exercise'),
          _buildNavItem(context,
              activeIcon: Icons.settings,
              inactiveIcon: Icons.settings_outlined,
              label: 'Settings',
              route: '/settings'),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context,
      {required IconData activeIcon,
      required IconData inactiveIcon,
      required String label,
      required String route}) {
    // In lib/widgets/bottom_nav_bar.dart
    final String currentLocation = GoRouterState.of(context).uri.toString();

    // The '/home' route can be matched by either '/' or '/home'.
    // For other routes, we use startsWith to handle potential nested routes correctly.
    final bool isSelected = (route == '/home')
        ? (currentLocation == '/' || currentLocation == '/home')
        : currentLocation.startsWith(route);

    return InkWell(
      onTap: () => context.go(route),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        // Reduced vertical padding to prevent the overflow error.
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              isSelected ? activeIcon : inactiveIcon,
              color: isSelected ? const Color(0xFF111827) : const Color(0xFF9CA3AF), // Black active, Grey inactive
              size: 26, // Slightly larger icons
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.label.copyWith(
                fontSize: 10, // Smaller font
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? const Color(0xFF111827) : const Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
