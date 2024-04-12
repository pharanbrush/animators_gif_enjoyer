import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

const acceptedExtensions = ['gif', 'webp', 'apng', 'png'];

Future<(FileImage? gifImage, String? fullFilePath)> openGifImageFile() async {
  const typeGroup = XTypeGroup(
    label: 'GIFs',
    extensions: acceptedExtensions,
  );

  final file = await openFile(acceptedTypeGroups: const [typeGroup]);
  if (file == null) return (null, null);

  return (FileImage(File(file.path)), file.path);
}

FileImage getFileImageFromPath(String path) {
  return FileImage(File(path));
}

bool isAcceptedFile({required String filename}) {
  for (final extension in acceptedExtensions) {
    if (filename.endsWith(extension)) return true;
  }

  return false;
}

const informallyAcceptedExtensions = [
  'jpg',
  'jfif',
  'jpeg',
];

bool isInformallyAcceptedFile({required String filename}) {
  for (final extension in informallyAcceptedExtensions) {
    if (filename.endsWith(extension)) return true;
  }

  return false;
}