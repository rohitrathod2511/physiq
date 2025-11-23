import 'package:flutter/material.dart';
import 'package:physiq/utils/design_system.dart';
import 'package:physiq/widgets/streak_calendar_popup.dart';

class HeaderWidget extends StatefulWidget {
  const HeaderWidget({super.key});

  @override
  State<HeaderWidget> createState() => _HeaderWidgetState();
}

class _HeaderWidgetState extends State<HeaderWidget> {
  String _userName = 'Guest'; // Default name

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // App Logo / Name
              GestureDetector(
                onTap: _showEditNameDialog,
                child: Row(
                  children: [
                    const Icon(Icons.apple, size: 32, color: AppColors.primaryText), // Placeholder logo
                    const SizedBox(width: 8),
                    Text(
                      'Cal AI', // Hardcoded to match image, but could be _userName
                      style: AppTextStyles.heading1.copyWith(fontSize: 26),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Row(
            children: [
              // Streak Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(100),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.local_fire_department_rounded, color: Colors.orange, size: 20),
                    const SizedBox(width: 6),
                    Text('0', style: AppTextStyles.button.copyWith(fontSize: 16)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showEditNameDialog() {
    final TextEditingController controller = TextEditingController(text: _userName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.bigCard)),
        title: Text('Edit Name', style: AppTextStyles.heading2),
        content: TextField(
          controller: controller,
          style: AppTextStyles.heading2.copyWith(fontSize: 18),
          decoration: InputDecoration(
            hintText: "Enter your name",
            hintStyle: AppTextStyles.label,
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.secondaryText.withOpacity(0.5))),
            focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.accent)),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: AppTextStyles.button.copyWith(color: AppColors.secondaryText)),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _userName = controller.text.trim().isNotEmpty ? controller.text.trim() : _userName;
              });
              // TODO: Save to database
              Navigator.pop(context);
            },
            child: Text('Save', style: AppTextStyles.button.copyWith(color: AppColors.accent)),
          ),
        ],
      ),
    );
  }
}
