import 'package:animators_gif_enjoyer/phlutter/phdart/command_rate_limiter.dart';
import 'package:animators_gif_enjoyer/phlutter/widget/preferences_stored_bool.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

const rememberWindowSizeKey = 'remember_window_size';
const windowWidthKey = 'window_width';
const windowHeightKey = 'window_height';

final appRememberWindowSize = PreferencesStoredBool(
  preferenceKey: rememberWindowSizeKey,
  defaultValue: false,
);

void _storeWindowSizePreference(int width, int height) async {
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

Future<void> _storeCurrentWindowSize() async {
  if (await windowManager.isMaximized()) return;

  final size = await windowManager.getSize();
  _storeWindowSizePreference(size.width.toInt(), size.height.toInt());
  // debugPrint('window size saved $size');
}

mixin WindowSizeRememberer<T extends StatefulWidget>
    on State<T>, WindowListener {
  final limiter = CommandRateLimiter();

  @override
  void initState() {
    super.initState();
    appRememberWindowSize.valueNotifier.addListener(_handleWindowResize);
    windowManager.addListener(this);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    appRememberWindowSize.valueNotifier.removeListener(_handleWindowResize);
    appRememberWindowSize.dispose();
    super.dispose();
  }

  @override
  void onWindowResize() {
    _handleWindowResize();
    super.onWindowResize();
  }

  void _handleWindowResize() {
    if (!appRememberWindowSize.value) return;
    limiter.queueCommand(
      () {
        if (!appRememberWindowSize.value) return;
        _storeCurrentWindowSize();
      },
    );
  }
}
