import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:musai_f/login_kakao.dart';
import 'login_google.dart';

class SignupPage extends StatelessWidget {
  const SignupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDFC),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenHeight = constraints.maxHeight;
            final screenWidth = constraints.maxWidth;

            return Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
              child: Align(
                alignment: Alignment.topLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                  SizedBox(height: screenHeight * 0.08),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '내 손 안의\n전시회 관람 가이드',
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          fontWeight: FontWeight.w600, // SemiBold
                          fontSize: screenWidth * 0.08,
                          height: 1.1875,
                          letterSpacing: 0,
                          color: Color(0xFF706B66),
                        ),
                      ),
                      SizedBox(height: screenWidth * 0.02),
                      Text(
                        'musai',
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: screenWidth * 0.1,
                          color: Color(0xFF343231),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: screenHeight * 0.14),
                  Center(
                    child: Text(
                      '함께 시작해요!',
                      style: TextStyle(
                        fontSize: screenWidth * 0.04,
                        color: const Color(0xFFB1B1B1),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),

                  // 카카오
                  SizedBox(
                    width: double.infinity,
                    height: screenHeight * 0.06,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFE812),
                        foregroundColor: const Color(0xFF343231),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(screenWidth * 0.05),
                        ),
                      ),
                      onPressed: () {
                        loginWithKakao();
                      },
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Image.asset(
                              'assets/images/kakao_icon.png',
                              width: screenWidth * 0.05,
                              height: screenWidth * 0.05,
                            ),
                          ),
                          Center(
                            child: Text(
                              '카카오로 시작하기',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: screenWidth * 0.04,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  // 네이버
                  SizedBox(
                    width: double.infinity,
                    height: screenHeight * 0.06,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF03C75A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(screenWidth * 0.05),
                        ),
                      ),
                      onPressed: () {
                        // 네이버 로그인 함수
                      },
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Image.asset(
                              'assets/images/naver_icon.png',
                              width: screenWidth * 0.045,
                              height: screenWidth * 0.045,
                            ),
                          ),
                          Center(
                            child: Text(
                              '네이버로 시작하기',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: screenWidth * 0.04,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  // 구글
                  SizedBox(
                    width: double.infinity,
                    height: screenHeight * 0.06,
                    child: OutlinedButton(
                      onPressed: () {
                        signInWithGoogle();
                      },
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFFB1B1B1)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(screenWidth * 0.05),
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: SvgPicture.asset(
                              'assets/images/google_icon.svg',
                              width: screenWidth * 0.05,
                              height: screenWidth * 0.05,
                            ),
                          ),
                          Center(
                            child: Text(
                              '구글로 시작하기',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF343231),
                                fontSize: screenWidth * 0.04,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),
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