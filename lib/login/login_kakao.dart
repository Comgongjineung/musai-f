import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

Future<void> loginWithKakao() async {
  try {
    OAuthToken token;

    // 카카오톡 설치 여부 확인
    if (await isKakaoTalkInstalled()) {
      // 카카오톡으로 로그인
      token = await UserApi.instance.loginWithKakaoTalk();
    } else {
      // 카카오계정으로 로그인
      token = await UserApi.instance.loginWithKakaoAccount();
    }

    // 사용자 정보 가져오기
    final user = await UserApi.instance.me();
    print('로그인 성공!');
    print('사용자 ID: ${user.id}');
    print('이메일: ${user.kakaoAccount?.email}');
    print('AccessToken: ${token.accessToken}');
  } catch (e) {
    print('❌ 로그인 실패: $e');
  }
}

Future<bool> checkIfLoggedIn() async {
  final tokenInfo = await TokenManagerProvider.instance.manager.getToken();
  return tokenInfo != null && tokenInfo.accessToken != null;
}