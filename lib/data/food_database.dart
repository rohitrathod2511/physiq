
class FoodDatabase {
  static const List<Map<String, dynamic>> foods = [
    // 1. Staple Foods
    {"name": "White Rice", "category": "Staple Foods"},
    {"name": "Brown Rice", "category": "Staple Foods"},
    {"name": "Roti / Chapati", "category": "Staple Foods"},
    {"name": "Whole Wheat Bread", "category": "Staple Foods"},
    {"name": "White Bread", "category": "Staple Foods"},
    {"name": "Pasta", "category": "Staple Foods"},
    {"name": "Noodles", "category": "Staple Foods"},
    {"name": "Oats", "category": "Staple Foods"},

    // 2. Fast Food & Street Food
    {"name": "Pizza (Cheese)", "category": "Fast Food & Street Food"},
    {"name": "Pizza (Veg)", "category": "Fast Food & Street Food"},
    {"name": "Pizza (Chicken)", "category": "Fast Food & Street Food"},
    {"name": "Pizza (Pepperoni)", "category": "Fast Food & Street Food"},
    {"name": "Burger (Veg)", "category": "Fast Food & Street Food"},
    {"name": "Burger (Chicken)", "category": "Fast Food & Street Food"},
    {"name": "French Fries", "category": "Fast Food & Street Food"},
    {"name": "Momos (Veg)", "category": "Fast Food & Street Food"},
    {"name": "Momos (Chicken)", "category": "Fast Food & Street Food"},
    {"name": "Tacos", "category": "Fast Food & Street Food"},
    {"name": "Samosa", "category": "Fast Food & Street Food"},

    // 3. Traditional / Regional Foods
    {"name": "Dal Tadka", "category": "Traditional / Regional Foods"},
    {"name": "Paneer Butter Masala", "category": "Traditional / Regional Foods"},
    {"name": "Chicken Curry", "category": "Traditional / Regional Foods"},
    {"name": "Biryani (Veg)", "category": "Traditional / Regional Foods"},
    {"name": "Biryani (Chicken)", "category": "Traditional / Regional Foods"},
    {"name": "Dosa", "category": "Traditional / Regional Foods"},
    {"name": "Idli", "category": "Traditional / Regional Foods"},

    // 4. Protein Sources
    {"name": "Chicken Breast", "category": "Protein Sources"},
    {"name": "Grilled Fish", "category": "Protein Sources"},
    {"name": "Boiled Eggs", "category": "Protein Sources"},
    {"name": "Scrambled Eggs", "category": "Protein Sources"},
    {"name": "Paneer (Raw)", "category": "Protein Sources"},
    {"name": "Tofu", "category": "Protein Sources"},
    {"name": "Soya Chunks", "category": "Protein Sources"},
    {"name": "Whey Protein Shake", "category": "Protein Sources"},

    // 5. Vegetarian & Vegan
    {"name": "Mixed Vegetable Curry", "category": "Vegetarian & Vegan"},
    {"name": "Vegan Bowl", "category": "Vegetarian & Vegan"},
    {"name": "Green Salad", "category": "Vegetarian & Vegan"},
    {"name": "Caesar Salad", "category": "Vegetarian & Vegan"},
    {"name": "Chickpea Salad", "category": "Vegetarian & Vegan"},

    // 6. Fruits
    {"name": "Apple", "category": "Fruits"},
    {"name": "Banana", "category": "Fruits"},
    {"name": "Mango", "category": "Fruits"},
    {"name": "Orange", "category": "Fruits"},
    {"name": "Grapes", "category": "Fruits"},
    {"name": "Berries (Strawberry/Blueberry)", "category": "Fruits"},
    {"name": "Watermelon", "category": "Fruits"},
    {"name": "Papaya", "category": "Fruits"},

    // 7. Vegetables
    {"name": "Potato (Boiled)", "category": "Vegetables"},
    {"name": "Spinach", "category": "Vegetables"},
    {"name": "Carrot", "category": "Vegetables"},
    {"name": "Broccoli", "category": "Vegetables"},
    {"name": "Cauliflower", "category": "Vegetables"},
    {"name": "Capsicum", "category": "Vegetables"},
    {"name": "Onion", "category": "Vegetables"},
    {"name": "Tomato", "category": "Vegetables"},

    // 8. Snacks & Sweets
    {"name": "Potato Chips", "category": "Snacks & Sweets"},
    {"name": "Biscuits / Cookies", "category": "Snacks & Sweets"},
    {"name": "Chocolate Cake", "category": "Snacks & Sweets"},
    {"name": "Chocolate Bar", "category": "Snacks & Sweets"},
    {"name": "Popcorn", "category": "Snacks & Sweets"},
    {"name": "Ice Cream", "category": "Snacks & Sweets"},
    {"name": "Donut", "category": "Snacks & Sweets"},

    // 9. Beverages
    {"name": "Tea (with milk)", "category": "Beverages"},
    {"name": "Black Coffee", "category": "Beverages"},
    {"name": "Cappuccino", "category": "Beverages"},
    {"name": "Orange Juice", "category": "Beverages"},
    {"name": "Milkshake (Chocolate)", "category": "Beverages"},
    {"name": "Milkshake (Banana)", "category": "Beverages"},
    {"name": "Cola / Soda", "category": "Beverages"},

    // 10. Dairy & Fats
    {"name": "Milk (Whole)", "category": "Dairy & Fats"},
    {"name": "Curd / Yogurt", "category": "Dairy & Fats"},
    {"name": "Greek Yogurt", "category": "Dairy & Fats"},
    {"name": "Cheese Slice", "category": "Dairy & Fats"},
    {"name": "Butter", "category": "Dairy & Fats"},
    {"name": "Olive Oil", "category": "Dairy & Fats"},
    {"name": "Peanut Butter", "category": "Dairy & Fats"},
    {"name": "Almonds", "category": "Dairy & Fats"},
    {"name": "Walnuts", "category": "Dairy & Fats"},
  ];

  static List<Map<String, dynamic>> search(String query) {
    if (query.isEmpty) return [];
    final lowerQuery = query.toLowerCase();
    
    // Sort logic: exact match first, then starts with, then contains
    return foods.where((item) {
      final name = (item["name"] as String).toLowerCase();
      return name.contains(lowerQuery);
    }).toList();
  }
}
