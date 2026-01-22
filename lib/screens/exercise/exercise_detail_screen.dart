import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:physiq/theme/design_system.dart';
import 'package:physiq/viewmodels/exercise_viewmodel.dart';
import 'package:physiq/models/exercise_log_model.dart';
import 'package:physiq/screens/exercise/add_burned_calories_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:physiq/services/user_repository.dart';

class ExerciseDetailScreen extends ConsumerStatefulWidget {
  final String exerciseId;
  final String name;
  final String category;

  const ExerciseDetailScreen({
    super.key,
    required this.exerciseId,
    required this.name,
    required this.category,
  });

  @override
  ConsumerState<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends ConsumerState<ExerciseDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  


  // Manual State
  final List<Map<String, String>> _sets = [];
  final _setsController = TextEditingController(text: '1');
  final _repsController = TextEditingController();
  final _weightController = TextEditingController();

  // Timer State
  Timer? _timer;
  int _timeLeft = 30;
  int _workDuration = 30; // Customizable work duration
  int _restDuration = 10; // Customizable rest
  int _targetRounds = 3; // Customizable rounds
  bool _isWork = true;
  int _rounds = 0;
  bool _isRunning = false;
  int _totalDurationSec = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: widget.category == 'home' ? 2 : 1, vsync: this);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tabController.dispose();
    _setsController.dispose();
    _repsController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _toggleTimer() {
    if (_isRunning) {
      _timer?.cancel();
    } else {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          if (_timeLeft > 0) {
            _timeLeft--;
            _totalDurationSec++;
          } else {
            // Switch mode
            _isWork = !_isWork;
            _timeLeft = _isWork ? _workDuration : _restDuration; // Customizable rest
            if (_isWork) _rounds++;
          }
        });
      });
    }
    setState(() => _isRunning = !_isRunning);
  }

  void _editSettings() {
    showDialog(
      context: context,
      builder: (context) {
        final workController = TextEditingController(text: _workDuration.toString());
        final restController = TextEditingController(text: _restDuration.toString());
        final roundsController = TextEditingController(text: _targetRounds.toString());

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppRadii.card),
              boxShadow: [AppShadows.card],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Timer Settings', style: AppTextStyles.heading2),
                const SizedBox(height: 24),
                
                Row(
                  children: [
                     Expanded(child: _buildInput('Work (s)', workController)),
                     const SizedBox(width: 12),
                     Expanded(child: _buildInput('Rest (s)', restController)),
                     const SizedBox(width: 12),
                     Expanded(child: _buildInput('Rounds', roundsController)),
                  ],
                ),

                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(foregroundColor: AppColors.secondaryText),
                        child: Text('Cancel', style: AppTextStyles.button.copyWith(color: AppColors.secondaryText)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final w = int.tryParse(workController.text);
                          final r = int.tryParse(restController.text);
                          final rnd = int.tryParse(roundsController.text);
                          
                          if (w != null && w > 0 && r != null && r >= 0 && rnd != null && rnd > 0) {
                            setState(() {
                              _workDuration = w;
                              _restDuration = r;
                              _targetRounds = rnd;
                              // Reset timer if changed
                              if (!_isRunning && _isWork) {
                                _timeLeft = _workDuration;
                              }
                            });
                          }
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        child: Text('Save', style: AppTextStyles.button.copyWith(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _addSet() {
    if (_repsController.text.isNotEmpty) {
      final int count = int.tryParse(_setsController.text) ?? 1;
      setState(() {
        for (int i = 0; i < count; i++) {
          _sets.add({
            'reps': _repsController.text,
            'weight': _weightController.text,
          });
        }
        // _repsController.clear(); // Keep reps/weight for easy multi-add
        // _weightController.clear();
      });
    }
  }

  void _incrementWeight() {
    double current = double.tryParse(_weightController.text) ?? 0;
    current += 2.5;
    _weightController.text = current.toString();
  }

  Future<void> _onSave() async {
    final viewModel = ref.read(exerciseViewModelProvider.notifier);
    
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    
    // Fetch user weight
    final user = await ref.read(userRepositoryProvider).streamUser(uid).first;
    final double weightKg = (user?.weightKg ?? 70.0).toDouble();

    int durationMin = 0;
    double calories = 0;

    if (_tabController.index == (widget.category == 'home' ? 1 : -1)) { // Logic for timer tab index
       // Re-evaluating index logic: 
       // If Home: Tab 0 = Manual, Tab 1 = Timer.
       // If Gym: Tab 0 = Manual. Timer tab not present.
       // So if category == 'home' && index == 1, it's timer.
      // Timer mode
      durationMin = (_totalDurationSec / 60).ceil();
      calories = await viewModel.estimateCalories(
        exerciseType: 'hiit', // Timer implies HIIT/Circuit
        intensity: 'high',
        durationMinutes: durationMin,
        weightKg: weightKg,
      );
    } else {
      // Manual Sets mode (Index 0)
      // Estimate duration: sets * (reps * 3s + 60s rest)
      // Simple heuristic: 2 mins per set
      durationMin = _sets.length * 2; 
      calories = await viewModel.estimateCalories(
        exerciseType: widget.exerciseId, // Specific ID
        intensity: 'medium',
        durationMinutes: durationMin,
        weightKg: weightKg,
      );
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddBurnedCaloriesScreen(
          initialCalories: calories,
          onLog: (finalCalories) {
            viewModel.logExercise(
              userId: uid,
              exerciseId: widget.exerciseId,
              name: widget.name,
              type: widget.category == 'home' ? ExerciseType.home : ExerciseType.gym,
              durationMinutes: durationMin,
              calories: finalCalories,
              intensity: 'medium',
              details: {
                'mode': _tabController.index == 1 ? 'timer' : 'sets',
                'rounds': _rounds,
                'sets': _sets,
              },
              isManualOverride: finalCalories != calories,
            );
            Navigator.popUntil(context, (route) => route.isFirst);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Workout logged!')));
          },
        ),
      ),
    );
  }

  Widget _buildInput(String label, TextEditingController controller, {VoidCallback? onSuffixTap}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.smallLabel),
        const SizedBox(height: 4),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyBold,
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0), // Centered vertically by default
              suffixIcon: onSuffixTap != null 
                  ? IconButton(
                      icon: const Icon(Icons.add, size: 16), 
                      onPressed: onSuffixTap,
                      color: AppColors.primary,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ) 
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.name, style: AppTextStyles.heading2),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: AppColors.primaryText),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.secondaryText,
          indicatorColor: AppColors.primary,
          tabs: [
            const Tab(text: 'Manual Sets'), // Swapped
            if (widget.category == 'home') const Tab(text: 'Timer'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Manual Sets Tab (Now First)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: _sets.length,
                    itemBuilder: (context, index) {
                      final set = _sets[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: ListTile(
                          title: Text('Set ${index + 1}', style: AppTextStyles.bodyBold),
                          subtitle: Text('${set['reps']} reps @ ${set['weight']} kg', style: AppTextStyles.body),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                            onPressed: () => setState(() => _sets.removeAt(index)),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(flex: 2, child: _buildInput('Sets', _setsController)),
                          const SizedBox(width: 12),
                          Expanded(flex: 3, child: _buildInput('Reps', _repsController)),
                          if (widget.category != 'home') ...[
                            const SizedBox(width: 12),
                            Expanded(flex: 3, child: _buildInput('Weight (kg)', _weightController, onSuffixTap: _incrementWeight)),
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _addSet,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: const BorderSide(color: AppColors.primary),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: Text('Add Set', style: AppTextStyles.button),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
            // Timer Tab (Now Second)
          if (widget.category == 'home')
            Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_isWork ? 'Start' : 'Rest', style: AppTextStyles.heading1.copyWith(color: _isWork ? Colors.green : Colors.orange)),
              const SizedBox(height: 20),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('$_timeLeft', style: AppTextStyles.largeNumber.copyWith(fontSize: 80)),
                  IconButton(
                    icon: const Icon(Icons.edit, color: AppColors.secondaryText),
                    onPressed: _editSettings,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Rounds Display with Target
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('Round $_rounds / $_targetRounds', style: AppTextStyles.bodyBold),
              ),

              const SizedBox(height: 40),

              // Enhanced Start Button (Replaces FAB)
              SizedBox(
                width: 200,
                child: ElevatedButton(
                  onPressed: _toggleTimer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 5,
                    shadowColor: AppColors.primary.withOpacity(0.4),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(_isRunning ? Icons.pause : Icons.play_arrow),
                      const SizedBox(width: 8),
                      Text(
                        _isRunning ? 'Pause' : 'Start', 
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 96), // Lifted up
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _onSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            child: Text('Finish & Save', style: AppTextStyles.button.copyWith(color: Colors.white)),
          ),
        ),
      ),
    );
  }
}
