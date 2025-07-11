import 'package:flutter/material.dart';
import 'package:musai_f/login_kakao.dart';

class SignupKakaoPage extends StatelessWidget {
  const SignupKakaoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenHeight = constraints.maxHeight;
            final screenWidth = constraints.maxWidth;

            return Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: screenHeight * 0.1),
                  Text(
                    '내 손 안의\n전시회 관람 가이드',
                    style: TextStyle(
                      fontSize: screenWidth * 0.08,
                      fontWeight: FontWeight.w400,
                      height: 1.5,
                      color: const Color(0xFF706B66), 
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  Text(
                    'musai',
                    style: TextStyle(
                      fontSize: screenWidth * 0.1,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF343231), 
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.1),
                  Text(
                    '함께 시작해요!',
                    style: TextStyle(
                      fontSize: screenWidth * 0.04,
                      color: const Color(0xFFB1B1B1), //B1B1B1
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  // 카카오
                  GestureDetector(
                    onTap: () {
                      loginWithKakao();
                    },
                    child: Image.asset(
                      'assets/images/kakao_login_medium_wide.png',
                      width: double.infinity,
                      fit: BoxFit.contain,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  // 네이버
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF03C75A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      icon: const Icon(Icons.nat), // 대체 아이콘
                      label: Text(
                        '네이버로 시작하기',
                        style: TextStyle(fontSize: screenWidth * 0.04),
                      ),
                      onPressed: () {},
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  // 구글
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.g_mobiledata, size: 28),
                      label: Text(
                        '구글로 시작하기',
                        style: TextStyle(
                          color: const Color(0xFF343231),
                          fontSize: screenWidth * 0.04,
                        ),
                      ),
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: const Color(0xFFB1B1B1)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      '로그인 | 회원가입 | 계정 찾기',
                      style: TextStyle(
                        fontSize: screenWidth * 0.04,
                        color: const Color(0xFFB1B1B1),
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.1),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}