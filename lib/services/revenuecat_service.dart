import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// Notifies [GoRouter] when premium status changes.
class PremiumSubscription extends ChangeNotifier {
  bool isPremium = false;

  void update(bool value) {
    if (isPremium == value) return;
    isPremium = value;
    notifyListeners();
  }
}

final premiumSubscription = PremiumSubscription();

class RevenueCatService {
  RevenueCatService._();

  static final RevenueCatService instance = RevenueCatService._();

  static const String entitlementId = 'premium';
  static const String defaultOfferingId = 'default';

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

  void Function(CustomerInfo)? _customerInfoListener;

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

      _customerInfoListener = _onCustomerInfoUpdated;
      Purchases.addCustomerInfoUpdateListener(_customerInfoListener!);

      await getOfferings(forceRefresh: true);
      await _updatePremiumStatus(emitAlways: true);
    } catch (e) {
      debugPrint('❌ RevenueCat initialization failed: $e');
    }
  }

  void _onCustomerInfoUpdated(CustomerInfo customerInfo) {
    _updatePremiumStatusFromInfo(customerInfo);
  }

  void _updatePremiumStatusFromInfo(
    CustomerInfo customerInfo, {
    bool forceNotify = false,
  }) {
    final wasPremium = _isPremium;
    final isEntitlementActive = customerInfo.entitlements.active.containsKey(entitlementId);
    _isPremium = isEntitlementActive;

    debugPrint(
      '🔔 [DEBUG] RevenueCat: CustomerInfo fetched. Premium entitlement status: $isEntitlementActive',
    );

    if (forceNotify || wasPremium != _isPremium) {
      _emitPremiumStatus();
    }
  }

  void _emitPremiumStatus() {
    _premiumStatusController?.add(_isPremium);
    premiumSubscription.update(_isPremium);
    debugPrint('🔔 [DEBUG] RevenueCat: Premium status = $_isPremium');
  }

  Future<void> _updatePremiumStatus({bool emitAlways = false}) async {
    try {
      final customerInfo = await getCustomerInfo();
      _updatePremiumStatusFromInfo(customerInfo, forceNotify: emitAlways);
      if (emitAlways) {
        _emitPremiumStatus();
      }
    } catch (e) {
      debugPrint('❌ [DEBUG] RevenueCat: Failed to update premium status: $e');
    }
  }

  Future<Offerings?> getOfferings({bool forceRefresh = false}) async {
    if (!_isInitialized) return null;

    if (forceRefresh || _cachedOfferings == null) {
      try {
        debugPrint('🔄 [DEBUG] RevenueCat: Fetching offerings...');
        final offerings = await Purchases.getOfferings();
        _cachedOfferings = offerings;

        debugPrint('📦 [DEBUG] RevenueCat: Got ${offerings.all.length} offerings');
        debugPrint('📦 [DEBUG] RevenueCat: current = ${offerings.current?.identifier}');
        for (final entry in offerings.all.entries) {
          debugPrint('  Offering: ${entry.key}');
          for (final pkg in entry.value.availablePackages) {
            debugPrint(
              '    - Package: ${pkg.identifier}, type: ${pkg.packageType}, product: ${pkg.storeProduct.identifier}',
            );
          }
        }

        return offerings;
      } catch (e) {
        debugPrint('❌ [DEBUG] RevenueCat getOfferings failed: $e');
        return _cachedOfferings;
      }
    }
    return _cachedOfferings;
  }

  Offering? _resolveOffering() {
    final offerings = _cachedOfferings;
    if (offerings == null) return null;
    return offerings.current ?? offerings.getOffering(defaultOfferingId);
  }

  Future<void> loginUser(String appUserId) async {
    if (!_isInitialized) {
      debugPrint('⚠️ [DEBUG] RevenueCat: loginUser skipped — not initialized');
      return;
    }

    try {
      await Purchases.logIn(appUserId);
      debugPrint('✅ [DEBUG] RevenueCat: Logged in as $appUserId');
      await getOfferings(forceRefresh: true);
      await _updatePremiumStatus(emitAlways: true);
    } catch (e) {
      debugPrint('❌ [DEBUG] RevenueCat login failed: $e');
    }
  }

  Future<void> logout() async {
    if (!_isInitialized) return;

    try {
      await Purchases.logOut();
      _isPremium = false;
      _cachedOfferings = null;
      _emitPremiumStatus();
      debugPrint('✅ [DEBUG] RevenueCat: Logged out');
    } catch (e) {
      debugPrint('❌ [DEBUG] RevenueCat logout failed: $e');
    }
  }

  Future<CustomerInfo> getCustomerInfo() async {
    if (!_isInitialized) {
      throw StateError('RevenueCat not initialized');
    }
    return await Purchases.getCustomerInfo();
  }

  Future<bool> purchasePackage(Package package) async {
    if (!_isInitialized) {
      throw StateError('RevenueCat is not initialized');
    }

    try {
      debugPrint('🛒 [DEBUG] RevenueCat: Starting purchase for package: ${package.identifier}');
      final result = await Purchases.purchasePackage(package);
      
      // Perform a fresh check to update global state
      final isPremium = await isPremiumUser();
      
      if (isPremium) {
        debugPrint('✅ [DEBUG] RevenueCat: Purchase successful! Premium entitlement status: true');
      } else {
        debugPrint('⚠️ [DEBUG] RevenueCat: Purchase completed but no active entitlement found.');
      }

      return isPremium;
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      String errorMessage;

      switch (errorCode) {
        case PurchasesErrorCode.purchaseCancelledError:
          debugPrint('ℹ️ [DEBUG] RevenueCat: Purchase cancelled by user');
          return false;
        case PurchasesErrorCode.networkError:
          errorMessage = 'Network connection failed. Please check your internet connection and try again.';
          break;
        case PurchasesErrorCode.storeProblemError:
          errorMessage = 'Google Play Store / App Store encountered an issue. Please try again later.';
          break;
        case PurchasesErrorCode.purchaseNotAllowedError:
          errorMessage = 'This purchase is not allowed on this account (e.g., parental controls).';
          break;
        case PurchasesErrorCode.productAlreadyPurchasedError:
          errorMessage = 'You already have an active subscription for this product.';
          break;
        default:
          errorMessage = 'Purchase failed: ${e.message ?? e.toString()}';
          break;
      }
      
      debugPrint('❌ [DEBUG] RevenueCat: Purchase failed. Code: $errorCode, Error: $errorMessage');
      throw errorMessage;
    } catch (e) {
      debugPrint('❌ [DEBUG] RevenueCat: Purchase failed with unexpected error: $e');
      throw 'An unexpected error occurred during purchase: $e';
    }
  }

  Future<bool> restorePurchases() async {
    if (!_isInitialized) {
      throw StateError('RevenueCat is not initialized');
    }

    try {
      debugPrint('🔄 [DEBUG] RevenueCat: Restoring purchases...');
      final customerInfo = await Purchases.restorePurchases();
      
      // Perform a fresh check to update global state
      final isPremium = await isPremiumUser();
      
      if (isPremium) {
        debugPrint('✅ [DEBUG] RevenueCat: Restore successful! Premium entitlement status: true');
      } else {
        debugPrint('⚠️ [DEBUG] RevenueCat: Restore completed but no active entitlement found.');
      }
      
      return isPremium;
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      String errorMessage;

      switch (errorCode) {
        case PurchasesErrorCode.networkError:
          errorMessage = 'Network connection failed. Please check your connection and try again.';
          break;
        case PurchasesErrorCode.storeProblemError:
          errorMessage = 'Store issue encountered. Please try again later.';
          break;
        default:
          errorMessage = 'Restore failed: ${e.message ?? e.toString()}';
          break;
      }
      
      debugPrint('❌ [DEBUG] RevenueCat: Restore failed. Code: $errorCode, Error: $errorMessage');
      throw errorMessage;
    } catch (e) {
      debugPrint('❌ [DEBUG] RevenueCat: Restore failed with unexpected error: $e');
      throw 'An unexpected error occurred during restore: $e';
    }
  }

  Future<bool> isPremiumUser() async {
    if (!_isInitialized) return _isPremium;

    try {
      final customerInfo = await getCustomerInfo();
      _updatePremiumStatusFromInfo(customerInfo);
      debugPrint('🔍 [DEBUG] RevenueCat: isPremiumUser = $_isPremium');
      return _isPremium;
    } catch (e) {
      debugPrint('❌ [DEBUG] RevenueCat: isPremiumUser failed: $e');
      return _isPremium;
    }
  }

  Package? getMonthlyPackage() => _findPackage(PackageType.monthly);

  Package? getYearlyPackage() => _findPackage(PackageType.annual);

  Package? getSpecialPackage() {
    final offering = _resolveOffering();
    if (offering != null) {
      for (final pkg in offering.availablePackages) {
        if (_isSpecialPackage(pkg)) return pkg;
      }
    }

    if (_cachedOfferings == null) return null;

    for (final offering in _cachedOfferings!.all.values) {
      for (final pkg in offering.availablePackages) {
        if (_isSpecialPackage(pkg)) {
          debugPrint('✅ RevenueCat: Found special package: ${pkg.identifier}');
          return pkg;
        }
      }
    }

    debugPrint('⚠️ RevenueCat: No special package found');
    return null;
  }

  bool _isSpecialPackage(Package pkg) {
    final id = pkg.identifier.toLowerCase();
    final productId = pkg.storeProduct.identifier.toLowerCase();
    return id.contains('special') || productId.contains('special');
  }

  Package? _findPackage(PackageType type) {
    final offering = _resolveOffering();
    if (offering != null) {
      for (final pkg in offering.availablePackages) {
        if (pkg.packageType == type) {
          debugPrint('✅ RevenueCat: Found $type in ${offering.identifier}: ${pkg.identifier}');
          return pkg;
        }
      }
    }

    if (_cachedOfferings == null) return null;

    for (final off in _cachedOfferings!.all.values) {
      for (final pkg in off.availablePackages) {
        if (pkg.packageType == type) {
          debugPrint('✅ RevenueCat: Found $type in ${off.identifier}: ${pkg.identifier}');
          return pkg;
        }
      }
    }

    debugPrint('⚠️ RevenueCat: No package for $type');
    return null;
  }

  /// Price label for paywall footers, e.g. "₹250.00 per month".
  String? getMonthlyPriceLabel() {
    final pkg = getMonthlyPackage();
    if (pkg == null) return null;
    return '${pkg.storeProduct.priceString} per month';
  }

  List<Package> getAllPackages({String? offeringId}) {
    if (_cachedOfferings == null) return [];

    try {
      Offering? offering;
      if (offeringId != null) {
        offering = _cachedOfferings!.getOffering(offeringId);
      } else {
        offering = _resolveOffering();
      }
      return offering?.availablePackages ?? [];
    } catch (e) {
      debugPrint('❌ RevenueCat: Error getting all packages: $e');
      return [];
    }
  }

  void dispose() {
    if (_customerInfoListener != null) {
      Purchases.removeCustomerInfoUpdateListener(_customerInfoListener!);
      _customerInfoListener = null;
    }
    _premiumStatusController?.close();
    _premiumStatusController = null;
  }
}

final revenueCatServiceProvider = Provider<RevenueCatService>((ref) {
  return RevenueCatService.instance;
});
