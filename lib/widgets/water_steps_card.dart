import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:physiq/theme/design_system.dart';

class WaterStepsCard extends StatefulWidget {
  final Map<String, dynamic> dailySummary;

  const WaterStepsCard({super.key, required this.dailySummary});

  @override
  State<WaterStepsCard> createState() => _WaterStepsCardState();
}

class _WaterStepsCardState extends State<WaterStepsCard> {
  bool _isHealthConnected = false;
  bool _isConnecting = false;
  late int _currentWaterMl;
  late int _goalWaterMl;
  late int _stepsGoal;

  @override
  void initState() {
    super.initState();
    // Initialize local state from widget props (converting oz to ml)
    final double waterOz = (widget.dailySummary['waterConsumed'] ?? 0).toDouble();
    // Default water goal changed to 4000ml (approx 135 oz) if not provided
    final double goalOz = (widget.dailySummary['waterGoal'] ?? 135.25).toDouble(); // 4000ml ~ 135.25oz
    
    _currentWaterMl = (waterOz * 29.5735).round();
    _goalWaterMl = (widget.dailySummary['waterGoal'] != null) 
        ? (goalOz * 29.5735).round() 
        : 4000; // Force default to 4000ml if null/default

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
        backgroundColor: Colors.white,
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

  @override
  Widget build(BuildContext context) {
    // Calculate display values
    final double waterPercent = (_goalWaterMl > 0) 
        ? (_currentWaterMl / _goalWaterMl).clamp(0.0, 1.0) 
        : 0.0;
    
    // Display Helper
    String displayVolume = _currentWaterMl >= 1000 
        ? '${(_currentWaterMl / 1000).toStringAsFixed(2)} L'
        : '$_currentWaterMl ml';
    
    String displayGoal = _goalWaterMl >= 1000 
        ? '${(_goalWaterMl / 1000).toStringAsFixed(1)} L'
        : '$_goalWaterMl ml';

    return Column(
      children: [
        // Top Card: Steps (Google Health Integrated)
        _buildStepCard(),

        const SizedBox(height: 16),

        // Bottom Card: Water (Redesigned)
        GestureDetector(
          onTap: () => _showWaterEntrySheet(),
          child: Container(
            height: 130, // Kept fixed height as requested
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
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
                // Water Icon & Label & Progress Ring
                CircularPercentIndicator(
                    radius: 42.0,
                    lineWidth: 8.0,
                    percent: waterPercent,
                    circularStrokeCap: CircularStrokeCap.round,
                    backgroundColor: const Color(0xFFF3F4F6),
                    progressColor: AppColors.water,
                    center: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.water.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.water_drop, color: AppColors.water, size: 20),
                    ),
                ),
                
                const SizedBox(width: 20),
                
                // Text Info
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
                
                // Add Button (Visual Cue)
                Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                        color: AppColors.water,
                        borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.add, color: Colors.white),
                )
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showWaterEntrySheet() async {
      // Expecting a map or simpler return. For now, we update local state if map returned.
      final result = await showModalBottomSheet<Map<String, int>>(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (context) => _WaterEntrySheet(currentMl: _currentWaterMl, goalMl: _goalWaterMl),
      );

      if (result != null) {
        setState(() {
          _currentWaterMl = result['current']!;
          _goalWaterMl = result['goal']!;
        });
      }
  }

  Widget _buildStepCard() {
    final int steps = (widget.dailySummary['steps'] ?? 0).toInt();
    
    // Logic Changed: Progress Bar fills as you walk (steps / goal)
    // Content displays Remaining Goal (Goal - Steps)
    final double stepsPercent = (_stepsGoal > 0) ? (steps / _stepsGoal).clamp(0.0, 1.0) : 0.0;
    
    // Decrease the number inside the ring as user walks
    final int remainingGoal = (_stepsGoal - steps).clamp(0, _stepsGoal);
    
    final int burnedFromSteps = (steps * 0.04).toInt();

    return Container(
      height: 220,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
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
            // Active State
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
                                  child: const Icon(Icons.edit, size: 16, color: AppColors.secondaryText),
                                )
                              ],
                            ),
                            const SizedBox(height: 2), // Small spacing
                            Text(
                              'GOAL', // Changed from 'steps' to 'GOAL'
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
                                color: const Color(0xFFFFF7ED), // Light orange bg
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

            // Disconnected Overlay
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

  const _WaterEntrySheet({required this.currentMl, required this.goalMl});

  @override
  State<_WaterEntrySheet> createState() => _WaterEntrySheetState();
}

class _WaterEntrySheetState extends State<_WaterEntrySheet> {
    int _selectedUnit = 250; // Default to Glass
    late int _currentTotal;
    late int _currentGoal;
    
    @override
    void initState() {
        super.initState();
        _currentTotal = widget.currentMl;
        _currentGoal = widget.goalMl;
    }

    void _selectUnit(int amount) {
        setState(() {
            _selectedUnit = amount;
            // No auto-add to _currentTotal here, as requested.
        });
    }

    void _increment(int sign) {
        setState(() {
            _currentTotal += (sign * _selectedUnit);
            if (_currentTotal < 0) _currentTotal = 0;
        });
    }

    void _adjustGoal(int sign) {
        setState(() {
            _currentGoal += (sign * _selectedUnit);
            if (_currentGoal < 0) _currentGoal = 0;
        });
    }

    @override
    Widget build(BuildContext context) {
        return Container(
            decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
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
                    Text("Add Water", style: AppTextStyles.heading2),
                    const SizedBox(height: 8),
                    Text("Stay hydrated!", style: AppTextStyles.body.copyWith(color: AppColors.secondaryText)),
                    const SizedBox(height: 32),
                    
                    // Presets
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                            _buildPresetOption("Glass", "250 ml", Icons.local_drink, 250),
                            _buildPresetOption("Mug", "500 ml", Icons.coffee, 500),
                            _buildPresetOption("Bottle", "1 L", Icons.local_cafe_outlined, 1000),
                        ],
                    ),
                    const SizedBox(height: 32),
                    
                    // Water Controls
                    Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                            _buildControlBtn(Icons.remove, () => _increment(-1)),
                            const SizedBox(width: 24),
                            SizedBox(
                                width: 140, // Fixed width for stability
                                child: Column(
                                    children: [
                                        Text(
                                          _currentTotal >= 1000 
                                            ? "${(_currentTotal / 1000).toStringAsFixed(2)} L" 
                                            : "$_currentTotal ml", 
                                          style: AppTextStyles.heading1.copyWith(fontSize: 40)
                                        ),
                                        Text("Today's Total", style: AppTextStyles.smallLabel),
                                    ]
                                ),
                            ),
                            const SizedBox(width: 24),
                            _buildControlBtn(Icons.add, () => _increment(1)),
                        ],
                    ),
                    
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 12),

                    // Goal Controls (Replaces Manual Entry)
                    Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                            IconButton(
                              onPressed: () => _adjustGoal(-1),
                              icon: const Icon(Icons.remove_circle_outline, color: AppColors.secondaryText),
                            ),
                            const SizedBox(width: 8),
                            Column(
                                children: [
                                    Text(
                                      _currentGoal >= 1000 
                                        ? "${(_currentGoal / 1000).toStringAsFixed(1)} L" 
                                        : "$_currentGoal ml",
                                      style: AppTextStyles.heading2
                                    ),
                                    Text("Daily Water Goal", style: AppTextStyles.smallLabel),
                                ]
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () => _adjustGoal(1),
                              icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                            ),
                        ],
                    ),

                    const SizedBox(height: 24),
                    
                    // Save Button (Moved up / Validated visibility)
                    SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                            onPressed: () => Navigator.pop(context, {'current': _currentTotal, 'goal': _currentGoal}),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.water,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: const Text("Save"),
                        ),
                    ),
                    const SizedBox(height: 16), // Extra padding for safety
                ],
            ),
        );
    }
    
    Widget _buildPresetOption(String label, String amountText, IconData icon, int amountVal) {
        final bool isSelected = _selectedUnit == amountVal;
                                
        return GestureDetector(
            onTap: () {
              // Now only sets the unit, does NOT auto-add.
              _selectUnit(amountVal);
            },
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
    
    Widget _buildControlBtn(IconData icon, VoidCallback onTap) {
        return GestureDetector(
            onTap: onTap,
            child: Container(
                width: 50, height: 50,
                decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [AppShadows.card],
                    border: Border.all(color: Colors.grey.shade100),
                ),
                child: Icon(icon, color: Colors.black),
            ),
        );
    }
}
