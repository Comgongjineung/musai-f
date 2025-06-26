import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class ARViewPage extends StatefulWidget {
  const ARViewPage({Key? key}) : super(key: key);

  @override
  State<ARViewPage> createState() => _ARViewPageState();
}

class _ARViewPageState extends State<ARViewPage> {
  bool _hasPermission = false;
  String _permissionStatusMessage = 'Granting permission...';

  @override
  void initState() {
    super.initState();
    requestCameraPermission();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AR View'),
      ),
      body: _hasPermission
          ? const Center(
              child: Text(
                '🔧 Unity 연동 뷰가 여기에 들어갈 예정입니다.',
                style: TextStyle(fontSize: 16),
              ),
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _permissionStatusMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      openAppSettings();
                    },
                    child: const Text('설정 열기'),
                  ),
                ],
              ),
            ),
    );
  }
}