
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:physiq/theme/design_system.dart';

class MotivationalQuoteScreen extends StatefulWidget {
  const MotivationalQuoteScreen({super.key});

  @override
  State<MotivationalQuoteScreen> createState() => _MotivationalQuoteScreenState();
}

class _MotivationalQuoteScreenState extends State<MotivationalQuoteScreen> {
  int _currentIndex = 0;
  Timer? _timer;

  // Leaders Order: Cristiano Ronaldo -> Arnold Schwarzenegger -> Dwayne Johnson -> Virat Kohli -> David Goggins -> Conor McGregor
  final List<Map<String, String>> _quotes = const [
    {
      'author': 'Cristiano Ronaldo',
      'quote': '“I train my body every day because discipline is everything.”',
    },
    {
      'author': 'Arnold Schwarzenegger',
      'quote': '“The body you build reflects the discipline you live by.”',
    },
    {
      'author': 'Dwayne Johnson',
      'quote': '“Consistency and discipline separate good from great.”',
    },
    {
      'author': 'Virat Kohli',
      'quote': '“Fitness gives me the mental edge to perform under pressure.”',
    },
    {
      'author': 'David Goggins',
      'quote': '“You are not going to find your limit in one workout.”',
    },
    {
      'author': 'Conor McGregor',
      'quote': '“Excellence is not a singular act but a habit. You are what you do repeatedly.”',
    },
  ];

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    // Change every 3 seconds (User requested 2.5-3 seconds)
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted) return;
      setState(() {
        _currentIndex = (_currentIndex + 1) % _quotes.length;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: AppColors.primaryText),
      ),
      body: SafeArea(
        // "Content sits directly on screen background"
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            // "Center everything vertically (balanced layout)" -> using Spacers
            children: [
               // 1. MAIN TITLE (CENTERED, POWERFUL)
               // "At the top center (below back button)"
              const SizedBox(height: 10),
              Text(
                "Highly successful people train their body as seriously as their mind",
                style: AppTextStyles.heading1.copyWith(
                  fontSize: 28, 
                  height: 1.2,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              
              // Subtitle REMOVED per user request

              const SizedBox(height: 16), // Less breathing room needed since subtitle is gone

              const SizedBox(height: 32), // Breathing room

              // 2. SUPPORTING MESSAGE (SHORT, CONVINCING)
              // EMPHASIZE THIS LINE (ATTENTION GRABBER) - RED
              Text(
                "“The world’s top performers track their routines, protect their health, and stay disciplined every single day.”",
                style: AppTextStyles.bodyBold.copyWith(
                  color: AppColors.primaryText, // Changed from Black/Red to primaryText
                  fontSize: 18, 
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w500, // Medium
                  letterSpacing: 0.5, // Slightly relaxed
                  height: 1.4, // Comfortable & readable
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              // BENEFIT-ORIENTED LINE (POSITIVE SIGNAL) - GREEN
              Text(
                "“This app helps you build the same habits automatically.”",
                style: AppTextStyles.bodyMedium.copyWith(
                  color: const Color(0xFF2E7D32), // Keeping Green as requested
                  fontSize: 19, 
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w500, // Medium
                  letterSpacing: 0.5, // Slightly relaxed
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              
              const Spacer(), // Pushes content to distribute space

              // 3. SUCCESS LEADER QUOTES (AUTO-ROTATING, NO SCROLL)
              // Display it inside a card, same style as other cards in the app
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(AppRadii.card),
                  boxShadow: [AppShadows.card],
                ),
                child: SizedBox(
                  height: 140, // Fixed height to prevent layout shifts (Jitter)
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 600), // Smooth fade
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                    child: Column(
                      key: ValueKey<int>(_currentIndex), // Triggers animation
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Leader Name
                        Text(
                          _quotes[_currentIndex]['author']!,
                          style: AppTextStyles.heading2.copyWith(
                            fontSize: 22,
                            color: AppColors.primaryText, // Changed from Black
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        // Quote Text
                        Text(
                          _quotes[_currentIndex]['quote']!,
                          style: AppTextStyles.h3.copyWith(
                            fontSize: 18,
                            fontStyle: FontStyle.italic,
                            color: AppColors.secondaryText,
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const Spacer(),

              // 5. PRE-CALL-TO-ACTION MESSAGE (JUST ABOVE BUTTON)
              Text(
                "“You’re about to train like these high performers do.”",
                style: AppTextStyles.bodyMedium.copyWith(
                  fontSize: 16,
                  color: const Color(0xFFD32F2F), // Red
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w500, // Medium
                  letterSpacing: 0.5, // Slightly relaxed
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // 5. CONTINUE BUTTON (UNCHANGED)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.push('/onboarding/paywall-free'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary, // AppColors.primary
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 5,
                    shadowColor: Colors.black.withOpacity(0.3),
                  ),
                  child: const Text(
                    'Start Your Journey', 
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
