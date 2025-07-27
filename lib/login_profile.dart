import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'home_screen.dart';
import 'utils/auth_storage.dart';

class LoginProfileScreen extends StatelessWidget {
  final int userId;
  const LoginProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: screenHeight * 0.035),
                  _stepIndicator(),
                  SizedBox(height: screenHeight * 0.04),
                  _titleSection(screenWidth),
                  SizedBox(height: screenHeight * 0.075),
                  Center(child: ProfileAvatar(screenWidth: screenWidth, screenHeight: screenHeight)),
                  SizedBox(height: screenHeight * 0.05),
                  _nicknameSection(screenWidth, screenHeight),
                  const Spacer(),
                  _saveButtonSection(context, screenWidth, screenHeight),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _stepIndicator() {
    return const Align(
      alignment: Alignment.centerLeft,
      child: StepIndicator(),
    );
  }

  Widget _titleSection(double screenWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '프로필 설정',
          style: TextStyle(
            fontSize: screenWidth * 0.06,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF343231),
          ),
        ),
        SizedBox(height: screenWidth * 0.02),
        Text(
          'musai를 자유롭게 사용해보세요.',
          style: TextStyle(
            fontSize: screenWidth * 0.04,
            color: const Color(0xFF706B66),
          ),
        ),
      ],
    );
  }

  Widget _nicknameSection(double screenWidth, double screenHeight) {
    return NicknameInput(screenWidth: screenWidth, screenHeight: screenHeight);
  }

  Widget _saveButtonSection(BuildContext context, double screenWidth, double screenHeight) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () async {
            final success = await SaveButton(userId: userId).saveNickname();
            if (success) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('닉네임 저장 실패')),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF837670),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            minimumSize: Size.fromHeight(screenHeight * 0.07),
          ),
          child: Text(
            '다음으로',
            style: TextStyle(
              color: const Color(0xFFFEFDFC),
              fontSize: screenWidth * 0.05,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        SizedBox(height: screenHeight * 0.035),
      ],
    );
  }
}


class StepIndicator extends StatelessWidget {
  const StepIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Container(
          width: screenWidth * 0.06,
          height: screenWidth * 0.06,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFFC06062),
          ),
          alignment: Alignment.center,
          child: Text(
            '1',
            style: TextStyle(
              color: Colors.white,
              fontSize: screenWidth * 0.03,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        SizedBox(width: screenWidth * 0.0125),
        const Icon(Icons.circle, size: 4, color: Color(0xFFB1B1B1)),
        SizedBox(width: screenWidth * 0.005),
        const Icon(Icons.circle, size: 4, color: Color(0xFFB1B1B1)),
        SizedBox(width: screenWidth * 0.005),
        const Icon(Icons.circle, size: 4, color: Color(0xFFB1B1B1)),
        SizedBox(width: screenWidth * 0.0125),
        Container(
          width: screenWidth * 0.06,
          height: screenWidth * 0.06,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFC06062)),
          ),
          alignment: Alignment.center,
          child: Text(
            '2',
            style: TextStyle(
              color: const Color(0xFFC06062),
              fontSize: screenWidth * 0.03,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}

class ProfileAvatar extends StatelessWidget {
  final double screenWidth;
  final double screenHeight;
  const ProfileAvatar({super.key, required this.screenWidth, required this.screenHeight});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFFEFDFC),
            boxShadow: [
              BoxShadow(
                color: const Color(0x4DB1B1B1), // #B1B1B1 @ 30%
                blurRadius: screenWidth * 0.02,
                spreadRadius: screenWidth * 0.005,
                offset: const Offset(0, 0),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: screenWidth * 0.135,
            backgroundColor: const Color(0xFFFEFDFC),
            backgroundImage: const AssetImage('assets/images/profile.png'),
          ),
        ),
        GestureDetector(
          onTap: () {
            // To be implemented: open gallery and replace image
          },
          child: Container(
            width: screenWidth * 0.08,
            height: screenWidth * 0.08,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: const Color(0x4DB1B1B1), // #665E5E @ 30% opacity
                  blurRadius: screenWidth * 0.02,
                  spreadRadius: screenWidth * 0.005,
                  offset: const Offset(0, 0),
                ),
              ],
            ),
            child: Image.asset(
              'assets/images/edit.png',
              fit: BoxFit.contain,
            ),
          ),
        )
      ],
    );
  }
}

