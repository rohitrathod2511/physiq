import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:physiq/theme/design_system.dart';
import 'package:physiq/services/auth_service.dart';
import 'package:physiq/services/user_repository.dart';
import 'package:physiq/widgets/settings/settings_widgets.dart';
import 'package:physiq/screens/settings/invite_friends_page.dart';
import 'package:physiq/screens/settings/personal_details_page.dart';
import 'package:physiq/screens/macro_adjustment_screen.dart';
import 'package:physiq/screens/settings/weight_history_screen.dart';
import 'package:physiq/providers/preferences_provider.dart';
import 'package:physiq/providers/onboarding_provider.dart';
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
  bool _isLoggingOut = false;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = themeNotifier.value == ThemeMode.dark;

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
                SliverPadding(
                  padding: const EdgeInsets.all(24.0),
                  sliver: SliverToBoxAdapter(
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
                            SettingsRow(
                              icon: isDarkMode
                                  ? Icons.brightness_2
                                  : Icons.wb_sunny,
                              title: 'Dark Mode',
                              showChevron: false,
                              trailing: Switch(
                                value: isDarkMode,
                                activeThumbColor: AppColors.primary,
                                onChanged: _handleThemeToggle,
                              ),
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

  void _handleThemeToggle(bool value) {
    final newMode = value ? ThemeMode.dark : ThemeMode.light;
    if (themeNotifier.value == newMode) {
      return;
    }

    // Defer the app-wide theme rebuild until the UX animations (InkSplash)
    // completely finish. This completely eliminates 1-frame _dependents.isEmpty 
    // assertion crashes caused by unmounting inherited themes mid-animation.
    Future.delayed(const Duration(milliseconds: 250), () {
      if (!mounted) {
        return;
      }
      themeNotifier.value = newMode;
      ref.read(preferencesProvider.notifier).setThemeMode(newMode);
    });
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
    if (_isDeletingAccount || _isLoggingOut) {
      return;
    }

    final result = await _showDeleteAccountDialog();

    if (result == null || result['confirmed'] != true || !mounted) {
      return;
    }

    setState(() {
      _isDeletingAccount = true;
    });

    // CRITICAL FIX: Allow the Dialog's Navigator.pop transition completely 
    // finish its animation frame BEFORE initiating auth state teardown. 
    // Prevents GoRouter from severing InheritedElements while mid-disposal.
    await Future.delayed(const Duration(milliseconds: 250));

    try {
      await _deleteAccountFlow(currentPassword: result['password'] as String?);
      // Stop here. Auth state teardown already drives the redirect away from
      // Settings, so touching UI after delete risks acting on a disposed tree.
      return;
    } catch (e) {
      debugPrint('Delete account failed: $e');
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_formatDeleteAccountError(e))));
      setState(() {
        _isDeletingAccount = false;
      });
    }
  }

  Future<Map<String, dynamic>?> _showDeleteAccountDialog() async {
    final user = _auth.currentUser;
    if (user == null) {
      _showErrorDialog('No authenticated user found.');
      return null;
    }

    final providerIds = user.providerData
        .map((provider) => provider.providerId)
        .where((providerId) => providerId.isNotEmpty)
        .toSet();
    final isEmailUser = providerIds.contains('password');
    final isGoogleUser = providerIds.contains('google.com');
    final confirmationController = TextEditingController();
    final passwordController = TextEditingController();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        bool obscurePassword = true;
        String? validationMessage;

        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            final isDeleteTextValid = confirmationController.text == 'DELETE';
            final hasPassword = passwordController.text.trim().isNotEmpty;
            final canSubmit =
                isDeleteTextValid && (!isEmailUser || hasPassword);

            return Dialog(
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
                        Text('Delete Account', style: AppTextStyles.heading2),
                        const SizedBox(height: 8),
                        Text(
                          'This will permanently delete your account, including all progress, history, photos, and data. This action cannot be undone.',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.secondaryText,
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: confirmationController,
                          textCapitalization: TextCapitalization.characters,
                          textInputAction: isEmailUser
                              ? TextInputAction.next
                              : TextInputAction.done,
                          onChanged: (value) {
                            setDialogState(() {
                              validationMessage =
                                  value.isEmpty || value == 'DELETE'
                                  ? null
                                  : 'Type DELETE exactly to continue.';
                            });
                          },
                          decoration: const InputDecoration(
                            labelText: 'Type DELETE to confirm',
                          ),
                        ),
                        if (isEmailUser || isGoogleUser) ...[
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                dialogContext,
                              ).inputDecorationTheme.fillColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Email',
                                  style: AppTextStyles.smallLabel.copyWith(
                                    color: AppColors.secondaryText,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  user.email ?? 'No email available',
                                  style: AppTextStyles.body,
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (isEmailUser) ...[
                          const SizedBox(height: 16),
                          TextField(
                            controller: passwordController,
                            obscureText: obscurePassword,
                            textInputAction: TextInputAction.done,
                            onChanged: (_) => setDialogState(() {}),
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
                        ] else if (isGoogleUser) ...[
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
                                onPressed: () => Navigator.pop(dialogContext, {
                                  'confirmed': false,
                                }),
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
                                onPressed: canSubmit
                                    ? () {
                                        Navigator.pop(dialogContext, {
                                          'confirmed': true,
                                          'password': isEmailUser
                                              ? passwordController.text.trim()
                                              : null,
                                        });
                                      }
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  disabledBackgroundColor: Colors.red
                                      .withOpacity(0.35),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                                child: Text(
                                  'Delete Account',
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
            );
          },
        );
      },
    );

    confirmationController.dispose();
    passwordController.dispose();
    return result;
  }

  Future<void> _deleteAccountFlow({String? currentPassword}) async {
    FocusManager.instance.primaryFocus?.unfocus();
    final onboardingStore = ref.read(onboardingProvider);
    final preferencesNotifier = ref.read(preferencesProvider.notifier);
    debugPrint('Delete account flow started.');
    await ref
        .read(userRepositoryProvider)
        .deleteAccount(currentPassword: currentPassword);
    await onboardingStore.clearDraft();
    await preferencesNotifier.clear();
    await AuthService().signOut();
  }

  String _formatDeleteAccountError(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '').trim();
    if (message.contains('re-login') || message.contains('re-authenticate')) {
      return 'Please re-login to confirm deletion.';
    }
    if (message.contains('network') || message.contains('unavailable')) {
      return 'Something went wrong. Please try again.';
    }
    if (message.isEmpty) {
      return 'Something went wrong. Please try again.';
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
                        if (_isLoggingOut || _isDeletingAccount) {
                          return;
                        }

                        setState(() {
                          _isLoggingOut = true;
                        });
                        Navigator.pop(ctx);
                        try {
                          await _clearLocalSessionState();
                          await AuthService().signOut();
                        } catch (e) {
                          debugPrint('Logout failed: $e');
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Something went wrong. Please try again.',
                                ),
                              ),
                            );
                          }
                        } finally {
                          if (mounted) {
                            setState(() {
                              _isLoggingOut = false;
                            });
                          }
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

  Future<void> _clearLocalSessionState() async {
    await ref.read(onboardingProvider).clearDraft();
    ref.invalidate(onboardingProvider);
    await ref.read(preferencesProvider.notifier).clear();
  }
}
