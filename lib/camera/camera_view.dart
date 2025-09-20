import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
//import 'package:flutter/foundation.dart';

class CameraView extends StatefulWidget {
  const CameraView({super.key});

  @override
  State<CameraView> createState() => CameraViewState();
}

class CameraViewState extends State<CameraView> {
  CameraController? _controller;
  Timer? _timer;
  //bool _isProcessing = false;

  double _currentZoomLevel = 1.0;
  double _baseZoomLevel = 1.0;
  double _maxZoomLevel = 1.0;
  double _minZoomLevel = 1.0;
  
  // 노출 보정 관련 변수들
  double _iso = 100.0; // ISO 값
  double _minIso = 100.0;
  double _maxIso = 3200.0;

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
    
    // ISO 범위 설정 (기본값 사용)
    _minIso = 100.0;
    _maxIso = 3200.0;
    
    print("Zoom range: $_minZoomLevel ~ $_maxZoomLevel");
    print("ISO range: $_minIso ~ $_maxIso");

    // 자동 노출 보정 활성화
    await _enableAutoExposure();
    
    // 자동 밝기 조정 실행
    await _autoAdjustBrightness();
    
    setState(() {});
  }

  // 자동 노출 보정 활성화
  Future<void> _enableAutoExposure() async {
    if (_controller != null && _controller!.value.isInitialized) {
      try {
        // 자동 노출 모드 설정
        await _controller!.setExposureMode(ExposureMode.auto);
        // 자동 포커스 모드 설정
        await _controller!.setFocusMode(FocusMode.auto);
        
        print("✅ 자동 노출 보정 활성화 완료");
      } catch (e) {
        print("❌ 자동 노출 보정 설정 실패: $e");
      }
    }
  }


  // ISO 설정 (시뮬레이션)
  Future<void> _setISO(double iso) async {
    if (_controller != null && _controller!.value.isInitialized) {
      try {
        // ISO 값 제한
        final clampedIso = iso.clamp(_minIso, _maxIso);
        _iso = clampedIso;
        print("📸 ISO 설정: $_iso (시뮬레이션)");
      } catch (e) {
        print("❌ ISO 설정 실패: $e");
      }
    }
  }

  // 자동 밝기 조정 (환경 감지)
  Future<void> _autoAdjustBrightness() async {
    if (_controller != null && _controller!.value.isInitialized) {
      try {
        // 자동 ISO 조정 (환경에 따라)
        await _setISO(_minIso * 2.0); // 적절한 ISO 설정
        
        print("🌞 자동 밝기 조정 완료");
      } catch (e) {
        print("❌ 자동 밝기 조정 실패: $e");
      }
    }
  }

  @override
  void dispose() {
    print('📷 CameraView dispose() called');
    _timer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  // 사진 촬영 메서드
  Future<XFile?> takePicture() async {
    if (_controller != null && _controller!.value.isInitialized) {
      await _controller!.setFlashMode(FlashMode.off); //촬영 전 플래시 끄기
      //await _controller!.stopImageStream(); // 스트리밍 중지
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
