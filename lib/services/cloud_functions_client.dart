import 'dart:convert';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:http/http.dart' as http;

class CloudFunctionsClient {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  static const String _baseUrl = 'https://us-central1-physiq-5811f.cloudfunctions.net';

  Future<void> generateCanonicalPlan({
    required String uid,
    required Map<String, dynamic> profile,
    required int clientPlanVersion,
  }) async {
    await _functions.httpsCallable('generateCanonicalPlan').call({
      'uid': uid,
      'profile': profile,
      'clientPlanVersion': clientPlanVersion,
    });
  }

  Future<void> deleteUserData(String uid) async {
    await _functions.httpsCallable('deleteUserData').call({'uid': uid});
  }

  Future<void> redeemPromoCode(String code, String newUserUid) async {
    await _functions.httpsCallable('redeemPromoCode').call({
      'code': code,
      'newUserUid': newUserUid,
    });
  }

  Future<Map<String, dynamic>> getUserRank(String uid) async {
    final result = await _functions.httpsCallable('getUserRank').call({
      'uid': uid,
    });
    return Map<String, dynamic>.from(result.data);
  }

  Future<Map<String, dynamic>> recognizeMealImage(String imageB64) async {
    final result = await _functions.httpsCallable('recognizeMealImage').call({
      'imageB64': imageB64,
    });
    return Map<String, dynamic>.from(result.data);
  }

  // MODERN HTTPS REQUEST (onRequest) Task 2
  Future<List<dynamic>> searchFoodUSDA(String query) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/searchFoodUSDA'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'query': query}),
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body) as List<dynamic>;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // MODERN HTTPS REQUEST (onRequest) Task 3
  Future<Map<String, dynamic>?> getFoodDetailsUSDA(String fdcId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/getFoodDetailsUSDA'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'fdcId': fdcId}),
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> enrichMealItem(String ingredient) async {
    try {
      final result = await _functions.httpsCallable('enrichMealItem').call({
        'ingredient': ingredient,
      });
      if (result.data == null) return null;
      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      return null;
    }
  }
}
