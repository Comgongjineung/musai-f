import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'app_bar_widget.dart';
import 'utils/auth_storage.dart';

class CommunityDetailScreen extends StatefulWidget {
  final int postId;
  
  const CommunityDetailScreen({super.key, required this.postId});

  @override
  State<CommunityDetailScreen> createState() => _CommunityDetailScreenState();
}

class _CommunityDetailScreenState extends State<CommunityDetailScreen> {
  PostDetail? postDetail;
  UserInfo? userInfo;
  CommentPage? commentPage;
  bool isLoading = true;
  bool isLoadingComments = false;
  bool isLiked = false;
  String? token;
  int? userId;
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    print('초기화 시작');
    await _loadAuthInfo();
    print('인증 정보 로드 완료 - 토큰: $token, userId: $userId');
    
    if (token != null) {
      await _loadPostDetail();
      await _loadUserInfo();
      await _loadComments();
    } else {
      print('토큰이 없어서 초기화를 중단합니다.');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadAuthInfo() async {
    token = await getJwtToken();
    userId = await getUserId();
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadPostDetail() async {
    if (token == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('http://43.203.23.173:8080/post/detail/${widget.postId}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          postDetail = PostDetail.fromJson(data);
        });
      }
    } catch (e) {
      print('게시물 상세 정보 로드 실패: $e');
    }
  }

