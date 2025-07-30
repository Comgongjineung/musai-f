import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'bottom_nav_bar.dart';
import 'app_bar_widget.dart';
import 'exhibition_detail_page.dart';
import 'package:intl/intl.dart';
import 'utils/auth_storage.dart';

// 상태별 태그 색상 함수
Color getTagBgColor(String status) {
  switch (status) {
    case '전시중':
      return const Color(0xFFB75456);
    case '오픈전':
      return const Color(0xFFFEFDFC);
    case '완료':
      return const Color(0xFFB1B1B1);
    default:
      return const Color(0xFFFEFDFC);
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

// 기간 기준 상태 판별 함수
String getStatusFromPeriod(String period) {
  try {
    final dates = period.split('~');
    if (dates.length != 2) return '상태없음';

    final start = DateTime.parse(dates[0].trim().replaceAll('.', '-'));
    final end = DateTime.parse(dates[1].trim().replaceAll('.', '-'));
    final today = DateTime.now();

    if (today.isBefore(start)) return '오픈전';
    if (today.isAfter(end)) return '완료';
    return '전시중';
  } catch (_) {
    return '상태없음';
  }
}

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  bool isSearchDone = false;
  List<dynamic> exhibitionList = [];

 Future<void> fetchExhibitions(String query) async {
  if (query.trim().isEmpty) {
    setState(() {
      isSearchDone = false;
      exhibitionList = [];
    });
    return;
  }
  final token = await getJwtToken(); // 저장된 토큰 가져오기
  if (token == null) {
    debugPrint('토큰 없음. 로그인 필요');
    return;
  }

  final uri = Uri.parse('http://43.203.23.173:8080/exhibition/search/title?keyword=${Uri.encodeQueryComponent(query)}');
  final response = await http.get(
    uri,
    headers: {
      'accept': '*/*',
      'Authorization': 'Bearer $token',
    },
  );

  if (response.statusCode == 200) {
    final utf8Decoded = utf8.decode(response.bodyBytes);
    final List<dynamic> data = json.decode(utf8Decoded);

    data.sort((a, b) {
  final aDate = DateTime.tryParse(a['startDate'] ?? '') ?? DateTime(1900);
  final bDate = DateTime.tryParse(b['startDate'] ?? '') ?? DateTime(1900);
  return bDate.compareTo(aDate); // 최신순 (내림차순)
});


    setState(() {
      isSearchDone = true;
      exhibitionList = data;
    });
  } else {
    setState(() {
      isSearchDone = true;
      exhibitionList = [];
    });
    debugPrint('API 호출 실패: ${response.statusCode}');
  }
}


  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFDFC),
      resizeToAvoidBottomInset: true,
      appBar: const AppBarWidget(
        showBackButton: true,
        backgroundColor: Color(0xFFFFFDFC),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(width * 0.06),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _searchBar(context),
              const SizedBox(height: 20),
              if (exhibitionList.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: const [
                    _SortDropdown(label: '최신순'),
                  ],
                ),
                const SizedBox(height: 20),
              ],
              const SizedBox(height: 20),
              exhibitionList.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 250),
                        child: Text(
                          isSearchDone
                              ? '검색 결과가 없습니다.'
                              : '전시 제목, 장소, 카테고리 등을 검색하여\n원하는 전시회를 찾아보세요.',
                          style: const TextStyle(
                            color: Color(0xFF706B66),
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : _ExhibitionList(exhibitionList: exhibitionList),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BottomNavBarWidget(currentIndex: 0),
    );
  }

  Widget _searchBar(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return TextField(
      controller: _controller,
      onSubmitted: (value) {
        fetchExhibitions(value);
      },
      decoration: InputDecoration(
        hintText: '전시회를 검색하세요',
        hintStyle: const TextStyle(color: Color(0xFFB1B1B1)),
        suffixIcon: IconButton(
          icon: const Icon(Icons.search),
          onPressed: () => fetchExhibitions(_controller.text),
        ),
        filled: true,
        fillColor: const Color(0xFFFEF6F2),
        contentPadding: EdgeInsets.symmetric(horizontal: width * 0.06),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(width * 0.06),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _SortDropdown extends StatelessWidget {
  final String label;
  final bool isPrimary;
  const _SortDropdown({required this.label, this.isPrimary = false});

  @override
  Widget build(BuildContext context) {
    final backgroundColor =
        isPrimary ? const Color(0xFF837670) : const Color(0xFFFFFDFC);
    final textColor =
        isPrimary ? const Color(0xFFFEFDFC) : const Color(0xFF837670);
    final iconColor =
        isPrimary ? const Color(0xFFFEFDFC) : const Color(0xFF837670);
    final border =
        isPrimary ? null : Border.all(color: const Color(0xFF837670));

    return SizedBox(
      width: 84,
      height: 28,
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: border,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
            Icon(Icons.arrow_drop_down, color: iconColor, size: 18),
          ],
        ),
      ),
    );
  }
}

class _ExhibitionList extends StatelessWidget {
  final List<dynamic> exhibitionList;
  const _ExhibitionList({required this.exhibitionList});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: exhibitionList.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final exhi = exhibitionList[index];
        final startDate = exhi['startDate'] ?? '';
        final endDate = exhi['endDate'] ?? '';
        final period = '${formatDate(startDate)} ~ ${formatDate(endDate)}';
        final status = getStatusFromPeriod(period);

        return GestureDetector(
          onTap: () {
            final exhibition = Exhibition.fromJson(exhi);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ExhibitionDetailPage(exhibition: exhibition),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFEFDFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEAEAEA)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _Tag(
                      text: '카테고리',
                      bgColor: const Color(0xFFA28F7D),
                      textColor: const Color(0xFFFEFDFC),
                      radius: 15,
                      width: 60,
                      height: 20,
                      fontSize: 12,
                    ),
                    const SizedBox(width: 4),
                    _Tag(
                      text: status,
                      bgColor: getTagBgColor(status),
                      textColor: getTagTextColor(status),
                      radius: 15,
                      border: getTagBorder(status),
                      width: 49,
                      height: 20,
                      fontSize: 12,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 67,
                      height: 67,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: exhi['thumbnail'] == null || exhi['thumbnail'] == 'null'
    ? const SizedBox.shrink()
    : ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          exhi['thumbnail'],
          width: 67,
          height: 67,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              color: Colors.grey[300],
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return const Icon(Icons.broken_image, size: 30, color: Colors.grey);
          },
        ),
      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            exhi['title'] ?? '제목 없음',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            exhi['place'] ?? '',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF706B66),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            period,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
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

class _Tag extends StatelessWidget {
  final String text;
  final Color bgColor;
  final Color textColor;
  final double radius;
  final Border? border;
  final double width;
  final double height;
  final double fontSize;

  const _Tag({
    required this.text,
    required this.bgColor,
    this.textColor = Colors.black,
    this.radius = 6,
    this.border,
    this.width = 49,
    this.height = 20,
    this.fontSize = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(radius),
        border: border,
      ),
      child: Text(text, style: TextStyle(fontSize: 12, color: textColor),  textAlign: TextAlign.center,),
    );
  }
}
