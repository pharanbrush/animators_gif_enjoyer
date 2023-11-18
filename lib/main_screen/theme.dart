import 'dart:convert';

import 'package:flutter/material.dart';

// Settings

const bool _cacheThemes = true;

//
// App
//

const _appIconData =
    'iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAIMElEQVR4XsWVaYxeVRnHf8+52/tOZ+u002VautAB2ykDLZaCLQEEQyhBG2NDNGqEGvzAlpjIh6Ym1i3RD40YYuIXIsZPBkmIGhdMisbK0tbu0wKltNDFdtpZ3pl3u8s5x3dO7g1vpgQ+GU/y3Ofc5Tz///N/znmu7N692+f/ONS2bds6nti+fdPXH3xw3ubNm/+nZObPny/bH3lkyeOPPvrA/fffHwL4fVNT67Lz518pG5MMl0rnhu+99/f09OyxCxacSZKkWq/XG11dXT1GZ9rUxtH/fnGJsbYG+AIdmWVUCWVtmDYWLaBiQ72pJfmgETUr5QH7wJYtSzrC8GEzNnavHR9fl01OTqwaHPwW8LpUDx9+ilrtWat1irWRhCFAIxoa0l5X11lr7SnAb3mL0Ytrr/2mX1cuR2BDwAcSaykDDeAKcMaKVER51lu0em95zWc/l567eF8L3KJURJYBROHatc/84oUXnvPF8643WYbMvAxDwpUraQGX8X2Am4DVgBIRscqjvO4L0hj5G2bqsjVJXbBYAGvtHKAPZDVgrLXKK3dvNfXmVZtmPkEQ2iyzEkU+SYIeHb21t7dXpHbgwL9Mvb7JmzuXaNUqJIpABGstAMYYtDaIgPI8APTkJeLTb2CqY1idYhpTgGBNBqKshOUkWHqTigY3KfECDYT66lX0xAQiAsYgSp2b6utbL9W9eyt+f393sHw5EoYYq/nPpfOcPHmcK6MTzO9fwNCamymXywShTymMcDHiKmZqlPTyu46ARHPAAsojGBiCrn4yA6C5MnaOwC/T19VLqCKdXb7k2XrdyODgnRKfOVP1ens7VE+PvHv6HZ7/9c8ZeXs/xw6eZfTiNP2LO/nKN+9m25YdrFi2ilIpIgx8LE4ebBZjkgZYC6IckTg1JFnKO6eOtuL9jJMnTjF8ew8dHZ0smXub/drDT8Y9ygubnv8N0VpPiEjvP/f+gxf/tJuxyvv87vkTeCogjmPAcvdDS7lnyxruGd7Bp9dvJPB98rpjjaEYFly56o0mh4/uY+eO7zJy/ATNZsy8hSWe/tEtlDoCKhf67Fcf+gnlzu5nlTGm9/DhQ/xx749Zsa7CX186hdGu9nieh4jixMFxrFflldeeo1qtYgtwC1YECxhHRmNaduXqBb7/vV0cOzoCiIszcSXmz799H8Qy97oJXvrDL22apFv9ickxXn71pwzcmHJ8/zi1igUgy7JiEzI9mTA10WTRQIWz50e4pXsTYHEktMYaC54CUXiesOfvf+H4sbdcDGst4jY1nB6pkMUwp9uTqfKIjI+NrvSPvLWHW+9ThKXFvPryRZIkoVQqOa+1JggC0liz4oZ5DC7dzNCn1ufZG2wcY5qxU0GCAGZMCTcPry/AAQqP7wfcMLSQrt6Q2vKUt986JGrRghXUJhRR5CPi5JqpvQMHnO/oai1cvoHNQ4/jqQgndabRjSZGa2yaoet1TK3mFFl/yx384Ie7UErl4B8SqYzHeJ7CZH7LPNSNKzew0PsSzZpww/A8tyCKIgDCyCcMQ77z7R3cseoZfNXp3ps0Izl9hsaREer7DlLff4jG0RPErWfZ+KQD2r79MZ586gm6ujrxfM+Bp0mGHygqY4azb67gwS2fR5rN2IoSTp7ax3uX9/DMY78CUfT393HnXZ/hoS1fZMNtG8FaLLh6J2c/oHlsxM2L5xQmEK1dQ7ByGSAcPXKYnTt3cvq9d1m4NGLrl29neHAL9921lXJpDnL56rjt7e5EoK3zadI0c9nn9c49zjdef5P00hUctHLZUQysJVi2hGjdMIKAuCtxEqOUuP2llEJQIKAmp6a5OjZJrdEkSVLAtdxrwI0zNydYfSOqI8ROO7kBwZGrjCO+oObPAwsWxxgESlGJqGWSf5umKdPVOr7ONFPVGrVGw2Xe19tDZ0cZoB0cLIUCSHc3pXvuIj5yjOTCKBYDQDA4SDi8FimXc/C2DiUgVtDWMDVdo96IybTGL5qKTjOHMD5ZwUkVhe2gbl4o4uaeR7B+HTL/PMl77xNcvwJ/yWJEJO8RgkhBoHDWJdtoxjSTxH2rHAIggOep/BgmGO2yzw1MO7gDALB4S5dQ3rQRf2ARUJDM4YpvcXEccCt75/PMUDaXulhsjAPGlSSf22vACwObZVSOHSar1ygGs0lY0Ma4mKnOXDLF8B5/8uldeZ3bmoYAIILbsRQlaAsIYJKEyUMHMMbSvHiBcP4C1xElXywCWhvAtjKvUpmuOQyhGOQKQBHVHb9Gs0mSpm5Bsxk7cgU4OVEdN5k48CalRQPM3bCRzrXDTOx7g6yW/6zccXbGdK3B5HTVqZvjtSnwxFO7iqCm8MaiW+Z5+ZHJMrdjsdYRjKtVKvvfIGyBl69bhgVShDgs0Th6COmbR6xdGXEnrNZwTUt5qugNzkQpfADaWYng2BtNkkKmDWKt6w1ZliFxg/jIQeyy64laBBpxArgaY0pl4gUDpK/tRa8ZRqIoLwGIi2tB3BwAAeToiXdsa1AcR2nbjACuawkuc6UEOznpGpKe04Xv++5Z0PJZpp1S2hjU9BQEAbbc4cAEXLZKHLr1PG8GU3mewhEw+c4qPDmJNnPvPKUcgOT3RWbtCrZvMgrwQvLcVOGVwrdwTYD2UagjgJuBAxcR5wtAC+RO3IVPHG69osj6o7IHREkBUDSna4jaWTnMBrcfc+8U+CijAMolVNcGmv0r/uSk20mLIOAU0IAp0m5naXNVZtfEgnauQOWTWcym396KxWHnUDmRdhLGHbGZiUNFsFYVr2fLn1s26xlYDGBmK/1f3GiTRH873g8AAAAASUVORK5CYII=';

