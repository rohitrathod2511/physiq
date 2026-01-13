import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:physiq/theme/design_system.dart';
import 'package:physiq/viewmodels/home_viewmodel.dart';
import 'package:physiq/widgets/header_widget.dart';
import 'package:physiq/widgets/date_slider.dart';
import 'package:physiq/widgets/calorie_and_macros_page.dart';
import 'package:physiq/widgets/water_steps_card.dart';
import 'package:physiq/widgets/recent_meals_list.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final homeState = ref.watch(homeViewModelProvider);
    final homeViewModel = ref.read(homeViewModelProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Sticky Header
            SliverAppBar(
              pinned: true,
              floating: false,
              backgroundColor: AppColors.background,
              scrolledUnderElevation: 0, // Prevents color change on scroll
              elevation: 0,
              toolbarHeight: 80, // Adjusted height for header
              titleSpacing: 0,
              title: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0),
                child: HeaderWidget(title: 'Physiq'),
              ),
            ),
            
            // Scrollable Content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    // Reduced spacing between header and slider
                    const SizedBox(height: 4), 
                    DateSlider(onDateSelected: homeViewModel.selectDate),
                    const SizedBox(height: 12), // Reduced spacing
                    SizedBox(
                      height: 390, // Adjusted height for new compact design
                      child: homeState.dailySummary != null
                          ? PageView(
                              controller: _pageController,
                              onPageChanged: (index) {
                                setState(() {
                                  _currentPage = index;
                                });
                              },
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                  child: CalorieAndMacrosPage(dailySummary: homeState.dailySummary!),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                  child: WaterStepsCard(dailySummary: homeState.dailySummary!),
                                ),
                              ],
                            )
                          : const Center(child: CircularProgressIndicator()),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(2, (index) => _buildDot(index, context)),
                    ),
                    const SizedBox(height: 8),
                    // Recent Meals List
                    RecentMealsList(meals: homeState.recentMeals),
                    // Extra padding at bottom for scrolling
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDot(int index, BuildContext context) {
    bool isActive = _currentPage == index;
    return Container(
      height: 8,
      width: 8,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: isActive ? AppColors.accent : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(
          color: isActive ? AppColors.accent : AppColors.secondaryText.withOpacity(0.4),
          width: 1.5,
        ),
      ),
    );
  }
}
