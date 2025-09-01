import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'ticket_screen.dart'; // TicketCard 불러오기
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/auth_storage.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:http_parser/http_parser.dart';

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
  final GlobalKey _captureKey = GlobalKey();     // 캡처용 키
  bool _saving = false;                          // 저장 로딩

  List<Color> recommendedColors = [];
  TextEditingController _placeController = TextEditingController();
List<dynamic> searchResults = [];
String? selectedPlace; // 최종 장소 값
final DraggableScrollableController _sheetController = DraggableScrollableController();


  @override
  void initState() {
    super.initState();
    selectedColor = const Color(0xFF212121);
    _loadRecommendedColors();
  }

  String get todayDateFormatted {
  return DateFormat('yyyy.MM.dd').format(DateTime.now());
}

  Future<void> _loadRecommendedColors() async {
  final token = await getJwtToken();
  if (token == null) {
    print('❌ 토큰 없음');
    return;
  }
  final uri = Uri.parse('http://43.203.23.173:8080/ticket/color');

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
      print('🎨 색상 추천 응답: $data');

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
        backgroundColor: const Color(0xFFFFFDFC),
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
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF343231),
              textStyle: const TextStyle(
                fontSize: 16,
              ),
            ),
            child: const Text("취소"),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF343231),
              textStyle: const TextStyle(
                fontSize: 16,
              ),
            ),
            child: const Text("적용"),
            onPressed: () {
              setState(() {
                selectedColor = tempColor.withOpacity(1.0);
                if (!recommendedColors.contains(tempColor)) {
                  recommendedColors.add(tempColor.withOpacity(1.0)); // 팔레트에도 불투명으로
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
  try {
    setState(() => _saving = true);

    // 1) PNG 캡처
    final png = await _captureTicketPng(pixelRatio: 2.0);

    // 2) 서버 업로드 → URL 획득
    final ticketPngUrl = await _uploadTicketPng(png);

    // 3) 티켓 등록 (ticketImage = PNG URL)
    await _submitTicket(ticketPngUrl);

    // 4) 티켓 목록 화면으로 이동
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const TicketScreen()),
    );
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('티켓 저장/업로드 실패: $e')),
    );
  } finally {
    if (mounted) setState(() => _saving = false);
  }
}


  Future<void> _submitTicket(String ticketPngUrl) async {
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
      "ticketImage": ticketPngUrl,
      "title": widget.title,
      "artist": widget.artist,
      "place": selectedPlace ?? '',
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

Future<Uint8List> _captureTicketPng({double pixelRatio = 2.0}) async {
  final boundary = _captureKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
  final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  return byteData!.buffer.asUint8List();
}

Future<String> _uploadTicketPng(Uint8List pngBytes) async {
  final token = await getJwtToken();
  if (token == null) throw Exception('토큰 없음');

  final uri = Uri.parse('http://43.203.23.173:8080/ticket/upload');

  final req = http.MultipartRequest('POST', uri)
    ..headers['accept'] = '*/*'
    ..headers['Authorization'] = 'Bearer $token'
    ..files.add(
      http.MultipartFile.fromBytes(
        'file',
        pngBytes,
        filename: 'ticket.png',
        contentType: MediaType('image', 'png'),
      ),
    );

  final streamed = await req.send();
  final res = await http.Response.fromStream(streamed);

  if (res.statusCode == 200) {
    // 서버가 순수 문자열(URL) 반환하므로 따옴표/공백 정리
    return res.body.trim().replaceAll('"', '');
  }
  throw Exception('업로드 실패: ${res.statusCode} ${res.body}');
}



  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: const Color(0xFFB1B1B1), // 회색 배경
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(screenWidth * 0.14), // 높이 (was 60)
        child: AppBar(
          backgroundColor: const Color(0xFFFFFDFC), // 상단바 배경
          elevation: 0,
          leading: Padding(
            padding: EdgeInsets.only(left: screenWidth * 0.06),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF343231)),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          title: Text(
            "티켓 만들기",
            style: TextStyle(
              fontSize: screenWidth * 0.05,
              fontWeight: FontWeight.w600,
              color: Color(0xFF343231),
            ),
          ),
          centerTitle: true,
          actions: [
  Padding(
    padding: EdgeInsets.only(right: screenWidth * 0.06),
    child: SizedBox(
      width: 52,
      height: 28,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: _saving ? null : _completeTicket, // 연타 방지
        child: Container(
          decoration: BoxDecoration(
            color: _saving ? const Color(0xFFB1B1B1) : const Color(0xFF837670),
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.center,
          child: _saving
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )                             // 로딩 표시
          : const Text(
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
            child: RepaintBoundary(            // 추가
    key: _captureKey,    
                child: TicketCard(
                  ticketImage: widget.imageUrl,
                  title: widget.title,
                  artist: widget.artist,
                  date: todayDateFormatted,
                  location: selectedPlace ?? '',
                  backgroundColor: selectedColor,
  textColor: isDarkText ? const Color(0xFF343231) : const Color(0xFFFEFDFC),
                ),
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
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
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
                        SizedBox(height: screenWidth * 0.08), // 시트 상단 ↔ 안내 문구
                    Row(
  children: [
    SvgPicture.asset(
      'assets/images/bulb_on.svg', // 전구 아이콘
      width: 12,
      height: 12,
    ),
    const SizedBox(width: 4), // 아이콘 ↔ 텍스트 간격 조절
    const Text(
      "Tip 작품과 어울리는 티켓 색상을 추천해드려요.",
      style: TextStyle(fontSize: 12, color: Color(0xFF837670)),
    ),
  ],
),

                        SizedBox(height: screenWidth * 0.03), // 안내문구 ↔ 색상 버튼

                        // 색상 버튼
                        Row(
                          children: [
                            for (int i = 0; i < recommendedColors.take(5).length; i++)
                              Container(
        margin: EdgeInsets.only(right: i == 4 ? 0 : screenWidth * 0.02), // 버튼 간격만 적용 (was 8)
                                child: GestureDetector(
                                  onTap: () => setState(() => selectedColor = recommendedColors[i].withOpacity(1.0)),
                                  child: Container(
                                    width: screenWidth * 0.12, // 48
                                    height: screenWidth * 0.12,
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
        margin: EdgeInsets.only(left: screenWidth * 0.02), // 앞 버튼과 간격 8
        width: screenWidth * 0.12,
        height: screenWidth * 0.12,
        decoration: BoxDecoration(
          color: const Color(0xFFEBEBEB),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Icon(Icons.add, size: screenWidth * 0.06, color: Color(0xFFB1B1B1)),
      ),
    ),
  ],
),

                        SizedBox(height: screenWidth * 0.04), // 색상 버튼 ↔ T 버튼

                        // T 버튼
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => setState(() => isDarkText = false),
                              child: Container(
                                width: screenWidth * 0.125, // 50
                                height: screenWidth * 0.06, // 24
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: Color(0xFF343231),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Text("T",
                                    style: TextStyle(color: Color(0xFFFEFDFC), fontSize: screenWidth * 0.04)), 
                              ),
                            ),
                            SizedBox(width: screenWidth * 0.02),
                            GestureDetector(
                              onTap: () => setState(() => isDarkText = true),
                              child: Container(
                                width: screenWidth * 0.125,
                                height: screenWidth * 0.06,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(color: Color(0xFFB1B1B1)),
                                ),
                                child: Text("T",
                                    style: TextStyle(color: Color(0xFF343231), fontSize: screenWidth * 0.04)), 
                              ),
                            ),
                          ],
                        ),

SizedBox(height: screenWidth * 0.07), // 버튼 ↔ 검색창 간 여백
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
      ? const Icon(Icons.check_circle, color: Color(0xFF837670))
      : const Icon(Icons.search, color: Color(0xFFB1B1B1)),
),
                            filled: true,
                            fillColor: const Color(0xFFFEF6F2),
                            contentPadding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06), //vertical: 12
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        
                        SizedBox(height: screenWidth * 0.04), // 검색창 ↔ 검색목록 여백
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
  Padding(
    padding: EdgeInsets.only(top: screenWidth * 0.02),
    child: Text(
      '전시관이 선택되었습니다.',
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