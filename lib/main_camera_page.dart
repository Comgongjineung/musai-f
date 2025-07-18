import 'package:flutter/material.dart';
import 'camera_view.dart';
import 'fail_dialog.dart';
import 'describe_page.dart';
import 'bottom_nav_bar.dart';
import 'ar_camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';
import 'dart:ui';
import 'login_google.dart';

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
    print('🔍 uploadImage 시작 - 파일 경로: ${imageFile.path}');
    print('🔍 파일 크기: ${await imageFile.length()} bytes');
    
    final uri = Uri.parse("http://43.203.23.173:8080/recog/analyzeAndRegister");
    print('🔍 API 엔드포인트: $uri');
    
    var request = http.MultipartRequest("POST", uri);
    request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));
    print('🔍 HTTP 요청 생성 완료');

    try {
      bool isTimeout = false;
      // API 호출 타임아웃 처리
      Future.delayed(const Duration(seconds: 10), () {
        if (isRecognizing && !isTimeout && mounted) { // isRecognizing 상태로 타임아웃 체크
          isTimeout = true;
          print('⏰ API 호출 타임아웃 발생');
          setState(() {
            isRecognizing = false; // 타임아웃 시 로딩 상태 해제
          });
          showDialog(
            context: context,
            builder: (_) => const FailDialog(),
          );
        }
      });

      print('🔍 HTTP 요청 전송 시작...');
      final response = await request.send();
      print('🔍 HTTP 응답 수신 - 상태 코드: ${response.statusCode}');

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
          print('❌ 작품 인식 실패 - 상태 코드: ${response.statusCode}');
          print('🔍 응답 헤더: ${response.headers}');
          
          // 응답 본문 읽기 시도
          try {
            final responseBody = await response.stream.bytesToString();
            print('🔍 응답 본문: $responseBody');
          } catch (e) {
            print('🔍 응답 본문 읽기 실패: $e');
          }
          
          // 실패 시에도 DescribePage로 이동 (서버 문제일 수 있으므로)
          print('🔍 서버 오류로 인해 DescribePage로 이동');
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
      }
    } catch (e) {
      print('❌ 에러 발생: $e');
      print('🔍 에러 타입: ${e.runtimeType}');
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
        behavior: HitTestBehavior.opaque,
        onTap: () async {
          print('🔍 터치 이벤트 발생');
          print('🔍 _cameraViewKey.currentState: ${_cameraViewKey.currentState}');
          
          if (_cameraViewKey.currentState == null) {
            print('❌ CameraView 상태가 null입니다');
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
              
              // 사진 촬영 후 로딩 시작 (isRecognizing 상태 true)
              setState(() {
                isRecognizing = true;
                isPhotoCaptured = true;
              });

              print('🔍 uploadImage 함수 호출 시작');
              // uploadImage 함수 호출 (API 호출 및 결과 처리)
              await uploadImage(context, file);
            } else {
              print('❌ 사진 촬영 실패: picture가 null입니다');
            }
          } catch (e) {
            print('❌ 사진 촬영 중 오류 발생: $e');
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
                  Expanded(child: Container()),
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
      floatingActionButton: ElevatedButton(
        onPressed: () async {
          print('버튼 눌림');
          await signInWithGoogle(); // 이게 실제로 호출되고 있는지 확인
        },
        child: Text('Google 로그인'),
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