import 'package:flutter/material.dart';
import 'dart:io';
import 'bottom_nav_bar.dart'; // 반드시 import 필요
import 'main.dart'; // 탭 클릭 시 이동하려면 필요
import 'dart:convert';
import 'dart:typed_data';
import 'tts_service.dart';
import 'package:audioplayers/audioplayers.dart';
import 'main_camera_page.dart';

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
  String selectedDescription = '클래식한 해설';  // 기본값 설정

  final List<String> descriptionTypes = [
    '한눈에 보는 해설',
    '클래식한 해설',
    '깊이 있는 해설',
  ];

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool isPlaying = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF47423D),
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
                height: MediaQuery.of(context).size.height * 0.07,
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
            top: MediaQuery.of(context).size.height * 0.105, // Responsive top padding
            left: 0,
            right: 0,
            child: Container(
              alignment: Alignment.topCenter,
              padding: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.03),
              child: Stack(
                children: [
                  // 이미지 (고정 사이즈)
                  Container(
                    width: MediaQuery.of(context).size.width * 0.9,
                    height: MediaQuery.of(context).size.height * 0.6,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Builder(
                        builder: (context) {
                          print('📷 widget.imageUrl: ${widget.imageUrl}');
                          if (widget.imageUrl != null && widget.imageUrl!.startsWith('http')) {
                            print('✅ 네트워크 이미지 받음');
                            return Image.network(
                              widget.imageUrl!,
                              fit: BoxFit.cover,
                            );
                          } else if (widget.imageUrl != null && widget.imageUrl!.startsWith('data:image')) {
                            final base64Str = widget.imageUrl!.split(',').last;
                            final bytes = base64Decode(base64Str);
                            print('✅ base64 메모리 받음');
                            return Image.memory(
                              bytes,
                              fit: BoxFit.cover,
                            );
                          } else {
                            print('✅ 렌더링 안보임');
                            return const SizedBox.shrink();
                          }
                        },
                      ),
                    ),
                  ),
                  // AR 버튼 (가운데)
                  Positioned(
                    top: MediaQuery.of(context).size.height * 0.02,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: MediaQuery.of(context).size.width * 0.06,
                          vertical: MediaQuery.of(context).size.height * 0.01,
                        ),
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
                    top: MediaQuery.of(context).size.height * 0.02,
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
                        size: MediaQuery.of(context).size.width * 0.08,
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
                          width: MediaQuery.of(context).size.width * 0.1,
                          height: MediaQuery.of(context).size.height * 0.005,
                          decoration: BoxDecoration(
                            color: Colors.grey[700],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                    // 상단 컨트롤 바 (진한 회색)
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.04),
                      child: Container(
                        height: MediaQuery.of(context).size.height * 0.06,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF37322F), // 진한 회색
                          // color: const Color(0xFFEAE1DC), // 연한 회색
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            // 드롭다운 메뉴 감싸는 연한 회색 박스
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              height: MediaQuery.of(context).size.height * 0.045,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEAE1DC),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: selectedDescription,
                                  dropdownColor: const Color(0xFFEAE1DC),
                                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF4B4237)),
                                  style: const TextStyle(color: Color(0xFF4B4237), fontWeight: FontWeight.w500),
                                  borderRadius: BorderRadius.circular(20),
                                  items: descriptionTypes.map((type) {
                                    return DropdownMenuItem<String>(
                                      value: type,
                                      child: Text(type, style: const TextStyle(color: Color(0xFF4B4237))),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() {
                                        selectedDescription = value;
                                      });
                                    }
                                  },
                                ),
                              ),
                            ),
                            const Spacer(),
                            // TTS 버튼 감싸는 연한 회색 박스
                            Container(
                              width: MediaQuery.of(context).size.width * 0.09,
                              height: MediaQuery.of(context).size.width * 0.09,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEAE1DC),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: IconButton(
                                icon: Icon(Icons.volume_up, color: Color(0xFF4B4237)),
                                onPressed: _playTTS,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.015),
                    // 제목, 작가, 연도
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.04),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            widget.title,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: MediaQuery.of(context).size.width * 0.05,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${widget.artist}, ${widget.year}',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: MediaQuery.of(context).size.width * 0.035,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.015),
                    // 설명 스크롤
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.04),
                        child: SingleChildScrollView(
                          controller: scrollController,
                          child: Text(
                            widget.description.replaceAll('*', ''),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: MediaQuery.of(context).size.width * 0.035,
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

        ],
      ),
    );
  }

  Future<void> _playTTS() async {
    if (isPlaying) {
      await _audioPlayer.stop();
      setState(() {
        isPlaying = false;
      });
      return;
    }

    var ttsText = [
      widget.title,
      widget.artist,
      widget.year,
      widget.description,
    ].where((e) => e != null && e.isNotEmpty).join(', ');
    ttsText = ttsText.replaceAll('*', '');
    try {
      print('TTS 요청 텍스트: $ttsText');
      final audioBytes = await TTSService.synthesize(ttsText);
      if (audioBytes != null) {
        if (Platform.isIOS) {
          // iOS는 BytesSource 지원 안하므로 파일로 저장 후 재생
          final tempDir = await Directory.systemTemp.createTemp();
          final tempFile = File('${tempDir.path}/tts_audio.mp3');
          await tempFile.writeAsBytes(audioBytes);
          await _audioPlayer.play(DeviceFileSource(tempFile.path));
        } else {
          // Android 등에서는 BytesSource로 직접 재생
          await _audioPlayer.play(BytesSource(audioBytes));
        }
        setState(() {
          isPlaying = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('TTS 오류: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
