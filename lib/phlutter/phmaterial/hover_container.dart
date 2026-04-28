import 'package:flutter/material.dart';

class HoverContainer extends StatefulWidget {
  const HoverContainer({
    super.key,
    required this.hoverBackgroundColor,
    required this.child,
    this.fadeDuration = defaultDuration,
    this.borderRadius = const BorderRadius.all(Radius.circular(25)),
    this.unhoveredAlpha = 0,
  });

  static const defaultDuration = Duration(milliseconds: 200);

  final Color hoverBackgroundColor;
  final int unhoveredAlpha;
  final Widget child;
  final Duration fadeDuration;
  final BorderRadius borderRadius;

  @override
  State<HoverContainer> createState() => _HoverContainerState();
}

class _HoverContainerState extends State<HoverContainer> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: AnimatedContainer(
        duration: widget.fadeDuration,
        decoration: BoxDecoration(
          borderRadius: widget.borderRadius,
          color: _isHovering
              ? widget.hoverBackgroundColor
              : widget.hoverBackgroundColor.withAlpha(widget.unhoveredAlpha),
        ),
        child: widget.child,
      ),
    );
  }
}
