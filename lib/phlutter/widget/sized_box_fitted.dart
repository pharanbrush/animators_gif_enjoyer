import 'package:flutter/widgets.dart';

/// [SizedBoxFitted] forces a widget to resize when it doesn't resize according to SizedBox.
class SizedBoxFitted extends StatelessWidget {
  const SizedBoxFitted({
    super.key,
    this.width,
    this.height,
    required this.child,
  });

  final double? width;
  final double? height;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: key,
      width: width,
      height: height,
      child: FittedBox(child: child),
    );
  }
}
