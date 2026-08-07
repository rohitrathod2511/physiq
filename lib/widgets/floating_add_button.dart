import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:physiq/theme/design_system.dart';
import 'package:physiq/screens/meal/meal_logging_flows.dart';
import 'package:physiq/providers/subscription_provider.dart';
import 'package:physiq/services/premium_guard.dart';

class FloatingAddButton extends ConsumerWidget {
  const FloatingAddButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: 72,
      height: 72,
      child: FloatingActionButton(
        onPressed: () async {
          final allowed = await PremiumGuard.requirePremium(context, ref);
          if (allowed && context.mounted) {
            _showAddOptions(context, ref);
          }
        },
        backgroundColor: const Color(0xFF111827),
        foregroundColor: Colors.white,
        elevation: 10.0,
        shape: const CircleBorder(),
        heroTag: null,
        child: Stack(
          alignment: Alignment.center,
          children: const [
            Icon(Icons.add, size: 36),
          ],
        ),
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
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Padding(
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
                  _buildOptionTile(
                    sheetContext,
                    'Snap Meal',
                    Icons.camera_alt_outlined,
                    () => showSnapMealFlow(context, ref),
                  ),
                  _buildOptionTile(
                    sheetContext,
                    'Food Database',
                    Icons.search,
                    () => showFoodDatabaseFlow(context, ref),
                  ),
                  _buildOptionTile(
                    sheetContext,
                    'Saved Foods',
                    Icons.bookmark_border,
                    () => showSavedFoodsFlow(context, ref),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOptionTile(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTapAction,
  ) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primaryText, size: 28),
      title: Text(
        title,
        style: AppTextStyles.label.copyWith(
          fontSize: 16,
          color: AppColors.primaryText,
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        onTapAction();
      },
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.smallCard),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
    );
  }
}
