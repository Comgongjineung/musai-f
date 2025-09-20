import 'package:flutter/material.dart';
import '../utils/auth_storage.dart';
import 'login_UI.dart';
import '../homescreen/home_screen.dart';

class AuthCheck extends StatefulWidget {
  const AuthCheck({super.key});

  @override
  State<AuthCheck> createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  bool _isLoading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      // JWT 토큰과 사용자 ID 확인
      final token = await getJwtToken();
      final userId = await getUserId();
      
      setState(() {
        _isLoggedIn = (token != null && token.isNotEmpty && userId != null);
        _isLoading = false;
      });
    } catch (e) {
      print('인증 상태 확인 실패: $e');
      setState(() {
        _isLoggedIn = false;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFFFFDFC),
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFFA28F7D),
          ),
        ),
      );
    }

    // 로그인 상태에 따라 라우팅
    if (_isLoggedIn) {
      return const HomeScreen();
    } else {
      return const SignupPage();
    }
  }
}
