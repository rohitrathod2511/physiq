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
  bool _isDeletingAccount = false;

  @override
  Widget build(BuildContext context) {
    final prefsState = ref.watch(preferencesProvider);
    final isDarkMode = prefsState.themeMode == ThemeMode.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          SafeArea(
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
                    child: HeaderWidget(title: 'Settings', showActions: false),
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
          if (_isDeletingAccount) ...[
            const Positioned.fill(
              child: IgnorePointer(child: ColoredBox(color: Color(0x66000000))),
            ),
            const Positioned.fill(
              child: Center(child: CircularProgressIndicator()),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSettingsList(List<Widget> rows) {
    final List<Widget> children = [];
    for (int i = 0; i < rows.length; i++) {
      children.add(rows[i]);
      if (i < rows.length - 1) {
        children.add(
          Divider(
            height: 1,
            color: Theme.of(context).dividerColor.withOpacity(0.3),
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
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
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

  Future<void> _confirmDeleteAccount() async {
    if (_isDeletingAccount) {
      return;
    }

    final user = _auth.currentUser;
    if (user == null) {
      _showErrorDialog('No authenticated user found.');
      return;
    }

    // We only ask for the credential type that can actually re-authenticate this user.
    final providerIds = user.providerData
        .map((provider) => provider.providerId)
        .where((providerId) => providerId.isNotEmpty)
        .toSet();
    final requiresPassword = providerIds.contains('password');
    final usesGoogle = providerIds.contains('google.com');

    final confirmationController = TextEditingController();
    final passwordController = TextEditingController();

    final request = await showDialog<_DeleteAccountRequest>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        bool obscurePassword = true;
        bool isSubmitting = false;
        String? validationMessage;

        return StatefulBuilder(
          builder: (dialogContext, setDialogState) => Dialog(
            backgroundColor: AppColors.background,
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 24,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.bigCard),
            ),
            child: AnimatedPadding(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(dialogContext).bottom,
              ),
              child: SingleChildScrollView(
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
                      Text('Delete account', style: AppTextStyles.heading2),
                      const SizedBox(height: 8),
                      Text(
                        'This permanently deletes your account, profile, meal history, progress photos, cloud-stored images, and related Firebase data. This cannot be undone.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.secondaryText,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Typed confirmation reduces accidental destructive actions.
                      TextField(
                        controller: confirmationController,
                        textCapitalization: TextCapitalization.characters,
                        textInputAction: requiresPassword
                            ? TextInputAction.next
                            : TextInputAction.done,
                        decoration: const InputDecoration(
                          labelText: 'Type DELETE to confirm',
                        ),
                      ),
                      if (requiresPassword) ...[
                        const SizedBox(height: 16),
                        TextField(
                          controller: passwordController,
                          obscureText: obscurePassword,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) async {
                            FocusScope.of(dialogContext).unfocus();
                          },
                          decoration: InputDecoration(
                            labelText: 'Current password',
                            suffixIcon: IconButton(
                              onPressed: () => setDialogState(() {
                                obscurePassword = !obscurePassword;
                              }),
                              icon: Icon(
                                obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                            ),
                          ),
                        ),
                      ] else if (usesGoogle) ...[
                        const SizedBox(height: 16),
                        Text(
                          'You will be asked to re-authenticate with Google before the account is deleted.',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.smallLabel.copyWith(
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ],
                      if (validationMessage != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          validationMessage!,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.smallLabel.copyWith(
                            color: Colors.red,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: isSubmitting
                                  ? null
                                  : () => Navigator.pop(ctx),
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
                                if (isSubmitting) {
                                  return;
                                }

                                final typedConfirmation = confirmationController
                                    .text
                                    .trim()
                                    .toUpperCase();
                                final password = passwordController.text.trim();

                                if (typedConfirmation != 'DELETE') {
                                  setDialogState(() {
                                    validationMessage =
                                        'Type DELETE exactly to continue.';
                                  });
                                  return;
                                }

                                if (requiresPassword && password.isEmpty) {
                                  setDialogState(() {
                                    validationMessage =
                                        'Enter your current password to continue.';
                                  });
                                  return;
                                }

                                setDialogState(() {
                                  isSubmitting = true;
                                  validationMessage = null;
                                });

                                FocusScope.of(dialogContext).unfocus();
                                await Future<void>.delayed(
                                  const Duration(milliseconds: 150),
                                );
                                if (!dialogContext.mounted) return;

                                Navigator.of(
                                  dialogContext,
                                  rootNavigator: true,
                                ).pop(
                                  _DeleteAccountRequest(
                                    currentPassword: requiresPassword
                                        ? password
                                        : null,
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
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
            ),
          ),
        );
      },
    );

    confirmationController.dispose();
    passwordController.dispose();

    if (request == null || !mounted) {
      return;
    }

    await _deleteAccount(currentPassword: request.currentPassword);
  }

  Future<void> _deleteAccount({String? currentPassword}) async {
    if (_isDeletingAccount) {
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _isDeletingAccount = true;
    });

    final scaffoldMessenger = ScaffoldMessenger.maybeOf(context);

    try {
      final message = await ref
          .read(userRepositoryProvider)
          .deleteAccount(currentPassword: currentPassword);

      if (!mounted) return;
      await ref.read(preferencesProvider.notifier).clear();

      if (!mounted) return;
      scaffoldMessenger?.hideCurrentSnackBar();
      scaffoldMessenger?.showSnackBar(SnackBar(content: Text(message)));

      await Future<void>.delayed(const Duration(milliseconds: 350));
      if (!mounted) return;

      await AuthService().signOut();
      if (!mounted) return;
    } catch (e) {
      if (!mounted) return;
      scaffoldMessenger?.hideCurrentSnackBar();
      scaffoldMessenger?.showSnackBar(
        SnackBar(content: Text(_formatDeleteAccountError(e))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDeletingAccount = false;
        });
      }
    }
  }

  String _formatDeleteAccountError(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '').trim();
    if (message.isEmpty) {
      return 'Failed to delete your account. Please try again.';
    }
    return message;
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
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('OK')),
        ],
      ),
    );
  }
}

class _DeleteAccountRequest {
  const _DeleteAccountRequest({this.currentPassword});

  final String? currentPassword;
}
