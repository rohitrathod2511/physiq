import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:physiq/theme/design_system.dart';
import 'package:physiq/services/fatsecret_service.dart';
import 'package:physiq/screens/meal/meal_preview_screen.dart';
import 'package:physiq/models/food_model.dart';
import 'package:physiq/models/fatsecret_food_model.dart';
import 'package:physiq/models/fatsecret_serving_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';

/// Describe meal - FatSecret search with details.
class DescribeMealScreen extends ConsumerStatefulWidget {
  final String? initialQuery;
  final bool isPicking;

  const DescribeMealScreen({
    super.key,
    this.initialQuery,
    this.isPicking = false,
  });

  @override
  ConsumerState<DescribeMealScreen> createState() => _DescribeMealScreenState();
}

class _DescribeMealScreenState extends ConsumerState<DescribeMealScreen> {
  late TextEditingController _controller;
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FatSecretService _fatSecretService = FatSecretService(); // Use FatSecretService directly

  List<FatSecretFood> _searchResults = [];
  bool _isListening = false;
  bool _speechAvailable = false;
  Timer? _debounce;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery ?? '');
    _initSpeech();

    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _performSearch(widget.initialQuery!);
    } else {
      setState(() {
        _searchResults = [];
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
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _performSearch(value);
    });
  }

  Future<void> _performSearch(String query) async {
    try {
      final results = await _fatSecretService.searchFoods(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      print("❌ Search Error: $e");
      if (mounted) {
        setState(() => _isSearching = false);
        
        String msg = "Search failed: $e";
        if (e.toString().contains('unauthenticated')) {
           msg = "Auth Error: Please restart app to sign in.";
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _toggleListening() async {
    if (!_speechAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Speech recognition not available")),
      );
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

  void _onFoodSelected(FatSecretFood partialFood) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Fetch full details (servings)
      final detailedFood = await _fatSecretService.getFoodDetails(partialFood.id);
      
      if (!mounted) return;
      Navigator.pop(context); // Dismiss loading

      // Show quantity selector with details
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppColors.background,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) => _FoodQuantitySelector(
          food: detailedFood,
          onConfirm: (quantity, serving, description) {
            final appFood = _mapToAppFood(detailedFood, serving, quantity);
            
            Navigator.pop(ctx); // Close sheet
            if (widget.isPicking) {
              Navigator.pop(context, {'food': appFood, 'quantity': quantity, 'description': description});
              return;
            }
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MealPreviewScreen(
                  initialFood: appFood,
                  initialQuantity: quantity,
                ),
              ),
            );
          },
        ),
      );
    } catch (e) {
      if (mounted) Navigator.pop(context); // Dismiss loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load food details: $e')),
      );
    }
  }

  Food _mapToAppFood(FatSecretFood fsFood, FatSecretServing serving, double quantity) {
    // Calculate total macros for the base Food object if needed, 
    // but usually Food object represents 1 unit/serving.
    // Here we map 1 'serving' unit to the Food object.
    
    return Food(
      id: "fs_${fsFood.id}",
      name: fsFood.name,
      category: fsFood.type,
      unit: serving.description, // e.g. "1 cup" or "100g"
      baseWeightG: double.tryParse(serving.metricServingAmount) ?? 0,
      calories: serving.calories,
      protein: serving.protein,
      carbs: serving.carbs,
      fat: serving.fat,
      source: 'fatsecret',
      saturatedFat: serving.saturatedFat,
      polyunsaturatedFat: serving.polyunsaturatedFat,
      monounsaturatedFat: serving.monounsaturatedFat,
      cholesterol: serving.cholesterol,
      sodium: serving.sodium,
      fiber: serving.fiber,
      sugar: serving.sugar,
      potassium: serving.potassium,
      vitaminA: serving.vitaminA,
      vitaminC: serving.vitaminC,
      calcium: serving.calcium,
      iron: serving.iron,
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  TextField(
                    controller: _controller,
                    autofocus: widget.initialQuery == null,
                    style: AppTextStyles.body.copyWith(fontSize: 18),
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: "Search food (e.g. Peanut Butter, Chicken)",
                      hintStyle: AppTextStyles.body.copyWith(color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: _onTextChanged,
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
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
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            _isListening ? Icons.mic : Icons.mic_none,
                            color: _isListening ? Colors.redAccent : AppColors.primary,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    children: [
                      if (_searchResults.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 40),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.search, size: 48, color: Colors.grey.withOpacity(0.5)),
                                const SizedBox(height: 16),
                                Text(
                                  "Search for food to log",
                                  style: AppTextStyles.body.copyWith(color: Colors.grey),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "e.g. Peanut Butter, Chicken, Rice",
                                  style: AppTextStyles.label.copyWith(color: Colors.grey),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ..._searchResults.map((food) {
                          // Show calories if available, else standard text
                          final macros = food.calories != null 
                              ? "${food.calories!.toInt()} cal"
                              : food.description ?? "Tap for details";
                          
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
                                            food.brandName.isNotEmpty ? "${food.brandName} • $macros" : macros,
                                            style: AppTextStyles.label.copyWith(fontSize: 13, color: Colors.grey),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
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

class _FoodQuantitySelector extends StatefulWidget {
  final FatSecretFood food;
  final Function(double quantity, FatSecretServing serving, String description) onConfirm;

  const _FoodQuantitySelector({required this.food, required this.onConfirm});

  @override
  State<_FoodQuantitySelector> createState() => _FoodQuantitySelectorState();
}

class _FoodQuantitySelectorState extends State<_FoodQuantitySelector> {
  final TextEditingController _qtyController = TextEditingController(text: "1");
  late FatSecretServing _selectedServing;

  @override
  void initState() {
    super.initState();
    if (widget.food.servings.isNotEmpty) {
      // Pick default or first
      _selectedServing = widget.food.servings.first; 
      // Theoretically we could look for 'is_default' but raw search response usually handles ordering or we trust list order.
      // FatSecretFood logic might not preserve is_default explicitly unless mapped.
    } else {
        // Fallback dummy
        _selectedServing = FatSecretServing(
          id: '0', 
          description: 'serving', 
          calories: 0, 
          protein: 0, 
          carbs: 0, 
          fat: 0
        ); 
    }
  }

  @override
  void dispose() {
    _qtyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.food.servings.isEmpty) {
         return Padding(
             padding: const EdgeInsets.all(20),
             child: Text("No serving information available."),
         );
    }
    
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 20,
        right: 20,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.food.name, style: AppTextStyles.h2),
          if (widget.food.brandName.isNotEmpty)
             Text(widget.food.brandName, style: AppTextStyles.label.copyWith(color: Colors.grey)),
          const SizedBox(height: 16),
          
          // Serving Size Dropdown
          Text("Serving Size", style: AppTextStyles.label),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white.withOpacity(0.1)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<FatSecretServing>(
                value: _selectedServing,
                isExpanded: true,
                dropdownColor: AppColors.card,
                items: widget.food.servings.map((s) {
                  return DropdownMenuItem(
                    value: s,
                    child: Text(
                      "${s.description} (${s.calories.toInt()} cal)",
                      style: AppTextStyles.body,
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedServing = val);
                  }
                },
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          TextField(
            controller: _qtyController,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: "Number of Servings",
              hintText: "e.g. 1, 0.5",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            autofocus: true,
          ),
          const SizedBox(height: 24),
          
          ElevatedButton(
            onPressed: () {
              final qty = double.tryParse(_qtyController.text) ?? 0;
              if (qty <= 0) return;
              final desc = "$qty x ${_selectedServing.description} ${widget.food.name}";
              widget.onConfirm(qty, _selectedServing, desc);
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
