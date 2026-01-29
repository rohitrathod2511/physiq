import 'package:cloud_firestore/cloud_firestore.dart';

class FoodService {
  final _firestore = FirebaseFirestore.instance;
  final String _collection = 'foods';

  // Categories as defined in the rules
  static const List<String> categories = [
    "Staple Foods",
    "Fast Food & Street Food",
    "Traditional / Regional Foods",
    "Protein Sources",
    "Vegetarian & Vegan",
    "Fruits",
    "Vegetables",
    "Snacks & Sweets",
    "Beverages",
    "Dairy & Fats"
  ];

  /// Search for foods by name prefix.
  /// Firestore simple prefix search: where name >= query AND name < query + 'z'
  /// We also check "searchKeywords" if available, but a simple prefix on 'name' is most robust for instant search.
  Future<List<Map<String, dynamic>>> searchFoods(String query) async {
    if (query.trim().isEmpty) return [];

    final term = query.trim().toLowerCase();
    
    // NOTE: This relies on the backend pipeline storing a 'searchKeywords' array 
    // for "contains" search behavior, which is better than prefix-only.
    // If you only have 'name', usage: 
    // .where('name', isGreaterThanOrEqualTo: term).where('name', isLessThan: term + '\uf8ff')
    
    // Using array-contains for token-based search (matches "pizza" in "Cheese Pizza")
    // Limit to 10 for performance.
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('searchKeywords', arrayContains: term)
          .limit(10)
          .get(const GetOptions(source: Source.serverAndCache)); // Leverage cache

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      // Fallback for simple prefix search if arrayContains fails or index missing
       final capitalizedTerm = term.isNotEmpty 
          ? term[0].toUpperCase() + term.substring(1) 
          : term;

      final snapshot = await _firestore
          .collection(_collection)
          .where('name', isGreaterThanOrEqualTo: capitalizedTerm)
          .where('name', isLessThan: '$capitalizedTerm\uf8ff')
          .limit(10)
          .get();
      
      return snapshot.docs.map((doc) => doc.data()).toList();
    }
  }

  /// Browse foods by category
  Future<List<Map<String, dynamic>>> getFoodsByCategory(String category) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('category', isEqualTo: category)
        .limit(20)
        .get(const GetOptions(source: Source.serverAndCache));

    return snapshot.docs.map((doc) => doc.data()).toList();
  }
}
