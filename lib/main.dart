import 'dart:ui';
import 'package:flutter/material.dart';
import 'camera_view.dart';
import 'fail_dialog.dart';

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
  @override
  void initState() {
    super.initState();

    // 10초 후 실패 다이얼로그 표시
    Future.delayed(const Duration(seconds: 10), () {
      showDialog(
        context: context,
        builder: (_) => const FailDialog(), // <- 분리한 위젯을 사용!
      );
    });
  }

  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),

            // 앱 타이틀
            const Text(
              'musai',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 12),

            // 안내 문구
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
              decoration: BoxDecoration(
                color: const Color(0xFFD3D3D3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                '사각형 영역 안에 작품을 위치시켜주세요',
                style: TextStyle(color: Color(0xFF666666), fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 24),

            // 카메라 뷰 (비율 맞춰 중앙에)
            AspectRatio(
              aspectRatio: 3 / 4, // 정사각형보다 살짝 세로로 긴 형태
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: DashedBorderContainer(child: const CameraView()),
              ),
            ),

            const Spacer(),

            // 하단 네비게이션 바
            Container(
              height: 80,
              decoration: const BoxDecoration(
                color: Color(0xFF7A7A7A),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
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

            // 하단 인디케이터
            const SizedBox(height: 8),
            Container(
              height: 5,
              width: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 10),
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
