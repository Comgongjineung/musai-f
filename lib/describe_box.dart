import 'package:flutter/material.dart';
import 'dart:io';
import 'bottom_nav_bar.dart'; // 반드시 import 필요
import 'main.dart'; // 탭 클릭 시 이동하려면 필요
import 'dart:convert';
import 'dart:typed_data';
import 'tts_service.dart';
import 'package:audioplayers/audioplayers.dart';
import 'main_camera_page.dart';
import 'package:http/http.dart' as http;
import 'utils/auth_storage.dart';

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
  String? token;
  int? userId;
  bool isBookmarked = false;
  int? bookmarkId;
  String selectedDescription = '클래식한 해설';  // 기본값 설정
  String currentDescription = ''; // 현재 표시되는 설명
  bool isLoadingDescription = false; // 설명 로딩 상태

  final List<String> descriptionTypes = [
    '한눈에 보는 해설',
    '클래식한 해설',
    '깊이 있는 해설',
  ];

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool isPlaying = false;

  @override
  void initState() {
    super.initState();
    // 초기 설명 설정
    currentDescription = widget.description;
    _loadAuthInfo();
  }

  Future<void> _loadAuthInfo() async {
  token = await getJwtToken();
  userId = await getUserId();
  if (mounted) {
    setState(() {}); // UI 갱신
  }
  await _initializeState();
}

  Future<void> _initializeState() async {
  await _checkBookmarkStatus();  // 북마크 여부 확인
}


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
                          print('widget.imageUrl: ${widget.imageUrl}');
                          if (widget.imageUrl != null && widget.imageUrl!.startsWith('http')) {
                            print('네트워크 이미지 받음');
                            return Image.network(
                              widget.imageUrl!,
                              fit: BoxFit.cover,
                            );
                          } else if (widget.imageUrl != null && widget.imageUrl!.startsWith('data:image')) {
                            final base64Str = widget.imageUrl!.split(',').last;
                            final bytes = base64Decode(base64Str);
                            print('base64 메모리 받음');
                            return Image.memory(
                              bytes,
                              fit: BoxFit.cover,
                            );
                          } else {
                            print('렌더링 안보임');
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
      onTap: _handleBookmarkToggle,
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
                                    if (value != null && value != selectedDescription) {
                                      setState(() {
                                        selectedDescription = value;
                                      });
                                      // 새로운 해설 타입으로 API 호출
                                      _fetchNewDescription(value);
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
                          child: isLoadingDescription
                              ? const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(20.0),
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                    ),
                                  ),
                                )
                              : Text(
                                  currentDescription.replaceAll('*', ''),
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

  Future<void> _handleBookmarkToggle() async {
    if (token == null || userId == null) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('인증 정보가 없습니다. 다시 로그인해주세요.')),
  );
  return;
}

    if (!isBookmarked) {
      // 북마크 추가
      final response = await http.post(
        Uri.parse('http://43.203.23.173:8080/bookmark/add'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token',},
        body: jsonEncode({
          'userId': userId,
          'title': widget.title,
          'artist': widget.artist,
          'description': widget.description,
          'imageUrl': widget.imageUrl ?? '',
        }),
      );

      if (response.statusCode == 200) {
        final result = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          isBookmarked = true;
          bookmarkId = result['bookmarkId']; // 응답에서 bookmarkId 저장
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('북마크에 추가되었습니다.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('북마크 추가 실패: ${response.statusCode}')),
        );
      }
    } else {
      // 북마크 삭제
      if (bookmarkId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('bookmarkId가 없어 삭제할 수 없습니다.')),
        );
        return;
      }

      final deleteUrl = 'http://43.203.23.173:8080/bookmark/delete/$bookmarkId/$userId';
      final deleteResponse = await http.delete( Uri.parse(deleteUrl),
      headers: {
    'Authorization': 'Bearer $token',
  },);

      if (deleteResponse.statusCode == 200) {
        setState(() {
          isBookmarked = false;
          bookmarkId = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('북마크가 삭제되었습니다.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('북마크 삭제 실패: ${deleteResponse.statusCode}')),
        );
      }
    }
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
      currentDescription,
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

  // 해설 타입에 따른 level 매핑
  String _getLevelForDescriptionType(String descriptionType) {
    switch (descriptionType) {
      case '한눈에 보는 해설':
        return '하';
      case '클래식한 해설':
        return '중';
      case '깊이 있는 해설':
        return '상';
      default:
        return '하';
    }
  }

  // 새로운 해설 타입으로 API 호출
  Future<void> _fetchNewDescription(String descriptionType) async {
    if (token == null || userId == null) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('인증 정보가 없습니다. 다시 로그인해주세요.')),
  );
  return;
}

    setState(() {
      isLoadingDescription = true;
    });

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('http://43.203.23.173:8080/recog/analyzeAndRegister'),
      );
      request.files.add(await http.MultipartFile.fromPath('file', widget.imagePath));
      request.fields['level'] = _getLevelForDescriptionType(descriptionType);

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = json.decode(responseBody);
        final newDescription = data['gemini_result']['description'] ?? '';
        
        setState(() {
          currentDescription = newDescription;
          isLoadingDescription = false;
        });
      } else {
        print('새로운 해설 요청 실패: ${response.statusCode}');
        setState(() {
          isLoadingDescription = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('새로운 해설을 가져오는데 실패했습니다.')),
          );
        }
      }
    } catch (e) {
      print('새로운 해설 요청 에러: $e');
      setState(() {
        isLoadingDescription = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('새로운 해설 요청 중 에러가 발생했습니다: $e')),
        );
      }
    }
  }

Future<void> _checkBookmarkStatus() async {
  if (userId == null) return;

  final response = await http.get(Uri.parse(
    'http://43.203.23.173:8080/bookmark/readAll/$userId'), 
    headers: {
    'Authorization': 'Bearer $token',
  },
  );

  if (response.statusCode == 200) {
    final utf8Decoded = utf8.decode(response.bodyBytes);
    final List<dynamic> bookmarks = json.decode(utf8Decoded);
    final match = bookmarks.firstWhere(
      (item) =>
          item['title'] == widget.title &&
          item['artist'] == widget.artist,
      orElse: () => null,
    );

    if (match != null) {
      setState(() {
        isBookmarked = true;
        bookmarkId = match['bookmarkId'];
      });
    }
  }
}

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
