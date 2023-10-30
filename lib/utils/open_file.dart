import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

Future<(FileImage? gifImage, String? name)> openGifImageFile() async {
  const typeGroup = XTypeGroup(
    label: 'GIFs',
    extensions: ['gif'],
  );

  final file = await openFile(acceptedTypeGroups: const [typeGroup]);
  if (file == null) return (null, null);

  return (FileImage(File(file.path)), file.name);
}

FileImage getFileImageFromPath(String path) {
  return FileImage(File(path));
}
