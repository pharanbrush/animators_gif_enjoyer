import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

const allowWideSliderKey = 'allow_wide_slider';

mixin GifEnjoyerWindowPreferences {
  final allowWideSliderNotifier = ValueNotifier<bool>(false);
}

void toggleAllowWideSliderPreference(
  ValueNotifier<bool> allowWideSliderNotifier,
) async {
  storeAllowWideSliderPreference(!allowWideSliderNotifier.value);
  allowWideSliderNotifier.value = await getAllowWideSliderPreference();
}

void storeAllowWideSliderPreference(bool allowWideSlider) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(allowWideSliderKey, allowWideSlider);
}

Future<bool> getAllowWideSliderPreference({
  bool defaultAllowWideSlider = false,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final storedValue = prefs.getBool(allowWideSliderKey);
  if (storedValue == null) return defaultAllowWideSlider;

  return storedValue;
}
