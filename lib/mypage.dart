import 'package:flutter/material.dart';
import 'bottom_nav_bar.dart';
import 'app_bar_widget.dart';
import 'mypage_bookmark.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'utils/auth_storage.dart';
import 'mypage_edit.dart';


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

//화면 디자인
class MyPageScreen extends StatefulWidget {
  const MyPageScreen({super.key});

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  String nickname = '닉네임';
  String dropdownValue = '클래식한 해설'; // 기본값

  @override
  void initState() {
    super.initState();
    _loadNickname();
    _loadUserDifficulty(); // 사용자 난이도 로드
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: const AppBarWidget(),
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
          child: const CircleAvatar(
            radius: 48,
            backgroundColor: Color(0xFFFEFDFC),
            backgroundImage: AssetImage('assets/images/profile.png'),
          ),
        ),
        SizedBox(height: screenHeight * 0.01),
        Text(nickname, style: TextStyle(fontSize: screenWidth * 0.051, fontWeight: FontWeight.w500)),
        SizedBox(height: screenHeight * 0.015),
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
                // TODO: 티켓 페이지 이동
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
      height: screenHeight * 0.12,
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
              // TODO: Navigate to written posts page
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
              // TODO: Navigate to written comments page
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('작성한 댓글', style: TextStyle(fontSize: screenWidth * 0.04)),
                Icon(Icons.chevron_right, color: Color(0xFF343231)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _notificationSwitches(double screenWidth, double screenHeight) {
    bool exhibitionAlarm = false;
    bool communityAlarm = false;
    return StatefulBuilder(
      builder: (context, setState) {
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
                  Text('전시회 추천 알림', style: TextStyle(fontSize: screenWidth * 0.04)),
                  Transform.scale(
                    scale: 0.95,
                    child: Switch(
                      value: exhibitionAlarm,
                      onChanged: (bool value) {
                        setState(() {
                          exhibitionAlarm = value;
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
                      value: communityAlarm,
                      onChanged: (bool value) {
                        setState(() {
                          communityAlarm = value;
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