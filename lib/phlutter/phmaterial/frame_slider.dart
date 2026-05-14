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
  late FocusNode _focusNode;

  bool get enabled => widget.onChanged != null;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

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

    bool willSnap = false;
    if (snapMode != .none) {
      final frameMarkers = widget.frameMarkers;
      if (frameMarkers != null && frameMarkers.isNotEmpty) {
        final nearestMarker = frameMarkers.reduce((a, b) {
          return (a - newValue).abs() < (b - newValue).abs() ? a : b;
        });

        // Snap within distance

        if (snapMode == .nearest) {
          if (useSpaceBasedSnap) {
            const snapThresholdPixels = 10.0;
            final nearestMarkerPosition = (nearestMarker - min) * squareWidth;
            final newValuePosition = (newValue - min) * squareWidth;
            if ((nearestMarkerPosition - newValuePosition).abs() <=
                snapThresholdPixels) {
              willSnap = true;
            }
          } else {
            final snapThresholdBoxes = (20.0 / squareWidth).ceil();
            if ((nearestMarker - newValue).abs() <= snapThresholdBoxes) {
              willSnap = true;
            }
          }
        } else {
          willSnap = true;
        }

        if (willSnap) {
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

  void _updateHoveredIndex(Offset localPosition, double squareWidth) {
    setState(() {
      _hoveredIndex = _findValueFromPosition(localPosition, squareWidth);
    });
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
    final hoveredMarkerColor = markerColor.withValues(alpha: .8);

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final squareWidth = totalWidth / itemCount;
        final useContinuous = willUseContinuous(squareWidth);

        return Focus(
          focusNode: _focusNode,
          child: GestureDetector(
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
            onPanEnd: (details) {
              _focusNode.requestFocus();
              _isDragging = false;
            },
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
              child: MouseRegion(
                onEnter: (event) =>
                    _updateHoveredIndex(event.localPosition, squareWidth),
                onHover: (event) =>
                    _updateHoveredIndex(event.localPosition, squareWidth),
                onExit: (_) => setState(() => _hoveredIndex = null),
                child: useContinuous
                    ? CustomPaint(
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
                      )
                    : CustomPaint(
                        painter: _DiscreteSliderPainter(
                          min: widget.min,
                          max: widget.max,
                          value: widget.value,
                          hoveredIndex: _isDragging
                              ? widget.value
                              : _hoveredIndex,
                          cellHeight: widget.cellHeight,
                          selectedCellHeight: widget.selectedCellHeight,
                          borderRadius: widget.borderRadius,
                          activeColor: activeColor,
                          inactiveColor: inactiveColor,
                          hoverColor: hoverColor,
                          markerColor: markerColor,
                          hoveredMarkerColor: hoveredMarkerColor,
                          markerInactiveColor: markerInactiveColor,
                          frameMarkers: widget.frameMarkers,
                          dividerColor: colorScheme.outlineVariant,
                          dividerWidth: 1,
                        ),
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DiscreteSliderPainter extends CustomPainter {
  final int min;
  final int max;
  final int value;
  final int? hoveredIndex;
  final double cellHeight;
  final double selectedCellHeight;
  final double borderRadius;
  final Color activeColor;
  final Color inactiveColor;
  final Color hoverColor;
  final Color hoveredMarkerColor;
  final Color markerColor;
  final Color markerInactiveColor;
  final Iterable<int>? frameMarkers;
  final Color dividerColor;
  final double dividerWidth;

  _DiscreteSliderPainter({
    required this.min,
    required this.max,
    required this.value,
    required this.hoveredIndex,
    required this.cellHeight,
    required this.selectedCellHeight,
    required this.borderRadius,
    required this.activeColor,
    required this.inactiveColor,
    required this.hoverColor,
    required this.hoveredMarkerColor,
    required this.markerColor,
    required this.markerInactiveColor,
    required this.frameMarkers,
    this.dividerColor = Colors.black,
    this.dividerWidth = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final itemCount = max - min + 1;
    final squareWidth = size.width / itemCount;
    final r = Radius.circular(borderRadius);

    // Track
    final trackTop = (size.height - cellHeight) / 2;
    final trackPaint = Paint()..color = inactiveColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, trackTop, size.width, cellHeight),
        r,
      ),
      trackPaint,
    );

    // Boxes
    const firstBox = 0;
    final lastBox = itemCount - 1;
    void drawBox(
      int boxValue, {
      bool isSelected = false,
      bool isHovered = false,
      bool isMarkerFrame = false,
    }) {
      final i = boxValue - min;
      if (i < firstBox || i > lastBox) return;
      if (!isSelected && !isHovered && !isMarkerFrame) return;

      final cellHeight = isSelected ? selectedCellHeight : this.cellHeight;
      final cellTop = (size.height - cellHeight) / 2;

      final rect = Rect.fromLTWH(
        i * squareWidth,
        cellTop,
        squareWidth,
        cellHeight,
      );

      BorderRadius radius = BorderRadius.zero;
      if (isSelected) {
        radius = BorderRadius.all(r);
      } else if (i == firstBox) {
        radius = BorderRadius.horizontal(left: r);
      } else if (i == lastBox) {
        radius = BorderRadius.horizontal(right: r);
      }

      Color fillColor;
      if (isSelected) {
        fillColor = isMarkerFrame ? markerColor : activeColor;
      } else if (isHovered) {
        fillColor = isMarkerFrame ? hoveredMarkerColor : hoverColor;
      } else {
        fillColor = isMarkerFrame ? markerInactiveColor : inactiveColor;
      }

      final paint = Paint()..color = fillColor;
      final rrect = RRect.fromRectAndCorners(
        rect,
        topLeft: radius.topLeft,
        topRight: radius.topRight,
        bottomLeft: radius.bottomLeft,
        bottomRight: radius.bottomRight,
      );
      canvas.drawRRect(rrect, paint);
    }

    // Markers
    final markers = frameMarkers;
    if (markers != null) {
      for (final frameNumber in markers) {
        if (frameNumber == hoveredIndex) continue;
        if (frameNumber == value) continue;
        drawBox(
          frameNumber,
          isMarkerFrame: true,
          isHovered: false,
        );
      }
    }

    // Hovered
    if (hoveredIndex != null) {
      drawBox(
        hoveredIndex!,
        isHovered: true,
        isMarkerFrame: markers?.contains(hoveredIndex!) ?? false,
      );
    }

    // Dividers
    final beforeSelectedBoxValue = value - min - 1;
    for (int i = 0; i < itemCount; i++) {
      if (i == beforeSelectedBoxValue) {
        // Skip this line and the next one to remove the lines on both sides of the selected box.
        i++;
        continue;
      }

      if (i < itemCount - 1) {
        final linePaint = Paint()
          ..color = dividerColor
          ..strokeWidth = dividerWidth;
        final x = (i + 1) * squareWidth;
        canvas.drawLine(
          Offset(x, trackTop + 1),
          Offset(x, trackTop + cellHeight - 1),
          linePaint,
        );
      }
    }

    // Selected
    drawBox(
      value,
      isSelected: true,
      isHovered: value == hoveredIndex,
      isMarkerFrame: markers?.contains(value) ?? false,
    );
  }

  @override
  bool shouldRepaint(covariant _DiscreteSliderPainter old) {
    return old.value != value ||
        old.hoveredIndex != hoveredIndex ||
        old.frameMarkers != frameMarkers ||
        old.dividerColor != dividerColor ||
        old.dividerWidth != dividerWidth;
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
