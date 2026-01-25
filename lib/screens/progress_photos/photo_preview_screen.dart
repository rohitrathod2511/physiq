import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:physiq/theme/design_system.dart';
import 'package:physiq/viewmodels/progress_viewmodel.dart';
import 'package:physiq/widgets/header_widget.dart';

class PhotoPreviewScreen extends ConsumerStatefulWidget {
  final XFile imageFile;
  final double currentWeight;

  const PhotoPreviewScreen({
    super.key,
    required this.imageFile,
    required this.currentWeight,
  });

  @override
  ConsumerState<PhotoPreviewScreen> createState() => _PhotoPreviewScreenState();
}

class _PhotoPreviewScreenState extends ConsumerState<PhotoPreviewScreen> {
  bool _isUploading = false;

  Future<void> _submitPhoto() async {
    setState(() => _isUploading = true);

    try {
      final file = File(widget.imageFile.path);
      await ref.read(progressViewModelProvider.notifier).addPhoto(file, widget.currentWeight);
      
      if (mounted) {
        Navigator.pop(context); // Close preview
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Progress photo uploaded!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: ${e.toString().replaceAll("Exception:", "")}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateStr = DateFormat('MMM d, yyyy').format(now);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
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

            // Metadata Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _infoBadge(widget.currentWeight.toStringAsFixed(1), 'kg'),
                  Container(width: 1, height: 24, color: AppColors.secondaryText.withOpacity(0.3)),
                  _infoBadge(dateStr, ''),
                ],
              ),
            ),

            // Image Preview
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.file(
                    File(widget.imageFile.path),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),

            // Submit Button
            Padding(
              padding: const EdgeInsets.only(left: 24.0, right: 24.0, bottom: 40.0, top: 16.0), // Increased bottom, moved up effectively
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isUploading ? null : _submitPhoto,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.card)),
                  ),
                  child: _isUploading
                      ? const SizedBox(
                          height: 24, 
                          width: 24, 
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                        )
                      : Text('Upload Photo', style: AppTextStyles.button.copyWith(fontSize: 16, color: Colors.white)),
                ),
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
