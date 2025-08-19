import 'package:flutter/material.dart';
import '../mypage/mypage_bookmark.dart';
import '../app_bar_widget.dart';
import 'dart:io';
import '../bottom_nav_bar.dart';
import 'dart:convert';
import 'tts_service.dart';
import 'package:audioplayers/audioplayers.dart';
import '../camera/main_camera_page.dart';
import 'package:http/http.dart' as http;
import '../utils/auth_storage.dart';
import 'package:flutter/services.dart';

// 사용자의 저장된 난이도를 가져오는 함수
Future<String?> getUserDifficulty(int userId, String token) async {
  try {
    print('🔍 사용자 난이도 조회 시작: userId=$userId');
    
    // 로컬 저장소에서 난이도 확인 (임시 해결책)
    final localDifficulty = await storage.read(key: 'user_difficulty');
    if (localDifficulty != null) {
      print('✅ 로컬에서 난이도 찾음: $localDifficulty');
      return localDifficulty;
    }
    
    // 서버에서 난이도 조회 시도 (API가 존재하는 경우)
    try {
      final difficultyResponse = await http.get(
        Uri.parse('http://43.203.23.173:8080/user/difficulty/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      
      print('난이도 조회 응답: ${difficultyResponse.statusCode}');
      if (difficultyResponse.statusCode == 200) {
        final data = json.decode(difficultyResponse.body);
        print('난이도 데이터: $data');
        final difficulty = data['defaultDifiiculty'] ?? data['level'];
        if (difficulty != null) {
          // 로컬에 저장
          await storage.write(key: 'user_difficulty', value: difficulty);
          return difficulty;
        }
      } else {
        print('❌ 난이도 조회 실패: ${difficultyResponse.statusCode}');
        print('응답 내용: ${difficultyResponse.body}');
      }
    } catch (e) {
      print('❌ 서버 난이도 조회 에러: $e');
    }
    
    // 기본값 반환
    print('⚠️ 난이도 정보를 찾을 수 없어 기본값 사용: NORMAL');
    return 'NORMAL';
  } catch (e) {
    print('❌ 난이도 조회 에러: $e');
    return 'NORMAL'; // 기본값
  }
}

class DescriptionScreen extends StatefulWidget {
  final String title;
  final String artist;
  final String year;
  final String description;
  final String imagePath;
  final String? imageUrl;
  final String? jwtToken;
  final ScrollController scrollController;
  final bool fromBookmark;

  const DescriptionScreen({
    super.key,
    required this.title,
    required this.artist,
    required this.year,
    required this.description,
    required this.imagePath,
    this.imageUrl,
    this.jwtToken,
    required this.scrollController,
    this.fromBookmark = false,
  });

  @override
  State<DescriptionScreen> createState() => _DescriptionScreenState();
}

class _DescriptionScreenState extends State<DescriptionScreen> {
  static const MethodChannel _unityChannel = MethodChannel('com.example.musai_f/unity_ar');

  Future<void> _sendJwtToUnity() async {
    final token = widget.jwtToken;
    if (token == null || token.isEmpty) {
      debugPrint('[AR] jwtToken 없음 — Unity 전송 스킵');
      return;
    }
    try {
      await _unityChannel.invokeMethod('SetJwtToken', token);
      debugPrint('[AR] JWT 토큰 Unity로 전송 성공: $token');
    } catch (e) {
      debugPrint('[AR] JWT 토큰 Unity 전송 실패: $e');
    }
  }

  String? token;
  int? userId;
  bool isBookmarked = false;
  int? bookmarkId;
  String selectedDescription = '클래식한 해설';  // 기본값 설정
  String currentDescription = ''; // 현재 표시되는 설명
  bool isLoadingDescription = false; // 설명 로딩 상태
  String? userDifficulty; // 사용자의 저장된 난이도

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
      await _loadUserDifficulty();   // 사용자 난이도 로드
    }
  }

  // 사용자 난이도 로드
  Future<void> _loadUserDifficulty() async {
    if (token != null && userId != null) {
      print('사용자 난이도 로드 시작');
      final difficulty = await getUserDifficulty(userId!, token!);
      print('조회된 난이도: $difficulty');
      
      if (mounted) {
        setState(() {
          userDifficulty = difficulty;
          // 사용자의 저장된 난이도에 따라 드롭다운 기본값 설정
          if (difficulty != null) {
            print('난이도에 따른 드롭다운 설정: $difficulty');
            switch (difficulty) {
              case 'EASY':
                selectedDescription = '한눈에 보는 해설';
                print('✅ 쉬운 해설로 설정');
                break;
              case 'NORMAL':
                selectedDescription = '클래식한 해설';
                print('✅ 클래식한 해설로 설정');
                break;
              case 'HARD':
                selectedDescription = '깊이 있는 해설';
                print('✅ 깊이 있는 해설로 설정');
                break;
              default:
                print('알 수 없는 난이도: $difficulty');
            }
          } else {
            print('사용자 난이도가 null입니다. 기본값 사용');
          }
        });
      }
    } else {
      print('토큰 또는 userId가 null입니다. token=$token, userId=$userId');
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
          AppBarWidget(
            showBackButton: true,
            onBackPressed: () {
              if (widget.fromBookmark == true) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => BookmarkScreen()),
                );
              } else {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const MusaiHomePage()),
                );
              }
            },
          ),

          // ===== 메인 이미지 영역 =====
          Positioned(
            top: kToolbarHeight + MediaQuery.of(context).padding.top + screenHeight * 0.01,
            left: 0,
            right: 0,
            child: Container(
              alignment: Alignment.topCenter,
              child: Stack(
                children: [
                  // ===== 작품 이미지 컨테이너 =====
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
                  Positioned(
                    top: screenHeight * 0.02,
                    left: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () async {
                        await _sendJwtToUnity();
                      },
                      child: Center(
                        child: Container(
                          width: screenWidth * 0.15,
                          height: screenHeight * 0.04,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEFDFC),
                            borderRadius: BorderRadius.circular(20),
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
                                color: Color(0xFF343231),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // ===== 북마크 버튼 (이미지 우상단 오버레이) =====
                  Positioned(
                    top: screenHeight * 0.02,
                    right: screenWidth * 0.04,
                    child: GestureDetector(
                      onTap: _handleBookmarkToggle,
                      child: Icon(
                        isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                        color: Color(0xFFFEFDFC),
                        size: screenHeight * 0.04,
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
        horizontal: screenWidth * ((390 - 367) / 2 / 390),
      ),
      width: screenWidth * (367 / 390),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF5F0),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color.fromRGBO(63, 65, 70, 0.2),
            blurRadius: 19.045,
          ),
        ],
      ),
      child: SingleChildScrollView(
        controller: scrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 드래그 핸들
            Padding(
              padding: EdgeInsets.only(
                top: screenHeight * 0.015,
                bottom: screenHeight * 0.015,
              ),
              child: Container(
                width: screenWidth * 0.10,   
                height: screenHeight * 0.005, 
                decoration: BoxDecoration(
                  color: const Color(0xFFB1B1B1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // 해설 선택 드롭다운 + TTS 버튼
            Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05), // 20/390
              child: Container(
                height: screenHeight * 0.05,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0E4DE),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Padding(
                      padding: EdgeInsets.only(left: screenWidth * 0.02), 
                      child: Container(
                        width: screenWidth * 0.36,
                        height: screenHeight * 0.036, // 30/844
                        decoration: BoxDecoration(
                          color: const Color(0xFFA28F7D),
                          borderRadius: BorderRadius.circular(15.907),
                          boxShadow: [
                            BoxShadow(
                              color: const Color.fromRGBO(63, 65, 70, 0.2),
                              blurRadius: 17.675,
                            ),
                          ],
                        ),
                        child: DropdownButtonHideUnderline(
                          child: Padding(
                            padding: EdgeInsets.only(right: screenWidth * 0.015, left: screenWidth * 0.03), //이것?
                            child: DropdownButton<String>(
                              value: selectedDescription,
                              dropdownColor: const Color(0xFFA28F7D),
                              isExpanded: true,
                              underline: const SizedBox(),
                              icon: const SizedBox(),
                              style: TextStyle(
                                color: const Color(0xFFFEFDFC),
                                fontSize: screenWidth * 0.036, // 14/390
                                fontWeight: FontWeight.w500,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              items: descriptionTypes.map((type) {
                                return DropdownMenuItem<String>(
                                  value: type,
                                  child: Padding(
                                    padding: EdgeInsets.only(left: screenWidth * 0.03), 
                                    child: Text(type),
                                  ),
                                );
                              }).toList(),
                              selectedItemBuilder: (BuildContext context) {
                                return descriptionTypes.map((type) {
                                  return Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        type,
                                        style: TextStyle(
                                          color: const Color(0xFFFEFDFC),
                                          fontSize: screenWidth * 0.036, // 14/390
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const Icon(
                                        Icons.keyboard_arrow_down,
                                        color: Color(0xFFFEFDFC),
                                      ),
                                    ],
                                  );
                                }).toList();
                              },
                                                             onChanged: (value) {
                                 if (value != null && value != selectedDescription) {
                                   setState(() {
                                     selectedDescription = value;
                                   });
                                   // 선택한 해설 타입으로 새로운 설명 가져오기
                                   _fetchNewDescription(value);
                                 }
                               },
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Padding(
                      padding: EdgeInsets.only(right: screenWidth * 0.02), 
                      child: Container(
                        width: screenWidth * 0.113, // 44/390
                        height: screenHeight * 0.036, // 30/844
                        decoration: BoxDecoration(
                          color: const Color(0xFFA28F7D),
                          borderRadius: BorderRadius.circular(15.907),
                          boxShadow: [
                            BoxShadow(
                              color: const Color.fromRGBO(63, 65, 70, 0.2),
                              blurRadius: 17.675,
                            ),
                          ],
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            Icons.volume_up,
                            color: const Color(0xFFFEFDFC),
                            size: screenWidth * 0.049,
                          ),
                          onPressed: _playTTS,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: screenHeight * 0.025),

            // 작품 제목, 작가, 연도
            Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05), 
              child: Column(
                children: [
                  Text(
                    widget.title.replaceAll('*', ''),
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: screenWidth * 0.05,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  Text(
                    '${widget.artist.replaceAll('*', '')}, ${widget.year.replaceAll('*', '')}',
                    style: TextStyle(
                      color: const Color(0xFFB1B1B1),
                      fontSize: screenWidth * 0.031, // 12/390
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            SizedBox(height: screenHeight * 0.03), 

            // 해설 설명 텍스트
            Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05), 
              child: isLoadingDescription
                  ? Center(
                      child: Padding(
                        padding: EdgeInsets.all(screenWidth * 0.05),
                        child: const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      ),
                    )
                  : Text(
                      currentDescription.replaceAll('*', ''),
                      style: TextStyle(
                        color: const Color(0xFF343231),
                        fontSize: screenWidth * 0.04,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.justify,
                    ),
            ),

            SizedBox(height: screenHeight * 0.12), 
          ],
        ),
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

      final deleteUrl = 'http://43.203.23.173:8080/bookmark/delete/$bookmarkId';
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

  // 사용자의 저장된 난이도에 따른 level 매핑
  String _getLevelForDescriptionType(String descriptionType) {
    print('🎯 난이도 매핑 시작: descriptionType=$descriptionType, userDifficulty=$userDifficulty');
    
    // 드롭다운에서 해설 타입을 선택한 경우, 해당 해설 타입에 맞는 난이도 사용
    print('📝 선택된 해설 타입에 따른 난이도 매핑');
    switch (descriptionType) {
      case '한눈에 보는 해설':
        print('📝 쉬운 해설로 매핑: 하');
        return '하';
      case '클래식한 해설':
        print('📝 클래식한 해설로 매핑: 중');
        return '중';
      case '깊이 있는 해설':
        print('📝 깊이 있는 해설로 매핑: 상');
        return '상';
      default:
        print('⚠️ 알 수 없는 해설 타입: $descriptionType, 기본값 사용: 중');
        return '중';
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
      // 사용자의 저장된 난이도에 따른 level 결정
      final level = _getLevelForDescriptionType(descriptionType);
      print('🎯 선택된 난이도: $level');
      
      // 이미지 파일을 업로드하여 AI 서버에 전달하고 분석 결과를 반환하는 API 호출
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('http://43.203.23.173:8080/recog/analyzeAndRegister'),
      );
      request.files.add(await http.MultipartFile.fromPath('file', widget.imagePath));
      request.fields['level'] = level;
      
      // Authorization 헤더 추가
      request.headers['Authorization'] = 'Bearer $token';

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      print('AI 해설 API 응답: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = json.decode(responseBody);
        final newDescription = data['gemini_result']['description'] ?? '';
        
        setState(() {
          currentDescription = newDescription;
          isLoadingDescription = false;
        });
        print('✅ 새로운 해설 로드 완료');
      } else {
        print('❌ AI 해설 요청 실패: ${response.statusCode}');
        print('응답 내용: $responseBody');
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
      print('❌ AI 해설 요청 에러: $e');
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
