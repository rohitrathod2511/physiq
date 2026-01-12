import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:physiq/theme/design_system.dart';
import 'package:physiq/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MacroAdjustmentScreen extends ConsumerStatefulWidget {
  const MacroAdjustmentScreen({super.key});

  @override
  ConsumerState<MacroAdjustmentScreen> createState() => _MacroAdjustmentScreenState();
}

class _MacroAdjustmentScreenState extends ConsumerState<MacroAdjustmentScreen> {
  final _caloriesController = TextEditingController(text: '2000');
  final _proteinController = TextEditingController(text: '150');
  final _carbsController = TextEditingController(text: '200');
  final _fatsController = TextEditingController(text: '65');
  final _fiberController = TextEditingController(text: '30');
  final _sugarController = TextEditingController(text: '40');
  final _sodiumController = TextEditingController(text: '2300');
  final _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _loadCurrentMacros();
  }

  Future<void> _loadCurrentMacros() async {
    // In a real app, load from Firestore or Provider
    // For now, we keep defaults or load if available
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Edit Nutrition Goals', style: AppTextStyles.heading2),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: AppColors.primaryText),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Progress Ring & Main Calorie Input
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: CircularProgressIndicator(
                      value: 0.7, // Mock value
                      strokeWidth: 10,
                      backgroundColor: Colors.grey[200],
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.local_fire_department, color: Colors.orange),
                      Text('Calories', style: AppTextStyles.smallLabel),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            _buildMacroInput('Calories (kcal)', _caloriesController),
            const SizedBox(height: 16),
            _buildMacroInput('Protein (g)', _proteinController, color: AppColors.primary),
            const SizedBox(height: 16),
            _buildMacroInput('Carbs (g)', _carbsController, color: Colors.blue),
            const SizedBox(height: 16),
            _buildMacroInput('Fats (g)', _fatsController, color: Colors.orange),
            const SizedBox(height: 16),
            _buildMacroInput('Fiber (g)', _fiberController),
            const SizedBox(height: 16),
            _buildMacroInput('Sugar (g)', _sugarController),
            const SizedBox(height: 16),
            _buildMacroInput('Sodium (mg)', _sodiumController),
            
            const SizedBox(height: 20),
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
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroInput(String label, TextEditingController controller, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            const SizedBox(width: 12),
          ],
          Expanded(child: Text(label, style: AppTextStyles.bodyMedium)),
          SizedBox(
            width: 80,
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.end,
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
              ),
              style: AppTextStyles.bodyBold,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.edit, size: 16, color: AppColors.secondaryText),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await _firestoreService.updateMacros(uid, {
        'calories': int.tryParse(_caloriesController.text) ?? 2000,
        'protein_g': int.tryParse(_proteinController.text) ?? 150,
        'carbs_g': int.tryParse(_carbsController.text) ?? 200,
        'fat_g': int.tryParse(_fatsController.text) ?? 65,
        'fiber_g': int.tryParse(_fiberController.text) ?? 30,
        'sugar_g': int.tryParse(_sugarController.text) ?? 40,
        'sodium_mg': int.tryParse(_sodiumController.text) ?? 2300,
      });
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nutrition goals saved!')),
        );
      }
    }
  }
}
