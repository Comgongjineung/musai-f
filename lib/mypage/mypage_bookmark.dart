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
  String? selectedStyle; // 선택된 예술사조
  bool isStyleExpanded = false; // 예술사조 필터 확장 여부
  
  // 예술사조 목록 (한글 순서대로 정렬)
  final List<String> artStyles = [
    '고대 미술',
    '남아시아',
    '동남아시아',
    '동아시아',
    '로코코',
    '르네상스',
    '바로크',
    '사실주의',
    '서아시아 / 중동',
    '신고전주의',
    '아르누보',
    '인상주의',
    '입체주의',
    '중세 미술',
    '중앙아시아',
    '추상표현주의',
    '초현실주의',
    '팝아트',
    '표현주의',
    '현대미술',
    '후기 인상주의',
    '미상'
  ];

  // 예술사조 버튼 폭 계산
  double _styleButtonWidth(String style) {
    if (style == '서아시아 / 중동') return 66;
    final int charCount = style.replaceAll(' ', '').length;
    return charCount <= 4 ? 58 : 62;
  }

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

    String url;
    if (selectedStyle != null) {
      // 예술사조별 조회
      url = 'http://43.203.23.173:8080/bookmark/readAll/$userId/${Uri.encodeComponent(selectedStyle!)}';
      print('🎨 예술사조별 북마크 조회: $selectedStyle');
    } else {
      // 전체 조회
      url = 'http://43.203.23.173:8080/bookmark/readAll/$userId';
      print('📚 전체 북마크 조회');
    }

    final response = await http.get(
      Uri.parse(url),
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

  // 예술사조 필터 UI 빌드
  Widget _buildStyleFilter(double screenWidth, double screenHeight) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 첫 줄: 처음 5개 + 우측 V 아이콘(고정)
        SizedBox(
          height: 24,
          child: Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: artStyles
                      .take(5)
                      .map((style) => _buildStyleButton(style))
                      .toList(),
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    isStyleExpanded = !isStyleExpanded;
                  });
                },
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: Center(
                    child: Icon(
                      isStyleExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: const Color(0xFF837670),
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // 둘째 줄: 확장 시 나머지 사조들 표시
        if (isStyleExpanded) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: artStyles
                .skip(5)
                .map((style) => _buildStyleButton(style))
                .toList(),
          ),
        ],
      ],
    );
  }

  // 개별 예술사조 버튼 빌드
  Widget _buildStyleButton(String style) {
    final isSelected = selectedStyle == style;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            selectedStyle = null; // 선택 해제
          } else {
            selectedStyle = style; // 새로운 선택
          }
        });
        _loadBookmarks(); // 북마크 다시 로드
      },
      child: Container(
        width: _styleButtonWidth(style),
        height: 24,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF837670) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF837670)),
        ),
        child: Text(
          style,
          style: TextStyle(
            fontSize: 12,
            color: isSelected ? Colors.white : const Color(0xFF837670),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
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
               
                               // 예술사조 필터
                _buildStyleFilter(screenWidth, screenHeight),
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
        print('🔍 북마크 상세 조회 응답: $data');
        print('🎭 북마크 style 값: ${data['style']}');

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
              style: data['style'], // 예술사조 추가
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




