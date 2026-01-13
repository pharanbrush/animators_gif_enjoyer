import 'package:animators_gif_enjoyer/phlutter/app_theme_cycler.dart';
import 'package:animators_gif_enjoyer/main_screen/main_screen.dart';
import 'package:animators_gif_enjoyer/main_screen/theme.dart' as app_theme;
import 'package:animators_gif_enjoyer/phlutter/remember_window_size.dart'
    as remember_window_size;
import 'package:animators_gif_enjoyer/phlutter/single_instance.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:windows_single_instance/windows_single_instance.dart';

const appName = "Animator's GIF Enjoyer Deluxe";

bool appAllowMultipleInstances = false;
String appFileToLoadFromMainArgs = '';
Function()? onSecondWindow;

const appWindowIdentifier = 'animators_gif_enjoyer';

void main(List<String> args) async {
  if (args.isNotEmpty) {
    appFileToLoadFromMainArgs = args[0];
  }

  WidgetsFlutterBinding.ensureInitialized();

  appAllowMultipleInstances = await getAllowMultipleInstancePreference(
    defaultAllowMultipleInstances: false,
  );

  if (!appAllowMultipleInstances) {
    await WindowsSingleInstance.ensureSingleInstance(
      args,
      appWindowIdentifier,
      onSecondWindow: (newArgs) {
        if (newArgs.isNotEmpty) {
          appFileToLoadFromMainArgs = newArgs[0];
          onSecondWindow?.call();
        }
      },
    );
  }

  remember_window_size.appRememberWindowSize =
      await remember_window_size.getRememberWindowSizePreference();
  final Size startingWindowSize;
  if (remember_window_size.appRememberWindowSize) {
    startingWindowSize = await remember_window_size.getWindowSizePreference();
  } else {
    startingWindowSize = const Size(500, 540);
  }

  await windowManager.ensureInitialized();

  final windowOptions = WindowOptions(
    minimumSize: const Size.square(460),
    size: startingWindowSize,
    title: appName,
    center: true,
    titleBarStyle: TitleBarStyle.hidden,
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  final initialThemeString = await getThemeStringFromPreference(
      defaultThemeString: app_theme.defaultThemeString);

  runApp(
    MyApp(initialTheme: initialThemeString),
  );
}
