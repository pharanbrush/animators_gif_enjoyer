import 'package:flutter/material.dart';

class DiscreteDragListener extends StatefulWidget {
  const DiscreteDragListener({
    super.key,
    this.sensitivity = 0.1,
    required this.onDragUpdate,
    this.child,
    this.cursor = MouseCursor.defer,
  });

  final double sensitivity;
  final Function(Offset delta) onDragUpdate;
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
        deltaAccumulator += inputDelta.scale(sensitivity, sensitivity);

        final outputDelta = Offset(
          (deltaAccumulator.dx).truncate().toDouble(),
          (deltaAccumulator.dy).truncate().toDouble(),
        );

        deltaAccumulator = deltaAccumulator - outputDelta;

        widget.onDragUpdate(outputDelta);
      },
      onPanEnd: (_) => deltaAccumulator = Offset.zero,
      child: MouseRegion(
        cursor: widget.cursor,
        child: widget.child,
      ),
    );
  }
}
