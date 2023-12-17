import 'package:animators_gif_enjoyer/main.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

const rememberWindowSizeKey = 'remember_window_size';
const windowWidthKey = 'window_width';
const windowHeightKey = 'window_height';

void storeRememberWindowSizePreference(bool remember) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(rememberWindowSizeKey, remember);
}

Future<bool> getRememberWindowSizePreference({
  bool defaultPreference = false,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final shouldRemember = prefs.getBool(rememberWindowSizeKey);
  if (shouldRemember == null) return defaultPreference;

  return shouldRemember;
}

void storeWindowSizePreference(int width, int height) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt(windowWidthKey, width);
  await prefs.setInt(windowHeightKey, height);
}

Future<Size> getWindowSizePreference({
  Size defaultSize = const Size(500, 540),
}) async {
  final prefs = await SharedPreferences.getInstance();
  final width = prefs.getInt(windowWidthKey);
  if (width == null) return defaultSize;

  final height = prefs.getInt(windowHeightKey);
  if (height == null) return defaultSize;

  return Size(width.toDouble(), height.toDouble());
}

Future<void> storeCurrentWindowSize() async {
  if (await windowManager.isMaximized()) return;

  final size = await windowManager.getSize();
  storeWindowSizePreference(size.width.toInt(), size.height.toInt());
  //print('window size saved $size');
}

mixin WindowSizeRememberer<T extends StatefulWidget>
    on State<T>, WindowListener {
  int _windowSizeSaveCommandId = 0;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowResize() {
    _handleWindowResize();
    super.onWindowResize();
  }

  void _handleWindowResize() {
    //print('handleWindowResize');
    void queueSavetoPreferences() async {
      if (!appRememberSize) return;
      int getLatestSaveCommandId() => _windowSizeSaveCommandId;
      int saveCommandId = DateTime.now().millisecondsSinceEpoch;
      _windowSizeSaveCommandId = saveCommandId;

      const long = Duration(milliseconds: 250);
      const short = Duration(milliseconds: 15);
      const checkDurations = [short, short, short, long, long, long, long];
      for (final waitDuration in checkDurations) {
        await Future.delayed(waitDuration);
        if (getLatestSaveCommandId() != saveCommandId) {
          //print('save canceled.');
          return;
        }
      }

      if (getLatestSaveCommandId() == saveCommandId) {
        if (appRememberSize) {
          storeCurrentWindowSize();
        }
      }
    }

    if (appRememberSize) queueSavetoPreferences();
  }
}
