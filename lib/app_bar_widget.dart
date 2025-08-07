import 'package:flutter/material.dart';
import 'alarm_page.dart';

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
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    final List<Widget> combinedActions = [...?actions];
    if (showNotificationIcon) {
      combinedActions.add(
        Padding(
          padding: const EdgeInsets.only(right: 24),
          child: IconButton(
            icon: const Icon(Icons.notifications_none, size: 24, color: Color(0xFF343231)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AlarmPage(initialIndex: 0)),
              );
            },
          ),
        ),
      );
    }

    return AppBar(
      backgroundColor: backgroundColor ?? Colors.transparent,
      elevation: 0,
      centerTitle: centerTitle,
      leading: showBackButton
        ? Padding(
            padding: const EdgeInsets.only(left:24), // ← 원하는 값으로 변경
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
      actions: combinedActions,
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