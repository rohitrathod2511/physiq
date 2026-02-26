import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:physiq/theme/design_system.dart';

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isCompact = screenWidth < 390;
    final bool isDark = theme.brightness == Brightness.dark;
    final double outerHorizontalPadding = isCompact ? 14 : 22;
    final double navItemHorizontalPadding = isCompact ? 12 : 16;
    final double navLabelFontSize = isCompact ? 11 : 12;
    final Color selectedContentColor = theme.colorScheme.onSurface;
    final Color unselectedContentColor = theme.colorScheme.onSurface.withValues(
      alpha: isDark ? 0.72 : 0.62,
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        outerHorizontalPadding,
        0,
        outerHorizontalPadding,
        18,
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(46),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.08),
              blurRadius: 18,
              spreadRadius: -4,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(46),
          child: Stack(
            children: [
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                  child: const SizedBox.expand(),
                ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? theme.colorScheme.surface.withValues(alpha: 0.38)
                        : theme.colorScheme.surface.withValues(alpha: 0.52),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.12)
                          : Colors.white.withValues(alpha: 0.22),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    _buildNavItem(
                      context,
                      activeIcon: Icons.home_filled,
                      inactiveIcon: Icons.home_outlined,
                      label: 'Home',
                      route: '/home',
                      isDark: isDark,
                      horizontalPadding: navItemHorizontalPadding,
                      labelFontSize: navLabelFontSize,
                      selectedContentColor: selectedContentColor,
                      unselectedContentColor: unselectedContentColor,
                    ),
                    _buildNavItem(
                      context,
                      activeIcon: Icons.bar_chart_rounded,
                      inactiveIcon: Icons.bar_chart_outlined,
                      label: 'Progress',
                      route: '/progress',
                      isDark: isDark,
                      horizontalPadding: navItemHorizontalPadding,
                      labelFontSize: navLabelFontSize,
                      selectedContentColor: selectedContentColor,
                      unselectedContentColor: unselectedContentColor,
                    ),
                    const SizedBox(width: 48), // The space for the FAB
                    _buildNavItem(
                      context,
                      activeIcon: Icons.fitness_center,
                      inactiveIcon: Icons.fitness_center_outlined,
                      label: 'Exercise',
                      route: '/exercise',
                      isDark: isDark,
                      horizontalPadding: navItemHorizontalPadding,
                      labelFontSize: navLabelFontSize,
                      selectedContentColor: selectedContentColor,
                      unselectedContentColor: unselectedContentColor,
                    ),
                    _buildNavItem(
                      context,
                      activeIcon: Icons.settings,
                      inactiveIcon: Icons.settings_outlined,
                      label: 'Settings',
                      route: '/settings',
                      isDark: isDark,
                      horizontalPadding: navItemHorizontalPadding,
                      labelFontSize: navLabelFontSize,
                      selectedContentColor: selectedContentColor,
                      unselectedContentColor: unselectedContentColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData activeIcon,
    required IconData inactiveIcon,
    required String label,
    required String route,
    required bool isDark,
    required double horizontalPadding,
    required double labelFontSize,
    required Color selectedContentColor,
    required Color unselectedContentColor,
  }) {
    final String currentLocation = GoRouterState.of(context).matchedLocation;

    final bool isSelected = (route == '/home')
        ? (currentLocation == '/' || currentLocation == '/home')
        : currentLocation.startsWith(route);

    return InkWell(
      onTap: () => context.go(route),
      borderRadius: BorderRadius.circular(30),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          vertical: 8,
          horizontal: horizontalPadding,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                    ? Colors.white.withValues(alpha: 0.14)
                    : Colors.white.withValues(alpha: 0.28))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          border: isSelected
              ? Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.18)
                      : Colors.white.withValues(alpha: 0.3),
                )
              : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.09),
                    blurRadius: 12,
                    spreadRadius: -4,
                    offset: const Offset(0, 5),
                  ),
                ]
              : const [],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeOutCubic,
              transitionBuilder: (child, animation) =>
                  FadeTransition(opacity: animation, child: child),
              child: Icon(
                isSelected ? activeIcon : inactiveIcon,
                key: ValueKey('${label}_$isSelected'),
                color: isSelected
                    ? selectedContentColor
                    : unselectedContentColor,
                size: 28,
              ),
            ),
            const SizedBox(height: 1),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              style: AppTextStyles.label.copyWith(
                fontSize: labelFontSize,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? selectedContentColor
                    : unselectedContentColor,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
