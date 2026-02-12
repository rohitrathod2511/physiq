
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:physiq/theme/design_system.dart';
import 'package:physiq/services/food_service.dart';
import 'package:physiq/models/food_model.dart';
import 'dart:async';
import 'package:physiq/screens/meal/meal_preview_screen.dart';
import 'package:physiq/screens/meal/meal_logging_flows.dart';
import 'package:physiq/screens/meal/my_meals_screen.dart';
import 'package:physiq/screens/food/my_foods_screen.dart';
import 'package:physiq/screens/food/saved_scans_screen.dart';

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

class _FoodDatabaseScreenState extends ConsumerState<FoodDatabaseScreen> with SingleTickerProviderStateMixin {
  late TextEditingController _searchController;
  late TabController _tabController;
  final FoodService _foodService = FoodService();
  
  List<Food> _searchResults = [];
  bool _isLoading = false;
  Timer? _debounce;
  
  // Tabs
  final List<String> _tabs = ["All", "My meals", "My foods", "Saved scans"];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery);
    _tabController = TabController(length: _tabs.length, vsync: this, initialIndex: widget.initialTabIndex);
    
    // Initial load
    if (widget.initialQuery?.isNotEmpty == true) {
        _onSearchChanged(widget.initialQuery!);
    } else {
        _loadCommonFoods();
    }
    
    // Listen to text changes for icon update
    _searchController.addListener(() {
        setState(() {}); // specific rebuild for icon inside build
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
        _loadCommonFoods();
        return;
    }

    setState(() => _isLoading = true);
    _debounce = Timer(const Duration(milliseconds: 500), () async {
        try {
            final results = await _foodService.searchFoods(query);
            if (mounted) {
                setState(() {
                    _searchResults = results;
                    _isLoading = false;
                });
            }
        } catch(e) {
            if (mounted) setState(() => _isLoading = false);
        }
    });
  }

  void _loadCommonFoods() async {
      setState(() => _isLoading = true);
      try {
          final foods = await _foodService.getCommonFoods();
          if (mounted) {
              setState(() {
                  _searchResults = foods;
                  _isLoading = false;
              });
          }
      } catch (e) {
          if (mounted) setState(() => _isLoading = false);
      }
  }

  void _onFoodTap(Food food) async {
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text("Log food", style: AppTextStyles.h2),
        centerTitle: true,
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.primaryText),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Tab Bar
          TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: AppColors.primaryText,
            unselectedLabelColor: Colors.grey,
            labelStyle: AppTextStyles.h3.copyWith(fontSize: 16),
            unselectedLabelStyle: AppTextStyles.body.copyWith(color: Colors.grey),
            indicatorColor: AppColors.primary,
            indicatorSize: TabBarIndicatorSize.label,
            dividerColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            tabs: _tabs.map((t) => Tab(text: t)).toList(),
          ),
          
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Food Search
                Column(
                  children: [
                    const SizedBox(height: 16),
                    // Search Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                          decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.black.withOpacity(0.1)),
                          ),
                          child: TextField(
                              controller: _searchController,
                              style: AppTextStyles.body,
                              onChanged: _onSearchChanged,
                              decoration: InputDecoration(
                                  hintText: "Describe what you ate",
                                  hintStyle: AppTextStyles.body.copyWith(color: Colors.grey),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.all(16),
                                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                                  suffixIcon: _searchController.text.isEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.mic, color: Colors.black),
                                          onPressed: () async {
                                              final text = await showVoiceSearchDialog(context);
                                              if (text != null && text.isNotEmpty) {
                                                  _searchController.text = text;
                                                  _onSearchChanged(text);
                                              }
                                          },
                                      )
                                      : IconButton(
                                          icon: const Icon(Icons.clear, color: Colors.grey),
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
                    
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text("Suggestions", style: AppTextStyles.h2),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // List
                    Expanded(
                      child: _isLoading 
                          ? const Center(child: CircularProgressIndicator())
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              itemCount: _searchResults.length,
                              itemBuilder: (context, index) {
                                  final food = _searchResults[index];
                                  return Padding(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: InkWell(
                                          onTap: () => _onFoodTap(food),
                                          borderRadius: BorderRadius.circular(16),
                                          child: Container(
                                              padding: const EdgeInsets.all(16),
                                              decoration: BoxDecoration(
                                                  color: AppColors.card,
                                                  borderRadius: BorderRadius.circular(16),
                                                  boxShadow: [
                                                      BoxShadow(
                                                          color: Colors.black.withOpacity(0.02),
                                                          blurRadius: 10,
                                                          offset: const Offset(0, 2)
                                                      )
                                                  ]
                                              ),
                                              child: Row(
                                                  children: [
                                                      Expanded(
                                                          child: Column(
                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                              children: [
                                                                  Text(food.name, style: AppTextStyles.h3.copyWith(fontSize: 16)),
                                                                  const SizedBox(height: 4),
                                                                  Row(
                                                                    children: [
                                                                      const Icon(Icons.local_fire_department, size: 14, color: Colors.grey),
                                                                      const SizedBox(width: 4),
                                                                      Text(
                                                                          "${food.calories.toInt()} cal • ${food.unit}", 
                                                                          style: AppTextStyles.label
                                                                      ),
                                                                    ],
                                                                  ),
                                                              ],
                                                          ),
                                                      ),
                                                      Container(
                                                          padding: const EdgeInsets.all(8),
                                                          decoration: BoxDecoration(
                                                              color: AppColors.background, // Slight contrast
                                                              shape: BoxShape.circle,
                                                          ),
                                                          child: Icon(Icons.add, color: AppColors.primary),
                                                      )
                                                  ],
                                              ),
                                          ),
                                      ),
                                  );
                              },
                          ),
                    ),
                  ],
                ),

                // Tab 2: My Meals
                const MyMealsScreen(),


                // Tab 3: My Foods
                const MyFoodsScreen(),

                // Tab 4: Saved Scans
                const SavedScansScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
