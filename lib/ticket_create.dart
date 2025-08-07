import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'ticket_screen.dart'; // TicketCard 불러오기
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'utils/auth_storage.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:math';

class TicketCreateScreen extends StatefulWidget {
  final String imageUrl;
  final String title;
  final String artist;
  final String place;
  final String createdAt; 

  const TicketCreateScreen({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.artist,
    required this.place,
    required this.createdAt,
  });
  
  @override
  State<TicketCreateScreen> createState() => _TicketCreateScreenState();
}

class _TicketCreateScreenState extends State<TicketCreateScreen> {
  late Color selectedColor;
  bool isDarkText = false; // T 버튼 상태 (false=흰색 글씨, true=검은 글씨)

  List<Color> recommendedColors = [];
  TextEditingController _placeController = TextEditingController();
List<dynamic> searchResults = [];
String? selectedPlace; // 최종 장소 값
final DraggableScrollableController _sheetController = DraggableScrollableController();


  @override
  void initState() {
    super.initState();
    selectedColor = const Color(0xFFFFFFFF);
    _loadRecommendedColors();
  }

  String get todayDateFormatted {
  return DateFormat('yyyy.MM.dd').format(DateTime.now());
}

  Future<void> _loadRecommendedColors() async {
  final token = await getJwtToken();
  final uri = Uri.parse('http://43.203.23.173:8080/api/Ticketcolor/recommend-color');

  try {
    // 1. 이미지 다운로드
    final response = await http.get(Uri.parse(widget.imageUrl));
    if (response.statusCode != 200) {
      print('이미지 다운로드 실패');
      return;
    }

    // 2. 임시 파일로 저장
    final tempDir = await getTemporaryDirectory();
  final random = Random().nextInt(999999);
  final imagePath = '${tempDir.path}/ticket_$random.jpg';
    final file = File(imagePath);
    await file.writeAsBytes(response.bodyBytes);

    // 3. multipart 요청 생성
    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(await http.MultipartFile.fromPath('image', imagePath));

    final streamedResponse = await request.send();
    final responseData = await http.Response.fromStream(streamedResponse);

    if (responseData.statusCode == 200) {
      final data = jsonDecode(responseData.body);
      final List<dynamic> palette = data['palette'];
      setState(() {
        recommendedColors.clear();
        recommendedColors.addAll(
          palette.map<Color>((rgb) => Color.fromRGBO(rgb[0], rgb[1], rgb[2], 1)),
        );
        selectedColor = recommendedColors.first;
      });
    } else {
      print('색상 추천 실패: ${responseData.statusCode}');
    }
  } catch (e) {
    print('색상 추천 예외: $e');
  }
}

