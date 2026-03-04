import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:physiq/theme/design_system.dart';
import 'package:physiq/services/auth_service.dart';
import 'package:physiq/services/user_repository.dart';
import 'package:physiq/widgets/settings/settings_widgets.dart';
import 'package:physiq/screens/settings/invite_friends_page.dart';
import 'package:physiq/screens/settings/personal_details_page.dart';
import 'package:physiq/screens/macro_adjustment_screen.dart';
import 'package:physiq/screens/settings/weight_history_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:physiq/providers/preferences_provider.dart';
import 'package:physiq/services/support_service.dart';
import 'package:physiq/services/cloud_functions_client.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:physiq/widgets/header_widget.dart';
import 'package:physiq/main.dart';
// Localizations import removed

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  static final Uri _termsOfServiceUri = Uri.parse(
    'https://sites.google.com/view/termsandcondition-physiqai/home',
  );
  static final Uri _privacyPolicyUri = Uri.parse(
    'https://sites.google.com/view/physiqai-privacy/home',
  );

  final _supportService = SupportService();
  final _cloudFunctions = CloudFunctionsClient();
  final _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    final prefsState = ref.watch(preferencesProvider);
    final isDarkMode = prefsState.themeMode == ThemeMode.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              floating: false,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              scrolledUnderElevation: 0,
              elevation: 0,
              toolbarHeight: 80,
              titleSpacing: 0,
              title: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0),
                child: HeaderWidget(
                  title: 'Settings',
                  showActions: false,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    // Invite Banner
                    InviteBannerCard(
                      onInviteTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const InviteFriendsPage(),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Personal & Preferences
                    SettingsCard(
                      padding: EdgeInsets.zero,
                      child: _buildSettingsList([
                        SettingsRow(
                          icon: Icons.person,
                          title: 'Personal Details',
                          showChevron: false,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PersonalDetailsPage(),
                            ),
                          ),
                        ),
                        SettingsRow(
                          icon: Icons.tune,
                          title: 'Adjust Macronutrients',
                          showChevron: false,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const MacroAdjustmentScreen(),
                            ),
                          ),
                        ),
                        SettingsRow(
                          icon: Icons.history,
                          title: 'Weight History',
                          showChevron: false,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const WeightHistoryScreen(),
                            ),
                          ),
                        ),

                        ValueListenableBuilder<ThemeMode>(
                          valueListenable: themeNotifier,
                          builder: (context, mode, child) {
                            final isDark = mode == ThemeMode.dark;
                            return SettingsRow(
                              icon: isDark
                                  ? Icons.brightness_2
                                  : Icons.wb_sunny,
                              title: 'Dark Mode',
                              showChevron: false,
                              trailing: Switch(
                                value: isDark,
                                activeColor: AppColors.primary,
                                onChanged: (val) async {
                                  final newMode = val
                                      ? ThemeMode.dark
                                      : ThemeMode.light;
                                  themeNotifier.value = newMode;
                                  await ref
                                      .read(preferencesProvider.notifier)
                                      .setThemeMode(newMode);
                                },
                              ),
                            );
                          },
                        ),
                      ]),
                    ),

                    // Legal, Support & Delete
                    SettingsCard(
                      padding: EdgeInsets.zero,
                      child: _buildSettingsList([
                        SettingsRow(
                          icon: Icons.description_outlined,
                          title: 'Terms of Service',
                          showChevron: false,
                          onTap: openTermsOfService,
                        ),
                        SettingsRow(
                          icon: Icons.privacy_tip_outlined,
                          title: 'Privacy Policy',
                          showChevron: false,
                          onTap: openPrivacyPolicy,
                        ),
                        SettingsRow(
                          icon: Icons.mail_outline,
                          title: 'Support',
                          showChevron: false,
                          onTap: _sendSupportEmail,
                        ),

                        SettingsRow(
                          icon: Icons.delete_outline,
                          title: 'Delete account',
                          titleColor: Colors.red,
                          showChevron: false,
                          onTap: _confirmDeleteAccount,
                        ),
                      ]),
                    ),

                    // Logout
                    SettingsCard(
                      padding: EdgeInsets.zero,
                      child: SettingsRow(
                        icon: Icons.logout,
                        title: 'Log out',
                        showChevron: false,
                        onTap: _confirmLogout,
                      ),
                    ),

                    const SizedBox(height: 20),
                    FutureBuilder<PackageInfo>(
                      future: PackageInfo.fromPlatform(),
                      builder: (context, snapshot) {
                        final version = snapshot.data?.version ?? '1.0.0';
                        return Text(
                          'Version $version',
                          style: AppTextStyles.smallLabel,
                        );
                      },
                    ),
                    const SizedBox(height: 80), // Bottom padding
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsList(List<Widget> rows) {
    final List<Widget> children = [];
    for (int i = 0; i < rows.length; i++) {
      children.add(rows[i]);
      if (i < rows.length - 1) {
        children.add(
          const Divider(
            height: 1,
            color: Color(0xFFF1F1F3),
            indent: 16,
            endIndent: 16,
          ),
        );
      }
    }
    return Column(children: children);
  }



  Future<void> _sendSupportEmail() async {
    try {
      await _supportService.openSupportEmail();
    } catch (e) {
      if (mounted) _showErrorDialog('Could not launch email client: $e');
    }
  }

  Future<void> openTermsOfService() async {
    await _openExternalLink(_termsOfServiceUri);
  }

  Future<void> openPrivacyPolicy() async {
    await _openExternalLink(_privacyPolicyUri);
  }

  Future<void> _openExternalLink(Uri uri) async {
    try {
      final opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to open link. Please try again.'),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to open link. Please try again.'),
          ),
        );
      }
    }
  }

  void _showFeatureRequestDialog() {
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
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                Navigator.pop(context);
                try {
                  final uid = _auth.currentUser?.uid;
                  if (uid != null) {
                    await _supportService.submitFeatureRequest(
                      uid,
                      'Feature Request',
                      controller.text,
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Request sent! Thank you.'),
                        ),
                      );
                    }
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please log in to submit requests.'),
                        ),
                      );
                    }
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to send request: $e')),
                    );
                  }
                }
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.bigCard),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Delete account',
                style: AppTextStyles.heading2,
              ),
              const SizedBox(height: 8),
              Text(
                'Are you sure you want to permanently delete all your data? This cannot be undone.',
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.secondaryText,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(
                        'Cancel',
                        style: AppTextStyles.button.copyWith(
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (_) =>
                              const Center(child: CircularProgressIndicator()),
                        );

                        try {
                          final uid = _auth.currentUser?.uid;
                          if (uid != null) {
                            await ref
                                .read(userRepositoryProvider)
                                .deleteUserData(uid);
                            await ref
                                .read(preferencesProvider.notifier)
                                .clear();

                            await AuthService().deleteUser();

                            if (mounted) {
                              Navigator.pop(context);
                              context.go('/get-started');
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Account deleted successfully'),
                                ),
                              );
                            }
                          }
                        } catch (e) {
                          if (mounted) {
                            Navigator.pop(context);
                            _showErrorDialog(e.toString());
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        'Delete',
                        style: AppTextStyles.button.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.bigCard),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.logout, color: AppColors.primary, size: 32),
              ),
              const SizedBox(height: 16),
              Text('Log out', style: AppTextStyles.heading2),
              const SizedBox(height: 8),
              Text(
                'Are you sure you want to log out?',
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.secondaryText,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(
                        'Cancel',
                        style: AppTextStyles.button.copyWith(
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await ref.read(preferencesProvider.notifier).clear();
                        await AuthService().signOut();
                        if (mounted) {
                          context.go('/get-started');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        'Log out',
                        style: AppTextStyles.button.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}
