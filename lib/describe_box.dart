import 'package:flutter/material.dart';

import 'dart:io';
import 'bottom_nav_bar.dart'; // 반드시 import 필요
import 'main.dart'; // 탭 클릭 시 이동하려면 필요
import 'dart:convert';
import 'dart:typed_data';

class DescriptionScreen extends StatefulWidget {
  final String title;
  final String artist;
  final String year;
  final String description;
  final String imagePath;
  final String? imageUrl;
  final ScrollController scrollController;

  const DescriptionScreen({
    super.key,
    required this.title,
    required this.artist,
    required this.year,
    required this.description,
    required this.imagePath,
    this.imageUrl,
    required this.scrollController,
  });

  @override
  State<DescriptionScreen> createState() => _DescriptionScreenState();
}

class _DescriptionScreenState extends State<DescriptionScreen> {
  bool isBookmarked = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4B4237),
      body: Stack(
        children: [
          // 상단 바(AppBar)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const MusaiHomePage()),
                        );
                      },
                    ),
                    const Text(
                      'musai',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(width: 40), // 오른쪽 여백(아이콘 자리)
                  ],
                ),
              ),
            ),
          ),

          // 상단 이미지와 버튼 (디자인 개선)
          Positioned(
            top: 60, // AppBar 높이(60)
            left: 0,
            right: 0,
            child: Container(
              alignment: Alignment.topCenter,
              padding: const EdgeInsets.only(top: 24),
              child: Stack(
                children: [
                  // 이미지 (고정 사이즈)
                  Container(
                    width: 342,
                    height: 514,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: widget.imageUrl != null &&
                              widget.imageUrl!.isNotEmpty &&
                              widget.imageUrl!.startsWith('data:image')
                          ? (() {
                              try {
                                final base64Str = widget.imageUrl!.split(',').last;
                                final bytes = base64Decode(base64Str);
                                return Image.memory(
                                  bytes,
                                  fit: BoxFit.cover,
                                );
                              } catch (e) {
                                print('❌ Base64 디코딩 오류: $e');
                                return Image.file(
                                  File(widget.imagePath),
                                  fit: BoxFit.cover,
                                );
                              }
                            })()
                          : Image.file(
                              File(widget.imagePath),
                              fit: BoxFit.cover,
                            ),
                    ),
                  ),
                  // AR 버튼 (가운데)
                  Positioned(
                    top: 16,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'AR',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // 북마크 버튼 (오른쪽 상단)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          isBookmarked = !isBookmarked;
                        });
                      },
                      child: Icon(
                        isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Draggable 설명 카드
          DraggableScrollableSheet(
            initialChildSize: 0.38,
            minChildSize: 0.38,
            maxChildSize: 0.85,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF22201F),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    // 드래그 핸들
                    Padding(
                      padding: const EdgeInsets.only(top: 12, bottom: 8),
                      child: Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[700],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                    // 드롭다운, TTS 버튼
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 36,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF37322F),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: const [
                                  Text(
                                    '적당한 설명',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFF37322F),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.volume_up, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // 제목, 작가, 연도
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${widget.artist}, ${widget.year}',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // 설명 스크롤
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: SingleChildScrollView(
                          controller: scrollController,
                          child: Text(
                            widget.description,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // 하단바
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: BottomNavBarWidget(
              currentIndex: 1,
              onItemTapped: (index) {
                if (index == 0) {
                  Navigator.pop(context);
                } else if (index == 2) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const MusaiHomePage()),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('탭 $index: 연결된 페이지가 아직 없습니다.')),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
