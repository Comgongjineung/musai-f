import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'ticket_screen.dart'; // TicketCard 불러오기

class TicketCreateScreen extends StatefulWidget {
  final Color initialColor;
  const TicketCreateScreen({super.key, required this.initialColor});

  @override
  State<TicketCreateScreen> createState() => _TicketCreateScreenState();
}

class _TicketCreateScreenState extends State<TicketCreateScreen> {
  late Color selectedColor;
  bool isDarkText = false; // T 버튼 상태 (false=흰색 글씨, true=검은 글씨)

  final List<Color> recommendedColors = [
    const Color(0xFF8DAA91),
    const Color(0xFF4E6C50),
    const Color(0xFFF9D57A),
    const Color(0xFFFCEEC8),
    const Color(0xFF6B8FD6),
  ];

  @override
  void initState() {
    super.initState();
    selectedColor = widget.initialColor;
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

  void _completeTicket() {
    Navigator.pop(context, selectedColor); // 선택 색상 반환
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
                scale: 0.875,
                child: TicketCard(
                  imageAsset: "assets/images/ticket.png",
                  title: "아이와 해바라기 정원",
                  artist: "Claude Monet",
                  date: "2025.07.27",
                  location: "예술의 전당",
                  backgroundColor: selectedColor,
                  textColor: isDarkText ? Colors.black : Colors.white,
                ),
              ),
            ),

          // 하단 드래거블 시트
          DraggableScrollableSheet(
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
                          decoration: InputDecoration(
                            hintText: "방문했던 전시관을 검색하세요",
                            hintStyle: const TextStyle(color: Color(0xFFB1B1B1)),
                            suffixIcon: const Icon(Icons.search, color: Color(0xFFB1B1B1)),
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

                        const Text(
                          "💡 작품과 어울리는 티켓 색상을 추천해드려요.",
                          style: TextStyle(fontSize: 14, color: Color(0xFF837670)),
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

                        const SizedBox(height: 28), // 마지막 여백
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