import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';


class ProfileImageHelper {
  static const String _kProfileImageKey = 'profile_image_path';

  /// 갤러리/카메라에서 이미지를 선택하고 앱 디렉토리에 복사한 뒤, 경로를 저장합니다.
  /// 반환값: 최종 저장된 파일 경로 (실패/취소 시 null)
  static Future<String?> pickAndSaveProfileImage({
    ImageSource source = ImageSource.gallery,
    int imageQuality = 90,
    String fileNamePrefix = 'profile',
  }) async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: source,
      imageQuality: imageQuality,
    );
    if (picked == null) return null;

    final String savedPath = await _persistToAppDir(
      File(picked.path),
      fileNamePrefix: fileNamePrefix,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kProfileImageKey, savedPath);
    return savedPath;
  }

  /// SharedPreferences에 저장된 프로필 이미지 경로를 반환합니다.
  static Future<String?> getSavedProfileImagePath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kProfileImageKey);
  }

  /// 저장된 프로필 이미지를 File로 반환합니다. 없거나 삭제되었으면 null.
  static Future<File?> getSavedProfileImageFile() async {
    final path = await getSavedProfileImagePath();
    if (path == null) return null;
    final file = File(path);
    if (await file.exists()) return file;
    return null;
  }

  /// 저장된 프로필 이미지가 존재하는지 여부
  static Future<bool> hasSavedProfileImage() async {
    final file = await getSavedProfileImageFile();
    return file != null;
  }

  /// 외부에서 받은 File을 앱 디렉토리에 저장하고 경로를 기록합니다.
  static Future<String> saveProfileImageFromFile(
    File file, {
    String fileNamePrefix = 'profile',
  }) async {
    final savedPath = await _persistToAppDir(
      file,
      fileNamePrefix: fileNamePrefix,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kProfileImageKey, savedPath);
    return savedPath;
  }

  /// 저장된 프로필 이미지와 키를 삭제합니다.
  static Future<void> clearSavedProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString(_kProfileImageKey);
    if (path != null) {
      final file = File(path);
      if (await file.exists()) {
        try {
          await file.delete();
        } catch (_) {
          // 파일 삭제 실패는 무시
        }
      }
    }
    await prefs.remove(_kProfileImageKey);
  }

  /// 원본 파일을 앱 전용 디렉토리(예: Documents/profile_images)에 복사하여 영구 보관
  static Future<String> _persistToAppDir(
    File file, {
    required String fileNamePrefix,
  }) async {
    final Directory appDir = await getApplicationDocumentsDirectory();
    final Directory targetDir = Directory(p.join(appDir.path, 'profile_images'));
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }

    final String ext = p.extension(file.path).isNotEmpty ? p.extension(file.path) : '.jpg';
    final String fileName = '${fileNamePrefix}_${DateTime.now().millisecondsSinceEpoch}$ext';
    final String newPath = p.join(targetDir.path, fileName);

    final File copied = await file.copy(newPath);
    return copied.path;
  }
}