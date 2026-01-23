import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:physiq/theme/design_system.dart';
import 'package:physiq/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:physiq/viewmodels/home_viewmodel.dart';

class MacroAdjustmentScreen extends ConsumerStatefulWidget {
  const MacroAdjustmentScreen({super.key});

  @override
  ConsumerState<MacroAdjustmentScreen> createState() => _MacroAdjustmentScreenState();
}

class _MacroAdjustmentScreenState extends ConsumerState<MacroAdjustmentScreen> {
  late TextEditingController _caloriesController;
  late TextEditingController _proteinController;
  late TextEditingController _carbsController;
  late TextEditingController _fatsController;
  final _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    final homeState = ref.read(homeViewModelProvider);
    final plan = homeState.currentPlan ?? {};

    // Defaults matching Onboarding/Home fallback
    // calories: 2000, protein: 150, carbs: 200, fat: 65
    _caloriesController = TextEditingController(text: (plan['calories'] ?? 2000).toString());
    _proteinController = TextEditingController(text: (plan['protein'] ?? 150).toString());
    _carbsController = TextEditingController(text: (plan['carbs'] ?? 200).toString());
    _fatsController = TextEditingController(text: (plan['fat'] ?? 65).toString());
  }

  @override
  void dispose() {
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatsController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final int calories = int.tryParse(_caloriesController.text) ?? 2000;
      final int protein = int.tryParse(_proteinController.text) ?? 150;
      final int carbs = int.tryParse(_carbsController.text) ?? 200;
      final int fat = int.tryParse(_fatsController.text) ?? 65;

      final newPlan = {
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'source': 'manual',
        'updatedAt': DateTime.now().toIso8601String(), // converting to ISO string or Timestamp? 
        // FirestoreService uses merge, so we should be consistent. ReviewScreen used FieldValue.serverTimestamp().
        // However, updating HomeViewModel immediately requires a concrete value or we handle it.
        // Let's us FieldValue for Firestore and just put map in HomeViewModel.
      };

      // 1. Update Firestore (Single Source of Truth)
      // We pass the newPlan nested under 'currentPlan' to match ReviewScreen logic
      await _firestoreService.updateUserProfile(uid, {'currentPlan': newPlan});

      // 2. Update Local State (Immediate UI Refresh)
      ref.read(homeViewModelProvider.notifier).updateCurrentPlan(newPlan);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nutrition goals saved!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Edit Nutrition Goals', style: AppTextStyles.heading2),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: AppColors.primaryText),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildMacroInput('Calories (kcal)', _caloriesController),
            const SizedBox(height: 16),
            _buildMacroInput('Protein (g)', _proteinController, color: const Color(0xFFE55B5B)), // Red
            const SizedBox(height: 16),
            _buildMacroInput('Carbs (g)', _carbsController, color: const Color(0xFFE8AA42)), // Yellow/Gold
            const SizedBox(height: 16),
            _buildMacroInput('Fats (g)', _fatsController, color: const Color(0xFF5B8BE5)), // Blue
            
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: Text('Save Goals', style: AppTextStyles.button.copyWith(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroInput(String label, TextEditingController controller, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadii.card),
        boxShadow: [AppShadows.card],
      ),
      child: Row(
        children: [
          if (color != null) ...[
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(child: Text(label, style: AppTextStyles.bodyMedium.copyWith(fontSize: 16))),
          SizedBox(
            width: 80,
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.end,
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: AppTextStyles.bodyBold.copyWith(fontSize: 18),
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.edit, size: 16, color: AppColors.secondaryText),
        ],
      ),
    );
  }
}
