import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:image_picker/image_picker.dart';
import 'package:physiq/screens/meal/meal_logging_flows.dart';
import 'package:physiq/screens/meal/meal_preview_screen.dart';
import 'package:physiq/services/food_service.dart';

/// Camera flow:
/// - Scan/Gallery: ML Kit on-device object detection + Open Food Facts nutrition
/// - Barcode: Open Food Facts barcode lookup
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
  final FoodService _foodService = FoodService();
  late final ObjectDetector _objectDetector;

  static const List<String> _foodKeywords = [
    'apple',
    'rice',
    'chicken',
    'dal',
    'bread',
    'maggi',
    'banana',
    'veggies',
    'vegetable',
    'meat',
    'juice',
    'food',
  ];

  @override
  void initState() {
    super.initState();
    _objectDetector = ObjectDetector(
      options: ObjectDetectorOptions(
        mode: DetectionMode.single,
        classifyObjects: true,
        multipleObjects: true,
      ),
    );
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
    _objectDetector.close();
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

  bool _isFoodLabel(String label) {
    final normalized = label.trim().toLowerCase();
    if (normalized.isEmpty) return false;
    return _foodKeywords.any(normalized.contains);
  }

  Future<List<String>> _detectFoodLabels(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final detectedObjects = await _objectDetector.processImage(inputImage);
    final labels = <String>{};

    for (final detectedObject in detectedObjects) {
      for (final label in detectedObject.labels) {
        final text = label.text.trim().toLowerCase();
        if (_isFoodLabel(text)) {
          labels.add(text);
        }
      }
    }

    return labels.toList();
  }

  Future<void> _openMealPreviewFromImage(
    XFile imageFile, {
    String source = 'camera',
  }) async {
    var loadingShown = false;
    try {
      if (mounted) {
        showLoading(context, source == 'gallery' ? 'Detecting...' : 'Scanning...');
        loadingShown = true;
      }

      final labels = await _detectFoodLabels(imageFile.path);
      final recognition = await _foodService.getMealNutritionFromLabels(labels);

      if (!mounted) return;
      if (loadingShown) {
        closeLoading(context);
        loadingShown = false;
      }

      if (recognition == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No food detected. Try another image, barcode, or Type search.',
            ),
          ),
        );
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => MealPreviewScreen(
            initialFood: recognition.meal,
            imagePath: imageFile.path,
          ),
        ),
      );
    } catch (e) {
      if (mounted && loadingShown) {
        closeLoading(context);
      }
      rethrow;
    }
  }

  Future<void> _onSnap() async {
    if (_controller == null || !_controller!.value.isInitialized || _isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final imageFile = await _controller!.takePicture();
      await _openMealPreviewFromImage(imageFile, source: 'camera');
    } catch (e) {
      if (mounted) {
        String msg = 'Scan failed: $e';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _pickGallery() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (picked == null) return;

    setState(() => _isProcessing = true);
    try {
      await _openMealPreviewFromImage(picked, source: 'gallery');
    } catch (e) {
      if (mounted) {
        String msg = 'Gallery scan failed: $e';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
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
              child: Row(
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
                      child: _isProcessing
                          ? const Padding(
                              padding: EdgeInsets.all(22),
                              child: CircularProgressIndicator(color: Colors.white),
                            )
                          : Container(
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
