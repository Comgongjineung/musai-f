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
import 'package:flutter_svg/flutter_svg.dart';

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
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadAuthInfo();      // 토큰, userId 불러오기
    await _initializeState();   // 그다음 상태 초기화
  }

  Future<void> _loadAuthInfo() async {
    token = await getJwtToken();
    userId = await getUserId();
    if (mounted) {
      setState(() {}); // UI 갱신
    }
  }

  Future<void> _initializeState() async {
    if (token != null && userId != null) {
      await _checkBookmarkStatus();  // 북마크 여부 확인
    }
  }


  @override
  Widget build(BuildContext context) {
    // 반응형 디자인을 위한 화면 크기 변수들 (Figma 기준: 390 × 844)
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDFC),
      body: Stack(
        children: [
          // ===== 상단 네비게이션 바 =====
          // - 뒤로가기 버튼과 앱 로고가 있는 상단 고정 영역
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Container(
                height: 60,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // ===== 뒤로가기 버튼 (검정색) =====
                    SizedBox(
                      width: 36,
                      height: 36,
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.black, // 검정색으로 수정
                          size: 24,
                        ),
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const MusaiHomePage()),
                          );
                        },
                      ),
                    ),
                    // ===== musai 텍스트 =====
                    Text(
                      'musai',
                      style: TextStyle(
                        color: const Color(0xFF343231), // #343231
                        fontFamily: 'Pretendard',
                        fontSize: screenWidth * (32 / 390), // 약 8.2
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 40), // 오른쪽 여백(아이콘 자리)
                  ],
                ),
              ),
            ),
          ),

          // ===== 메인 이미지 영역 =====
          // - 작품 이미지가 표시되는 중앙 영역
          // - AR 버튼과 북마크 버튼이 오버레이로 배치
          Positioned(
            top: screenHeight * 0.09, // 상단 네비게이션 바 아래 여백
            left: 0,
            right: 0,
            child: Container(
              alignment: Alignment.topCenter,
              padding: EdgeInsets.only(top: screenHeight * 0.02), // 추가 상단 패딩
              child: Stack(
                children: [
                  // ===== 작품 이미지 컨테이너 =====
                  // - Figma 기준 정확한 크기: 342×473 (390×844 기준)
                  Container(
                    width: screenWidth * (342 / 390), // 정확한 비율 계산
                    height: screenHeight * (473 / 844), // 정확한 비율 계산
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.grey[200],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
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
                  // ===== AR 버튼 (이미지 중앙 오버레이) =====
                  // - 작품 이미지 위에 떠있는 AR 기능 버튼
                  Positioned(
                    top: screenHeight * 0.02,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        width: 58, // Figma 기준 정확한 크기
                        height: 30, // Figma 기준 정확한 크기
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEFDFC), // 흰색 배경
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: const Color.fromRGBO(102, 94, 94, 0.3),
                              blurRadius: 20,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'AR',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // ===== 북마크 버튼 (이미지 우상단 오버레이) =====
                  // - 작품을 북마크에 추가/제거할 수 있는 버튼
                  Positioned(
                    top: screenHeight * 0.02,
                    right: screenWidth * 0.04,
                    child: GestureDetector(
                      onTap: _handleBookmarkToggle,
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

          // ===== 드래그 가능한 설명 카드 =====
          // - 하단에서 위로 드래그하여 확장할 수 있는 작품 정보 영역
          // - 초기 크기: 화면의 38%, 최소: 38%, 최대: 85%
          DraggableScrollableSheet(
            initialChildSize: 0.38,
            minChildSize: 0.38,
            maxChildSize: 0.85,
            builder: (context, scrollController) {
              return Container(
                margin: EdgeInsets.symmetric(
                  horizontal: screenWidth * ((390 - 367) / 2 / 390), // 약 11.5px 양쪽 여백
                ),
                width: screenWidth * (367 / 390), // Figma 기준 정확한 너비 (약 94% 수준)
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF5F0),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(19.045), // Figma 기준 정확한 값
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color.fromRGBO(63, 65, 70, 0.2),
                      blurRadius: 19.045,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // ===== 드래그 핸들 =====
                    // - 사용자가 카드를 드래그할 수 있음을 나타내는 시각적 표시
                    // - V자형 SVG 아이콘 사용 (Figma 디자인 기준)
                    Padding(
                      padding: const EdgeInsets.only(
                        top: 2,
                        bottom: 0, // 드래그 핸들과 상단 컨트롤 바 사이 패딩 최소화
                      ),
                      child: Center(
                        child: SizedBox(
                          width: 30, // 1.5배 크기 (21.879 * 2)
                          height: 50, // 1.5배 크기 (38.632 * 2)
                          child: SvgPicture.asset(
                            'assets/icons/drag_v_handle.svg',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                    // ===== 상단 컨트롤 바 =====
                    // - 해설 타입 선택 드롭다운과 TTS 버튼이 있는 제어 영역
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        width: screenWidth * (340 / 390), // Figma 기준 정확한 너비
                        height: 40, // Figma 기준 정확한 높이
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0E4DE), // 상단 컨트롤 바 배경
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          children: [
                            // ===== 해설 타입 선택 드롭다운 =====
                            // - 한눈에 보는 해설, 클래식한 해설, 깊이 있는 해설 중 선택
                            Padding(
                              padding: const EdgeInsets.only(left: 6), // 왼쪽 여백 추가
                              child: Container(
                                width: 127,
                                height: 30, // Figma 기준 정확한 크기
                                decoration: BoxDecoration(
                                  color: const Color(0xFFA28F7D), // 드롭다운 배경
                                  borderRadius: BorderRadius.circular(15.907), // Figma 기준 정확한 값
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color.fromRGBO(63, 65, 70, 0.2),
                                      blurRadius: 17.675,
                                    ),
                                  ],
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: selectedDescription,
                                    dropdownColor: const Color(0xFFEAE1DC),
                                    icon: Padding(
                                      padding: const EdgeInsets.only(right: 4.27),
                                      child: SvgPicture.asset('assets/icons/dropdown_icon.svg', width: 20.7, height: 20.7),
                                    ),
                                    style: const TextStyle(
                                      color: Color(0xFFFEFDFC),
                                      fontFamily: 'Pretendard',
                                      fontSize: 14.849, // Figma 기준 정확한 크기
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: -0.247, // Figma 기준 정확한 값
                                    ),
                                     borderRadius: BorderRadius.circular(8),
                                     items: descriptionTypes.map((type) {
                                       return DropdownMenuItem<String>(
                                         value: type,
                                         child: Padding(
                                           padding: const EdgeInsets.only(left: 15), // 왼쪽 패딩 15px 추가
                                           child: Text(type),
                                         ),
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
                            ),
                            const Spacer(),
                            // ===== TTS 버튼 =====
                            // - 텍스트를 음성으로 변환하여 읽어주는 기능
                            Padding(
                              padding: const EdgeInsets.only(right: 7), // 오른쪽 여백 추가
                              child: Container(
                                width: 43, // Figma 기준 정확한 크기
                                height: 30, // Figma 기준 정확한 크기
                                decoration: BoxDecoration(
                                  color: const Color(0xFFA28F7D), // TTS 버튼 배경
                                  borderRadius: BorderRadius.circular(15.907), // Figma 기준 정확한 값
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color.fromRGBO(63, 65, 70, 0.2),
                                      blurRadius: 17.675,
                                    ),
                                  ],
                                ),
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  icon: const Icon(
                                    Icons.volume_up,
                                    color: Color(0xFFFEFDFC),
                                    size: 19, // Figma 기준 정확한 크기
                                  ),
                                  onPressed: _playTTS,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    // ===== 작품 정보 헤더 =====
                    // - 작품 제목, 작가명, 제작 연도가 표시되는 영역
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                                                     Text(
                             widget.title.replaceAll('*', ''),
                             style: const TextStyle(
                               color: Colors.black,
                               fontSize: 20,
                               fontWeight: FontWeight.bold,
                             ),
                             textAlign: TextAlign.center,
                           ),
                           const SizedBox(height: 6),
                           Text(
                             '${widget.artist.replaceAll('*', '')}, ${widget.year.replaceAll('*', '')}',
                             style: const TextStyle(
                               color: Color(0xFFB1B1B1),
                               fontSize: 14,
                               fontWeight: FontWeight.w600,
                             ),
                             textAlign: TextAlign.center,
                           ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    // ===== 작품 설명 스크롤 영역 =====
                    // - 선택된 해설 타입에 따른 작품 설명 텍스트가 표시되는 영역
                    // - 로딩 중일 때는 CircularProgressIndicator 표시
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: SingleChildScrollView(
                          controller: scrollController,
                          child: isLoadingDescription
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 3,
                                    ),
                                  ),
                                )
                              : Text(
                                  currentDescription.replaceAll('*', ''),
                                  style: const TextStyle(
                                    color: Color(0xFF343231),
                                    fontSize: 14,
                                    height: 1.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.justify,
                                ),
                        ),
                      ),
                                         ),
                   ],
                 ),
               );
             },
           ),

           // ===== 하단 네비게이션 바 =====
           // - 다른 페이지와 동일한 하단 탭 바
           Positioned(
             bottom: 0,
             left: 0,
             right: 0,
             child: BottomNavBarWidget(currentIndex: 1), // 현재 인덱스는 1 (카메라 탭)
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
      debugPrint('❗ 토큰 또는 유저 ID가 없습니다. 로그인 필요');
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('로그인이 필요합니다.')),
        );
      }
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
      
      // Authorization 헤더 추가
      request.headers['Authorization'] = 'Bearer $token';

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
  if (token == null || userId == null) {
    debugPrint('❗ 토큰 또는 유저 ID가 없습니다. 북마크 상태 확인 불가');
    return;
  }

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
