import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../bottom_nav_bar.dart';
import '../utils/auth_storage.dart';
import '../describe/describe_box.dart';
import '../app_bar_widget.dart';

class BookmarkScreen extends StatefulWidget {
  const BookmarkScreen({super.key});

  @override
  State<BookmarkScreen> createState() => _BookmarkScreenState();
}

class _BookmarkScreenState extends State<BookmarkScreen> {
  List<Map<String, dynamic>> bookmarks = [];
  bool isLoading = true;
  String? token;
  int? userId;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadAuthInfo();      // 토큰, userId 불러오기
    await _loadBookmarks();     // 북마크 불러오기
  }

  Future<void> _loadAuthInfo() async {
    token = await getJwtToken();
    userId = await getUserId();
    setState(() {});
  }

  Future<void> _deleteBookmark(int bookmarkId) async {
    if (token == null) return;

    final response = await http.delete(
      Uri.parse('http://43.203.23.173:8080/bookmark/delete/$bookmarkId'),
      headers: {
        'accept': '*/*',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        bookmarks.removeWhere((item) => item['bookmarkId'] == bookmarkId);
      });
    } else {
      debugPrint('❌ 삭제 실패: ${response.statusCode}');
    }
  }

  Future<void> _loadBookmarks() async {
    if (token == null || userId == null) {
      debugPrint('❗ 토큰 또는 유저 ID가 없습니다. 로그인 필요');
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
        bookmarks = data.cast<Map<String, dynamic>>();
        isLoading = false;
      });
    } else {
      debugPrint('북마크 불러오기 실패: ${response.statusCode}');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFDFC),
      appBar: const AppBarWidget(
        title: 'musai',
        showBackButton: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: screenHeight * 0.02),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _SortDropdown(label: '가나다순', screenWidth: screenWidth, screenHeight: screenHeight),
                ],
              ),
              SizedBox(height: screenHeight * 0.025),
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : bookmarks.isEmpty
                        ? const Center(child: Text('북마크가 없습니다.'))
                        : ListView.separated(
                            padding: EdgeInsets.only(bottom: screenHeight * 0.02),
                            itemCount: bookmarks.length,
                            separatorBuilder: (_, __) =>
                                SizedBox(height: screenHeight * 0.01),
                            itemBuilder: (context, index) {
                              final item = bookmarks[index];

                              return GestureDetector(
    onTap: () async {
      if (token == null || userId == null) return;

      final bookmarkId = item['bookmarkId'];

      final response = await http.get(
        Uri.parse('http://43.203.23.173:8080/bookmark/read/$bookmarkId/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));

        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DescriptionScreen(
              title: data['title'],
              artist: data['artist'],
              year: '', // 북마크 데이터엔 year 없음
              description: data['description'],
              imagePath: '', // 사용되지 않음
              imageUrl: data['imageUrl'],
              scrollController: ScrollController(),
              fromBookmark: true,
            ),
          ),
        );

        // 북마크 목록 새로고침
        await _loadBookmarks();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('상세 정보 조회 실패: ${response.statusCode}')),
        );
      }
    },
                              child: Stack(
  children: [
    Container(
      padding: EdgeInsets.symmetric(
    horizontal: screenWidth * 0.04,
    vertical: screenHeight * 0.02, 
  ),
      decoration: BoxDecoration(
        color: const Color(0xFFFEFDFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEAEAEA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: screenWidth * 0.18,
            height: screenHeight * 0.1,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
              image: item['imageUrl'] != null
                  ? DecorationImage(
                      image: NetworkImage(item['imageUrl']),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
          ),
          SizedBox(width: screenWidth * 0.037),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: screenWidth * 0.5,
                  child: Text(
                    (item['title'] ?? '').replaceAll('*', ''),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: screenWidth * 0.042,
                      height: 1.1875,
                      color: const Color(0xFF343231),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.005), 
                SizedBox(
                  width: screenWidth * 0.5,
                  child:
                  Text(
                    (item['artist'] ?? '').replaceAll('*', ''),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: screenWidth * 0.032,
                      color: const Color(0xFF706B66),
                    )
                  )
                )
              ],
            ),
          )
        ],
      ),
    ),
    Positioned(
      right: 0,
      child: IconButton(
        icon: Icon(Icons.close, size: screenWidth * 0.045, color: const Color(0xFFA28F7D)),
        onPressed: () => _deleteBookmark(item['bookmarkId']),
      ),
    ),
  ],
),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BottomNavBarWidget(currentIndex: 3),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String text;
  final bool selected;
  final double screenWidth;
  final double screenHeight;
  const _TabButton({required this.text, required this.selected, required this.screenWidth, required this.screenHeight});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: screenWidth * 0.21,
      height: screenHeight * 0.038,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF837670) : const Color(0xFFFEF6F2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: screenWidth * 0.042,
          color:
              selected ? const Color(0xFFFEFDFC) : const Color(0xFF706B66),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SortDropdown extends StatelessWidget {
  final String label;
  final double screenWidth;
  final double screenHeight;
  const _SortDropdown({required this.label, required this.screenWidth, required this.screenHeight});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: screenWidth * 0.22,
      height: screenHeight * 0.035,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFFFDFC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF837670)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                color: const Color(0xFF837670),
                fontWeight: FontWeight.w500,
                fontSize: screenWidth * 0.036,
              ),
            ),
            Icon(Icons.arrow_drop_down,
                color: const Color(0xFF837670), size: screenWidth * 0.036),
          ],
        ),
      ),
    );
  }
}
