import 'package:flutter/material.dart';

const visualDensity = VisualDensity(horizontal: -2, vertical: -2);

const sliderPadding = EdgeInsets.symmetric(vertical: 3, horizontal: 3);

const suffixIconConstraints = BoxConstraints(
  minWidth: 15,
  minHeight: 15,
);

InputDecorationTheme inputDecorationTheme({
  required BorderRadius borderRadius,
  required Color borderColor,
  required Color enabledBorderColor,
}) {
  return InputDecorationTheme(
    isDense: true, // makes the field more compact
    contentPadding: const .symmetric(horizontal: 8, vertical: 8),
    filled: true,
    fillColor: const Color(0xFF_ffffff),
    // focusColor: const Color(0xFF23262E),
    border: OutlineInputBorder(
      borderSide: BorderSide(
        color: borderColor,
        width: 0,
      ),
      borderRadius: borderRadius,
    ),
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(
        color: enabledBorderColor,
        width: 0,
      ),
      borderRadius: borderRadius,
    ),
  );
}

DropdownMenuThemeData dropDownMenuThemeData({
  required double fieldHeight,
  required BorderRadius borderRadius,
  VisualDensity? visualDensity,
}) {
  return DropdownMenuThemeData(
    inputDecorationTheme: InputDecorationTheme(
      visualDensity:
          visualDensity ?? const VisualDensity(horizontal: -3, vertical: -2),
      contentPadding: const .symmetric(horizontal: 4),
      constraints: .tight(.fromHeight(fieldHeight)),
      border: OutlineInputBorder(
        borderRadius: borderRadius,
      ),
      suffixIconConstraints: BoxConstraints(
        maxWidth: fieldHeight,
        maxHeight: fieldHeight,
        minWidth: fieldHeight,
        minHeight: fieldHeight,
      ),
    ),
  );
}

class VerticalPillSliderThumbShape extends SliderComponentShape {
  const VerticalPillSliderThumbShape({this.height = 20});

  static const double hitRadius = 12;

  final double height;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return const Size.fromRadius(hitRadius);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = sliderTheme.thumbColor ?? Colors.grey;

    const double width = 5;
    const double cornerRadius = 4;

    final rrect = RRect.fromRectXY(
      Rect.fromCenter(center: center, width: width, height: height),
      cornerRadius,
      cornerRadius,
    );

    final canvas = context.canvas;
    canvas.drawRRect(rrect, paint);
  }
}

class VerticalPillRangeSliderThumbShape extends RangeSliderThumbShape {
  const VerticalPillRangeSliderThumbShape({this.height = 20});

  static const double hitRadius = 12;

  final double height;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return const Size.fromRadius(hitRadius);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    bool isDiscrete = false,
    bool isEnabled = true,
    bool isOnTop = true,
    TextDirection textDirection = TextDirection.ltr,
    required SliderThemeData sliderTheme,
    Thumb thumb = .start,
    bool isPressed = false,
  }) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = sliderTheme.thumbColor ?? Colors.grey;

    const double width = 5;
    const double cornerRadius = 4;

    final rrect = RRect.fromRectXY(
      Rect.fromCenter(center: center, width: width, height: height),
      cornerRadius,
      cornerRadius,
    );

    final canvas = context.canvas;
    canvas.drawRRect(rrect, paint);
  }
}
