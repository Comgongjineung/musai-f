import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'main.dart';
import 'main_camera_page.dart';
// import 'community.dart';
// import 'mypage.dart';

class BottomNavBarWidget extends StatelessWidget {
  final int currentIndex;

  const BottomNavBarWidget({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.10,
      decoration: const BoxDecoration(
        color: Color(0xFFFFFDFC), // 배경색 변경
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x4D6E5E5E), // #6E5E5E with 30% opacity
            offset: Offset(0, -2), // shadow only on top
            blurRadius: 20,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: _buildNavItem(
              context,
              icon: Icons.home,
              label: '홈',
              index: 0,
            ),
          ),
          Expanded(
            child: _buildNavItem(
              context,
              icon: Icons.camera_alt,
              label: '카메라',
              index: 1,
            ),
          ),
          Expanded(
            child: _buildNavItem(
              context,
              icon: Icons.forum,
              label: '커뮤니티',
              index: 2,
            ),
          ),
          Expanded(
            child: _buildNavItem(
              context,
              icon: Icons.person,
              label: '마이페이지',
              index: 3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = index == currentIndex;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque, // 💡 터치 범위 전체 확장
        onTap: () {
          if (index == currentIndex) return;

          switch (index) {
            case 0:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const HomeScreen()),
              );
              break;
            case 1:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const MusaiHomePage()),
              );
              break;
            case 2:
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('커뮤니티는 준비 중입니다.')));
              break;
            case 3:
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('마이페이지는 준비 중입니다.')));
              break;
          }
        },
        child: Container(
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color:
                    isSelected ? Color(0xFF837670) : Color(0xFFB1B1B1), // 색상 변경
                size: 26,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color:
                      isSelected
                          ? Color(0xFF837670)
                          : Color(0xFFB1B1B1), // 색상 변경
                ),
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }
}
