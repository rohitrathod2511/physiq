import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:physiq/theme/design_system.dart';
import 'package:physiq/viewmodels/onboarding_viewmodel.dart';

class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  late TextEditingController _proteinController;
  late TextEditingController _fatController;
  late TextEditingController _carbsController;

  @override
  void initState() {
    super.initState();
    final plan = ref.read(onboardingProvider).calculatedPlan;
    // Safely handle null values by defaulting to '0'
    _proteinController = TextEditingController(text: (plan?['proteinG'] ?? 0).toString());
    _fatController = TextEditingController(text: (plan?['fatG'] ?? 0).toString());
    _carbsController = TextEditingController(text: (plan?['carbsG'] ?? 0).toString());
  }

  void _recalc() {
    final p = int.tryParse(_proteinController.text) ?? 0;
    final f = int.tryParse(_fatController.text) ?? 0;
    final c = int.tryParse(_carbsController.text) ?? 0;

    // Update state
    ref.read(onboardingProvider.notifier).updateMacroSplit(
      proteinG: p,
      fatG: f,
      carbsG: c,
    );
    
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingProvider);
    final plan = state.calculatedPlan;

    if (plan == null) {
      return const Scaffold(body: Center(child: Text('No plan generated.')));
    }

    // Calculate total calories from current inputs
    final p = int.tryParse(_proteinController.text) ?? 0;
    final f = int.tryParse(_fatController.text) ?? 0;
    final c = int.tryParse(_carbsController.text) ?? 0;
    final totalCal = (p * 4) + (f * 9) + (c * 4);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Review Your Plan'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Calorie Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text('Daily Calories', style: AppTextStyles.h3),
                  const SizedBox(height: 8),
                  Text(
                    '$totalCal',
                    style: AppTextStyles.h1.copyWith(fontSize: 48, color: AppColors.primary),
                  ),
                  const Text('kcal', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Macros
            _buildMacroRow('Protein', _proteinController, Colors.redAccent),
            const SizedBox(height: 16),
            _buildMacroRow('Fats', _fatController, Colors.orangeAccent),
            const SizedBox(height: 16),
            _buildMacroRow('Carbs', _carbsController, Colors.blueAccent),

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: () {
                  context.go('/paywall');
                },
                child: Text('Save & Continue', style: AppTextStyles.button),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroRow(String label, TextEditingController controller, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(radius: 6, backgroundColor: color),
          const SizedBox(width: 12),
          Text(label, style: AppTextStyles.h3),
          const Spacer(),
          SizedBox(
            width: 80,
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.end,
              decoration: const InputDecoration(
                border: InputBorder.none,
                suffixText: 'g',
              ),
              onChanged: (_) => _recalc(),
            ),
          ),
        ],
      ),
    );
  }
}
