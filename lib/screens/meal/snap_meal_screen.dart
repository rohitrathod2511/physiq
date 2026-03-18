import 'dart:io';
import 'package:camera/camera.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

class _SnapMealScreenState extends ConsumerState<SnapMealScreen> with WidgetsBindingObserver {
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
    setState(() {
      _isProcessing = true;
      _currentStep = 'Uploading image...';
    });

    try {
      final meal = await _aiFoodService.processMealImage(file, (step) {
        if (mounted) setState(() => _currentStep = step);
      });

      if (!mounted) return;

      if (meal == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to process meal.')),
        );
        return;
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // START BACKGROUND ENRICHMENT
      // We don't await this so the screen opens immediately
      _aiFoodService.enrichMeal(user.uid, meal).then((enrichedMeal) {
        debugPrint('Meal enrichment complete for ${meal.id}');
      }).catchError((e) {
        debugPrint('Meal enrichment failed: $e');
      });

      // Sum up Gemini's nutrition estimates from all ingredients
      double totalCalories = 0;
      double totalProtein = 0;
      double totalCarbs = 0;
      double totalFat = 0;

      for (final ingredient in meal.ingredients) {
        totalCalories += ingredient.caloriesEstimate;
        totalProtein += ingredient.proteinEstimate;
        totalCarbs += ingredient.carbsEstimate;
        totalFat += ingredient.fatEstimate;
      }

      // Create a Food object populated with Gemini's estimates
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
        aliases: meal.ingredients.map((i) => "${i.name} (${i.amount})").toList(),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => MealPreviewScreen(
            initialFood: dummyFood,
            meal: meal,
            imagePath: file.path,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _currentStep = '';
        });
      }
    }
  }

  Future<void> _onSnap() async {
    if (_controller == null || !_controller!.value.isInitialized || _isProcessing) return;

    try {
      final imageFile = await _controller!.takePicture();
      await _processImage(File(imageFile.path));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Scan failed: $e')),
        );
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
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.only(bottom: 40, top: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent],
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
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
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
                        icon: const Icon(Icons.photo_library_outlined, color: Colors.white, size: 32),
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
