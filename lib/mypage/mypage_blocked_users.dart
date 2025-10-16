import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/auth_storage.dart';
import 'package:flutter_svg/flutter_svg.dart';

class BlockedUsersPage extends StatefulWidget {
  const BlockedUsersPage({super.key});

  @override
  State<BlockedUsersPage> createState() => _BlockedUsersPageState();
}

class _BlockedUsersPageState extends State<BlockedUsersPage> {
  List<BlockedUser> blockedUsers = [];
  bool isLoading = true;
  String? token;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    token = await getJwtToken();
    await _loadBlockedUsers();
  }

  Future<void> _loadBlockedUsers() async {
    if (token == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('http://43.203.23.173:8080/api/v1/community/blocks/list'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'accept': '*/*',
        },
      );

      print('차단 사용자 목록 응답 상태: ${response.statusCode}');
      print('차단 사용자 목록 응답 바디: ${response.body}');

      if (response.statusCode == 200) {
        final body = utf8.decode(response.bodyBytes);
        final decoded = jsonDecode(body);

        if (decoded is! List) {
          throw FormatException('Expected a JSON array, got: $decoded');
        }

        // 정수 배열을 안전하게 파싱
        final blockedUserIds = decoded.map<int>((e) {
          if (e is int) return e;
          return int.parse(e.toString());
        }).toList();

        print('차단된 사용자 ID 목록: $blockedUserIds');

        // 각 userId에 대해 사용자 정보 조회
        final List<BlockedUser> users = [];
        for (int userId in blockedUserIds) {
          final userInfo = await _fetchUserInfo(userId);
          if (userInfo != null) {
            users.add(userInfo);
          }
        }

        setState(() {
          blockedUsers = users;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('차단 사용자 목록 로드 실패: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  // 개별 사용자 정보 조회
  Future<BlockedUser?> _fetchUserInfo(int userId) async {
    if (token == null) return null;

    try {
      final response = await http.get(
        Uri.parse('http://43.203.23.173:8080/user/read/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('사용자 정보 조회 (userId: $userId) 상태: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return BlockedUser(
          blockId: 0, // API에서 제공하지 않으므로 0으로 설정
          blockedUserId: userId,
          nickname: data['nickname'] ?? '알 수 없음',
          profileImage: data['profileImage'],
          blockedAt: DateTime.now().toIso8601String(), // API에서 제공하지 않으므로 현재 시간
        );
      }
    } catch (e) {
      print('사용자 정보 조회 실패 (userId: $userId): $e');
    }
    return null;
  }

  void _showUnblockConfirmDialog(BlockedUser user) {
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
              Text(
                '${user.nickname}님의',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF343231),
                ),
                textAlign: TextAlign.center,
              ),
              const Text(
                '차단을 해제하시겠습니까?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF343231),
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
                        _unblockUser(user.blockedUserId);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC06062),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        '해제',
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

  Future<void> _unblockUser(int blockedUserId) async {
    if (token == null) {
      print('❌ 토큰이 없어서 차단 해제할 수 없습니다.');
      return;
    }

    print('🔍 사용자 차단 해제 시작...');
    print('🔍 차단 해제할 사용자 ID: $blockedUserId');

    try {
      final response = await http.delete(
        Uri.parse('http://43.203.23.173:8080/api/v1/community/blocks/delete/$blockedUserId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'accept': '*/*',
        },
      );

      print('📊 사용자 차단 해제 응답 상태 코드: ${response.statusCode}');
      print('📊 사용자 차단 해제 응답 바디: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('차단이 해제되었습니다.')),
        );
        // 목록 새로고침
        await _loadBlockedUsers();
      } else {
        print('❌ 사용자 차단 해제 실패 - 상태 코드: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('차단 해제에 실패했습니다. (${response.statusCode})')),
        );
      }
    } catch (e) {
      print('❌ 사용자 차단 해제 실패: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('차단 해제 중 오류가 발생했습니다.')),
      );
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return '날짜 정보 없음';
    }
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
        scrolledUnderElevation: 2,
        surfaceTintColor: const Color(0xFFFAFAFA),
        leading: Padding(
          padding: EdgeInsets.only(left: screenWidth * 0.06),
          child: IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF343231)),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: const Text(
          '차단 사용자 관리',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            fontFamily: 'Pretendard',
            color: Color(0xFF343231),
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFA28F7D)))
            : blockedUsers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.block, size: screenWidth * 0.15, color: const Color(0xFFB1B1B1)),
                        SizedBox(height: screenHeight * 0.02),
                        const Text(
                          '차단한 사용자가 없습니다.',
                          style: TextStyle(
                            fontSize: 16,
                            fontFamily: 'Pretendard',
                            color: Color(0xFFB1B1B1),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.06,
                      vertical: screenHeight * 0.02,
                    ),
                    itemCount: blockedUsers.length,
                    itemBuilder: (context, index) {
                      final user = blockedUsers[index];
                      return Padding(
                        padding: EdgeInsets.only(bottom: screenHeight * 0.015),
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
                          child: Row(
                            children: [
                              // 프로필 이미지
                              Container(
                                width: screenWidth * 0.12,
                                height: screenWidth * 0.12,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF4F0ED),
                                  borderRadius: BorderRadius.circular(screenWidth * 0.06),
                                ),
                                child: user.profileImage != null && user.profileImage!.isNotEmpty
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(screenWidth * 0.06),
                                        child: Image.network(
                                          user.profileImage!,
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
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      user.nickname,
                                      style: TextStyle(
                                        fontSize: screenWidth * 0.04,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: 'Pretendard',
                                        color: const Color(0xFF343231),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              // 차단 해제 버튼
                              ElevatedButton(
                                onPressed: () => _showUnblockConfirmDialog(user),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF837670),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: screenWidth * 0.04,
                                    vertical: screenHeight * 0.01,
                                  ),
                                  minimumSize: Size.zero,
                                ),
                                child: Text(
                                  '해제',
                                  style: TextStyle(
                                    color: const Color(0xFFFEFDFC),
                                    fontSize: screenWidth * 0.035,
                                    fontFamily: 'Pretendard',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}

class BlockedUser {
  final int blockId;
  final int blockedUserId;
  final String nickname;
  final String? profileImage;
  final String blockedAt;

  BlockedUser({
    required this.blockId,
    required this.blockedUserId,
    required this.nickname,
    this.profileImage,
    required this.blockedAt,
  });

  factory BlockedUser.fromJson(Map<String, dynamic> json) {
    return BlockedUser(
      blockId: json['blockId'] ?? 0,
      blockedUserId: json['blockedUserId'] ?? 0,
      nickname: json['nickname'] ?? '알 수 없음',
      profileImage: json['profileImage'],
      blockedAt: json['blockedAt'] ?? '',
    );
  }
}

