
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:physiq/services/ai_nutrition_service.dart';
import 'package:physiq/services/food_service.dart';
import 'package:physiq/screens/meal/food_database_screen.dart';
import 'package:physiq/screens/meal/meal_preview_screen.dart';
import 'package:physiq/theme/design_system.dart';

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
  
  final AiNutritionService _aiService = AiNutritionService();
  final FoodService _foodService = FoodService();

  // Mode: 0=Scan, 1=Barcode, 2=Gallery, 3=Type
  int _selectedMode = 0;

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
        if (mounted) setState(() => _isCameraInitialized = true);
      }
    } catch (e) {
      print("Camera init error: $e");
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

  Future<void> _onSnap() async {
    if (_controller == null || !_controller!.value.isInitialized || _isProcessing) return;

    setState(() => _isProcessing = true);

    try {
        final xFile = await _controller!.takePicture();
        _processImage(xFile.path);

    } catch (e) {
        print("Snap error: $e");
        setState(() => _isProcessing = false);
    }
  }

  Future<void> _processImage(String path) async {
      try {
          // 1. AI Analysis
          final aiResult = await _aiService.estimateFromImage(path);
          // { meal_name: "Poha", quantity: 2, unit: "plate" }

          final String mealName = aiResult['meal_name'] ?? 'Unknown';
          final double qty = (aiResult['quantity'] as num?)?.toDouble() ?? 1.0;
          
          if (mealName == 'Unknown') {
             _navToDatabase('');
             return;
          }

          // 2. Search Database
          final foods = await _foodService.searchFoods(mealName);
          
          if (foods.isEmpty) {
              // No match found, go to DB screen with query pre-filled
              _navToDatabase(mealName);
          } else {
              // 3. Match found - Pick best one (first for now)
              // Ideally we check for unit match too, but for now just first.
              final bestFood = foods.first;
              
              if (mounted) {
                  Navigator.push(context, MaterialPageRoute(
                      builder: (_) => MealPreviewScreen(
                          initialFood: bestFood,
                          initialQuantity: qty,
                      )
                  ));
              }
          }

      } catch (e) {
          print("Processing error: $e");
          // Fallback
          _navToDatabase("");
      } finally {
          if (mounted) setState(() => _isProcessing = false);
      }
  }

  void _navToDatabase(String query) {
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(
          builder: (_) => FoodDatabaseScreen(initialQuery: query)
      ));
  }

  Future<void> _pickGallery() async {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
          setState(() => _isProcessing = true);
          _processImage(picked.path);
      }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized) {
        return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
            // Camera Preview
            SizedBox(
                height: MediaQuery.of(context).size.height,
                width: MediaQuery.of(context).size.width,
                child: CameraPreview(_controller!),
            ),

            // Top Bar
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
                                    color: Colors.black.withOpacity(0.5),
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

            // Bottom Overlay
            Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                    padding: const EdgeInsets.only(bottom: 30, top: 20),
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                        ),
                    ),
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                            // Shutter Button
                             GestureDetector(
                                onTap: _onSnap,
                                child: Container(
                                    height: 80, width: 80,
                                    decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 4),
                                        color: Colors.white.withOpacity(0.2), // Transparent inner
                                    ),
                                    child: _isProcessing 
                                        ? const Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: Colors.white))
                                        : null,
                                ),
                            ),
                            const SizedBox(height: 30),
                            
                            // Modes
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
              if (index == 2) _pickGallery();
              if (index == 3) {
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const FoodDatabaseScreen()));
              }
          },
          child: Column(
              children: [
                  Icon(icon, color: isSelected ? Colors.amber : Colors.white, size: 28),
                  const SizedBox(height: 4),
                  Text(label, style: TextStyle(
                      color: isSelected ? Colors.amber : Colors.white, 
                      fontSize: 12, fontWeight: FontWeight.bold
                  )),
              ],
          ),
      );
  }
}
