import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class RevenueCatService {
  RevenueCatService._();

  static final RevenueCatService instance = RevenueCatService._();

  static const String _androidApiKeyPlaceholder =
      'goog_XAFupTgLMUsRleCsUqSZFkRVWJg';
  static const String _iosApiKeyPlaceholder = '';

  String get _androidApiKey => _androidApiKeyPlaceholder;
  String get _iosApiKey => _iosApiKeyPlaceholder;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await Purchases.setLogLevel(LogLevel.debug);

      final apiKey = Platform.isAndroid ? _androidApiKey : _iosApiKey;

      if (apiKey == _androidApiKeyPlaceholder ||
          apiKey == _iosApiKeyPlaceholder) {
        debugPrint('⚠️ RevenueCat: API key not set. Using placeholder.');
        debugPrint(
          '⚠️ Please set your API keys in lib/services/revenuecat_service.dart',
        );
      }

      await Purchases.configure(PurchasesConfiguration(apiKey));

      _isInitialized = true;
      debugPrint('✅ RevenueCat initialized successfully');
    } catch (e) {
      debugPrint('❌ RevenueCat initialization failed: $e');
      rethrow;
    }
  }

  Future<void> loginUser(String appUserId) async {
    try {
      await Purchases.logIn(appUserId);
      debugPrint('✅ RevenueCat: Logged in as $appUserId');
    } catch (e) {
      debugPrint('❌ RevenueCat login failed: $e');
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await Purchases.logOut();
      debugPrint('✅ RevenueCat: Logged out');
    } catch (e) {
      debugPrint('❌ RevenueCat logout failed: $e');
      rethrow;
    }
  }

  Future<CustomerInfo> getCustomerInfo() async {
    try {
      return await Purchases.getCustomerInfo();
    } catch (e) {
      debugPrint('❌ RevenueCat getCustomerInfo failed: $e');
      rethrow;
    }
  }

  Future<Offerings> getOfferings() async {
    try {
      return await Purchases.getOfferings();
    } catch (e) {
      debugPrint('❌ RevenueCat getOfferings failed: $e');
      rethrow;
    }
  }

  Future<bool> purchasePackage(Package package) async {
    try {
      final result = await Purchases.purchasePackage(package);
      return result.customerInfo.entitlements.all.isNotEmpty;
    } catch (e) {
      debugPrint('❌ RevenueCat purchasePackage failed: $e');
      rethrow;
    }
  }

  Future<bool> restorePurchases() async {
    try {
      final customerInfo = await Purchases.restorePurchases();
      return customerInfo.entitlements.all.isNotEmpty;
    } catch (e) {
      debugPrint('❌ RevenueCat restorePurchases failed: $e');
      rethrow;
    }
  }

  Future<bool> checkPremiumStatus({String entitlementId = 'premium'}) async {
    try {
      final customerInfo = await getCustomerInfo();
      final entitlement = customerInfo.entitlements.all[entitlementId];
      return entitlement?.isActive == true;
    } catch (e) {
      debugPrint('❌ RevenueCat checkPremiumStatus failed: $e');
      return false;
    }
  }

  Offering? getOffering(Offerings offerings, {String offeringId = 'default'}) {
    try {
      return offerings.getOffering(offeringId);
    } catch (e) {
      debugPrint('❌ RevenueCat getOffering failed: $e');
      return null;
    }
  }

  Package? getPackageFromOffering(Offering offering, {String? packageId}) {
    try {
      if (packageId != null) {
        return offering.availablePackages.firstWhere(
          (p) => p.identifier == packageId,
          orElse: () => offering.availablePackages.first,
        );
      }
      return offering.availablePackages.isNotEmpty
          ? offering.availablePackages.first
          : null;
    } catch (e) {
      debugPrint('❌ RevenueCat getPackageFromOffering failed: $e');
      return null;
    }
  }
}