  Future<void> _loadUserInfo() async {
    if (token == null || postDetail == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('http://43.203.23.173:8080/user/read/${postDetail!.userId}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          userInfo = UserInfo.fromJson(data);
        });
      }
    } catch (e) {
      print('사용자 정보 로드 실패: $e');
    }
  }

  Future<void> _loadComments() async {
    if (token == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    setState(() {
      isLoadingComments = true;
    });

    try {
      print('댓글 로드 요청: /comment/readAll/${widget.postId}?page=0');
      print('토큰: $token');
      
      final response = await http.get(
        Uri.parse('http://43.203.23.173:8080/comment/readAll/${widget.postId}?page=0'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'accept': '*/*',
        },
      );

      print('댓글 로드 응답 상태: ${response.statusCode}');
      print('댓글 로드 응답 바디: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        print('파싱된 데이터: $data');
        print('content 필드 타입: ${data['content'].runtimeType}');
        print('content 필드 값: ${data['content']}');
        
        // API 응답 구조 확인
        if (data is Map<String, dynamic>) {
          setState(() {
            commentPage = CommentPage.fromJson(data);
            isLoading = false;
          });
          print('댓글 페이지 설정 완료: ${commentPage?.content.length}개 댓글');
          print('댓글 목록: ${commentPage?.content.map((c) => c.content).toList()}');
        } else {
          print('예상하지 못한 응답 형식: ${data.runtimeType}');
          setState(() {
            isLoading = false;
          });
        }
      } else {
        print('댓글 로드 실패 - 상태 코드: ${response.statusCode}');
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('댓글 로드 실패: $e');
      setState(() {
        isLoading = false;
      });
    } finally {
      setState(() {
        isLoadingComments = false;
      });
    }
  }

  Future<void> _submitComment() async {
    if (token == null || _commentController.text.trim().isEmpty) {
      return;
    }

    try {
      final requestBody = {
        'userId': userId ?? 0,
        'postId': widget.postId,
        'parentCommentId': 1, // 최상위 댓글은 1로 설정 (API 명세에 따름)
        'content': _commentController.text.trim(),
      };

      print('댓글 작성 요청: ${json.encode(requestBody)}');

      final response = await http.post(
        Uri.parse('http://43.203.23.173:8080/comment/add'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'accept': '*/*',
        },
        body: json.encode(requestBody),
      );

      print('댓글 작성 응답 상태: ${response.statusCode}');
      print('댓글 작성 응답 바디: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        _commentController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('댓글이 성공적으로 작성되었습니다.')),
        );
        // 서버가 댓글을 처리할 시간을 주기 위해 잠시 대기
        await Future.delayed(const Duration(milliseconds: 500));
        // 댓글 목록 새로고침
        await _loadComments();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('댓글 작성에 실패했습니다.')),
        );
      }
    } catch (e) {
      print('댓글 작성 실패: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('댓글 작성 중 오류가 발생했습니다.')),
      );
    }
  }

  Future<void> _toggleLike() async {
    if (token == null || userId == null) {
      return;
    }

    try {
      final requestBody = {
        'postId': widget.postId,
        'userId': userId,
      };

      if (isLiked) {
        // 공감 취소
        final response = await http.delete(
          Uri.parse('http://43.203.23.173:8080/like/delete'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: json.encode(requestBody),
        );

        if (response.statusCode == 200) {
          setState(() {
            isLiked = false;
            postDetail = PostDetail(
              postId: postDetail!.postId,
              userId: postDetail!.userId,
              title: postDetail!.title,
              content: postDetail!.content,
              image1: postDetail!.image1,
              image2: postDetail!.image2,
              image3: postDetail!.image3,
              image4: postDetail!.image4,
              createdAt: postDetail!.createdAt,
              updatedAt: postDetail!.updatedAt,
              likeCount: postDetail!.likeCount - 1,
            );
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('공감이 취소되었습니다.')),
          );
        }
      } else {
        // 공감 등록
        final response = await http.post(
          Uri.parse('http://43.203.23.173:8080/like/add'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: json.encode(requestBody),
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          setState(() {
            isLiked = true;
            postDetail = PostDetail(
              postId: postDetail!.postId,
              userId: postDetail!.userId,
              title: postDetail!.title,
              content: postDetail!.content,
              image1: postDetail!.image1,
              image2: postDetail!.image2,
              image3: postDetail!.image3,
              image4: postDetail!.image4,
              createdAt: postDetail!.createdAt,
              updatedAt: postDetail!.updatedAt,
              likeCount: postDetail!.likeCount + 1,
            );
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('공감이 등록되었습니다.')),
          );
        }
      }
    } catch (e) {
      print('공감 토글 실패: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('공감 처리 중 오류가 발생했습니다.')),
      );
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return '2025.08.02';
    }
  }

  String _formatTime(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '25.08.02 11:15';
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
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
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onPressed: () {
              // TODO: 더보기 메뉴
            },
          ),
        ],
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFA28F7D)))
            : postDetail == null
                ? const Center(child: Text('게시물을 찾을 수 없습니다'))
                : Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.041),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 사용자 정보
                              _buildUserInfo(screenWidth, screenHeight),
                              SizedBox(height: screenHeight * 0.02),
                              
                                                             // 본문
                               _buildPostContent(screenWidth, screenHeight),
                               SizedBox(height: screenHeight * 0.06),
                               
                               // 댓글/공감 버튼
                               _buildInteractionButtons(screenWidth, screenHeight),
                               SizedBox(height: screenHeight * 0.06),
                              
                              // 댓글 목록
                              _buildCommentList(screenWidth, screenHeight),
                            ],
                          ),
                        ),
                      ),
                      
                      // 댓글 입력창
                      _buildCommentInput(screenWidth, screenHeight),
                    ],
                  ),
      ),
    );
  }

  Widget _buildUserInfo(double screenWidth, double screenHeight) {
    return Row(
      children: [
        // 프로필 이미지
        Container(
          width: screenWidth * 0.12,
          height: screenWidth * 0.12,
          decoration: BoxDecoration(
            color: const Color(0xFFF4F0ED),
            borderRadius: BorderRadius.circular(screenWidth * 0.06),
          ),
          child: userInfo?.profileImage != null && userInfo!.profileImage!.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(screenWidth * 0.06),
                  child: Image.network(
                    userInfo!.profileImage!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.person,
                      color: Color(0xFFB1B1B1),
                      size: 24,
                    ),
                  ),
                )
              : const Icon(
                  Icons.person,
                  color: Color(0xFFB1B1B1),
                  size: 24,
                ),
        ),
        SizedBox(width: screenWidth * 0.03),
        
        // 사용자 정보
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                userInfo?.nickname ?? '닉네임',
                style: TextStyle(
                  fontSize: screenWidth * 0.04,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Pretendard',
                  color: const Color(0xFF343231),
                ),
              ),
              SizedBox(height: screenHeight * 0.005),
              Text(
                _formatDate(postDetail!.createdAt),
                style: TextStyle(
                  fontSize: screenWidth * 0.035,
                  fontFamily: 'Pretendard',
                  color: const Color(0xFFB1B1B1),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPostContent(double screenWidth, double screenHeight) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 제목
        Text(
          postDetail!.title,
          style: TextStyle(
            fontSize: screenWidth * 0.051,
            fontWeight: FontWeight.bold,
            fontFamily: 'Pretendard',
            color: const Color(0xFF343231),
          ),
        ),
        SizedBox(height: screenHeight * 0.02),
        
        // 내용
        Text(
          postDetail!.content,
          style: TextStyle(
            fontSize: screenWidth * 0.041,
            fontFamily: 'Pretendard',
            color: const Color(0xFF343231),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildInteractionButtons(double screenWidth, double screenHeight) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // 댓글 버튼
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF837670), width: 0.928),
            borderRadius: BorderRadius.circular(15.907),
            color: const Color(0xFFFFFDFC),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.chat_bubble_outline, size: 16, color: Color(0xFF837670)),
              const SizedBox(width: 4),
              Text('댓글 ${commentPage?.content.length ?? 0}', style: const TextStyle(fontSize: 14, fontFamily: 'Pretendard', color: Color(0xFF837670))),
            ],
          ),
        ),
        
        // 공감 버튼
        GestureDetector(
          onTap: _toggleLike,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF837670), width: 0.928),
              borderRadius: BorderRadius.circular(15.907),
              color: const Color(0xFFFFFDFC),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isLiked ? Icons.favorite : Icons.favorite_border,
                  size: 16,
                  color: isLiked ? Colors.red : const Color(0xFF837670),
                ),
                const SizedBox(width: 4),
                Text(
                  '공감 ${postDetail!.likeCount}',
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'Pretendard',
                    color: isLiked ? Colors.red : const Color(0xFF837670),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCommentList(double screenWidth, double screenHeight) {
    print('댓글 목록 빌드 - isLoadingComments: $isLoadingComments');
    print('댓글 페이지: ${commentPage?.content.length}개 댓글');
    print('댓글 페이지 null 여부: ${commentPage == null}');
    print('댓글 목록 null 여부: ${commentPage?.content == null}');
    print('댓글 목록 비어있음 여부: ${commentPage?.content.isEmpty}');
    
    if (isLoadingComments) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFA28F7D)));
    }

    if (commentPage?.content == null || commentPage!.content.isEmpty) {
      print('댓글이 없음 - commentPage: $commentPage');
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '댓글',
            style: TextStyle(
              fontSize: screenWidth * 0.045,
              fontWeight: FontWeight.bold,
              fontFamily: 'Pretendard',
              color: const Color(0xFF343231),
            ),
          ),
          SizedBox(height: screenHeight * 0.02),
          const Center(
            child: Text(
              '아직 댓글이 없습니다.',
              style: TextStyle(
                fontSize: 14,
                fontFamily: 'Pretendard',
                color: Color(0xFFB1B1B1),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '댓글',
          style: TextStyle(
            fontSize: screenWidth * 0.045,
            fontWeight: FontWeight.bold,
            fontFamily: 'Pretendard',
            color: const Color(0xFF343231),
          ),
        ),
        SizedBox(height: screenHeight * 0.02),
        
        ...commentPage!.content.map((comment) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _buildCommentItem(comment, screenWidth, screenHeight),
        )),
      ],
    );
  }

  Widget _buildCommentItem(Comment comment, double screenWidth, double screenHeight) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFFEFDFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEBEBEB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 댓글 헤더
          Row(
            children: [
              Expanded(
                child: Text(
                  '사용자 ${comment.userId}', // TODO: 사용자 정보 API로 닉네임 가져오기
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Pretendard',
                    color: Color(0xFF343231),
                  ),
                ),
              ),
              Row(
                children: [
                  Text(
                    _formatTime(comment.createdAt),
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'Pretendard',
                      color: Color(0xFFB1B1B1),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.info_outline,
                    size: 14,
                    color: Color(0xFFB1B1B1),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          
          // 댓글 내용
          Text(
            comment.content,
            style: const TextStyle(
              fontSize: 14,
              fontFamily: 'Pretendard',
              color: Color(0xFF343231),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput(double screenWidth, double screenHeight) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDFC),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x4DB1B1B1),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Container(
        width: 342,
        height: 43,
        decoration: BoxDecoration(
          color: const Color(0xFFFEF6F2),
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                decoration: const InputDecoration(
                  hintText: '댓글을 입력하세요',
                  hintStyle: TextStyle(
                    fontSize: 14,
                    fontFamily: 'Pretendard',
                    color: Color(0xFFB1B1B1),
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _submitComment,
              child: const Icon(
                Icons.send,
                size: 20,
                color: Color(0xFFA28F7D),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PostDetail {
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

  PostDetail({
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

  factory PostDetail.fromJson(Map<String, dynamic> json) => PostDetail(
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

class UserInfo {
  final int userId;
  final String email;
  final String nickname;
  final String? profileImage;

  UserInfo({
    required this.userId,
    required this.email,
    required this.nickname,
    this.profileImage,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) => UserInfo(
        userId: json['userId'] ?? 0,
        email: json['email'] ?? '',
        nickname: json['nickname'] ?? '',
        profileImage: json['profileImage'],
      );
}

class CommentPage {
  final int totalPages;
  final int totalElements;
  final Pageable pageable;
  final int size;
  final List<Comment> content;
  final int number;
  final List<Sort> sort;
  final int numberOfElements;
  final bool first;
  final bool last;
  final bool empty;

  CommentPage({
    required this.totalPages,
    required this.totalElements,
    required this.pageable,
    required this.size,
    required this.content,
    required this.number,
    required this.sort,
    required this.numberOfElements,
    required this.first,
    required this.last,
    required this.empty,
  });

  factory CommentPage.fromJson(Map<String, dynamic> json) {
    print('CommentPage.fromJson 호출됨');
    print('입력 JSON: $json');
    
    try {
      // content 필드 안전하게 처리
      List<Comment> contentList = [];
      if (json['content'] != null) {
        if (json['content'] is List) {
          contentList = (json['content'] as List)
              .map((e) => Comment.fromJson(e))
              .toList();
        } else {
          print('content가 List가 아님: ${json['content'].runtimeType}');
        }
      }
      
      // sort 필드는 실제로는 Map 형태로 오므로 빈 리스트로 처리
      List<Sort> sortList = [];
      
      return CommentPage(
        totalPages: json['totalPages'] ?? 0,
        totalElements: json['totalElements'] ?? 0,
        pageable: Pageable.fromJson(json['pageable'] ?? {}),
        size: json['size'] ?? 0,
        content: contentList,
        number: json['number'] ?? 0,
        sort: sortList, // 빈 리스트로 처리
        numberOfElements: json['numberOfElements'] ?? 0,
        first: json['first'] ?? true,
        last: json['last'] ?? true,
        empty: json['empty'] ?? true,
      );
    } catch (e) {
      print('CommentPage.fromJson 오류: $e');
      print('오류 발생 위치: ${StackTrace.current}');
      // 기본값으로 빈 CommentPage 반환
      return CommentPage(
        totalPages: 0,
        totalElements: 0,
        pageable: Pageable.fromJson({}),
        size: 0,
        content: [],
        number: 0,
        sort: [],
        numberOfElements: 0,
        first: true,
        last: true,
        empty: true,
      );
    }
  }
}

class Pageable {
  final int pageNumber;
  final int pageSize;
  final int offset;
  final List<Sort> sort;
  final bool paged;
  final bool unpaged;

  Pageable({
    required this.pageNumber,
    required this.pageSize,
    required this.offset,
    required this.sort,
    required this.paged,
    required this.unpaged,
  });

  factory Pageable.fromJson(Map<String, dynamic> json) {
    // sort 필드는 실제로는 Map 형태로 오므로 빈 리스트로 처리
    List<Sort> sortList = [];
    
    return Pageable(
      pageNumber: json['pageNumber'] ?? 0,
      pageSize: json['pageSize'] ?? 0,
      offset: json['offset'] ?? 0,
      sort: sortList, // 빈 리스트로 처리
      paged: json['paged'] ?? true,
      unpaged: json['unpaged'] ?? false,
    );
  }
}

class Sort {
  final String direction;
  final String nullHandling;
  final bool ascending;
  final String property;
  final bool ignoreCase;

  Sort({
    required this.direction,
    required this.nullHandling,
    required this.ascending,
    required this.property,
    required this.ignoreCase,
  });

  factory Sort.fromJson(Map<String, dynamic> json) => Sort(
        direction: json['direction'] ?? '',
        nullHandling: json['nullHandling'] ?? '',
        ascending: json['ascending'] ?? true,
        property: json['property'] ?? '',
        ignoreCase: json['ignoreCase'] ?? true,
      );
}

class Comment {
  final int commentId;
  final int userId;
  final int postId;
  final int parentCommentId;
  final String content;
  final String createdAt;
  final String updatedAt;
  final List<String> replies;

  Comment({
    required this.commentId,
    required this.userId,
    required this.postId,
    required this.parentCommentId,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    required this.replies,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    try {
      // replies 필드 안전하게 처리
      List<String> repliesList = [];
      if (json['replies'] != null) {
        if (json['replies'] is List) {
          repliesList = (json['replies'] as List)
              .map((e) => e.toString())
              .toList();
        } else {
          print('replies가 List가 아님: ${json['replies'].runtimeType}');
        }
      }
      
      return Comment(
        commentId: json['commentId'] ?? 0,
        userId: json['userId'] ?? 0,
        postId: json['postId'] ?? 0,
        parentCommentId: json['parentCommentId'] ?? 0,
        content: json['content'] ?? '',
        createdAt: json['createdAt'] ?? '',
        updatedAt: json['updatedAt'] ?? '',
        replies: repliesList,
      );
    } catch (e) {
      print('Comment.fromJson 오류: $e');
      print('오류 발생 JSON: $json');
      // 기본값으로 빈 Comment 반환
      return Comment(
        commentId: 0,
        userId: 0,
        postId: 0,
        parentCommentId: 0,
        content: '',
        createdAt: '',
        updatedAt: '',
        replies: [],
      );
    }
  }
} 