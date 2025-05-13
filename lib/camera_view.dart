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

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final backCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.back,
    );

    _controller = CameraController(
      backCamera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await _controller!.initialize();
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
      await _controller!.stopImageStream(); // 스트리밍 중지
      return await _controller!.takePicture();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (!(_controller?.value.isInitialized ?? false)) {
      return const Center(child: CircularProgressIndicator());
    }

    // ✅ 전체화면 카메라 (ClipRRect, AspectRatio 제거)
    return CameraPreview(_controller!);
  }
}
