import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:physiq/providers/onboarding_provider.dart';
import 'package:physiq/theme/design_system.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:physiq/viewmodels/home_viewmodel.dart';

class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  late TextEditingController _proteinController;
  late TextEditingController _fatController;
  late TextEditingController _carbsController;
  late TextEditingController _caloriesController;
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
       _caloriesController = TextEditingController(text: (plan?['goalCalories'] ?? 0).toString());
       _initialized = true;
    }
  }

  void _recalc() {
    setState(() {});
  }

  Future<void> _onSave() async {
    final store = ref.read(onboardingProvider);
    final initialPlan = store.data['currentPlan'] as Map<String, dynamic>? ?? {};
    
    // Parse current values
    final p = int.tryParse(_proteinController.text) ?? 0;
    final f = int.tryParse(_fatController.text) ?? 0;
    final c = int.tryParse(_carbsController.text) ?? 0;
    final cal = int.tryParse(_caloriesController.text) ?? 0;
    
    // Determine if edited
    final initialP = initialPlan['protein'] ?? initialPlan['proteinG'] ?? 0;
    final initialF = initialPlan['fat'] ?? initialPlan['fatG'] ?? 0;
    final initialC = initialPlan['carbs'] ?? initialPlan['carbsG'] ?? 0;
    final initialCal = initialPlan['calories'] ?? initialPlan['goalCalories'] ?? 0;
    
    // Check if values changed significantly (allowing for string/int parsing diffs)
    bool isEdited = (p != initialP) || (f != initialF) || (c != initialC) || (cal != initialCal);
    
    final String source = isEdited ? 'manual' : (initialPlan['source'] ?? 'calculated');
    
    final currentPlan = {
      'calories': cal,
      'protein': p,
      'carbs': c,
      'fat': f,
      'source': source,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    
    // Save to Firestore
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'currentPlan': currentPlan,
          // Ensure profile is also saved/merged if not already
          ...store.data,
        }, SetOptions(merge: true));
      } catch (e) {
        print("Error saving current plan: $e");
      }
    }

    // Update local state
    store.saveStepData('currentPlan', currentPlan);

    // Update HomeViewModel state immediately (Shared Frontend State)
    ref.read(homeViewModelProvider.notifier).updateCurrentPlan(currentPlan);
    
    if (mounted) {
      context.push('/onboarding/notification');
    }
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
    final currentWeightVal = store.data['weightKg'];
    final targetWeight = targetWeightVal != null ? targetWeightVal.toStringAsFixed(1) : '--';
    
    // Calculate difference
    double diff = 0;
    if (targetWeightVal != null && currentWeightVal != null) {
      diff = (currentWeightVal - targetWeightVal).abs();
    }
    final diffString = "${diff.toStringAsFixed(1)} kg";
    
    // Calculate date based on timeframeMonths (default to 6 if missing)
    final months = store.data['timeframeMonths'] ?? 6; 
    final targetDate = DateTime.now().add(Duration(days: months * 30));
    final dateString = _formatDate(targetDate);
    
    final isGain = (store.data['goal'] ?? '').toString().toLowerCase().contains('gain');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
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
  
                    // 2. Title
                    Text(
                      "Congratulations\nyour custom plan is ready!",
                      textAlign: TextAlign.center,
                      style: AppTextStyles.h2.copyWith(fontSize: 24, height: 1.2),
                    ),
                    const SizedBox(height: 16),
                    
                    // 3. Subtext (Goal)
                    Text(
                      "You should ${isGain ? 'Gain' : 'Lose'}:",
                      style: AppTextStyles.bodyBold.copyWith(fontSize: 16, color: Colors.black87),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "$diffString by $dateString",
                        style: AppTextStyles.bodyBold.copyWith(fontSize: 14),
                      ),
                    ),
                    
                    const SizedBox(height: 18),
  
                    // 4. Daily Recommendation Section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FE), // Light background for the section
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Daily Recommendation",
                            style: AppTextStyles.h3.copyWith(fontSize: 18),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "You can edit this any time",
                            style: AppTextStyles.h3.copyWith(color: AppColors.secondaryText, fontSize: 13),
                          ),
                          const SizedBox(height: 20),
                          
                          // Macro Grid
                          GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.95,
                            children: [
                               // Calories Card
                               _buildMacroCard(
                                 title: "Calories",
                                 icon: Icons.local_fire_department_rounded,
                                 color: Colors.black,
                                 controller: _caloriesController,
                                 unit: "",
                                 isEditable: true,
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
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Health Score Card (Separate)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.pink.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.favorite, color: Colors.pink, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text("Health score", style: AppTextStyles.bodyBold),
                                    Text("7/10", style: AppTextStyles.h3.copyWith(fontSize: 16)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: 0.7,
                                    backgroundColor: Colors.grey.shade100,
                                    color: Colors.green, // Visual match
                                    minHeight: 6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            
            // Fixed Bottom Button
            Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: AppColors.background,
              ),
              child: SizedBox(
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
            ),
          ],
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
          // 1. Top Left: Icon + Title
          Positioned(
            top: 16,
            left: 16,
            child: Row(
              children: [
                Icon(icon, size: 18, color: color.withOpacity(0.8)),
                const SizedBox(width: 8),
                Text(title, style: AppTextStyles.bodyBold.copyWith(fontSize: 14)),
              ],
            ),
          ),

          // 2. Center: Amount + Unit Inline
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                if (isEditable && controller != null)
                  IntrinsicWidth(
                    child: TextField(
                      controller: controller,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.h1.copyWith(fontSize: 32, height: 1.0),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        hintText: "0",
                      ),
                      onChanged: (_) => _recalc(),
                    ),
                  )
                else
                  Text(
                    value ?? "0",
                    style: AppTextStyles.h1.copyWith(fontSize: 32, height: 1.0),
                  ),
                
                if (unit.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  Text(
                    unit, 
                    style: TextStyle(
                      fontSize: 16, 
                      color: Colors.grey[400], 
                      fontWeight: FontWeight.bold
                    ),
                  ),
                ],
              ],
            ),
          ),

          // 3. Bottom Right: Edit Icon
          if (isEditable)
            Positioned(
              bottom: 12,
              right: 12,
              child: Icon(Icons.edit, size: 18, color: Colors.grey[400]),
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
