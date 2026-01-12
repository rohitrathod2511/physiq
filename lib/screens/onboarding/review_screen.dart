
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
    context.push('/onboarding/notification');
  }

  @override
  Widget build(BuildContext context) {
    final store = ref.read(onboardingProvider);
    final p = int.tryParse(_proteinController.text) ?? 0;
    final f = int.tryParse(_fatController.text) ?? 0;
    final c = int.tryParse(_carbsController.text) ?? 0;
    final totalCal = (p * 4) + (f * 9) + (c * 4);

    // Fetch target data
    final targetWeightVal = store.data['targetWeightKg'];
    final targetWeight = targetWeightVal != null ? targetWeightVal.toStringAsFixed(1) : '--';
    
    // Calculate date based on timeframeMonths (default to 6 if missing)
    final months = store.data['timeframeMonths'] ?? 6; 
    final targetDate = DateTime.now().add(Duration(days: months * 30));
    final dateString = _formatDate(targetDate);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Column(
            children: [
              // 1. Success Icon (Checkmark)
              Container(
                 padding: const EdgeInsets.all(12),
                 decoration: const BoxDecoration(
                   color: Colors.black,
                   shape: BoxShape.circle,
                 ),
                 child: const Icon(Icons.check, color: Colors.white, size: 32),
              ),
              const SizedBox(height: 24),

              // 2. Title & Subtitle
              Text(
                "Congratulations\nyour custom plan is ready!",
                textAlign: TextAlign.center,
                style: AppTextStyles.h2.copyWith(fontSize: 24, height: 1.2),
              ),
              const SizedBox(height: 60),


              // 5. Macro Cards Grid
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.85,
                children: [
                   // Calories Card
                   _buildMacroCard(
                     title: "Calories",
                     icon: Icons.local_fire_department_rounded,
                     color: Colors.black,
                     value: totalCal.toString(),
                     unit: "",
                     isEditable: false,
                     progress: 1.0,
                   ),
                   // Carbs
                   _buildMacroCard(
                     title: "Carbs",
                     icon: Icons.grain_rounded,
                     color: const Color(0xFFE8AA42), // Wheat/Gold
                     controller: _carbsController,
                     unit: "g",
                     isEditable: true,
                     progress: totalCal > 0 ? (c * 4) / totalCal : 0,
                   ),
                   // Protein
                   _buildMacroCard(
                     title: "Protein",
                     icon: Icons.lunch_dining_rounded,
                     color: const Color(0xFFE55B5B), // Red/Pink
                     controller: _proteinController,
                     unit: "g",
                     isEditable: true,
                     progress: totalCal > 0 ? (p * 4) / totalCal : 0,
                   ),
                   // Fats
                   _buildMacroCard(
                     title: "Fats",
                     icon: Icons.water_drop_rounded,
                     color: const Color(0xFF5B8BE5), // Blue
                     controller: _fatController,
                     unit: "g",
                     isEditable: true,
                     progress: totalCal > 0 ? (f * 9) / totalCal : 0,
                   ),
                ],
              ),
              
              const SizedBox(height: 80),

              // Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _onSave,
                  child: const Text('Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMacroCard({
    required String title,
    required IconData icon,
    required Color color,
    TextEditingController? controller,
    String? value,
    required String unit,
    required bool isEditable,
    required double progress,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 18, color: color.withOpacity(0.8)),
                    const SizedBox(width: 8),
                    Text(title, style: AppTextStyles.bodyBold.copyWith(fontSize: 14)),
                  ],
                ),
                const Spacer(),
                Center(
                  child: SizedBox(
                    width: 80,
                    height: 80,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 6,
                          backgroundColor: Colors.grey.shade100,
                          color: color,
                          strokeCap: StrokeCap.round,
                        ),
                        Column(
                           mainAxisSize: MainAxisSize.min,
                           children: [
                             if (isEditable && controller != null)
                               SizedBox(
                                 width: 50,
                                 child: TextField(
                                   controller: controller,
                                   keyboardType: TextInputType.number,
                                   textAlign: TextAlign.center,
                                   style: AppTextStyles.h3.copyWith(fontSize: 16),
                                   decoration: const InputDecoration(
                                     border: InputBorder.none,
                                     isDense: true,
                                     contentPadding: EdgeInsets.zero,
                                   ),
                                   onChanged: (_) => _recalc(),
                                 ),
                               )
                             else
                               Text(
                                 value ?? "0",
                                 style: AppTextStyles.h3.copyWith(fontSize: 18),
                               ),
                             if (unit.isNotEmpty)
                               Text(
                                 unit, 
                                 style: TextStyle(
                                   fontSize: 12, 
                                   color: Colors.grey[500], 
                                   fontWeight: FontWeight.w500
                                 ),
                               ),
                           ],
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
          if (isEditable)
            Positioned(
              bottom: 12,
              right: 12,
              child: Icon(Icons.edit, size: 16, color: Colors.grey[400]),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return "${date.day} ${months[date.month - 1]}";
  }
}
