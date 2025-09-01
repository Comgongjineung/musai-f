import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'login_profile.dart';
import '../utils/auth_storage.dart';
import '../homescreen/home_screen.dart';

class PreferencePage extends StatefulWidget {
  const PreferencePage({super.key});

  @override
  State<PreferencePage> createState() => _PreferencePageState();
}

class _PreferencePageState extends State<PreferencePage> {
  late List<ArtStyle> _shuffled;        // 24개 랜덤 정렬
  int _round = 0;                        // 0,1,2 (총 3단계)
  ArtStyle? _pickedInThisRound;          // 현재 단계에서 사용자가 고른 항목
  late Map<String, int> _scores;         // 사조별 점수

  // 다중 사조는 ',', '·', '&', '+' 로만 구분하세요. (예: "르네상스+바로크", "르네상스 & 바로크")
  List<String> _splitStyles(String raw) {
    final parts = raw.split(RegExp(r"\s*[,·&+]\s*"));
    return parts.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }

  @override
  void initState() {
    super.initState();
    _initStylesAndScores();              // 24개 정의 + 랜덤 + 점수맵 0으로 초기화
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final screenWidth  = size.width;
    final screenHeight = size.height;

    // 반응형 간격/타일 높이 (844 기준: gap≈18, tile≈96)
    final vGap = screenHeight * 0.02; // 세로 간격 ≈18px
    final tileH = screenHeight * 0.114; // 타일 높이 ≈96px
    final stepItems = _current8(); // 이번 단계의 8개

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
    );

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: screenHeight * 0.03),
                  _stepIndicator(),
                  SizedBox(height: screenHeight * 0.038),
                  _Title(context),
                  SizedBox(height: screenHeight * 0.032),
                  SizedBox(
                    height: 4 * tileH + 3 * vGap, // 2x4 고정 높이(반응형)
                    child: _buildGrid(
                      context: context,
                      items: stepItems,
                      vGap: vGap,
                      tileHeight: tileH,
                      scrollable: false,
                    ),
                  ),
                  const Spacer(),
                  _buttonSection(context, screenWidth, screenHeight),
                ],
              );
            },
          ),
        ),
      ),
    );
  }


  // 24개 스타일 초기화 + 셔플 + 점수맵 0으로 세팅
  void _initStylesAndScores() {
    final seed = _artStylesSeed();
    _shuffled = List<ArtStyle>.from(seed)..shuffle();
    final allKeys = <String>{};
    for (final a in seed) {
      allKeys.addAll(_splitStyles(a.name));
    }
    _scores = { for (final k in allKeys) k : 0 };
  }

  // 현재 단계의 8개 (0~7, 8~15, 16~23)
  List<ArtStyle> _current8() {
    final start = _round * 8;
    final end = start + 8;
    return _shuffled.sublist(start, end);
  }


  // 제목/설명
  Widget _Title(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('좋아하는 작품을\n자유롭게 골라보세요.',
            style: TextStyle(
              color: Color(0xFF343231),
              fontSize: 24,
              fontWeight: FontWeight.bold,
              height: 1.2,
            )),
        SizedBox(height: 8),
        Text('이를 바탕으로 취향에 맞는 작품을 추천해드려요.',
            style: TextStyle(
              color: Color(0xFF706B66),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            )),
      ],
    );
  }

  // 2x4 그리드(패딩 제외 딱 맞게), 타일 탭 시 선택 처리
  Widget _buildGrid({
    required BuildContext context,
    required List<ArtStyle> items,
    required double vGap,
    required double tileHeight,
    bool scrollable = true,
  }) {
    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;

    return GridView.builder(
      physics: scrollable ? const BouncingScrollPhysics() : const NeverScrollableScrollPhysics(),
      shrinkWrap: !scrollable,
      itemCount: items.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: vGap,
        crossAxisSpacing: screenWidth * 0.05, // 칼럼 간격(대략 16px~)
        mainAxisExtent: tileHeight,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        final isPicked = _pickedInThisRound?.name == item.name;
        return _buildTile(
          context: context,
          item: item,
          isPicked: isPicked,
          tileHeight: tileHeight,
          onTap: () => _onPick(item),
        );
      },
    );
  }

  // 개별 타일
  Widget _buildTile({
    required BuildContext context,
    required ArtStyle item,
    required bool isPicked,
    required double tileHeight,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        height: tileHeight,
        child: Container(
          decoration: BoxDecoration(
            //color: const Color(0xFFE9E8E7),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isPicked ? const Color(0xFFC06062) : Colors.transparent,
              width: isPicked ? 2 : 0,
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: _buildStyleImage(item),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: StepIndicator(current: _round + 2), // 0→2, 1→3, 2→4
    );
  }
  
  // 실제 이미지 위젯
  Widget _buildStyleImage(ArtStyle s) {
    return Image(
      image: s.imageProvider,
      fit: BoxFit.cover,
      errorBuilder: (_, Object error, __) {
        print('⚠️ asset load failed: ${s.imagePath}  error=$error');
        return const ColoredBox(color: Color(0xFFB1B1B1));
      },
    );
  }

  // 하단 저장/진행 버튼 섹션 (디자인/동작 반영)
  Widget _buttonSection(BuildContext context, double screenWidth, double screenHeight) {
    final enabled = _pickedInThisRound != null;
    final buttonText = (_round < 2) ? '다음으로' : '시작하기';
    return Column(
      children: [
        ElevatedButton(
          onPressed: enabled
              ? () async {
                  await _onNext();
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF837670),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            minimumSize: Size.fromHeight(screenHeight * 0.07),
          ),
          child: Text(
            buttonText,
            style: TextStyle(
              color: const Color(0xFFFEFDFC),
              fontSize: screenWidth * 0.05,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        SizedBox(height: screenHeight * 0.035),
      ],
    );
  }

  // --- 유저 인터랙션 핸들러 ---
  void _onPick(ArtStyle item) {
    if (_pickedInThisRound?.name == item.name) return;
    setState(() {
      _pickedInThisRound = item;
    });
  }

  Future<void> _onNext() async {
    if (_pickedInThisRound == null) return;

    // 선택 시, 이름을 분해하여 포함된 모든 사조에 +1
    for (final key in _splitStyles(_pickedInThisRound!.name)) {
      _scores[key] = (_scores[key] ?? 0) + 1;
    }

    // 다음 단계로
    if (_round < 2) {
      setState(() {
        _round += 1;
        _pickedInThisRound = null;
      });
    } else {
      // 3단계 완료 → 전송 후 홈으로 이동
      await _submitPreferences();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  // --- 서버 전송 ---
  Future<void> _submitPreferences() async {
    try {
      final storedUserId = await getUserId();
      if (storedUserId == null || storedUserId.toString().isEmpty) {
        if (!mounted) return;
        print("유저 아이디를 불러올 수 없습니다. 다시 로그인해 주세요.");
        return;
      }
      final token = await getJwtToken();
      if (token == null || token.isEmpty) {
        if (!mounted) return;
        print("인증 토큰을 불러올 수 없습니다. 다시 로그인해 주세요.");
        return;
      }
      
      final filtered = <String, int>{  // 점수 0 초과인 항목만 전송
        for (final e in _scores.entries)
          if (e.value > 0) e.key: e.value,
      };
      if (filtered.isEmpty) {
        print("전송할 선호도가 없습니다. (모든 점수 0)");
        return;
      }
      final url = Uri.parse('http://43.203.23.173:8080/preference/$storedUserId');

      final body = filtered;

      final res = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(body),
      );

      if (!mounted) return;

      if (res.statusCode == 200) {
        print("선호도 저장 성공 (200): ${jsonEncode(body)}");
      } else {
        print("선호도 저장 실패 (code: ${res.statusCode}, body: ${jsonEncode(body)})");
      }
    } catch (e) {
      if (!mounted) return;
      print("네트워크 오류: $e");
    }
  }

  // --- 데이터 정의부, image path ---
  // 다중 사조는 '+' 로 구분함 (예: "르네상스 + 바로크")
  List<ArtStyle> _artStylesSeed() {
    const entries = <Map<String, String>>[
      {"name": "로코코", "image": "assets/styles/rococo.jpg"}, 
      {"name": "바로크", "image": "assets/styles/baroque.jpg"}, 
      {"name": "팝아트", "image": "assets/styles/pop_art.jpg"}, 
      {"name": "남아시아", "image": "assets/styles/south_asia.jpg"},
      {"name": "낭만주의 + 인상주의", "image": "assets/styles/romanticism.jpg"}, 
      {"name": "동아시아", "image": "assets/styles/east_asia.jpg"}, 
      {"name": "르네상스 + 바로크", "image": "assets/styles/renaissance.jpg"}, 
      {"name": "사실주의", "image": "assets/styles/realism.jpg"}, 
      {"name": "아르누보", "image": "assets/styles/art_nouveau.jpg"}, 
      {"name": "인상주의", "image": "assets/styles/impressionism.jpg"}, 
      {"name": "입체주의 + 표현주의", "image": "assets/styles/cubism.jpg"}, 
      {"name": "표현주의", "image": "assets/styles/expressionism.jpg"},
      {"name": "현대미술", "image": "assets/styles/contemporary.jpg"}, 
      {"name": "고대 미술", "image": "assets/styles/ancient.jpg"}, 
      {"name": "중세 미술", "image": "assets/styles/medieval.jpg"},
      {"name": "동남아시아", "image": "assets/styles/eastsouth_asia.jpg"},
      {"name": "신고전주의 + 낭만주의", "image": "assets/styles/neoclassicism.jpg"}, 
      {"name": "중앙아시아", "image": "assets/styles/central_asia.jpg"},
      {"name": "초현실주의", "image": "assets/styles/surrealism.jpg"}, 
      {"name": "추상표현주의", "image": "assets/styles/abstract_expressionism.jpg"}, 
      {"name": "후기 인상주의 + 입체주의", "image": "assets/styles/post_impressionism.jpg"}, 
      {"name": "서아시아 / 중동", "image": "assets/styles/westasia_middleeast.jpg"},
      {"name": "인상주의 + 후기 인상주의", "image": "assets/styles/impressionism2.jpg"},
      {"name": "미래주의", "image": "assets/styles/futurism.jpg"},
    ];

    return entries.map((e) => ArtStyle(name: e['name']!, imagePath: e['image']!)).toList();
  }
}

// 데이터 모델 
class ArtStyle {
  final String name;
  final String imagePath;

  ArtStyle({required this.name, required this.imagePath});

  ImageProvider get imageProvider {
    return AssetImage(imagePath);
  }
}