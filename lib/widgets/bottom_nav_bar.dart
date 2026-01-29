import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:physiq/theme/design_system.dart';
import 'package:physiq/main.dart';
import 'package:physiq/l10n/app_localizations.dart';

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, themeMode, _) {
        return BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 8.0,
          color: AppColors.background,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              _buildNavItem(context, activeIcon: Icons.home_filled, inactiveIcon: Icons.home_outlined, label: AppLocalizations.of(context)!.home, route: '/home'),
              _buildNavItem(context, activeIcon: Icons.bar_chart_rounded, inactiveIcon: Icons.bar_chart_outlined, label: AppLocalizations.of(context)!.progress, route: '/progress'),
              const SizedBox(width: 48), // The space for the FAB
              _buildNavItem(context, activeIcon: Icons.fitness_center, inactiveIcon: Icons.fitness_center_outlined, label: AppLocalizations.of(context)!.exercise, route: '/exercise'),
              _buildNavItem(context, activeIcon: Icons.settings, inactiveIcon: Icons.settings_outlined, label: AppLocalizations.of(context)!.settingsTitle, route: '/settings'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNavItem(BuildContext context, {required IconData activeIcon, required IconData inactiveIcon, required String label, required String route}) {
    final String currentLocation = GoRouterState.of(context).matchedLocation;

    final bool isSelected = (route == '/home')
        ? (currentLocation == '/' || currentLocation == '/home')
        : currentLocation.startsWith(route);

    return InkWell(
      onTap: () => context.go(route),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              isSelected ? activeIcon : inactiveIcon,
              color: isSelected ? AppColors.primaryText : AppColors.secondaryText,
              // Increased icon size
              size: 28,
            ),
            // Reduced spacing to accommodate larger elements
            const SizedBox(height: 0),
            Text(
              label,
              style: AppTextStyles.label.copyWith(
                // Increased font size
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.primaryText : AppColors.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
