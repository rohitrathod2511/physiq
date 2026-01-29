import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:physiq/theme/design_system.dart';
import 'package:physiq/services/ai_nutrition_service.dart';
import 'package:physiq/models/meal_model.dart';
import 'package:physiq/viewmodels/home_viewmodel.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:physiq/screens/meal/describe_meal_screen.dart';

final aiService = AiNutritionService();


// SNAP MEAL

Future<void> showSnapMealFlow(BuildContext context, WidgetRef ref) async {
  final picker = ImagePicker();
  final photo = await picker.pickImage(source: ImageSource.camera);
  if (photo == null || !context.mounted) return;

  // Capture navigator to ensure we can pop dialog even if context unmounts
  final navigator = Navigator.of(context, rootNavigator: true);
  showLoading(context, "Analyzing food...");

  try {
    final result = await aiService.estimateFromImage(photo.path);

    navigator.pop(); // Close loading

    if (!context.mounted) return;
    showMealPreview(
      context,
      ref,
      result,
      imagePath: photo.path,
      source: 'camera',
    );
  } catch (e) {
    debugPrint("Error analyzing meal: $e");
    navigator.pop(); // Close loading
    if (context.mounted) {
      // Show actual error to help debugging
      final msg = e.toString().replaceAll("Exception: ", "");
      showError(context, "Failed: $msg");
    }
  }
}


// MANUAL ENTRY (DESCRIBE MEAL)

void showManualEntryFlow(BuildContext context, WidgetRef ref) {
  // Navigate to the new full-screen UX
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => const DescribeMealScreen()),
  );
}

// VOICE ENTRY

void showVoiceEntryFlow(BuildContext context, WidgetRef ref) {
  showDialog(
    context: context,
    builder: (_) => _VoiceListeningDialog(
      parentContext: context,
      ref: ref,
    ),
  );
}

class _VoiceListeningDialog extends StatefulWidget {
  final BuildContext parentContext;
  final WidgetRef ref;

  const _VoiceListeningDialog({
    required this.parentContext,
    required this.ref,
  });

  @override
  State<_VoiceListeningDialog> createState() => _VoiceListeningDialogState();
}

class _VoiceListeningDialogState extends State<_VoiceListeningDialog> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  String _text = "Listening...";

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  void _initSpeech() async {
    final available = await _speech.initialize();
    if (!available) {
      setState(() => _text = "Mic unavailable");
      return;
    }

    _speech.listen(onResult: (result) async {
      setState(() => _text = result.recognizedWords);

      if (result.finalResult) {
        _speech.stop();
        Navigator.pop(context);

        if (!widget.parentContext.mounted) return;

        final navigator = Navigator.of(widget.parentContext, rootNavigator: true);
        showLoading(widget.parentContext, "Analyzing speech...");

        try {
          final data =
              await aiService.estimateFromText(result.recognizedWords);

          navigator.pop();

          if (!widget.parentContext.mounted) return;
          showMealPreview(
            widget.parentContext,
            widget.ref,
            data,
            source: 'voice',
          );
          } catch (e) {
            debugPrint("Voice error: $e");
            navigator.pop();
            if (widget.parentContext.mounted) {
               final msg = e.toString().replaceAll("Exception: ", "");
               showError(widget.parentContext, "Voice Failed: $msg");
            }
          }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Identify Meal"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.mic, size: 48),
          const SizedBox(height: 16),
          Text(_text),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            _speech.stop();
            Navigator.pop(context);
          },
          child: const Text("Cancel"),
        ),
      ],
    );
  }
}


// LOADING / ERROR / PREVIEW


void showLoading(BuildContext context, String message) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => Dialog(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 20),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    ),
  );
}

void closeLoading(BuildContext context) {
  Navigator.of(context, rootNavigator: true).pop();
}

void showError(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), backgroundColor: Colors.red),
  );
}

