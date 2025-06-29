import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';

class ARViewPage extends StatefulWidget {
  const ARViewPage({Key? key}) : super(key: key);

  @override
  State<ARViewPage> createState() => _ARViewPageState();
}

class _ARViewPageState extends State<ARViewPage> {
  bool _hasPermission = false;
  bool _isUnityAvailable = false;
  String _permissionStatusMessage = '권한을 확인하는 중...';
  static const MethodChannel _channel = MethodChannel('com.example.musai_f/unity_ar');

  @override
  void initState() {
    super.initState();
    _initializeAR();
  }

  Future<void> _initializeAR() async {
    // Unity 사용 가능 여부 확인
    await _checkUnityAvailability();
    
    // 카메라 권한 요청
    await requestCameraPermission();
  }

  Future<void> _checkUnityAvailability() async {
    try {
      final bool isAvailable = await _channel.invokeMethod('isUnityAvailable');
      setState(() {
        _isUnityAvailable = isAvailable;
      });
      print('🎮 Unity 사용 가능: $_isUnityAvailable');
    } catch (e) {
      print('❌ Unity 사용 가능 여부 확인 실패: $e');
      setState(() {
        _isUnityAvailable = false;
      });
    }
  }

  Future<void> requestCameraPermission() async {
    final status = await Permission.camera.status;
    print('📸 카메라 상태 초기: ${status.toString()}');

    if (status.isGranted) {
      setState(() {
        _hasPermission = true;
      });
    } else {
      final result = await Permission.camera.request();
      print('📸 요청 후 상태: ${result.toString()}');

      if (result.isGranted) {
        setState(() {
          _hasPermission = true;
        });
      } else {
        setState(() {
          _permissionStatusMessage = '카메라 권한이 완전히 거부되었습니다.\n설정에서 권한을 허용해주세요.';
        });
      }
    }
  }

  Future<void> _launchUnityAR() async {
    if (!_hasPermission) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('카메라 권한이 필요합니다.')),
      );
      return;
    }

    if (!_isUnityAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unity AR이 사용할 수 없습니다.')),
      );
      return;
    }

    try {
      print('🚀 Unity AR 실행 중...');
      final String result = await _channel.invokeMethod('launchUnityAR');
      print('✅ Unity AR 실행 결과: $result');
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unity AR이 실행되었습니다.')),
      );
    } catch (e) {
      print('❌ Unity AR 실행 실패: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unity AR 실행에 실패했습니다: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AR View'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (!_hasPermission) {
      return _buildPermissionRequest();
    }

    if (!_isUnityAvailable) {
      return _buildUnityNotAvailable();
    }

    return _buildARInterface();
  }

  Widget _buildPermissionRequest() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.camera_alt,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 20),
          Text(
            _permissionStatusMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              openAppSettings();
            },
            icon: const Icon(Icons.settings),
            label: const Text('설정 열기'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnityNotAvailable() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.orange,
          ),
          const SizedBox(height: 20),
          const Text(
            'Unity AR을 사용할 수 없습니다.',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'Unity 라이브러리가 제대로 로드되지 않았습니다.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _checkUnityAvailability,
            icon: const Icon(Icons.refresh),
            label: const Text('다시 시도'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildARInterface() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.view_in_ar,
            size: 80,
            color: Colors.blue,
          ),
          const SizedBox(height: 20),
          const Text(
            'Unity AR 카메라',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'Vuforia 기반 AR 기능을 사용합니다',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 40),
          ElevatedButton.icon(
            onPressed: _launchUnityAR,
            icon: const Icon(Icons.play_arrow),
            label: const Text('AR 시작'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              textStyle: const TextStyle(fontSize: 18),
            ),
          ),
          const SizedBox(height: 20),
          TextButton.icon(
            onPressed: () {
              setState(() {
                _hasPermission = false;
                _isUnityAvailable = false;
              });
              _initializeAR();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('재설정'),
          ),
        ],
      ),
    );
  }
}