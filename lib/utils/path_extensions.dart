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

/// Doesn't check the format of the string.
String filenameWithoutExtension(String filenameWithExtension) {
  final extension = filenameWithExtension.split('.').last;
  return filenameWithExtension.substring(
    0,
    filenameWithExtension.length - extension.length - 1,
  );
}

String filenameFromFullPathWithoutExtensions(String fullPath) {
  return filenameWithoutExtension(filenameFromFullPath(fullPath));
}
