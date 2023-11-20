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

void openInBrowser(String urlString) {
  launchUrlString(urlString);
}
