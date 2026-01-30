import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:physiq/models/progress_photo_model.dart';
import 'package:physiq/theme/design_system.dart';
import 'package:physiq/viewmodels/progress_viewmodel.dart';
import 'package:physiq/screens/progress_photos/compare_photos_screen.dart';

class PhotoViewerScreen extends ConsumerStatefulWidget {
  final String initialPhotoId;
  final List<ProgressPhoto> allPhotos;

  const PhotoViewerScreen({
    super.key,
    required this.initialPhotoId,
    required this.allPhotos,
  });

  @override
  ConsumerState<PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends ConsumerState<PhotoViewerScreen> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.allPhotos.indexWhere((p) => p.id == widget.initialPhotoId);
    if (_currentIndex == -1) _currentIndex = 0;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _deletePhoto(ProgressPhoto photo) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Photo?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(progressViewModelProvider.notifier).deletePhoto(photo);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.allPhotos.isEmpty) return const SizedBox.shrink();

    final currentPhoto = widget.allPhotos[_currentIndex];
    final dateStr = DateFormat('MMM d, yyyy').format(currentPhoto.date);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header (same as photo_preview)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.close, color: AppColors.primaryText),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Metadata Card (same as photo_preview: weight | date)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _infoBadge(currentPhoto.weightKg.toStringAsFixed(1), 'kg'),
                  Container(width: 1, height: 24, color: AppColors.secondaryText.withOpacity(0.3)),
                  _infoBadge(dateStr, ''),
                ],
              ),
            ),

            // Image (same as photo_preview: Expanded, padding 16, ClipRRect 20)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: widget.allPhotos.length,
                    onPageChanged: (index) => setState(() => _currentIndex = index),
                    itemBuilder: (context, index) {
                      return InteractiveViewer(
                        child: Center(
                          child: Image.network(
                            widget.allPhotos[index].imageUrl,
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(color: AppColors.primary),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            // Dots when multiple photos
            if (widget.allPhotos.length > 1)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    widget.allPhotos.length > 10 ? 0 : widget.allPhotos.length,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentIndex == index
                            ? AppColors.primary
                            : Colors.grey.shade300,
                      ),
                    ),
                  ),
                ),
              ),

            // Compare + Delete (same position as Upload in preview)
            Padding(
              padding: const EdgeInsets.only(left: 24.0, right: 24.0, bottom: 40.0, top: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ComparePhotosScreen(
                                initialPhoto: widget.allPhotos[_currentIndex],
                                allPhotos: widget.allPhotos,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.card)),
                        ),
                        child: Text('Compare', style: AppTextStyles.button.copyWith(fontSize: 16, color: Colors.white)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: OutlinedButton(
                        onPressed: () => _deletePhoto(widget.allPhotos[_currentIndex]),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          foregroundColor: Colors.red,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.card)),
                        ),
                        child: const Icon(Icons.delete_outline, size: 24),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoBadge(String value, String unit) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(value, style: AppTextStyles.heading2),
            if (unit.isNotEmpty) ...[
              const SizedBox(width: 4),
              Text(unit, style: AppTextStyles.body.copyWith(color: AppColors.secondaryText)),
            ],
          ],
        ),
      ],
    );
  }
}
