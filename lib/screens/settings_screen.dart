import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:physiq/services/auth_service.dart';
import 'package:physiq/services/user_repository.dart';
import 'package:physiq/utils/design_system.dart';
import 'package:physiq/widgets/settings/personal_details_sheet.dart';
import 'package:physiq/screens/macro_adjustment_screen.dart';
import 'package:physiq/screens/settings/weight_history_screen.dart';
import 'package:physiq/widgets/settings/preferences_sheet.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:physiq/widgets/header_widget.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static final Uri _termsOfServiceUri = Uri.parse(
    'https://sites.google.com/view/termsandcondition-physiqai/home',
  );
  static final Uri _privacyPolicyUri = Uri.parse(
    'https://sites.google.com/view/physiqai-privacy/home',
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    debugPrint('🏗️ SETTINGS_SCREEN: Building widget');
    // In a real app, we'd watch a user provider. For now, fetching stream.
    final authService = AuthService();
    final currentUser = authService.getCurrentUser();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              floating: false,
              backgroundColor: AppColors.background,
              scrolledUnderElevation: 0,
              elevation: 0,
              toolbarHeight: 70,
              titleSpacing: 0,
              title: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: HeaderWidget(title: 'Settings'),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 16.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24.0),
                      child: Text(
                        'Settings',
                        style: AppTextStyles.heading2.copyWith(fontSize: 24),
                      ),
                    ),

                    // 1. Invite Friend (Top-most tile)
                    // const SizedBox(height: 24), // Removed extra spacing as title has padding

                    // 2. Personal Details
                    _buildSectionItem(
                      icon: Icons.person_outline,
                      title: 'Personal Details',
                      subtitle:
                          'Goal: ${currentUser?.goalWeightKg ?? "--"}kg • Age: ${currentUser?.birthYear != null ? DateTime.now().year - currentUser!.birthYear! : "--"}',
                      onTap: () => _showPersonalDetails(context),
                    ),
                    const SizedBox(height: 32),

                    // 4. Adjust Macronutrients
                    _buildSectionItem(
                      icon: Icons.pie_chart_outline, // Changed icon
                      title: 'Adjust Macronutrients',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MacroAdjustmentScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 32),

                    // 5. Weight History
                    _buildSectionItem(
                      icon: Icons.history,
                      title: 'Weight History',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const WeightHistoryScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 32),

                    // 6. Preferences
                    _buildSectionItem(
                      icon: Icons.settings_outlined,
                      title: 'Preferences',
                      onTap: () => _showPreferences(context),
                    ),
                    const SizedBox(height: 48),

                    // 7. Legal & Support
                    Text('Legal & Support', style: AppTextStyles.heading2),
                    const SizedBox(height: 24),
                    _buildSectionItem(
                      icon: Icons.description_outlined,
                      title: 'Terms of Service',
                      onTap: () =>
                          _openExternalLink(context, _termsOfServiceUri),
                    ),
                    const SizedBox(height: 32),
                    _buildSectionItem(
                      icon: Icons.privacy_tip_outlined,
                      title: 'Privacy Policy',
                      onTap: () =>
                          _openExternalLink(context, _privacyPolicyUri),
                    ),
                    const SizedBox(height: 32),
                    _buildSectionItem(
                      icon: Icons.help_outline,
                      title: 'Support',
                      onTap: () => _showLegalDialog(
                        context,
                        'Support',
                        'Email us at support@physiq.app',
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildSectionItem(
                      icon: Icons.feedback_outlined,
                      title: 'Feature Request',
                      onTap: () => _showFeatureRequestDialog(context),
                    ),

                    const SizedBox(height: 48),

                    // 7. Logout & Delete
                    Center(
                      child: TextButton(
                        onPressed: () => _confirmLogout(context),
                        child: Text(
                          'Log out',
                          style: AppTextStyles.button.copyWith(
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ),
                    Center(
                      child: TextButton(
                        onPressed: () => _confirmDeleteAccount(context, ref),
                        child: Text(
                          'Delete account',
                          style: AppTextStyles.smallLabel.copyWith(
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        child: Row(
          children: [
            Icon(icon, size: 24, color: AppColors.primaryText),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.bodyMedium),
                  if (subtitle != null) ...[
                    const SizedBox(height: 6),
                    Text(subtitle, style: AppTextStyles.smallLabel),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.secondaryText),
          ],
        ),
      ),
    );
  }

  void _showPersonalDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const PersonalDetailsSheet(),
    );
  }

  void _showPreferences(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const PreferencesSheet(),
    );
  }

  void _showLegalDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _openExternalLink(BuildContext context, Uri uri) async {
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to open link. Please try again.'),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to open link. Please try again.'),
          ),
        );
      }
    }
  }

  void _confirmDeleteAccount(BuildContext context, WidgetRef ref) {
    debugPrint('🔍 DELETE_ACCOUNT: Button clicked');
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text('Are you sure? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () {
              debugPrint('🔍 DELETE_ACCOUNT: Dialog cancelled');
              Navigator.pop(dialogContext);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              debugPrint(
                '🔍 DELETE_ACCOUNT: Dialog confirmed, starting delete',
              );
              Navigator.pop(dialogContext);
              debugPrint('🔍 DELETE_ACCOUNT: Dialog closed');

              await Future.delayed(const Duration(milliseconds: 50));

              WidgetsBinding.instance.addPostFrameCallback((_) async {
                debugPrint(
                  '🔍 DELETE_ACCOUNT: Starting deletion after frame callback',
                );
                try {
                  final result = await ref
                      .read(userRepositoryProvider)
                      .deleteAccount();
                  debugPrint(
                    '🔍 DELETE_ACCOUNT: Firestore delete completed, result: $result',
                  );
                  await Future.delayed(const Duration(milliseconds: 500));
                  debugPrint('🔍 DELETE_ACCOUNT: All done');
                } catch (e) {
                  debugPrint('🔍 DELETE_ACCOUNT: Error during delete: $e');
                }
              });
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await AuthService().signOut();
              // Router will handle redirect
            },
            child: const Text('Log out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showFeatureRequestDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Feature Request'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Describe your idea...'),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Send request
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Request sent! Thank you.')),
              );
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }
}
