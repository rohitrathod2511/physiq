import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:physiq/models/food_model.dart';

class AddManualScreen extends ConsumerStatefulWidget {
  const AddManualScreen({super.key});

  @override
  ConsumerState<AddManualScreen> createState() => _AddManualScreenState();
}

class _AddManualScreenState extends ConsumerState<AddManualScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _caloriesController = TextEditingController(
    text: "",
  );
  final TextEditingController _proteinController = TextEditingController(
    text: "",
  );
  final TextEditingController _carbsController = TextEditingController(
    text: "",
  );
  final TextEditingController _fatsController = TextEditingController(text: "");

  int _quantity = 1;

  // Base values per 1 unit
  double _baseCalories = 0;
  double _baseProtein = 0;
  double _baseCarbs = 0;
  double _baseFat = 0;

  @override
  void dispose() {
    _nameController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatsController.dispose();
    super.dispose();
  }

  void _updateQuantity(int change) {
    int newQuantity = _quantity + change;
    if (newQuantity < 1) return;

    setState(() {
      _quantity = newQuantity;
      // Update displays based on base values * new quantity
      // If base is 0, keep empty to allow placeholder to show or show 0 if intended
      if (_baseCalories > 0 || _caloriesController.text.isNotEmpty) {
        _caloriesController.text = _formatValue(_baseCalories * _quantity);
      }
      if (_baseProtein > 0 || _proteinController.text.isNotEmpty) {
        _proteinController.text = _formatValue(_baseProtein * _quantity);
      }
      if (_baseCarbs > 0 || _carbsController.text.isNotEmpty) {
        _carbsController.text = _formatValue(_baseCarbs * _quantity);
      }
      if (_baseFat > 0 || _fatsController.text.isNotEmpty) {
        _fatsController.text = _formatValue(_baseFat * _quantity);
      }
    });
  }

  String _formatValue(double value) {
    // Remove trailing .0
    if (value % 1 == 0) return value.toInt().toString();
    return value.toStringAsFixed(1);
  }

  void _onMacroChanged(String value, String type) {
    double val = double.tryParse(value) ?? 0;
    // Update base value
    double baseVal = val / _quantity;

    setState(() {
      if (type == 'cal') _baseCalories = baseVal;
      if (type == 'prot') _baseProtein = baseVal;
      if (type == 'carb') _baseCarbs = baseVal;
      if (type == 'fat') _baseFat = baseVal;
    });
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
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Selected food",
          style: TextStyle(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.bookmark_border, color: textPrimary),
            onPressed: () {
              // Placeholder for bookmark action
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  // Name and Quantity Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Name Input
                      Expanded(
                        child: TextField(
                          controller: _nameController,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText: "Tap to name",
                            border: InputBorder.none,
                            hintStyle: TextStyle(
                              color: textSecondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Quantity Selector
                      Container(
                        height: 44,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: theme.dividerColor,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove, size: 20),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => _updateQuantity(-1),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              "$_quantity",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            IconButton(
                              icon: const Icon(Icons.add, size: 20),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => _updateQuantity(1),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // Calories Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: theme.dividerColor),
                      boxShadow: [
                        BoxShadow(
                          color: theme.shadowColor.withValues(alpha: 0.12),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Icon
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            Icons.local_fire_department,
                            color: theme.colorScheme.onSurfaceVariant,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Text Fields
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Calories",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              TextField(
                                controller: _caloriesController,
                                keyboardType: TextInputType.number,
                                onChanged: (val) => _onMacroChanged(val, 'cal'),
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: textPrimary,
                                ),
                                decoration: InputDecoration(
                                  hintText: "0",
                                  hintStyle: TextStyle(color: textSecondary),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Macros Row
                  Row(
                    children: [
                      Expanded(
                        child: _buildMacroCard(
                          label: "Protein",
                          icon: Icons.fitness_center, // Or a generic food icon
                          iconColor: theme.colorScheme.error,
                          controller: _proteinController,
                          type: 'prot',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMacroCard(
                          label: "Carbs",
                          icon: Icons.grass, // Closest to wheat/grain
                          iconColor: theme.colorScheme.secondary,
                          controller: _carbsController,
                          type: 'carb',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMacroCard(
                          label: "Fats",
                          icon: Icons.water_drop,
                          iconColor: theme.colorScheme.primary,
                          controller: _fatsController,
                          type: 'fat',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Bottom Log Button
          Container(
            padding: const EdgeInsets.only(
              left: 20,
              right: 20,
              bottom: 34,
              top: 16,
            ),
            decoration: BoxDecoration(color: theme.scaffoldBackgroundColor),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _logMeal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  foregroundColor: textPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  "Log",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroCard({
    required String label,
    required IconData icon,
    required Color iconColor,
    required TextEditingController controller,
    required String type,
  }) {
    final ThemeData theme = Theme.of(context);
    final Color textSecondary =
        theme.textTheme.bodyMedium?.color ??
        theme.colorScheme.onSurface.withValues(alpha: 0.72);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  onChanged: (val) => _onMacroChanged(val, type),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                  decoration: InputDecoration(
                    hintText: "0",
                    hintStyle: TextStyle(color: textSecondary),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              Text(
                "g",
                style: TextStyle(
                  fontSize: 14,
                  color: textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _logMeal() {
    final String name = _nameController.text.isEmpty
        ? "Manual Meal"
        : _nameController.text;

    // Create a Food object with the calculated totals
    // Note: The app likely expects 'unit' to be the serving size name, e.g., "1 serving"
    // and nutrition per unit. We have the total per quantity.
    // If quantity is 1, it's exact. Use base values for nutrition per unit.

    final food = Food(
      id: DateTime.now().millisecondsSinceEpoch.toString(), // Simple unique ID
      name: name,
      category: "Manual",
      unit: "serving",
      baseWeightG: 0, // Unknown
      calories: _baseCalories, // Store per serving
      protein: _baseProtein,
      carbs: _baseCarbs,
      fat: _baseFat,
      source: 'manual',
    );

    // Return the food and quantity.
    // The previous screen needs to know quantity too.
    // We can assume the calling screen handles the 'Food' object and quantity separately or as a MealItem.
    // Since we don't know the exact return contract, we'll return a Map or similar.
    // Ideally we return the Food object, and the caller asks for quantity.
    // Or we return {food, quantity}.

    // For now, let's return the food object, assuming the quantity sets the *default* serving count?
    // Actually, if we pass the Food object with base nutrition, and pass quantity back,
    // the receiver can multiply.

    Navigator.pop(context, {'food': food, 'quantity': _quantity});
  }
}
