import 'package:flutter/material.dart';
import '../bottom_nav_bar.dart';
import '../app_bar_widget.dart';
import 'home_screen.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';


class Exhibition {
  final int exhiId;
  final String title;
  final String startDate;
  final String endDate;
  final String place;
  final String realmName;
  final String thumbnail;
  final int seqnum;
  final String? placeUrl;

  Exhibition({
    required this.exhiId,
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.place,
    required this.realmName,
    required this.thumbnail,
    required this.seqnum,
    this.placeUrl,
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
      placeUrl: json['placeUrl'] ?? '',
    );
  }
}

class ExhibitionDetailPage extends StatelessWidget {
  final Exhibition exhibition;
  const ExhibitionDetailPage({super.key, required this.exhibition});

  Future<void> _launchPlaceUrl(BuildContext context) async {
    final raw = exhibition.placeUrl ?? '';
    if (raw.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('홈페이지 주소가 없습니다.')),
      );
      return;
    }
    final normalized = raw.startsWith('http') ? raw : 'https://$raw';
    final uri = Uri.parse(normalized);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('링크를 열 수 없습니다: $normalized')),
      );
    }
  }

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
    final height = MediaQuery.of(context).size.height;
    final status = getExhibitionStatus(ex.startDate, ex.endDate);

    return Scaffold(
      backgroundColor: const Color(0xFFFFFDFC),
      appBar: const AppBarWidget(
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: width * 0.06),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: height * 0.02),

              // 포스터 썸네일
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: ex.thumbnail.isNotEmpty
                    ? Image.network(
                        ex.thumbnail,
                        width: double.infinity,
                        fit: BoxFit.fitWidth,
                      )
                    : Container(
                        width: double.infinity,
                        height: 200,
                        color: const Color(0xFFF4F0ED),
                        alignment: Alignment.center,
                        child: const Text('전시회 썸네일', style: TextStyle(color: Color(0xFFB1B1B1))),
                      ),
              ),

              SizedBox(height: height * 0.03),

              // 상태(전시중/오픈전/완료)만 표시
              Row(
                children: [
                  _Tag(
                    text: status,
                    bgColor: getTagBgColor(status),
                    textColor: getTagTextColor(status),
                    border: getTagBorder(status),
                    width: width * 0.17,
                    height: height * 0.033,
                    fontSize: 16,
                  ),
                ],
              ),
              
              SizedBox(height: height * 0.01),
              // 제목
              Text(
                decodeHtml(ex.title),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Color(0xFF343231),
                ),
              ),

              SizedBox(height: height * 0.02),

              // 일정 & 장소
              _InfoRow(label: '일정', value: '${formatDate(ex.startDate)} ~ ${formatDate(ex.endDate)}'),
              _InfoRow(label: '장소', value: ex.place),

              SizedBox(height: height * 0.03),

              // 홈페이지 바로가기 버튼
              Center(
                child: GestureDetector(
                  onTap: () => _launchPlaceUrl(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFA28F7D),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      '홈페이지 바로가기',
                      style: TextStyle(
                        color: Color(0xFFFEFDFC),
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ), //텍스트 크기
                    ),
                  ),
                ),
              ),

              SizedBox(height: height * 0.035),
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
    this.width = 0, 
    this.height = 0,
    this.fontSize = 16, 
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width > 0 ? width : MediaQuery.of(context).size.width * 0.2,
      height: height > 0 ? height : MediaQuery.of(context).size.height * 0.033,
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
            width: MediaQuery.of(context).size.width * 0.15,
            child: Text(label, style: const TextStyle(color: Color(0xFF706B66), fontSize: 16)),
          ),
          SizedBox(width: MediaQuery.of(context).size.width * 0.02),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Color(0xFF343231)),
            ),
          ),
        ],
      ),
    );
  }
}
