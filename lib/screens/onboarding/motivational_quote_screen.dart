
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:physiq/theme/design_system.dart';

class MotivationalQuoteScreen extends StatelessWidget {
  const MotivationalQuoteScreen({super.key});

  final List<Map<String, String>> _quotes = const [
    {
      'quote': 'Take action today — transform tomorrow.',
      'author': 'Cristiano Ronaldo',
    },
    {
      'quote': 'Success starts with self-discipline.',
      'author': 'Dwayne Johnson',
    },
    {
      'quote': 'Believe in yourself and anything is possible.',
      'author': 'Virat Kohli',
    },
    {
      'quote': 'There is no talent here, this is hard work.',
      'author': 'Conor McGregor',
    },
    {
      'quote': 'I trained 4 years to run 9 seconds.',
      'author': 'Usain Bolt',
    },
    {
      'quote': 'Strength does not come from winning.',
      'author': 'Arnold Schwarzenegger',
    },
    {
      'quote': 'Discipline is doing what you hate to do, but doing it like you love it.',
      'author': 'Mike Tyson',
    },
    {
      'quote': 'Be water, my friend.',
      'author': 'Bruce Lee',
    },
    {
      'quote': 'Dedication makes dreams come true.',
      'author': 'Kobe Bryant',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(24),
                itemCount: _quotes.length,
                itemBuilder: (context, index) {
                  final quote = _quotes[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppRadii.card),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          '"${quote['quote']}"',
                          style: AppTextStyles.h2.copyWith(fontSize: 20),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '- ${quote['author']}',
                          style: AppTextStyles.bodyBold.copyWith(color: AppColors.secondaryText),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.push('/onboarding/paywall-main'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text('Start Your Journey'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
