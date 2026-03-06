import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:image_picker/image_picker.dart';
import 'package:physiq/screens/meal/food_database_screen.dart';
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
  int _selectedMode = 0; // 0=Scan, 1=Barcode, 2=Gallery, 3=Type
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

  Future<void> _lookupBarcode() async {
    final controller = TextEditingController();
    final barcode = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Barcode'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: 'e.g. 8901058001014',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Search'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (barcode == null || barcode.isEmpty) return;

    setState(() => _isProcessing = true);
    try {
      final results = await _foodService.searchByBarcode(barcode);
      if (!mounted) return;

      if (results.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No food found for that barcode.')),
        );
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => MealPreviewScreen(initialFood: results.first),
        ),
      );
    } catch (e) {
      if (mounted) {
        String msg = 'Barcode search failed: $e';
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
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            child: CameraPreview(_controller!),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.flash_off, color: Colors.white, size: 16),
                        SizedBox(width: 4),
                        Text("Off", style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.only(bottom: 30, top: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: _onSnap,
                    child: Container(
                      height: 80,
                      width: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                      child: _isProcessing
                          ? const Padding(
                              padding: EdgeInsets.all(20),
                              child: CircularProgressIndicator(color: Colors.white),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildModeIcon(0, Icons.center_focus_strong, "Scan"),
                      _buildModeIcon(1, Icons.qr_code_scanner, "Barcode"),
                      _buildModeIcon(2, Icons.photo_library, "Gallery"),
                      _buildModeIcon(3, Icons.edit, "Type"),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeIcon(int index, IconData icon, String label) {
    final isSelected = _selectedMode == index;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedMode = index);
        if (index == 1) _lookupBarcode();
        if (index == 2) _pickGallery();
        if (index == 3) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const FoodDatabaseScreen()),
          );
        }
      },
      child: Column(
        children: [
          Icon(icon, color: isSelected ? Colors.amber : Colors.white, size: 28),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.amber : Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
