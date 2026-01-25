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
      if (mounted) Navigator.pop(context); // Pop viewer after delete
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.allPhotos.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentPhoto = widget.allPhotos[_currentIndex];

    return Scaffold(
      backgroundColor: isDark ? Colors.black : AppColors.background,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: isDark ? Colors.white : AppColors.primaryText),
        title: Column(
          children: [
            Text(
              DateFormat('MMM d, yyyy').format(currentPhoto.date),
              style: AppTextStyles.heading3.copyWith(
                color: isDark ? Colors.white : AppColors.primaryText,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${currentPhoto.weightKg} kg',
              style: AppTextStyles.heading3.copyWith( // Using same style base
                color: isDark ? Colors.white : AppColors.primaryText, // Same color as well for uniformity? User said "Same font style & size" 
                fontSize: 18,
              ),
            ),
          ],
        ),
        actions: const [], // Actions moved to bottom
      ),
      body: Column(
        children: [
          // Main Image
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.allPhotos.length,
              onPageChanged: (index) {
                setState(() => _currentIndex = index);
              },
              itemBuilder: (context, index) {
                return InteractiveViewer(
                  child: Center(
                    child: Image.network(
                      widget.allPhotos[index].imageUrl,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            color: isDark ? Colors.white : AppColors.primary
                          )
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Slider Indicator (Dots) - "Horizontal slider"
          if (widget.allPhotos.length > 1)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.allPhotos.length > 10 ? 0 : widget.allPhotos.length, // Hide if too many
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentIndex == index 
                          ? (isDark ? Colors.white : AppColors.primary)
                          : (isDark ? Colors.white24 : Colors.grey.shade300),
                    ),
                  )
                ),
              ),
            ),

          // Bottom Actions
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Row(
                children: [
                  // Compare Button
                  Expanded(
                    flex: 1, // Same flex as delete button
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
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      child: const Text('Compare', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Delete Button
                  Expanded(
                    flex: 1,
                    child: OutlinedButton(
                      onPressed: () => _deletePhoto(widget.allPhotos[_currentIndex]),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12), // Match Compare vertical padding
                        side: const BorderSide(color: Colors.red),
                        foregroundColor: Colors.red,
                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      child: const Icon(Icons.delete_outline),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopInfo(ProgressPhoto photo) {
    return Column(
      children: [
        Text(
          '${photo.weightKg} kg',
          style: AppTextStyles.heading2.copyWith(color: Colors.white),
        ),
        const SizedBox(height: 4),
        Text(
          DateFormat('MMMM d, yyyy').format(photo.date),
          style: AppTextStyles.body.copyWith(color: Colors.white70),
        ),
      ],
    );
  }
}
