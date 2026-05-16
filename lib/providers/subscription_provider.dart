import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:physiq/services/revenuecat_service.dart';

final isPremiumStreamProvider = StreamProvider<bool>((ref) {
  return RevenueCatService.instance.premiumStatusStream;
});

final isPremiumNotifierProvider = StateNotifierProvider<PremiumStatusNotifier, bool>((ref) {
  final notifier = PremiumStatusNotifier();

  RevenueCatService.instance.premiumStatusStream.listen((isPremium) {
    notifier.updatePremiumStatus(isPremium);
  });

  ref.onDispose(() {});

  return notifier;
});

class PremiumStatusNotifier extends StateNotifier<bool> {
  PremiumStatusNotifier() : super(false) {
    _checkInitialStatus();
  }

  Future<void> _checkInitialStatus() async {
    final isPremium = await RevenueCatService.instance.isPremiumUser();
    updatePremiumStatus(isPremium);
  }

  void updatePremiumStatus(bool isPremium) {
    state = isPremium;
  }

  Future<bool> checkPremiumStatus() async {
    final isPremium = await RevenueCatService.instance.isPremiumUser();
    updatePremiumStatus(isPremium);
    return isPremium;
  }
}

final offeringsProvider = FutureProvider<Offerings?>((ref) async {
  return await RevenueCatService.instance.getOfferings(forceRefresh: true);
});

final subscriptionGuardProvider = Provider<SubscriptionGuard>((ref) {
  return SubscriptionGuard(ref);
});

class SubscriptionGuard {
  final Ref _ref;

  SubscriptionGuard(this._ref);

  bool get isPremium => _ref.read(isPremiumNotifierProvider);

  Future<bool> checkAndUpdateStatus() async {
    final isPremium = await RevenueCatService.instance.isPremiumUser();
    _ref.read(isPremiumNotifierProvider.notifier).updatePremiumStatus(isPremium);
    return isPremium;
  }

  bool canAccessPremiumFeature() {
    return _ref.read(isPremiumNotifierProvider);
  }
}