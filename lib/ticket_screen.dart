import 'package:flutter/material.dart'; 
import 'package:flutter_svg/flutter_svg.dart'; 
import 'package:smooth_page_indicator/smooth_page_indicator.dart'; 
import 'mypage.dart'; 
import 'bottom_nav_bar.dart'; 
import 'app_bar_widget.dart'; 
import 'ticket_create.dart';
import 'ticket_select_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'utils/auth_storage.dart';
import 'package:intl/intl.dart';

class TicketScreen extends StatefulWidget { 
  final bool fromMyPage; 
  const TicketScreen({super.key, this.fromMyPage = false}); 

  @override 
  State<TicketScreen> createState() => _TicketScreenState(); 
} 

class _TicketScreenState extends State<TicketScreen> { 
  bool isSingleView = true; 
  List<Map<String, dynamic>> tickets = [];
bool isLoading = true;
int? userId;
String? token;

  // 기본 티켓 배경색 (초록색) 
  Color selectedColor = const Color(0xFF8DAA91); 
  final PageController controller = PageController(viewportFraction: 0.59);
  int currentPage = 0;

  @override
void initState() {
  super.initState();
  _loadTickets();
}

@override
void dispose() {
  controller.dispose();
  super.dispose();
}

Future<void> _loadTickets() async {
  token = await getJwtToken();
  userId = await getUserId();

  if (token == null || userId == null) {
    setState(() => isLoading = false);
    return;
  }

  final response = await http.get(
    Uri.parse('http://43.203.23.173:8080/ticket/readAll/$userId'),
    headers: {
      'accept': '*/*',
      'Authorization': 'Bearer $token',
    },
  );

  if (response.statusCode == 200) {
    final List<dynamic> data =
        jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
    setState(() {
      tickets = data.cast<Map<String, dynamic>>();
      isLoading = false;
    });
  } else {
    print('❌ 티켓 조회 실패: ${response.statusCode}');
    setState(() => isLoading = false);
  }
}

String formatDate(String? isoString) {
  if (isoString == null || isoString.isEmpty) return '';
  try {
    final dt = DateTime.parse(isoString);
    return DateFormat('yyyy.MM.dd').format(dt);
  } catch (_) {
    return '';
  }
}

  @override 
  Widget build(BuildContext context) { 
    return WillPopScope( 
      onWillPop: () async { 
        if (widget.fromMyPage) { 
          Navigator.pushReplacement( 
            context, 
            MaterialPageRoute(builder: (_) => const MyPageScreen()), 
          ); 
          return false; 
        } 
        return true; 
      }, 
      child: Scaffold( 
        backgroundColor: const Color(0xFFFFFDFC),
        appBar: const AppBarWidget( 
          title: 'musai', 
          showBackButton: true, 
        ), 
        body: SafeArea( 
          child: Column( 
            children: [ 
              const SizedBox(height: 18), 
              Padding( 
  padding: const EdgeInsets.symmetric(horizontal: 16), 
  child: Stack( 
    alignment: Alignment.center, 
    children: [ 
      // 가운데: 티켓 만들기 버튼 
      Align( 
        alignment: Alignment.center, 
        child: _buildCreateTicketButton(), 
      ), 

      // 오른쪽 끝: 메뉴 버튼 
      Positioned( 
        right: 0, 
        child: IconButton( 
          icon: SvgPicture.asset( 
            'assets/images/ticket_menu.svg', 
            width: 22, 
            height: 22, 
          ), 
          onPressed: () { 
            _showViewMenu(); 
          }, 
        ), 
      ), 
    ], 
  ), 
), 
              const SizedBox(height: 40), 
              Expanded( 
                child: isSingleView ? _buildSingleView() : _buildMultiView(), 
              ), 
            ], 
          ), 
        ), 
        bottomNavigationBar: const BottomNavBarWidget(currentIndex: 3), 
      ), 
    ); 
  } 

