import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../login/login_profile.dart';
import '../utils/auth_storage.dart';



const String kProfileImageKey = 'profile_image_path';

class EditProfileAvatar extends StatefulWidget {
  final double screenWidth;
  final double screenHeight;
  const EditProfileAvatar({super.key, required this.screenWidth, required this.screenHeight});

  @override
  State<EditProfileAvatar> createState() => _EditProfileAvatarState();
}

class _EditProfileAvatarState extends State<EditProfileAvatar> {
  String? _imagePath;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadSavedPath();
  }

  Future<void> _loadSavedPath() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _imagePath = prefs.getString(kProfileImageKey);
    });
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (picked != null) {
      final path = picked.path;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(kProfileImageKey, path);
      setState(() {
        _imagePath = path;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.screenWidth * 0.25;
    final iconSize = widget.screenWidth * 0.04; // smaller pencil
    final imageProvider = (_imagePath != null && File(_imagePath!).existsSync())
        ? FileImage(File(_imagePath!)) as ImageProvider
        : const AssetImage('assets/images/profile.png');

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
            radius: size / 2,
            backgroundColor: const Color(0xFFFEFDFC),
            backgroundImage: imageProvider,
          ),
          Positioned(
            bottom: 0,
            right: 2,
            child: InkWell(
              onTap: _pickImage,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: EdgeInsets.all(iconSize * 0.25),
                decoration: BoxDecoration(
                  color: const Color(0xFF837670),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.edit, size: 26, color: const Color(0xFFFEFDFC)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<bool?> showEditProfileDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (context) {
      final screenWidth = MediaQuery.of(context).size.width;
      final screenHeight = MediaQuery.of(context).size.height;

      return Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            Container(
              height: screenHeight * 0.56,
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFDFC),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: screenHeight * 0.045),
                  Center(child: EditProfileAvatar(screenWidth: screenWidth, screenHeight: screenHeight)),
                  SizedBox(height: screenHeight * 0.045),
                  NicknameInput(screenWidth: screenWidth, screenHeight: screenHeight),
                  SizedBox(height: screenHeight * 0.055),
                  const EditDialogButtons(),
                  SizedBox(height: screenHeight * 0.045)
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}

// 취소, 저장 버튼
class EditDialogButtons extends StatefulWidget {
  const EditDialogButtons({super.key});

  @override
  State<EditDialogButtons> createState() => _EditDialogButtonsState();
}

class _EditDialogButtonsState extends State<EditDialogButtons> {
  int? userId;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final id = await getUserId();
    setState(() {
      userId = id;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return SizedBox(
      height: screenHeight * 0.05,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: screenWidth * 0.33,
            height: screenHeight * 0.05,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB1B1B1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text('취소', style: TextStyle(color: Color(0xFFFEFDFC), fontSize: screenWidth * 0.04)),
            ),
          ),
          SizedBox(width: screenWidth * 0.015),
          SizedBox(
            width: screenWidth * 0.33,
            height: screenHeight * 0.05,
            child: userId == null
                ? const SizedBox.shrink()
                : ElevatedButton(
                    onPressed: () async {
  bool nicknameSaved = false;
  bool imageUpdated = false;

  // 1) 이미지가 선택/저장되었는지 확인
  final prefs = await SharedPreferences.getInstance();
  final imgPath = prefs.getString(kProfileImageKey);
  if (imgPath != null && File(imgPath).existsSync()) {
    imageUpdated = true;
  }

  // 2) 닉네임 저장 시도 (userId가 있을 때만)
  if (userId != null) {
    nicknameSaved = await SaveButton(userId: userId!).saveNickname();
    if (!nicknameSaved) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('닉네임 저장 실패')),
      );
    }
  }

  // 3) 결과 반환
  if (!mounted) return;
  Navigator.of(context).pop(nicknameSaved || imageUpdated);
},

                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF837670),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text('저장', style: TextStyle(color: Color(0xFFFEFDFC), fontSize: screenWidth * 0.04)),
                  ),
          ),
        ],
      ),
    );
  }
}