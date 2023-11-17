import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

const double defaultTitleBarHeight = 30;
const double _topResizeHandleHeight = 6;

const double _extraButtonRadius = 4;
const Radius _extraButtonRadiusRadius = Radius.circular(_extraButtonRadius);
const OutlinedBorder _extraButtonShape = RoundedRectangleBorder(
  borderRadius: BorderRadius.all(_extraButtonRadiusRadius),
);

class WindowTitlebar extends StatelessWidget {
  const WindowTitlebar({
    super.key,
    this.height = defaultTitleBarHeight,
    this.title = '',
    this.titleColor,
    this.iconWidget,
    this.extraWidgets,
  });

  final double height;
  final String title;
  final Color? titleColor;
  final Image? iconWidget;
  final List<Widget>? extraWidgets;

  static const double titleFontSize = 12;
  static const double iconSize = 17;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: height,
              child: Stack(
                children: [
                  SizedBox.expand(
                    child: Row(
                      children: [
                        const SizedBox(width: 6),
                        WindowIconGestureDetector(
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
                              padding:
                                  const EdgeInsets.only(bottom: 2, left: 2),
                              child: Text(
                                title,
                                style: TextStyle(
                                  fontSize: titleFontSize,
                                  color: titleColor,
                                ),
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                  const TopWindowEdgeResizer(),
                ],
              ),
            ),
          ),
          if (extraWidgets != null)
            ExtraTitlebarButtonsContainer(children: extraWidgets!),
          const DefaultWindowButtonSet(),
        ],
      ),
    );
  }
}

class ExtraTitlebarButtonsContainer extends StatelessWidget {
  const ExtraTitlebarButtonsContainer({
    super.key,
    required this.children,
    this.iconSize = 16,
  });

  final double iconSize;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    const double buttonSize = 20;
    Color buttonColor =
        Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5);

    final iconButtonStyle = ButtonStyle(
      alignment: Alignment.topCenter,
      iconSize: MaterialStatePropertyAll(iconSize),
      minimumSize: const MaterialStatePropertyAll(Size(buttonSize, buttonSize)),
      padding: const MaterialStatePropertyAll(EdgeInsets.all(4)),
      shape: const MaterialStatePropertyAll(_extraButtonShape),
      iconColor: MaterialStatePropertyAll(buttonColor),
    );

    final themeData = IconButtonThemeData(style: iconButtonStyle);

    return IconButtonTheme(
      data: themeData,
      child: Padding(
        padding: const EdgeInsets.only(right: 6),
        child: Row(children: children),
      ),
    );
  }
}

class TopWindowEdgeResizer extends StatelessWidget {
  const TopWindowEdgeResizer({
    super.key,
    this.height = _topResizeHandleHeight,
  });

  final double height;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      top: 0,
      child: MouseRegion(
        cursor: SystemMouseCursors.resizeUpDown,
        child: GestureDetector(
          onPanStart: (_) => _handleWindowResizeTop(),
          child: SizedBox(
            height: _topResizeHandleHeight,
            child: Container(color: Colors.transparent),
          ),
        ),
      ),
    );
  }
}

const _closeButttonHoverBgColor = Color(0xFFF23F42);
const _closeButtonPressedBgColor = Color(0xFFF16F7A);
const _closeButtonIconHoverColor = Colors.white;

/// Buttons to the right of the titlebar that controls window minimize, maximize and close.
class DefaultWindowButtonSet extends StatelessWidget {
  const DefaultWindowButtonSet({
    super.key,
    this.iconSize = 14,
  });

  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final iconButtonStyle = ButtonStyle(
      alignment: Alignment.topCenter,
      iconSize: MaterialStatePropertyAll(iconSize),
      shape: const MaterialStatePropertyAll(LinearBorder()),
    );

    final themeData = IconButtonThemeData(style: iconButtonStyle);

    Color idleColor = Theme.of(context).colorScheme.onSurfaceVariant;

    return IconButtonTheme(
      data: themeData,
      child: Row(
        children: [
          const WindowButton(
            icon: Icon(Icons.minimize),
            onPressed: _minimizeWindow,
          ),
          const WindowButton(
            icon: Icon(Icons.check_box_outline_blank),
            onPressed: _maximizeOrRestoreWindow,
          ),
          WindowButton(
            icon: const Icon(Icons.close),
            style: iconButtonStyle.copyWith(
                overlayColor:
                    const MaterialStatePropertyAll(Colors.transparent),
                backgroundColor: _hoverPressedColors(
                  idle: Colors.transparent,
                  hover: _closeButttonHoverBgColor,
                  pressed: _closeButtonPressedBgColor,
                ),
                iconColor: _hoverColors(
                  idle: idleColor,
                  hover: _closeButtonIconHoverColor,
                )),
            onPressed: _closeWindow,
          ),
        ],
      ),
    );
  }
}

/// A button styled for the window buttons of a titlebar.
class WindowButton extends StatelessWidget {
  const WindowButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.style,
  });

  final VoidCallback? onPressed;
  final Icon icon;
  final ButtonStyle? style;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      style: style,
      highlightColor: Colors.transparent,
      autofocus: false,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      onPressed: onPressed ?? () {},
      icon: icon,
    );
  }
}

class WindowIconGestureDetector extends StatelessWidget {
  const WindowIconGestureDetector({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _popupWindowMenu,
      onSecondaryTap: _popupWindowMenu,
      child: child,
    );
  }
}

/// Handles titlebar actions like click to drag window, and right-click to show window menu.
class TitlebarGestureDetector extends StatelessWidget {
  const TitlebarGestureDetector({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onPanStart: (details) => windowManager.startDragging(),
      onSecondaryTap: _popupWindowMenu,
      onDoubleTap: _maximizeOrRestoreWindow,
      child: child,
    );
  }
}

void _handleWindowResizeTop() {
  windowManager.startResizing(ResizeEdge.top);
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

MaterialStateProperty<Color> _hoverPressedColors({
  required Color idle,
  required Color hover,
  required Color pressed,
}) {
  return MaterialStateProperty.resolveWith((states) {
    if (states.contains(MaterialState.pressed)) {
      return pressed;
    } else if (states.contains(MaterialState.hovered)) {
      return hover;
    }

    return idle;
  });
}

MaterialStateProperty<Color> _hoverColors({
  required Color idle,
  required Color hover,
}) {
  return MaterialStateProperty.resolveWith(
      (states) => states.contains(MaterialState.hovered) ? hover : idle);
}

// class DebugDecoration extends StatelessWidget {
//   const DebugDecoration(this.color, {super.key, required this.child});

//   final Color color;
//   final Widget child;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       decoration: BoxDecoration(color: color),
//       child: child,
//     );
//   }
// }
