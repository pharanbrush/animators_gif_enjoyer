import 'dart:io';

import 'package:animators_gif_enjoyer/utils/path_extensions.dart';
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

Future<(List<FileImage>? images, String? folderName)>
    openFolderSelectorForFileImages() async {
  var folderPath = await getDirectoryPath();
  if (folderPath == null || folderPath.isEmpty) return (null, null);

  var fileImages = await loadFolderAsFileImages(folderPath);
  if (fileImages == null) return (null, null);

  return (fileImages, folderPath);
}

Future<int> tryGetFramerateFromFolder(
  String folderPath, {
  int defaultFrameRate = 25,
  int maxFramerate = 120,
}) async {
  if (folderPath.isEmpty) return defaultFrameRate;

  try {
    final directory = Directory(folderPath);
    final directoryContents = directory.list(recursive: false);

    await for (final FileSystemEntity entry in directoryContents) {
      if (entry is File) {
        final fileName = entry.name;

        if (!fileName.endsWith(' fps.txt')) continue;

        var splitName = fileName.split(' ');
        if (splitName.length != 2) continue;

        var possibleNumber = splitName[0].trim();
        if (possibleNumber.isEmpty) continue;

        var possibleInt = int.tryParse(possibleNumber);
        if (possibleInt == null) continue;

        if (possibleInt > maxFramerate) possibleInt = maxFramerate;
        if (possibleInt <= 1) possibleInt = 1;

        return possibleInt;
      }
    }
  } catch (_) {
    return defaultFrameRate;
  }

  return defaultFrameRate;
}

Future<List<FileImage>?> loadFolderAsFileImages(String folderPath) async {
  if (folderPath.isEmpty) return null;

  final directory = Directory(folderPath);

  final directoryContents = directory.list(recursive: false);
  final List<FileImage> files = [];
  await for (final FileSystemEntity entry in directoryContents) {
    if (entry is File) {
      final fileName = entry.name;
      if (!isAcceptedFile(filename: fileName) &&
          !isInformallyAcceptedFile(filename: fileName)) {
        continue;
      }

      files.add(FileImage(entry));
    }
  }

  sortPaths(files);
  return files;
}

void sortPaths(List<FileImage> files) {
  files.sort(alphabeticalCompare);
}

int alphabeticalCompare(FileImage a, FileImage b) {
  final aName = a.file.name;
  final bName = b.file.name;
  return aName.compareTo(bName);
}
