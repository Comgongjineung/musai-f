import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'login_profile.dart';

late final GoogleSignIn _googleSignIn;

void configureGoogleSignIn() {
  if (Platform.isIOS) {
    _googleSignIn = GoogleSignIn(
      scopes: ['email', 'profile'],
      clientId: '951832016031-irkuvgtrgq1cotf6qlrlbda9rcf9dcnn.apps.googleusercontent.com',
    );
  } else if (Platform.isAndroid) {
    _googleSignIn = GoogleSignIn(
      scopes: ['email', 'profile'],
      serverClientId: '951832016031-bvh0bpst80oep57dp64510hp5s0jt51o.apps.googleusercontent.com',
    );
  } else {
    _googleSignIn = GoogleSignIn(
      scopes: ['email', 'profile'],
    );
  }
}

final storage = FlutterSecureStorage();

Future<void> signInWithGoogle(BuildContext context) async {
  try {
    configureGoogleSignIn();
    final account = await _googleSignIn.signIn();
    print('account 반환값: $account');

    if (account == null) {
      print('Google 로그인 실패 또는 사용자가 취소함');
      return;
    }

    final auth = await account.authentication;
    final idToken = auth.idToken;
    final accessToken = auth.accessToken;

    print('구글 access token: $accessToken');
    print('구글 id token: $idToken');

    // 백엔드로 id token 전달
    final response = await http.post(
      Uri.parse('http://43.203.23.173:8080/auth/google'),
      headers: {'Content-Type': 'application/json'},
       body: jsonEncode({'idToken': idToken}),
    );

    if (response.statusCode == 200) {
      //print('로그인 성공: ${response.body}');
      final responseJson = jsonDecode(response.body);
      final token = responseJson['accessToken'];
      final userId = responseJson['user']['userId'];
      print('서버 응답: ${response.body}');

      await storage.write(key: 'jwt_token', value: token);
      await storage.write(key: 'user_id', value: userId.toString());

      print('JWT 저장 완료: $token');
      print('userId 저장 완료: $userId');

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginProfileScreen(userId: userId)),
      );

    } else {
      print('로그인 실패: ${response.statusCode} / ${response.body}');
    }
  } catch (e) {
    print('에러 발생: $e');
  }
}


Future<String?> getStoredToken() async {
  final token = await storage.read(key: 'jwt_token');
  print('저장된 토큰: $token');
  return token;
}

Future<void> fetchProtectedResource() async {
  final token = await getStoredToken();
  if (token == null) {
    print('❗ 저장된 토큰이 없습니다');
    return;
  }

  final response = await http.get(
    Uri.parse('http://43.203.23.173:8080/auth/google'), // 여기에 실제 API 주소 입력
    headers: {'Authorization': 'Bearer $token'},
  );

  if (response.statusCode == 200) {
    print('보호된 데이터 응답: ${response.body}');
  } else {
    print('보호된 요청 실패: ${response.statusCode}');
  }
}
