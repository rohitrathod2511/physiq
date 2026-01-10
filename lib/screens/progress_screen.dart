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
              toolbarHeight: 80,
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

  void _showSetWeightDialog(BuildContext context, ProgressViewModel viewModel, double currentWeight) {
    final controller = TextEditingController(text: currentWeight.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Weight'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(suffixText: 'kg'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final weight = double.tryParse(controller.text);
              if (weight != null) {
                viewModel.addWeight(weight, DateTime.now());
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showUploadPhotoDialog(BuildContext context, ProgressViewModel viewModel, double currentWeight) {
    // Mock upload for now
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upload Photo'),
        content: const Text('This would open the camera/gallery.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
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
            child: const Text('Mock Upload'),
          ),
        ],
      ),
    );
  }
}