  void _openColorPicker() {
    Color tempColor = selectedColor;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: tempColor,
            onColorChanged: (color) {
              tempColor = color;
            },
          ),
        ),
        actions: [
          TextButton(
            child: const Text("취소"),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text("적용"),
            onPressed: () {
              setState(() {
                selectedColor = tempColor;
                if (!recommendedColors.contains(tempColor)) {
                  recommendedColors.add(tempColor);
                }
              });
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _completeTicket() async {
  await _submitTicket();

  // 티켓 목록 화면으로 이동
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (context) => const TicketScreen()),
  );
}

  Future<void> _submitTicket() async {
  final token = await getJwtToken();
  final userId = await getUserId();

  if (token == null || userId == null) {
    print('인증 정보가 없습니다.');
    return;
  }

  final uri = Uri.parse('http://43.203.23.173:8080/ticket/add');

  final response = await http.post(
    uri,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode({
      "ticketId": 0,
      "userId": userId,
      "createdAt": widget.createdAt,
      "ticketImage": widget.imageUrl, // ← string URL
      "title": widget.title,
      "artist": widget.artist,
      "place": selectedPlace ?? '',

/*
      "ticketColor": '#${selectedColor.value.toRadixString(16).substring(2)}',
      "textColor": isDarkText ? "#000000" : "#FFFFFF",
      */
    }),
  );

  if (response.statusCode == 200 || response.statusCode == 201) {
    print("✅ 티켓 추가 성공");
  } else {
    print("❌ 티켓 추가 실패: ${response.statusCode}");
    print("응답 내용: ${response.body}");
  }
}

Future<void> _searchPlace(String query) async {
  final token = await getJwtToken();
  final uri = Uri.parse('http://43.203.23.173:8080/exhibition/search/place?place=$query');

  try {
    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'accept': '*/*',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> results = jsonDecode(utf8.decode(response.bodyBytes));
      setState(() {
        searchResults = results;
      });

      // 시트 자동 위로 올리기
      _sheetController.animateTo(
        0.6,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      print('전시관 검색 실패: ${response.statusCode}');
    }
  } catch (e) {
    print('전시관 검색 오류: $e');
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFB1B1B1), // 회색 배경
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60), // 높이
        child: AppBar(
          backgroundColor: const Color(0xFFFFFDFC), // 상단바 배경
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            "티켓 만들기",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          centerTitle: true,
          actions: [
  Padding(
    padding: const EdgeInsets.only(right: 16),
    child: SizedBox(
      width: 52,
      height: 28,
      child: InkWell(
        borderRadius: BorderRadius.circular(23),
        onTap: _completeTicket,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF837670),
            borderRadius: BorderRadius.circular(23),
          ),
          alignment: Alignment.center,
          child: const Text(
            "완료",
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ),
    ),
  ),
],
        ),
      ),
      body: Stack(
        children: [
          // 티켓 미리보기
          Align(
            alignment: Alignment.topCenter,
              child: Transform.scale(
                scale: 0.9,
                child: TicketCard(
                  ticketImage: widget.imageUrl,
                  title: widget.title,
                  artist: widget.artist,
                  date: todayDateFormatted,
                  location: selectedPlace ?? '',
                  backgroundColor: selectedColor,
                  textColor: isDarkText ? Colors.black : Colors.white,
                ),
              ),
            ),

          // 하단 드래거블 시트
          DraggableScrollableSheet(
            controller: _sheetController,
            initialChildSize: 0.35,
            minChildSize: 0.35,
            maxChildSize: 0.6,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFFFFDFC), // 시트 배경색
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 23), // 좌우 여백 23
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),
                        // 드래그 핸들
                        Center(
                          child: Container(
                            width: 40,
                            height: 2.5,
                            decoration: BoxDecoration(
                              color: const Color(0xFFB1B1B1),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40), // 시트 상단 ↔ 검색창

                        // 검색창
                        TextField(
                          controller: _placeController,
  onSubmitted: (value) {
    FocusScope.of(context).unfocus(); // 키보드 내리기
    _searchPlace(value);
  },
                          decoration: InputDecoration(
                            hintText: "방문했던 전시관을 검색하세요",
                            hintStyle: const TextStyle(color: Color(0xFFB1B1B1)),
                            suffixIcon: GestureDetector(
  onTap: () {
    FocusScope.of(context).unfocus(); // 키보드 닫기
    _searchPlace(_placeController.text); // 현재 입력값으로 검색 실행
  },
  child: selectedPlace != null
      ? const Icon(Icons.check_circle, color: Colors.green)
      : const Icon(Icons.search, color: Color(0xFFB1B1B1)),
),
                            filled: true,
                            fillColor: const Color(0xFFFEF6F2),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 36), // 검색창 ↔ 안내문구

                    Row(
  children: [
    SvgPicture.asset(
      'assets/images/bulb_on.svg', // 전구 아이콘
      width: 14,
      height: 14,
    ),
    const SizedBox(width: 2.5), // 아이콘 ↔ 텍스트 간격 조절
    const Text(
      "Tip 작품과 어울리는 티켓 색상을 추천해드려요.",
      style: TextStyle(fontSize: 14, color: Color(0xFF837670)),
    ),
  ],
),

                        const SizedBox(height: 12), // 안내문구 ↔ 색상 버튼

                        // 색상 버튼
                        Row(
                          children: [
                            for (int i = 0; i < recommendedColors.take(5).length; i++)
                              Container(
        margin: EdgeInsets.only(right: i == 4 ? 0 : 8), // 버튼 간격만 적용
                                child: GestureDetector(
                                  onTap: () => setState(() => selectedColor = recommendedColors[i]),
                                  child: Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: recommendedColors[i],
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                  ),
                                ),
                              ),
                            // + 버튼
    GestureDetector(
      onTap: _openColorPicker,
      child: Container(
        margin: const EdgeInsets.only(left: 8), // 앞 버튼과 간격 8
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFFD9D9D9),
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Icon(Icons.add, size: 24, color: Color(0xFFB1B1B1)),
      ),
    ),
  ],
),

                        const SizedBox(height: 16), // 색상 버튼 ↔ T 버튼

                        // T 버튼
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => setState(() => isDarkText = false),
                              child: Container(
                                width: 50,
                                height: 24,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: const Text("T",
                                    style: TextStyle(color: Colors.white, fontSize: 16)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => setState(() => isDarkText = true),
                              child: Container(
                                width: 50,
                                height: 24,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(color: Colors.grey),
                                ),
                                child: const Text("T",
                                    style: TextStyle(color: Colors.black, fontSize: 16)),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 30), // 마지막 여백
                        // 검색 결과 리스트 아래 여백 추가 + Scroll 가능하도록 수정
if (searchResults.isNotEmpty)
  SizedBox(
    height: 150, // 최대 높이 제한 (스크롤 영역 확보)
    child: ListView.builder(
      shrinkWrap: true,
      itemCount: searchResults.length,
      itemBuilder: (context, index) {
        final item = searchResults[index];
        return ListTile(
          title: Text(item['place'] ?? ''),
          onTap: () {
            setState(() {
              selectedPlace = item['place'];
              _placeController.text = selectedPlace!;
              searchResults.clear(); // 선택 후 리스트 숨기기
            });
          },
        );
      },
    ),
  ),

if (_placeController.text.isNotEmpty && searchResults.isEmpty)
  const Padding(
    padding: EdgeInsets.only(top: 8),
    child: Text(
      '검색 결과가 없습니다.',
      style: TextStyle(color: Colors.grey),
    ),
  ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}