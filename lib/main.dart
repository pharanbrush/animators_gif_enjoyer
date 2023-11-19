import 'package:animators_gif_enjoyer/phlutter/app_theme_cycler.dart';
import 'package:animators_gif_enjoyer/main_screen/main_screen.dart';
import 'package:animators_gif_enjoyer/main_screen/theme.dart' as app_theme;
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:windows_single_instance/windows_single_instance.dart';

const appName = "Animator's GIF Enjoyer Deluxe";
const appWindowIdentifier = 'animators_gif_enjoyer';

String fileToLoadFromMainArgs = '';
Function()? onSecondWindow;

void main(List<String> args) async {
  if (args.isNotEmpty) {
    fileToLoadFromMainArgs = args[0];
  }

  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    minimumSize: Size.square(460),
    size: Size(500, 540),
    title: appName,
    center: true,
    titleBarStyle: TitleBarStyle.hidden,
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  await WindowsSingleInstance.ensureSingleInstance(
    args,
    appWindowIdentifier,
    onSecondWindow: (newArgs) {
      if (newArgs.isNotEmpty) {
        fileToLoadFromMainArgs = newArgs[0];
        onSecondWindow?.call();
      }
    },
  );

  final initialThemeString = await getThemeStringFromPreference(
      defaultThemeString: app_theme.defaultThemeString);

  runApp(
    MyApp(initialTheme: initialThemeString),
  );
}
