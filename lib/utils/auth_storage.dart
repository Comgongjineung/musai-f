import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final FlutterSecureStorage storage = FlutterSecureStorage();

Future<String?> getJwtToken() async {
  return await storage.read(key: 'jwt_token');
}

Future<int?> getUserId() async {
  final id = await storage.read(key: 'user_id');
  return id != null ? int.tryParse(id) : null;
}
