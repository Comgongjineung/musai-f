import 'package:flutter/material.dart';
import 'package:camerawesome/camerawesome_plugin.dart';
import 'dart:math';

class CustomCameraScreen extends StatefulWidget {
  const CustomCameraScreen({Key? key}) : super(key: key);

  @override
  State<CustomCameraScreen> createState() => _CustomCameraScreenState();
}

class _CustomCameraScreenState extends State<CustomCameraScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ✅ 카메라 프리뷰
          CameraAwesomeBuilder.awesome(
            sensor: Sensors.back,
            saveConfig: SaveConfig.photo(
              pathBuilder: () async => '/tmp',
            ),
          ),

          // ✅ 점선 사각형 오버레이
          _CameraOverlay(),

          // ✅ 상단 중앙 로고
          Positioned(
            top: 60,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'musai',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // ✅ 안내 문구
          Positioned(
            top: 110,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '사각형 영역 안에 작품을 위치시켜주세요',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CameraOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width * 0.85;
    final double height = width * 1.2;
    final double top = (MediaQuery.of(context).size.height - height) / 2;

    return Stack(
      children: [
        // 어둡게 처리
        Positioned.fill(
          child: Container(
            color: Colors.black.withOpacity(0.4),
          ),
        ),
        // 점선 사각형
        Positioned(
          top: top,
          left: (MediaQuery.of(context).size.width - width) / 2,
          child: Container(
            width: width,
            height: height,
            color: Colors.transparent,
            child: CustomPaint(
              painter: DashedRectPainter(),
            ),
          ),
        ),
      ],
    );
  }
}

class DashedRectPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const dashWidth = 8.0;
    const dashSpace = 6.0;
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    _drawDashedLine(canvas, Offset(rect.left, rect.top), Offset(rect.right, rect.top), paint, dashWidth, dashSpace);
    _drawDashedLine(canvas, Offset(rect.right, rect.top), Offset(rect.right, rect.bottom), paint, dashWidth, dashSpace);
    _drawDashedLine(canvas, Offset(rect.right, rect.bottom), Offset(rect.left, rect.bottom), paint, dashWidth, dashSpace);
    _drawDashedLine(canvas, Offset(rect.left, rect.bottom), Offset(rect.left, rect.top), paint, dashWidth, dashSpace);
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint, double dashWidth, double dashSpace) {
    double dx = end.dx - start.dx;
    double dy = end.dy - start.dy;
    double distance = sqrt(dx * dx + dy * dy);
    double dashCount = distance / (dashWidth + dashSpace);
    double x = start.dx, y = start.dy;
    double stepX = dx / dashCount, stepY = dy / dashCount;

    for (int i = 0; i < dashCount; i++) {
      canvas.drawLine(
        Offset(x, y),
        Offset(
          x + stepX * (dashWidth / (dashWidth + dashSpace)),
          y + stepY * (dashWidth / (dashWidth + dashSpace)),
        ),
        paint,
      );
      x += stepX;
      y += stepY;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}