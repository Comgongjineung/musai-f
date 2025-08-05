import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'app_bar_widget.dart';
import 'utils/auth_storage.dart';

class CommunitySearchScreen extends StatefulWidget {
  const CommunitySearchScreen({super.key});

  @override
  State<CommunitySearchScreen> createState() => _CommunitySearchScreenState();
}

class _CommunitySearchScreenState extends State<CommunitySearchScreen> {
  final TextEditingController _controller = TextEditingController();
  bool isSearchDone = false;
  List<Post> postList = [];

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    if (_controller.text.trim().isEmpty) {
      setState(() {
        isSearchDone = false;
        postList = [];
      });
    }
  }

  Future<void> fetchPosts(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        isSearchDone = false;
        postList = [];
      });
      return;
    }

    final token = await getJwtToken();
    if (token == null) {
      debugPrint('토큰 없음. 로그인 필요');
      return;
    }

    try {
      final uri = Uri.parse('http://43.203.23.173:8080/post/search?keyword=${Uri.encodeQueryComponent(query)}');
      final response = await http.get(
        uri,
        headers: {
          'accept': '*/*',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final utf8Decoded = utf8.decode(response.bodyBytes);
        final List<dynamic> data = json.decode(utf8Decoded);

        setState(() {
          postList = data.map((json) => Post.fromJson(json)).toList();
          isSearchDone = true;
        });
        print('✅ 게시물 검색 완료: ${postList.length}개 결과');
      } else {
        print('❌ 게시물 검색 실패: ${response.statusCode}');
        setState(() {
          postList = [];
          isSearchDone = true;
        });
      }
    } catch (e) {
      print('❌ 게시물 검색 에러: $e');
      setState(() {
        postList = [];
        isSearchDone = true;
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
      appBar: const AppBarWidget(showBackButton: true),
      body: SafeArea(
        child: Column(
          children: [
            // 검색 입력창
            Padding(
              padding: EdgeInsets.only(
                left: screenWidth * 0.062, // 24px
                right: screenWidth * 0.062, // 24px
                top: screenWidth * 0.05,
                bottom: screenWidth * 0.051, // 20px
              ),
              child: Container(
                height: screenWidth * 0.12, // 44px → 반응형
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF6F2),
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04), // 16px → 반응형
                child: TextField(
                  controller: _controller,
                  autofocus: true,
                  onSubmitted: (value) {
                    fetchPosts(value);
                  },
                  decoration: InputDecoration(
                    hintText: '게시물을 검색하세요',
                    hintStyle: TextStyle(
                      color: const Color(0xFFB1B1B1),
                      fontSize: screenWidth * 0.04, // 16px → 반응형
                      fontFamily: 'Pretendard',
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    suffixIcon: Icon(
                      Icons.search,
                      color: const Color(0xFFB1B1B1),
                      size: screenWidth * 0.055, // 22px → 반응형
                    ),
                  ),
                ),
              ),
            ),

            // 검색 결과
            Expanded(
              child: isSearchDone
                  ? postList.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: screenWidth * 0.15,
                                color: const Color(0xFFB1B1B1),
                              ),
                              SizedBox(height: screenHeight * 0.02),
                              Text(
                                '검색 결과가 없습니다',
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
                          itemCount: postList.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: EdgeInsets.only(bottom: screenHeight * 0.01),
                              child: _buildPostCard(postList[index], screenWidth, screenHeight),
                            );
                          },
                        )
                  : Container(),
            ),
          ],
        ),
      ),
    );
  }

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
                      fontSize: screenWidth * 0.04,
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
                        size: screenWidth * 0.03,
                        color: const Color(0xFFB1B1B1),
                      ),
                      SizedBox(width: screenWidth * 0.01),
                      Text(
                        '8', // mock 댓글 수
                        style: TextStyle(
                          color: const Color(0xFFB1B1B1),
                          fontSize: screenWidth * 0.031,
                          fontFamily: 'Pretendard',
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.01),
                      Icon(
                        Icons.favorite_outline,
                        size: screenWidth * 0.03,
                        color: const Color(0xFFB1B1B1),
                      ),
                      SizedBox(width: screenWidth * 0.01),
                      Text(
                        '${post.likeCount}',
                        style: TextStyle(
                          color: const Color(0xFFB1B1B1),
                          fontSize: screenWidth * 0.031,
                          fontFamily: 'Pretendard',
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.01),
                      Text(
                        _formatDate(post.createdAt),
                        style: TextStyle(
                          color: const Color(0xFFB1B1B1),
                          fontSize: screenWidth * 0.031,
                          fontFamily: 'Pretendard',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // 이미지 영역
            SizedBox(width: screenWidth * 0.06),
            Container(
              width: screenWidth * 0.195,
              height: screenWidth * 0.195,
              decoration: BoxDecoration(
                color: const Color(0xFFF4F0ED),
                borderRadius: BorderRadius.circular(screenWidth * 0.026),
              ),
              child: post.image1 != null && post.image1!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(screenWidth * 0.026),
                      child: Image.network(
                        post.image1!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF4F0ED),
                              borderRadius: BorderRadius.circular(screenWidth * 0.026),
                            ),
                            child: Icon(
                              Icons.image_outlined,
                              color: const Color(0xFFB1B1B1),
                              size: screenWidth * 0.06,
                            ),
                          );
                        },
                      ),
                    )
                  : Icon(
                      Icons.image_outlined,
                      color: const Color(0xFFB1B1B1),
                      size: screenWidth * 0.06,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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