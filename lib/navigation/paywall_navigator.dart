import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:physiq/providers/subscription_provider.dart';

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

  /// After a successful purchase or restore — unlock UI and leave paywall.
  static void onPurchaseSuccess(BuildContext context, WidgetRef ref) {
    ref.read(isPremiumNotifierProvider.notifier).updatePremiumStatus(true);
    debugPrint('🔄 [DEBUG] PaywallNavigator: onPurchaseSuccess. Routing directly to /home.');
    context.go('/home');
  }

  /// Close without subscribing during an in-app paywall session.
  static void dismissInApp(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
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
      return path.contains('?') ? '$path&$inAppQueryKey=1' : '$path?$inAppQueryKey=1';
    }
    return path;
  }
}
