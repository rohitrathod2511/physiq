
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:physiq/theme/design_system.dart';

class MotivationalQuoteScreen extends StatelessWidget {
  const MotivationalQuoteScreen({super.key});

  final List<Map<String, String>> _quotes = const [
    {
      'quote': 'Talent without working hard is nothing.',
      'author': 'Cristiano Ronaldo',
      'desc': 'Discipline & Consistency',
    },
    {
      'quote': 'Success starts with self-discipline.',
      'author': 'Dwayne Johnson',
      'desc': 'Work Ethic & Fitness',
    },
    {
      'quote': 'Self-belief and hard work will always earn you success.',
      'author': 'Virat Kohli',
      'desc': 'Lifestyle & Mindset',
    },
    {
      'quote': 'Strength comes from overcoming the things you thought you couldn\'t.',
      'author': 'Arnold Schwarzenegger',
      'desc': 'Bodybuilding Legend',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),
                    // Global Fitness Icon / Visual
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.05),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.emoji_events_rounded, size: 48, color: Colors.black),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Title
                    Text(
                      "How the world’s most successful leaders stay unstoppable",
                      style: AppTextStyles.h1.copyWith(fontSize: 26, height: 1.3),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    
                    // Subtitle
                    Text(
                      "Discipline is the bridge between goals and accomplishment.",
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.secondaryText,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),

                    // Quotes
                    ..._quotes.map((q) => _buildQuoteCard(q)),
                  ],
                ),
              ),
            ),
            
            // Bottom Button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.push('/onboarding/paywall-free'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuoteCard(Map<String, String> data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // Align text to start for better reading
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '"',
                style: AppTextStyles.h1.copyWith(fontSize: 40, color: Colors.grey.shade300, height: 0.5),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8.0, left: 8.0),
                  child: Text(
                    data['quote']!,
                    style: AppTextStyles.h3.copyWith(fontSize: 18, height: 1.4, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "- ${data['author']}",
                  style: AppTextStyles.bodyBold.copyWith(fontSize: 14),
                ),
                if (data['desc'] != null)
                  Text(
                    data['desc']!,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
