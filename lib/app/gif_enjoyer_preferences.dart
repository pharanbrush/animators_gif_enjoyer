import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

const allowWideSliderKey = "allow_wide_slider";
const sliderWrapKey = "allow_wrap_slider";

const kDefaultAllowWideSlider = false;
const kDefaultSliderWrap = false;

mixin GifEnjoyerWindowPreferences {
  final allowWideSliderNotifier = ValueNotifier<bool>(false);
  final allowSliderWrapAroundDragNotifier = ValueNotifier<bool>(false);
}

// Wide Slider
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

Future<bool> getAllowWideSliderPreference() async {
  final prefs = await SharedPreferences.getInstance();
  final storedValue = prefs.getBool(allowWideSliderKey);
  if (storedValue == null) return kDefaultAllowWideSlider;

  return storedValue;
}

// Drag wrap
void toggleSliderWrapPreference(
  ValueNotifier<bool> allowSliderWrapNotifier,
) async {
  storeSliderWrapPreference(!allowSliderWrapNotifier.value);
  allowSliderWrapNotifier.value = await getSliderWrapPreference();
}

void storeSliderWrapPreference(bool allowSliderWrap) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(sliderWrapKey, allowSliderWrap);
}

Future<bool> getSliderWrapPreference() async {
  final prefs = await SharedPreferences.getInstance();
  final storedValue = prefs.getBool(sliderWrapKey);
  if (storedValue == null) return kDefaultSliderWrap;

  return storedValue;
}
