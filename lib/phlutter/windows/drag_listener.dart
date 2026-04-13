import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DiscreteDragListener extends StatefulWidget {
  const DiscreteDragListener({
    super.key,
    this.sensitivity = 0.1,
    this.shiftMultiplier = 0.1,
    this.onDragStart,
    this.onDragUpdate,
    this.onDragEnd,
    this.child,
    this.cursor = MouseCursor.defer,
  });

  final double sensitivity;
  final double shiftMultiplier;

  final Function(DragStartDetails details)? onDragStart;
  final Function(Offset delta)? onDragUpdate;
  final Function(DragEndDetails details)? onDragEnd;
  final Widget? child;
  final MouseCursor cursor;

  @override
  State<DiscreteDragListener> createState() => _DiscreteDragListenerState();
}

class _DiscreteDragListenerState extends State<DiscreteDragListener> {
  Offset deltaAccumulator = Offset.zero;

  static bool isOppositeDirections(double a, double b) =>
      a < 0 && b > 0 || a > 0 && b < 0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (details) {
        widget.onDragStart?.call(details);
      },
      onPanUpdate: (details) {
        final inputDelta = details.delta;
        final zeroX = isOppositeDirections(
          deltaAccumulator.dx,
          inputDelta.dx,
        );

        final zeroY = isOppositeDirections(
          deltaAccumulator.dy,
          inputDelta.dy,
        );

        if (zeroX || zeroY) {
          deltaAccumulator = Offset(
            zeroX ? 0 : deltaAccumulator.dx,
            zeroY ? 0 : deltaAccumulator.dy,
          );
        }

        final sensitivity = widget.sensitivity;
        final isHoldingShift = HardwareKeyboard.instance.isShiftPressed;
        final multipler = isHoldingShift ? widget.shiftMultiplier : sensitivity;
        deltaAccumulator += inputDelta.scale(multipler, multipler);

        final outputDelta = Offset(
          (deltaAccumulator.dx).truncate().toDouble(),
          (deltaAccumulator.dy).truncate().toDouble(),
        );

        deltaAccumulator = deltaAccumulator - outputDelta;

        widget.onDragUpdate?.call(outputDelta);
      },
      onPanEnd: (details) {
        deltaAccumulator = Offset.zero;
        widget.onDragEnd?.call(details);
      },
      child: MouseRegion(
        cursor: widget.cursor,
        child: widget.child,
      ),
    );
  }
}
