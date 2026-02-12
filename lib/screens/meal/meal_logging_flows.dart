
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:physiq/screens/meal/snap_meal_screen.dart';
import 'package:physiq/screens/meal/food_database_screen.dart';
import 'package:physiq/screens/meal/meal_preview_screen.dart'; 
import 'package:physiq/screens/meal/describe_meal_screen.dart';
import 'package:physiq/screens/meal/describe_meal_screen.dart';
import 'package:physiq/screens/meal/my_meals_screen.dart';
import 'package:physiq/models/food_model.dart';
import 'package:physiq/theme/design_system.dart';

// 1. SNAP MEAL FLOW (Camera)
void showSnapMealFlow(BuildContext context, WidgetRef ref) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => const SnapMealScreen()),
  );
}

// 2. FOOD DATABASE FLOW (Search)
void showFoodDatabaseFlow(BuildContext context, WidgetRef ref) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => const FoodDatabaseScreen()),
  );
}

// 3. SAVED FOODS FLOW (Direct to Database -> Saved Tab?)
void showSavedFoodsFlow(BuildContext context, WidgetRef ref) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => const FoodDatabaseScreen(initialTabIndex: 3)),
  );
}

// 4. MANUAL NUTRITION FLOW (Placeholder for Fix Results or Add Manually)
void showManualNutritionFlow(BuildContext context, WidgetRef ref) {
  // Placeholder implementation or navigation to a manual entry screen
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text("Manual entry coming soon")),
  );
}

// 5. MANUAL ENTRY FLOW (Describe Meal)
void showManualEntryFlow(BuildContext context, WidgetRef ref) {
     Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const DescribeMealScreen()),
      );
}

// 6. CUSTOM MEAL FLOW
void showCustomMealFlow(BuildContext context, WidgetRef ref) {
     Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MyMealsScreen()),
      );
}

// 7. SHOW LOADING
void showLoading(BuildContext context, String message) {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
            content: Row(
                children: [
                    const CircularProgressIndicator(),
                    const SizedBox(width: 16),
                    Text(message),
                ],
            ),
        ),
    );
}

void closeLoading(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
}

// 8. SHOW ERROR
void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
}

// 9. SHOW PREVIEW
void showMealPreview(BuildContext context, WidgetRef ref, Map<String, dynamic> data, {String source = 'unknown'}) {
    // 1. Extract Quantity
    double quantity = (data['quantity'] as num?)?.toDouble() ?? 1.0;
    
    // 2. Extract Nutrition from nested map if present (from AI output structure)
    // Sometimes AI returns flat {calories: 100} or nested {nutrition: {calories: 100}}
    // Let's assume flat for now based on AiNutritionService output format
    
    // Create Food object from AI data
    // Assuming data contains per-unit values if quantity is 1, or total values?
    // Usually AI returns total for the "quantity" described.
    // So if "2 slices bread", calories is for 2 slices.
    // Food model expects per-unit values.
    // So we divide by quantity.
    
    double cal = (data['calories'] as num?)?.toDouble() ?? 0;
    double protein = (data['protein_g'] as num?)?.toDouble() ?? 0;
    double fat = (data['fat_g'] as num?)?.toDouble() ?? 0;
    double carbs = (data['carbs_g'] as num?)?.toDouble() ?? 0;
    
    if (quantity > 0) {
        cal /= quantity;
        protein /= quantity;
        fat /= quantity;
        carbs /= quantity;
    }

    final food = Food(
        id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
        name: data['meal_name'] ?? 'Unknown Meal',
        category: 'AI Logged',
        unit: data['unit'] ?? 'serving',
        baseWeightG: 100, 
        calories: cal,
        protein: protein,
        carbs: carbs,
        fat: fat,
        source: source,
        isIndian: false,
    );

    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => MealPreviewScreen(
                initialFood: food,
                initialQuantity: quantity,
            )
        ),
    );
}

// 10. VOICE SEARCH HELPER
Future<String?> showVoiceSearchDialog(BuildContext context) {
  return showDialog<String>(
    context: context,
    builder: (context) => const VoiceListeningDialog(),
  );
}

class VoiceListeningDialog extends StatefulWidget {
  const VoiceListeningDialog({super.key});

  @override
  State<VoiceListeningDialog> createState() => _VoiceListeningDialogState();
}

class _VoiceListeningDialogState extends State<VoiceListeningDialog> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  String _text = "Listening...";
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  void _initSpeech() async {
    bool available = await _speech.initialize(
        onError: (val) => debugPrint('onError: $val'), 
        onStatus: (val) => debugPrint('onStatus: $val')
    );
    if (!available) {
      if (mounted) setState(() => _text = "Mic unavailable");
      return;
    }

    if (mounted) setState(() => _isListening = true);
    _speech.listen(onResult: (result) {
      if (mounted) {
          setState(() {
            _text = result.recognizedWords;
          });
      }

      if (result.finalResult && result.recognizedWords.isNotEmpty) {
        Future.delayed(const Duration(milliseconds: 500), () {
            _speech.stop();
            if (mounted) Navigator.pop(context, result.recognizedWords);
        });
      }
    });
  }
  
  @override
  void dispose() {
      _speech.stop();
      super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Speak now"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.mic, size: 48, color: _isListening ? Colors.red : Colors.grey),
          const SizedBox(height: 16),
          Text(_text, textAlign: TextAlign.center),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            _speech.stop();
            Navigator.pop(context, null);
          },
          child: const Text("Cancel"),
        ),
      ],
    );
  }
}
