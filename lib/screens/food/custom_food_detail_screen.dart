import 'package:flutter/material.dart';
import 'package:physiq/models/custom_food_model.dart';
import 'package:physiq/services/custom_food_service.dart';
import 'package:physiq/services/saved_food_service.dart';
import 'package:physiq/models/saved_food_model.dart';

class CustomFoodDetailScreen extends StatefulWidget {
  final CustomFood food;
  const CustomFoodDetailScreen({super.key, required this.food});

  @override
  State<CustomFoodDetailScreen> createState() => _CustomFoodDetailScreenState();
}

class _CustomFoodDetailScreenState extends State<CustomFoodDetailScreen> {
  late TextEditingController _nameController;
  late TextEditingController _caloriesController;
  late TextEditingController _proteinController;
  late TextEditingController _carbsController;
  late TextEditingController _fatController;

  bool _isEditing = false;
  final _service = CustomFoodService();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.food.description);
    _caloriesController = TextEditingController(text: widget.food.nutrition.calories.toString());
    _proteinController = TextEditingController(text: widget.food.nutrition.protein.toString());
    _carbsController = TextEditingController(text: widget.food.nutrition.carbs.toString());
    _fatController = TextEditingController(text: widget.food.nutrition.fat.toString());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  Future<void> _saveChanges() async {
    final updatedFood = CustomFood(
      id: widget.food.id,
      userId: widget.food.userId,
      brandName: widget.food.brandName,
      description: _nameController.text,
      servingSize: widget.food.servingSize,
      servingPerContainer: widget.food.servingPerContainer,
      nutrition: CustomFoodNutrition(
        calories: double.tryParse(_caloriesController.text) ?? 0,
        protein: double.tryParse(_proteinController.text) ?? 0,
        carbs: double.tryParse(_carbsController.text) ?? 0,
        fat: double.tryParse(_fatController.text) ?? 0,
        // Preserve other fields
        saturatedFat: widget.food.nutrition.saturatedFat,
        polyunsaturatedFat: widget.food.nutrition.polyunsaturatedFat,
        monounsaturatedFat: widget.food.nutrition.monounsaturatedFat,
        transFat: widget.food.nutrition.transFat,
        cholesterol: widget.food.nutrition.cholesterol,
        sodium: widget.food.nutrition.sodium,
        potassium: widget.food.nutrition.potassium,
        sugar: widget.food.nutrition.sugar,
        fiber: widget.food.nutrition.fiber,
        vitaminA: widget.food.nutrition.vitaminA,
        calcium: widget.food.nutrition.calcium,
        iron: widget.food.nutrition.iron,
      ),
      createdAt: widget.food.createdAt,
    );

    await _service.updateCustomFood(updatedFood);
    setState(() {
      _isEditing = false;
    });
    if (mounted) Navigator.pop(context); // Close detail screen after save
  }

  Future<void> _deleteFood() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Food?"),
        content: const Text("This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _service.deleteCustomFood(widget.food.id);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? "Edit Food" : "Food Details"),
        actions: [
          if (!_isEditing) ...[
            IconButton(
              icon: const Icon(Icons.star_border),
              tooltip: "Save to Saved Scans",
              onPressed: () async {
                try {
                  final savedFood = SavedFood(
                    id: '', // Service generates ID
                    userId: widget.food.userId,
                    name: widget.food.description,
                    sourceType: 'custom_food',
                    servingSize: widget.food.servingSize,
                    servingAmount: 1.0, // Default to 1 for custom food base entry
                    nutrition: SavedFoodNutrition(
                      calories: widget.food.nutrition.calories,
                      protein: widget.food.nutrition.protein,
                      carbs: widget.food.nutrition.carbs,
                      fat: widget.food.nutrition.fat,
                      saturatedFat: widget.food.nutrition.saturatedFat,
                      // Map other fields if needed, or simplified
                    ),
                    createdAt: DateTime.now(),
                  );
                  await SavedFoodService().saveFood(savedFood);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Saved successfully")),
                    );
                  }
                } catch (e) {
                   if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Error: $e")),
                    );
                  }
                }
              },
            ),
            IconButton(icon: const Icon(Icons.edit), onPressed: () {
                setState(() {
                  _isEditing = true;
                });
            }),
          ]
          else
            IconButton(icon: const Icon(Icons.save), onPressed: _saveChanges),
          
          if (!_isEditing)
             IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: _deleteFood),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildField("Name", _nameController, enabled: _isEditing),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildField("Calories", _caloriesController, enabled: _isEditing, isNumber: true)),
                const SizedBox(width: 16),
                Expanded(child: _buildField("Protein", _proteinController, enabled: _isEditing, isNumber: true)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildField("Carbs", _carbsController, enabled: _isEditing, isNumber: true)),
                const SizedBox(width: 16),
                Expanded(child: _buildField("Fat", _fatController, enabled: _isEditing, isNumber: true)),
              ],
            ),
            // Show other nutrition info as read-only for now if needed, or editable
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, {bool enabled = true, bool isNumber = false}) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }
}
