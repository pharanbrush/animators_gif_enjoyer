import 'package:flutter/material.dart';

class DebugContainer extends StatelessWidget {
  const DebugContainer(this.color, {super.key, required this.child});

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: color),
      child: child,
    );
  }
}
