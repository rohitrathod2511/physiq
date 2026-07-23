import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:physiq/providers/subscription_provider.dart';
import 'package:physiq/services/revenuecat_service.dart';

/// Central paywall entry and post-purchase navigation.
class PaywallNavigator {
  static const String inAppQueryKey = 'inApp';

  /// Opens the full paywall funnel for non-premium users.
  static void show(BuildContext context) {
    context.push('/onboarding/paywall-free?$inAppQueryKey=1');
  }

  /// Whether this paywall session was opened from the main app (vs onboarding).
  static bool isInAppSession(GoRouterState state) {
    return state.uri.queryParameters[inAppQueryKey] == '1';
  }

  /// After a successful purchase or restore — refresh entitlement and navigate
  /// once to Home. GoRouter only guards routes; it does not navigate post-purchase.
  static Future<void> onPurchaseSuccess(
    BuildContext context,
    WidgetRef ref,
  ) async {
    await RevenueCatService.instance.invalidateAndFetchCustomerInfo();

    final isPremium = RevenueCatService.instance.isPremium;
    ref
        .read(isPremiumNotifierProvider.notifier)
        .updatePremiumStatus(isPremium);

    if (!context.mounted || !isPremium) return;

    final location = GoRouterState.of(context).uri.path;
    if (!_isPaywallPath(location)) return;

    debugPrint(
      '🔄 [DEBUG] PaywallNavigator: navigating once to /home after purchase.',
    );
    context.go('/home');
  }

  static bool _isPaywallPath(String path) {
    return path == '/paywall' || path.startsWith('/onboarding/paywall');
  }

  /// Push the next funnel step, preserving in-app query when applicable.
  static void pushStep(BuildContext context, String path) {
    context.push(_withInAppQuery(context, path));
  }

  static void replaceStep(BuildContext context, String path) {
    context.pushReplacement(_withInAppQuery(context, path));
  }

  static String _withInAppQuery(BuildContext context, String path) {
    final state = GoRouterState.of(context);
    if (isInAppSession(state)) {
      return path.contains('?')
          ? '$path&$inAppQueryKey=1'
          : '$path?$inAppQueryKey=1';
    }
    return path;
  }
}
