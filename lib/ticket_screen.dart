import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'mypage.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: TicketScreen(),
  ));
}

class TicketScreen extends StatefulWidget {
  final bool fromMyPage;
  const TicketScreen({super.key, this.fromMyPage = false});

  @override
  State<TicketScreen> createState() => _TicketScreenState();
}

class _TicketScreenState extends State<TicketScreen> {
  bool isSingleView = true;

  final tickets = [
    {
      "imageUrl":
          "https://upload.wikimedia.org/wikipedia/commons/0/0e/Claude_Monet_-_The_Artist's_Garden_at_Vetheuil.jpg",
      "title": "아이와 해바라기 정원",
      "artist": "Claude Monet",
      "date": "2025.07.27",
      "location": "예술의 전당",
      "color": const Color(0xFF8DAA91), // 초록
    },
    {
      "imageUrl":
          "https://upload.wikimedia.org/wikipedia/commons/0/0e/Claude_Monet_-_The_Artist's_Garden_at_Vetheuil.jpg",
      "title": "아이와 해바라기 정원",
      "artist": "Claude Monet",
      "date": "2025.07.27",
      "location": "예술의 전당",
      "color": const Color(0xFFF8E6A0), // 노랑
    }
  ];

 @override
Widget build(BuildContext context) {
  return WillPopScope(
    onWillPop: () async {
      if (widget.fromMyPage) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MyPageScreen()),
        );
        return false; // 기본 pop 동작 막음
      }
      return true; // 기본 pop 허용
    },
    child: Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildCreateTicketButton(),
            const SizedBox(height: 8),
            Expanded(
              child: isSingleView ? _buildSingleView() : _buildMultiView(),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "musai",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 56, right: 12),
                    child: _TicketMenu(
                      isSingleView: isSingleView,
                      onToggleView: () {
                        setState(() {
                          isSingleView = !isSingleView;
                        });
                      },
                    ),
                  ),
                ),
              );
            },
          )
        ],
      ),
    );
  }

  /// 시안에 맞춘 + 티켓 만들기 버튼 (상단 배치)
Widget _buildCreateTicketButton() {
  const buttonColor = Color(0xFF837670); // #837670

  return Padding(
    padding: const EdgeInsets.only(left: 16, top: 4), // 상단 정렬
    child: InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        // TODO: 티켓 생성 페이지 이동
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), // 좌우12, 상하6
        decoration: BoxDecoration(
          border: Border.all(color: buttonColor, width: 1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.add, size: 18, color: buttonColor),
            SizedBox(width: 4), // 아이콘-텍스트 간격
            Text(
              "티켓 만들기",
              style: TextStyle(fontSize: 14, color: buttonColor),
            ),
          ],
        ),
      ),
    ),
  );
}

  // 티켓을 한 개씩 보여주는 뷰와 여러 개씩 보여주는 뷰를 전환하는 위젯
  Widget _buildSingleView() {
  final PageController controller = PageController(viewportFraction: 0.8);
  int currentPage = 0;

  return StatefulBuilder(
    builder: (context, setState) {
      return Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: controller,
              itemCount: tickets.length,
              onPageChanged: (index) {
                setState(() => currentPage = index);
              },
              itemBuilder: (context, index) {
                final ticket = tickets[index];
                final isCurrent = index == currentPage;
                final scale = isCurrent ? 1.0 : 0.8;

                return Center(
                  child: Transform.scale(
                    scale: scale,
                    child: _TicketCard(
                      imageUrl: ticket["imageUrl"] as String,
                      title: ticket["title"] as String,
                      artist: ticket["artist"] as String,
                      date: ticket["date"] as String,
                      location: ticket["location"] as String,
                      backgroundColor: ticket["color"] as Color,
                      textColor: index % 2 == 0 ? Colors.white : const Color(0xFF343231),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          SmoothPageIndicator(
            controller: controller,
            count: tickets.length,
            effect: WormEffect(
              dotHeight: 6,
              dotWidth: 6,
              spacing: 6,
              dotColor: const Color(0xFFB1B1B1),   // 선택 안 된 원
              activeDotColor: const Color(0xFF706B66), // 선택된 원
            ),
          ),
        ],
      );
    },
  );
}

  Widget _buildMultiView() {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65,
      ),
      itemCount: tickets.length,
      itemBuilder: (context, index) {
        final ticket = tickets[index];
        return _TicketCard(
          imageUrl: ticket["imageUrl"] as String,
          title: ticket["title"] as String,
          artist: ticket["artist"] as String,
          date: ticket["date"] as String,
          location: ticket["location"] as String,
          backgroundColor: ticket["color"] as Color,
          textColor: index % 2 == 0 ? Colors.white : const Color(0xFF343231),
        );
      },
    );
  }
}

class _TicketCard extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String artist;
  final String date;
  final String location;
  final Color backgroundColor;
  final Color textColor;

  const _TicketCard({
    required this.imageUrl,
    required this.title,
    required this.artist,
    required this.date,
    required this.location,
    required this.backgroundColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 400,
      child: Stack(
        children: [
          // 티켓 배경 (SVG)
          SvgPicture.asset(
            'assets/images/ticket_bg.svg',
            width: 200,
            height: 400,
            colorFilter: ColorFilter.mode(backgroundColor, BlendMode.srcIn),
          ),
          // 내용
          Positioned.fill(
            child: Column(
              children: [
                const SizedBox(height: 28),
                Text(
  "musai ticket",
  style: TextStyle(fontSize: 12, color: textColor), // 변경
),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    imageUrl,
                    width: 190,
                    height: 222,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
  title,
  style: TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: textColor, // 변경
  ),
  textAlign: TextAlign.center,
),
                const SizedBox(height: 4),
                Text(
  artist,
  style: TextStyle(fontSize: 14, color: textColor), // 변경
),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(date, style: TextStyle(fontSize: 12, color: textColor), // 변경
),
Text(location, style: TextStyle(fontSize: 12, color: textColor), // 변경
),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _TicketMenu extends StatelessWidget {
  final bool isSingleView;
  final VoidCallback onToggleView;
  static const menuColor = Color(0xFF837670);

  const _TicketMenu({
    required this.isSingleView,
    required this.onToggleView,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _menuItem(
              icon: isSingleView ? Icons.grid_view : Icons.view_agenda,
              text: isSingleView ? "여러 개씩 보기" : "한 개씩 보기",
              onTap: () {
                Navigator.pop(context);
                onToggleView();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuItem({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: menuColor),
            const SizedBox(width: 12),
            Text(text, style: const TextStyle(fontSize: 14, color: menuColor)),
          ],
        ),
      ),
    );
  }
}
