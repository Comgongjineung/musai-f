import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:http/http.dart' as http;
import 'mypage.dart';
import 'bottom_nav_bar.dart';
import 'app_bar_widget.dart';
import 'ticket_create.dart';
import 'ticket_select_screen.dart';
import 'utils/auth_storage.dart';
import 'package:flutter/gestures.dart';

// 3초 롱프레스 전용 인식기
class _DelayedLongPressRecognizer extends LongPressGestureRecognizer {
  _DelayedLongPressRecognizer({ Duration? duration })
      : super(duration: duration ?? const Duration(milliseconds: 3000));
}

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
      // ignore: avoid_print
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

  Future<bool> _deleteTicket(int ticketId) async {
    token ??= await getJwtToken();
    if (token == null) return false;

    final resp = await http.delete(
      Uri.parse('http://43.203.23.173:8080/ticket/delete/$ticketId'),
      headers: {
        'accept': '*/*',
        'Authorization': 'Bearer $token',
      },
    );
    return resp.statusCode == 200;
  }

  // 공통: 티켓을 삭제 제스처로 감싸는 래퍼
Widget _deletableTicketWrapper({
  required Widget child,
  required int ticketId,
}) {
  return RawGestureDetector(
    behavior: HitTestBehavior.opaque,
    gestures: {
      _DelayedLongPressRecognizer:
          GestureRecognizerFactoryWithHandlers<_DelayedLongPressRecognizer>(
        () => _DelayedLongPressRecognizer(), // 3초
        (_DelayedLongPressRecognizer instance) {
          // 3초 롱프레스가 성립되는 순간 (필요 시 비주얼 효과 넣고 싶으면 여기서 setState 가능)
          instance.onLongPressStart = (details) {
            // no-op
          };

          instance.onLongPress = () async {
            final ok = await _deleteTicket(ticketId);
            if (ok) {
              setState(() {
                tickets.removeWhere(
                  (t) => (t['ticketId'] ?? t['id']) == ticketId,
                );
              });
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('티켓이 삭제되었습니다.')),
                );
              }
            } else {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('삭제에 실패했습니다.')),
                );
              }
            }
          };
          instance.onLongPressCancel = () {
            // 롱프레스 성립 전/중 취소된 경우: 아무것도 안 함
          };
        },
      ),
    },
    child: child,
  );
}


  // ---------- UI ----------
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
          child: Stack(
            children: [
              Column(
                children: [
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
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
                            onPressed: _showViewMenu,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),

// 안내 문구 추가
const Text(
  '티켓을 3초간 꾹 누르시면 해당 티켓이 삭제됩니다.',
  style: TextStyle(
    fontSize: 10,
    color: Colors.grey,
  ),
  textAlign: TextAlign.center,
),
                  const SizedBox(height: 20),
                  Expanded(
                    child:
                        isSingleView ? _buildSingleView() : _buildMultiView(),
                  ),
                ],
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
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: Offset(0, 4),
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
              style:
                  const TextStyle(fontSize: 14, color: Color(0xFF837670)),
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
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, size: 18, color: buttonColor),
            SizedBox(width: 4),
            Text(
              "티켓 만들기",
              style: TextStyle(
                fontSize: 14.85,
                fontWeight: FontWeight.w400,
                color: buttonColor,
              ),
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

              final url = (ticket['ticketImage'] ?? '').toString();
              final showPng = url.isNotEmpty;

              final ticketId =
                  (ticket['ticketId'] ?? ticket['id'] ?? 0) as int;

              final wrappedCard = showPng
                  ? _PngTicket(url: url)
                  : TicketCard(
                      ticketImage: ticket['ticketImage'] ?? '',
                      title: ticket['title'] ?? '',
                      artist: ticket['artist'] ?? '',
                      date: formatDate(ticket['createdAt'] ?? ''),
                      location: ticket['place'] ?? '',
                    );

              return Transform.scale(
                scale: scale,
                child: _deletableTicketWrapper(
                  ticketId: ticketId,
                  child: wrappedCard,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 53),
        SmoothPageIndicator(
          controller: controller,
          count: tickets.length,
          effect: const WormEffect(
            dotHeight: 6,
            dotWidth: 6,
            spacing: 6,
            dotColor: Color(0xFFB1B1B1),
            activeDotColor: Color(0xFF706B66),
          ),
        ),
        const SizedBox(height: 37),
      ],
    );
  }

  Widget _buildMultiView() {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 20.5, // 세로 간격
        crossAxisSpacing: 20, // 가로 간격
        childAspectRatio: 230 / 468, // 원본 티켓 비율 유지
      ),
      itemCount: tickets.length,
      itemBuilder: (context, index) {
        final ticket = tickets[index];
        final url = (ticket['ticketImage'] ?? '').toString();
        final ticketId = (ticket['ticketId'] ?? ticket['id'] ?? 0) as int;

        final card = url.isNotEmpty
            ? _PngTicket(url: url)
            : TicketCard(
                ticketImage: ticket['ticketImage'] ?? '',
                title: ticket['title'] ?? '',
                artist: ticket['artist'] ?? '',
                date: formatDate(ticket['createdAt'] ?? ''),
                location: ticket['place'] ?? '',
              );

        return FittedBox(
          fit: BoxFit.fill,
          child: _deletableTicketWrapper(
            ticketId: ticketId,
            child: card,
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
  final Color? backgroundColor;
  final Color? textColor;

  const TicketCard({
    super.key,
    required this.ticketImage,
    required this.title,
    required this.artist,
    required this.date,
    required this.location,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final cardWidth = screenWidth * 0.64;
    final cardHeight = cardWidth * (468 / 230); // 기존 비율 유지
    final Color effectiveText = textColor ?? const Color(0xFF212121);

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
            colorFilter: backgroundColor == null
                ? null
                : ColorFilter.mode(backgroundColor!, BlendMode.srcIn),
          ),

          // 바코드 & 점선
          SvgPicture.asset(
            'assets/images/ticket_detail.svg', // 규격 맞춘 새로운 svg
            width: cardWidth,
            height: cardHeight,
          ),

          // musai ticket 텍스트
          Positioned(
            top: screenWidth * 0.04,
            left: 0,
            right: 0,
            child: Text(
              "musai ticket",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: screenWidth * 0.04,
                fontWeight: FontWeight.w200, // extraLight
                color: effectiveText,
              ),
            ),
          ),

          // 이미지, 제목, 작가
          Positioned.fill(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: screenHeight * 0.054), // 48px
                Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
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
                SizedBox(height: screenHeight * 0.015),
                Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                  child: Text(
                    title.replaceAll('*', ''),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: screenWidth * 0.045,
                      fontWeight: FontWeight.w600,
                      height: 1.0,
                      color: effectiveText,
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.006),
                Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                  child: Text(
                    artist.replaceAll('*', ''),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: screenWidth * 0.035,
                      fontWeight: FontWeight.w300,
                      height: 1.0,
                      color: effectiveText,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 날짜 & 장소 (항상 하단 고정)
          Positioned(
            left: screenWidth * 0.05,
            right: screenWidth * 0.05,
            bottom: screenHeight * 0.072,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  date,
                  style: TextStyle(
                    fontSize: screenWidth * 0.03,
                    fontWeight: FontWeight.w300,
                    color: effectiveText,
                  ),
                ),
                Text(
                  location,
                  style: TextStyle(
                    fontSize: screenWidth * 0.03,
                    fontWeight: FontWeight.w300,
                    color: effectiveText,
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

class _PngTicket extends StatelessWidget {
  final String url;
  const _PngTicket({required this.url});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth * 0.64;
    final cardHeight = cardWidth * (468 / 230);

    return SizedBox(
      width: cardWidth,
      height: cardHeight,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: Colors.grey[300],
            alignment: Alignment.center,
            child: const Icon(Icons.broken_image),
          ),
        ),
      ),
    );
  }
}
