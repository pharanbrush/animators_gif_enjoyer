import 'package:flutter/material.dart';

const double smallTextSize = 12;
const Color focusRangeColor = Color.fromARGB(255, 137, 175, 76);

const double borderRadius = 6;
const Radius borderRadiusRadius = Radius.circular(borderRadius);
const OutlinedBorder buttonShape = RoundedRectangleBorder(
  borderRadius: BorderRadius.all(borderRadiusRadius),
);

const ButtonStyle buttonStyle = ButtonStyle(
  shape: MaterialStatePropertyAll(buttonShape),
);

ThemeData focusTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: focusRangeColor,
    primary: focusRangeColor,
  ),
);

ThemeData paleButtonTheme = ThemeData(
  colorScheme:
      ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 128, 170, 190)),
  textButtonTheme: const TextButtonThemeData(style: buttonStyle),
  iconButtonTheme: const IconButtonThemeData(style: buttonStyle),
  buttonTheme: const ButtonThemeData(shape: buttonShape),
);

extension EnjoyerColorExtensions on ColorScheme {
  Color get grayColor => onSurface.withAlpha(0x55);
}

extension EnjoyerThemeExtensions on ThemeData {
  TextStyle get grayStyle => TextStyle(color: colorScheme.grayColor);
  TextStyle get smallGrayStyle =>
      TextStyle(color: colorScheme.grayColor, fontSize: smallTextSize);
}

ThemeData getEnjoyerTheme() {
  const Color interfaceColor = Color.fromARGB(255, 107, 152, 204);

  return ThemeData(
    scaffoldBackgroundColor: Colors.white,
    colorScheme: ColorScheme.fromSeed(
      seedColor: interfaceColor,
      primary: interfaceColor,
      scrim: const Color(0xDD000000),
    ),
    textButtonTheme: const TextButtonThemeData(style: buttonStyle),
    iconButtonTheme: const IconButtonThemeData(style: buttonStyle),
    buttonTheme: const ButtonThemeData(shape: buttonShape),
    useMaterial3: true,
  );
}

ThemeData getEnjoyerThemeDark() {
  const Color interfaceColor = Color.fromARGB(255, 107, 152, 204);
  const Color darkBackground = Color(0xFF161616);

  return ThemeData(
    scaffoldBackgroundColor: darkBackground,
    colorScheme: ColorScheme.fromSeed(
      brightness: Brightness.dark,
      seedColor: interfaceColor,
      primary: interfaceColor,
      scrim: const Color(0xDD000000),
    ),
    textButtonTheme: const TextButtonThemeData(style: buttonStyle),
    iconButtonTheme: const IconButtonThemeData(style: buttonStyle),
    buttonTheme: const ButtonThemeData(shape: buttonShape),
    useMaterial3: true,
  );
}

const defaultThemeMode = ThemeMode.light;

class ThemeContext extends InheritedWidget {
  ThemeContext({
    super.key,
    required super.child,
    required ThemeMode initialThemeMode,
  }) : themeMode = ValueNotifier(initialThemeMode);

  final ValueNotifier<ThemeMode> themeMode;

  static ThemeContext? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ThemeContext>();
  }

  @override
  bool updateShouldNotify(ThemeContext oldWidget) {
    return false;
  }
}
