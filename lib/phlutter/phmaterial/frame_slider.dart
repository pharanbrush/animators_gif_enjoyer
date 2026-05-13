import 'package:flutter/material.dart';

class FrameSlider extends StatefulWidget {
  const FrameSlider({
    super.key,
    required this.min,
    required this.max,
    required this.value,
    this.onChanged,
    this.cellHeight = 15,
    this.selectedCellHeight = 23,
    this.hitHeight = 40,
    this.minCellWidth = 6.0,
    this.borderRadius = 4.0,
    this.hoverColor,
    this.wrapWhenDragging = false,
  });

  final int min;
  final int max;
  final int value;
  final ValueChanged<int>? onChanged;
  final double cellHeight;
  final double selectedCellHeight;
  final double hitHeight;
  final double minCellWidth;
  final double borderRadius;
  final Color? hoverColor;
  final bool wrapWhenDragging;

  @override
  State<FrameSlider> createState() => _FrameSliderState();
}

class _FrameSliderState extends State<FrameSlider> {
  int? _hoveredIndex;

  bool get enabled => widget.onChanged != null;

  void _updateValue(Offset localPosition, double totalWidth) {
    if (!enabled) return;

    final itemCount = widget.max - widget.min + 1;
    final squareWidth = totalWidth / itemCount;

    int index = (localPosition.dx ~/ squareWidth);

    if (widget.wrapWhenDragging) {
      // Wrap mode
      index = (index % itemCount + itemCount) % itemCount;
    } else {
      // Clamp mode
      index = index.clamp(0, itemCount - 1);
    }

    final newValue = widget.min + index;

    if (newValue != widget.value) {
      widget.onChanged?.call(newValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemCount = widget.max - widget.min + 1;
    final colorScheme = Theme.of(context).colorScheme;

    final activeColor = enabled ? colorScheme.primary : colorScheme.outline;
    final inactiveColor = enabled
        ? colorScheme.surfaceContainerHigh
        : colorScheme.surfaceContainerLow;
    final hoverColor =
        widget.hoverColor ?? colorScheme.primary.withValues(alpha: 0.4);

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final squareWidth = totalWidth / itemCount;
        final useContinuous = squareWidth < widget.minCellWidth;

        Widget continuousSlider() => CustomPaint(
          painter: _ContinuousSliderPainter(
            min: widget.min,
            max: widget.max,
            value: widget.value,
            activeColor: activeColor,
            inactiveColor: inactiveColor,
            cellHeight: widget.cellHeight,
            selectedCellHeight: widget.selectedCellHeight,
            borderRadius: widget.borderRadius,
            thumbWidth: widget.borderRadius * 2,
          ),
        );

        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onPanDown: enabled
              ? (details) => _updateValue(details.localPosition, totalWidth)
              : null,
          onPanUpdate: enabled
              ? (details) => _updateValue(details.localPosition, totalWidth)
              : null,
          child: SizedBox(
            height: widget.hitHeight,
            child: useContinuous
                ? continuousSlider()
                : Row(
                    children: List.generate(itemCount, (index) {
                      final boxValue = widget.min + index;
                      final isSelected = boxValue == widget.value;
                      final isHovered = _hoveredIndex == index;

                      BorderRadius radius = BorderRadius.zero;
                      final r = Radius.circular(widget.borderRadius);

                      if (isSelected) {
                        radius = BorderRadius.all(r);
                      } else if (index == 0) {
                        radius = BorderRadius.horizontal(left: r);
                      } else if (index == itemCount - 1) {
                        radius = BorderRadius.horizontal(right: r);
                      }

                      return Expanded(
                        child: MouseRegion(
                          onEnter: (_) => setState(() => _hoveredIndex = index),
                          onExit: (_) => setState(() => _hoveredIndex = null),
                          child: Padding(
                            padding: const EdgeInsets.only(right: 1),
                            child: Align(
                              alignment: Alignment.center,
                              child: Container(
                                height: isSelected
                                    ? widget.selectedCellHeight
                                    : widget.cellHeight,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? activeColor
                                      : isHovered
                                      ? hoverColor
                                      : inactiveColor,
                                  borderRadius: radius,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
          ),
        );
      },
    );
  }
}

class _ContinuousSliderPainter extends CustomPainter {
  _ContinuousSliderPainter({
    required this.min,
    required this.max,
    required this.value,
    required this.activeColor,
    required this.inactiveColor,
    required this.cellHeight,
    required this.selectedCellHeight,
    required this.borderRadius,
    required this.thumbWidth,
  });

  final int min;
  final int max;
  final int value;
  final Color activeColor;
  final Color inactiveColor;
  final double cellHeight;
  final double selectedCellHeight;
  final double borderRadius;
  final double thumbWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final itemCount = max - min + 1;
    final squareWidth = size.width / itemCount;

    // Position of selected value
    final selectedX = (value - min) * squareWidth;

    final paintInactive = Paint()..color = inactiveColor;
    final paintActive = Paint()..color = activeColor;

    // Track
    final barRect = Rect.fromLTWH(
      0,
      (size.height - cellHeight) / 2,
      size.width,
      cellHeight,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(barRect, Radius.circular(borderRadius)),
      paintInactive,
    );

    // Thumb
    final selectedRect = Rect.fromLTWH(
      selectedX - (thumbWidth / 2),
      (size.height - selectedCellHeight) / 2,
      thumbWidth,
      selectedCellHeight,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(selectedRect, Radius.circular(borderRadius)),
      paintActive,
    );
  }

  @override
  bool shouldRepaint(covariant _ContinuousSliderPainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.inactiveColor != inactiveColor ||
        oldDelegate.borderRadius != borderRadius ||
        oldDelegate.thumbWidth != thumbWidth;
  }
}
