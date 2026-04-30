import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

class ScrollListener extends StatelessWidget {
  const ScrollListener({
    super.key,
    this.onScrollDown,
    this.onScrollUp,
    this.onMiddleClickDown,
    required this.child,
    this.behavior = HitTestBehavior.deferToChild,
  });

  final Function()? onScrollUp, onScrollDown, onMiddleClickDown;
  final Widget? child;
  final HitTestBehavior behavior;

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: behavior,
      onPointerDown: onMiddleClickDown == null ? null : _handlePointerDown,
      onPointerSignal: _handlePointerSignal,
      child: child,
    );
  }

  void _handlePointerSignal(PointerSignalEvent pointerEvent) {
    if (pointerEvent is PointerScrollEvent) {
      final dy = pointerEvent.scrollDelta.dy;
      if (dy > 0) {
        onScrollDown?.call();
      } else if (dy < 0) {
        onScrollUp?.call();
      }
    }
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (event.buttons == kMiddleMouseButton) {
      onMiddleClickDown?.call();
    }
  }
}
