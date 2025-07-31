import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final FlutterSecureStorage storage = FlutterSecureStorage();

Future<String?> getJwtToken() async {
  return await storage.read(key: 'jwt_token');
}

Future<int?> getUserId() async {
  final id = await storage.read(key: 'user_id');
  return id != null ? int.tryParse(id) : null;
}

void clearCachedToken() {
  _cachedToken = null;
}

Future<void> clearAuthStorage() async {
  await storage.delete(key: 'jwt_token');
  await storage.delete(key: 'user_id');
  await storage.delete(key: 'fcm_token');
  clearCachedToken();
}

String? _cachedToken;

Future<String?> getJwtTokenCached() async {
  if (_cachedToken != null) return _cachedToken;
  _cachedToken = await storage.read(key: 'jwt_token');
  return _cachedToken;
}

String? _cachedFcmToken;

// 저장
Future<void> saveFcmToken(String token) async {
  await storage.write(key: 'fcm_token', value: token);
  _cachedFcmToken = token; // 메모리에도 저장
  print("📌 FCM 토큰 로컬 저장 완료: $token");
}

// 불러오기
Future<String?> getFcmToken() async {
  if (_cachedFcmToken != null) return _cachedFcmToken;
  _cachedFcmToken = await storage.read(key: 'fcm_token');
  return _cachedFcmToken;
}

// 삭제
Future<void> clearFcmToken() async {
  await storage.delete(key: 'fcm_token');
  _cachedFcmToken = null;
  print("FCM 토큰 삭제 완료");
}

