import 'package:flutter/material.dart';

class BottomNavBarWidget extends StatelessWidget {
  final int currentIndex;
  final Function(int)? onItemTapped;

  const BottomNavBarWidget({
    Key? key,
    required this.currentIndex,
    this.onItemTapped,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.09,
      decoration: const BoxDecoration(
        color: Color(0xFF5E5955),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(icon: Icons.home, index: 0),
          _buildNavItem(icon: Icons.camera_alt, index: 1),
          _buildNavItem(icon: Icons.calendar_today, index: 2),
          _buildNavItem(icon: Icons.person, index: 3),
        ],
      ),
    );
  }

  Widget _buildNavItem({required IconData icon, required int index}) {
    final isSelected = index == currentIndex;

    return GestureDetector(
      onTap: () => onItemTapped?.call(index),
      child: Icon(
        icon,
        color: isSelected ? Colors.white : Colors.grey,
        size: 28,
      ),
    );
  }
}
