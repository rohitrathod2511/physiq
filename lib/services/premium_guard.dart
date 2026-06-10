import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:physiq/navigation/paywall_navigator.dart';
import 'package:physiq/providers/subscription_provider.dart';
import 'package:physiq/services/revenuecat_service.dart';

/// Gates premium features (+ menu, Exercise, meal logging).
class PremiumGuard {
  static bool isPremium(WidgetRef ref) {
    return ref.read(isPremiumNotifierProvider);
  }

  /// Refreshes from RevenueCat when local state is not already premium.
  static Future<bool> ensurePremium(WidgetRef ref) async {
    final cached = ref.read(isPremiumNotifierProvider);
    if (cached && RevenueCatService.instance.isPremium) {
      return true;
    }

    final fresh = await RevenueCatService.instance.isPremiumUser();
    ref.read(isPremiumNotifierProvider.notifier).updatePremiumStatus(fresh);
    return fresh;
  }

  /// If not premium, opens the paywall funnel. Returns true when allowed.
  static Future<bool> requirePremium(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final fresh = await ensurePremium(ref);
    if (fresh) return true;

    if (!context.mounted) return false;
    PaywallNavigator.show(context);
    return false;
  }
}
