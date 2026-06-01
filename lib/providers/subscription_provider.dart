import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:physiq/services/revenuecat_service.dart';

final isPremiumNotifierProvider =
    StateNotifierProvider<PremiumStatusNotifier, bool>((ref) {
  final notifier = PremiumStatusNotifier();
  StreamSubscription<bool>? sub;

  sub = RevenueCatService.instance.premiumStatusStream.listen((isPremium) {
    notifier.updatePremiumStatus(isPremium);
  });

  ref.onDispose(() => sub?.cancel());

  return notifier;
});

class PremiumStatusNotifier extends StateNotifier<bool> {
  PremiumStatusNotifier() : super(RevenueCatService.instance.isPremium) {
    _checkInitialStatus();
  }

  Future<void> _checkInitialStatus() async {
    final isPremium = await RevenueCatService.instance.isPremiumUser();
    updatePremiumStatus(isPremium);
  }

  void updatePremiumStatus(bool isPremium) {
    if (state != isPremium) {
      state = isPremium;
    }
  }

  Future<bool> checkPremiumStatus() async {
    final isPremium = await RevenueCatService.instance.isPremiumUser();
    updatePremiumStatus(isPremium);
    return isPremium;
  }
}

final offeringsProvider = FutureProvider<Offerings?>((ref) async {
  return RevenueCatService.instance.getOfferings(forceRefresh: true);
});
