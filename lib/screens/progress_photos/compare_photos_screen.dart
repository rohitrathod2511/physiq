import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:physiq/models/progress_photo_model.dart';
import 'package:physiq/theme/design_system.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class ComparePhotosScreen extends StatefulWidget {
  final ProgressPhoto initialPhoto; // The "After" photo (usually)
  final List<ProgressPhoto> allPhotos;

  const ComparePhotosScreen({
    super.key,
    required this.initialPhoto,
    required this.allPhotos,
  });

  @override
  State<ComparePhotosScreen> createState() => _ComparePhotosScreenState();
}

class _ComparePhotosScreenState extends State<ComparePhotosScreen> {
  late ProgressPhoto _beforePhoto;
  late ProgressPhoto _afterPhoto;
  final GlobalKey _globalKey = GlobalKey(); // For RepaintBoundary

  @override
  void initState() {
    super.initState();
    // Sort logic? Assuming allPhotos is sorted desc or asc.
    // If not, we should sort them by date.
    final sorted = List<ProgressPhoto>.from(widget.allPhotos)
      ..sort((a, b) => a.date.compareTo(b.date));
    
    // Default "Before" is the first photo (Day 1)
    if (sorted.isNotEmpty) {
      _beforePhoto = sorted.first;
    } else {
      _beforePhoto = widget.initialPhoto;
    }

    // Default "After" is the passed photo
    _afterPhoto = widget.initialPhoto;
  }

  Future<void> _shareComparison() async {
    try {
      RenderRepaintBoundary? boundary =
          _globalKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      if (boundary.debugNeedsPaint) {
        // Wait for paint? usually fine in callback.
        await Future.delayed(const Duration(milliseconds: 20));
      }

      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData != null) {
        final Uint8List pngBytes = byteData.buffer.asUint8List();
        
        final tempDir = await getTemporaryDirectory();
        final file = await File('${tempDir.path}/progress_comparison.png').create();
        await file.writeAsBytes(pngBytes);

        await Share.shareXFiles([XFile(file.path)], text: 'Check out my progress on Physiq!');
      }
    } catch (e) {
      print('Error sharing: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not share image')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.allPhotos.isEmpty) return const SizedBox.shrink();

    // Sort for the slider (Chronological)
    final sliderPhotos = List<ProgressPhoto>.from(widget.allPhotos)
      ..sort((a, b) => a.date.compareTo(b.date));

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Compare', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareComparison,
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Center(
                child: RepaintBoundary(
                  key: _globalKey,
                  child: Container(
                    color: Colors.black, // Background for the shared image
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(child: _buildPhotoColumn(_beforePhoto, "Before")),
                        const SizedBox(width: 8),
                        Expanded(child: _buildPhotoColumn(_afterPhoto, "After")),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Slider Area
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              'Select "After" photo:',
              style: AppTextStyles.body.copyWith(color: Colors.white70),
            ),
          ),
          SizedBox(
            height: 80,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: sliderPhotos.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final photo = sliderPhotos[index];
                final isSelected = photo.id == _afterPhoto.id;
                final isBefore = photo.id == _beforePhoto.id;
                
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _afterPhoto = photo;
                    });
                  },
                  child: Container(
                    width: 60,
                    decoration: BoxDecoration(
                      border: isSelected 
                          ? Border.all(color: AppColors.primary, width: 2) // Changed from AppColors.water (blue) to primary if visible or white
                          : (isBefore ? Border.all(color: Colors.grey, width: 2) : null), // Mark 'before' too?
                      borderRadius: BorderRadius.circular(8),
                      // If selected, maybe add specific color border
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.network(
                            photo.imageUrl, 
                            fit: BoxFit.cover,
                            height: 60, 
                            width: 60
                          ),
                        ),
                         if (isSelected)
                          Container(color: Colors.white.withOpacity(0.3)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildPhotoColumn(ProgressPhoto photo, String label) {
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: AppTextStyles.smallLabel.copyWith(color: Colors.grey, letterSpacing: 1.2),
        ),
        const SizedBox(height: 8),
        Container(
          constraints: const BoxConstraints(maxHeight: 300), // restrict height
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              photo.imageUrl,
              fit: BoxFit.contain, // Maintain aspect ratio
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${photo.weightKg} kg',
          style: AppTextStyles.heading3.copyWith(color: Colors.white),
        ),
        Text(
          DateFormat('MMM d, yy').format(photo.date), // Shorter date
          style: AppTextStyles.body.copyWith(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}
