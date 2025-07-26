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

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          //padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 28),
                  _stepIndicator(),
                  const SizedBox(height: 32),
                  _titleSection(),
                  const SizedBox(height: 60),
                  const Center(child: ProfileAvatar()),
                  const SizedBox(height: 40),
                  _nicknameSection(),
                  const Spacer(),
                  _nextButton(context),
                  const SizedBox(height: 28),
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

  Widget _titleSection() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '프로필 설정',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF343231),
          ),
        ),
        SizedBox(height: 8),
        Text(
          'musai를 자유롭게 사용해보세요.',
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFF706B66),
          ),
        ),
      ],
    );
  }

  Widget _nicknameSection() {
    return const NicknameInput();
  }

  Widget _nextButton(BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed: () async {
          final nickname = NicknameInput.controller.text.trim();
          if (nickname.isEmpty) return;

          print('👉 닉네임 저장 시도: $nickname');

          final token = await getJwtToken();
          print('📦 불러온 토큰: $token');

          if (token == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('토큰 없음: 로그인 상태를 확인해주세요.')),
            );
            return;
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
          minimumSize: const Size.fromHeight(54),
        ),
        child: const Text(
          '다음으로',
          style: TextStyle(
            color: Color(0xFFFEFDFC),
            fontSize: 20,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class StepIndicator extends StatelessWidget {
  const StepIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFFC06062),
          ),
          alignment: Alignment.center,
          child: const Text(
            '1',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        const SizedBox(width: 5),
        const Icon(Icons.circle, size: 4, color: Color(0xFFB1B1B1)),
        const SizedBox(width: 2),
        const Icon(Icons.circle, size: 4, color: Color(0xFFB1B1B1)),
        const SizedBox(width: 2),
        const Icon(Icons.circle, size: 4, color: Color(0xFFB1B1B1)),
        const SizedBox(width: 5),
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFC06062)),
          ),
          alignment: Alignment.center,
          child: const Text(
            '2',
            style: TextStyle(
              color: Color(0xFFC06062),
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: const Color(0x4DB1B1B1), // #B1B1B1 @ 30%
                blurRadius: 5.45,
                spreadRadius: 1.36,
                offset: const Offset(0, 0),
              ),
            ],
          ),
          padding: const EdgeInsets.all(4),
          child: const CircleAvatar(
            radius: 54,
            backgroundColor:  Color(0xFFFEFDFC),
            backgroundImage: AssetImage('assets/images/profile.png'),
          ),
        ),
        GestureDetector(
          onTap: () {
            // To be implemented: open gallery and replace image
          },
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Color(0x4D665E5E), // #665E5E @ 30% opacity
                  blurRadius: 27.27,
                  spreadRadius: 0,
                  offset: Offset(0, 0),
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
  const NicknameInput({super.key});
  static final TextEditingController controller = TextEditingController();

  @override
  State<NicknameInput> createState() => _NicknameInputState();
}

class _NicknameInputState extends State<NicknameInput> {
  String? _nicknameStatusMessage;
  Color _nicknameStatusColor = Colors.transparent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text(
                  '닉네임',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF343231),
                  ),
                ),
                const SizedBox(width: 8),
                Image.asset(
                  'assets/images/check_circle.png',
                  width: 16,
                  height: 16,
                ),
              ],
            ),
            if (_nicknameStatusMessage != null)
              Text(
                _nicknameStatusMessage!,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: _nicknameStatusColor,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF6F2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: NicknameInput.controller,
                  decoration: const InputDecoration(
                    hintText: 'n자 이내로 입력하세요.',
                    border: InputBorder.none,
                    hintStyle: TextStyle(
                      fontSize: 16,
                      color: Color(0xFFB1B1B1),
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
                      _nicknameStatusColor = Color(0xFFC06062);
                    } else {
                      _nicknameStatusMessage = '사용 가능한 닉네임입니다.';
                      _nicknameStatusColor = Color(0xFFC06062);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF837670),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '중복확인',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFFFEFDFC),
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