import 'dart:io';
import 'package:camera/camera.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:physiq/models/food_model.dart';
import 'package:physiq/models/meal_model.dart';
import 'package:physiq/screens/meal/meal_preview_screen.dart';
import 'package:physiq/services/ai_food_service.dart';

class SnapMealScreen extends ConsumerStatefulWidget {
  const SnapMealScreen({super.key});

  @override
  ConsumerState<SnapMealScreen> createState() => _SnapMealScreenState();
}

class _SnapMealScreenState extends ConsumerState<SnapMealScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  String _currentStep = '';
  final AiFoodService _aiFoodService = AiFoodService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
        _controller = CameraController(
          _cameras[0],
          ResolutionPreset.high,
          enableAudio: false,
        );
        await _controller!.initialize();
        await _controller!.setZoomLevel(1.0);
        if (mounted) setState(() => _isCameraInitialized = true);
      }
    } catch (e) {
      debugPrint("Camera init error: $e");
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      _controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _processImage(File file) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final mealId = DateTime.now().millisecondsSinceEpoch.toString();
    final nav = Navigator.of(context);
    final rootNav = Navigator.of(context, rootNavigator: true);
    final scaffoldMsg = ScaffoldMessenger.of(context);

    setState(() {
      _isProcessing = true;
      _currentStep = 'Uploading image...';
    });

    // STEP 3: Create temporary loading meal card
    // Set logged: true so it appears immediately in "Today's logs"
    final loadingMeal = Meal(
      id: mealId,
      imageUrl: file.path,
      title: 'Analyzing meal...',
      container: 'plate',
      ingredients: [],
      createdAt: DateTime.now(),
      logged: true,
    );

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('meals')
          .doc(mealId)
          .set(loadingMeal.toJson());
    } catch (e) {
      debugPrint('Failed to save loading card: $e');
    }

    if (mounted) {
      nav.pop(); // Close scanner, return to Home for the seamless loading card
    }

    // Process using AI service in background
    try {
      // await geminiDetection, usdaProcessing, and calculations all inside this function
      final meal = await _aiFoodService.processAndEnrichMealAsync(
        user.uid,
        mealId,
        file,
      );

      if (meal == null) {
        await _deleteMealDoc(user.uid, mealId);
        scaffoldMsg.showSnackBar(
          const SnackBar(content: Text('Failed to process meal.')),
        );
        setState(() => _isProcessing = false);
        return;
      }

      // Calculation logic
      double totalCalories = 0.0;
      double totalProtein = 0.0;
      double totalCarbs = 0.0;
      double totalFat = 0.0;

      for (final ingredient in meal.ingredients) {
        totalCalories +=
            (ingredient.caloriesEstimate as num?)?.toDouble() ?? 0.0;
        totalProtein += (ingredient.proteinEstimate as num?)?.toDouble() ?? 0.0;
        totalCarbs += (ingredient.carbsEstimate as num?)?.toDouble() ?? 0.0;
        totalFat += (ingredient.fatEstimate as num?)?.toDouble() ?? 0.0;
      }

      final dummyFood = Food(
        id: meal.id,
        name: meal.title,
        category: 'AI Scanned',
        unit: meal.container,
        baseWeightG: 100,
        calories: totalCalories,
        protein: totalProtein,
        carbs: totalCarbs,
        fat: totalFat,
        source: 'gemini_vision',
        aliases: meal.ingredients
            .map((i) => "${i.name} (${i.amount})")
            .toList(),
      );

      print(
        '🏁 STEP 8: All calculations done. Navigating to preview screen with ${meal.ingredients.length} ingredients.',
      );
      rootNav.push(
        MaterialPageRoute(
          builder: (_) => MealPreviewScreen(
            initialFood: dummyFood,
            meal: meal,
            imagePath: file.path,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error: $e');
      await _deleteMealDoc(user.uid, mealId);
      scaffoldMsg.showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to analyze this meal. Please try again or log it manually.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _deleteMealDoc(String userId, String mealId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('meals')
          .doc(mealId)
          .delete();
    } catch (e) {
      debugPrint('Failed to delete meal doc: $e');
    }
  }

  Future<void> _onSnap() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _isProcessing)
      return;

    try {
      final imageFile = await _controller!.takePicture();
      await _processImage(File(imageFile.path));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Scan failed: $e')));
      }
    }
  }

  Future<void> _pickGallery() async {
    if (_isProcessing) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (picked == null) return;

    await _processImage(File(picked.path));
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _controller!.value.previewSize?.height ?? 1,
              height: _controller!.value.previewSize?.width ?? 1,
              child: CameraPreview(_controller!),
            ),
          ),
          // Scanner Overlay
          const Center(child: ScannerOverlay()),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.only(bottom: 40, top: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.8),
                    Colors.transparent,
                  ],
                ),
              ),
              child: _isProcessing
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(color: Colors.white),
                        const SizedBox(height: 16),
                        Text(
                          _currentStep,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        const SizedBox(width: 48), // Placeholder for balance
                        GestureDetector(
                          onTap: _onSnap,
                          child: Container(
                            height: 84,
                            width: 84,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                            child: Container(
                              margin: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.photo_library_outlined,
                            color: Colors.white,
                            size: 32,
                          ),
                          onPressed: _pickGallery,
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class ScannerOverlay extends StatelessWidget {
  const ScannerOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scanAreaSize = size.width * 0.85; // Increased size

    return Stack(
      children: [
        Container(
          width: size.width,
          height: size.height,
          decoration: ShapeDecoration(
            shape: ScannerOverlayShape(
              borderColor: Colors.white.withValues(alpha: 0.8),
              borderRadius: 24,
              borderLength: 40,
              borderWidth: 3,
              cutOutSize: scanAreaSize,
            ),
          ),
        ),
      ],
    );
  }
}

class ScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderWidth;
  final double borderRadius;
  final double borderLength;
  final double cutOutSize;

  const ScannerOverlayShape({
    this.borderColor = Colors.white,
    this.borderWidth = 3.0,
    this.borderRadius = 24.0,
    this.borderLength = 40.0,
    required this.cutOutSize,
  });

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => Path();

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    return Path()..addRect(rect);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final width = rect.width;
    final height = rect.height;

    final cutOutRect = Rect.fromCenter(
      center: Offset(width / 2, height / 2),
      width: cutOutSize,
      height: cutOutSize,
    );

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    // Corner markers
    final path = Path();

    // Top Left
    path.moveTo(cutOutRect.left, cutOutRect.top + borderLength);
    path.lineTo(cutOutRect.left, cutOutRect.top + borderRadius);
    path.arcToPoint(
      Offset(cutOutRect.left + borderRadius, cutOutRect.top),
      radius: Radius.circular(borderRadius),
    );
    path.lineTo(cutOutRect.left + borderLength, cutOutRect.top);

    // Top Right
    path.moveTo(cutOutRect.right - borderLength, cutOutRect.top);
    path.lineTo(cutOutRect.right - borderRadius, cutOutRect.top);
    path.arcToPoint(
      Offset(cutOutRect.right, cutOutRect.top + borderRadius),
      radius: Radius.circular(borderRadius),
    );
    path.lineTo(cutOutRect.right, cutOutRect.top + borderLength);

    // Bottom Left
    path.moveTo(cutOutRect.left, cutOutRect.bottom - borderLength);
    path.lineTo(cutOutRect.left, cutOutRect.bottom - borderRadius);
    path.arcToPoint(
      Offset(cutOutRect.left + borderRadius, cutOutRect.bottom),
      radius: Radius.circular(borderRadius),
      clockwise: false,
    );
    path.lineTo(cutOutRect.left + borderLength, cutOutRect.bottom);

    // Bottom Right
    path.moveTo(cutOutRect.right - borderLength, cutOutRect.bottom);
    path.lineTo(cutOutRect.right - borderRadius, cutOutRect.bottom);
    path.arcToPoint(
      Offset(cutOutRect.right, cutOutRect.bottom - borderRadius),
      radius: Radius.circular(borderRadius),
      clockwise: false,
    );
    path.lineTo(cutOutRect.right, cutOutRect.bottom - borderLength);

    canvas.drawPath(path, borderPaint);
  }

  @override
  ShapeBorder scale(double t) {
    return ScannerOverlayShape(
      borderColor: borderColor,
      borderWidth: borderWidth,
      borderRadius: borderRadius,
      borderLength: borderLength,
      cutOutSize: cutOutSize,
    );
  }
}
