import 'dart:math' as math;

import 'package:flutter/material.dart';

class DebugContainer extends StatefulWidget {
  const DebugContainer({
    super.key,
    required this.child,
    this.alpha = 0.3,
    this.enabled = true,
  });

  final Widget child;
  final double alpha;
  final bool enabled;

  @override
  State<DebugContainer> createState() => _DebugContainerState();
}

class _DebugContainerState extends State<DebugContainer> {
  late final Color color;

  static const colors = <Color>[
    Colors.red,
    Colors.amber,
    Colors.blue,
    Colors.cyan,
    Colors.purple,
    Colors.pink,
    Colors.orange,
    Colors.deepOrange,
    Colors.lightGreen,
    Colors.lime,
    Colors.indigoAccent,
    Colors.green,
    Colors.brown,
  ];

  @override
  void initState() {
    color = colors[math.Random().nextInt(colors.length)].withValues(
      alpha: widget.alpha,
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.enabled) {
      return Container(
        color: color,
        child: widget.child,
      );
    } else {
      return widget.child;
    }
  }
}

extension DebugWrapper on Widget {
  DebugContainer debugContainer() {
    return DebugContainer(child: this);
  }
}
