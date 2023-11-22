import 'package:animators_gif_enjoyer/phlutter/windows/window_manager_titlebar.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

///
/// Wraps the child with a titlebar and optional window resizing handles all around.
/// This is meant as a top-level visible widget.
class WindowsPhwindow extends StatelessWidget {
  const WindowsPhwindow({
    super.key,
    this.title = '',
    this.titleColor,
    this.iconWidget,
    this.addExtraResizingFrame = true,
    this.isAlwaysOnTopNotifier,
    this.titleBarHeight = defaultTitleBarHeight,
    required this.child,
  });

  final String title;
  final Color? titleColor;
  final Image? iconWidget;
  final Widget child;
  final bool addExtraResizingFrame;
  final ValueNotifier<bool>? isAlwaysOnTopNotifier;
  final double titleBarHeight;

  @override
  Widget build(BuildContext context) {
    final titleBar = WindowTitlebar(
      title: title,
      titleColor: titleColor,
      iconWidget: iconWidget,
      includeTopWindowResizer: !addExtraResizingFrame,
      height: titleBarHeight,
      extraWidgets: [
        KeepWindowOnTopButton(notifier: isAlwaysOnTopNotifier),
      ],
    );

    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              SizedBox(height: titleBarHeight),
              Expanded(child: child),
            ],
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: titleBar,
          ),
          if (addExtraResizingFrame) const WindowResizeFrame(),
        ],
      ),
    );
  }
}

class KeepWindowOnTopButton extends StatefulWidget {
  const KeepWindowOnTopButton({
    super.key,
    this.notifier,
  });

  final ValueNotifier<bool>? notifier;

  @override
  State<KeepWindowOnTopButton> createState() => _KeepWindowOnTopButtonState();
}

class _KeepWindowOnTopButtonState extends State<KeepWindowOnTopButton> {
  late ValueNotifier<bool> notifier = widget.notifier ?? ValueNotifier(false);
  void toggleNotifier() => notifier.value = !notifier.value;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: notifier,
      builder: (_, value, __) {
        return IconButton(
          isSelected: value,
          tooltip: value
              ? 'Click to disable Keep window on top'
              : 'Click to enable Keep window on top',
          icon: value
              ? const Icon(Icons.picture_in_picture_alt)
              : const Icon(Icons.picture_in_picture_alt_outlined),
          onPressed: toggleNotifier,
        );
      },
    );
  }

  @override
  void initState() {
    notifier.addListener(updateAlwaysOnTop);
    super.initState();
  }

  @override
  void dispose() {
    notifier.removeListener(updateAlwaysOnTop);
    super.dispose();
  }

  void updateAlwaysOnTop() {
    windowManager.setAlwaysOnTop(notifier.value);
  }
}
