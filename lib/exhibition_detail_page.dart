import 'package:flutter/material.dart';
import 'bottom_nav_bar.dart';
import 'app_bar_widget.dart';
import 'package:intl/intl.dart';

class Exhibition {
  final int exhiId;
  final String title;
  final String startDate;
  final String endDate;
  final String place;
  final String realmName;
  final String thumbnail;
  final int seqnum;

  Exhibition({
    required this.exhiId,
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.place,
    required this.realmName,
    required this.thumbnail,
    required this.seqnum,
  });

  factory Exhibition.fromJson(Map<String, dynamic> json) {
    return Exhibition(
      exhiId: json['exhiId'] ?? 0,
      title: json['title'] ?? '',
      startDate: json['startDate'] ?? '',
      endDate: json['endDate'] ?? '',
      place: json['place'] ?? '',
      realmName: json['realmName'] ?? '',
      thumbnail: json['thumbnail'] ?? '',
      seqnum: json['seqnum'] ?? 0,
    );
  }
}

class ExhibitionDetailPage extends StatelessWidget {
  final Exhibition exhibition;
  const ExhibitionDetailPage({super.key, required this.exhibition});

  String getExhibitionStatus(String start, String end) {
    try {
      final today = DateTime.now();
      final startDate = DateTime.parse(start.replaceAll('.', '-'));
      final endDate = DateTime.parse(end.replaceAll('.', '-'));

      if (today.isBefore(startDate)) return '오픈전';
      if (today.isAfter(endDate)) return '완료';
      return '전시중';
    } catch (_) {
      return '상태없음';
    }
  }

  @override
  Widget build(BuildContext context) {
    final ex = exhibition;
    final width = MediaQuery.of(context).size.width;
    final posterSize = width * 0.85;
    final status = getExhibitionStatus(ex.startDate, ex.endDate);

    return Scaffold(
      backgroundColor: const Color(0xFFFFFDFC),
      appBar: const AppBarWidget(
        showBackButton: true,
        backgroundColor: Color(0xFFFFFDFC),
        titleSize: 22,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: width * 0.06),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),

              // 포스터 썸네일
              Center(
                child: Container(
                  width: posterSize,
                  height: posterSize * 264 / 343,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F0ED),
                    borderRadius: BorderRadius.circular(16),
                    image: ex.thumbnail.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(ex.thumbnail),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: ex.thumbnail.isEmpty
                      ? const Text('전시회 썸네일', style: TextStyle(color: Color(0xFFB1B1B1)))
                      : null,
                ),
              ),

              const SizedBox(height: 18),

              // 카테고리 + 상태
              Row(
                children: [
                  const _Tag(text: '카테고리', bgColor: Color(0xFFFEF6F2), textColor: Colors.black,  
                  width: 80, height: 27, fontSize: 16,),
                  const SizedBox(width: 8),
                  _Tag(text: status, bgColor: getTagBgColor(status),
      textColor: getTagTextColor(status),
      border: getTagBorder(status),
      width: 66,
      height: 27,
      fontSize: 16,),
                ],
              ),
              
              const SizedBox(height: 10),
              // 제목
              Text(
                ex.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Color(0xFF343231),
                ),
              ),

              const SizedBox(height: 12),

              // 일정 & 장소
              _InfoRow(label: '일정', value: '${formatDate(ex.startDate)} ~ ${formatDate(ex.endDate)}'),
              _InfoRow(label: '장소', value: ex.place),

              const SizedBox(height: 18),

              // 상세 내용 블럭
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F1EC),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () {}, // 홈페이지 연결 예정
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFBDAF9D),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text(
                          '홈페이지 바로가기',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (ex.thumbnail.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(ex.thumbnail),
                      )
                    else
                      Container(
                        width: double.infinity,
                        height: 180,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE6E0DC),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          '전시회에서 제공하는 포스터',
                          style: TextStyle(color: Color(0xFFB1B1B1)),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BottomNavBarWidget(currentIndex: 0),
    );
  }
}

String formatDate(String yyyymmdd) {
  try {
    final date = DateTime.parse(yyyymmdd);
    return DateFormat('yyyy.MM.dd').format(date);
  } catch (_) {
    return yyyymmdd; // 포맷 실패 시 원본 출력
  }
}

Color getTagBgColor(String status) {
  switch (status) {
    case '전시중':
      return const Color(0xFFB75456);
    case '오픈전':
      return const Color(0xFFFEFDFC);
    case '완료':
      return const Color(0xFFB1B1B1);
    default:
      return const Color(0xFFE6E0DC);
  }
}

Color getTagTextColor(String status) {
  switch (status) {
    case '전시중':
    case '완료':
      return const Color(0xFFFEFDFC);
    case '오픈전':
      return const Color(0xFFB75456);
    default:
      return Colors.black;
  }
}

Border? getTagBorder(String status) {
  if (status == '오픈전') {
    return Border.all(color: const Color(0xFFB75456));
  }
  return null;
}


// 태그 컴포넌트
class _Tag extends StatelessWidget {
  final String text;
  final Color bgColor;
  final Color textColor;
  final Border? border;
  final double width;
  final double height;
  final double fontSize;

  const _Tag({
    required this.text,
    required this.bgColor,
    required this.textColor,
    this.border,
    this.width = 80, 
    this.height = 27,
    this.fontSize = 16, 
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(15),
        border: border,
      ),
      child: Text(text, style: TextStyle(fontSize: fontSize, color: textColor)),
    );
  }
}


// 정보 줄 컴포넌트
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(label, style: const TextStyle(color: Color(0xFFB1B1B1), fontSize: 14)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF343231)),
            ),
          ),
        ],
      ),
    );
  }
}