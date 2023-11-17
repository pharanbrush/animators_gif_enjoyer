import 'package:flutter/material.dart';

const double smallTextSize = 12;
const Color focusRangeColor = Color.fromARGB(255, 137, 175, 76);

const double borderRadius = 5;
const Radius borderRadiusRadius = Radius.circular(borderRadius);
const OutlinedBorder appButtonShape = RoundedRectangleBorder(
  borderRadius: BorderRadius.all(borderRadiusRadius),
);

const ButtonStyle buttonStyle = ButtonStyle(
  shape: MaterialStatePropertyAll(appButtonShape),
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
  buttonTheme: const ButtonThemeData(shape: appButtonShape),
);

extension EnjoyerColorExtensions on ColorScheme {
  Color get faintGrayColor => onSurface.withAlpha(0x33);
  Color get grayColor => onSurface.withAlpha(0x66);
  Color get mutedSurfaceColor => onSurface.withAlpha(0x99);
}

extension EnjoyerThemeExtensions on ThemeData {
  TextStyle get grayStyle => TextStyle(color: colorScheme.grayColor);
  TextStyle get smallGrayStyle =>
      TextStyle(color: colorScheme.grayColor, fontSize: smallTextSize);
}

const lightThemeString = 'light';
const grayThemeString = 'gray';
const darkThemeString = 'dark';
const blackThemeString = 'black';
//const systemThemeString = 'system';
const defaultThemeString = lightThemeString;

String getNextCycleTheme(String currentThemeString) =>
    switch (currentThemeString) {
      lightThemeString => blackThemeString,
      blackThemeString => darkThemeString,
      darkThemeString => grayThemeString,
      grayThemeString => lightThemeString,
      _ => lightThemeString,
    };

/// Use `lightThemeString`, `grayThemeString` or `darkThemeString`.
/// Returns light theme by default.
ThemeData getThemeFromString(String themeString) => switch (themeString) {
      lightThemeString => getEnjoyerTheme(),
      grayThemeString => getEnjoyerThemeGray(),
      darkThemeString => getPhriendsTheme(),
      blackThemeString => getEnjoyerThemeBlack(),
      _ => getEnjoyerTheme(),
    };

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
    buttonTheme: const ButtonThemeData(shape: appButtonShape),
    useMaterial3: true,
  );
}

ThemeData getPhriendsTheme() {
  const Color interfaceColor = Color(0xFF5865F2);
  //const Color panelBackground = Color(0xFF2B2D31);
  const Color appBackground = Color(0xFF313338);
  const Color tooltipBackgroundColor = Color(0xFF111214);
  const Color tooltipTextColor = Color(0xEEDBDEE1);

  const tooltipTheme = TooltipThemeData(
    verticalOffset: 26,
    textStyle: TextStyle(
      color: tooltipTextColor,
      fontWeight: FontWeight.w500,
      fontSize: 13,
    ),
    padding: EdgeInsets.symmetric(
      vertical: 7,
      horizontal: 13,
    ),
    decoration: BoxDecoration(
      color: tooltipBackgroundColor,
      borderRadius: BorderRadius.all(Radius.circular(5)),
    ),
  );

  return ThemeData(
    scaffoldBackgroundColor: appBackground,
    colorScheme: ColorScheme.fromSeed(
      brightness: Brightness.dark,
      seedColor: interfaceColor,
      primary: interfaceColor,
      scrim: const Color(0xDD000000),
    ),
    tooltipTheme: tooltipTheme,
    textButtonTheme: const TextButtonThemeData(style: buttonStyle),
    iconButtonTheme: const IconButtonThemeData(style: buttonStyle),
    buttonTheme: const ButtonThemeData(shape: appButtonShape),
    useMaterial3: true,
  );
}

ThemeData getEnjoyerThemeGray() {
  const Color interfaceColor = Color.fromARGB(255, 107, 152, 204);
  const Color background = Color.fromARGB(255, 115, 115, 115);

  return ThemeData(
    scaffoldBackgroundColor: background,
    colorScheme: ColorScheme.fromSeed(
      brightness: Brightness.dark,
      seedColor: interfaceColor,
      primary: interfaceColor,
      scrim: const Color(0xDD000000),
    ),
    textButtonTheme: const TextButtonThemeData(style: buttonStyle),
    iconButtonTheme: const IconButtonThemeData(style: buttonStyle),
    buttonTheme: const ButtonThemeData(shape: appButtonShape),
    useMaterial3: true,
  );
}

ThemeData getEnjoyerThemeBlack() {
  const Color interfaceColor = Color.fromARGB(255, 107, 152, 204);
  const Color darkBackground = Color(0xFF181818);

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
    buttonTheme: const ButtonThemeData(shape: appButtonShape),
    useMaterial3: true,
  );
}

const defaultThemeMode = ThemeMode.light;

class ThemeContext extends InheritedWidget {
  ThemeContext({
    super.key,
    required super.child,
    required ThemeData initialThemeData,
  }) : themeData = ValueNotifier(initialThemeData);

  final ValueNotifier<ThemeData> themeData;

  static ThemeContext? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ThemeContext>();
  }

  @override
  bool updateShouldNotify(ThemeContext oldWidget) {
    return false;
  }
}
