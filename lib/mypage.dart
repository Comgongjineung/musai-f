import 'package:flutter/material.dart';
import 'bottom_nav_bar.dart';
import 'app_bar_widget.dart';
import 'mypage_bookmark.dart';

class MyPageScreen extends StatelessWidget {
  const MyPageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppBarWidget(),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 24),
            _profileSection(),
            const SizedBox(height: 24),
            _bookmarkTicketSection(context),
            const SizedBox(height: 24),
            _interpretationDropdown(),
            const SizedBox(height: 16),
            _writtenItemsSection(),
            const SizedBox(height: 16),
            _notificationSwitches(),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBarWidget(currentIndex: 3),
    );
  }

  Widget _profileSection() {
    return Column(
      children: [
        const CircleAvatar(
          radius: 40,
          backgroundImage: AssetImage('assets/profile.png'),
        ),
        const SizedBox(height: 16),
        const Text('닉네임', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: const Color(0xFFF5F0EC),
            foregroundColor: Colors.black,
            elevation: 0,
          ),
          child: const Text('내 정보 수정', style: TextStyle(fontSize: 16)),
        ),
      ],
    );
  }

  Widget _bookmarkTicketSection(BuildContext context) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: const Color(0xFF7A6F68),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const BookmarkScreen()),
                );
              },
              child: const Center(
                child: Icon(Icons.bookmark, color: Colors.white),
              ),
            ),
          ),
          const VerticalDivider(color: Colors.white, width: 1),
          Expanded(
            child: GestureDetector(
              onTap: () {
                // TODO: Replace with actual TicketScreen navigation once implemented
              },
              child: const Center(
                child: Icon(Icons.confirmation_number, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _interpretationDropdown() {
    String dropdownValue = '클래식한 해설';
    return StatefulBuilder(
      builder: (context, setState) {
        return Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Color(0xFFF5F0EC),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              const Text('해설 난이도', style: TextStyle(fontSize: 16)),
              const Spacer(),
              DropdownButton<String>(
                value: dropdownValue,
                underline: const SizedBox(),
                icon: const Icon(Icons.keyboard_arrow_down),
                items: <String>['쉬운 해설', '클래식한 해설', '전문가 해설']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value, style: const TextStyle(fontSize: 16)),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    dropdownValue = newValue!;
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _writtenItemsSection() {
    return Column(
      children: [
        Container(
          height: 90,
          decoration: BoxDecoration(
            color: Color(0xFFF5F0EC),
            borderRadius: BorderRadius.circular(20),
          ),
          child: ListTile(
            title: const Text('작성한 글', style: TextStyle(fontSize: 16)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Navigate to written posts page
            },
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: Color(0xFFF5F0EC),
            borderRadius: BorderRadius.circular(20),
          ),
          child: ListTile(
            title: const Text('작성한 댓글', style: TextStyle(fontSize: 16)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Navigate to written comments page
            },
          ),
        ),
      ],
    );
  }

  Widget _notificationSwitches() {
    bool exhibitionAlarm = false;
    bool communityAlarm = false;
    return StatefulBuilder(
      builder: (context, setState) {
        return Column(
          children: [
            Container(
              height: 54,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Color(0xFFF5F0EC),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('전시회 추천 알림', style: TextStyle(fontSize: 16)),
                  Switch(
                    value: exhibitionAlarm,
                    onChanged: (bool value) {
                      setState(() {
                        exhibitionAlarm = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 54,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Color(0xFFF5F0EC),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('커뮤니티 알림', style: TextStyle(fontSize: 16)),
                  Switch(
                    value: communityAlarm,
                    onChanged: (bool value) {
                      setState(() {
                        communityAlarm = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}