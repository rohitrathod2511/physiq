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

final aiService = AiNutritionService();

// ------------------------------------------------
// SNAP MEAL
// ------------------------------------------------
Future<void> showSnapMealFlow(BuildContext context, WidgetRef ref) async {
  final picker = ImagePicker();
  final photo = await picker.pickImage(source: ImageSource.camera);
  if (photo == null || !context.mounted) return;

  // Capture navigator to ensure we can pop dialog even if context unmounts
  final navigator = Navigator.of(context, rootNavigator: true);
  _showLoading(context, "Analyzing food...");

  try {
    final result = await aiService.estimateFromImage(photo.path);

    navigator.pop(); // Close loading

    if (!context.mounted) return;
    _showMealPreview(
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
      _showError(context, "Failed to analyze meal");
    }
  }
}

// ------------------------------------------------
// MANUAL ENTRY
// ------------------------------------------------
void showManualEntryFlow(BuildContext context, WidgetRef ref) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.background,
    builder: (sheetContext) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("What did you eat?", style: AppTextStyles.h2),
            const SizedBox(height: 12),
            TextField(
              autofocus: true,
              decoration: InputDecoration(
                hintText: "e.g. 2 eggs and toast",
                filled: true,
                fillColor: AppColors.card,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onSubmitted: (value) async {
                Navigator.pop(sheetContext);
                if (value.trim().isEmpty || !context.mounted) return;

                final navigator = Navigator.of(context, rootNavigator: true);
                _showLoading(context, "Estimating nutrition...");

                try {
                  final result = await aiService.estimateFromText(value);

                  navigator.pop();

                  if (!context.mounted) return;
                  _showMealPreview(context, ref, result, source: 'manual');
                } catch (e) {
                  debugPrint("Manual entry error: $e");
                  navigator.pop();
                  if (context.mounted) {
                    _showError(context, "Failed to estimate meal");
                  }
                }
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      );
    },
  );
}

// ------------------------------------------------
// VOICE ENTRY
// ------------------------------------------------
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
        _showLoading(widget.parentContext, "Analyzing speech...");

        try {
          final data =
              await aiService.estimateFromText(result.recognizedWords);

          navigator.pop();

          if (!widget.parentContext.mounted) return;
          _showMealPreview(
            widget.parentContext,
            widget.ref,
            data,
            source: 'voice',
          );
        } catch (e) {
          debugPrint("Voice error: $e");
          navigator.pop();
          if (widget.parentContext.mounted) {
            _showError(widget.parentContext, "Voice analysis failed");
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

// ------------------------------------------------
// LOADING / ERROR / PREVIEW
// ------------------------------------------------

void _showLoading(BuildContext context, String message) {
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

void _closeLoading(BuildContext context) {
  Navigator.of(context, rootNavigator: true).pop();
}

void _showError(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), backgroundColor: Colors.red),
  );
}

void _showMealPreview(
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