final appIconDataBytes = const Base64Decoder().convert(_appIconData);

//
// Common
//

const double smallTextSize = 12;
const Color focusRangeColor = Color.fromARGB(255, 137, 175, 76);
const Color defaultActiveColor = Colors.orange;

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

//
// Extensions
//

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

//
// Theme getters
//

const lightThemeString = 'light';
const grayThemeString = 'gray';
const darkThemeString = 'dark';
const blackThemeString = 'black';
//const systemThemeString = 'system';
const defaultThemeString = lightThemeString;

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
ThemeData getThemeFromString(String themeString) {
  if (_cacheThemes) {
    return switch (themeString) {
      lightThemeString => _cache.light,
      grayThemeString => _cache.gray,
      darkThemeString => _cache.dark,
      blackThemeString => _cache.black,
      _ => _cache.light,
    };
  }

  return _getThemeFromStringUncached(themeString);
}

ThemeData _getThemeFromStringUncached(String themeString) {
  return switch (themeString) {
    lightThemeString => getEnjoyerTheme(),
    grayThemeString => getEnjoyerThemeGray(),
    darkThemeString => getPhriendsTheme(),
    blackThemeString => getEnjoyerThemeBlack(),
    _ => getEnjoyerTheme(),
  };
}

final ThemeCache _cache = ThemeCache();

class ThemeCache {
  late final light = getEnjoyerTheme();
  late final gray = getEnjoyerThemeGray();
  late final dark = getPhriendsTheme();
  late final black = getEnjoyerThemeBlack();
}

//
// Theme builders
//

ThemeData getEnjoyerTheme() {
  const Color interfaceColor = Color.fromARGB(255, 107, 152, 204);

  return ThemeData(
    scaffoldBackgroundColor: Colors.white,
    colorScheme: ColorScheme.fromSeed(
      seedColor: interfaceColor,
      primary: interfaceColor,
      tertiary: defaultActiveColor,
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
  const Color tertiary = Color(0xFF23A55A);
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
      tertiary: tertiary,
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
      tertiary: defaultActiveColor,
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
      tertiary: defaultActiveColor,
      scrim: const Color(0xDD000000),
    ),
    textButtonTheme: const TextButtonThemeData(style: buttonStyle),
    iconButtonTheme: const IconButtonThemeData(style: buttonStyle),
    buttonTheme: const ButtonThemeData(shape: appButtonShape),
    useMaterial3: true,
  );
}
