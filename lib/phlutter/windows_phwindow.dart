import 'package:animators_gif_enjoyer/phlutter/window_manager_titlebar.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

///
/// Wraps the child with a titlebar and optional window resizing handles all around.
/// This is meant as a top-level visible widget.
class WindowsPhwindow extends StatefulWidget {
  const WindowsPhwindow({
    super.key,
    this.title = '',
    this.titleColor,
    this.iconWidget,
    this.addExtraResizingFrame = true,
    required this.child,
  });

  final String title;
  final Color? titleColor;
  final Image? iconWidget;
  final Widget child;
  final bool addExtraResizingFrame;

  @override
  State<WindowsPhwindow> createState() => _WindowsPhwindowState();
}

class _WindowsPhwindowState extends State<WindowsPhwindow> {
  final ValueNotifier<bool> isAlwaysOnTop = ValueNotifier(false);

  @override
  Widget build(BuildContext context) {
    final titleBar = WindowTitlebar(
      title: widget.title,
      titleColor: widget.titleColor,
      iconWidget: widget.iconWidget,
      includeTopWindowResizer: !widget.addExtraResizingFrame,
      extraWidgets: [
        KeepWindowOnTopButton(notifier: isAlwaysOnTop),
      ],
    );

    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              titleBar,
              Expanded(child: widget.child),
            ],
          ),
          if (widget.addExtraResizingFrame) const WindowResizeFrame(),
        ],
      ),
    );
  }

  @override
  void initState() {
    isAlwaysOnTop.addListener(updateAlwaysOnTop);
    super.initState();
  }

  @override
  void dispose() {
    isAlwaysOnTop.removeListener(updateAlwaysOnTop);
    super.dispose();
  }

  void updateAlwaysOnTop() {
    windowManager.setAlwaysOnTop(isAlwaysOnTop.value);
  }
}

class KeepWindowOnTopButton extends StatelessWidget {
  const KeepWindowOnTopButton({
    super.key,
    required this.notifier,
  });

  final ValueNotifier<bool> notifier;
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
}
