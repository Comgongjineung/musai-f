import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'alarm_page.dart';
import 'package:flutter/services.dart';

class AppBarWidget extends StatelessWidget implements PreferredSizeWidget {
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final List<Widget>? actions;
  final Color? backgroundColor;
  final bool centerTitle;
  final String? title;
  final double? titleSize;
  final Color? titleColor;
  final bool showNotificationIcon;
  final bool showSettingsIcon;
  final VoidCallback? onSettingsPressed;
  final SystemUiOverlayStyle? systemOverlayStyle;

  const AppBarWidget({
    super.key,
    this.showBackButton = false,
    this.onBackPressed,
    this.actions,
    this.backgroundColor,
    this.centerTitle = true,
    this.title,
    this.titleSize,
    this.titleColor,
    this.showNotificationIcon = false,
    this.showSettingsIcon = false,
    this.onSettingsPressed,
    this.systemOverlayStyle,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return AppBar(
      backgroundColor: const Color(0xFFFFFDFC),
      elevation: 0,
      scrolledUnderElevation: 2, // 스크롤 시 그림자 추가
      surfaceTintColor: const Color(0xFFFAFAFA), // 스크롤 시 FAFAFA 색상
      centerTitle: centerTitle,
      systemOverlayStyle: systemOverlayStyle ?? SystemUiOverlayStyle(
        statusBarColor: (backgroundColor ?? Colors.white),
        statusBarIconBrightness: Brightness.dark, // Android: dark icons
        statusBarBrightness: Brightness.light,    // iOS: dark icons
      ),
      leading: showBackButton
        ? Padding(
            padding: const EdgeInsets.only(left:24), 
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(
                Icons.arrow_back_ios,
                color: Color(0xFF343231),
              ),
              onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
            ),
          )
        : null,
      title: title != null
          ? Text(
              title!,
              style: TextStyle(
                color: titleColor ?? const Color(0xFF343231),
                fontSize: titleSize ?? screenWidth * 0.08,
                fontWeight: FontWeight.bold,
                fontFamily: 'Pretendard',
                letterSpacing: 0,
              ),
            )
          : Text(
              'musai',
              style: TextStyle(
                color: titleColor ?? const Color(0xFF343231),
                fontSize: screenWidth * 0.08,
                fontWeight: FontWeight.bold,
                fontFamily: 'Pretendard',
                letterSpacing: 0,
              ),
            ),
      actions: [
        if (showNotificationIcon)
          Padding(
            padding: const EdgeInsets.only(right: 24),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AlarmPage(initialIndex: 0)),
                );
              },
              child: SvgPicture.asset(
                'assets/icons/notification.svg',
                width: 20,
                height: 20,
              ),
            ),
          ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

// 카메라 페이지용 특별한 앱바 (흰색 텍스트)
class CameraAppBarWidget extends StatelessWidget implements PreferredSizeWidget {
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final List<Widget>? actions;

  const CameraAppBarWidget({
    super.key,
    this.showBackButton = false,
    this.onBackPressed,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light, // Android: light icons (white)
        statusBarBrightness: Brightness.dark,       // iOS: light icons
      ),
      leading: showBackButton
          ? IconButton(
              icon: const Icon(
                Icons.arrow_back_ios,
                color: Colors.white,
              ),
              onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
            )
          : null,
      title: Text(
        'musai',
        style: TextStyle(
          color: Colors.white,
          fontSize: screenWidth * 0.08,
          fontWeight: FontWeight.bold,
          fontFamily: 'Pretendard',
          letterSpacing: 0,
        ),
      ),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}