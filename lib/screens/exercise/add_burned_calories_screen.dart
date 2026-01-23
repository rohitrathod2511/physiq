import 'package:flutter/material.dart';
import 'package:physiq/theme/design_system.dart';

class AddBurnedCaloriesScreen extends StatefulWidget {
  final double initialCalories;
  final ValueChanged<double> onLog;

  const AddBurnedCaloriesScreen({
    super.key,
    required this.initialCalories,
    required this.onLog,
  });

  @override
  State<AddBurnedCaloriesScreen> createState() => _AddBurnedCaloriesScreenState();
}

class _AddBurnedCaloriesScreenState extends State<AddBurnedCaloriesScreen> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialCalories.round().toString());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Summary', style: AppTextStyles.heading2),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: AppColors.primaryText),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Spacer(),
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 200,
                    height: 200,
                    child: CircularProgressIndicator(
                      value: 1.0,
                      strokeWidth: 16,
                      color: AppColors.primary,
                      backgroundColor: Colors.grey[200],
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Burned', style: AppTextStyles.bodyMedium),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 100,
                            child: TextField(
                              controller: _controller,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.largeNumber.copyWith(fontSize: 40),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                          Icon(Icons.edit, size: 20, color: AppColors.secondaryText),
                        ],
                      ),
                      Text('kcal', style: AppTextStyles.bodyMedium),
                    ],
                  ),
                ],
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final val = double.tryParse(_controller.text) ?? widget.initialCalories;
                  widget.onLog(val);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: Text('Log Workout', style: AppTextStyles.button.copyWith(color: Colors.white)),
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
 