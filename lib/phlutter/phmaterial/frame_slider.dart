import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum SnapMode {
  none,
  nearest,
  force,
}

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
    this.markerColor,
    this.wrapWhenDragging = false,
    this.frameMarkers,
    this.onSecondaryTapOnFrame,
    this.snapMode = SnapMode.nearest,
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
  final Color? markerColor;
  final bool wrapWhenDragging;
  final Iterable<int>? frameMarkers;
  final void Function(int frame)? onSecondaryTapOnFrame;
  final SnapMode snapMode;

  @override
  State<FrameSlider> createState() => _FrameSliderState();
}

class _FrameSliderState extends State<FrameSlider> {
  int? _hoveredIndex;

  bool get enabled => widget.onChanged != null;
  bool _isDragging = false;

  int _findValueFromPosition(
    Offset localPosition,
    double squareWidth, {
    bool useSnap = false,
  }) {
    final min = widget.min;
    final itemCount = widget.max - min + 1;

    int index = (localPosition.dx ~/ squareWidth);
    if (widget.wrapWhenDragging) {
      index = (index % itemCount + itemCount) % itemCount;
    } else {
      index = index.clamp(0, itemCount - 1);
    }

    int newValue = min + index;

    if (useSnap) {
      final frameMarkers = widget.frameMarkers;
      if (frameMarkers != null && frameMarkers.isNotEmpty) {
        final nearestMarker = frameMarkers.reduce((a, b) {
          return (a - newValue).abs() < (b - newValue).abs() ? a : b;
        });

        final nearestMarkerPosition = (nearestMarker - min) * squareWidth;
        final newValuePosition = (newValue - min) * squareWidth;
        const snapThresholdPixels = 9.0;
        if ((nearestMarkerPosition - newValuePosition).abs() <=
            snapThresholdPixels) {
          newValue = nearestMarker;
        }
      }
    }

    return newValue;
  }

  void _updateValue(
    Offset localPosition,
    double squareWidth,
    bool useSpaceBasedSnap,
  ) {
    if (!enabled) return;
    _isDragging = true;

    final min = widget.min;
    int newValue = _findValueFromPosition(localPosition, squareWidth);

    // Snapping
    SnapMode snapMode = widget.snapMode;
    // Snap mode keyboard overrides
    final keyboard = HardwareKeyboard.instance;
    if (keyboard.isShiftPressed) {
      snapMode = .none;
    }
    if (keyboard.isControlPressed) {
      snapMode = .force;
    }

    if (snapMode != .none) {
      final frameMarkers = widget.frameMarkers;
      if (frameMarkers != null && frameMarkers.isNotEmpty) {
        final nearestMarker = frameMarkers.reduce((a, b) {
          return (a - newValue).abs() < (b - newValue).abs() ? a : b;
        });

        // Snap within distance
        if (snapMode == .nearest) {
          if (useSpaceBasedSnap) {
            final nearestMarkerPosition = (nearestMarker - min) * squareWidth;
            final newValuePosition = (newValue - min) * squareWidth;
            const snapThresholdPixels = 10.0;
            if ((nearestMarkerPosition - newValuePosition).abs() <=
                snapThresholdPixels) {
              newValue = nearestMarker;
            }
          } else {
            const snapThreshold = 2;
            if ((nearestMarker - newValue).abs() <= snapThreshold) {
              newValue = nearestMarker;
            }
          }
        } else {
          newValue = nearestMarker;
        }
      }
    }

    if (newValue != widget.value) {
      widget.onChanged?.call(newValue);
    }
  }

  bool willUseContinuous(double squareWidth) {
    return squareWidth < widget.minCellWidth;
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
    final markerColor = widget.markerColor ?? Colors.orange;
    final markerInactiveColor = markerColor.withValues(alpha: 0.4);
    final markerTrackColors = (
      hover: markerColor,
      inactive: markerInactiveColor,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final squareWidth = totalWidth / itemCount;
        final useContinuous = willUseContinuous(squareWidth);

        Widget continuousSlider() => CustomPaint(
          painter: _ContinuousSliderPainter(
            min: widget.min,
            max: widget.max,
            value: widget.value,
            activeColor: activeColor,
            inactiveColor: inactiveColor,
            markerColor: markerInactiveColor,
            activeMarkerColor: markerColor,
            cellHeight: widget.cellHeight,
            selectedCellHeight: widget.selectedCellHeight,
            borderRadius: widget.borderRadius,
            frameMarkers: widget.frameMarkers,
            thumbWidth: widget.borderRadius * 2,
          ),
        );

        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onPanDown: enabled
              ? (details) => _updateValue(
                  details.localPosition,
                  squareWidth,
                  useContinuous,
                )
              : null,
          onPanUpdate: enabled
              ? (details) => _updateValue(
                  details.localPosition,
                  squareWidth,
                  useContinuous,
                )
              : null,
          onPanEnd: (details) => _isDragging = false,
          onPanCancel: () => _isDragging = false,
          onSecondaryTapDown: enabled
              ? (details) {
                  if (widget.onSecondaryTapOnFrame == null) return;
                  final frame = _findValueFromPosition(
                    details.localPosition,
                    squareWidth,
                    useSnap: true,
                  );
                  widget.onSecondaryTapOnFrame?.call(frame);
                }
              : null,
          onSecondaryTapUp: (_) => _isDragging = false,
          onSecondaryTapCancel: () => _isDragging = false,
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

                      final isMarkerFrame =
                          widget.frameMarkers?.contains(boxValue) ?? false;

                      final overrideColors =
                          (isMarkerFrame ? markerTrackColors : null) ??
                          const (hover: null, inactive: null);

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
                                      ? (isMarkerFrame
                                            ? markerColor
                                            : activeColor)
                                      : isHovered
                                      ? (_isDragging
                                                ? inactiveColor
                                                : overrideColors.hover) ??
                                            hoverColor
                                      : overrideColors.inactive ??
                                            inactiveColor,
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
    required this.markerColor,
    required this.activeMarkerColor,
    required this.cellHeight,
    required this.selectedCellHeight,
    required this.borderRadius,
    required this.thumbWidth,
    this.frameMarkers,
  });

  final int min;
  final int max;
  final int value;
  final Color activeColor;
  final Color inactiveColor;
  final Color markerColor;
  final Color activeMarkerColor;
  final double cellHeight;
  final double selectedCellHeight;
  final double borderRadius;
  final double thumbWidth;
  final Iterable<int>? frameMarkers;

  @override
  void paint(Canvas canvas, Size size) {
    final itemCount = max - min + 1;
    final squareWidth = size.width / itemCount;

    final selectedIsMarker = frameMarkers?.contains(value) ?? false;

    final paintInactive = Paint()..color = inactiveColor;
    final paintActive = Paint()
      ..color = selectedIsMarker ? activeMarkerColor : activeColor;

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

    // Markers
    if (frameMarkers != null) {
      final paintMarker = Paint()..color = markerColor;
      final markerWidth = thumbWidth * 0.35;

      for (final marker in frameMarkers!) {
        if (marker < min) continue;
        if (marker > max) continue;

        final markerX = (marker - min) * squareWidth;
        final markerRect = Rect.fromLTWH(
          markerX - (markerWidth / 2),
          (size.height - cellHeight) / 2,
          markerWidth,
          cellHeight,
        );

        canvas.drawRRect(
          RRect.fromRectAndRadius(markerRect, Radius.circular(borderRadius)),
          paintMarker,
        );
      }
    }

    // Thumb
    final selectedX = (value - min) * squareWidth;
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
