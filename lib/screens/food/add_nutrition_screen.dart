import 'package:flutter/material.dart';
import 'package:physiq/models/custom_food_model.dart';
import 'package:physiq/services/custom_food_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class AddNutritionScreen extends StatefulWidget {
  final String brandName;
  final String description;
  final String servingSize;
  final double servingPerContainer;

  const AddNutritionScreen({
    super.key,
    required this.brandName,
    required this.description,
    required this.servingSize,
    required this.servingPerContainer,
  });

  @override
  State<AddNutritionScreen> createState() => _AddNutritionScreenState();
}

class _AddNutritionScreenState extends State<AddNutritionScreen> {
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  
  // Advanced macros
  final _saturatedFatController = TextEditingController();
  final _polyunsaturatedFatController = TextEditingController();
  final _monounsaturatedFatController = TextEditingController();
  final _transFatController = TextEditingController();
  final _cholesterolController = TextEditingController();
  final _sodiumController = TextEditingController();
  final _potassiumController = TextEditingController();
  final _sugarController = TextEditingController();
  final _fiberController = TextEditingController();
  final _vitaminAController = TextEditingController();
  final _calciumController = TextEditingController();
  final _ironController = TextEditingController();

  final _service = CustomFoodService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Add Nutrition"),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSection("Required"),
                _buildField("Calories*", _caloriesController, isNumber: true),
                _buildField("Protein (g)", _proteinController, isNumber: true),
                _buildField("Carbs (g)", _carbsController, isNumber: true),
                _buildField("Total Fat (g)", _fatController, isNumber: true),
                const SizedBox(height: 24),
                _buildSection("Optional"),
                _buildField("Saturated Fat (g)", _saturatedFatController, isNumber: true),
                _buildField("Polyunsaturated Fat (g)", _polyunsaturatedFatController, isNumber: true),
                _buildField("Monounsaturated Fat (g)", _monounsaturatedFatController, isNumber: true),
                _buildField("Trans Fat (g)", _transFatController, isNumber: true),
                _buildField("Cholesterol (mg)", _cholesterolController, isNumber: true),
                _buildField("Sodium (mg)", _sodiumController, isNumber: true),
                _buildField("Potassium (mg)", _potassiumController, isNumber: true),
                _buildField("Sugar (g)", _sugarController, isNumber: true),
                _buildField("Fiber (g)", _fiberController, isNumber: true),
                _buildField("Vitamin A", _vitaminAController, isNumber: true),
                _buildField("Calcium", _calciumController, isNumber: true),
                _buildField("Iron", _ironController, isNumber: true),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveFood,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  disabledBackgroundColor: Colors.grey,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Save Food", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveFood() async {
    final calories = double.tryParse(_caloriesController.text.trim());
    if (calories == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter calories")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final nutrition = CustomFoodNutrition(
        calories: calories,
        protein: double.tryParse(_proteinController.text) ?? 0,
        carbs: double.tryParse(_carbsController.text) ?? 0,
        fat: double.tryParse(_fatController.text) ?? 0,
        saturatedFat: double.tryParse(_saturatedFatController.text) ?? 0,
        polyunsaturatedFat: double.tryParse(_polyunsaturatedFatController.text) ?? 0,
        monounsaturatedFat: double.tryParse(_monounsaturatedFatController.text) ?? 0,
        transFat: double.tryParse(_transFatController.text) ?? 0,
        cholesterol: double.tryParse(_cholesterolController.text) ?? 0,
        sodium: double.tryParse(_sodiumController.text) ?? 0,
        potassium: double.tryParse(_potassiumController.text) ?? 0,
        sugar: double.tryParse(_sugarController.text) ?? 0,
        fiber: double.tryParse(_fiberController.text) ?? 0,
        vitaminA: double.tryParse(_vitaminAController.text) ?? 0,
        calcium: double.tryParse(_calciumController.text) ?? 0,
        iron: double.tryParse(_ironController.text) ?? 0,
      );

      final foodId = const Uuid().v4();
      final food = CustomFood(
        id: foodId,
        userId: _service.uid ?? '',
        brandName: widget.brandName,
        description: widget.description,
        servingSize: widget.servingSize,
        servingPerContainer: widget.servingPerContainer,
        nutrition: nutrition,
        createdAt: DateTime.now(),
      );

      await _service.createCustomFood(food);

      if (mounted) {
        // Pop back to My Meals screen (need to pop twice: AddNutrition -> CreateFood -> MyFoods)
        // Pop back to CreateFoodScreen then to FoodDatabaseScreen
        Navigator.pop(context); // Pop AddNutritionScreen
        Navigator.pop(context); // Pop CreateFoodScreen
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error saving food: $e")));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
