import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'ticket_create.dart';
import 'utils/auth_storage.dart';

class TicketSelectScreen extends StatefulWidget {
  const TicketSelectScreen({super.key});

  @override
  State<TicketSelectScreen> createState() => _TicketSelectScreenState();
}

class _TicketSelectScreenState extends State<TicketSelectScreen> {
  List<Map<String, dynamic>> items = [];
  bool isLoading = true;
  String? token;
  int? userId;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadAuthInfo();
    await _loadBookmarks();
  }

  Future<void> _loadAuthInfo() async {
    token = await getJwtToken();
    userId = await getUserId();
  }

  Future<void> _loadBookmarks() async {
    if (token == null || userId == null) {
      setState(() => isLoading = false);
      return;
    }

    final response = await http.get(
      Uri.parse('http://43.203.23.173:8080/bookmark/readAll/$userId'),
      headers: {
        'accept': '*/*',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final utf8Decoded = utf8.decode(response.bodyBytes);
      final List<dynamic> data = jsonDecode(utf8Decoded);
      setState(() {
        items = data.cast<Map<String, dynamic>>();
        // 가나다순 기본 정렬
        items.sort((a, b) => (a["title"] ?? '').compareTo(b["title"] ?? ''));
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFDFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFDFC),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF343231)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "티켓 만들기",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF343231),
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 23), // 티켓 만들기 아래 간격
            // 안내문구 + 가나다순 버튼
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    SvgPicture.asset(
                      'assets/images/bulb_on.svg', // 전구 아이콘
                      width: screenWidth * 0.04,
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      "티켓으로 제작할 작품을 선택하세요.",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF706B66),
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 90,
                  height: 28,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF837670)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: "가나다순",
                      icon: const Icon(Icons.keyboard_arrow_down,
                          color: Color(0xFF837670), size: 18),
                      style: const TextStyle(
                        color: Color(0xFF837670),
                        fontSize: 14,
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: "가나다순",
                          child: Text("가나다순"),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          items.sort((a, b) =>
                              (a["title"] ?? '').compareTo(b["title"] ?? ''));
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // 작품 리스트
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : items.isEmpty
                      ? const Center(child: Text('북마크가 없습니다.'))
                      : ListView.separated(
                          itemCount: items.length,
                          separatorBuilder: (_, __) =>
                              SizedBox(height: screenHeight * 0.011),
                          itemBuilder: (context, index) {
                            final item = items[index];
                            return GestureDetector(
                              onTap: () async {
                                final selectedColor = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => TicketCreateScreen(
                                      initialColor: const Color(0xFF8DAA91),
                                    ),
                                  ),
                                );
                                if (selectedColor != null &&
                                    selectedColor is Color) {
                                  Navigator.pop(context, selectedColor);
                                }
                              },
                              child: Container(
                                width: screenWidth * 0.877, // 342 / 390
                                height: screenHeight * 0.145,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEFDFC),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: const Color(0xFFEAEAEA)),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 18),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // 썸네일
                                    Container(
                                      width: screenWidth * 0.172, // 67 / 390
                                      height: screenHeight * 0.11,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[300],
                                        borderRadius:
                                            BorderRadius.circular(8),
                                        image: item['imageUrl'] != null &&
                                                item['imageUrl']
                                                    .toString()
                                                    .isNotEmpty
                                            ? DecorationImage(
                                                image: NetworkImage(
                                                    item['imageUrl']),
                                                fit: BoxFit.cover,
                                              )
                                            : null,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    // 제목 + 작가
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            (item['title'] ?? '')
                                                .replaceAll('*', ''),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize:
                                                  screenWidth * 0.042,
                                              height: 1.25,
                                              color: const Color(0xFF343231),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(
                                              height:
                                                  screenHeight * 0.031), // 26 / 844
                                          Text(
                                            (item['artist'] ?? '')
                                                .replaceAll('*', ''),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize:
                                                  screenWidth * 0.032,
                                              color: const Color(0xFF706B66),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
