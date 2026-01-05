import 'package:flutter/material.dart';
import 'package:physiq/widgets/bottom_nav_bar.dart';
import 'package:physiq/widgets/floating_add_button.dart';
import 'package:physiq/theme/design_system.dart';

class ScaffoldWithNavBar extends StatelessWidget {
  final Widget child;

  const ScaffoldWithNavBar({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: child,
      bottomNavigationBar: const BottomNavBar(),
      floatingActionButton: const FloatingAddButton(),
      // Centering the button and docking it to the BottomAppBar
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
