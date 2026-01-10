
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:physiq/providers/onboarding_provider.dart';
import 'package:physiq/theme/design_system.dart';

class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  late TextEditingController _proteinController;
  late TextEditingController _fatController;
  late TextEditingController _carbsController;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
       final store = ref.read(onboardingProvider);
       final plan = store.data['currentPlan'] as Map<String, dynamic>?;
       
       _proteinController = TextEditingController(text: (plan?['proteinG'] ?? 0).toString());
       _fatController = TextEditingController(text: (plan?['fatG'] ?? 0).toString());
       _carbsController = TextEditingController(text: (plan?['carbsG'] ?? 0).toString());
       _initialized = true;
    }
  }

  void _recalc() {
    setState(() {});
  }

  void _onSave() {
    final store = ref.read(onboardingProvider);
    final plan = Map<String, dynamic>.from(store.data['currentPlan'] ?? {});
    
    plan['proteinG'] = int.tryParse(_proteinController.text) ?? 0;
    plan['fatG'] = int.tryParse(_fatController.text) ?? 0;
    plan['carbsG'] = int.tryParse(_carbsController.text) ?? 0;
    
    // Recalculate calories
    plan['goalCalories'] = (plan['proteinG'] * 4) + (plan['fatG'] * 9) + (plan['carbsG'] * 4);
    
    store.saveStepData('currentPlan', plan);
    context.push('/onboarding/motivational-quote');
  }

  @override
  Widget build(BuildContext context) {
    final p = int.tryParse(_proteinController.text) ?? 0;
    final f = int.tryParse(_fatController.text) ?? 0;
    final c = int.tryParse(_carbsController.text) ?? 0;
    final totalCal = (p * 4) + (f * 9) + (c * 4);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Text(
              "Review Your Plan",
              style: AppTextStyles.h1,
            ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Calorie Card
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppRadii.card),
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
                              style: AppTextStyles.largeNumber.copyWith(fontSize: 48),
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
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: _onSave,
                child: const Text('Confirm & Continue'),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroRow(
    String label,
    TextEditingController controller,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
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
              style: AppTextStyles.bodyBold,
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
