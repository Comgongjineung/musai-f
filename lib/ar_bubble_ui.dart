import 'package:flutter/material.dart';

class ExplainPoint {
  final Offset offset;
  final String description;
  ExplainPoint({required this.offset, required this.description});
}

class ARExplainOverlay extends StatelessWidget {
  final List<ExplainPoint> points;
  final VoidCallback? onBackgroundTap;

  const ARExplainOverlay({
    super.key,
    required this.points,
    this.onBackgroundTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onBackgroundTap,
      child: Stack(
        children: points
            .map((point) => Positioned(
                  left: point.offset.dx,
                  top: point.offset.dy,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _SpeechBubble(text: point.description),
                      const SizedBox(height: 4),
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.9),
                          border: Border.all(color: Colors.black26),
                        ),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }
}

class _SpeechBubble extends StatelessWidget {
  final String text;

  const _SpeechBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 180),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 14, color: Colors.black87),
        textAlign: TextAlign.center,
      ),
    );
  }
}
