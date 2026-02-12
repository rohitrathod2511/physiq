import 'package:flutter/material.dart';
import 'package:physiq/theme/design_system.dart';
import 'package:physiq/screens/food/add_nutrition_screen.dart';

class CreateFoodScreen extends StatefulWidget {
  const CreateFoodScreen({super.key});

  @override
  State<CreateFoodScreen> createState() => _CreateFoodScreenState();
}

class _CreateFoodScreenState extends State<CreateFoodScreen> {
  final _brandController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _servingSizeController = TextEditingController();
  final _servingPerContainerController = TextEditingController();

  bool _isNextEnabled = false;

  @override
  void initState() {
    super.initState();
    _descriptionController.addListener(_validate);
    _servingSizeController.addListener(_validate);
    _servingPerContainerController.addListener(_validate);
  }

  @override
  void dispose() {
    _brandController.dispose();
    _descriptionController.dispose();
    _servingSizeController.dispose();
    _servingPerContainerController.dispose();
    super.dispose();
  }

  void _validate() {
    final isValid = _descriptionController.text.trim().isNotEmpty &&
        _servingSizeController.text.trim().isNotEmpty &&
        _servingPerContainerController.text.trim().isNotEmpty;
    
    if (isValid != _isNextEnabled) {
      setState(() => _isNextEnabled = isValid);
    }
  }

  void _onNext() {
    if (!_isNextEnabled) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddNutritionScreen(
          brandName: _brandController.text.trim(),
          description: _descriptionController.text.trim(),
          servingSize: _servingSizeController.text.trim(),
          servingPerContainer: double.tryParse(_servingPerContainerController.text.trim()) ?? 1.0,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Create Food", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildField("Brand Name", _brandController, hint: "ex Campbell's"),
                const SizedBox(height: 16),
                _buildField("Description*", _descriptionController, hint: "Domino's cheese Pizza"),
                const SizedBox(height: 16),
                _buildField("Serving size*", _servingSizeController, hint: "ex 1 cup"),
                const SizedBox(height: 16),
                _buildField("Serving per container*", _servingPerContainerController, hint: "ex. 1", isNumber: true),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isNextEnabled ? _onNext : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  disabledBackgroundColor: Colors.grey[300],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text("Next", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, {String? hint, bool isNumber = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400]),
            filled: true,
            fillColor: Colors.grey[50], // Match reference lighter background
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }
}
