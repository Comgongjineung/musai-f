import 'dart:ui';
import 'package:flutter/material.dart';
import 'camera_view.dart';
import 'fail_dialog.dart';
import 'success_dialog.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
  bool isRecognizing = false; // 인식 중인지 상태 관리
  bool isPhotoCaptured = false; // 사진 촬영 성공 여부
  bool hasShownFailDialog = false; // 실패 다이얼로그 표시 여부
  final GlobalKey<CameraViewState> _cameraViewKey =
      GlobalKey<CameraViewState>();

  @override
  void initState() {
    super.initState();

    // 10초 후 실패 다이얼로그 표시 (사진이 찍히지 않았을 때만)
    Future.delayed(const Duration(seconds: 10), () {
      if (!isPhotoCaptured && !hasShownFailDialog) {
        showDialog(
          context: context,
          builder: (_) => const FailDialog(),
        ).then((_) {
          // 팝업 닫음 표시
          hasShownFailDialog = false;

          // 팝업 닫고 15초 후 다시 실패 시 다이얼로그 표시
          Future.delayed(const Duration(seconds: 15), () {
            if (!isPhotoCaptured && !hasShownFailDialog) {
              showDialog(
                context: context,
                builder: (_) => const FailDialog(),
              ).then((_) => hasShownFailDialog = false);
              hasShownFailDialog = true;
            }
          });
        });
        hasShownFailDialog = true;
      }
    });
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

            // API 호출
            print('✅ 사진 파일 생성됨: ${file.path}');
            await uploadImage(file);

            setState(() {
              isRecognizing = true;
              isPhotoCaptured = true; // 사진 촬영 성공 -> false면 실패 팝업 안뜸
            });
          } else {
            print('❌ 사진 촬영 실패');
          }
        },
        child: Stack(
          children: [
            // 카메라 전체 화면
            Positioned.fill(child: CameraView(key: _cameraViewKey)),

            // 마스크
            Positioned.fill(child: CustomPaint(painter: HolePainter())),

            // 점선 사각형 (반응형)
            Positioned(
              top: MediaQuery.of(context).size.height * 0.215, // 화면 높이에 비례한 위치 
              left: MediaQuery.of(context).size.width * 0.065,
              right: MediaQuery.of(context).size.width * 0.065,
              child: AspectRatio(
                aspectRatio: 3 / 4.6,
                child: DashedBorderContainer(
                  child: Container(), // 그냥 빈 영역
                ),
              ),
            ),

            // 오버레이 UI
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

                  // 하단 네비게이션
                  Padding(
                    padding: const EdgeInsets.only(bottom: 0), 
                    child: Container(
                      height: screenHeight * 0.09,
                      decoration: const BoxDecoration(
                        color: Color(0xFF5E5955),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: const [
                          Icon(Icons.home, color: Colors.white, size: 28),
                          Icon(Icons.camera_alt, color: Colors.white, size: 28),
                          Icon(
                            Icons.calendar_today,
                            color: Colors.white,
                            size: 28,
                          ),
                          Icon(Icons.person, color: Colors.white, size: 28),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // 하단바 색상 그대로
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 40,
              child: Container(
                color: const Color(0xFF5E5955), // 하단바 색상 그대로
              ),
            ),

            // 작품 인식 중일 때만 보여줄 로딩 화면
            if (isRecognizing) const SuccessDialog(),
          ],
        ),
      ),
    );
  }
}

// Custom widget for dashed border
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
    final Paint paint =
        Paint()
          ..color = Colors.white
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;

    final Path path =
        Path()..addRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(0, 0, size.width, size.height),
            const Radius.circular(20),
          ),
        );

    final Path dashPath = Path();
    const double dashWidth = 10.0;
    const double dashSpace = 5.0;

    double distance = 0.0;
    for (PathMetric pathMetric in path.computeMetrics()) {
      while (distance < pathMetric.length) {
        dashPath.addPath(
          pathMetric.extractPath(distance, distance + dashWidth),
          Offset.zero,
        );
        distance += dashWidth;
        distance += dashSpace;
      }
    }

    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class DarkMask extends StatelessWidget {
  final double borderRadius;
  final EdgeInsetsGeometry padding;

  const DarkMask({
    super.key,
    required this.borderRadius,
    required this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final rect = padding
            .resolve(TextDirection.ltr)
            .deflateRect(Offset.zero & size);

        return CustomPaint(
          size: size,
          painter: _DarkMaskPainter(rect, borderRadius),
        );
      },
    );
  }
}

class _DarkMaskPainter extends CustomPainter {
  final Rect holeRect;
  final double radius;

  _DarkMaskPainter(this.holeRect, this.radius);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withOpacity(0.5);

    final outer = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final inner =
        Path()
          ..addRRect(RRect.fromRectAndRadius(holeRect, Radius.circular(radius)))
          ..close();

    // combine paths with difference: outer - inner
    canvas.drawPath(
      Path.combine(PathOperation.difference, outer, inner),
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class HolePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.black.withOpacity(0.5)
          ..style = PaintingStyle.fill;

    // Responsive layout based on size
    final holeTop = size.height * 0.215;
    final horizontalPadding = size.width * 0.065;
    final holeWidth = size.width - 2 * horizontalPadding;
    final holeHeight = holeWidth * (4.6 / 3);

    final holeRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(horizontalPadding, holeTop, holeWidth, holeHeight),
      const Radius.circular(20),
    );

    final path =
        Path()
          ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
          ..addRRect(holeRect)
          ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

Future<void> uploadImage(File imageFile) async {
  final uri = Uri.parse("http://52.79.54.131:8080/recog/analyze"); // fast api 서버: 사진 정보 받아옴
  var request = http.MultipartRequest("POST", uri);

  request.files.add(
    await http.MultipartFile.fromPath('file', imageFile.path),
  );

  final response = await request.send();

  if (response.statusCode == 200) {
    final res = await http.Response.fromStream(response);
    final json = jsonDecode(res.body);

    final vision = json['vision_result'];
    final gemini = json['gemini_result'];

    print('✅ 제목: $vision');
    print('✅ 설명(gemini): $gemini');

  } else {
    print('❌ 업로드 실패: ${response.statusCode}');
  }
}