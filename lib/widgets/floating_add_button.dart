import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:physiq/utils/design_system.dart';
import 'package:physiq/viewmodels/home_viewmodel.dart';

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
            _showAddOptions(context);
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

  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.bigCard)),
      ),
      builder: (context) {
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
              _buildOptionTile(context, 'Snap Meal', Icons.camera_alt_outlined),
              _buildOptionTile(context, 'Add Manually', Icons.edit_outlined),
              _buildOptionTile(context, 'Voice Entry', Icons.mic_outlined),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOptionTile(BuildContext context, String title, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primaryText, size: 28),
      title: Text(title, style: AppTextStyles.label.copyWith(fontSize: 16, color: AppColors.primaryText)),
      onTap: () => Navigator.pop(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.smallCard),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
    );
  }
}
