import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:physiq/providers/onboarding_provider.dart';
import 'package:physiq/theme/design_system.dart';

class ObstaclesScreen extends ConsumerStatefulWidget {
  const ObstaclesScreen({super.key});

  @override
  ConsumerState<ObstaclesScreen> createState() => _ObstaclesScreenState();
}

class _ObstaclesScreenState extends ConsumerState<ObstaclesScreen> {
  static const List<_ObstacleOption> _options = [
    _ObstacleOption('Lack of consistency', Icons.sync_rounded),
    _ObstacleOption('Unhealthy eating habits', Icons.fastfood_rounded),
    _ObstacleOption('Lack of support', Icons.groups_rounded),
    _ObstacleOption('Busy schedule', Icons.schedule_rounded),
    _ObstacleOption(
      'Lack of meal inspiration',
      Icons.lightbulb_outline_rounded,
    ),
  ];

  List<String> selectedObstacles = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final savedObstacles = ref
          .read(onboardingProvider)
          .data['selectedObstacles'];
      if (savedObstacles is List) {
        setState(() {
          selectedObstacles = savedObstacles.whereType<String>().toList();
        });
      }
    });
  }

  void _toggleObstacle(String option) {
    setState(() {
      if (selectedObstacles.contains(option)) {
        selectedObstacles.remove(option);
      } else {
        selectedObstacles.add(option);
      }
    });
  }

  void _onContinue() {
    if (selectedObstacles.isEmpty) return;
    ref
        .read(onboardingProvider)
        .saveStepData(
          'selectedObstacles',
          List<String>.from(selectedObstacles),
        );
    context.push('/onboarding/target-weight');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: AppColors.primaryText),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "What's stopping you from reaching your goals?",
                style: AppTextStyles.h1,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: _options.map((option) {
                        final isSelected = selectedObstacles.contains(
                          option.label,
                        );

                        return GestureDetector(
                          onTap: () => _toggleObstacle(option.label),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 20),
                            padding: const EdgeInsets.symmetric(
                              vertical: 24,
                              horizontal: 24,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.card,
                              borderRadius: BorderRadius.circular(
                                AppRadii.card,
                              ),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.transparent
                                    : Colors.grey.shade300,
                                width: 1,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.05),
                                        blurRadius: 4,
                                      ),
                                    ],
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  option.icon,
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.primary,
                                  size: 28,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    option.label,
                                    textAlign: TextAlign.start,
                                    style:
                                        const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: 'Inter',
                                        ).copyWith(
                                          color: isSelected
                                              ? Colors.white
                                              : AppColors.primaryText,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 26),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: selectedObstacles.isNotEmpty ? _onContinue : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.secondaryText
                        .withOpacity(0.2),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text('Continue'),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _ObstacleOption {
  final String label;
  final IconData icon;

  const _ObstacleOption(this.label, this.icon);
}
