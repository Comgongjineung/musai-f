import 'package:flutter/material.dart';
import 'login_profile.dart';
import 'utils/auth_storage.dart';


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
              height: screenHeight * 0.48,
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFDFC),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: screenHeight * 0.045),
                  Center(child: ProfileAvatar(screenWidth: screenWidth, screenHeight: screenHeight)),
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
              onPressed: () => Navigator.of(context).pop(),
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
                      final success = await SaveButton(userId: userId!).saveNickname();
                      if (success) {
                        Navigator.of(context).pop(true);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('닉네임 저장 실패')),
                        );
                      }
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