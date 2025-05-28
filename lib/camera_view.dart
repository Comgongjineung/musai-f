import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class CameraView extends StatefulWidget {
  const CameraView({super.key});

  @override
  State<CameraView> createState() => CameraViewState();
}

class CameraViewState extends State<CameraView> {
  CameraController? _controller;
  Timer? _timer;
  bool _isProcessing = false;

  double _currentZoomLevel = 1.0;
  double _baseZoomLevel = 1.0;
  double _maxZoomLevel = 1.0;
  double _minZoomLevel = 1.0;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final backCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back);

    _controller = CameraController(
      backCamera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await _controller!.initialize();
    _maxZoomLevel = await _controller!.getMaxZoomLevel();
    _minZoomLevel = await _controller!.getMinZoomLevel();
    print("Zoom range: $_minZoomLevel ~ $_maxZoomLevel");
    await _controller!.startImageStream(_processFrame);

    setState(() {});
  }

  void _processFrame(CameraImage image) {
    if (_isProcessing) return;
    _isProcessing = true;

    _timer ??= Timer.periodic(const Duration(seconds: 1), (_) {
      final bytes = _concatenatePlanes(image.planes);
      debugPrint("Captured ${bytes.lengthInBytes} bytes of image data");
    });

    _isProcessing = false;
  }

  Uint8List _concatenatePlanes(List<Plane> planes) {
    final WriteBuffer buffer = WriteBuffer();
    for (final plane in planes) {
      buffer.putUint8List(plane.bytes);
    }
    return buffer.done().buffer.asUint8List();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  // 사진 촬영 메서드
  Future<XFile?> takePicture() async {
    if (_controller != null && _controller!.value.isInitialized) {
      await _controller!.setFlashMode(FlashMode.off); //촬영 전 플래시 끄기
      await _controller!.stopImageStream(); // 스트리밍 중지
      final picture = await _controller!.takePicture();
      await _controller!.setFlashMode(FlashMode.off); //촬영 후 다시 플래시 끄기
      return picture;
    }
    return null;
  }

  void onZoomStart(ScaleStartDetails details) {
    _baseZoomLevel = _currentZoomLevel;
    //print("🔍 줌 시작: $_baseZoomLevel");
  }

  void onZoomUpdate(ScaleUpdateDetails details) async {
    final newZoom = (_baseZoomLevel * details.scale).clamp(_minZoomLevel, _maxZoomLevel);
    //final direction = details.scale > 1 ? "🔎 확대 중" : "🔍 축소 중";
   // print("📏 $direction (요청 줌: $newZoom)");
    _currentZoomLevel = newZoom;
    await _controller?.setZoomLevel(_currentZoomLevel);
    //print("✅ 적용된 줌: $_currentZoomLevel");
  }

  @override
  Widget build(BuildContext context) {
  if (!(_controller?.value.isInitialized ?? false)) {
    return const Center(child: CircularProgressIndicator());
  }

  // 전체화면 카메라 (ClipRRect, AspectRatio 제거)
  final size = MediaQuery.of(context).size;
  final camera = _controller!.value;

  // 카메라 비율은 landscape 기준이므로, portrait 모드에선 반대로 계산
  double scale = size.aspectRatio * camera.aspectRatio;
  if (scale < 1) scale = 1 / scale;

  return Stack(
    children: [
      Transform.scale(
        scale: scale,
        child: Center(
          child: CameraPreview(_controller!),
        ),
      ),
    ],
  );
}
}
