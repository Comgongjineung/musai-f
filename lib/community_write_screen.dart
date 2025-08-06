import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'utils/auth_storage.dart';
import 'community_screen.dart';

class CommunityWriteScreen extends StatefulWidget {
  const CommunityWriteScreen({super.key});

  @override
  State<CommunityWriteScreen> createState() => _CommunityWriteScreenState();
}

class _CommunityWriteScreenState extends State<CommunityWriteScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  bool isLoading = false;
  String? token;
  int? userId;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadAuthInfo();
  }

  Future<void> _loadAuthInfo() async {
    token = await getJwtToken();
    userId = await getUserId();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submitPost() async {
    if (_titleController.text.trim().isEmpty || _contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('제목과 내용을 모두 입력해주세요.')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('로그인이 필요합니다.')),
        );
        return;
      }
      
      final requestBody = {
        'postId': 0,
        'userId': userId ?? 0,
        'title': _titleController.text.trim(),
        'content': _contentController.text.trim(),
        'image1': 'string',
        'image2': 'string',
        'image3': 'string',
        'image4': 'string',
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
        'likeCount': 0,
      };

      print('🔍 게시물 작성 시작...');
      print('🔍 토큰: ${token != null ? "있음" : "없음"}');
      print('🔍 사용자 ID: $userId');
      print('📤 요청 바디: ${json.encode(requestBody)}');

      final response = await http.post(
        Uri.parse('http://43.203.23.173:8080/post/add'),
        headers: {
          'accept': '*/*',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(requestBody),
      );

      print('📊 응답 상태 코드: ${response.statusCode}');
      print('📊 응답 바디: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('게시물이 성공적으로 작성되었습니다.')),
        );
        // 성공 결과와 함께 이전 화면으로 돌아가기
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('게시물 작성에 실패했습니다. (${response.statusCode})')),
        );
      }
    } catch (e) {
      print('❌ 게시물 작성 에러: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류가 발생했습니다: $e')),
      );
    } finally {
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
      backgroundColor: const Color(0xFFFFFEFD),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: GestureDetector(
          onTap: () {
            // 키보드 숨기기
            FocusScope.of(context).unfocus();
          },
          child: Stack(
            children: [
              // X 버튼
              Positioned(
                top: screenHeight * (23 / 844),
                left: screenWidth * (24 / 390),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.black),
                  onPressed: () => Navigator.pop(context),
                ),
              ),

              // 글쓰기 텍스트
              Positioned(
                top: screenHeight * (31 / 844),
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    '글쓰기',
                    style: TextStyle(
                      fontSize: screenWidth * (20 / 390),
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Pretendard',
                    ),
                  ),
                ),
              ),

              // 완료 버튼
              Positioned(
                top: screenHeight * (31 / 844),
                right: screenWidth * (24 / 390),
                child: GestureDetector(
                  onTap: isLoading ? null : _submitPost,
                  child: Container(
                    width: screenWidth * (52 / 390),
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * (12 / 390),
                      vertical: screenHeight * (4 / 844),
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF837670),
                      borderRadius: BorderRadius.circular(screenWidth * (23.226 / 390)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color.fromRGBO(177, 177, 177, 0.3),
                          blurRadius: screenWidth * (3.097 / 390),
                          spreadRadius: screenWidth * (0.774 / 390),
                        ),
                      ],
                    ),
                    child: Center(
                      child: isLoading
                          ? SizedBox(
                              width: screenWidth * (16 / 390),
                              height: screenWidth * (16 / 390),
                              child: const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              '완료',
                              style: TextStyle(
                                fontSize: screenWidth * (16 / 390),
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Pretendard',
                              ),
                            ),
                    ),
                  ),
                ),
              ),

              // 본문 입력 영역
              Positioned(
                top: screenHeight * (87 / 844),
                left: screenWidth * (24 / 390),
                right: screenWidth * (24 / 390),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // 제목 입력란
                      Container(
                        width: screenWidth * (342 / 390),
                        height: screenHeight * (48 / 844),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF6F2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: TextField(
                          controller: _titleController,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: screenWidth * (20 / 390),
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Pretendard',
                          ),
                          decoration: InputDecoration(
                            hintText: '제목',
                            hintStyle: TextStyle(
                              color: const Color(0xFFB1B1B1),
                              fontSize: screenWidth * (20 / 390),
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Pretendard',
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: screenWidth * (20 / 390),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: screenHeight * (8 / 844)),
                      // 내용 입력란
                      Container(
                        width: screenWidth * (342 / 390),
                        height: screenHeight * (456 / 844),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFEBEBEB)),
                        ),
                        child: TextField(
                          controller: _contentController,
                          maxLines: null,
                          expands: true,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: screenWidth * (16 / 390),
                            fontFamily: 'Pretendard',
                          ),
                          decoration: InputDecoration(
                            hintText: '내용을 입력하세요.',
                            hintStyle: TextStyle(
                              color: const Color(0xFFB1B1B1),
                              fontSize: screenWidth * (16 / 390),
                              fontFamily: 'Pretendard',
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(screenWidth * (20 / 390)),
                          ),
                        ),
                      ),
                      SizedBox(height: screenHeight * (20 / 844)),
                      // 커뮤니티 이용 수칙
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: EdgeInsets.only(left: screenWidth * (16 / 390)),
                          child: Text(
                            '커뮤니티 이용 수칙\n비속어 사용 금지 등등..',
                            style: TextStyle(
                              color: const Color(0xFF706B66),
                              fontSize: screenWidth * (12 / 390),
                              fontWeight: FontWeight.w400,
                              fontFamily: 'Pretendard',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