void showMealPreview(
  BuildContext context,
  WidgetRef ref,
  Map<String, dynamic> data, {
  String? imagePath,
  required String source,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text("Meal Preview", style: AppTextStyles.h2),
            const SizedBox(height: 16),
            if (imagePath != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(imagePath),
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 16),
            _macro("Calories", "${data['calories']} kcal"),
            _macro("Protein", "${data['protein_g']} g"),
            _macro("Carbs", "${data['carbs_g']} g"),
            _macro("Fat", "${data['fat_g']} g"),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                final user = FirebaseAuth.instance.currentUser;
                if (user == null) return;

                final meal = MealModel(
                  id: '',
                  userId: user.uid,
                  name: data['meal_name'] ?? 'Meal',
                  calories: (data['calories'] as num).toInt(),
                  proteinG: (data['protein_g'] as num).toInt(),
                  carbsG: (data['carbs_g'] as num).toInt(),
                  fatG: (data['fat_g'] as num).toInt(),
                  timestamp: DateTime.now(),
                  imageUrl: imagePath,
                  source: source,
                );

                ref.read(homeViewModelProvider.notifier).logMeal(meal);
                Navigator.pop(context);
              },
              child: const Text("Log Meal"),
            ),
          ],
        ),
      );
    },
  );
}

Widget _macro(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [Text(label), Text(value)],
    ),
  );
}

// MANUAL NUTRITION ENTRY (Exact Macros)

void showManualNutritionFlow(BuildContext context, WidgetRef ref) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
        left: 20,
        right: 20,
        top: 24,
      ),
      child: _ManualNutritionForm(ref: ref),
    ),
  );
}

class _ManualNutritionForm extends StatefulWidget {
  final WidgetRef ref;
  const _ManualNutritionForm({required this.ref});

  @override
  State<_ManualNutritionForm> createState() => _ManualNutritionFormState();
}

class _ManualNutritionFormState extends State<_ManualNutritionForm> {
  final _nameController = TextEditingController();
  final _calController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();

  void _submit() {
    final name = _nameController.text.trim();
    final cals = int.tryParse(_calController.text.trim());
    final protein = int.tryParse(_proteinController.text.trim());
    final carbs = int.tryParse(_carbsController.text.trim()) ?? 0;
    final fat = int.tryParse(_fatController.text.trim()) ?? 0;

    if (name.isEmpty) {
      showError(context, "Please enter a food name");
      return;
    }
    if (cals == null || cals < 0) {
      showError(context, "Please enter valid calories");
      return;
    }
    if (protein == null || protein < 0) {
      showError(context, "Please enter valid protein");
      return;
    }
    if (carbs < 0) {
      showError(context, "Please enter valid carbohydrates");
      return;
    }
    if (fat < 0) {
      showError(context, "Please enter valid fat");
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final meal = MealModel(
      id: '',
      userId: user.uid,
      name: name,
      calories: cals,
      proteinG: protein,
      carbsG: carbs,
      fatG: fat,
      timestamp: DateTime.now(),
      imageUrl: null,
      source: 'manual_nutrition',
    );

    widget.ref.read(homeViewModelProvider.notifier).logMeal(meal);
    Navigator.pop(context);
  } 

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text("Manual Nutrition", style: AppTextStyles.h2),
        const SizedBox(height: 20),
        
        // Food Name
        Text("Food Name", style: AppTextStyles.label),
        const SizedBox(height: 8),
        TextField(
          controller: _nameController,
          style: AppTextStyles.body,
          decoration: InputDecoration(
            hintText: "e.g. Protein Bar",
            filled: true,
            fillColor: AppColors.card,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
          textCapitalization: TextCapitalization.sentences,
        ),
        const SizedBox(height: 16),

        // Row for Calories & Protein
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Calories (kcal)", style: AppTextStyles.label),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _calController,
                    keyboardType: TextInputType.number,
                    style: AppTextStyles.body,
                    decoration: InputDecoration(
                      hintText: "0",
                      filled: true,
                      fillColor: AppColors.card,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Protein (g)", style: AppTextStyles.label),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _proteinController,
                    keyboardType: TextInputType.number,
                    style: AppTextStyles.body,
                    decoration: InputDecoration(
                      hintText: "0",
                      filled: true,
                      fillColor: AppColors.card,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),

        // Row for Carbs & Fat (Optional)
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Carbohydrates (g)", style: AppTextStyles.label),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _carbsController,
                    keyboardType: TextInputType.number,
                    style: AppTextStyles.body,
                    decoration: InputDecoration(
                      hintText: "0",
                      filled: true,
                      fillColor: AppColors.card,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Fat (g)", style: AppTextStyles.label),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _fatController,
                    keyboardType: TextInputType.number,
                    style: AppTextStyles.body,
                    decoration: InputDecoration(
                      hintText: "0",
                      filled: true,
                      fillColor: AppColors.card,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 24),
        
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: const Text("Log Meal", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
