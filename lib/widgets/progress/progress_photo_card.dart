import 'package:flutter/material.dart';
import 'package:physiq/models/progress_photo_model.dart';
import 'package:physiq/theme/design_system.dart';
import 'package:intl/intl.dart';

class ProgressPhotoCard extends StatelessWidget {
  final List<ProgressPhoto> photos;
  final VoidCallback onUploadTap;
  final Function(ProgressPhoto) onPhotoTap;

  const ProgressPhotoCard({
    super.key,
    required this.photos,
    required this.onUploadTap,
    required this.onPhotoTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadii.card),
        boxShadow: [AppShadows.card],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Progress Photos', style: AppTextStyles.heading2),
              IconButton(
                onPressed: onUploadTap,
                icon: Icon(Icons.add_a_photo, color: AppColors.accent),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (photos.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text('Track your visual progress!', style: AppTextStyles.bodyMedium),
              ),
            )
          else
            SizedBox(
              height: 120,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: photos.length,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final photo = photos[index];
                  return GestureDetector(
                    onTap: () => onPhotoTap(photo),
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: AppColors.background,
                            image: photo.imageUrl.isNotEmpty
                                ? DecorationImage(image: NetworkImage(photo.imageUrl), fit: BoxFit.cover)
                                : null,
                          ),
                          child: photo.imageUrl.isEmpty
                              ? Icon(Icons.image, color: AppColors.secondaryText)
                              : null,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('MMM d').format(photo.date),
                          style: AppTextStyles.smallLabel,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
