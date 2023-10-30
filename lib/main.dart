import 'package:animators_gif_enjoyer/main_screen/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

const appName = "Animator's GIF Enjoyer Deluxe";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    minimumSize: Size.square(460),
    size: Size(500, 540),
    title: appName,
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const MyApp());
}
