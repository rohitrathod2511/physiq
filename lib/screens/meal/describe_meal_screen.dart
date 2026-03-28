import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:physiq/models/food_model.dart';
import 'package:physiq/models/meal_model.dart';
import 'package:physiq/screens/meal/meal_preview_screen.dart';
import 'package:physiq/services/food_service.dart';
import 'package:physiq/theme/design_system.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

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
  final FoodService _foodService = FoodService();

  List<Food> _searchResults = [];
  bool _isListening = false;
  bool _speechAvailable = false;
  bool _isSearching = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery ?? '');
    _initSpeech();

    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _performSearch(widget.initialQuery!);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _initSpeech() async {
    _speechAvailable = await _speech.initialize();
    if (mounted) {
      setState(() {});
    }
  }

  void _onTextChanged(String value) {
    _debounce?.cancel();

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
      final results = await _foodService.searchFoods(query);
      if (!mounted) return;
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (error) {
      debugPrint('DescribeMeal search error: $error');
      if (!mounted) return;

      setState(() => _isSearching = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Search failed. Please try again.'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _toggleListening() async {
    if (!_speechAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Speech recognition not available')),
      );
      return;
    }

    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
      return;
    }

    setState(() => _isListening = true);
    await _speech.listen(
      onResult: (result) {
        setState(() {
          _controller.text = result.recognizedWords;
          _controller.selection = TextSelection.fromPosition(
            TextPosition(offset: _controller.text.length),
          );
        });
        _onTextChanged(result.recognizedWords);
        if (result.finalResult && mounted) {
          setState(() => _isListening = false);
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
    );
  }

  Future<void> _onFoodSelected(Food selectedFood) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final detailedFood = selectedFood.isPartial
          ? await _foodService.getFoodById(selectedFood.id) ?? selectedFood
          : selectedFood;

      if (!mounted) return;
      Navigator.pop(context);

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (sheetContext) => _FoodQuantitySelector(
          food: detailedFood,
          onConfirm: (quantity, serving, description) {
            final previewFood = _mapToPreviewFood(detailedFood, serving);

            Navigator.pop(sheetContext);
            if (widget.isPicking) {
              Navigator.pop(context, {
                'food': previewFood,
                'quantity': quantity,
                'description': description,
              });
              return;
            }

            Navigator.of(context, rootNavigator: true).push(
              MaterialPageRoute(
                builder: (_) => MealPreviewScreen(
                  initialFood: previewFood,
                  initialQuantity: quantity,
                ),
              ),
            );
          },
        ),
      );
    } catch (error) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load food details: $error')),
        );
      }
    }
  }

  Food _mapToPreviewFood(Food food, ServingOption serving) {
    final baseWeight = food.baseWeightG > 0 ? food.baseWeightG : 100.0;
    final servingWeight = serving.grams > 0 ? serving.grams : baseWeight;
    final scale = servingWeight / baseWeight;

    return food.copyWith(
      unit: serving.label,
      baseWeightG: servingWeight,
      calories: food.calories * scale,
      protein: food.protein * scale,
      carbs: food.carbs * scale,
      fat: food.fat * scale,
      saturatedFat: food.saturatedFat == null ? null : food.saturatedFat! * scale,
      polyunsaturatedFat: food.polyunsaturatedFat == null
          ? null
          : food.polyunsaturatedFat! * scale,
      monounsaturatedFat: food.monounsaturatedFat == null
          ? null
          : food.monounsaturatedFat! * scale,
      cholesterol: food.cholesterol == null ? null : food.cholesterol! * scale,
      sodium: food.sodium == null ? null : food.sodium! * scale,
      fiber: food.fiber == null ? null : food.fiber! * scale,
      sugar: food.sugar == null ? null : food.sugar! * scale,
      calcium: food.calcium == null ? null : food.calcium! * scale,
      iron: food.iron == null ? null : food.iron! * scale,
      potassium: food.potassium == null ? null : food.potassium! * scale,
      vitaminA: food.vitaminA == null ? null : food.vitaminA! * scale,
      vitaminC: food.vitaminC == null ? null : food.vitaminC! * scale,
      source: food.source.isNotEmpty ? food.source : 'usda',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textPrimary = theme.textTheme.bodyLarge?.color ?? theme.colorScheme.onSurface;
    final textSecondary = theme.textTheme.bodyMedium?.color ??
        theme.colorScheme.onSurface.withValues(alpha: 0.72);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Log Food', style: AppTextStyles.h2.copyWith(fontSize: 20)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(AppRadii.bigCard),
                boxShadow: [
                  BoxShadow(
                    color: theme.shadowColor.withValues(alpha: 0.12),
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
                      hintText: 'Search food (e.g. Peanut Butter, Chicken)',
                      hintStyle: AppTextStyles.body.copyWith(color: textSecondary),
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
                            color: _isListening
                                ? theme.colorScheme.errorContainer
                                : Colors.transparent,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _isListening
                                  ? theme.colorScheme.error
                                  : theme.colorScheme.primary.withValues(alpha: 0.2),
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            _isListening ? Icons.mic : Icons.mic_none,
                            color: _isListening
                                ? theme.colorScheme.error
                                : theme.colorScheme.primary,
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
                                Icon(
                                  Icons.search,
                                  size: 48,
                                  color: textSecondary.withValues(alpha: 0.5),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Search for food to log',
                                  style: AppTextStyles.body.copyWith(color: textSecondary),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'e.g. Peanut Butter, Chicken, Rice',
                                  style: AppTextStyles.label.copyWith(color: textSecondary),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ..._searchResults.map((food) {
                          final detailText = food.calories > 0
                              ? '${food.calories.toInt()} cal • ${food.category}'
                              : food.category;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: InkWell(
                              onTap: () => _onFoodSelected(food),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: theme.cardColor,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: theme.dividerColor.withValues(alpha: 0.45),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor:
                                          theme.colorScheme.primary.withValues(alpha: 0.1),
                                      child: Text(
                                        food.name.isNotEmpty ? food.name[0].toUpperCase() : '?',
                                        style: TextStyle(color: theme.colorScheme.primary),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            food.name,
                                            style: AppTextStyles.body.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            detailText,
                                            style: AppTextStyles.label.copyWith(
                                              fontSize: 13,
                                              color: textSecondary,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.add_circle,
                                      color: theme.colorScheme.primary,
                                    ),
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
  final Food food;
  final void Function(double quantity, ServingOption serving, String description)
      onConfirm;

  const _FoodQuantitySelector({required this.food, required this.onConfirm});

  @override
  State<_FoodQuantitySelector> createState() => _FoodQuantitySelectorState();
}

class _FoodQuantitySelectorState extends State<_FoodQuantitySelector> {
  final TextEditingController _qtyController = TextEditingController(text: '1');
  late final List<ServingOption> _servings;
  late ServingOption _selectedServing;

  @override
  void initState() {
    super.initState();
    _servings = widget.food.servingOptions.isNotEmpty
        ? widget.food.servingOptions.where((serving) => serving.grams > 0).toList()
        : [
            ServingOption(
              label: widget.food.unit.isNotEmpty ? widget.food.unit : '100g',
              grams: widget.food.baseWeightG > 0 ? widget.food.baseWeightG : 100,
            ),
          ];
    _selectedServing = _servings.first;
  }

  @override
  void dispose() {
    _qtyController.dispose();
    super.dispose();
  }

  double _caloriesForServing(ServingOption serving) {
    final baseWeight = widget.food.baseWeightG > 0 ? widget.food.baseWeightG : 100.0;
    final servingWeight = serving.grams > 0 ? serving.grams : baseWeight;
    return widget.food.calories * (servingWeight / baseWeight);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textPrimary = theme.textTheme.bodyLarge?.color ?? theme.colorScheme.onSurface;
    final textSecondary = theme.textTheme.bodyMedium?.color ??
        theme.colorScheme.onSurface.withValues(alpha: 0.72);

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
          Text(
            widget.food.name,
            style: AppTextStyles.h2.copyWith(color: textPrimary),
          ),
          if (widget.food.category.isNotEmpty)
            Text(
              widget.food.category,
              style: AppTextStyles.label.copyWith(color: textSecondary),
            ),
          const SizedBox(height: 16),
          Text('Serving Size', style: AppTextStyles.label),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: theme.dividerColor),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<ServingOption>(
                value: _selectedServing,
                isExpanded: true,
                dropdownColor: theme.cardColor,
                items: _servings.map((serving) {
                  return DropdownMenuItem(
                    value: serving,
                    child: Text(
                      '${serving.label} (${_caloriesForServing(serving).round()} cal)',
                      style: AppTextStyles.body,
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedServing = value);
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _qtyController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Number of Servings',
              hintText: 'e.g. 1, 0.5',
              hintStyle: TextStyle(color: textSecondary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            autofocus: true,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              final quantity = double.tryParse(_qtyController.text) ?? 0;
              if (quantity <= 0) return;

              final description = '$quantity x ${_selectedServing.label} ${widget.food.name}';
              widget.onConfirm(quantity, _selectedServing, description);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Add Food',
              style: TextStyle(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
