import 'package:flutter/material.dart';
import 'package:ar_flutter_plugin_2/widgets/ar_view.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ar_flutter_plugin_2/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin_2/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_session_manager.dart';
import 'ar_bubble_ui.dart';

class ARViewPage extends StatefulWidget {
  const ARViewPage({Key? key}) : super(key: key);

  @override
  State<ARViewPage> createState() => _ARViewPageState();
}

class _ARViewPageState extends State<ARViewPage> {
  late ARSessionManager arSessionManager;
  late ARObjectManager arObjectManager;
  late ARAnchorManager arAnchorManager;

  bool _hasPermission = false;
  String _permissionStatusMessage = 'Granting permission...';

  bool _arExplainActive = false;

  @override
  void initState() {
    super.initState();
    requestCameraPermission();
  }

  Future<void> requestCameraPermission() async {
    final status = await Permission.camera.status;
    if (status.isGranted) {
      setState(() => _hasPermission = true);
    } else {
      final result = await Permission.camera.request();
      if (result.isGranted) {
        setState(() => _hasPermission = true);
      } else {
        setState(() => _permissionStatusMessage = '카메라 권한이 완전히 거부되었습니다. 설정에서 권한을 허용해주세요.');
      }
    }
  }

  @override
  void dispose() {
    arSessionManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AR View'),
        actions: [
          IconButton(
            icon: Icon(
              Icons.bubble_chart,
              color: _arExplainActive ? Colors.orange : Colors.white,
            ),
            onPressed: () {
              setState(() => _arExplainActive = !_arExplainActive);
            },
          ),
        ],
      ),
      body: _hasPermission
          ? Stack(
              children: [
                ARView(onARViewCreated: onARViewCreated),
                if (_arExplainActive)
                  GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () => setState(() => _arExplainActive = false),
                    child: ARExplainOverlay(
                      points: [
                        ExplainPoint(offset: Offset(120, 250), description: '이 부분은 작가의 시선이 시작되는 지점입니다.'),
                        ExplainPoint(offset: Offset(220, 340), description: '여기에는 숨겨진 상징이 숨어 있습니다.'),
                        ExplainPoint(offset: Offset(80, 420), description: '빛의 방향은 작품의 흐름을 유도합니다.'),
                        ExplainPoint(offset: Offset(180, 520), description: '이 구조는 전체 주제와 연결되어 있습니다.'),
                      ],
                    ),
                  ),
              ],
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
                    onPressed: () => openAppSettings(),
                    child: const Text('설정 열기'),
                  ),
                ],
              ),
            ),
    );
  }

  void onARViewCreated(
    ARSessionManager arSessionManager,
    ARObjectManager arObjectManager,
    ARAnchorManager arAnchorManager,
    ARLocationManager arLocationManager,
  ) {
    this.arSessionManager = arSessionManager;
    this.arObjectManager = arObjectManager;
    this.arAnchorManager = arAnchorManager;

    arSessionManager.onInitialize(
      showFeaturePoints: false,
      showPlanes: true,
      customPlaneTexturePath: "assets/images/pointer.png",
      showWorldOrigin: true,
    );
    arObjectManager.onInitialize();
  }
}
