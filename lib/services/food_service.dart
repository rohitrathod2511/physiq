import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/food_model.dart';

class FoodService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  // 1. SEARCH FOODS (Firebase + FatSecret)
  Future<List<Food>> searchFoods(String query) async {
    if (query.isEmpty) return [];

    final normalizedQuery = query.toLowerCase().trim();
    List<Food> results = [];

    try {
      // Step A: Firebase Search (Prioritize Indian Foods)
      final aliasSnap = await _firestore
          .collection('food_aliases')
          .where('alias', isEqualTo: normalizedQuery)
          .limit(5)
          .get();

      // If exact match found in Firebase, add it
      for (var doc in aliasSnap.docs) {
        final foodId = doc['foodId'];
        final food = await getFoodById(foodId);
        if (food != null && !results.any((f) => f.id == food.id)) {
          results.add(food);
        }
      }

      // Step B: Prefix Search in Firebase (only if few results)
      if (results.length < 3) {
        final prefixSnap = await _firestore
            .collection('food_aliases')
            .orderBy('alias')
            .startAt([normalizedQuery])
            .endAt([normalizedQuery + '\uf8ff'])
            .limit(5)
            .get();

        for (var doc in prefixSnap.docs) {
          final foodId = doc['foodId'];
          if (results.any((f) => f.id == foodId)) continue;
          
          final food = await getFoodById(foodId);
          if (food != null) results.add(food);
        }
      }

      // Step C: FatSecret API Search via Cloud Function
      
      final callable = _functions.httpsCallable('searchFood');
      final result = await callable.call({'query': query});
      final fsFoods = result.data as List<dynamic>;

      for (var f in fsFoods) {
        // Parse basic info from description if possible, or use defaults
        final desc = f['description'] as String? ?? '';
        final Map<String, double> macros = _parseDescription(desc);
        
        // Extract unit from description start "Per ..."
        String unit = 'serving';
        if (desc.startsWith('Per ')) {
          final dashIndex = desc.indexOf(' -');
          if (dashIndex != -1) {
            unit = desc.substring(4, dashIndex).trim();
          }
        }

        results.add(Food(
          id: 'fs_${f["id"]}',
          name: f['name'] ?? 'Unknown',
          category: f['type'] ?? 'General',
          unit: unit,
          baseWeightG: 0, 
          calories: macros['calories'] ?? 0,
          protein: macros['protein'] ?? 0,
          carbs: macros['carbs'] ?? 0,
          fat: macros['fat'] ?? 0,
          source: 'fatsecret',
          isIndian: false, 
        ));
      }

    } catch (e) {
      print('❌ Food Search Error: $e');
    }

    return results;
  }

  // Helper to parse FatSecret description string
  Map<String, double> _parseDescription(String desc) {
    // "Per 100g - Calories: 52kcal | Fat: 0.17g | Carbs: 13.81g | Protein: 0.26g"
    final Map<String, double> macros = {};
    
    // Extract calories
    final calMatch = RegExp(r'Calories:\s*([\d\.]+)kcal').firstMatch(desc);
    if (calMatch != null) macros['calories'] = double.tryParse(calMatch.group(1) ?? '0') ?? 0;

    // Extract fat
    final fatMatch = RegExp(r'Fat:\s*([\d\.]+)g').firstMatch(desc);
    if (fatMatch != null) macros['fat'] = double.tryParse(fatMatch.group(1) ?? '0') ?? 0;

    // Extract carbs
    final carbsMatch = RegExp(r'Carbs:\s*([\d\.]+)g').firstMatch(desc);
    if (carbsMatch != null) macros['carbs'] = double.tryParse(carbsMatch.group(1) ?? '0') ?? 0;

    // Extract protein
    final protMatch = RegExp(r'Protein:\s*([\d\.]+)g').firstMatch(desc);
    if (protMatch != null) macros['protein'] = double.tryParse(protMatch.group(1) ?? '0') ?? 0;

    return macros;
  }

  // 2. FETCH FOOD BY ID
  Future<Food?> getFoodById(String id) async {
    try {
      if (id.startsWith('fs_')) {
        return _getFatSecretDetails(id.substring(3)); // Remove 'fs_' prefix
      }

      final doc = await _firestore.collection('foods').doc(id).get();
      if (doc.exists) {
        return Food.fromSnapshot(doc);
      }
    } catch (e) {
      print('❌ Get Food Error: $e');
    }
    return null;
  }

  // 3. GET FATSECRET DETAILS
  Future<Food?> _getFatSecretDetails(String fsId) async {
    try {
      final callable = _functions.httpsCallable('getFoodDetails');
      final result = await callable.call({'foodId': fsId});
      final data = result.data as Map<String, dynamic>;

      // Servings logic: Pick the default or first serving
      final servings = data['servings'] as List<dynamic>;
      if (servings.isEmpty) return null;
      
      var serving = servings.first;

      return Food(
        id: 'fs_${data['id']}',
        name: data['name'],
        category: 'General',
        unit: serving['description'] ?? 'serving',
        baseWeightG: (serving['metric_serving_amount'] ?? 0).toDouble(), // e.g. 100g
        calories: (serving['calories'] ?? 0).toDouble(),
        protein: (serving['protein'] ?? 0).toDouble(),
        carbs: (serving['carbs'] ?? 0).toDouble(),
        fat: (serving['fat'] ?? 0).toDouble(),
        source: 'fatsecret',
        isIndian: false,
      );

    } catch (e) {
      print('❌ Get Info Error: $e');
      return null;
    }
  }

  // 4. GET COMMON FOODS
  Future<List<Food>> getCommonFoods() async {
    try {
      final snap = await _firestore
          .collection('foods')
          .where('isIndian', isEqualTo: true)
          .limit(20)
          .get();

      return snap.docs.map((doc) => Food.fromSnapshot(doc)).toList();
    } catch (e) {
      print('❌ Get Common Foods Error: $e');
      return [];
    }
  }

  // 5. BARCODE SEARCH
  Future<Food?> searchBarcode(String code) async {
    try {
        final callable = _functions.httpsCallable('searchBarcode');
        final result = await callable.call({'barcode': code});
        final data = result.data; // { foodId: ... } or null

        if (data == null) return null;
        
        final foodId = data['foodId'];
        if (foodId != null) {
            return _getFatSecretDetails(foodId);
        }
    } catch (e) {
        print('❌ Barcode Error: $e');
    }
    return null;
  }
}
