import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class RevenueCatService {
  RevenueCatService._();

  static final RevenueCatService instance = RevenueCatService._();

  static const String _androidApiKey = 'goog_XAFupTgLMUsRleCsUqSZFkRVWJg';
  static const String _iosApiKey = '';

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  StreamController<bool>? _premiumStatusController;
  Stream<bool> get premiumStatusStream {
    _premiumStatusController ??= StreamController<bool>.broadcast();
    return _premiumStatusController!.stream;
  }

  bool _isPremium = false;
  bool get isPremium => _isPremium;

  Offerings? _cachedOfferings;
  Offerings? get cachedOfferings => _cachedOfferings;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await Purchases.setLogLevel(LogLevel.debug);

      final apiKey = Platform.isAndroid ? _androidApiKey : _iosApiKey;

      if (apiKey.isEmpty) {
        debugPrint('⚠️ RevenueCat: API key not set');
        return;
      }

      await Purchases.configure(PurchasesConfiguration(apiKey));
      _isInitialized = true;
      debugPrint('✅ RevenueCat initialized successfully');

      Purchases.addCustomerInfoUpdateListener(_onCustomerInfoUpdated);

      await getOfferings(forceRefresh: true);
      await _updatePremiumStatus();
    } catch (e) {
      debugPrint('❌ RevenueCat initialization failed: $e');
    }
  }

  void _onCustomerInfoUpdated(CustomerInfo customerInfo) {
    _updatePremiumStatusFromInfo(customerInfo);
  }

  void _updatePremiumStatusFromInfo(CustomerInfo customerInfo) {
    final wasPremium = _isPremium;
    final entitlement = customerInfo.entitlements.all['premium'];
    _isPremium = entitlement?.isActive == true;

    debugPrint('🔔 RevenueCat: Checking premium - isActive: ${entitlement?.isActive}');

    if (wasPremium != _isPremium) {
      _premiumStatusController?.add(_isPremium);
      debugPrint('🔔 RevenueCat: Premium status changed to $_isPremium');
    }
  }

  Future<void> _updatePremiumStatus() async {
    try {
      final customerInfo = await getCustomerInfo();
      _updatePremiumStatusFromInfo(customerInfo);
    } catch (e) {
      debugPrint('❌ RevenueCat: Failed to update premium status: $e');
    }
  }

  Future<Offerings?> getOfferings({bool forceRefresh = false}) async {
    if (forceRefresh || _cachedOfferings == null) {
      try {
        debugPrint('🔄 RevenueCat: Fetching offerings...');
        final offerings = await Purchases.getOfferings();
        _cachedOfferings = offerings;

        debugPrint('📦 RevenueCat: Got ${offerings.all.length} offerings');
        for (final entry in offerings.all.entries) {
          debugPrint('  Offering: ${entry.key}');
          for (final pkg in entry.value.availablePackages) {
            debugPrint('    - Package: ${pkg.identifier}, ProductId: ${pkg.storeProduct.identifier}');
          }
        }

        return offerings;
      } catch (e) {
        debugPrint('❌ RevenueCat getOfferings failed: $e');
        return null;
      }
    }
    return _cachedOfferings;
  }

  Future<void> loginUser(String appUserId) async {
    try {
      await Purchases.logIn(appUserId);
      debugPrint('✅ RevenueCat: Logged in as $appUserId');
      await getOfferings(forceRefresh: true);
      await _updatePremiumStatus();
    } catch (e) {
      debugPrint('❌ RevenueCat login failed: $e');
    }
  }

  Future<void> logout() async {
    try {
      await Purchases.logOut();
      _isPremium = false;
      _cachedOfferings = null;
      _premiumStatusController?.add(false);
      debugPrint('✅ RevenueCat: Logged out');
    } catch (e) {
      debugPrint('❌ RevenueCat logout failed: $e');
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

  Future<bool> purchasePackage(Package package) async {
    try {
      debugPrint('🛒 RevenueCat: Purchasing package: ${package.identifier}');
      final result = await Purchases.purchasePackage(package);
      _updatePremiumStatusFromInfo(result.customerInfo);

      if (_isPremium) {
        debugPrint('✅ RevenueCat: Purchase successful!');
      } else {
        debugPrint('⚠️ RevenueCat: Purchase completed but no active entitlement');
      }

      return _isPremium;
    } catch (e) {
      debugPrint('❌ RevenueCat purchasePackage failed: $e');
      rethrow;
    }
  }

  Future<bool> restorePurchases() async {
    try {
      debugPrint('🔄 RevenueCat: Restoring purchases...');
      final customerInfo = await Purchases.restorePurchases();
      _updatePremiumStatusFromInfo(customerInfo);
      debugPrint('✅ RevenueCat: Restore completed, isPremium: $_isPremium');
      return _isPremium;
    } catch (e) {
      debugPrint('❌ RevenueCat restorePurchases failed: $e');
      return false;
    }
  }

  Future<bool> isPremiumUser() async {
    try {
      final customerInfo = await getCustomerInfo();
      final entitlement = customerInfo.entitlements.all['premium'];
      final isPremium = entitlement?.isActive == true;
      debugPrint('🔍 RevenueCat: isPremiumUser = $isPremium');
      return isPremium;
    } catch (e) {
      debugPrint('❌ RevenueCat isPremiumUser failed: $e');
      return _isPremium;
    }
  }

  Package? getMonthlyPackage() {
    return _findPackage(PackageType.monthly);
  }

  Package? getYearlyPackage() {
    return _findPackage(PackageType.annual);
  }

  Package? getSpecialPackage() {
    if (_cachedOfferings == null) return null;

    for (final offering in _cachedOfferings!.all.values) {
      for (final pkg in offering.availablePackages) {
        if (pkg.identifier.toLowerCase().contains('special') ||
            pkg.storeProduct.identifier.toLowerCase().contains('special')) {
          debugPrint('✅ RevenueCat: Found special package: ${pkg.identifier}');
          return pkg;
        }
      }
    }
    return null;
  }

Package? _findPackage(PackageType type) {
    if (_cachedOfferings == null) return null;

    final typeString = type.name;

    for (final offering in _cachedOfferings!.all.values) {
      for (final pkg in offering.availablePackages) {
        if (pkg.packageType == type) {
          debugPrint('✅ RevenueCat: Found package for $typeString: ${pkg.identifier}');
          return pkg;
        }
      }
    }
    return null;
  }

  List<Package> getAllPackages({String? offeringId}) {
    if (_cachedOfferings == null) return [];

    try {
      Offering? offering;
      if (offeringId != null) {
        offering = _cachedOfferings!.getOffering(offeringId);
      } else {
        offering = _cachedOfferings!.current;
      }

      return offering?.availablePackages ?? [];
    } catch (e) {
      debugPrint('❌ RevenueCat: Error getting all packages: $e');
      return [];
    }
  }

  void dispose() {
    _premiumStatusController?.close();
    _premiumStatusController = null;
  }
}

final revenueCatServiceProvider = Provider<RevenueCatService>((ref) {
  return RevenueCatService.instance;
});

final isPremiumProvider = StreamProvider<bool>((ref) {
  return RevenueCatService.instance.premiumStatusStream;
});

final offeringsProvider = FutureProvider<Offerings?>((ref) async {
  return await RevenueCatService.instance.getOfferings(forceRefresh: true);
});