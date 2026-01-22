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
import 'package:image_picker/image_picker.dart';
import 'package:physiq/screens/progress_photos/photo_preview_screen.dart';
import 'package:physiq/screens/progress_photos/progress_photos_grid_screen.dart';
import 'package:physiq/screens/progress_photos/photo_viewer_screen.dart';


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
                    GestureDetector(
                      onTap: () {
                         Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ProgressPhotosGridScreen()),
                        );
                      },
                      child: ProgressPhotoCard(
                        photos: state.photos,
                        onUploadTap: () => _onCameraTap(context, state.currentWeight),
                        onPhotoTap: (photo) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PhotoViewerScreen(
                                initialPhotoId: photo.id,
                                allPhotos: state.photos,
                              ),
                            ),
                          );
                        },
                      ),
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

  Future<void> _onCameraTap(BuildContext context, double currentWeight) async {
    // Show modal to choose Camera or Gallery (Simulating the "button in camera" requirement by giving choice upfront)
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.card)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.primary),
              title: const Text('Take Photo', style: TextStyle(color: AppColors.primaryText)),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndShowPreview(context, ImageSource.camera, currentWeight);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.primary),
              title: const Text('Choose from Gallery', style: TextStyle(color: AppColors.primaryText)),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndShowPreview(context, ImageSource.gallery, currentWeight);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndShowPreview(BuildContext context, ImageSource source, double currentWeight) async {
    try {
      final ImagePicker picker = ImagePicker();
      // Compress here using imageQuality to target roughly < 300KB (heuristic)
      // 1080p roughly, 70% quality usually yields < 300KB for JPEGs
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1080,
        maxHeight: 1920,
        imageQuality: 70, 
      );

      if (image != null && context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PhotoPreviewScreen(
              imageFile: image,
              currentWeight: currentWeight,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

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
}
