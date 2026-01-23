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
        title: Text('Personal details', style: AppTextStyles.heading2),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: AppColors.primaryText),
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) return const Center(child: Text('User not found'));
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Goal Card
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EditGoalWeightPage(initialValue: (user.goalWeightKg ?? 70.0).toDouble()))),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(AppRadii.card),
                        boxShadow: [AppShadows.card],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Goal Weight', style: AppTextStyles.label.copyWith(fontSize: 16)),
                              const SizedBox(height: 8),
                              Text('${(user.goalWeightKg ?? 0).toInt()} kg', style: AppTextStyles.heading2),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Change Goal',
                              style: AppTextStyles.button.copyWith(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ),
                const SizedBox(height: 20),

                // Details Card
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(AppRadii.card),
                    boxShadow: [AppShadows.card],
                  ),
                  child: Column(
                    children: [
                       _buildRow(
                        context,
                        title: 'Name',
                        value: user.displayName.isEmpty ? 'Set Name' : user.displayName,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EditNamePage(initialName: user.displayName))),
                        isFirst: true,
                      ),
                      _buildDivider(),
                      _buildRow(
                        context,
                        title: 'Current Weight',
                        value: '${(user.weightKg ?? 0).toInt()} kg',
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EditHeightWeightPage(initialHeight: (user.heightCm ?? 170.0).toDouble(), initialWeight: (user.weightKg ?? 70.0).toDouble()))),
                      ),
                      _buildDivider(),
                      _buildRow(
                        context,
                        title: 'Height',
                        value: '${(user.heightCm ?? 0).round()} cm',
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EditHeightWeightPage(initialHeight: (user.heightCm ?? 170.0).toDouble(), initialWeight: (user.weightKg ?? 70.0).toDouble()))),
                      ),
                       _buildDivider(),
                      _buildRow(
                        context,
                        title: 'Date of birth',
                        value: _formatDOB(user.birthDay, user.birthMonth, user.birthYear),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EditDOBPage(
                          initialYear: user.birthYear ?? 2000,
                          initialMonth: user.birthMonth ?? 1,
                          initialDay: user.birthDay ?? 1,
                        ))),
                      ),
                       _buildDivider(),
                      _buildRow(
                        context,
                        title: 'Gender',
                        value: user.gender ?? 'Select',
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EditGenderPage(initialGender: user.gender ?? 'Male'))),
                      ),
                       _buildDivider(),
                      _buildRow(
                        context,
                        title: 'Daily Step Goal',
                        value: '${user.dailyStepGoal ?? 10000} steps',
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EditStepGoalPage(initialGoal: user.dailyStepGoal ?? 10000))),
                        isLast: true,
                      ),
                    ],
                  ),
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

  Widget _buildRow(BuildContext context, {required String title, required String value, required VoidCallback onTap, bool isFirst = false, bool isLast = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.vertical(
        top: isFirst ? Radius.circular(AppRadii.card) : Radius.zero,
        bottom: isLast ? Radius.circular(AppRadii.card) : Radius.zero,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primaryText, fontSize: 16)),
            Row(
              children: [
                Text(value, style: AppTextStyles.bodyBold.copyWith(fontSize: 16)),
                const SizedBox(width: 8),
                const Icon(Icons.edit, size: 16, color: Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, thickness: 1, color: Colors.grey[200], indent: 20, endIndent: 20);
  }

  String _formatDOB(int? day, int? month, int? year) {
    if (day == null || month == null || year == null) {
      if (year != null) return '01/01/$year'; // Fallback
      return 'Set Date';
    }
    final d = day.toString().padLeft(2, '0');
    final m = month.toString().padLeft(2, '0');
    return '$d/$m/$year';
  }
}

final userStreamProvider = StreamProvider.family<dynamic, String>((ref, uid) {
  if (uid.isEmpty) return Stream.value(null);
  return ref.read(userRepositoryProvider).streamUser(uid);
});
