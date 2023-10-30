import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// ModalPanel encapsulates the stateful controls needed for a widget to be able to open and close.
/// It is a modal that can block things behind it.
///
/// The user can click anywhere outside the panel to close it. But any descendant widgets in the builder can use
/// ```dart
/// ModalDismissContext.of(context).onDismiss?.call()
/// ```
/// to manually close the ModalPanel.
///
/// Use the callbacks to add additional logic when opening and closing the panel.
class ModalPanel {
  ModalPanel({
    this.key,
    required this.builder,
    this.onBeforeOpen,
    this.onOpened,
    this.onClosed,
    this.isUnderlayTransparent = false,
    this.transitionBuilder = AnimatedSwitcher.defaultTransitionBuilder,
  });

  final Key? key;
  final Widget Function() builder;
  final Function()? onBeforeOpen;
  final Function()? onOpened;
  final Function()? onClosed;

  /// [ModalPanel] automatically adds a clickable scrim/underlay to make the underlying elements
  /// less prominent. [isUnderlayTransparent] makes the underlay invisible but still clickable.
  final bool isUnderlayTransparent;

  /// Defines the transition animation widget builder used by the internal [AnimatedSwitcher].
  /// See documentation on [AnimatedSwitcher] for more info.
  final AnimatedSwitcherTransitionBuilder transitionBuilder;

  final ValueNotifier<bool> _isOpen = ValueNotifier(false);
  bool get isOpen => _isOpen.value;

  /// A listenable for the opened state of the panel.
  ValueListenable<bool> get openStateListenable => _isOpen;

  void open() {
    onBeforeOpen?.call();
    _isOpen.value = true;
    onOpened?.call();
  }

  void close() {
    _isOpen.value = false;
    onClosed?.call();
  }

  Widget widget() {
    return _ModalPanelWidget(
      key: key,
      isOpen: _isOpen,
      close: close,
      isUnderlayTransparent: isUnderlayTransparent,
      transitionBuilder: transitionBuilder,
      builder: builder,
    );
  }
}

class _ModalPanelWidget extends StatelessWidget {
  const _ModalPanelWidget({
    super.key,
    required this.isOpen,
    required this.close,
    required this.isUnderlayTransparent,
    required this.transitionBuilder,
    required this.builder,
  });

  final ValueListenable<bool> isOpen;
  final VoidCallback close;
  final bool isUnderlayTransparent;
  final AnimatedSwitcherTransitionBuilder transitionBuilder;
  final Widget Function() builder;

  static const defaultDuration = Duration(milliseconds: 200);
  static const fastDuration = Duration(milliseconds: 100);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: isOpen,
      builder: (_, value, __) {
        return ModalDismissContext(
          onDismiss: close,
          child: Stack(
            children: [
              AnimatedSwitcher(
                duration: fastDuration,
                child: value
                    ? (isUnderlayTransparent
                        ? const ModalUnderlay.transparent()
                        : const ModalUnderlay())
                    : null,
              ),
              AnimatedSwitcher(
                transitionBuilder: transitionBuilder,
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeOutCubic,
                duration: defaultDuration,
                reverseDuration: fastDuration,
                child: value ? builder() : null,
              ),
            ],
          ),
        );
      },
    );
  }
}

class ModalUnderlay extends StatelessWidget {
  const ModalUnderlay({
    super.key,
    this.onDismiss,
    this.isTransparent = false,
  });

  const ModalUnderlay.transparent({super.key, this.onDismiss})
      : isTransparent = true;

  final Function()? onDismiss;
  final bool isTransparent;

  @override
  Widget build(BuildContext context) {
    final dismissFunction =
        onDismiss ?? ModalDismissContext.of(context)?.onDismiss ?? () {};

    return ModalBarrier(
      dismissible: true,
      onDismiss: dismissFunction,
      color: isTransparent
          ? Colors.transparent
          : Theme.of(context).colorScheme.scrim,
    );
  }
}

class ModalDismissContext extends InheritedWidget {
  const ModalDismissContext({
    super.key,
    required this.onDismiss,
    required super.child,
  });

  final VoidCallback? onDismiss;

  static ModalDismissContext? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ModalDismissContext>();
  }

  @override
  bool updateShouldNotify(ModalDismissContext oldWidget) {
    return true;
  }
}
