import 'package:flutter/material.dart';

class FailDialog extends StatelessWidget {
  const FailDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          // 팝업 박스 
          Container(
            width: screenWidth * 0.65,
            height: screenHeight * 0.2,
            margin: EdgeInsets.only(top: screenHeight * 0.02),
            decoration: BoxDecoration(
              color: const Color(0xFF3E3C3B),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: screenHeight * 0.02, bottom: screenHeight * 0.02),
                  child: Text(
                    '작품 인식에 실패했습니다.\n다시 시도해주세요.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0xFFFEFDFC),
                      fontSize: screenWidth * 0.038,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                // 확인 버튼 
                SizedBox(
                  width: screenWidth * 0.45,
                  height: screenHeight * 0.05,
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
                    child: Text(
                      '확인',
                      style: TextStyle(
                        color: const Color(0xFFFEFDFC),
                        fontSize: screenWidth * 0.04,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.028),
              ],
            ),
          ),

          // 경고 아이콘 (세모 PNG만 겹치기)
          Positioned(
            top: -screenHeight * 0.045,
            child: Image.asset(
              'assets/images/warning_icon.png', 
              width: screenWidth * 0.3,
              height: screenWidth * 0.3,
            ),
          ),
        ],
      ),
    );
  }
}