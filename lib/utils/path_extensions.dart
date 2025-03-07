import 'dart:io';

extension NameExtensions on FileSystemEntity {
  String get name {
    return filenameFromFullPath(path);
  }
}

/// Doesn't check the format of the string.
String filenameFromFullPath(String fullPath) {
  return fullPath.split(Platform.pathSeparator).last;
}

/// Tries to get the name of the file without the extension.
///
/// Excludes everything after the last occurence of a dot.
/// Returns an empty string if the dot comes at the start of the filename.
/// Returns the full argument if no dot was found.
/// Returns an empty string if the argument was empty or whitespace.
String filenameWithoutExtension(String filenameWithExtension) {
  if (filenameWithExtension.trim().isEmpty) return '';
  final dotIndex = filenameWithExtension.lastIndexOf('.');
  if (dotIndex < 0) return filenameWithExtension;
  if (dotIndex == 0) return '';

  return filenameWithExtension.substring(0, dotIndex);
}

String filenameFromFullPathWithoutExtensions(String fullPath) {
  return filenameWithoutExtension(filenameFromFullPath(fullPath));
}

String? filenameFromUrlWithoutExtension(String url) {
  final argumentIndex = url.lastIndexOf('?');
  final lastSlashIndex = url.lastIndexOf('/');
  final filenameEndIndex =
      argumentIndex > lastSlashIndex ? argumentIndex : null;

  var fullFilename = url.substring(lastSlashIndex + 1, filenameEndIndex).trim();
  if (fullFilename.isEmpty) return null;

  return filenameWithoutExtension(fullFilename);
}