  // 보기 모드 전환 메뉴 
  void _showViewMenu() { 
    showDialog( 
      context: context, 
      builder: (_) => Align( 
        alignment: Alignment.topRight, 
        child: Padding( 
          padding: const EdgeInsets.only(top: 70, right: 20), 
          child: Material( 
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
                    icon: isSingleView 
                        ? Icons.grid_view 
                        : Icons.view_agenda, 
                    text: isSingleView ? "여러 개씩 보기" : "한 개씩 보기", 
                    onTap: () { 
                      Navigator.pop(context); 
                      setState(() { 
                        isSingleView = !isSingleView; 
                      }); 
                    }, 
                  ), 
                ], 
              ), 
            ), 
          ), 
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
            Icon(icon, size: 20, color: const Color(0xFF837670)), 
            const SizedBox(width: 12), 
            Text( 
              text, 
              style: const TextStyle(fontSize: 14, color: Color(0xFF837670)), 
            ), 
          ], 
        ), 
      ), 
    ); 
  } 

  Widget _buildCreateTicketButton() { 
    const buttonColor = Color(0xFF837670); 
    return InkWell( 
      borderRadius: BorderRadius.circular(20), 
     onTap: () async {
      // 1. TicketSelectScreen 이동
      final selectedColorFromFlow = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const TicketSelectScreen(), // 작품 선택 화면
        ),
      );

      // 2. 색상 결과가 있으면 적용
      if (selectedColorFromFlow != null && selectedColorFromFlow is Color) {
        setState(() {
          selectedColor = selectedColorFromFlow;
        });
      }
    },
      child: Container( 
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), 
        decoration: BoxDecoration( 
          border: Border.all(color: buttonColor, width: 1), 
          borderRadius: BorderRadius.circular(16), 
        ), 
        child: Row( 
          mainAxisSize: MainAxisSize.min, 
          children: const [ 
            Icon(Icons.add, size: 18, color: buttonColor), 
            SizedBox(width: 4), 
            Text( 
              "티켓 만들기", 
              style: TextStyle(fontSize: 14, color: buttonColor), 
            ), 
          ], 
        ), 
      ), 
    ); 
  } 

  Widget _buildSingleView() {
    if (isLoading) {
    return const Center(child: CircularProgressIndicator());
  }

  if (tickets.isEmpty) {
    return const Center(child: Text('티켓이 없습니다.'));
  }

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

                    return Transform.scale(
                      scale: scale, 
                      child: TicketCard( 
                        ticketImage: ticket['ticketImage'] ?? '', 
                        title: ticket['title'] ?? '', 
  artist: ticket['artist'] ?? '', 
  date: formatDate(ticket['createdAt'] ?? ''), 
  location: ticket['place'] ?? '',
                        textColor: index % 2 == 0 
                            ? Colors.white 
                            : const Color(0xFF343231), 
                        backgroundColor: selectedColor, 
                      ), 
                  ); 
                }, 
              ), 
            ), 
            const SizedBox(height: 53), 
            SmoothPageIndicator( 
              controller: controller, 
              count: tickets.length, 
              effect: WormEffect( 
                dotHeight: 6, 
                dotWidth: 6, 
                spacing: 6, 
                dotColor: const Color(0xFFB1B1B1), 
                activeDotColor: const Color(0xFF706B66), 
              ), 
            ),
            const SizedBox(height: 37), 
          ],
  );
}

  Widget _buildMultiView() { 

  return GridView.builder( 
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24), 
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount( 
      crossAxisCount: 2, 
      mainAxisSpacing: 20.5,  // 세로 간격 추가 
      crossAxisSpacing: 20, // 가로 간격 추가 
      childAspectRatio: 230 / 468, // 원본 티켓 비율 유지 (0.491) 
    ), 
    itemCount: tickets.length, 
    itemBuilder: (context, index) { 
      final ticket = tickets[index]; 

      // FittedBox를 사용하여 TicketCard가 그리드 셀에 맞게 조절되도록 함 
      return FittedBox( 
        fit: BoxFit.fill, // 셀을 꽉 채우도록 설정 
        child: TicketCard( 
          ticketImage: ticket['ticketImage'] ?? '',
  title: ticket['title'] ?? '',
  artist: ticket['artist'] ?? '',
  date: formatDate(ticket['createdAt'] ?? ''),
  location: ticket['place'] ?? '',
           backgroundColor: selectedColor, 
          textColor: index % 2 == 0 ? Colors.white : const Color(0xFF343231), 
        ), 
      ); 
    }, 
  ); 
} 

} 

