import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:physiq/models/food_model.dart';
import 'package:physiq/screens/food/my_foods_screen.dart';
import 'package:physiq/screens/food/saved_scans_screen.dart';
import 'package:physiq/screens/meal/add_manual_screen.dart';
import 'package:physiq/screens/meal/meal_logging_flows.dart';
import 'package:physiq/screens/meal/meal_preview_screen.dart';
import 'package:physiq/screens/meal/my_meals_screen.dart';
import 'package:physiq/services/food_service.dart';
import 'package:physiq/theme/design_system.dart';

class FoodDatabaseScreen extends ConsumerStatefulWidget {
  final String? initialQuery;
  final bool isSelectionMode;
  final int initialTabIndex;

  const FoodDatabaseScreen({
    super.key,
    this.initialQuery,
    this.isSelectionMode = false,
    this.initialTabIndex = 0,
  });

  @override
  ConsumerState<FoodDatabaseScreen> createState() => _FoodDatabaseScreenState();
}

class _FoodDatabaseScreenState extends ConsumerState<FoodDatabaseScreen>
    with SingleTickerProviderStateMixin {
  late TextEditingController _searchController;
  late TabController _tabController;
  final FoodService _foodService = FoodService();

  List<Food> _searchResults = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  Timer? _debounce;

  final List<String> _tabs = ['All', 'My Meals', 'My Foods', 'Saved Food'];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery);
    _tabController = TabController(
      length: _tabs.length,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );

    if (widget.initialQuery?.isNotEmpty == true) {
      _onSearchChanged(widget.initialQuery!);
    } else {
      _searchResults = [];
      _isLoading = false;
    }

    _searchController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isLoading = false;
        _hasSearched = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      try {
        final results = await _foodService.searchFoods(query);
        if (!mounted) return;
        setState(() {
          _searchResults = results;
          _isLoading = false;
          _hasSearched = true;
        });
      } catch (error) {
        debugPrint('Search error: $error');
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _hasSearched = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Search failed. Please try again.'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  Future<void> _onFoodTap(Food food) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MealPreviewScreen(
          initialFood: food,
          isSelectionMode: widget.isSelectionMode,
        ),
      ),
    );

    if (result != null && widget.isSelectionMode && mounted) {
      Navigator.pop(context, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color textPrimary =
        theme.textTheme.bodyLarge?.color ?? theme.colorScheme.onSurface;
    final Color textSecondary =
        theme.textTheme.bodyMedium?.color ??
        theme.colorScheme.onSurface.withValues(alpha: 0.72);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Custom Tab Row with reduced margins
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 16, 8),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Row(
                  children: List.generate(_tabs.length, (index) {
                    return Expanded(
                      child: AnimatedBuilder(
                        animation: _tabController,
                        builder: (context, child) {
                          final isSelected = _tabController.index == index;
                          return GestureDetector(
                            onTap: () => _tabController.animateTo(index),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? (theme.brightness == Brightness.dark
                                          ? Colors.white.withValues(alpha: 0.14)
                                          : theme.cardColor)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(20),
                                border:
                                    isSelected &&
                                        theme.brightness == Brightness.dark
                                    ? Border.all(
                                        color: Colors.white.withValues(
                                          alpha: 0.24,
                                        ),
                                        width: 1,
                                      )
                                    : null,
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha:
                                                theme.brightness ==
                                                    Brightness.dark
                                                ? 0.3
                                                : 0.08,
                                          ),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : [],
                              ),
                              alignment: Alignment.center,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    _tabs[index],
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.w600,
                                      color: isSelected
                                          ? textPrimary
                                          : textSecondary,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                Column(
                  children: [
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: theme.dividerColor),
                        ),
                        child: TextField(
                          controller: _searchController,
                          style: AppTextStyles.body.copyWith(
                            color: textPrimary,
                          ),
                          onChanged: _onSearchChanged,
                          decoration: InputDecoration(
                            hintText: 'Describe what you ate',
                            hintStyle: AppTextStyles.body.copyWith(
                              color: textSecondary,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(16),
                            prefixIcon: Icon(
                              Icons.search,
                              color: textSecondary,
                            ),
                            suffixIcon: _searchController.text.isEmpty
                                ? IconButton(
                                    icon: Icon(Icons.mic, color: textPrimary),
                                    onPressed: () async {
                                      final text = await showVoiceSearchDialog(
                                        context,
                                      );
                                      if (text != null && text.isNotEmpty) {
                                        _searchController.text = text;
                                        _onSearchChanged(text);
                                      }
                                    },
                                  )
                                : IconButton(
                                    icon: Icon(
                                      Icons.clear,
                                      color: textSecondary,
                                    ),
                                    onPressed: () {
                                      _searchController.clear();
                                      _onSearchChanged('');
                                    },
                                  ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _searchResults.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _hasSearched
                                          ? Icons.search_off
                                          : Icons.search,
                                      size: 64,
                                      color: textSecondary.withValues(
                                        alpha: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      _hasSearched
                                          ? 'No results, add manually?'
                                          : 'Search for food',
                                      style: AppTextStyles.h3.copyWith(
                                        color: textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _hasSearched
                                          ? 'Try another term or use Add Manual below.'
                                          : 'e.g. Apple, Chicken Biryani, Rice',
                                      style: AppTextStyles.body.copyWith(
                                        color: textSecondary,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              itemCount: _searchResults.length,
                              itemBuilder: (context, index) {
                                final food = _searchResults[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    side: BorderSide(
                                      color: theme.dividerColor.withValues(
                                        alpha: 0.35,
                                      ),
                                    ),
                                  ),
                                  child: ListTile(
                                    onTap: () => _onFoodTap(food),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 6,
                                    ),
                                    leading: CircleAvatar(
                                      backgroundColor: theme
                                          .colorScheme
                                          .surfaceContainerHighest,
                                      child: Text(
                                        food.name.isNotEmpty
                                            ? food.name[0].toUpperCase()
                                            : '?',
                                        style: TextStyle(
                                          color: textPrimary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      food.name,
                                      style: AppTextStyles.h3.copyWith(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        '${food.calories.toInt()} cal - ${food.unit}',
                                        style: AppTextStyles.label.copyWith(
                                          color: textSecondary,
                                        ),
                                      ),
                                    ),
                                    trailing: Icon(
                                      Icons.add_circle_outline,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AddManualScreen(),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(color: theme.dividerColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Add Manual',
                            style: TextStyle(
                              color: textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const MyMealsScreen(),
                const MyFoodsScreen(),
                const SavedScansScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
