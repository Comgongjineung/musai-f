import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'camera_view.dart';
import '../describe/describe_page.dart';
import '../bottom_nav_bar.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:ui';

class MusaiHomePage extends StatefulWidget {
  const MusaiHomePage({super.key});

  @override
  State<MusaiHomePage> createState() => _MusaiHomePageState();
}

class _MusaiHomePageState extends State<MusaiHomePage> {
  bool isRecognizing = false;
  bool isPhotoCaptured = false;
  final GlobalKey<CameraViewState> _cameraViewKey = GlobalKey<CameraViewState>();
  //final ArtCameraController _cameraController = ArtCameraController();

  Future<void> uploadImage(BuildContext context, File imageFile) async {
  print('🔍 uploadImage 시작 - 파일 경로: ${imageFile.path}');
  print('🔍 파일 크기: ${await imageFile.length()} bytes');

  // 더 이상 여기서 API 호출 안함
  // 바로 DescribePage로 이동만 함
  if (!mounted) return;

  setState(() {
    isRecognizing = false;
  });

  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (context) => DescribePage(
        imagePath: imageFile.path,
      ),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light, // Android: white icons
        statusBarBrightness: Brightness.dark,      // iOS: white icons
      ),
      child: Scaffold(
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () async {
            if (isRecognizing) {
      print('⚠️ 인식 중에는 다시 촬영할 수 없습니다.');
      return;
    }

    // 터치 즉시 인식 중으로 설정 (race condition 방지)
    setState(() {
      isRecognizing = true;
    });
            print('🔍 터치 이벤트 발생');
            print('🔍 _cameraViewKey.currentState: ${_cameraViewKey.currentState}');
            
            if (_cameraViewKey.currentState == null) {
              print('❌ CameraView 상태가 null입니다');
              setState(() {
        isRecognizing = false; // 오류 발생 시 다시 false로 설정
      });
              return;
            }
            
            try {
              final picture = await _cameraViewKey.currentState!.takePicture();
              print('🔍 사진 촬영 결과: $picture');
              
              if (picture != null) {
                final bytes = await picture.readAsBytes();
                final dir = await getTemporaryDirectory();
                final file = File('${dir.path}/captured.jpg');
                await file.writeAsBytes(bytes);
                
                print('🔍 파일 저장 완료: ${file.path}');
                
                // uploadImage 함수 호출 (API 호출 및 결과 처리)
                await uploadImage(context, file);
              } else {
                print('❌ 사진 촬영 실패: picture가 null입니다');
                setState(() {
          isRecognizing = false; // 실패 시 복구
        });
              }
            } catch (e) {
              print('❌ 사진 촬영 중 오류 발생: $e');
              setState(() {
        isRecognizing = false; // 예외 발생 시 복구
      });
            }
          },
          onScaleStart: (details) {
            _cameraViewKey.currentState?.onZoomStart(details);
          },
          onScaleUpdate: (details) {
            _cameraViewKey.currentState?.onZoomUpdate(details);
          },
          child: Stack(
            children: [
              Positioned.fill(child: IgnorePointer(child: CameraView(key: _cameraViewKey))),
              Positioned.fill(child: CustomPaint(painter: HolePainter())),
              Positioned(
                top: screenHeight * 0.215,
                left: screenWidth * 0.065,
                right: screenWidth * 0.065,
                child: AspectRatio(
                  aspectRatio: 3 / 4.6,
                  child: DashedBorderContainer(child: Container()),
                ),
              ),
              SafeArea(
                child: Column(
                  children: [
                    SizedBox(height: screenHeight * 0.001),
                    Text(
                      'musai',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: screenWidth * 0.08,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.018),
                    Container(
                      padding: EdgeInsets.symmetric(
                        vertical: screenHeight * 0.01,
                        horizontal: screenWidth * 0.05,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF6F2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '영역 안에 작품을 위치시키고 화면을 터치해주세요',
                        style: TextStyle(
                          color: const Color(0xFF706B66),
                          fontSize: screenWidth * 0.035,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.015),
                    Expanded(child: Container()),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: const BottomNavBarWidget(currentIndex: 1),
      ),
    );
  }
}

class DashedBorderContainer extends StatelessWidget {
  final Widget child;
  const DashedBorderContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: DashedBorderPainter(),
      child: ClipRRect(borderRadius: BorderRadius.circular(20), child: child),
    );
  }
}

class DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(20),
      ));

    final dashPath = Path();
    const double dashWidth = 10.0;
    const double dashSpace = 5.0;

    double distance = 0.0;
    for (PathMetric pathMetric in path.computeMetrics()) {
      while (distance < pathMetric.length) {
        dashPath.addPath(
          pathMetric.extractPath(distance, distance + dashWidth), 
          Offset.zero,
        );
        distance += dashWidth + dashSpace;
      }
    }

    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class HolePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    final holeTop = size.height * 0.215;
    final horizontalPadding = size.width * 0.065;
    final holeWidth = size.width - 2 * horizontalPadding;
    final holeHeight = holeWidth * (4.6 / 3);

    final holeRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(horizontalPadding, holeTop, holeWidth, holeHeight),
      const Radius.circular(20),
    );

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(holeRect)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}