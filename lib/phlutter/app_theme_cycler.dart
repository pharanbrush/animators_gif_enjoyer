import 'package:animators_gif_enjoyer/phlutter/dart/command_rate_limiter.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

mixin ThemeCycler<T extends StatefulWidget> on State<T> {
  late final ValueNotifier<String> themeString;

  final saveLimiter = CommandRateLimiter();

  // Abstract members
  String get defaultThemeString;
  String? get initialThemeString;
  ThemeData getThemeFromString(String themeName);
  String getNextCycleTheme(String currentValue);

  @override
  void initState() {
    themeString = ValueNotifier(initialThemeString ?? defaultThemeString);

    themeString.addListener(_updateAppTheme);
    super.initState();
  }

  @override
  void dispose() {
    themeString.removeListener(_updateAppTheme);
    super.dispose();
  }

  void _updateAppTheme() {
    final themeContext = ThemeContext.of(context);
    if (themeContext == null) {
      return;
    }

    themeContext.themeData.value = getThemeFromString(themeString.value);
    saveLimiter.queueCommand(
      () => storeThemeStringPreference(themeString.value),
    );
  }

  void cycleTheme() {
    themeString.value = getNextCycleTheme(themeString.value);
  }
}

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

//
// ThemeString preference
//
const themeStringKey = 'theme_string';

void storeThemeStringPreference(String themeString) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(themeStringKey, themeString);
}

Future<String> getThemeStringFromPreference({
  required String defaultThemeString,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final retrievedThemeString = prefs.getString(themeStringKey);
  if (retrievedThemeString == null) return defaultThemeString;

  return retrievedThemeString;
}
