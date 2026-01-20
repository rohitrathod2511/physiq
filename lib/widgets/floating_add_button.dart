import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:physiq/theme/design_system.dart';
import 'package:physiq/viewmodels/home_viewmodel.dart';
import 'package:physiq/screens/meal/meal_logging_flows.dart';

class FloatingAddButton extends ConsumerWidget {
  const FloatingAddButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = true; // Hardcoded for UI-only task

    return SizedBox(
      width: 72, // Larger size
      height: 72,
      child: FloatingActionButton(
        onPressed: () {
          if (isPremium) {
            _showAddOptions(context, ref);
          } else {
            context.go('/paywall');
          }
        },
        backgroundColor: const Color(0xFF111827), // Dark/Black color
        foregroundColor: Colors.white,
        elevation: 10.0,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 36, weight: 400), // Thinner plus icon
        heroTag: null, // Avoids tag conflicts
      ),
    );
  }

  void _showAddOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.bigCard)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text('Add a Meal', style: AppTextStyles.heading2),
              ),
              const SizedBox(height: 16),
              // FIX: Passing 'context' (parent) instead of 'sheetContext' so it remains mounted after pop
              _buildOptionTile(sheetContext, 'Snap Meal', Icons.camera_alt_outlined, () => showSnapMealFlow(context, ref)),
              _buildOptionTile(sheetContext, 'Add Manually', Icons.edit_outlined, () => showManualEntryFlow(context, ref)),
              _buildOptionTile(sheetContext, 'Voice Entry', Icons.mic_outlined, () => showVoiceEntryFlow(context, ref)),
            ],
          ),
        );
      },
    );

  }

  Widget _buildOptionTile(BuildContext context, String title, IconData icon, VoidCallback onTapAction) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primaryText, size: 28),
      title: Text(title, style: AppTextStyles.label.copyWith(fontSize: 16, color: AppColors.primaryText)),
      onTap: () {
        Navigator.pop(context); // Close the bottom sheet first
        onTapAction();
      },
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.smallCard),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
    );
  }
}
