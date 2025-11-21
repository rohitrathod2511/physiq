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
              // Editable Name (Moved to left, icon removed)
              GestureDetector(
                onTap: _showEditNameDialog,
                child: Text(
                  _userName,
                  style: AppTextStyles.heading1.copyWith(fontSize: 28), // Increased size slightly
                ),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                onPressed: () => showStreakCalendar(context),
                icon: const Icon(Icons.calendar_today_outlined, color: AppColors.secondaryText),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(100),
                  boxShadow: [AppShadows.card],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.local_fire_department, color: Colors.orange, size: 20),
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
