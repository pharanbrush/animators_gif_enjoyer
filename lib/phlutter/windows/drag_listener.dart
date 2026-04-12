import 'package:flutter/material.dart';

class DiscreteDragListener extends StatefulWidget {
  const DiscreteDragListener({
    super.key,
    this.sensitivity = 0.17,
    required this.onDragUpdate,
    this.child,
  });

  final double sensitivity;
  final Function(Offset delta) onDragUpdate;
  final Widget? child;

  @override
  State<DiscreteDragListener> createState() => _DiscreteDragListenerState();
}

class _DiscreteDragListenerState extends State<DiscreteDragListener> {
  Offset offsetAccumulator = Offset.zero;

  static bool isOppositeDirections(double a, double b) =>
      a < 0 && b > 0 || a > 0 && b < 0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        final zeroX = isOppositeDirections(
          offsetAccumulator.dx,
          details.delta.dx,
        );

        final zeroY = isOppositeDirections(
          offsetAccumulator.dy,
          details.delta.dy,
        );

        if (zeroX || zeroY) {
          offsetAccumulator = Offset(
            zeroX ? 0 : offsetAccumulator.dx,
            zeroY ? 0 : offsetAccumulator.dy,
          );
        }

        final sensitivity = widget.sensitivity;
        offsetAccumulator += details.delta.scale(sensitivity, sensitivity);

        int outputX = (offsetAccumulator.dx).truncate();
        int outputY = (offsetAccumulator.dy).truncate();

        final outputDelta = Offset(
          outputX.toDouble(),
          outputY.toDouble(),
        );
        debugPrint("$offsetAccumulator :: $outputDelta");

        offsetAccumulator = offsetAccumulator - outputDelta;

        widget.onDragUpdate(outputDelta);
      },
      onPanEnd: (details) {
        offsetAccumulator = Offset.zero;
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.resizeLeftRight,
        child: widget.child,
      ),
    );
  }
}
