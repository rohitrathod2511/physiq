import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:physiq/models/progress_photo_model.dart';
import 'package:physiq/theme/design_system.dart';
import 'package:physiq/viewmodels/progress_viewmodel.dart';
import 'package:physiq/widgets/header_widget.dart';
import 'package:physiq/screens/progress_photos/photo_viewer_screen.dart';

class ProgressPhotosGridScreen extends ConsumerWidget {
  const ProgressPhotosGridScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(progressViewModelProvider);
    final photos = state.photos;

    // Group photos by month: "January 2026"
    final Map<String, List<ProgressPhoto>> groupedPhotos = {};
    for (var photo in photos) {
      final key = DateFormat('MMMM yyyy').format(photo.date);
      if (!groupedPhotos.containsKey(key)) {
        groupedPhotos[key] = [];
      }
      groupedPhotos[key]!.add(photo);
    }

    final sortedKeys = groupedPhotos.keys.toList(); // Should be naturally sorted by date desc if photos are input desc?
    // Actually photos are usually sorted by date desc in VM. So map keys insertion order should generally follow.
    // If not, we might need manual sorting. VM loads orderBy date desc.

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const HeaderWidget(title: 'Progress Gallery', showActions: false),
        centerTitle: false,
        backgroundColor: AppColors.background,
        iconTheme: const IconThemeData(color: AppColors.primaryText),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: photos.isEmpty
          ? Center(
              child: Text(
                'No photos yet.\nStart by tracking your progress!',
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(color: AppColors.secondaryText),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sortedKeys.length,
              itemBuilder: (context, index) {
                final monthKey = sortedKeys[index];
                final monthPhotos = groupedPhotos[monthKey]!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: Text(monthKey, style: AppTextStyles.heading3),
                    ),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 1,
                      ),
                      itemCount: monthPhotos.length,
                      itemBuilder: (context, idx) {
                        final photo = monthPhotos[idx];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PhotoViewerScreen(
                                  initialPhotoId: photo.id,
                                  allPhotos: photos,
                                ),
                              ),
                            );
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.network(
                                  photo.imageUrl,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (ctx, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(color: Colors.grey[300]);
                                  },
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(color: Colors.grey[300], child: const Icon(Icons.error)),
                                ),
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                        colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                                      ),
                                    ),
                                    padding: const EdgeInsets.all(4),
                                    child: Text(
                                      '${photo.weightKg}kg',
                                      style: AppTextStyles.smallLabel.copyWith(color: Colors.white),
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              },
            ),
    );
  }
}
