import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../utils/auth_storage.dart';
import 'login_profile.dart';

Future<void> loginWithApple(BuildContext context) async {
  try {
    // 애플 로그인 인증 정보 가져오기
    final AuthorizationCredentialAppleID credential =
        await SignInWithApple.getAppleIDCredential(scopes: [
      AppleIDAuthorizationScopes.email,
      AppleIDAuthorizationScopes.fullName,
    ]);
  
    print('사용자 ID: ${credential.userIdentifier}');
    print('이메일: ${credential.email}');
    print('이름: ${credential.givenName} ${credential.familyName}');
    print('Authorization Code: ${credential.authorizationCode}');
    
    // 서버로 애플 authorization_code 전송
    final response = await http.post(
      Uri.parse('http://43.203.23.173:8080/auth/apple'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'code': credential.authorizationCode,
      }),
    );

    if (response.statusCode == 200) {
      final responseJson = jsonDecode(response.body);
      final token = responseJson['accessToken'];
      final userId = responseJson['user']['userId'];
      
      print('✅ 서버 인증 성공');
      print('서버 응답: ${response.body}');
      print('JWT 토큰: $token');
      print('사용자 ID: $userId');

      // JWT 토큰과 사용자 ID 저장
      await saveJwtToken(token);
      await saveUserId(userId);
      
      print('JWT 저장 완료: $token');
      print('userId 저장 완료: $userId');
      
      // 프로필 설정 화면으로 이동
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginProfileScreen(userId: userId)),
        );
      }
    } else {
      print('❌ 서버 인증 실패: ${response.statusCode}');
      print('응답 내용: ${response.body}');
      print('응답 헤더: ${response.headers}');
      
      String errorMessage = '서버 인증에 실패했습니다.';
      if (response.statusCode == 403) {
        errorMessage = '서버에서 요청을 거부했습니다.';
      }
      
      _showErrorDialog(context, errorMessage);
    }
  } on SignInWithAppleAuthorizationException catch (e) {
    print('❌ 애플 로그인 인증 실패: ${e.code}');
    print('❌ 에러 상세 정보: ${e.toString()}');
    String errorMessage = '애플 로그인이 취소되었습니다.';
    
    switch (e.code) {
      case AuthorizationErrorCode.canceled:
        errorMessage = '애플 로그인이 취소되었습니다.';
        break;
      case AuthorizationErrorCode.failed:
        errorMessage = '애플 로그인에 실패했습니다.';
        break;
      case AuthorizationErrorCode.invalidResponse:
        errorMessage = '애플 로그인 응답이 유효하지 않습니다.';
        break;
      case AuthorizationErrorCode.notHandled:
        errorMessage = '애플 로그인 처리가 중단되었습니다.';
        break;
      case AuthorizationErrorCode.notInteractive:
        errorMessage = '애플 로그인 인터랙션이 불가능합니다.';
        break;
      case AuthorizationErrorCode.unknown:
        errorMessage = '알 수 없는 오류가 발생했습니다.';
        break;
    }
    
    if (context.mounted) {
      _showErrorDialog(context, errorMessage);
    }
  } catch (e) {
    print('❌ 애플 로그인 예외 발생: $e');
    if (context.mounted) {
      _showErrorDialog(context, '네트워크 오류가 발생했습니다. 다시 시도해주세요.');
    }
  }
}


// 애플 토큰 취소 함수
Future<void> revokeAppleToken() async {
  try {
    // 애플에서 토큰 취소 (서버를 통해)
    final response = await http.post(
      Uri.parse('http://43.203.23.173:8080/auth/apple/revoke'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'action': 'revoke',
      }),
    );
    
    if (response.statusCode == 200) {
      print('✅ 애플 토큰 취소 성공');
    } else {
      print('❌ 애플 토큰 취소 실패: ${response.statusCode}');
    }
  } catch (e) {
    print('❌ 애플 토큰 취소 실패: $e');
  }
}

// 로그아웃 함수 (토큰 취소 포함)
Future<void> logoutWithApple() async {
  try {
    // 1. 애플 토큰 취소
    await revokeAppleToken();
    
    // 2. 로컬 저장소에서 인증 정보 삭제
    await clearAuthStorage();
    
    print('✅ 애플 로그아웃 완료');
  } catch (e) {
    print('❌ 애플 로그아웃 실패: $e');
  }
}

void _showErrorDialog(BuildContext context, String message) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('로그인 실패'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('확인'),
          ),
        ],
      );
    },
  );
}
