import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'app_bar_widget.dart';
import 'bottom_nav_bar.dart';
import 'utils/auth_storage.dart';
import 'community_search_screen.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  List<Post> posts = [];
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
    await _loadPosts();
  }

  Future<void> _loadAuthInfo() async {
    token = await getJwtToken();
    userId = await getUserId();
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadPosts() async {
    print('🔍 게시물 로드 시작...');
    print('🔍 토큰: ${token != null ? "있음" : "없음"}');
    
    if (token == null) {
      print('❌ 토큰이 없습니다.');
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      print('🌐 API 호출: http://43.203.23.173:8080/post/readAll');
      final response = await http.get(
        Uri.parse('http://43.203.23.173:8080/post/readAll'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('📊 응답 상태 코드: ${response.statusCode}');
      print('📊 응답 바디: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          posts = data.map((json) => Post.fromJson(json)).toList();
          isLoading = false;
        });
        print('✅ 게시물 로드 완료: ${posts.length}개');
      } else {
        print('❌ 게시물 로드 실패: ${response.statusCode}');
        print('❌ 에러 응답: ${response.body}');
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('❌ 게시물 로드 에러: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return '00.00';
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFDFC),
      appBar: const AppBarWidget(),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // 검색창
                Padding(
                  padding: EdgeInsets.only(
                    left: screenWidth * 0.062, // 24px
                    right: screenWidth * 0.062, // 24px
                    top: screenWidth * 0.05,
                    bottom: screenWidth * 0.051, // 20px
                  ),
                  child: _buildSearchBar(screenWidth),
                ),

                // 게시물 목록
                Expanded(
                  child: isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFA28F7D),
                          ),
                        )
                      : posts.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.forum_outlined,
                                    size: screenWidth * 0.15,
                                    color: const Color(0xFFB1B1B1),
                                  ),
                                  SizedBox(height: screenHeight * 0.02),
                                  Text(
                                    '게시물이 없습니다',
                                    style: TextStyle(
                                      color: const Color(0xFFB1B1B1),
                                      fontSize: screenWidth * 0.04,
                                      fontFamily: 'Pretendard',
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.062, // 24px
                                vertical: screenHeight * 0.021, // 18px
                              ),
                              itemCount: posts.length,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: EdgeInsets.only(bottom: screenHeight * 0.01), // 8px
                                  child: _buildPostCard(posts[index], screenWidth, screenHeight),
                                );
                              },
                            ),
                ),
              ],
            ),
            // 글쓰기 버튼
            Positioned(
              bottom: screenHeight * 0.028, // 24px from bottom navigation
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    // TODO: 글쓰기 페이지로 이동
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('글쓰기 기능은 준비 중입니다.')),
                    );
                  },
                  child: Container(
                    width: screenWidth * 0.308, // 120px
                    height: screenHeight * 0.052, // 44px
                    decoration: BoxDecoration(
                      color: const Color(0xFFA28F7D),
                      borderRadius: BorderRadius.circular(screenWidth * 0.092), // 35.82px
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.edit,
                          color: const Color(0xFFFEFDFC),
                          size: screenWidth * 0.051, // 20px
                        ),
                        SizedBox(width: screenWidth * 0.026), // 10px
                        Text(
                          '글쓰기',
                          style: TextStyle(
                            color: const Color(0xFFFEFDFC),
                            fontSize: screenWidth * 0.051, // 20px
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Pretendard',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBarWidget(currentIndex: 2),
    );
  }

  Widget _buildSearchBar(double screenWidth) => GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CommunitySearchScreen()),
      );
    },
    child: Container(
      height: screenWidth * 0.12, // 44px → 반응형
      decoration: BoxDecoration(
        color: const Color(0xFFFEF6F2),
        borderRadius: BorderRadius.circular(20),
      ),
      alignment: Alignment.centerLeft,
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04), // 16px → 반응형
      child: Row(
        children: [
          Expanded(
            child: Text(
              '게시물을 검색하세요',
              style: TextStyle(
                color: const Color(0xFFB1B1B1),
                fontSize: screenWidth * 0.04, // 16px → 반응형
                fontFamily: 'Pretendard',
              ),
            ),
          ),
          Icon(Icons.search, color: const Color(0xFFB1B1B1), size: screenWidth * 0.055), // 22px → 반응형
        ],
      ),
    ),
  );

  Widget _buildPostCard(Post post, double screenWidth, double screenHeight) {
    return GestureDetector(
      onTap: () {
        // TODO: 게시물 상세 페이지로 이동
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('게시물 "${post.title}" 상세보기는 준비 중입니다.')),
        );
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.041, // 16px
          vertical: screenHeight * 0.021, // 18px
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFFEFDFC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFEAEAEA)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 텍스트 영역
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 제목
                  Text(
                    post.title,
                    style: TextStyle(
                      color: const Color(0xFF343231),
                      fontSize: screenWidth * 0.04, // 16px
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Pretendard',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: screenHeight * 0.01), // 간격
                  // 댓글 수, 좋아요 수, 작성일
                  Row(
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: screenWidth * 0.03, // 12px
                        color: const Color(0xFFB1B1B1),
                      ),
                      SizedBox(width: screenWidth * 0.01), // 4px
                      Text(
                        '8', // mock 댓글 수
                        style: TextStyle(
                          color: const Color(0xFFB1B1B1),
                          fontSize: screenWidth * 0.031, // 12px
                          fontFamily: 'Pretendard',
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.01), // 4px
                      Icon(
                        Icons.favorite_outline,
                        size: screenWidth * 0.03, // 12px
                        color: const Color(0xFFB1B1B1),
                      ),
                      SizedBox(width: screenWidth * 0.01), // 4px
                      Text(
                        '${post.likeCount}',
                        style: TextStyle(
                          color: const Color(0xFFB1B1B1),
                          fontSize: screenWidth * 0.031, // 12px
                          fontFamily: 'Pretendard',
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.01), // 4px
                      Text(
                        _formatDate(post.createdAt),
                        style: TextStyle(
                          color: const Color(0xFFB1B1B1),
                          fontSize: screenWidth * 0.031, // 12px
                          fontFamily: 'Pretendard',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // 이미지 영역
            SizedBox(width: screenWidth * 0.06), // 22px gap
            Container(
              width: screenWidth * 0.195, // 76px
              height: screenWidth * 0.195, // 76px
              decoration: BoxDecoration(
                color: const Color(0xFFF4F0ED),
                borderRadius: BorderRadius.circular(10), // 10px
              ),
              child: post.image1 != null && post.image1!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10), // 10px
                      child: Image.network(
                        post.image1!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF4F0ED),
                              borderRadius: BorderRadius.circular(10), // 10px
                            ),
                            child: Icon(
                              Icons.image_outlined,
                              color: const Color(0xFFB1B1B1),
                              size: screenWidth * 0.06, // 24px
                            ),
                          );
                        },
                      ),
                    )
                  : Icon(
                      Icons.image_outlined,
                      color: const Color(0xFFB1B1B1),
                      size: screenWidth * 0.06, // 24px
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class Post {
  final int postId;
  final int userId;
  final String title;
  final String content;
  final String? image1;
  final String? image2;
  final String? image3;
  final String? image4;
  final String createdAt;
  final String updatedAt;
  final int likeCount;

  Post({
    required this.postId,
    required this.userId,
    required this.title,
    required this.content,
    this.image1,
    this.image2,
    this.image3,
    this.image4,
    required this.createdAt,
    required this.updatedAt,
    required this.likeCount,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      postId: json['postId'] ?? 0,
      userId: json['userId'] ?? 0,
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      image1: json['image1'],
      image2: json['image2'],
      image3: json['image3'],
      image4: json['image4'],
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
      likeCount: json['likeCount'] ?? 0,
    );
  }
} 