import 'dart:ui';
import 'package:flutter/material.dart';
import 'camera_view.dart';
import 'fail_dialog.dart';
import 'success_dialog.dart';

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
  bool isRecognizing = false;  // 인식 중인지 상태 관리

  @override
  void initState() {
    super.initState();

    // 10초 후 실패 다이얼로그 표시
    Future.delayed(const Duration(seconds: 10), () {
      showDialog(
        context: context,
        builder: (_) => const FailDialog(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 카메라 전체 화면
          const Positioned.fill(child: CameraView()),

          // 마스크 
          Positioned.fill(
            child: CustomPaint(
              painter: HolePainter(),
            ),
          ),

          // 점선 사각형
          Positioned(
            top: 180, 
            left: 24,
            right: 24,
            child: AspectRatio(
              aspectRatio: 3 / 4.7,
              child: DashedBorderContainer(
                child: Container(), // 그냥 빈 영역
              ),
            ),
          ),

          // 오버레이 UI
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 16),
                const Text(
                  'musai',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAE1DC),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '사각형 영역 안에 작품을 위치시켜주세요',
                    style: TextStyle(
                      color: Color(0xFF706B66), 
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 28),

                const Spacer(),

                // 하단 네비게이션
                Padding(
                  padding: const EdgeInsets.only(bottom: 0), // 원하는 만큼 조절 가능
                  child: Container(
                    height: 80,
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
                        Icon(Icons.calendar_today, color: Colors.white, size: 28),
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
            height: 30,
            child: Container(
               color: const Color(0xFF5E5955), // 하단바 색상 그대로
            ),
          ),

          // 작품 인식 중일 때만 보여줄 로딩 화면
          if (isRecognizing) const SuccessDialog(),
        ],
      ),
      // 테스트용 버튼
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            isRecognizing = true;  // 인식 시작
          });
        },
        child: const Icon(Icons.check),
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
    return LayoutBuilder(builder: (context, constraints) {
      final size = constraints.biggest;
      final rect = padding.resolve(TextDirection.ltr).deflateRect(Offset.zero & size);

      return CustomPaint(
        size: size,
        painter: _DarkMaskPainter(rect, borderRadius),
      );
    });
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
    final inner = Path()
      ..addRRect(RRect.fromRectAndRadius(holeRect, Radius.circular(radius)))
      ..close();

    // combine paths with difference: outer - inner
    canvas.drawPath(Path.combine(PathOperation.difference, outer, inner), paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class HolePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    final holeTop = 180.0;
    final horizontalPadding = 24.0;
    final holeWidth = size.width - 2 * horizontalPadding;
    final holeHeight = holeWidth * (4.7 / 3); // 3:4.5 비율

    final holeRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        horizontalPadding,
        holeTop,
        holeWidth,
        holeHeight,
      ),
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

