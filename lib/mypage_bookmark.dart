import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'bottom_nav_bar.dart';
import 'utils/auth_storage.dart';

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
  await _loadBookmarks();     // 그다음 북마크 불러오기
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
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFDFC),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'musai',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 32,
            color: Colors.black,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              const Row(
                children: [
                  _TabButton(text: '북마크', selected: true),
                  SizedBox(width: 12),
                  _TabButton(text: '티켓', selected: false),
                ],
              ),
              const SizedBox(height: 28),
              const Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _SortDropdown(label: '최신순'),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : bookmarks.isEmpty
                        ? const Center(child: Text('북마크가 없습니다.'))
                        : ListView.separated(
                            padding: const EdgeInsets.only(bottom: 16),
                            itemCount: bookmarks.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final item = bookmarks[index];
                              return Stack(
  children: [
    Container(
      width: 342,
      padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFFEFDFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEAEAEA)),
      ),
      child: Row(
        children: [
          Container(
            width: 67,
            height: 67,
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
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['title'] ?? '',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF343231),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item['artist'] ?? '',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF706B66),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '북마크 등록 날짜',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF706B66),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    Positioned(
      right: 8,
      top: 8,
      child: GestureDetector(
        onTap: () => _deleteBookmark(item['bookmarkId']),
        child: const Icon(Icons.close, size: 12, color: Color(0xFFA28F7D)),
      ),
    ),
  ],
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
  const _TabButton({required this.text, required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 31,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF837670) : const Color(0xFFFEF6F2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 16,
          color: selected ? const Color(0xFFFEFDFC) : const Color(0xFF706B66),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SortDropdown extends StatelessWidget {
  final String label;
  const _SortDropdown({required this.label});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 84,
      height: 28,
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
              style: const TextStyle(
                color: Color(0xFF837670),
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: Color(0xFF837670), size: 18),
          ],
        ),
      ),
    );
  }
}