class NicknameInput extends StatefulWidget {
  final double screenWidth;
  final double screenHeight;
  const NicknameInput({super.key, required this.screenWidth, required this.screenHeight});
  static final TextEditingController controller = TextEditingController();

  @override
  State<NicknameInput> createState() => _NicknameInputState();
}

class _NicknameInputState extends State<NicknameInput> {
  String? _nicknameStatusMessage;
  Color _nicknameStatusColor = Colors.transparent;

  @override
  Widget build(BuildContext context) {
    final screenWidth = widget.screenWidth;
    final screenHeight = widget.screenHeight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  '닉네임',
                  style: TextStyle(
                    fontSize: screenWidth * 0.04,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF343231),
                  ),
                ),
                SizedBox(width: screenWidth * 0.02),
                Image.asset(
                  'assets/images/check_circle.png',
                  width: screenWidth * 0.04,
                  height: screenWidth * 0.04,
                ),
              ],
            ),
            if (_nicknameStatusMessage != null)
              Text(
                _nicknameStatusMessage!,
                style: TextStyle(
                  fontSize: screenWidth * 0.04,
                  fontWeight: FontWeight.w400,
                  color: _nicknameStatusColor,
                ),
              ),
          ],
        ),
        SizedBox(height: screenHeight * 0.01),
        Container(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.03, vertical: screenHeight * 0.01),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF6F2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: NicknameInput.controller,
                  decoration: InputDecoration(
                    hintText: 'n자 이내로 입력하세요.',
                    border: InputBorder.none,
                    hintStyle: TextStyle(
                      fontSize: screenWidth * 0.04,
                      color: const Color(0xFFB1B1B1),
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () async {
                  final nickname = NicknameInput.controller.text.trim();
                  final userId = await getUserId();

                  if (nickname.isEmpty || userId == null) return;

                  final isDuplicate = await isNicknameDuplicate(userId, nickname);

                  setState(() {
                    if (isDuplicate) {
                      _nicknameStatusMessage = '사용 중인 닉네임입니다.';
                      _nicknameStatusColor = const Color(0xFFC06062);
                    } else {
                      _nicknameStatusMessage = '사용 가능한 닉네임입니다.';
                      _nicknameStatusColor = const Color(0xFFC06062);
                    }
                  });
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.03, vertical: screenHeight * 0.005),
                  decoration: BoxDecoration(
                    color: const Color(0xFF837670),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '중복확인',
                    style: TextStyle(
                      fontSize: screenWidth * 0.04,
                      color: const Color(0xFFFEFDFC),
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ],
    );
  }
}

// 중복 닉네임 확인
Future<bool> isNicknameDuplicate(int userId, String nickname) async {
  final token = await getJwtToken();
  if (token == null) return true;

  final url = Uri.parse(
    'http://43.203.23.173:8080/user/check/nickname?userId=$userId&nickname=$nickname',
  );

  final response = await http.get(
    url,
    headers: {'Authorization': 'Bearer $token'},
  );

  if (response.statusCode == 200) {
    final body = response.body.trim();
    print('📡 닉네임 중복확인 응답 본문: $body');
    return body.contains('이미 사용');
  }

  return true;
}


// 프로필 저장 버튼 클래스
class SaveButton extends StatelessWidget {
  final int userId;
  final void Function()? onSuccess;
  final String? buttonText;

  const SaveButton({
    super.key,
    required this.userId,
    this.onSuccess,
    this.buttonText,
  });

  Future<bool> saveNickname() async {
    final nickname = NicknameInput.controller.text.trim();
    if (nickname.isEmpty) return false;

    print('👉 닉네임 저장 시도: $nickname');

    final token = await getJwtToken();
    print('📦 불러온 토큰: $token');

    if (token == null) {
      return false;
    }

    final url = Uri.parse('http://43.203.23.173:8080/user/update');
    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        "userId": userId,
        "nickname": nickname,
      }),
    );

    print('✅ 응답 상태 코드: ${response.statusCode}');
    print('✅ 응답 본문: ${response.body}');

    if (response.statusCode == 200) {
      final storage = FlutterSecureStorage();
      await storage.write(key: 'nickname', value: nickname);
      return true;
    } else {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}