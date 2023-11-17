import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

class WindowTitlebar extends StatelessWidget {
  const WindowTitlebar({
    super.key,
    this.height = 30,
    this.title = '',
    this.titleColor,
    this.iconWidget,
  });

  final double height;
  final String title;
  final Color? titleColor;
  final Image? iconWidget;

  static const double titleFontSize = 12;
  static const double iconSize = 17;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Row(
        children: [
          const SizedBox(width: 6),
          GestureDetector(
            onTap: _popupWindowMenu,
            onSecondaryTap: _popupWindowMenu,
            child: Padding(
              padding: const EdgeInsets.all(3.0),
              child: iconWidget != null
                  ? SizedBox(
                      height: iconSize,
                      width: iconSize,
                      child: iconWidget,
                    )
                  : const SizedBox.shrink(),
            ),
          ),
          Expanded(
            child: TitlebarGestureDetector(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 2, left: 2),
                child: Text(title,
                    style: TextStyle(
                      fontSize: titleFontSize,
                      color: titleColor,
                    )),
              ),
            ),
          ),
          const DefaultWindowButtonSet(),
        ],
      ),
    );
  }
}

class DebugDecoration extends StatelessWidget {
  const DebugDecoration(this.color, {super.key, required this.child});

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      //decoration: BoxDecoration(color: color),
      child: child,
    );
  }
}

class DefaultWindowButtonSet extends StatelessWidget {
  const DefaultWindowButtonSet({
    super.key,
    this.iconSize = 14,
  });

  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final themeData = IconButtonThemeData(
      style: ButtonStyle(
        alignment: Alignment.topCenter,
        iconSize: MaterialStatePropertyAll(iconSize),
        shape: const MaterialStatePropertyAll(LinearBorder()),
      ),
    );

    return IconButtonTheme(
      data: themeData,
      child: const Row(
        children: [
          WindowButton(
            icon: Icon(Icons.minimize),
            onPressed: _minimizeWindow,
          ),
          WindowButton(
            icon: Icon(Icons.check_box_outline_blank),
            onPressed: _maximizeOrRestoreWindow,
          ),
          WindowButton(
            icon: Icon(Icons.close),
            hoverColor: Color(0xFFE81123),
            onPressed: _closeWindow,
          ),
        ],
      ),
    );
  }
}

class WindowButton extends StatelessWidget {
  const WindowButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.hoverColor,
  });

  final VoidCallback? onPressed;
  final Icon icon;
  final Color? hoverColor;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      hoverColor: hoverColor,
      highlightColor: Colors.transparent,
      autofocus: false,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      onPressed: onPressed ?? () {},
      icon: icon,
    );
  }
}

class TitlebarGestureDetector extends StatelessWidget {
  const TitlebarGestureDetector({
    super.key,
    this.child,
    this.onDoubleTap,
  });

  final Widget? child;
  final VoidCallback? onDoubleTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onPanStart: (details) => windowManager.startDragging(),
      onSecondaryTap: _popupWindowMenu,
      onDoubleTap: onDoubleTap ?? _maximizeOrRestoreWindow,
      child: child ?? Container(),
    );
  }
}

void _maximizeOrRestoreWindow() async {
  final isMaximized = await windowManager.isMaximized();
  if (isMaximized) {
    windowManager.restore();
  } else {
    windowManager.maximize();
  }
}

void _popupWindowMenu() {
  windowManager.popUpWindowMenu();
}

void _minimizeWindow() {
  windowManager.minimize();
}

void _closeWindow() {
  windowManager.close();
}

// MaterialStateProperty<Color> _hoverActiveColors({
//   required Color idle,
//   required Color hover,
//   required Color active,
// }) {
//   return MaterialStateProperty.resolveWith((states) {
//     if (states.contains(MaterialState.hovered)) {
//       return hover;
//     } else if (states.contains(MaterialState.selected)) {
//       return active;
//     }

//     return idle;
//   });
// }
