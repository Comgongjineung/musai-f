import 'package:flutter/material.dart';
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
    final posterSize = width * 0.85;
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
              // 2️⃣ 전시 메인 포스터
              SizedBox(height: 10),
              Container(
                width: posterSize,
                height: posterSize,
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F0ED),
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: const Text('전시회 메인 포스터', style: TextStyle(color: Color(0xFFB1B1B1))),
              ),
              const SizedBox(height: 18),
              // 3️⃣ 태그 영역
              Row(
                children: [
                  _Tag(text: ex.category, bgColor: const Color(0xFFEEE9E4), textColor: Colors.black),
                  const SizedBox(width: 8),
                  _Tag(text: ex.status, bgColor: const Color(0xFFD86B6B), textColor: Colors.white),
                ],
              ),
              const SizedBox(height: 10),
              // 4️⃣ 전시 정보 블럭
              Text(ex.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF343231), fontFamily: 'Pretendard')),
              const SizedBox(height: 12),
              _InfoRow(label: '가격', value: ex.price),
              _InfoRow(label: '일정', value: ex.date),
              _InfoRow(label: '시간', value: ex.time),
              _InfoRow(label: '장소', value: ex.place),
              const SizedBox(height: 18),
              // 5️⃣ 상세 내용 / 상세 정보 탭
              Row(
                children: [
                  _TabButton(
                    text: '상세 내용',
                    selected: selectedTab == 0,
                    onTap: () => setState(() => selectedTab = 0),
                  ),
                  _TabButton(
                    text: '상세 정보',
                    selected: selectedTab == 1,
                    onTap: () => setState(() => selectedTab = 1),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // 6️⃣ 탭 콘텐츠
              if (selectedTab == 0) ...[
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
                        onTap: () {},
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFBDAF9D),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Text('홈페이지 바로가기', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(ex.description, style: const TextStyle(fontSize: 15, color: Color(0xFF343231))),
                      const SizedBox(height: 18),
                      Container(
                        width: double.infinity,
                        height: posterSize,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE6E0DC),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: const Text('전시회에서 제공하는 포스터', style: TextStyle(color: Color(0xFFB1B1B1))),
                      ),
                    ],
                  ),
                ),
              ] else ...[
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
                      const Text('연계 기관', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF343231))),
                      const SizedBox(height: 8),
                      Text(ex.detailInfo, style: const TextStyle(fontSize: 14, color: Color(0xFF837670))),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 30),
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
  const _Tag({required this.text, required this.bgColor, required this.textColor});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Text(text, style: TextStyle(fontSize: 12, color: textColor)),
    );
  }
}

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
          SizedBox(width: 60, child: Text(label, style: const TextStyle(color: Color(0xFFB1B1B1), fontSize: 14))),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF343231)))),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String text;
  final bool selected;
  final VoidCallback onTap;
  const _TabButton({required this.text, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Text(
              text,
              style: TextStyle(
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                fontSize: 15,
                color: const Color(0xFF343231),
              ),
            ),
            const SizedBox(height: 2),
            Container(
              height: 2,
              color: selected ? const Color(0xFFD86B6B) : Colors.transparent,
            ),
          ],
        ),
      ),
    );
  }
} 