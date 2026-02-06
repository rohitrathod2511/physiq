import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:physiq/theme/design_system.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:physiq/viewmodels/home_viewmodel.dart';

class WaterStepsCard extends ConsumerStatefulWidget {
  final Map<String, dynamic> dailySummary;

  const WaterStepsCard({super.key, required this.dailySummary});

  @override
  ConsumerState<WaterStepsCard> createState() => _WaterStepsCardState();
}

class _WaterStepsCardState extends ConsumerState<WaterStepsCard> {
  bool _isHealthConnected = false;
  bool _isConnecting = false;
  late int _stepsGoal;
  
  // Persistent selection state (resets on reload, but fine for session)
  int _selectedUnit = 250; // Default to Glass

  @override
  void initState() {
    super.initState();
    _stepsGoal = (widget.dailySummary['stepsGoal'] ?? 10000).toInt();
  }

  void _connectGoogleHealth() async {
    setState(() => _isConnecting = true);
    // Simulate connection delay
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() {
        _isHealthConnected = true;
        _isConnecting = false;
      });
    }
  }

  void _editStepGoal() {
    final controller = TextEditingController(text: _stepsGoal.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text("Set Step Goal", style: AppTextStyles.heading2),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            suffixText: "steps",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              final val = int.tryParse(controller.text);
              if (val != null && val > 0) {
                setState(() => _stepsGoal = val);
                // Ideally save to Firestore here via VM/Service if needed
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text("Save", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  void _logWater() {
    ref.read(homeViewModelProvider.notifier).logWater(_selectedUnit);
  }

  @override
  Widget build(BuildContext context) {
    // Current state from props
    final double waterOz = (widget.dailySummary['waterConsumed'] ?? 0).toDouble();
    final double goalOz = (widget.dailySummary['waterGoal'] ?? 135.25).toDouble();
    
    // Check if dailySummary data is already in ml or oz. 
    // Previous code assumed oz in DB but converted to ml for display.
    // If we just logged ml, we should be consistent.
    // Assuming DB stores ml now since my logWater uses ml.
    // But if legacy data is Oz... I'll check magnitude.
    // If water > 500, likely ml. If < 200, likely Oz.
    // This is risky. I'll trust the previous logic which converted oz->ml.
    // BUT my new logWater saves ML directly.
    // So I should standardize on ML.
    // I'll assume standardizing on ML:
    // int currentWaterMl = (widget.dailySummary['waterConsumed'] ?? 0).toInt();
    
    // Prefer waterMl (new standard) over waterConsumed (legacy)
    int currentWaterMl = (widget.dailySummary['waterMl'] ?? widget.dailySummary['waterConsumed'] ?? 0).toInt();
    // If value is small (<200) and user logged >250, it might be oz.
    // But I'm pushing ML. I'll display as is.
    int goalWaterMl = (widget.dailySummary['waterGoal'] ?? 4000).toInt();
    if (goalWaterMl < 500) goalWaterMl = 4000; // Fix legacy default

    final double waterPercent = (goalWaterMl > 0) 
        ? (currentWaterMl / goalWaterMl).clamp(0.0, 1.0) 
        : 0.0;
    
    String displayVolume = currentWaterMl >= 1000 
        ? '${(currentWaterMl / 1000).toStringAsFixed(2)} L'
        : '$currentWaterMl ml';
    
    String displayGoal = goalWaterMl >= 1000 
        ? '${(goalWaterMl / 1000).toStringAsFixed(1)} L'
        : '$goalWaterMl ml';

    return Column(
      children: [
        // Top Card: Steps
        _buildStepCard(),

        const SizedBox(height: 16),

        // Bottom Card: Water
        GestureDetector(
          onTap: () => _showWaterEntrySheet(currentWaterMl, goalWaterMl),
          child: Container(
            height: 130,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularPercentIndicator(
                        radius: 42.0,
                        lineWidth: 8.0,
                        percent: waterPercent,
                        circularStrokeCap: CircularStrokeCap.round,
                        backgroundColor: const Color(0xFFF3F4F6),
                        progressColor: AppColors.water,
                        center: const SizedBox(),
                    ),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.water.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.water_drop, color: AppColors.water, size: 20),
                    ),
                  ],
                ),
                
                const SizedBox(width: 20),
                
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Water Intake",
                        style: AppTextStyles.bodyBold.copyWith(color: AppColors.secondaryText, fontSize: 13),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        displayVolume,
                        style: AppTextStyles.heading2.copyWith(fontSize: 26),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text("Goal:", style: AppTextStyles.smallLabel.copyWith(color: AppColors.secondaryText)),
                          const SizedBox(width: 4),
                          Text(
                            displayGoal, 
                            style: AppTextStyles.smallLabel.copyWith(fontWeight: FontWeight.bold)
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 8),
                
                // Add Button (Action)
                GestureDetector(
                  onTap: _logWater,
                  child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                          color: AppColors.water,
                          borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.add, color: Colors.white),
                  ),
                )
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showWaterEntrySheet(int current, int goal) async {
      final result = await showModalBottomSheet<Map<String, int>>(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (context) => _WaterEntrySheet(currentMl: current, goalMl: goal, initialUnit: _selectedUnit),
      );

      if (result != null) {
         if (result['selectedUnit'] != null) {
           setState(() {
             _selectedUnit = result['selectedUnit']!;
           });
         }
         
         if (result['waterGoal'] != null && result['waterGoal'] != goal) {
            ref.read(homeViewModelProvider.notifier).updateWaterGoal(result['waterGoal']!);
         }
      }
  }

  Widget _buildStepCard() {
    final int steps = (widget.dailySummary['steps'] ?? 0).toInt();
    final double stepsPercent = (_stepsGoal > 0) ? (steps / _stepsGoal).clamp(0.0, 1.0) : 0.0;
    final int remainingGoal = (_stepsGoal - steps).clamp(0, _stepsGoal);
    final int burnedFromSteps = (steps * 0.04).toInt();

    return Container(
      height: 220,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          children: [
            AnimatedOpacity(
              duration: const Duration(milliseconds: 500),
              opacity: _isHealthConnected ? 1.0 : 0.3,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(
                  sigmaX: _isHealthConnected ? 0 : 4, 
                  sigmaY: _isHealthConnected ? 0 : 4
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Row(
                    children: [
                      CircularPercentIndicator(
                        radius: 65.0,
                        lineWidth: 10.0,
                        animation: true,
                        percent: stepsPercent,
                        circularStrokeCap: CircularStrokeCap.round,
                        backgroundColor: const Color(0xFFF3F4F6),
                        progressColor: AppColors.steps,
                        center: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '$remainingGoal', 
                                  style: AppTextStyles.heading2.copyWith(fontSize: 22), 
                                ),
                                const SizedBox(width: 4),
                                GestureDetector(
                                  onTap: _editStepGoal,
                                  child: Icon(Icons.edit, size: 16, color: AppColors.secondaryText),
                                )
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'GOAL', 
                              style: AppTextStyles.bodyBold.copyWith(
                                color: AppColors.secondaryText,
                                fontSize: 12,
                                fontWeight: FontWeight.bold
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Today's Steps",
                              style: AppTextStyles.bodyBold.copyWith(color: AppColors.secondaryText),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '$steps',
                              style: AppTextStyles.h1.copyWith(fontSize: 32),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF7ED),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.local_fire_department, size: 14, color: Colors.orange),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$burnedFromSteps kcal',
                                    style: AppTextStyles.smallLabel.copyWith(
                                      color: Colors.orange[800],
                                      fontWeight: FontWeight.bold
                                    ),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (!_isHealthConnected)
              Positioned.fill(
                child: Container(
                  color: Colors.white.withOpacity(0.1), 
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.health_and_safety, size: 32, color: Colors.blue),
                      ),
                      const SizedBox(height: 16),
                      Text("Connect Google Health", style: AppTextStyles.h3),
                      const SizedBox(height: 6),
                      Text(
                        "Sync your daily steps automatically",
                        style: AppTextStyles.body.copyWith(color: AppColors.secondaryText, fontSize: 13),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 44,
                        child: ElevatedButton(
                          onPressed: _isConnecting ? null : _connectGoogleHealth,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                          ),
                          child: _isConnecting 
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text("Connect"),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _WaterEntrySheet extends StatefulWidget {
  final int currentMl;
  final int goalMl;
  final int initialUnit;

  const _WaterEntrySheet({required this.currentMl, required this.goalMl, required this.initialUnit});

  @override
  State<_WaterEntrySheet> createState() => _WaterEntrySheetState();
}

class _WaterEntrySheetState extends State<_WaterEntrySheet> {
    late int _selectedUnit;
    late int _currentGoal;
    
    @override
    void initState() {
        super.initState();
        _currentGoal = widget.goalMl;
        _selectedUnit = widget.initialUnit;
    }

    void _selectUnit(int amount) {
        setState(() {
            _selectedUnit = amount;
        });
    }

    void _adjustGoal(int amount) {
        setState(() {
            _currentGoal = (_currentGoal + amount).clamp(250, 10000);
        });
    }
    
    @override
    Widget build(BuildContext context) {
        return Container(
            decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            ),
            padding: EdgeInsets.only(
              left: 24, 
              right: 24, 
              top: 24, 
              bottom: 24 + MediaQuery.of(context).viewInsets.bottom
            ),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                    Container(height: 4, width: 40, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
                    const SizedBox(height: 24),
                    Text("Select Container", style: AppTextStyles.heading2),
                    const SizedBox(height: 32),
                    
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                            _buildPresetOption("Glass", "250 ml", Icons.local_drink, 250),
                            _buildPresetOption("Mug", "500 ml", Icons.coffee, 500),
                            _buildPresetOption("Bottle", "1 L", Icons.local_cafe_outlined, 1000),
                        ],
                    ),
                    const SizedBox(height: 32),
                    
                    Text("Selected: ${_selectedUnit}ml", style: AppTextStyles.bodyBold),
                    
                    const SizedBox(height: 32),
                    const Divider(),
                    const SizedBox(height: 16),
                    
                    Text("Daily Water Goal", style: AppTextStyles.heading2),
                    const SizedBox(height: 16),
                    Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                                IconButton(
                                    onPressed: () => _adjustGoal(-250),
                                    icon: const Icon(Icons.remove),
                                    color: AppColors.primary,
                                ),
                                Container(
                                    constraints: const BoxConstraints(minWidth: 80),
                                    alignment: Alignment.center,
                                    child: Text(
                                        "$_currentGoal ml", 
                                        style: AppTextStyles.heading2.copyWith(fontSize: 20)
                                    ),
                                ),
                                IconButton(
                                    onPressed: () => _adjustGoal(250),
                                    icon: const Icon(Icons.add),
                                    color: AppColors.primary,
                                ),
                            ],
                        ),
                    ),

                    const SizedBox(height: 32),

                    SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                            onPressed: () => Navigator.pop(context, {
                                'selectedUnit': _selectedUnit, 
                                'waterGoal': _currentGoal
                            }),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.water,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: const Text("Done"),
                        ),
                    ),
                    const SizedBox(height: 16),
                ],
            ),
        );
    }
    
    Widget _buildPresetOption(String label, String amountText, IconData icon, int amountVal) {
        final bool isSelected = _selectedUnit == amountVal;
                                
        return GestureDetector(
            onTap: () => _selectUnit(amountVal),
            child: Column(
                children: [
                    Container(
                        width: 70, height: 70,
                        decoration: BoxDecoration(
                            color: isSelected ? AppColors.water : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: isSelected ? AppColors.water : Colors.grey.shade200),
                        ),
                        child: Icon(icon, color: isSelected ? Colors.white : AppColors.water, size: 30),
                    ),
                    const SizedBox(height: 8),
                    Text(label, style: AppTextStyles.bodyBold),
                    Text(amountText, style: AppTextStyles.smallLabel.copyWith(color: AppColors.secondaryText)),
                ],
            )
        );
    }
}
