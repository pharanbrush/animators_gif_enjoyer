import 'package:flutter/material.dart';

const _defaultFadeDuration = Duration(milliseconds: 100);

class HoverContainer extends StatelessWidget {
  const HoverContainer({
    super.key,
    required this.hoverBackgroundColor,
    required this.child,
    this.fadeDuration = _defaultFadeDuration,
    this.borderRadius = const BorderRadius.all(Radius.circular(5)),
    this.unhoveredAlpha = 0,
  });

  final Color hoverBackgroundColor;
  final double unhoveredAlpha;
  final Widget child;
  final Duration fadeDuration;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return HoverBuilder(
      builder: (_, isHovering) {
        return TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: isHovering ? 1 : unhoveredAlpha),
          duration: fadeDuration,
          builder: (_, value, _) {
            return Container(
              decoration: BoxDecoration(
                borderRadius: borderRadius,
                color: hoverBackgroundColor.withValues(alpha: value),
              ),
              child: child,
            );
          },
        );
      },
    );
  }
}

class HoverContainerBuilder extends StatelessWidget {
  const HoverContainerBuilder({
    super.key,
    required this.hoverBackgroundColor,
    required this.builder,
    this.fadeDuration = _defaultFadeDuration,
    this.borderRadius = const BorderRadius.all(Radius.circular(25)),
    this.unhoveredAlpha = 0,
  });

  final Color hoverBackgroundColor;
  final int unhoveredAlpha;
  final Widget Function(BuildContext context, bool isHovering) builder;
  final Duration fadeDuration;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return HoverBuilder(
      builder: (context, isHovering) {
        return AnimatedContainer(
          duration: fadeDuration,
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            color: isHovering
                ? hoverBackgroundColor
                : hoverBackgroundColor.withAlpha(unhoveredAlpha),
          ),
          child: builder(context, isHovering),
        );
      },
    );
  }
}

class HoverBuilder extends StatefulWidget {
  const HoverBuilder({
    super.key,
    required this.builder,
    this.onHover,
    this.onExit,
  });

  final VoidCallback? onHover;
  final VoidCallback? onExit;
  final Widget Function(BuildContext context, bool isHovering) builder;

  @override
  State<HoverBuilder> createState() => _HoverBuilderState();
}

class _HoverBuilderState extends State<HoverBuilder> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (_) {
        _isHovering = true;
        widget.onHover?.call();
        setState(() {});
      },
      onExit: (_) {
        _isHovering = false;
        widget.onExit?.call();
        setState(() {});
      },
      child: widget.builder(context, _isHovering),
    );
  }
}

class HoverNotifier extends StatelessWidget {
  const HoverNotifier({
    super.key,
    required this.child,
    required this.isHoveringNotifier,
    this.onHover,
    this.onExit,
  });

  final VoidCallback? onHover;
  final VoidCallback? onExit;
  final Widget child;
  final ValueNotifier<bool> isHoveringNotifier;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (_) {
        isHoveringNotifier.value = true;
        onHover?.call();
      },
      onExit: (_) {
        isHoveringNotifier.value = false;
        onExit?.call();
      },
      child: child,
    );
  }
}
