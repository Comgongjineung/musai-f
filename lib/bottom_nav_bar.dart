import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'main.dart';
// import 'community.dart';
// import 'mypage.dart';

class BottomNavBarWidget extends StatelessWidget {
  final int currentIndex;

  const BottomNavBarWidget({
    super.key,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.09,
      decoration: const BoxDecoration(
        color: Color(0xFF3C342E),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(context, icon: Icons.home, label: '홈', index: 0),
          _buildNavItem(context, icon: Icons.camera_alt, label: '카메라', index: 1),
          _buildNavItem(context, icon: Icons.forum, label: '커뮤니티', index: 2),
          _buildNavItem(context, icon: Icons.person, label: '마이페이지', index: 3),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, {
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = index == currentIndex;

    return GestureDetector(
      onTap: () {
        if (!isSelected) {
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('커뮤니티는 준비 중입니다.')),
              );
              break;
            case 3:
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('마이페이지는 준비 중입니다.')),
              );
              break;
          }
        }
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isSelected ? Colors.white : Colors.white54,
            size: 26,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isSelected ? Colors.white : Colors.white54,
            ),
          ),
        ],
      ),
    );
  }
}