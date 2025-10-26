import 'package:flutter/material.dart';
import '../bottom_nav_bar.dart';
import '../alarm_page.dart';
import '../login/login_UI.dart';
import 'mypage_bookmark.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/auth_storage.dart';
import 'mypage_edit.dart';
import '../ticket/ticket_screen.dart';
import 'package:flutter_svg/flutter_svg.dart'; 
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart'; 
import 'mypage_comments.dart';
import 'mypage_posts.dart';
import 'mypage_blocked_users.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final storage = FlutterSecureStorage();

class ProfileAvatarDisplay extends StatefulWidget {
  final double size; // width/height
  const ProfileAvatarDisplay({super.key, required this.size});

  @override
  State<ProfileAvatarDisplay> createState() => _ProfileAvatarDisplayState();
}

class _ProfileAvatarDisplayState extends State<ProfileAvatarDisplay> {
  String? _path;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _path = prefs.getString('profile_image_path');
    });
  }

  @override
  Widget build(BuildContext context) {
    final imageProvider = (_path != null && File(_path!).existsSync())
        ? FileImage(File(_path!)) as ImageProvider
        : const AssetImage('assets/images/profile.png');
    return CircleAvatar(
      radius: widget.size / 2,
      backgroundColor: const Color(0xFFFEFDFC),
      backgroundImage: imageProvider,
    );
  }
}

//회원 정보 수정
Future<void> updateUserInfo({
  required int userId,
  required String nickname,
  //required String email,
  //required String profileImage,
}) async {
  final url = Uri.parse('http://43.203.23.173:8080/user/update');
  final token = await getJwtToken();
  final response = await http.put(
    url,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode({
      'userId': userId,
      'nickname': nickname,
      //'email': email,
      //'profileImage': profileImage,
    }),
  );
  if (response.statusCode == 200) {
    print('회원 정보 수정 완료');
  } else {
    print('회원 정보 수정 실패: ${response.statusCode}');
  }
}

//난이도 설정
Future<void> updateDifficulty({
  required int userId,
  required String level, // "EASY", "NORMAL", "HARD"
}) async {
  final url = Uri.parse('http://43.203.23.173:8080/user/difficulty/$userId/$level');
  final token = await getJwtToken();
  final response = await http.put(
    url,
    headers: {
      'Authorization': 'Bearer $token',
    },
  );
  if (response.statusCode == 200) {
    print('난이도 수정 완료');
  } else {
    print('난이도 수정 실패: ${response.statusCode}');
  }
}

//알림 설정 API 호출 함수 (전시회 추천 알림)
Future<void> updateExhibitionAlarm(int userId, bool allowRAlarm) async {
  final url = Uri.parse('http://43.203.23.173:8080/user/alarm/recog/$userId');
  final token = await getJwtToken();
  final response = await http.put(
    url,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode({
      'userId': userId,
      'allowRAlarm': allowRAlarm,
    }),
  );
  if (response.statusCode == 200) {
    print('전시회 추천 알림 설정 완료');
  } else {
    print('전시회 추천 알림 설정 실패: ${response.statusCode}');
  }
}

//알림 설정 API 호출 함수 (커뮤니티 알림)
Future<void> updateCommunityAlarm(int userId, bool allowCAlarm) async {
  final url = Uri.parse('http://43.203.23.173:8080/user/alarm/community/$userId');
  final token = await getJwtToken();
  final response = await http.put(
    url,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode({
      'userId': userId,
      'allowCAlarm': allowCAlarm,
    }),
  );
  if (response.statusCode == 200) {
    print('커뮤니티 알림 설정 완료');
  } else {
    print('커뮤니티 알림 설정 실패: ${response.statusCode}');
  }
}

//화면 디자인
class MyPageScreen extends StatefulWidget {
  const MyPageScreen({super.key});

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  String nickname = '닉네임';
  String dropdownValue = '클래식한 해설'; // 기본값
  bool _exhibitionAlarm = false; // 전시회 추천 알림
  bool _communityAlarm = false;  // 커뮤니티 알림
  int _avatarVersion = 0; // 아바타 강제 리빌드용 버전 키

  @override
  void initState() {
    super.initState();
    _loadNickname();
    _loadUserDifficulty(); // 사용자 난이도 로드
    _loadAlarmStates();
  }