class TicketCard extends StatelessWidget {
  final String ticketImage;
  final String title;
  final String artist;
  final String date;
  final String location;
  final Color backgroundColor;
  final Color textColor;

  const TicketCard({
    super.key,
    required this.ticketImage,
    required this.title,
    required this.artist,
    required this.date,
    required this.location,
    required this.backgroundColor,
    required this.textColor,
  });

  @override 
Widget build(BuildContext context) {
  final cardWidth = MediaQuery.of(context).size.width * 0.59;
  final cardHeight = cardWidth * (468 / 230); // 기존 비율 유지
  final screenHeight = MediaQuery.of(context).size.height;
  return SizedBox(
    width: cardWidth,
    height: cardHeight,
    child: Stack( 
      alignment: Alignment.center, 
      children: [ 
        // 배경 
        SvgPicture.asset( 
          'assets/images/ticket_bg.svg', 
          width: cardWidth,
          height: cardHeight,
          colorFilter: ColorFilter.mode( 
            backgroundColor, 
            BlendMode.srcIn, 
          ), 
        ), 

        // 바코드 & 점선 
        SvgPicture.asset( 
          'assets/images/ticket_details.svg', 
          width: cardWidth * 0.83,
          height: cardHeight * 0.9,
        ), 
      

        // musai ticket 텍스트 
        Positioned( 
          top: 20, 
          left: 0, 
          right: 0, 
          child: Text( 
            "musai ticket", 
            textAlign: TextAlign.center, 
            style: TextStyle( 
              fontSize: 16, 
              fontWeight: FontWeight.w200, // extraLight 
              color: textColor, 
            ), 
          ), 
        ), 

        // 이미지, 제목, 작가 
        Positioned.fill( 
          child: Column( 
            crossAxisAlignment: CrossAxisAlignment.start, 
            children: [ 
              const SizedBox(height: 55), 
              Padding( 
                padding: const EdgeInsets.symmetric(horizontal: 20), 
                child: ClipRRect( 
                  borderRadius: BorderRadius.circular(10), 
                  child: Image.network(
      ticketImage,
      width: double.infinity,
      height: screenHeight * 0.27,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: Colors.grey[300],
        width: 190,
        height: 222,
        child: const Icon(Icons.broken_image),
      ),
    ),
                ), 
              ), 
              const SizedBox(height: 14), 
              Padding( 
                padding: const EdgeInsets.symmetric(horizontal: 20), 
                child: Text( 
                  title, 
                  style: TextStyle( 
                    fontSize: 18, 
                    fontWeight: FontWeight.bold, 
                    height: 1.0,
                    color: textColor, 
                  ), 
                ), 
              ), 
              const SizedBox(height: 10), 
              Padding( 
                padding: const EdgeInsets.symmetric(horizontal: 21),
                child: Text( 
                  artist, 
                  style: TextStyle( 
                    fontSize: 13, 
                    fontWeight: FontWeight.w300,
                    height: 1.0, 
                    color: textColor, 
                  ), 
                ), 
              ), 
            ], 
          ), 
        ), 

        // 날짜 & 장소 (절대 위치 → 항상 하단에 고정) 
        Positioned( 
          left: 19, 
          right: 19, 
          bottom: 60, 
          child: Row( 
            mainAxisAlignment: MainAxisAlignment.spaceBetween, 
            children: [ 
              Text( 
                date, 
                style: TextStyle( 
                  fontSize: 11, 
                  fontWeight: FontWeight.w300, 
                  color: textColor, 
                ), 
              ), 
              Text( 
                location, 
                style: TextStyle( 
                  fontSize: 11, 
                  fontWeight: FontWeight.w300, 
                  color: textColor, 
                ), 
              ), 
            ], 
          ), 
        ), 
      ], 
    ), 
  ); 
} 
}