import 'package:flutter/material.dart';
import 'package:physiq/widgets/slider_weight.dart';
import 'package:physiq/theme/design_system.dart';
import 'package:physiq/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:physiq/utils/conversions.dart'; 
import 'package:cloud_firestore/cloud_firestore.dart';

// Reusing widgets internally to avoid dependency on onboarding screen classes directly
// but using same visual style.

// --- Edit Name ---
class EditNamePage extends StatefulWidget {
  final String initialName;
  const EditNamePage({super.key, required this.initialName});

  @override
  State<EditNamePage> createState() => _EditNamePageState();
}

class _EditNamePageState extends State<EditNamePage> {
  late TextEditingController _nameController;
  final _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
  }

  Future<void> _save() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await _firestoreService.updateUserProfile(uid, {
        'profile': {'name': _nameController.text.trim()},
        'displayName': _nameController.text.trim()
      });
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Center(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _nameController,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Inter',
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter your name',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      fontFamily: 'Inter',
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 24,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(
                        color: Colors.black,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text('Save'),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

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
  String _unitSystem = 'Metric';

  @override
  void initState() {
    super.initState();
    _currentValue = widget.initialValue;
  }

  Future<void> _save() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await _firestoreService.updateUserProfile(uid, {'targetWeightKg': _currentValue});
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Mimic TargetWeightScreen UI
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: SliderWeight(
              value: _currentValue,
              min: 30,
              max: 150,
              unit: _unitSystem == 'Metric' ? 'kg' : 'lbs',
              onChanged: (val) => setState(() => _currentValue = val),
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: SizedBox(
               width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text('Save'),
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
  late double _heightCm;
  late double _weightKg;
  final _firestoreService = FirestoreService();
  final String _unitSystem = 'Metric';

  late FixedExtentScrollController _heightController;
  late FixedExtentScrollController _weightController;

  @override
  void initState() {
    super.initState();
    _heightCm = widget.initialHeight;
    _weightKg = widget.initialWeight;
    _heightController = FixedExtentScrollController(initialItem: (_heightCm - 100).round().clamp(0, 120));
    _weightController = FixedExtentScrollController(initialItem: (_weightKg - 30).round().clamp(0, 170));
  }
  
  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      // Save both to profile
       await _firestoreService.updateUserProfile(uid, {
        'heightCm': _heightCm,
        'weightKg': _weightKg,
      });

      // SYNC Fix: Add to weight history so graph works
      // Assuming context has a Ref or similar, but this is a straightforward StatefulWidget.
      // We can use a service or just write to firestore directly for now to be safe and quick
      // following the constraint "without touching unrelated logic" but we need to fix the sync.
      // Easiest is to replicate what ProgressRepo does or assume we can access it?
      // Actually, we don't have Ref here easily unless we convert to ConsumerStatefulWidget, 
      // OR we just write to subcollection.
      // Let's write to subcollection directly to ensure it works.
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('weight_history')
            .add({
              'id': DateTime.now().millisecondsSinceEpoch.toString(),
              'weightKg': _weightKg,
              'date': FieldValue.serverTimestamp(), // or DateTime.now()
              'loggedAt': FieldValue.serverTimestamp(),
            });
      } catch (e) {
        // fail silently or log
        debugPrint('Failed to add weight history from settings: $e');
      }

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
            const SizedBox(height: 16),
             Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                   // Selection Highlight Overlay
                  Container(
                    height: 60,
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.withOpacity(0.1)),
                    ),
                  ),
                  Positioned.fill(
                    child: Row(
                      children: [
                        // Height Slider
                        Expanded(
                          child: ListWheelScrollView.useDelegate(
                            controller: _heightController,
                            itemExtent: 50,
                            perspective: 0.005, diameterRatio: 1.5,
                            physics: const FixedExtentScrollPhysics(),
                            onSelectedItemChanged: (index) {
                                setState(() {
                                   _heightCm = (100 + index).toDouble();
                                });
                            },
                             childDelegate: ListWheelChildBuilderDelegate(
                              childCount: 121,
                              builder: (context, index) {
                                final selectedIndex = (_heightCm - 100).round();
                                final isSelected = index == selectedIndex;
                                return Center(
                                  child: AnimatedDefaultTextStyle(
                                    duration: const Duration(milliseconds: 200),
                                    style: isSelected
                                        ? const TextStyle(fontFamily: 'Inter', fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black)
                                        : TextStyle(fontFamily: 'Inter', fontSize: 24, fontWeight: FontWeight.w500, color: Colors.grey.withOpacity(0.4)),
                                    child: Text("${100 + index} cm"),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        // Weight Slider
                         Expanded(
                          child: ListWheelScrollView.useDelegate(
                            controller: _weightController,
                            itemExtent: 50,
                            perspective: 0.005, diameterRatio: 1.5,
                            physics: const FixedExtentScrollPhysics(),
                            onSelectedItemChanged: (index) {
                                setState(() {
                                   _weightKg = (30 + index).toDouble();
                                });
                            },
                             childDelegate: ListWheelChildBuilderDelegate(
                              childCount: 171,
                              builder: (context, index) {
                                final selectedIndex = (_weightKg - 30).round();
                                final isSelected = index == selectedIndex;
                                return Center(
                                  child: AnimatedDefaultTextStyle(
                                    duration: const Duration(milliseconds: 200),
                                    style: isSelected
                                        ? const TextStyle(fontFamily: 'Inter', fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black)
                                        : TextStyle(fontFamily: 'Inter', fontSize: 24, fontWeight: FontWeight.w500, color: Colors.grey.withOpacity(0.4)),
                                    child: Text("${30 + index} kg"),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text('Save'),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// --- Edit Date of Birth (Renamed from EditBirthYear) ---
class EditDOBPage extends StatefulWidget {
  final int initialYear;
  final int initialMonth;
  final int initialDay;
  const EditDOBPage({super.key, this.initialYear = 2000, this.initialMonth = 1, this.initialDay = 1});

  @override
  State<EditDOBPage> createState() => _EditDOBPageState();
}

class _EditDOBPageState extends State<EditDOBPage> {
  late int _selectedYear;
  late int _selectedMonth; // 1-12
  late int _selectedDay; // 1-31
  final _firestoreService = FirestoreService();
  final int _currentYear = DateTime.now().year;

  late FixedExtentScrollController _yearController;
  late FixedExtentScrollController _monthController;
  late FixedExtentScrollController _dayController;

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialYear;
    _selectedMonth = widget.initialMonth;
    _selectedDay = widget.initialDay;
    
    // Bounds check
    if (_selectedYear < (_currentYear - 110)) _selectedYear = 2000;
    
    final years = List.generate(101, (index) => (_currentYear - 110) + index);
    
    _yearController = FixedExtentScrollController(initialItem: years.indexOf(_selectedYear) != -1 ? years.indexOf(_selectedYear) : years.indexOf(2000));
    _monthController = FixedExtentScrollController(initialItem: _selectedMonth - 1);
    _dayController = FixedExtentScrollController(initialItem: _selectedDay - 1);
  }
  
  @override
  void dispose() {
    _yearController.dispose();
    _monthController.dispose();
    _dayController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await _firestoreService.updateUserProfile(uid, {
        'birthYear': _selectedYear,
        'birthMonth': _selectedMonth,
        'birthDay': _selectedDay,
      });
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final years = List.generate(101, (index) => (_currentYear - 110) + index);
     final months = [
      "JAN", "FEB", "MAR", "APR", "MAY", "JUN",
      "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Date of Birth', style: AppTextStyles.heading2),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: AppColors.primaryText),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                   Container(
                    height: 60,
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.withOpacity(0.1)),
                    ),
                  ),
                  Positioned.fill(
                    child: Row(
                      children: [
                        // Day
                        Expanded(
                           child: ListWheelScrollView.useDelegate(
                            controller: _dayController,
                            itemExtent: 50,
                            perspective: 0.005, diameterRatio: 1.5,
                            physics: const FixedExtentScrollPhysics(),
                            onSelectedItemChanged: (index) {
                               setState(() => _selectedDay = index + 1);
                            },
                             childDelegate: ListWheelChildBuilderDelegate(
                              childCount: 31,
                              builder: (context, index) {
                                final isSelected = (index + 1) == _selectedDay;
                                return Center(
                                  child: AnimatedDefaultTextStyle(
                                     duration: const Duration(milliseconds: 200),
                                     style: isSelected
                                      ? AppTextStyles.h2.copyWith(fontSize: 24, color: Colors.black)
                                      : AppTextStyles.h2.copyWith(fontSize: 24, color: Colors.grey.withOpacity(0.4)),
                                    child: Text("${index + 1}"),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                         // Month
                        Expanded(
                           child: ListWheelScrollView.useDelegate(
                            controller: _monthController,
                            itemExtent: 50,
                            perspective: 0.005, diameterRatio: 1.5,
                            physics: const FixedExtentScrollPhysics(),
                            onSelectedItemChanged: (index) {
                               setState(() => _selectedMonth = index + 1);
                            },
                             childDelegate: ListWheelChildBuilderDelegate(
                              childCount: 12,
                              builder: (context, index) {
                                final isSelected = (index + 1) == _selectedMonth;
                                return Center(
                                  child: AnimatedDefaultTextStyle(
                                     duration: const Duration(milliseconds: 200),
                                     style: isSelected
                                      ? AppTextStyles.h2.copyWith(fontSize: 24, color: Colors.black)
                                      : AppTextStyles.h2.copyWith(fontSize: 24, color: Colors.grey.withOpacity(0.4)),
                                    child: Text(months[index]),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        // Year
                        Expanded(
                           child: ListWheelScrollView.useDelegate(
                            controller: _yearController,
                            itemExtent: 50,
                            perspective: 0.005, diameterRatio: 1.5,
                            physics: const FixedExtentScrollPhysics(),
                            onSelectedItemChanged: (index) {
                               if (index >= 0 && index < years.length) {
                                setState(() => _selectedYear = years[index]);
                               }
                            },
                             childDelegate: ListWheelChildBuilderDelegate(
                              childCount: years.length,
                              builder: (context, index) {
                                final year = years[index];
                                final isSelected = year == _selectedYear;
                                return Center(
                                  child: AnimatedDefaultTextStyle(
                                     duration: const Duration(milliseconds: 200),
                                     style: isSelected
                                      ? AppTextStyles.h1.copyWith(fontSize: 28, color: Colors.black)
                                      : AppTextStyles.h2.copyWith(fontSize: 24, color: Colors.grey.withOpacity(0.4)),
                                    child: Text("$year"),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
             SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text('Save'),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
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
    final options = ['Male', 'Female', 'Other'];
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
          children: [
             const SizedBox(height: 40),
             // Custom selection logic mimicking CentralPillButtons/GenderScreen logic but simpler
             Column(
               children: options.map((option) {
                 final isSelected = _selected == option;
                 return Padding(
                   padding: const EdgeInsets.only(bottom: 12.0),
                   child: GestureDetector(
                     onTap: () => setState(() => _selected = option),
                     child: AnimatedContainer(
                       duration: const Duration(milliseconds: 200),
                       width: double.infinity,
                       padding: const EdgeInsets.symmetric(vertical: 20),
                       decoration: BoxDecoration(
                         color: isSelected ? Colors.black : Colors.white,
                         borderRadius: BorderRadius.circular(30),
                         border: Border.all(color: Colors.grey.shade300),
                         boxShadow: [
                           if (!isSelected)
                             BoxShadow(
                               color: Colors.black.withOpacity(0.05),
                               blurRadius: 10,
                               offset: const Offset(0, 4),
                             )
                         ]
                       ),
                       child: Center(
                         child: Text(
                           option,
                           style: TextStyle(
                             fontFamily: 'Inter',
                             fontSize: 18,
                             fontWeight: FontWeight.w600,
                             color: isSelected ? Colors.white : Colors.black,
                           ),
                         ),
                       ),
                     ),
                   ),
                 );
               }).toList(),
             ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text('Save'),
              ),
            ),
            const SizedBox(height: 20),
          ],
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: SliderTheme(
               data: SliderTheme.of(context).copyWith(
                activeTrackColor: Colors.black,
                inactiveTrackColor: Colors.grey.shade300,
                thumbColor: Colors.black,
                overlayColor: Colors.black.withOpacity(0.1),
                trackHeight: 6.0,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12.0),
              ),
              child: Slider(
                value: _currentValue,
                min: 1000,
                max: 30000,
                divisions: 290,
                onChanged: (val) => setState(() => _currentValue = val),
              ),
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text('Save'),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
