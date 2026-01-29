import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:physiq/theme/design_system.dart';
import 'package:physiq/services/food_service.dart';
import 'package:physiq/services/ai_nutrition_service.dart';
import 'package:physiq/screens/meal/meal_logging_flows.dart';
import 'dart:async';

class DescribeMealScreen extends ConsumerStatefulWidget {
  const DescribeMealScreen({super.key});

  @override
  ConsumerState<DescribeMealScreen> createState() => _DescribeMealScreenState();
}

class _DescribeMealScreenState extends ConsumerState<DescribeMealScreen> {
  final TextEditingController _controller = TextEditingController();
  final stt.SpeechToText _speech = stt.SpeechToText();
  final aiService = AiNutritionService();
  final foodService = FoodService();
  
  List<Map<String, dynamic>> _searchResults = [];
  bool _isListening = false;
  bool _speechAvailable = false;
  Timer? _debounce;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }
  
  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }
  
  void _initSpeech() async {
    _speechAvailable = await _speech.initialize();
    if (mounted) setState(() {});
  }

  void _onTextChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    if (value.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      final results = await foodService.searchFoods(value);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    });
  }

  void _toggleListening() async {
    if (!_speechAvailable) {
      showError(context, "Speech recognition not available");
      return;
    }

    if (_isListening) {
      _speech.stop();
      setState(() => _isListening = false);
    } else {
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (result) {
          setState(() {
            _controller.text = result.recognizedWords;
            _controller.selection = TextSelection.fromPosition(TextPosition(offset: _controller.text.length));
          });
          _onTextChanged(result.recognizedWords);
          
          if (result.finalResult) {
            setState(() => _isListening = false);
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
      );
    }
  }

  // Submission Flow
  Future<void> _onFoodSelected(Map<String, dynamic> food) async {
      // Use existing flow functionality
      final previewData = {
        'meal_name': food['name'],
        'calories': food['calories'],
        'protein_g': food['protein'],
        'carbs_g': food['carbs'],
        'fat_g': food['fat'],
      };
      
      showMealPreview(context, ref, previewData, source: 'firestore');
  }

  Future<void> _submitAI() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    showLoading(context, "Estimating nutrition...");

    try {
      final result = await aiService.estimateFromText(text);
      
      if (!mounted) return;
      closeLoading(context);

      showMealPreview(context, ref, result, source: 'ai_fallback');
      
    } catch (e) {
      debugPrint("Describe meal error: $e");
      if (mounted) {
        closeLoading(context);
        final msg = e.toString().replaceAll("Exception: ", "");
        showError(context, "Error: $msg");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasText = _controller.text.trim().isNotEmpty;
    // Bottom padding for Analyze button
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom + 24;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.primaryText),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Describe Meal", 
          style: AppTextStyles.h2.copyWith(fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(AppRadii.bigCard),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Input Field
                      TextField(
                        controller: _controller,
                        autofocus: true,
                        style: AppTextStyles.body.copyWith(fontSize: 18),
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          hintText: "Describe your meal (e.g. 2 slices medium cheese pizza)",
                          hintStyle: AppTextStyles.body.copyWith(color: Colors.grey),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: _onTextChanged,
                        onSubmitted: (_) { 
                          if (hasText) _submitAI(); 
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      const Divider(height: 1),
                      const SizedBox(height: 16),
                      
                      // Voice Button
                      GestureDetector(
                        onTap: _toggleListening,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _isListening ? Colors.redAccent.withOpacity(0.1) : Colors.transparent,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _isListening ? Colors.redAccent : AppColors.primary.withOpacity(0.2), 
                              width: 2
                            ),
                          ),
                          child: Icon(
                            _isListening ? Icons.mic : Icons.mic_none,
                            color: _isListening ? Colors.redAccent : AppColors.primary,
                            size: 28,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Suggestions List
              if (_isSearching)
                 const Padding(
                   padding: EdgeInsets.all(24.0),
                   child: CircularProgressIndicator(),
                 )
              else if (_searchResults.isNotEmpty)
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100), // Bottom padding for button
                    itemCount: _searchResults.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = _searchResults[index];
                      // Simple macros string
                      final macros = "${item['calories']} kcal • P: ${item['protein']}g • C: ${item['carbs']}g • F: ${item['fat']}g";
                      
                      return InkWell(
                        onTap: () => _onFoodSelected(item),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withOpacity(0.05)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['name'],
                                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                macros,
                                style: AppTextStyles.label.copyWith(fontSize: 13, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                )
            ],
          ),

          // Analyze Button (Fixed at bottom)
          if (hasText)
            Positioned(
              left: 16,
              right: 16,
              bottom: bottomPadding > 24 ? 24 : 24, // Keep it visible above keyboard if desired, or let it float
              // Actually, existing design implies floating buttons usually. 
              // We'll place it at bottom of screen. If keyboard is up, it might cover it or we need resizeToAvoidBottomInset.
              // Given "keyboard opens immediately", scaffold usually resizes.
              child: SafeArea(
                child: ElevatedButton(
                  onPressed: _submitAI,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  child: const Text(
                    "Analyze", 
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