  Future<void> _loadNickname() async {
    final name = await storage.read(key: 'nickname');
    setState(() {
      nickname = name ?? '닉네임';
    });
  }

  // 사용자 난이도 로드
  Future<void> _loadUserDifficulty() async {
    final difficulty = await storage.read(key: 'user_difficulty');
    if (difficulty != null) {
      setState(() {
        switch (difficulty) {
          case 'EASY':
            dropdownValue = '한눈에 보는 해설';
            break;
          case 'NORMAL':
            dropdownValue = '클래식한 해설';
            break;
          case 'HARD':
            dropdownValue = '깊이 있는 해설';
            break;
          default:
            dropdownValue = '클래식한 해설';
        }
      });
    }
  }

  Future<void> _loadAlarmStates() async {
    final r = await storage.read(key: 'allow_r_alarm');
    final c = await storage.read(key: 'allow_c_alarm');
    setState(() {
      _exhibitionAlarm = (r == 'true');
      _communityAlarm = (c == 'true');
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
    );
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        title: Text(
          'musai',
          style: TextStyle(
            color: const Color(0xFF343231),
            fontSize: screenWidth * 0.08,
            fontWeight: FontWeight.bold,
            fontFamily: 'Pretendard',
            letterSpacing: 0,
          ),
        ),
        actions: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AlarmPage(initialIndex: 0)),
                  );
                },
                child: SvgPicture.asset(
                  'assets/icons/notification.svg',
                  width: 20,
                  height: 20,
                ),
              ),
              //const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: IconButton(
                  icon: const Icon(Icons.more_vert, size: 24, color: Color(0xFF343231)),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                  onPressed: () async {
                    final userId = await getUserId();
                    if (userId == null || !context.mounted) return;

                    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
                    final selected = await showMenu(
                      context: context,
                      position: RelativeRect.fromLTRB(
                        overlay.size.width - 20,
                        kToolbarHeight + 20,
                        20,
                        0,
                      ),
                      color: const Color(0xFFFEF6F2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      items: [
                        PopupMenuItem<String>(
                          value: 'withdraw',
                          child: Center(
                            child: Text(
                              '회원 탈퇴',
                              style: TextStyle(
                                color: Color(0xFF343231),
                                fontSize: MediaQuery.of(context).size.width * 0.04,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'logout',
                          child: Center(
                            child: Text(
                              '로그아웃',
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

                    if (selected == 'withdraw') {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => WithdrawConfirmDialog(userId: userId),
                      );
                    }
                    else if (selected == 'logout') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SignupPage()),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
            child: Column(
              children: [
                SizedBox(height: screenHeight * 0.03),
                _profileSection(screenWidth, screenHeight, nickname),
                SizedBox(height: screenHeight * 0.035),
                _bookmarkTicketSection(context, screenWidth, screenHeight),
                SizedBox(height: screenHeight * 0.03),
                _interpretationDropdown(screenWidth, screenHeight),
                SizedBox(height: screenHeight * 0.01),
                _writtenItemsSection(screenWidth, screenHeight),
                SizedBox(height: screenHeight * 0.01),
                _notificationSwitches(screenWidth, screenHeight),
                SizedBox(height: screenHeight * 0.015),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const BottomNavBarWidget(currentIndex: 3),
    );
  }

  Widget _profileSection(double screenWidth, double screenHeight, String nickname) {
    return Column(
      children: [
        Container(
          width: screenWidth * 0.25,
          height: screenWidth * 0.25,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Color(0x4DB1B1B1),
                blurRadius: 4,
                spreadRadius: 1,
                offset: Offset(0, 0),
              ),
            ],
          ),
          child: ProfileAvatarDisplay(
  key: ValueKey(_avatarVersion), // 버전 키로 강제 리빌드
  size: 96, // 기존 radius 48 * 2
),
        ),
        SizedBox(height: screenHeight * 0.01),
        Text(nickname, style: TextStyle(fontSize: screenWidth * 0.05, fontWeight: FontWeight.w500)),
        SizedBox(height: screenHeight * 0.012),
        Container(
          width: screenWidth * 0.27,
          height: screenHeight * 0.035,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Color(0x4DB1B1B1),
                blurRadius: 4,
                spreadRadius: 1,
                offset: Offset(0, 0),
              ),
            ],
          ),
          clipBehavior: Clip.hardEdge,
          child: Material(
            color: Color(0xFFFEF6F2),
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              onTap: () async {
                final updated = await showEditProfileDialog(context);
                if (updated == true) {
                  _loadNickname();
                  setState(() { _avatarVersion++; }); // 아바타 강제 리빌드
                }
              },
              child: Center(
                child: Text('내 정보 수정', style: TextStyle(fontSize: screenWidth * 0.04, color: Color(0xFF343231))),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _bookmarkTicketSection(BuildContext context, double screenWidth, double screenHeight) {
    return Container(
      height: screenHeight * 0.1,
      decoration: BoxDecoration(
        color: const Color(0xFF837670),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const BookmarkScreen()),
                );
              },
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.bookmark, color: Color(0xFFFEFDFC)),
                    SizedBox(height: screenHeight * 0.005),
                    Text('북마크', style: TextStyle(color: Color(0xFFFEFDFC), fontSize: screenWidth * 0.04)),
                  ],
                ),
              ),
            ),
          ),
          const VerticalDivider(color: Color(0xFFFEFDFC), width: 1),
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const TicketScreen(fromMyPage: true)),
      );
              },
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.confirmation_number, color: Color(0xFFFEFDFC)),
                    SizedBox(height: screenHeight * 0.005),
                    Text('티켓', style: TextStyle(color: Color(0xFFFEFDFC), fontSize: screenWidth * 0.04)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _interpretationDropdown(double screenWidth, double screenHeight) {
    return StatefulBuilder(
      builder: (context, setState) {
        return Container(
          height: screenHeight * 0.07,
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
          decoration: BoxDecoration(
            color: Color(0xFFFEF6F2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Text('해설 난이도', style: TextStyle(fontSize: screenWidth * 0.04)),
              const Spacer(),
              DropdownButton<String>(
                value: dropdownValue,
                underline: const SizedBox(),
                icon: const Icon(
                  Icons.keyboard_arrow_down,
                  color: Color(0xFF343231),
                ),
                dropdownColor: Color(0xFFFEF6F2),
                items: <String>['한눈에 보는 해설', '클래식한 해설', '깊이 있는 해설']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value, style: TextStyle(fontSize: screenWidth * 0.04)),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    dropdownValue = newValue!;
                    String level = '';
                    switch (dropdownValue) {
                      case '한눈에 보는 해설':
                        level = 'EASY';
                        break;
                      case '클래식한 해설':
                        level = 'NORMAL';
                        break;
                      case '깊이 있는 해설':
                        level = 'HARD';
                        break;
                    }
                    getUserId().then((userId) {
                      if (userId != null) {
                        updateDifficulty(userId: userId, level: level).then((_) {
                          // 로컬 저장소에도 저장
                          storage.write(key: 'user_difficulty', value: level);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('해설 난이도가 변경되었습니다.')),
                          );
                        });
                      }
                    });
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _writtenItemsSection(double screenWidth, double screenHeight) {
    return Container(
      height: screenHeight * 0.17,
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: screenHeight * 0.02),
      decoration: BoxDecoration(
        color: Color(0xFFFEF6F2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MyPostsPage()),
    );
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('작성한 글', style: TextStyle(fontSize: screenWidth * 0.04)),
                Icon(Icons.chevron_right, color: Color(0xFF343231)),
              ],
            ),
          ),
          SizedBox(height: screenHeight * 0.015),
          GestureDetector(
            onTap: () {
              Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MyCommentsPage()),
    );
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('작성한 댓글', style: TextStyle(fontSize: screenWidth * 0.04)),
                Icon(Icons.chevron_right, color: Color(0xFF343231)),
              ],
            ),
          ),
          SizedBox(height: screenHeight * 0.015),
          GestureDetector(
            onTap: () {
              Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BlockedUsersPage()),
    );
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('차단 사용자 관리', style: TextStyle(fontSize: screenWidth * 0.04)),
                Icon(Icons.chevron_right, color: Color(0xFF343231)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _notificationSwitches(double screenWidth, double screenHeight) {
    return StatefulBuilder(
      builder: (context, setSBState) {
        // setSBState는 내부 스위치 애니메이션만 빠르게 갱신용, 실제 상태는 setState와 함께 유지 보수
        return Container(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: screenHeight * 0.01),
          decoration: BoxDecoration(
            color: Color(0xFFFEF6F2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('작품 추천 알림', style: TextStyle(fontSize: screenWidth * 0.04)),
                  Transform.scale(
                    scale: 0.95,
                    child: Switch(
                      value: _exhibitionAlarm,
                      onChanged: (bool value) {
                        setState(() { _exhibitionAlarm = value; });
                        setSBState(() {});
                        getUserId().then((userId) {
                          if (userId != null) {
                            updateExhibitionAlarm(userId, !value);
                            storage.write(key: 'allow_r_alarm', value: value.toString());
                          }
                        });
                      },
                      activeTrackColor: Color(0xFFC06062),
                      inactiveTrackColor: Color(0xFFFFFDFC),
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('커뮤니티 알림', style: TextStyle(fontSize: screenWidth * 0.04)),
                  Transform.scale(
                    scale: 0.95,
                    child: Switch(
                      value: _communityAlarm,
                      onChanged: (bool value) {
                        setState(() { _communityAlarm = value; });
                        setSBState(() {});
                        getUserId().then((userId) {
                          if (userId != null) {
                            updateCommunityAlarm(userId, !value);
                            storage.write(key: 'allow_c_alarm', value: value.toString());
                          }
                        });
                      },
                      activeTrackColor: Color(0xFFC06062),
                      inactiveTrackColor: Color(0xFFF8F4F0),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
// 회원 탈퇴 확인 다이얼로그 및 API 함수
class WithdrawConfirmDialog extends StatelessWidget {
  final int userId;
  const WithdrawConfirmDialog({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        height: 230,
        padding: EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Color(0xFFFEFDFC),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset('assets/icons/warning_icon.svg', width: 52, height: 52),
            SizedBox(height: 8),
            Text(
              '정말 탈퇴하시겠습니까?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF343231),
              ),
            ),
            SizedBox(height: 4),
            Text(
              '탈퇴하면 이전 기록을 복구할 수 없습니다.',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF706B66),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: screenWidth * 0.33,
                  height: screenHeight * 0.05,
                  child: ElevatedButton(
                    onPressed: () async {
                      await _withdrawUser(userId, context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC06062),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text('네', style: TextStyle(color: Color(0xFFFEFDFC), fontSize: screenWidth * 0.04)),
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
                    child: Text('아니오', style: TextStyle(color: Color(0xFFFEFDFC), fontSize: screenWidth * 0.04)),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

Future<void> _withdrawUser(int userId, BuildContext context) async {
  try {
    print('🗑️ 회원 탈퇴 시작 - userId: $userId');
    
    final token = await getJwtToken();
    if (token == null) {
      print('❌ JWT 토큰이 없습니다');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('인증 토큰이 없습니다. 다시 로그인해주세요.')),
      );
      return;
    }
    
    print('🔑 JWT 토큰: ${token.substring(0, token.length > 50 ? 50 : token.length)}...');
    print('🔍 요청 URL: http://43.203.23.173:8080/user/delete/$userId');
    print('🔍 요청 헤더: Authorization: Bearer ${token.substring(0, 20)}...');
    
    final response = await http.delete(
      Uri.parse('http://43.203.23.173:8080/user/delete/$userId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );
    
    print('📡 회원 탈퇴 응답 상태: ${response.statusCode}');
    print('📡 회원 탈퇴 응답 바디: ${response.body}');

    if (response.statusCode == 200) {
      print('✅ 회원 탈퇴 성공 - 로컬 저장소 삭제 중...');
      
      // 로컬 저장소에서 모든 인증 정보 삭제
      await storage.deleteAll();
      print('✅ 로컬 저장소 삭제 완료');
      
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => SignupPage()),
          (route) => false,
        );
        print('✅ 로그인 화면으로 이동 완료');
      }
    } else {
      print('❌ 회원 탈퇴 실패: ${response.statusCode}');
      print('❌ 오류 메시지: ${response.body}');
      
      if (context.mounted) {
        String errorMessage = '회원 탈퇴 실패: ${response.statusCode}';
        if (response.statusCode == 403) {
          errorMessage = '권한이 없습니다. 서버 관리자에게 문의하세요.';
        } else if (response.statusCode == 404) {
          errorMessage = '사용자를 찾을 수 없습니다.';
        } else if (response.statusCode == 401) {
          errorMessage = '인증이 필요합니다. 다시 로그인해주세요.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    }
  } catch (e) {
    print('❌ 회원 탈퇴 중 오류 발생: $e');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('회원 탈퇴 중 오류가 발생했습니다: $e')),
      );
    }
  }
}
