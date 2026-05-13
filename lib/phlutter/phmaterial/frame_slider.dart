import 'package:flutter/material.dart';

class FrameSlider extends StatelessWidget {
  const FrameSlider({
    super.key,
    required this.min,
    required this.max,
    required this.value,
    this.onChanged,
    this.cellHeight = 15,
    this.selectedCellHeight = 23,
    this.hitHeight = 40,
    this.minCellWidth = 8.0,
    this.borderRadius = 5.0,
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

  bool get enabled => onChanged != null;

  void _updateValue(Offset localPosition, double totalWidth) {
    if (!enabled) return;

    final itemCount = max - min + 1;
    final squareWidth = totalWidth / itemCount;

    final index = (localPosition.dx ~/ squareWidth).clamp(0, itemCount - 1);
    final newValue = min + index;

    if (newValue != value) {
      onChanged?.call(newValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemCount = max - min + 1;
    final colorScheme = Theme.of(context).colorScheme;

    final activeColor = enabled
        ? colorScheme.primary
        : colorScheme.primary.withValues(alpha: 0.75);
    final inactiveColor = enabled
        ? colorScheme.surfaceContainerHigh
        : colorScheme.surfaceContainer.withValues(alpha: 0.12);

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final squareWidth = totalWidth / itemCount;
        final useContinuous = squareWidth < minCellWidth;

        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onPanDown: enabled
              ? (details) => _updateValue(details.localPosition, totalWidth)
              : null,
          onPanUpdate: enabled
              ? (details) => _updateValue(details.localPosition, totalWidth)
              : null,
          child: SizedBox(
            height: hitHeight,
            child: useContinuous
                ? CustomPaint(
                    painter: _ContinuousSliderPainter(
                      min: min,
                      max: max,
                      value: value,
                      activeColor: activeColor,
                      inactiveColor: inactiveColor,
                      cellHeight: cellHeight,
                      selectedCellHeight: selectedCellHeight,
                      borderRadius: borderRadius,
                      minCellWidth: minCellWidth,
                    ),
                  )
                : Row(
                    children: List.generate(itemCount, (index) {
                      final boxValue = min + index;
                      final isSelected = boxValue == value;

                      BorderRadius radius = BorderRadius.zero;
                      final r = Radius.circular(borderRadius);

                      if (isSelected) {
                        radius = BorderRadius.all(r);
                      } else if (index == 0) {
                        radius = BorderRadius.horizontal(left: r);
                      } else if (index == itemCount - 1) {
                        radius = BorderRadius.horizontal(right: r);
                      }

                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 1),
                          child: Align(
                            alignment: Alignment.center,
                            child: Container(
                              height: isSelected
                                  ? selectedCellHeight
                                  : cellHeight,
                              decoration: BoxDecoration(
                                color: isSelected ? activeColor : inactiveColor,
                                borderRadius: radius,
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
    required this.minCellWidth,
  });

  final int min;
  final int max;
  final int value;
  final Color activeColor;
  final Color inactiveColor;
  final double cellHeight;
  final double selectedCellHeight;
  final double borderRadius;
  final double minCellWidth;

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
      selectedX - (minCellWidth / 2),
      (size.height - selectedCellHeight) / 2,
      minCellWidth,
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
        oldDelegate.minCellWidth != minCellWidth;
  }
}
