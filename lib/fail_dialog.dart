import 'package:flutter/material.dart';

class FailDialog extends StatelessWidget {
  const FailDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          // 팝업 박스 
          Container(
            width: 240,
            height: 155,
            margin: const EdgeInsets.only(top: 24),
            decoration: BoxDecoration(
              color: const Color(0xFF3E3C3B),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 12, bottom: 16),
                  child: Text(
                    '작품 인식에 실패했습니다.\n다시 시도해주세요.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0xFFFEFDFC),
                      fontSize: 14,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                // 확인 버튼 
                SizedBox(
                  width: 150,
                  height: 35,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF837670),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: EdgeInsets.zero,
                      elevation: 0,
                    ),
                    child: const Text(
                      '확인',
                      style: TextStyle(
                        color: const Color(0xFFFEFDFC),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),

          // 경고 아이콘 (세모 PNG만 겹치기)
          Positioned(
            top: -6,
            child: Image.asset(
              'assets/images/warning_icon.png', 
              width: 60,
              height: 60,
            ),
          ),
        ],
      ),
    );
  }
}