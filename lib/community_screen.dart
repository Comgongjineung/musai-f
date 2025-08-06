import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'app_bar_widget.dart';
import 'bottom_nav_bar.dart';
import 'utils/auth_storage.dart';
import 'community_search_screen.dart';
import 'community_write_screen.dart';
import 'community_detail_screen.dart';

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
    if (token == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('http://43.203.23.173:8080/post/readAll'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          posts = data.map((json) => Post.fromJson(json)).toList();
          posts.sort((a, b) => DateTime.parse(b.createdAt).compareTo(DateTime.parse(a.createdAt)));
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
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
                Padding(
                  padding: EdgeInsets.fromLTRB(screenWidth * 0.062, screenWidth * 0.05, screenWidth * 0.062, screenWidth * 0.051),
                  child: _buildSearchBar(screenWidth),
                ),
                Expanded(
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFFA28F7D)))
                      : posts.isEmpty
                          ? _buildEmptyState(screenWidth, screenHeight)
                          : ListView.builder(
                              padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.062,
                                vertical: screenHeight * 0.021,
                              ),
                              itemCount: posts.length,
                              itemBuilder: (context, index) => Padding(
                                padding: EdgeInsets.only(bottom: screenHeight * 0.01),
                                child: _buildPostCard(posts[index], screenWidth, screenHeight),
                              ),
                            ),
                ),
              ],
            ),
            _buildWriteButton(screenWidth, screenHeight),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBarWidget(currentIndex: 2),
    );
  }

  Widget _buildEmptyState(double screenWidth, double screenHeight) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.forum_outlined, size: screenWidth * 0.15, color: const Color(0xFFB1B1B1)),
            SizedBox(height: screenHeight * 0.02),
            Text('게시물이 없습니다',
                style: TextStyle(
                  color: const Color(0xFFB1B1B1),
                  fontSize: screenWidth * 0.04,
                  fontFamily: 'Pretendard',
                )),
          ],
        ),
      );

  Widget _buildSearchBar(double screenWidth) => GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CommunitySearchScreen()),
        ),
        child: Container(
          height: screenWidth * 0.12,
          decoration: BoxDecoration(
            color: const Color(0xFFFEF6F2),
            borderRadius: BorderRadius.circular(20),
          ),
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
          child: Row(
            children: [
              Expanded(
                child: Text('게시물을 검색하세요',
                    style: TextStyle(
                      color: const Color(0xFFB1B1B1),
                      fontSize: screenWidth * 0.04,
                      fontFamily: 'Pretendard',
                    )),
              ),
              Icon(Icons.search, color: const Color(0xFFB1B1B1), size: screenWidth * 0.055),
            ],
          ),
        ),
      );

  Widget _buildWriteButton(double screenWidth, double screenHeight) => Positioned(
        bottom: screenHeight * 0.028,
        left: 0,
        right: 0,
        child: Center(
          child: GestureDetector(
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CommunityWriteScreen()),
              );
              if (result == true) _loadPosts();
            },
            child: Container(
              width: screenWidth * 0.308,
              height: screenHeight * 0.052,
              decoration: BoxDecoration(
                color: const Color(0xFFA28F7D),
                borderRadius: BorderRadius.circular(screenWidth * 0.092),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.edit, color: const Color(0xFFFEFDFC), size: screenWidth * 0.051),
                  SizedBox(width: screenWidth * 0.026),
                  Text('글쓰기',
                      style: TextStyle(
                        color: const Color(0xFFFEFDFC),
                        fontSize: screenWidth * 0.051,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Pretendard',
                      )),
                ],
              ),
            ),
          ),
        ),
      );

  Widget _buildPostCard(Post post, double screenWidth, double screenHeight) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CommunityDetailScreen(postId: post.postId),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.041,
          vertical: screenHeight * 0.021,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFFEFDFC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFEAEAEA)),
        ),
        child: post.image1 != null && post.image1!.isNotEmpty
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(post.title,
                            style: TextStyle(
                              color: const Color(0xFF343231),
                              fontSize: screenWidth * 0.04,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Pretendard',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        SizedBox(height: screenHeight * 0.01),
                        Row(
                          children: [
                            Icon(Icons.chat_bubble_outline, size: screenWidth * 0.03, color: const Color(0xFFB1B1B1)),
                            SizedBox(width: screenWidth * 0.01),
                            Text('8', style: TextStyle(color: const Color(0xFFB1B1B1), fontSize: screenWidth * 0.031, fontFamily: 'Pretendard')),
                            SizedBox(width: screenWidth * 0.01),
                            Icon(Icons.favorite_outline, size: screenWidth * 0.03, color: const Color(0xFFB1B1B1)),
                            SizedBox(width: screenWidth * 0.01),
                            Text('${post.likeCount}', style: TextStyle(color: const Color(0xFFB1B1B1), fontSize: screenWidth * 0.031, fontFamily: 'Pretendard')),
                            SizedBox(width: screenWidth * 0.01),
                            Text(_formatDate(post.createdAt), style: TextStyle(color: const Color(0xFFB1B1B1), fontSize: screenWidth * 0.031, fontFamily: 'Pretendard')),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.06),
                  Container(
                    width: screenWidth * 0.195,
                    height: screenWidth * 0.195,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F0ED),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        post.image1!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Icon(Icons.image_outlined, color: const Color(0xFFB1B1B1), size: screenWidth * 0.06),
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(post.title,
                      style: TextStyle(
                        color: const Color(0xFF343231),
                        fontSize: screenWidth * 0.04,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Pretendard',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  SizedBox(height: screenHeight * 0.01),
                  Row(
                    children: [
                      Icon(Icons.chat_bubble_outline, size: screenWidth * 0.03, color: const Color(0xFFB1B1B1)),
                      SizedBox(width: screenWidth * 0.01),
                      Text('8', style: TextStyle(color: const Color(0xFFB1B1B1), fontSize: screenWidth * 0.031, fontFamily: 'Pretendard')),
                      SizedBox(width: screenWidth * 0.01),
                      Icon(Icons.favorite_outline, size: screenWidth * 0.03, color: const Color(0xFFB1B1B1)),
                      SizedBox(width: screenWidth * 0.01),
                      Text('${post.likeCount}', style: TextStyle(color: const Color(0xFFB1B1B1), fontSize: screenWidth * 0.031, fontFamily: 'Pretendard')),
                      SizedBox(width: screenWidth * 0.01),
                      Text(_formatDate(post.createdAt), style: TextStyle(color: const Color(0xFFB1B1B1), fontSize: screenWidth * 0.031, fontFamily: 'Pretendard')),
                    ],
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

  factory Post.fromJson(Map<String, dynamic> json) => Post(
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
