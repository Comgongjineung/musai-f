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
  clearCachedToken();
}

String? _cachedToken;

Future<String?> getJwtTokenCached() async {
  if (_cachedToken != null) return _cachedToken;
  _cachedToken = await storage.read(key: 'jwt_token');
  return _cachedToken;
}