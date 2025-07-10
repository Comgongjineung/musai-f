import 'package:flutter/material.dart';
import 'bottom_nav_bar.dart';
import 'exhibition_detail_page.dart';

Color getStatusColor(String status) {
  switch (status) {
    case '전시중':
      return const Color(0xFFD48D7A);
    case '오픈전':
      return const Color(0xFFEDC240);
    case '완료':
      return const Color(0xFFB0B0B0);
    default:
      return const Color(0xFFE6E0DC);
  }
}

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFDFC),
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text(
          'musai',
          style: TextStyle(
            color: Color(0xFF343231),
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFFFFFDFC),
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(width * 0.04),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _searchBar(context),
              const SizedBox(height: 20),
              Row(
  mainAxisAlignment: MainAxisAlignment.end, // 오른쪽 정렬
  mainAxisSize: MainAxisSize.max,
  children: const [
    _SortDropdown(label: '최신순', isPrimary: true),
    SizedBox(width: 10),
    _SortDropdown(label: '최신순'),
  ],
),
              const SizedBox(height: 20),
              const _ExhibitionList(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BottomNavBarWidget(currentIndex: 0),
    );
  }

  Widget _searchBar(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        hintText: '전시회를 검색하세요',
        hintStyle: const TextStyle(color: Color(0xFFB1B1B1)),
        suffixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: const Color(0xFFF4F0ED),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
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
  const _ExhibitionList();

  @override
  Widget build(BuildContext context) {
    final items = List.generate(5, (i) => i);

    return ListView.separated(
      shrinkWrap: true, // ListView가 자식 높이만큼만 차지하게
      physics: const NeverScrollableScrollPhysics(), // 스크롤 중첩 방지
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final status = '전시중';
        return GestureDetector(
          onTap: () {
            final dummy = Exhibition(
              title: '이탈리아 국립 카포디몬테 컬렉션',
              category: '카테고리',
              status: '전시중',
              price: '무료',
              date: '2025.07.08 ~ 2025.08.08',
              time: '09시 ~ 18시, 일요일 휴무',
              place: '소마미술관',
              description: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, (소개글)',
              homepageUrl: 'https://example.com',
              detailInfo: '연계 기관',
            );
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ExhibitionDetailPage(exhibition: dummy),
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
                // 상단 태그들
                Row(
                  children: [
                    const _Tag(
                      text: '카테고리',
                      bgColor: Color(0xFFE6E0DC),
                      textColor: Colors.white,
                      radius: 15,
                    ),
                    const SizedBox(width: 4),
                    _Tag(
                      text: status,
                      bgColor: getStatusColor(status),
                      textColor: Colors.white,
                      radius: 15,
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // 대표사진 + 텍스트 Row
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
                      alignment: Alignment.center,
                      child: const Text('(대표사진)', style: TextStyle(fontSize: 11)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            '전시회 제목',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '소마미술관',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF706B66),
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            '2025.07.08 - 2025.08.08',
                            style: TextStyle(
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

class _Tag extends StatelessWidget {
  final String text;
  final Color bgColor;
  final Color textColor;
  final double radius;
  const _Tag({
    required this.text,
    required this.bgColor,
    this.textColor = Colors.black,
    this.radius = 6,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Text(text, style: TextStyle(fontSize: 11, color: textColor)),
    );
  }
}
