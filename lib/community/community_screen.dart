import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../app_bar_widget.dart';
import '../bottom_nav_bar.dart';
import '../utils/auth_storage.dart';
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
        print('📊 파싱된 게시물 개수: ${data.length}');
        
        // 빈 배열인 경우 사용자 권한 확인
        if (data.isEmpty) {
          print('⚠️ 게시물이 비어있음 - 사용자 ID: $userId');
          await _checkUserInfo();
        }
        
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

  Future<void> _checkUserInfo() async {
    if (token == null || userId == null) return;
    
    try {
      print('👤 사용자 정보 확인 중...');
      final response = await http.get(
        Uri.parse('http://43.203.23.173:8080/user/read/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      print('👤 사용자 정보 응답 상태: ${response.statusCode}');
      print('👤 사용자 정보 응답: ${response.body}');
      
      if (response.statusCode == 200) {
        final userData = json.decode(response.body);
        print('👤 사용자 ID: ${userData['userId']}');
        print('👤 이메일: ${userData['email']}');
        print('👤 닉네임: ${userData['nickname']}');
        print('👤 프로필 이미지: ${userData['profileImage']}');
      } else {
        print('❌ 사용자 정보 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 사용자 정보 조회 오류: $e');
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
                  padding: EdgeInsets.fromLTRB(screenWidth * 0.06, screenWidth * 0.03, screenWidth * 0.06, screenWidth * 0.03),
                  child: _buildSearchBar(screenWidth),
                ),
                Expanded(
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFFA28F7D)))
                      : posts.isEmpty
                          ? _buildEmptyState(screenWidth, screenHeight)
                          : ListView.builder(
                              padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.06,
                                vertical: screenHeight * 0.02,
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
                color: const Color(0xFF837670),
                borderRadius: BorderRadius.circular(screenWidth * 0.092),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0x66665E5E).withOpacity(0.3),
                    offset: Offset(0, 0),
                    blurRadius: 23.88,
                    spreadRadius: 0,
                  ),
                ],
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
                      )),
                ],
              ),
            ),
          ),
        ),
      );

  Widget _buildImageWidget(String imageData) {
    // Base64 데이터인지 URL인지 판단
    if (imageData.startsWith('data:image/') || imageData.startsWith('/9j/') || imageData.startsWith('iVBORw0KGgo')) {
      // Base64 데이터인 경우
      try {
        return Image.memory(
          base64Decode(imageData),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Icon(Icons.image_outlined, color: const Color(0xFFB1B1B1), size: 24),
        );
      } catch (e) {
        print('❌ Base64 이미지 디코딩 실패: $e');
        return Icon(Icons.image_outlined, color: const Color(0xFFB1B1B1), size: 24);
      }
    } else if (imageData.startsWith('http://') || imageData.startsWith('https://')) {
      // URL인 경우
      return Image.network(
        imageData,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Icon(Icons.image_outlined, color: const Color(0xFFB1B1B1), size: 24),
      );
    } else {
      // 기타 경우 (파일명 등)
      return Icon(Icons.image_outlined, color: const Color(0xFFB1B1B1), size: 24);
    }
  }

  Widget _buildPostCard(Post post, double screenWidth, double screenHeight) {
    // 디버깅: 이미지 데이터 출력
    /*print('🔍 게시물 ${post.postId} 이미지 정보:');
    print('  - image1: ${post.image1}');
    print('  - image1 길이: ${post.image1?.length ?? 0}');
    print('  - image1 null 여부: ${post.image1 == null}');
    print('  - image1 빈 문자열 여부: ${post.image1?.isEmpty ?? true}');
    print('  - image1 "string" 여부: ${post.image1 == "string"}');
    print('  - image1 시작 부분: ${post.image1?.substring(0, post.image1!.length > 50 ? 50 : post.image1!.length)}'); */
    
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CommunityDetailScreen(postId: post.postId),
          ),
        );
        // 게시글 작성자를 차단한 경우 게시물 목록 새로고침
        if (result == true) {
          _loadPosts();
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.04,
          vertical: screenHeight * 0.02,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFFEFDFC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFEAEAEA)),
        ),
        child: post.image1 != null && post.image1!.isNotEmpty && post.image1 != 'string' && post.image1!.length > 10
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
                            Icon(Icons.chat_bubble_outline, size: screenWidth * 0.03, color: const Color(0xFF706B66)),
                            SizedBox(width: screenWidth * 0.01),
                            Text('${post.commentCount}', style: TextStyle(color: const Color(0xFF706B66), fontSize: screenWidth * 0.031, fontFamily: 'Pretendard')),
                            SizedBox(width: screenWidth * 0.01),
                            Icon(Icons.favorite_outline, size: screenWidth * 0.03, color: const Color(0xFF706B66)),
                            SizedBox(width: screenWidth * 0.01),
                            Text('${post.likeCount}', style: TextStyle(color: const Color(0xFF706B66), fontSize: screenWidth * 0.031, fontFamily: 'Pretendard')),
                            SizedBox(width: screenWidth * 0.01),
                            Text(_formatDate(post.createdAt), style: TextStyle(color: const Color(0xFF706B66), fontSize: screenWidth * 0.031, fontFamily: 'Pretendard')),
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
                      child: _buildImageWidget(post.image1!),
                    ),
                  ),
                ],
              )
            : Container(
                height: screenWidth * 0.195,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                    Row(
                      children: [
                        Icon(Icons.chat_bubble_outline, size: screenWidth * 0.03, color: const Color(0xFF706B66)),
                        SizedBox(width: screenWidth * 0.01),
                        Text('${post.commentCount}', style: TextStyle(color: const Color(0xFF706B66), fontSize: screenWidth * 0.031, fontFamily: 'Pretendard')),
                        SizedBox(width: screenWidth * 0.01),
                        Icon(Icons.favorite_outline, size: screenWidth * 0.03, color: const Color(0xFF706B66)),
                        SizedBox(width: screenWidth * 0.01),
                        Text('${post.likeCount}', style: TextStyle(color: const Color(0xFF706B66), fontSize: screenWidth * 0.031, fontFamily: 'Pretendard')),
                        SizedBox(width: screenWidth * 0.01),
                        Text(_formatDate(post.createdAt), style: TextStyle(color: const Color(0xFF706B66), fontSize: screenWidth * 0.031, fontFamily: 'Pretendard')),
                      ],
                    ),
                  ],
                ),
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
  final int commentCount;

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
    required this.commentCount,
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
        commentCount: json['commentCount'] ?? 0,
      );
}
