// import 'package:animators_gif_enjoyer/main_screen/theme.dart';
// import 'package:flutter/material.dart';

//
// Theme preferences
//
const themeModePreferenceKey = 'theme_mode';

//
// ThemeMode preference
//
const darkMode = 'dark';
const lightMode = 'light';
const systemMode = 'system';

// String toThemeModeString(ThemeMode mode) => switch (mode) {
//       ThemeMode.light => lightMode,
//       ThemeMode.dark => darkMode,
//       ThemeMode.system => systemMode,
//     };

// ThemeMode toThemeModeFromString(String themeModeString) =>
//     switch (themeModeString) {
//       lightMode => ThemeMode.light,
//       darkMode => ThemeMode.dark,
//       systemMode => ThemeMode.system,
//       _ => defaultThemeMode,
//     };

// void storeThemeModePreference(ThemeMode mode) async {
//   final prefs = await SharedPreferences.getInstance();
//   await prefs.setString(themeModePreferenceKey, toThemeModeString(mode));
// }

// Future<ThemeMode> getThemeModeFromPreference() async {
//   final prefs = await SharedPreferences.getInstance();
//   final retrievedModeString = prefs.getString(themeModePreferenceKey);
//   if (retrievedModeString == null) return defaultThemeMode;

//   return toThemeModeFromString(retrievedModeString);
// }

