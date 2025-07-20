import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'bottom_nav_bar.dart';
import 'app_bar_widget.dart';

class Exhibition {
  final String title;
  final String category;
  final String status;
  final String price;
  final String date;
  final String time;
  final String place;
  final String description;
  final String homepageUrl;
  final String detailInfo;

  Exhibition({
    required this.title,
    required this.category,
    required this.status,
    required this.price,
    required this.date,
    required this.time,
    required this.place,
    required this.description,
    required this.homepageUrl,
    required this.detailInfo,
  });
}

class ExhibitionDetailPage extends StatefulWidget {
  final Exhibition exhibition;
  const ExhibitionDetailPage({super.key, required this.exhibition});

  @override
  State<ExhibitionDetailPage> createState() => _ExhibitionDetailPageState();
}

class _ExhibitionDetailPageState extends State<ExhibitionDetailPage> {
  int selectedTab = 0; // 0: 상세 내용, 1: 상세 정보

  @override
  Widget build(BuildContext context) {
    final ex = widget.exhibition;
    final width = MediaQuery.of(context).size.width;
    
    // 반응형 폰트 크기 계산
    final baseFontSize = width <= 360 ? 0.95 : width >= 768 ? 1.1 : 1.0;
    final titleFontSize = 20 * baseFontSize;
    final mediumFontSize = 16 * baseFontSize;
    final smallFontSize = 12 * baseFontSize;
    
    // 반응형 여백 계산
    final baseSpacing = width <= 360 ? 0.9 : width >= 768 ? 1.2 : 1.0;
    final marginHorizontal = 24 * baseSpacing;
    final spacing4 = 4 * baseSpacing;
    final spacing8 = 8 * baseSpacing;
    final spacing12 = 12 * baseSpacing;
    final spacing16 = 16 * baseSpacing;
    final spacing20 = 20 * baseSpacing;
    final spacing24 = 24 * baseSpacing;
    
    // 전시 이미지 크기 계산 (343:264 비율)
    final imageWidth = width - (marginHorizontal * 2);
    final imageHeight = (imageWidth * 264) / 343;
    
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDFC),
      appBar: const AppBarWidget(
        showBackButton: true,
        backgroundColor: Color(0xFFFFFDFC),
        titleSize: 22,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: marginHorizontal),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 전시 메인 포스터 (343:264 비율)
              SizedBox(height: spacing24),
              Center(
                child: Container(
                  width: imageWidth,
                  height: imageHeight,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F0ED),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  alignment: Alignment.center,
                  child: const Text('전시회 메인 포스터', style: TextStyle(color: Color(0xFFB1B1B1))),
                ),
              ),
              SizedBox(height: spacing16),
              
              // 카테고리 + 상태 뱃지
              Wrap(
                spacing: spacing8,
                runSpacing: spacing8,
                children: [
                  _Tag(
                    text: ex.category, 
                    bgColor: const Color(0xFFF8EFEA), 
                    textColor: Colors.black,
                    fontSize: mediumFontSize,
                  ),
                  _Tag(
                    text: ex.status, 
                    bgColor: const Color(0xFFB75456), // 원래 0xFFC46567 
                    textColor: Colors.white,
                    fontSize: mediumFontSize,
                  ),
                ],
              ),
              SizedBox(height: spacing8),
              
              // 전시 제목
              Text(
                ex.title, 
                style: TextStyle(
                  fontWeight: FontWeight.w600, 
                  fontSize: titleFontSize, 
                  color: const Color(0xFF343231), 
                  fontFamily: 'Pretendard',
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: spacing12),
              
              // 전시 상세 정보
              _InfoRow(label: '가격', value: ex.price, fontSize: mediumFontSize, valueFontSize: mediumFontSize),
              SizedBox(height: spacing4),
              _InfoRow(label: '일정', value: ex.date, fontSize: mediumFontSize, valueFontSize: mediumFontSize),
              SizedBox(height: spacing4),
              _InfoRow(label: '시간', value: ex.time, fontSize: mediumFontSize, valueFontSize: mediumFontSize),
              SizedBox(height: spacing4),
              _InfoRow(label: '장소', value: ex.place, fontSize: mediumFontSize, valueFontSize: mediumFontSize),
              SizedBox(height: spacing12),
              
              // 상세 내용 / 상세 정보 탭
              Row(
                children: [
                  _TabButton(
                    text: '상세 내용',
                    selected: selectedTab == 0,
                    onTap: () => setState(() => selectedTab = 0),
                    fontSize: mediumFontSize,
                  ),
                  SizedBox(width: spacing20),
                  _TabButton(
                    text: '상세 정보',
                    selected: selectedTab == 1,
                    onTap: () => setState(() => selectedTab = 1),
                    fontSize: mediumFontSize,
                  ),
                ],
              ),
              SizedBox(height: spacing4),
              
              // 탭 콘텐츠
              if (selectedTab == 0) ...[
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: spacing20, vertical: spacing20), //원래 16 12
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8EFEA),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () async {
                          if (ex.homepageUrl.isNotEmpty) {
                            final Uri url = Uri.parse(ex.homepageUrl);
                            if (await canLaunchUrl(url)) {
                              await launchUrl(url, mode: LaunchMode.externalApplication);
                            } else {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('링크를 열 수 없습니다.')),
                                );
                              }
                            }
                          } else {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('홈페이지 링크가 없습니다.')),
                              );
                            }
                          }
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: spacing16, vertical: spacing8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFBDAF9D),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '홈페이지 바로가기', 
                            style: TextStyle(
                              color: Colors.white, 
                              fontWeight: FontWeight.w400,
                              fontSize: mediumFontSize,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: spacing12),
                      Text(
                        ex.description, 
                        style: TextStyle(
                          fontSize: smallFontSize, 
                          color: const Color(0xFF343231),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      SizedBox(height: spacing16),
                      Container(
                        width: double.infinity,
                        height: imageHeight * 0.6,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE6E0DC),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '전시회에서 제공하는 포스터', 
                          style: TextStyle(
                            color: const Color(0xFFB1B1B1),
                            fontSize: smallFontSize,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: spacing16, vertical: spacing12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8EFEA),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '연계 기관', 
                        style: TextStyle(
                          fontWeight: FontWeight.w400, 
                          fontSize: smallFontSize, 
                          color: const Color(0xFF343231),
                        ),
                      ),
                      SizedBox(height: spacing8),
                      Text(
                        ex.detailInfo, 
                        style: TextStyle(
                          fontSize: smallFontSize, 
                          color: const Color(0xFF837670),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              SizedBox(height: spacing24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BottomNavBarWidget(currentIndex: 0),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  final Color bgColor;
  final Color textColor;
  final double fontSize;
  const _Tag({
    required this.text, 
    required this.bgColor, 
    required this.textColor,
    required this.fontSize,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        text, 
        style: TextStyle(
          fontSize: fontSize, 
          color: textColor,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final double fontSize;
  final double valueFontSize;
  const _InfoRow({
    required this.label, 
    required this.value,
    required this.fontSize,
    required this.valueFontSize,
  });
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 60, 
            child: Text(
              label, 
              style: TextStyle(
                color: const Color(0xFF343231), 
                fontSize: fontSize,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value, 
              style: TextStyle(
                fontWeight: FontWeight.w400, 
                fontSize: valueFontSize, 
                color: const Color(0xFF343231),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String text;
  final bool selected;
  final VoidCallback onTap;
  final double fontSize;
  const _TabButton({
    required this.text, 
    required this.selected, 
    required this.onTap,
    required this.fontSize,
  });
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48, // 최소 터치 영역 보장
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: TextStyle(
            fontWeight: selected ? FontWeight.bold : FontWeight.w400,
            fontSize: fontSize,
            color: const Color(0xFF343231),
          ),
        ),
      ),
    );
  }
} 