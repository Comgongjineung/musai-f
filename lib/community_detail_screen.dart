import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'app_bar_widget.dart';
import 'utils/auth_storage.dart';
import 'community_write_screen.dart'; // CommunityWriteScreen 추가
import 'package:flutter_svg/flutter_svg.dart';

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
  
  // 사용자 정보 캐시 추가
  final Map<int, UserInfo> _userCache = {};

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
          // 캐시에 추가
          _userCache[postDetail!.userId] = userInfo!;
        });
      }
    } catch (e) {
      print('사용자 정보 로드 실패: $e');
    }
  }

  // 특정 사용자 정보를 가져오는 메서드 추가
  Future<UserInfo?> _loadUserInfoById(int userId) async {
    // 이미 캐시에 있으면 반환
    if (_userCache.containsKey(userId)) {
      return _userCache[userId];
    }

    if (token == null) {
      return null;
    }

    try {
      final response = await http.get(
        Uri.parse('http://43.203.23.173:8080/user/read/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final userInfo = UserInfo.fromJson(data);
        
        // 캐시에 저장
        _userCache[userId] = userInfo;
        
        if (mounted) {
          setState(() {});
        }
        
        return userInfo;
      }
    } catch (e) {
      print('사용자 정보 로드 실패 (userId: $userId): $e');
    }
    
    return null;
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
    await _submitCommentWithParentId(_commentController.text.trim(), null);
  }

  Future<void> _submitCommentWithParentId(String content, int? parentCommentId) async {
    if (token == null || content.isEmpty) {
      return;
    }

    try {
      final requestBody = {
        'userId': userId ?? 0,
        'postId': widget.postId,
        'parentCommentId': parentCommentId, // 답글인 경우 부모 댓글 ID, 일반 댓글인 경우 null
        'content': content,
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
        if (parentCommentId == null) {
          _commentController.clear();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(parentCommentId == null ? '댓글이 성공적으로 작성되었습니다.' : '답글이 성공적으로 작성되었습니다.')),
        );
        // 서버가 댓글을 처리할 시간을 주기 위해 잠시 대기
        await Future.delayed(const Duration(milliseconds: 500));
        // 댓글 목록 새로고침
        await _loadComments();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(parentCommentId == null ? '댓글 작성에 실패했습니다.' : '답글 작성에 실패했습니다.')),
        );
      }
    } catch (e) {
      print('댓글 작성 실패: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(parentCommentId == null ? '댓글 작성 중 오류가 발생했습니다.' : '답글 작성 중 오류가 발생했습니다.')),
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
        print('좋아요 취소 요청');
        final response = await http.delete(
          Uri.parse('http://43.203.23.173:8080/like/delete'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: json.encode(requestBody),
        );

        print('좋아요 취소 응답 상태: ${response.statusCode}');
        print('좋아요 취소 응답 바디: ${response.body}');

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
        } else {
          print('좋아요 취소 실패 - 상태 코드: ${response.statusCode}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('공감 취소에 실패했습니다. (${response.statusCode})')),
          );
        }
      } else {
        // 공감 등록
        print('좋아요 등록 요청');
        final response = await http.post(
          Uri.parse('http://43.203.23.173:8080/like/add'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: json.encode(requestBody),
        );

        print('좋아요 등록 응답 상태: ${response.statusCode}');
        print('좋아요 등록 응답 바디: ${response.body}');

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
        } else if (response.statusCode == 400 && response.body.contains('이미 좋아요가 등록된 게시물입니다')) {
          // 이미 좋아요가 등록되어 있는 경우
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('이미 좋아요를 누른 게시물입니다.')),
          );
        } else {
          print('좋아요 등록 실패 - 상태 코드: ${response.statusCode}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('공감 등록에 실패했습니다. (${response.statusCode})')),
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

  // 메뉴 액션 처리 메서드
  void _handleMenuAction(String action) {
    switch (action) {
      case 'edit':
        _showEditDialog();
        break;
      case 'delete':
        _showDeleteConfirmDialog();
        break;
      case 'report':
        _showReportDialog();
        break;
    }
  }

  // 댓글 메뉴 액션 처리 메서드
  void _handleCommentMenuAction(String action, Comment comment) {
    switch (action) {
      case 'reply_comment':
        _showReplyCommentDialog(comment);
        break;
      case 'edit_comment':
        _showEditCommentDialog(comment);
        break;
      case 'delete_comment':
        _showDeleteCommentConfirmDialog(comment);
        break;
    }
  }

  // 수정하기 다이얼로그
  void _showEditDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommunityWriteScreen(
          postId: widget.postId,
          initialTitle: postDetail?.title,
          initialContent: postDetail?.content,
        ),
      ),
    ).then((result) {
      // 수정이 완료되면 게시물 정보를 새로고침
      if (result == true) {
        _loadPostDetail();
        _loadComments();
      }
    });
  }

  // 수정하기 댓글 다이얼로그
  void _showEditCommentDialog(Comment comment) {
    final TextEditingController editController = TextEditingController(text: comment.content);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          height: 280,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: const Color(0xFFFEFDFC),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.edit,
                size: 52,
                color: Color(0xFFC06062),
              ),
              const SizedBox(height: 8),
              const Text(
                '댓글을 수정해보세요!',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF343231),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              // 댓글 수정 입력 필드
              Container(
                width: double.infinity,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF6F2),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: TextField(
                  controller: editController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: '댓글을 입력하세요...',
                    hintStyle: TextStyle(
                      fontSize: 14,
                      fontFamily: 'Pretendard',
                      color: Color(0xFFB1B1B1),
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(12),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: screenWidth * 0.33,
                    height: screenHeight * 0.05,
                    child: ElevatedButton(
                      onPressed: () {
                        if (editController.text.trim().isNotEmpty) {
                          Navigator.of(context).pop();
                          _updateComment(comment.commentId, editController.text.trim());
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC06062),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        '수정하기',
                        style: TextStyle(
                          color: const Color(0xFFFEFDFC),
                          fontSize: screenWidth * 0.04,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.015),
                  SizedBox(
                    width: screenWidth * 0.33,
                    height: screenHeight * 0.05,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB1B1B1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        '취소',
                        style: TextStyle(
                          color: const Color(0xFFFEFDFC),
                          fontSize: screenWidth * 0.04,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  // 댓글 수정 메서드
  Future<void> _updateComment(int commentId, String content) async {
    if (token == null) {
      print('❌ 토큰이 없어서 댓글을 수정할 수 없습니다.');
      return;
    }

    print('🔍 댓글 수정 시작...');
    print('🔍 수정할 댓글 ID: $commentId');
    print('🔍 수정할 내용: $content');
    print('🔍 토큰: ${token != null ? "있음" : "없음"}');
    print('🔍 사용자 ID: $userId');

    try {
      final requestBody = {
        'content': content,
      };

      final response = await http.put(
        Uri.parse('http://43.203.23.173:8080/comment/update/$commentId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'accept': '*/*',
        },
        body: json.encode(requestBody),
      );

      print('📊 댓글 수정 응답 상태 코드: ${response.statusCode}');
      print('📊 댓글 수정 응답 바디: ${response.body}');
      print('📊 댓글 수정 응답 헤더: ${response.headers}');

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('댓글이 수정되었습니다.')),
        );
        _loadComments(); // 댓글 목록 새로고침
      } else if (response.statusCode == 403) {
        print('❌ 403 Forbidden - 권한이 없습니다.');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('댓글을 수정할 권한이 없습니다.')),
        );
      } else if (response.statusCode == 404) {
        print('❌ 404 Not Found - 댓글을 찾을 수 없습니다.');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('댓글을 찾을 수 없습니다.')),
        );
      } else {
        print('❌ 댓글 수정 실패 - 상태 코드: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('댓글 수정에 실패했습니다. (${response.statusCode})')),
        );
      }
    } catch (e) {
      print('❌ 댓글 수정 실패: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('댓글 수정 중 오류가 발생했습니다.')),
      );
    }
  }

  // 답글 다이얼로그
  void _showReplyCommentDialog(Comment comment) {
    final TextEditingController replyController = TextEditingController();
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          height: 280,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: const Color(0xFFFEFDFC),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.reply,
                size: 52,
                color: Color(0xFFC06062),
              ),
              const SizedBox(height: 8),
              const Text(
                '댓글에 답글을 달아보세요!',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF343231),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              // 답글 입력 필드
              Container(
                width: double.infinity,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF6F2),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: TextField(
                  controller: replyController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: '답글을 입력하세요...',
                    hintStyle: TextStyle(
                      fontSize: 14,
                      fontFamily: 'Pretendard',
                      color: Color(0xFFB1B1B1),
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(12),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: screenWidth * 0.33,
                    height: screenHeight * 0.05,
                    child: ElevatedButton(
                      onPressed: () {
                        if (replyController.text.trim().isNotEmpty) {
                          Navigator.of(context).pop();
                          _submitCommentWithParentId(replyController.text.trim(), comment.commentId);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC06062),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        '답글 작성',
                        style: TextStyle(
                          color: const Color(0xFFFEFDFC),
                          fontSize: screenWidth * 0.04,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.015),
                  SizedBox(
                    width: screenWidth * 0.33,
                    height: screenHeight * 0.05,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB1B1B1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        '취소',
                        style: TextStyle(
                          color: const Color(0xFFFEFDFC),
                          fontSize: screenWidth * 0.04,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  // 삭제 확인 다이얼로그
  void _showDeleteConfirmDialog() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          height: 230,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: const Color(0xFFFEFDFC),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset('assets/icons/warning_icon.svg', width: 52, height: 52),
              const SizedBox(height: 8),
              const Text(
                '정말로 이 게시물을 삭제하시겠습니까?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF343231),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              const Text(
                '삭제하면 복구할 수 없습니다.',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF706B66),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: screenWidth * 0.33,
                    height: screenHeight * 0.05,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _deletePost();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC06062),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        '삭제',
                        style: TextStyle(
                          color: const Color(0xFFFEFDFC),
                          fontSize: screenWidth * 0.04,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.015),
                  SizedBox(
                    width: screenWidth * 0.33,
                    height: screenHeight * 0.05,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB1B1B1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        '취소',
                        style: TextStyle(
                          color: const Color(0xFFFEFDFC),
                          fontSize: screenWidth * 0.04,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  // 삭제 확인 댓글 다이얼로그
  void _showDeleteCommentConfirmDialog(Comment comment) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          height: 230,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: const Color(0xFFFEFDFC),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset('assets/icons/warning_icon.svg', width: 52, height: 52),
              const SizedBox(height: 8),
              const Text(
                '정말로 이 댓글을 삭제하시겠습니까?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF343231),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              const Text(
                '삭제하면 복구할 수 없습니다.',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF706B66),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: screenWidth * 0.33,
                    height: screenHeight * 0.05,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _deleteComment(comment.commentId);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC06062),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        '삭제',
                        style: TextStyle(
                          color: const Color(0xFFFEFDFC),
                          fontSize: screenWidth * 0.04,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.015),
                  SizedBox(
                    width: screenWidth * 0.33,
                    height: screenHeight * 0.05,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB1B1B1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        '취소',
                        style: TextStyle(
                          color: const Color(0xFFFEFDFC),
                          fontSize: screenWidth * 0.04,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  // 신고하기 다이얼로그
  void _showReportDialog() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          height: 230,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: const Color(0xFFFEFDFC),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset('assets/icons/warning_icon.svg', width: 52, height: 52),
              const SizedBox(height: 8),
              const Text(
                '게시물을 신고하시겠습니까?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF343231),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              const Text(
                '신고 기능은 아직 개발 중입니다.',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF706B66),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: screenWidth * 0.33,
                    height: screenHeight * 0.05,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC06062),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        '확인',
                        style: TextStyle(
                          color: const Color(0xFFFEFDFC),
                          fontSize: screenWidth * 0.04,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.015),
                  SizedBox(
                    width: screenWidth * 0.33,
                    height: screenHeight * 0.05,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB1B1B1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        '취소',
                        style: TextStyle(
                          color: const Color(0xFFFEFDFC),
                          fontSize: screenWidth * 0.04,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  // 신고하기 댓글 다이얼로그
  void _showReportCommentDialog(Comment comment) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          height: 230,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: const Color(0xFFFEFDFC),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset('assets/icons/warning_icon.svg', width: 52, height: 52),
              const SizedBox(height: 8),
              const Text(
                '댓글을 신고하시겠습니까?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF343231),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              const Text(
                '신고 기능은 아직 개발 중입니다.',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF706B66),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: screenWidth * 0.33,
                    height: screenHeight * 0.05,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC06062),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        '확인',
                        style: TextStyle(
                          color: const Color(0xFFFEFDFC),
                          fontSize: screenWidth * 0.04,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.015),
                  SizedBox(
                    width: screenWidth * 0.33,
                    height: screenHeight * 0.05,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB1B1B1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        '취소',
                        style: TextStyle(
                          color: const Color(0xFFFEFDFC),
                          fontSize: screenWidth * 0.04,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  // 게시물 삭제 메서드
  Future<void> _deletePost() async {
    if (token == null) {
      print('❌ 토큰이 없어서 삭제할 수 없습니다.');
      return;
    }

    print('🔍 게시물 삭제 시작...');
    print('🔍 삭제할 게시물 ID: ${widget.postId}');
    print('🔍 토큰: ${token != null ? "있음" : "없음"}');
    print('🔍 사용자 ID: $userId');
    print('🔍 게시물 작성자 ID: ${postDetail?.userId}');
    print('🔍 현재 사용자와 게시물 작성자가 같은가?: ${postDetail?.userId == userId}');

    // 게시물 작성자가 아닌 경우 삭제 불가
    if (postDetail?.userId != userId) {
      print('❌ 게시물 작성자가 아니므로 삭제할 수 없습니다.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('자신이 작성한 게시물만 삭제할 수 있습니다.')),
      );
      return;
    }

    try {
      final requestBody = {
        'postId': widget.postId,
        'userId': userId,
      };

      final response = await http.delete(
        Uri.parse('http://43.203.23.173:8080/post/delete/${widget.postId}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'accept': '*/*',
        },
        body: json.encode(requestBody),
      );

      print('📊 삭제 응답 상태 코드: ${response.statusCode}');
      print('📊 삭제 응답 바디: ${response.body}');
      print('📊 삭제 응답 헤더: ${response.headers}');

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('게시물이 삭제되었습니다.')),
        );
        Navigator.of(context).pop(); // 상세 페이지에서 나가기
      } else if (response.statusCode == 403) {
        print('❌ 403 Forbidden - 권한이 없습니다.');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('게시물을 삭제할 권한이 없습니다.')),
        );
      } else if (response.statusCode == 404) {
        print('❌ 404 Not Found - 게시물을 찾을 수 없습니다.');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('게시물을 찾을 수 없습니다.')),
        );
      } else {
        print('❌ 삭제 실패 - 상태 코드: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('게시물 삭제에 실패했습니다. (${response.statusCode})')),
        );
      }
    } catch (e) {
      print('❌ 게시물 삭제 실패: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('게시물 삭제 중 오류가 발생했습니다.')),
      );
    }
  }

  // 댓글 삭제 메서드
  Future<void> _deleteComment(int commentId) async {
    if (token == null) {
      print('❌ 토큰이 없어서 댓글을 삭제할 수 없습니다.');
      return;
    }

    print('🔍 댓글 삭제 시작...');
    print('🔍 삭제할 댓글 ID: $commentId');
    print('🔍 토큰: ${token != null ? "있음" : "없음"}');
    print('🔍 사용자 ID: $userId');

    try {
      final response = await http.delete(
        Uri.parse('http://43.203.23.173:8080/comment/delete/$commentId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'accept': '*/*',
        },
      );

      print('📊 댓글 삭제 응답 상태 코드: ${response.statusCode}');
      print('📊 댓글 삭제 응답 바디: ${response.body}');
      print('📊 댓글 삭제 응답 헤더: ${response.headers}');

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('댓글이 삭제되었습니다.')),
        );
        _loadComments(); // 댓글 목록 새로고침
      } else if (response.statusCode == 403) {
        print('❌ 403 Forbidden - 권한이 없습니다.');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('댓글을 삭제할 권한이 없습니다.')),
        );
      } else if (response.statusCode == 404) {
        print('❌ 404 Not Found - 댓글을 찾을 수 없습니다.');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('댓글을 찾을 수 없습니다.')),
        );
      } else {
        print('❌ 댓글 삭제 실패 - 상태 코드: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('댓글 삭제에 실패했습니다. (${response.statusCode})')),
        );
      }
    } catch (e) {
      print('❌ 댓글 삭제 실패: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('댓글 삭제 중 오류가 발생했습니다.')),
      );
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
        leading: Padding(
          padding: EdgeInsets.only(left: screenWidth * 0.06),
          child: IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF343231)),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: screenWidth * 0.04),
            child: IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Icon(Icons.more_vert, color: Color(0xFF343231)),
              onPressed: () async {
                final currentUserId = await getUserId();
                if (currentUserId == null || !context.mounted) return;

                // 화면 크기 가져오기
                final screenSize = MediaQuery.of(context).size;
                
                // 메뉴 크기 (대략적인 값)
                const double menuWidth = 120.0;
                const double menuHeight = 150.0;
                
                // 메뉴 위치 계산 (오른쪽 상단에 표시)
                double left = screenSize.width - menuWidth - 20; // 오른쪽에서 20px 여백
                double top = kToolbarHeight + 20; // AppBar 아래에서 20px
                
                // 화면 경계 체크 및 조정
                if (left < 0) {
                  left = 20; // 왼쪽 여백 확보
                }
                
                if (top + menuHeight > screenSize.height) {
                  top = screenSize.height - menuHeight - 20; // 아래쪽 여백 확보
                }
                
                final selected = await showMenu(
                  context: context,
                  position: RelativeRect.fromLTRB(
                    left,
                    top,
                    screenSize.width - left - menuWidth,
                    screenSize.height - top - menuHeight,
                  ),
                  color: const Color(0xFFFEF6F2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  items: postDetail?.userId == currentUserId
                      ? [
                          // 내가 쓴 글인 경우
                          PopupMenuItem<String>(
                            value: 'edit',
                            child: Center(
                              child: Text(
                                '수정하기',
                                style: TextStyle(
                                  color: Color(0xFF343231),
                                  fontSize: MediaQuery.of(context).size.width * 0.04,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'delete',
                            child: Center(
                              child: Text(
                                '삭제하기',
                                style: TextStyle(
                                  color: Color(0xFF343231),
                                  fontSize: MediaQuery.of(context).size.width * 0.04,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ]
                      : [
                          // 다른 사람이 쓴 글인 경우
                          PopupMenuItem<String>(
                            value: 'report',
                            child: Center(
                              child: Text(
                                '신고하기',
                                style: TextStyle(
                                  color: Color(0xFF343231),
                                  fontSize: MediaQuery.of(context).size.width * 0.04,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                );

                if (selected != null) {
                  _handleMenuAction(selected);
                }
              },
            ),
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
                          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 사용자 정보
                              _buildUserInfo(screenWidth, screenHeight),
                              SizedBox(height: screenHeight * 0.03),
                              
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
        SizedBox(height: screenHeight * 0.012),
        
        // 내용
        Text(
          postDetail!.content,
          style: TextStyle(
            fontSize: screenWidth * 0.04,
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
            border: Border.all(color: const Color(0xFF837670), width: 1),
            borderRadius: BorderRadius.circular(20),
            color: const Color(0xFFFFFDFC),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.chat_bubble_outline, size: 16, color: Color(0xFF837670)),
              const SizedBox(width: 4),
              Text('댓글 ${commentPage != null ? _calculateTotalComments(commentPage!.content) : 0}', style: const TextStyle(fontSize: 16, fontFamily: 'Pretendard', color: Color(0xFF837670))),
            ],
          ),
        ),
        
        // 공감 버튼
        GestureDetector(
          onTap: _toggleLike,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF837670), width: 1),
              borderRadius: BorderRadius.circular(20),
              color: const Color(0xFFFFFDFC),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isLiked ? Icons.favorite : Icons.favorite_border,
                  size: 16,
                  color: isLiked ? Color(0xFFC46567) : const Color(0xFF837670),
                ),
                const SizedBox(width: 4),
                Text(
                  '공감 ${postDetail!.likeCount}',
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Pretendard',
                    color: isLiked ? Color(0xFFC46567) : const Color(0xFF837670),
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
                fontSize: 16,
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
          child: _buildCommentItem(comment, screenWidth, screenHeight, 0), // 들여쓰기 레벨 0 추가
        )),
      ],
    );
  }

  Widget _buildCommentItem(Comment comment, double screenWidth, double screenHeight, int indentLevel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: EdgeInsets.only(left: indentLevel * 20.0), // 들여쓰기
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
                    child: FutureBuilder<UserInfo?>(
                      future: _loadUserInfoById(comment.userId),
                      builder: (context, snapshot) {
                        String displayName = '사용자 ${comment.userId}';
                        
                        if (snapshot.hasData && snapshot.data != null) {
                          displayName = snapshot.data!.nickname;
                        } else if (snapshot.hasError) {
                          displayName = '사용자 ${comment.userId}';
                        }
                        
                        return Text(
                          displayName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Pretendard',
                            color: Color(0xFF343231),
                          ),
                        );
                      },
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
                      // 삭제되지 않은 댓글에만 더보기 버튼 표시
                      if (!comment.isDeleted) ...[
                        const SizedBox(width: 8),
                        // 더보기 버튼
                        Builder(
                          builder: (context) => GestureDetector(
                            onTap: () async {
                              final currentUserId = await getUserId();
                              if (currentUserId == null || !context.mounted) return;

                              // 더보기 버튼의 정확한 위치를 찾기
                              final RenderBox button = context.findRenderObject() as RenderBox;
                              final buttonPosition = button.localToGlobal(Offset.zero);
                              
                              // 화면 크기 가져오기
                              final screenSize = MediaQuery.of(context).size;
                              
                              // 메뉴 크기 (대략적인 값)
                              const double menuWidth = 120.0;
                              const double menuHeight = 150.0;
                              
                              // 메뉴 위치 계산 (버튼 바로 왼쪽 위에 표시)
                              double left = buttonPosition.dx - menuWidth - 5; // 버튼 왼쪽에 표시
                              double top = buttonPosition.dy - menuHeight + 125; // 버튼 아래?
                              
                              // 화면 경계 체크 및 조정
                              if (left < 0) {
                                left = buttonPosition.dx + 5; // 버튼 오른쪽에 표시
                              }
                              
                              if (top < 0) {
                                top = buttonPosition.dy + button.size.height + 5; // 버튼 아래로 표시
                              }
                              
                              final selected = await showMenu(
                                context: context,
                                position: RelativeRect.fromLTRB(
                                  left,
                                  top,
                                  screenSize.width - left - menuWidth,
                                  screenSize.height - top - menuHeight,
                                ),
                                color: const Color(0xFFFEF6F2),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                items: comment.userId == currentUserId
                                  ? [
                                      // 내가 쓴 댓글인 경우
                                      PopupMenuItem<String>(
                                        value: 'reply_comment',
                                        child: Center(
                                          child: Text(
                                            '답글달기',
                                            style: TextStyle(
                                              color: Color(0xFF343231),
                                              fontSize: MediaQuery.of(context).size.width * 0.04,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ),
                                      PopupMenuItem<String>(
                                        value: 'edit_comment',
                                        child: Center(
                                          child: Text(
                                            '수정하기',
                                            style: TextStyle(
                                              color: Color(0xFF343231),
                                              fontSize: MediaQuery.of(context).size.width * 0.04,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ),
                                      PopupMenuItem<String>(
                                        value: 'delete_comment',
                                        child: Center(
                                          child: Text(
                                            '삭제하기',
                                            style: TextStyle(
                                              color: Color(0xFF343231),
                                              fontSize: MediaQuery.of(context).size.width * 0.04,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ]
                                  : [
                                      // 다른 사람이 쓴 댓글인 경우
                                      PopupMenuItem<String>(
                                        value: 'reply_comment',
                                        child: Center(
                                          child: Text(
                                            '답글달기',
                                            style: TextStyle(
                                              color: Color(0xFF343231),
                                              fontSize: MediaQuery.of(context).size.width * 0.04,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                            );

                            if (selected != null) {
                              _handleCommentMenuAction(selected, comment);
                            }
                          },
                          child: const Icon(
                            Icons.more_vert,
                            size: 16,
                            color: Color(0xFFB1B1B1),
                          ),
                        ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              
              // 댓글 내용
              Text(
                comment.isDeleted ? '삭제된 댓글입니다.' : comment.content,
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: 'Pretendard',
                  color: comment.isDeleted ? const Color(0xFFB1B1B1) : const Color(0xFF343231),
                  fontStyle: comment.isDeleted ? FontStyle.italic : FontStyle.normal,
                ),
              ),
            ],
          ),
        ),
        
        // 답글들 재귀적으로 표시
        if (comment.replies.isNotEmpty)
          ...comment.replies.map((reply) => Padding(
            padding: const EdgeInsets.only(top: 8),
            child: _buildCommentItem(reply, screenWidth, screenHeight, indentLevel + 1),
          )),
      ],
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
  final List<Comment> replies; // List<String>에서 List<Comment>로 변경
  final bool isDeleted; // 삭제 상태 추가

  Comment({
    required this.commentId,
    required this.userId,
    required this.postId,
    required this.parentCommentId,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    required this.replies,
    this.isDeleted = false, // 기본값은 false
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    try {
      // replies 필드를 List<Comment>로 파싱
      List<Comment> repliesList = [];
      if (json['replies'] != null) {
        if (json['replies'] is List) {
          repliesList = (json['replies'] as List)
              .map((e) => Comment.fromJson(e))
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
        isDeleted: json['isDeleted'] ?? false, // 삭제 상태 파싱
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
        isDeleted: false,
      );
    }
  }
}

// 총 댓글 수를 재귀적으로 계산하는 함수 추가
int _calculateTotalComments(List<Comment> comments) {
  int total = 0;
  for (Comment comment in comments) {
    total += 1; // 현재 댓글
    total += _calculateTotalComments(comment.replies); // 답글들
  }
  return total;
} 