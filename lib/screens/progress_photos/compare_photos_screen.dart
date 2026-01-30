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
  bool _selectingBefore = false; // false = selecting After (default)
  final GlobalKey _globalKey = GlobalKey(); // For RepaintBoundary

  @override
  void initState() {
    super.initState();
    final sorted = List<ProgressPhoto>.from(widget.allPhotos)
      ..sort((a, b) => a.date.compareTo(b.date));

    if (sorted.isEmpty) {
      _beforePhoto = widget.initialPhoto;
      _afterPhoto = widget.initialPhoto;
      return;
    }

    _beforePhoto = sorted.first;
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

        await Share.shareXFiles([XFile(file.path)], text: 'Check out my progress on Physiq AI!');
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

    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Sort for the slider (Chronological)
    final sliderPhotos = List<ProgressPhoto>.from(widget.allPhotos)
      ..sort((a, b) => a.date.compareTo(b.date));

    return Scaffold(
      backgroundColor: isDark ? Colors.black : AppColors.background,
      appBar: AppBar(
        title: Text('Compare', style: TextStyle(color: isDark ? Colors.white : AppColors.primaryText)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : AppColors.primaryText),
        actions: [], // Removed from top
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _shareComparison,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.ios_share, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat, // "Top right side at the bottom" -> Bottom Right
      body: Column(
        children: [
          Expanded(
            child: RepaintBoundary(
              key: _globalKey,
              child: Container(
                color: isDark ? Colors.black : AppColors.background,
                padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: _buildPhotoColumn(_beforePhoto, "Before", isDark, context)),
                    const SizedBox(width: 4),
                    Expanded(child: _buildPhotoColumn(_afterPhoto, "After", isDark, context)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Select: ',
                  style: AppTextStyles.body.copyWith(
                    color: isDark ? Colors.white70 : AppColors.secondaryText,
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _selectingBefore = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: _selectingBefore
                          ? AppColors.primary.withOpacity(0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _selectingBefore ? AppColors.primary : (isDark ? Colors.grey : AppColors.secondaryText.withOpacity(0.5)),
                        width: _selectingBefore ? 2 : 1,
                      ),
                    ),
                    child: Text(
                      'Before',
                      style: AppTextStyles.bodyBold.copyWith(
                        color: _selectingBefore ? AppColors.primary : (isDark ? Colors.white70 : AppColors.secondaryText),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => setState(() => _selectingBefore = false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: !_selectingBefore
                          ? AppColors.primary.withOpacity(0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: !_selectingBefore ? AppColors.primary : (isDark ? Colors.grey : AppColors.secondaryText.withOpacity(0.5)),
                        width: !_selectingBefore ? 2 : 1,
                      ),
                    ),
                    child: Text(
                      'After',
                      style: AppTextStyles.bodyBold.copyWith(
                        color: !_selectingBefore ? AppColors.primary : (isDark ? Colors.white70 : AppColors.secondaryText),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 90,
            margin: const EdgeInsets.only(bottom: 24, top: 12),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: sliderPhotos.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final photo = sliderPhotos[index];
                final isAfter = photo.id == _afterPhoto.id;
                final isBefore = photo.id == _beforePhoto.id;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (_selectingBefore) {
                        _beforePhoto = photo;
                      } else {
                        _afterPhoto = photo;
                      }
                    });
                  },
                  child: Container(
                    width: 60,
                    decoration: BoxDecoration(
                      border: isAfter
                          ? Border.all(color: AppColors.primary, width: 2)
                          : isBefore
                              ? Border.all(color: isDark ? Colors.grey : AppColors.secondaryText, width: 2)
                              : null,
                      borderRadius: BorderRadius.circular(8),
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
                            width: 60,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(color: Colors.grey.shade300);
                            },
                          ),
                        ),
                        if (isAfter) Container(color: Colors.white.withOpacity(0.3)),
                        if (isBefore && !isAfter)
                          Container(
                            color: (isDark ? Colors.grey : AppColors.secondaryText).withOpacity(0.2),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoColumn(ProgressPhoto photo, String label, bool isDark, BuildContext context) {
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: AppTextStyles.bodyBold.copyWith(
            color: isDark ? Colors.grey : AppColors.secondaryText,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          DateFormat('MMM d, yyyy').format(photo.date),
          style: AppTextStyles.bodyBold.copyWith(
            color: isDark ? Colors.white : AppColors.primaryText,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${photo.weightKg} kg',
          style: AppTextStyles.bodyBold.copyWith(
            color: isDark ? Colors.white : AppColors.primaryText,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              color: Colors.black12,
              child: Image.network(
                photo.imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
