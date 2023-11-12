import 'package:flutter/material.dart';

const grayColor = Color(0x55000000);
const grayStyle = TextStyle(color: grayColor);
const double smallTextSize = 12;
const smallGrayStyle = TextStyle(color: grayColor, fontSize: smallTextSize);
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
