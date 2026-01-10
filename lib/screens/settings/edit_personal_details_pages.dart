import 'package:flutter/material.dart';
import 'package:physiq/theme/design_system.dart';
import 'package:physiq/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

// --- Edit Goal Weight ---
class EditGoalWeightPage extends StatefulWidget {
  final double initialValue;
  const EditGoalWeightPage({super.key, this.initialValue = 70.0});

  @override
  State<EditGoalWeightPage> createState() => _EditGoalWeightPageState();
}

class _EditGoalWeightPageState extends State<EditGoalWeightPage> {
  late double _currentValue;
  final _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _currentValue = widget.initialValue;
  }

  Future<void> _save() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await _firestoreService.updateUserProfile(uid, {'goalWeightKg': _currentValue});
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Goal Weight', style: AppTextStyles.heading2),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: AppColors.primaryText),
      ),
      body: Column(
        children: [
          const SizedBox(height: 40),
          Text('${_currentValue.toStringAsFixed(1)} kg', style: AppTextStyles.largeNumber),
          const SizedBox(height: 40),
          Slider(
            value: _currentValue,
            min: 40,
            max: 150,
            activeColor: AppColors.primary,
            inactiveColor: Colors.grey[300],
            onChanged: (val) => setState(() => _currentValue = val),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: Text('Save', style: AppTextStyles.button.copyWith(color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Edit Height & Weight ---
class EditHeightWeightPage extends StatefulWidget {
  final double initialHeight;
  final double initialWeight;
  const EditHeightWeightPage({super.key, this.initialHeight = 175, this.initialWeight = 70});

  @override
  State<EditHeightWeightPage> createState() => _EditHeightWeightPageState();
}

class _EditHeightWeightPageState extends State<EditHeightWeightPage> {
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  final _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _heightController = TextEditingController(text: widget.initialHeight.toString());
    _weightController = TextEditingController(text: widget.initialWeight.toString());
  }

  Future<void> _save() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await _firestoreService.updateUserProfile(uid, {
        'heightCm': double.tryParse(_heightController.text) ?? widget.initialHeight,
        'weightKg': double.tryParse(_weightController.text) ?? widget.initialWeight,
      });
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Height & Weight', style: AppTextStyles.heading2),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: AppColors.primaryText),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            TextField(
              controller: _heightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Height (cm)'),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _weightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Weight (kg)'),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: Text('Save', style: AppTextStyles.button.copyWith(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Edit Birth Year ---
class EditBirthYearPage extends StatefulWidget {
  final int initialYear;
  const EditBirthYearPage({super.key, this.initialYear = 1995});

  @override
  State<EditBirthYearPage> createState() => _EditBirthYearPageState();
}

class _EditBirthYearPageState extends State<EditBirthYearPage> {
  late int _selectedYear;
  final _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialYear;
  }

  Future<void> _save() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await _firestoreService.updateUserProfile(uid, {'birthYear': _selectedYear});
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Birth Year', style: AppTextStyles.heading2),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: AppColors.primaryText),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListWheelScrollView.useDelegate(
              itemExtent: 50,
              physics: const FixedExtentScrollPhysics(),
              controller: FixedExtentScrollController(initialItem: _selectedYear - 1900),
              onSelectedItemChanged: (index) {
                setState(() {
                  _selectedYear = 1900 + index;
                });
              },
              childDelegate: ListWheelChildBuilderDelegate(
                builder: (context, index) {
                  final year = 1900 + index;
                  return Center(
                    child: Text(
                      '$year',
                      style: year == _selectedYear
                          ? AppTextStyles.heading2.copyWith(color: AppColors.primary)
                          : AppTextStyles.bodyMedium.copyWith(color: Colors.grey),
                    ),
                  );
                },
                childCount: 150,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: Text('Save', style: AppTextStyles.button.copyWith(color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Edit Gender ---
class EditGenderPage extends StatefulWidget {
  final String initialGender;
  const EditGenderPage({super.key, this.initialGender = 'Male'});

  @override
  State<EditGenderPage> createState() => _EditGenderPageState();
}

class _EditGenderPageState extends State<EditGenderPage> {
  late String _selected;
  final _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _selected = widget.initialGender;
  }

  Future<void> _save() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await _firestoreService.updateUserProfile(uid, {'gender': _selected});
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Gender', style: AppTextStyles.heading2),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: AppColors.primaryText),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: ['Male', 'Female', 'Other'].map((gender) {
            final isSelected = _selected == gender;
            return GestureDetector(
              onTap: () => setState(() => _selected = gender),
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.card,
                  borderRadius: BorderRadius.circular(AppRadii.card),
                  boxShadow: [AppShadows.card],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      gender,
                      style: AppTextStyles.bodyBold.copyWith(
                        color: isSelected ? Colors.white : AppColors.primaryText,
                      ),
                    ),
                    if (isSelected)
                      const Icon(Icons.check, color: Colors.white),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            child: Text('Save', style: AppTextStyles.button.copyWith(color: Colors.white)),
          ),
        ),
      ),
    );
  }
}

// --- Edit Step Goal ---
class EditStepGoalPage extends StatefulWidget {
  final int initialGoal;
  const EditStepGoalPage({super.key, this.initialGoal = 10000});

  @override
  State<EditStepGoalPage> createState() => _EditStepGoalPageState();
}

class _EditStepGoalPageState extends State<EditStepGoalPage> {
  late double _currentValue;
  final _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _currentValue = widget.initialGoal.toDouble();
  }

  Future<void> _save() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await _firestoreService.updateUserProfile(uid, {'dailyStepGoal': _currentValue.toInt()});
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Daily Step Goal', style: AppTextStyles.heading2),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: AppColors.primaryText),
      ),
      body: Column(
        children: [
          const SizedBox(height: 40),
          Text('${_currentValue.toInt()} steps', style: AppTextStyles.largeNumber),
          const SizedBox(height: 40),
          Slider(
            value: _currentValue,
            min: 1000,
            max: 30000,
            divisions: 290, // increments of 100
            activeColor: AppColors.primary,
            inactiveColor: Colors.grey[300],
            onChanged: (val) => setState(() => _currentValue = val),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: Text('Save', style: AppTextStyles.button.copyWith(color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
