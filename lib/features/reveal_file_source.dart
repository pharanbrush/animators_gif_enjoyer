import 'dart:io';

import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';

void revealInExplorer(String fullFilePath) {
  if (Platform.isWindows) {
    final windowsFilePath = fullFilePath.replaceAll(
      '/',
      Platform.pathSeparator,
    );
    Process.start('explorer', ['/select,', windowsFilePath]);
  } else {
    final file = File(fullFilePath);
    launchUrl(file.parent.uri);
  }
}

void revealDirectoryInExplorer(Directory directory) {
  final launchPath = //
      'file:' // required by url_launcher to open platform file explorer
      '${directory.uri.toFilePath(windows: Platform.isWindows)}';
  launchUrlString(launchPath);
}

void openInBrowser(String urlString) {
  launchUrlString(urlString);
}
