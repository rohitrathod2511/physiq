import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:physiq/theme/design_system.dart';
import 'package:physiq/services/food_service.dart';
import 'package:physiq/services/ai_nutrition_service.dart';
import 'package:physiq/screens/meal/meal_logging_flows.dart';
import 'package:physiq/models/food_model.dart';
import 'dart:async';

class DescribeMealScreen extends ConsumerStatefulWidget {
  final String? initialQuery;
  final Map<String, dynamic>? fallbackAiData; // If valid AI data exists, use this as fallback
  final bool isPicking; // New: If true, returns the selected food/quantity instead of logging

  const DescribeMealScreen({
    super.key, 
    this.initialQuery,
    this.fallbackAiData,
    this.isPicking = false,
  });

  @override
  ConsumerState<DescribeMealScreen> createState() => _DescribeMealScreenState();
}

class _DescribeMealScreenState extends ConsumerState<DescribeMealScreen> {
  late TextEditingController _controller;
  final stt.SpeechToText _speech = stt.SpeechToText();
  final aiService = AiNutritionService();
  final foodService = FoodService();
  
  List<Food> _searchResults = [];
  bool _isListening = false;
  bool _speechAvailable = false;
  Timer? _debounce;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery ?? '');
    _initSpeech();
    
    // Auto-search if query provided
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _performSearch(widget.initialQuery!);
    } else {
        // Load common foods initially
        _loadCommonFoods();
    }
  }
  
  void _loadCommonFoods() async {
      setState(() => _isSearching = true);
      final foods = await foodService.getCommonFoods();
      if (mounted) {
          setState(() {
              _searchResults = foods;
              _isSearching = false;
          });
      }
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
      // If empty, maybe show common foods again?
      _loadCommonFoods();
      return;
    }

    setState(() => _isSearching = true);
    
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _performSearch(value);
    });
  }

  Future<void> _performSearch(String query) async {
      final results = await foodService.searchFoods(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
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

  // User clicked a DB food item -> Show Quantity Selector
  void _onFoodSelected(Food food) {
      showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: AppColors.background,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (ctx) => _FoodQuantitySelector(
              food: food,
              onConfirm: (quantity, description) {
                  Navigator.pop(ctx);
                  _logWithCalculatedValues(food, quantity, description);
              },
          ),
      );
  }

  void _logWithCalculatedValues(Food food, double quantity, String description) {
      if (widget.isPicking) {
          Navigator.pop(context, {
              'food': food,
              'quantity': quantity,
              'description': description
          });
          return;
      }

      final previewData = {
        'meal_name': description,
        'calories': (food.calories * quantity).round(),
        'protein_g': (food.protein * quantity).round(),
        'carbs_g': (food.carbs * quantity).round(),
        'fat_g': (food.fat * quantity).round(),
      };
      
      showMealPreview(context, ref, previewData, source: 'firestore');
  }

  Future<void> _submitAI() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    
    // If we have fallback data matching the current text (from SnapMeal), use it directly
    if (widget.fallbackAiData != null && 
        widget.initialQuery != null && 
        widget.initialQuery!.toLowerCase() == text.toLowerCase()) {
         showMealPreview(context, ref, widget.fallbackAiData!, source: 'ai_fallback');
         return;
    }

    // Explicit AI Feedback Confirmation
    final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
            title: const Text("Use AI Analysis?"),
            content: const Text("This searches online using AI. It may take a few seconds."),
            actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
                TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Proceed")),
            ],
        )
    );
    
    if (confirm != true) return;

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
          "Log Food", 
          style: AppTextStyles.h2.copyWith(fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search Bar Container
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
                    autofocus: widget.initialQuery == null,
                    style: AppTextStyles.body.copyWith(fontSize: 18),
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: "Search food (e.g. Roti, Egg)",
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
                  
                  // Voice & Search Actions
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                          GestureDetector(
                            onTap: _toggleListening,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(8),
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
                                size: 24,
                              ),
                            ),
                          ),
                          if (!widget.isPicking)
                            TextButton.icon(
                                onPressed: _submitAI,
                                icon: const Icon(Icons.auto_awesome, size: 16),
                                label: const Text("Ask AI to Analyze"),
                            )
                      ],
                  )
                ],
              ),
            ),
          ),
          
          // Content List
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    children: [
                      // 1. AI Fallback Card (if available)
                      if (widget.fallbackAiData != null) ...[
                        InkWell(
                          onTap: () => showMealPreview(context, ref, widget.fallbackAiData!, source: 'ai_fallback'),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.auto_awesome, color: AppColors.primary, size: 32),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "AI Suggestion: ${widget.fallbackAiData!['meal_name']}",
                                        style: AppTextStyles.h3.copyWith(color: AppColors.primary),
                                      ),
                                      Text(
                                        "${widget.fallbackAiData!['calories']} kcal (Estimated)",
                                        style: AppTextStyles.body.copyWith(fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text("Or select from Database:", style: AppTextStyles.label.copyWith(color: Colors.grey)),
                        const SizedBox(height: 12),
                      ],

                      // 2. Database Results
                      if (_searchResults.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 40),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.search_off, size: 48, color: Colors.grey.withOpacity(0.5)),
                                const SizedBox(height: 16),
                                Text(
                                  "No matching foods found.",
                                  style: AppTextStyles.body.copyWith(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ..._searchResults.map((food) {
                          final macros = "${food.calories.toInt()} kcal / ${food.unit}";
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: InkWell(
                              onTap: () => _onFoodSelected(food),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.card,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: AppColors.primary.withOpacity(0.1),
                                      child: Text(
                                        food.name.isNotEmpty ? food.name[0].toUpperCase() : "?", 
                                        style: TextStyle(color: AppColors.primary),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            food.name,
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
                                    Icon(Icons.add_circle, color: AppColors.primary),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

// QUANTITY SELECTOR BOTTOM SHEET
class _FoodQuantitySelector extends StatefulWidget {
    final Food food;
    final Function(double quantity, String description) onConfirm;

    const _FoodQuantitySelector({required this.food, required this.onConfirm});

    @override
    State<_FoodQuantitySelector> createState() => _FoodQuantitySelectorState();
}

class _FoodQuantitySelectorState extends State<_FoodQuantitySelector> {
    final TextEditingController _qtyController = TextEditingController(text: "1");

    @override
    void initState() {
        super.initState();
    }

    @override
    Widget build(BuildContext context) {
        return Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                left: 20, right: 20, top: 24
            ),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                    Text(widget.food.name, style: AppTextStyles.h2),
                    const SizedBox(height: 8),
                    Text("Enter Quantity (${widget.food.unit})", style: AppTextStyles.label),
                    const SizedBox(height: 16),
                    Row(
                        children: [
                            Expanded(
                                child: TextField(
                                    controller: _qtyController,
                                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                                    decoration: InputDecoration(
                                        labelText: "Quantity",
                                        hintText: "e.g. 1, 0.5",
                                        suffixText: "x ${widget.food.unit}",
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    autofocus: true,
                                ),
                            ),
                        ],
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                        onPressed: () {
                            final qty = double.tryParse(_qtyController.text) ?? 0;
                            if (qty <= 0) return;
                            
                            final desc = "$qty x ${widget.food.unit} ${widget.food.name}";
                            
                            widget.onConfirm(qty, desc);
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text("Add Food", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                ],
            ),
        );
    }
}
