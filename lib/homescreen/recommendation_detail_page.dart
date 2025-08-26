import 'package:flutter/material.dart';
import '../bottom_nav_bar.dart';
import '../app_bar_widget.dart';

class RecommendResponse {
  final int userId;
  final Map<String, dynamic> styleCounts;
  final List<RecommendItem> recommendations;

  RecommendResponse({
    required this.userId,
    required this.styleCounts,
    required this.recommendations,
  });

  factory RecommendResponse.fromJson(Map<String, dynamic> json) {
    final list = (json['recommendations'] as List? ?? [])
        .map((e) => RecommendItem.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
    return RecommendResponse(
      userId: json['userId'] ?? 0,
      styleCounts: (json['styleCounts'] as Map?)?.cast<String, dynamic>() ?? {},
      recommendations: list,
    );
  }
}

class RecommendItem {
  final String primaryImageSmall;
  final String name;
  final String department;
  final String title;
  final String culture;
  final String period;
  final String objectDate;
  final int? objectBeginDate;
  final int? objectEndDate;
  final int? objectID;
  final String classification;
  final String style;
  final String objectName;

  RecommendItem({
    required this.primaryImageSmall,
    required this.name,
    required this.department,
    required this.title,
    required this.culture,
    required this.period,
    required this.objectDate,
    required this.objectBeginDate,
    required this.objectEndDate,
    required this.objectID,
    required this.classification,
    required this.style,
    required this.objectName,
  });

  factory RecommendItem.fromJson(Map<String, dynamic> j) => RecommendItem(
        primaryImageSmall: j['primaryImageSmall'] ?? '',
        name: j['name'] ?? '',
        department: j['department'] ?? '',
        title: j['title'] ?? '',
        culture: j['culture'] ?? '',
        period: j['period'] ?? '',
        objectDate: j['objectDate']?.toString() ?? '',
        objectBeginDate: j['objectBeginDate'] is int ? j['objectBeginDate'] : null,
        objectEndDate: j['objectEndDate'] is int ? j['objectEndDate'] : null,
        objectID: j['objectID'] is int ? j['objectID'] : null,
        classification: j['classification'] ?? '',
        style: j['style'] ?? '',
        objectName: j['objectName'] ?? '',
      );
}

class DetailRecommendPage extends StatelessWidget {
  final RecommendItem item;
  const DetailRecommendPage({super.key, required this.item});

  String _dash(String v) => v.trim().isEmpty ? '미상' : v;

  @override
  Widget build(BuildContext context) {
    // ----- 비율 스케일 -----
    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;
    final screenHeight = size.height;
    final sx = screenWidth / 390.0;
    final sy = screenHeight / 841.0;
    double sr(double v) => v * ((sx + sy) / 2);

    final title = item.title.isNotEmpty ? item.title : '작품 제목';

    return Theme(
      data: Theme.of(context).copyWith(
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white, // 스크롤 틴트 제거
          elevation: 0,
          shadowColor: Colors.transparent,
          scrolledUnderElevation: 0,
          foregroundColor: Colors.black,
          centerTitle: true,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: const AppBarWidget(showBackButton: true),
        // 하단바 표시 (홈 탭 활성 가정: 0)
        bottomNavigationBar: const BottomNavBarWidget(currentIndex: 0),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24 * sx, vertical: 12 * sy),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 포스터 카드 (시안 느낌: 흰 카드, 얇은 테두리, 둥근 모서리)
                AspectRatio(
                  aspectRatio: 3 / 4,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(sr(20)),
                      border: Border.all(color: const Color(0xFFE9E9E9)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: item.primaryImageSmall.isEmpty
                        ? const Center(child: Icon(Icons.image_not_supported))
                        : Image.network(
                            item.primaryImageSmall,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Center(child: Icon(Icons.broken_image)),
                          ),
                  ),
                ),

                SizedBox(height: 24 * sy),

                // 제목 (시안: 굵은 제목, 여백 넉넉)
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20 * sr(1), // ≈ titleLarge보다 살짝 작게 고정
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                    color: const Color(0xFF111111),
                  ),
                ),

                SizedBox(height: 20 * sy),

                // 메타 정보 (라벨 좌측 정렬)
                _MetaRow(
                  label: '작가이름',
                  value: _dash(item.name),
                  sx: sx,
                  sy: sy,
                ),
                _MetaRow(
                  label: '제작시기',
                  value: _dash(item.objectDate),
                  sx: sx,
                  sy: sy,
                ),
                _MetaRow(
                  label: '예술사조',
                  value: _dash(item.style),
                  sx: sx,
                  sy: sy,
                ),

                SizedBox(height: 20 * sy),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final String label;
  final String value;
  final double sx;
  final double sy;

  const _MetaRow({
    required this.label,
    required this.value,
    required this.sx,
    required this.sy,
  });

  @override
  Widget build(BuildContext context) {
    double sr(double v) => v * ((sx + sy) / 2);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6 * sy),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80 * sx,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14 * sr(1),
                fontWeight: FontWeight.w600,
                color: const Color(0xFF222222),
                height: 1.4,
              ),
            ),
          ),
          SizedBox(width: 8 * sx),
          Expanded(
            child: Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14 * sr(1),
                fontWeight: FontWeight.w400,
                color: const Color(0xFF222222),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
