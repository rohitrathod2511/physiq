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

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _deletePhoto(widget.allPhotos[_currentIndex]),
          ),
          IconButton(
            icon: const Icon(Icons.compare_arrows),
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
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Column(
        children: [
          // Top Info (Weight / Date)
          // We put it in a SafeArea manually or use the AppBar title? 
          // Custom overlay looks nicer.
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: _buildTopInfo(widget.allPhotos[_currentIndex]),
            ),
          ),
          
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
                        return const Center(child: CircularProgressIndicator(color: Colors.white));
                      },
                    ),
                  ),
                );
              },
            ),
          ),

          // Bottom Thumbnails
          Container(
            height: 80,
            color: Colors.black.withOpacity(0.5),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              scrollDirection: Axis.horizontal,
              itemCount: widget.allPhotos.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final photo = widget.allPhotos[index];
                final isSelected = index == _currentIndex;
                return GestureDetector(
                  onTap: () {
                    _pageController.jumpToPage(index);
                  },
                  child: Container(
                    width: 60,
                    decoration: BoxDecoration(
                      border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: NetworkImage(photo.imageUrl),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Add some bottom padding for safe area
          SizedBox(height: MediaQuery.of(context).padding.bottom),
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
