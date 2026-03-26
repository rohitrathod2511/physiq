import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:physiq/theme/design_system.dart';

class SuccessStoriesScreen extends StatefulWidget {
  const SuccessStoriesScreen({super.key});

  @override
  State<SuccessStoriesScreen> createState() => _SuccessStoriesScreenState();
}

class _SuccessStoriesScreenState extends State<SuccessStoriesScreen> {
  static const _starColor = Color(0xFFFFC107);
  static const _checkColor = Color(0xFF4CAF50);
  static const _avatarBorderColor = Colors.white;
  static const _rotationInterval = Duration(seconds: 3);
  static const _transitionDuration = Duration(milliseconds: 550);

  final List<_StoryReview> _reviews = const [
    _StoryReview(
      title: 'I impressed my doctor',
      text:
          "Managing my health used to be a nightmare. My labs improved because I finally know exactly what I'm eating.",
    ),
    _StoryReview(
      title: 'Finally gained healthy weight',
      text:
          'I struggled to gain weight for years. This app gave me a clear plan and tracking. I gained 6kg in 2 months.',
    ),
    _StoryReview(
      title: 'Lost 10kg without stress',
      text:
          'No crash dieting. Just consistency. The AI tracking made everything simple and I stayed on track.',
    ),
    _StoryReview(
      title: "Best fitness app I've used",
      text:
          'Tried many apps before, but this one actually works. The UI, tracking, and reminders are perfect.',
    ),
    _StoryReview(
      title: 'Now I understand my body',
      text:
          'I never realized how much I was eating wrong. Now I feel more energetic and in control.',
    ),
  ];

  final List<_AvatarProfile> _profiles = const [
    _AvatarProfile(
      name: 'Mia',
      imageUrl: 'https://i.pravatar.cc/120?img=32',
      fallbackColor: Color(0xFFE8C6A8),
    ),
    _AvatarProfile(
      name: 'Ethan',
      imageUrl: 'https://i.pravatar.cc/120?img=15',
      fallbackColor: Color(0xFFC9D5E8),
    ),
    _AvatarProfile(
      name: 'Noah',
      imageUrl: 'https://i.pravatar.cc/120?img=58',
      fallbackColor: Color(0xFFD7C6E8),
    ),
    _AvatarProfile(
      name: 'Ava',
      imageUrl: 'https://i.pravatar.cc/120?img=47',
      fallbackColor: Color(0xFFF0D7C6),
    ),
  ];

  Timer? _rotationTimer;
  int _currentReviewIndex = 0;

  @override
  void initState() {
    super.initState();
    _rotationTimer = Timer.periodic(_rotationInterval, (_) {
      if (!mounted) return;
      setState(() {
        _currentReviewIndex = (_currentReviewIndex + 1) % _reviews.length;
      });
    });
  }

  @override
  void dispose() {
    _rotationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final review = _reviews[_currentReviewIndex];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: AppColors.primaryText),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    _buildHeader(),
                    const SizedBox(height: 26),
                    _buildStars(size: 24),
                    const SizedBox(height: 14),
                    Text(
                      'Thousands of users reaching their goals',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.secondaryText,
                      ),
                    ),
                    const SizedBox(height: 30),
                    _buildAvatarStack(),
                    const SizedBox(height: 24),
                    Text(
                      '+10K users with Physiq AI',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyBold,
                    ),
                    const SizedBox(height: 28),
                    _buildReviewCard(review),
                    const SizedBox(height: 18),
                    _buildIndicatorDots(),
                    const SizedBox(height: 28),
                    _buildSuccessIndicator(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            _buildBottomButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Text(
      'Success Stories',
      textAlign: TextAlign.center,
      style: AppTextStyles.h1,
    );
  }

  Widget _buildStars({required double size}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        5,
        (index) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Icon(Icons.star_rounded, size: size, color: _starColor),
        ),
      ),
    );
  }

  Widget _buildAvatarStack() {
    const avatarSize = 42.0;
    const overlap = 12.0;

    return SizedBox(
      width: avatarSize + ((_profiles.length - 1) * (avatarSize - overlap)),
      height: avatarSize + 8,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (int i = 0; i < _profiles.length; i++)
            Positioned(
              left: i * (avatarSize - overlap),
              child: _AvatarBubble(profile: _profiles[i], size: avatarSize),
            ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(_StoryReview review) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 420),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [AppShadows.card],
      ),
      child: AnimatedSwitcher(
        duration: _transitionDuration,
        switchInCurve: Curves.easeInOutCubic,
        switchOutCurve: Curves.easeInOutCubic,
        layoutBuilder: (currentChild, previousChildren) {
          return Stack(
            alignment: Alignment.topCenter,
            children: [
              ...previousChildren,
              if (currentChild != null) currentChild,
            ],
          );
        },
        transitionBuilder: (child, animation) {
          final isIncoming =
              (child.key as ValueKey<int>).value == _currentReviewIndex;
          final offsetTween = isIncoming
              ? Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
              : Tween<Offset>(begin: Offset.zero, end: const Offset(0, -0.12));

          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: offsetTween.animate(
                CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeInOutCubic,
                ),
              ),
              child: child,
            ),
          );
        },
        child: Column(
          key: ValueKey<int>(_currentReviewIndex),
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStars(size: 16),
            const SizedBox(height: 14),
            Text(review.title, style: AppTextStyles.bodyBold),
            const SizedBox(height: 12),
            Text(
              review.text,
              style: AppTextStyles.body.copyWith(
                color: AppColors.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIndicatorDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _reviews.length,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: index == _currentReviewIndex ? 20 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: index == _currentReviewIndex
                ? Colors.black
                : Colors.black.withOpacity(0.14),
            borderRadius: BorderRadius.circular(99),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessIndicator() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 420),
      padding: const EdgeInsets.symmetric(vertical: 26),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Center(
        child: Container(
          width: 78,
          height: 78,
          decoration: const BoxDecoration(
            color: _checkColor,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_rounded, color: Colors.white, size: 42),
        ),
      ),
    );
  }

  Widget _buildBottomButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
      color: AppColors.background,
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => context.push('/onboarding/notification'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: const Text('Continue'),
        ),
      ),
    );
  }
}

class _AvatarBubble extends StatelessWidget {
  const _AvatarBubble({required this.profile, required this.size});

  final _AvatarProfile profile;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: _SuccessStoriesScreenState._avatarBorderColor,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 6),
            spreadRadius: -6,
          ),
        ],
      ),
      child: ClipOval(
        child: Image.network(
          profile.imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) {
            return Container(
              color: profile.fallbackColor,
              alignment: Alignment.center,
              child: Text(
                profile.name.substring(0, 1),
                style: AppTextStyles.bodyBold.copyWith(
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _StoryReview {
  const _StoryReview({required this.title, required this.text});

  final String title;
  final String text;
}

class _AvatarProfile {
  const _AvatarProfile({
    required this.name,
    required this.imageUrl,
    required this.fallbackColor,
  });

  final String name;
  final String imageUrl;
  final Color fallbackColor;
}
