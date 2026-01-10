import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:physiq/theme/design_system.dart';
import 'package:physiq/services/user_repository.dart';
import 'package:physiq/widgets/settings/settings_widgets.dart';
import 'package:physiq/screens/settings/edit_personal_details_pages.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PersonalDetailsPage extends ConsumerWidget {
  const PersonalDetailsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final userAsync = ref.watch(userStreamProvider(uid ?? ''));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Personal Details', style: AppTextStyles.heading2),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: AppColors.primaryText),
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) return const Center(child: Text('User not found'));
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _buildDetailCard(
                  context,
                  title: 'Goal Weight',
                  value: '${user.goalWeightKg} kg',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EditGoalWeightPage(initialValue: user.goalWeightKg.toDouble()))),
                ),
                _buildDetailCard(
                  context,
                  title: 'Current Weight',
                  value: '${user.weightKg} kg',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EditHeightWeightPage(initialHeight: user.heightCm.toDouble(), initialWeight: user.weightKg.toDouble()))),
                ),
                _buildDetailCard(
                  context,
                  title: 'Height',
                  value: '${user.heightCm} cm',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EditHeightWeightPage(initialHeight: user.heightCm.toDouble(), initialWeight: user.weightKg.toDouble()))),
                ),
                _buildDetailCard(
                  context,
                  title: 'Birth Year',
                  value: '${user.birthYear}',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EditBirthYearPage(initialYear: user.birthYear))),
                ),
                _buildDetailCard(
                  context,
                  title: 'Gender',
                  value: user.gender,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EditGenderPage(initialGender: user.gender))),
                ),
                _buildDetailCard(
                  context,
                  title: 'Daily Step Goal',
                  value: '${user.dailyStepGoal ?? 10000} steps',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EditStepGoalPage(initialGoal: user.dailyStepGoal ?? 10000))),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildDetailCard(BuildContext context, {required String title, required String value, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadii.card),
        boxShadow: [AppShadows.card],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.card),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.label),
                    const SizedBox(height: 4),
                    Text(value, style: AppTextStyles.heading2),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.edit, size: 16, color: AppColors.primaryText),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final userStreamProvider = StreamProvider.family<dynamic, String>((ref, uid) {
  if (uid.isEmpty) return Stream.value(null);
  return ref.read(userRepositoryProvider).streamUser(uid);
});
