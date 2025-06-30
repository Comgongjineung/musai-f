import 'dart:ui';
import 'package:flutter/material.dart';
import 'camera_view.dart';
import 'fail_dialog.dart';
//import 'success_dialog.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'describe_page.dart';
import 'bottom_nav_bar.dart';
import 'describe_box.dart';

void main() {
  runApp(const MusaiApp());
}

class MusaiApp extends StatelessWidget {
  const MusaiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Pretendard',
        primarySwatch: Colors.grey,
        scaffoldBackgroundColor: const Color(0xFF5F5F5F),
      ),
      home: const MusaiHomePage(),
    );
  }
}

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

  // 결과 저장용 상태
  String title = '';
  String artist = '';
  String year = '';
  String description = '';
  String imageUrl = '';
  File? analyzedImage;

  Future<void> uploadImage(BuildContext context, File imageFile) async {
    final uri = Uri.parse("http://52.78.107.134:8080/recog/analyze");
    var request = http.MultipartRequest("POST", uri);
    request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    try {
      bool isTimeout = false;
      // API 호출 타임아웃 처리
      Future.delayed(const Duration(seconds: 10), () {
        if (isRecognizing && !isTimeout && mounted) { // isRecognizing 상태로 타임아웃 체크
          isTimeout = true;
          setState(() {
            isRecognizing = false; // 타임아웃 시 로딩 상태 해제
          });
          showDialog(
            context: context,
            builder: (_) => const FailDialog(),
          );
        }
      });

      final response = await request.send();

      if (mounted) { // 위젯 마운트 상태 확인
        if (response.statusCode == 200) {
          print('✅ 작품 인식 성공');
          // 성공 시 isRecognizing 상태 해제 및 DescribePage로 이동
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
        } else {
          print('❌ 작품 인식 실패');
          // 실패 시 isRecognizing 상태 해제 및 FailDialog 표시
          setState(() {
            isRecognizing = false;
          });
           showDialog(
            context: context,
            builder: (_) => const FailDialog(),
          );
        }
      }
    } catch (e) {
      print('❌ 에러 발생: $e');
      // 에러 발생 시 isRecognizing 상태 해제 및 FailDialog 표시
      if(mounted) {
        setState(() {
          isRecognizing = false;
        });
         showDialog(
          context: context,
          builder: (_) => const FailDialog(),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: GestureDetector(
        onTap: () async {
          final picture = await _cameraViewKey.currentState?.takePicture();
          if (picture != null) {
            final bytes = await picture.readAsBytes();
            final dir = await getTemporaryDirectory();
            final file = File('${dir.path}/captured.jpg');
            await file.writeAsBytes(bytes);
            
            // 사진 촬영 후 로딩 시작 (isRecognizing 상태 true)
            setState(() {
              isRecognizing = true;
              isPhotoCaptured = true;
            });

            // uploadImage 함수 호출 (API 호출 및 결과 처리)
            await uploadImage(context, file);

            // uploadImage 내에서 isRecognizing 상태가 업데이트 되므로 여기서 추가적인 setState는 필요 없습니다.
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
            Positioned.fill(child: CameraView(key: _cameraViewKey)),
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
                      color: const Color(0xFFEAE1DC),
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
                  const Spacer(),
                  BottomNavBarWidget(currentIndex: 1),
                ],
              ),
            ),
            /*
            if (isRecognizing)
              SuccessDialog(
                onCompleted: () {
                  // SuccessDialog 내용은 describe_page에서
                },
              ),
            */
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          print('📦 Disposing cameraView before ARView');
          _cameraViewKey.currentState?.dispose();
        },
        backgroundColor: Colors.deepOrange,
        child: Icon(Icons.view_in_ar), // 원하는 색상
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