import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:physiq/theme/design_system.dart';
import 'package:physiq/services/promo_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';

class InviteFriendsPage extends StatefulWidget {
  const InviteFriendsPage({super.key});

  @override
  State<InviteFriendsPage> createState() => _InviteFriendsPageState();
}

class _InviteFriendsPageState extends State<InviteFriendsPage> {
  String _promoCode = 'LOADING';
  final _promoService = PromoService();
  final _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _loadPromoCode();
  }

  Future<void> _loadPromoCode() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    
    try {
      final code = await _promoService.ensurePromoCode(uid);
      if (mounted) {
        setState(() {
          _promoCode = code;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading code: $e')),
        );
      }
    }
  }

  void _copyCode() {
    Clipboard.setData(ClipboardData(text: _promoCode));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Promo code copied to clipboard!')),
    );
  }

  void _shareCode() {
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      _promoService.logInviteShare(uid, _promoCode);
    }
    Share.share('Join me on Physiq! Use my code $_promoCode to earn rewards. Download here: https://physiq.app/invite/$_promoCode');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Invite Friends', style: AppTextStyles.heading2),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: AppColors.primaryText),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Text(
              'Share this code with friends to earn rewards',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.secondaryText),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(AppRadii.bigCard),
                boxShadow: [AppShadows.card],
              ),
              child: Column(
                children: [
                  Text('YOUR PROMO CODE', style: AppTextStyles.smallLabel),
                  const SizedBox(height: 16),
                  Text(
                    _promoCode,
                    style: AppTextStyles.heading1.copyWith(
                      fontSize: 40,
                      letterSpacing: 4,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton.icon(
                        onPressed: _copyCode,
                        icon: const Icon(Icons.copy, size: 20),
                        label: const Text('Copy'),
                        style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _promoCode == 'LOADING' ? null : _shareCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text('Share Code', style: AppTextStyles.button.copyWith(color: Colors.white)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
