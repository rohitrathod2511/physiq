import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:physiq/theme/design_system.dart';
import 'package:physiq/viewmodels/progress_viewmodel.dart';
import 'package:physiq/widgets/header_widget.dart';
import 'package:physiq/widgets/progress/weight_goal_card.dart';
import 'package:physiq/widgets/progress/progress_ring_card.dart';
import 'package:physiq/widgets/progress/ecg_graph_card.dart';
import 'package:physiq/widgets/progress/progress_photo_card.dart';
import 'package:physiq/widgets/progress/bmi_card.dart';
import 'package:physiq/models/progress_photo_model.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(progressViewModelProvider);
    final viewModel = ref.read(progressViewModelProvider.notifier);

    if (state.isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            const SliverAppBar(
              pinned: true,
              floating: false,
              backgroundColor: AppColors.background,
              surfaceTintColor: Colors.transparent,
              scrolledUnderElevation: 0,
              elevation: 0,
              toolbarHeight: 70,
              titleSpacing: 0,
              title: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0),
                child: HeaderWidget(title: 'Progress', showActions: false),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Cards
                    Row(
                      children: [
                        Expanded(
                          child: WeightGoalCard(
                            currentWeight: state.currentWeight,
                            goalWeight: state.goalWeight,
                            onTap: () => _showSetWeightDialog(context, viewModel, state.currentWeight),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ProgressRingCard(percent: state.progressPercent),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Graph
                    EcgGraphCard(
                      history: state.weightHistory,
                      selectedRange: state.selectedRange,
                      onRangeChanged: (range) => viewModel.setRange(range),
                    ),
                    const SizedBox(height: 16),

                    // Photos
                    ProgressPhotoCard(
                      photos: state.photos,
                      onUploadTap: () => _showUploadPhotoDialog(context, viewModel, state.currentWeight),
                      onPhotoTap: (photo) {
                        // TODO: Open comparison viewer
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Comparison viewer coming soon!')));
                      },
                    ),
                    const SizedBox(height: 20),

                    // BMI
                    BmiCard(
                      bmi: state.bmi,
                      category: state.bmiCategory,
                    ),
                    const SizedBox(height: 100), // Bottom padding
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // _showWeightOptions removed as per requirement to only allow logging weight directly

  void _showSetWeightDialog(BuildContext context, ProgressViewModel viewModel, double currentWeight) {
    final controller = TextEditingController(text: currentWeight.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.card)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
        contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
        actionsPadding: const EdgeInsets.all(16),
        title: Text('Log Current Weight', style: AppTextStyles.heading2),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: AppTextStyles.bodyMedium,
          decoration: InputDecoration(
            suffixText: 'kg',
            suffixStyle: AppTextStyles.body,
            focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade300)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.secondaryText,
              textStyle: AppTextStyles.button,
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final weight = double.tryParse(controller.text);
              if (weight != null) {
                viewModel.addWeight(weight, DateTime.now());
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              textStyle: AppTextStyles.button,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // _showSetGoalDialog removed or unused, kept if you want to reuse it later but not accessible via UI now.
  // Actually, I'll remove it to be clean as per "Disable Update Goal Weight". 

  void _showUploadPhotoDialog(BuildContext context, ProgressViewModel viewModel, double currentWeight) {
    // Mock upload for now
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.card)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
        contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Text('Upload Photo', style: AppTextStyles.heading2),
        content: Text(
          'Choose a source to upload your progress photo.',
          style: AppTextStyles.body.copyWith(color: AppColors.secondaryText),
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.secondaryText,
                  textStyle: AppTextStyles.button,
                ),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                 onPressed: () {
                  // Mock adding a photo
                  viewModel.addPhoto(ProgressPhoto(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    imageUrl: '', // Empty for now
                    weightKg: currentWeight,
                    date: DateTime.now(),
                    uploadedAt: DateTime.now(),
                  ));
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  textStyle: AppTextStyles.button,
                ),
                child: const Text('Simulate Camera'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
