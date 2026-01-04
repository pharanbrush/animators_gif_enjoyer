import 'dart:io';

import 'package:animators_gif_enjoyer/utils/path_extensions.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

const acceptedExtensions = ['gif', 'webp', 'apng', 'png', 'avif'];

Future<(FileImage? gifImage, String? fullFilePath)>
    userOpenFilePickerForImages() async {
  const typeGroup = XTypeGroup(
    label: 'Animated Images',
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

bool isCompatibleFile({required String filename}) {
  return isAcceptedFile(filename: filename) ||
      isInformallyAcceptedFile(filename: filename);
}

Future<String?> openFolderSelectorForFileImages() {
  return getDirectoryPath(confirmButtonText: "Import folder");
}

bool isFolder(String path) {
  return Directory(path).existsSync();
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
  final List<FileImage> fileImages = [];
  await for (final FileSystemEntity entry in directoryContents) {
    if (entry is File) {
      if (isCompatibleFile(filename: entry.name)) {
        fileImages.add(FileImage(entry));
      }
    }
  }

  trySortFileSequence(fileImages);
  return fileImages;
}

final imageSequencePattern = RegExp(r'(?<=\D|^)(\d+)\.(?=\D*$)');

void trySortFileSequence(List<FileImage> fileImages) {
  bool regexCheckPassed = true;
  for (final fileImage in fileImages) {
    if (!imageSequencePattern.hasMatch(fileImage.file.name)) {
      regexCheckPassed = false;
      break;
    }
  }

  if (regexCheckPassed) {
    fileImages.sort(regexSequenceCompare);
    return;
  }

  fileImages.sort(basicStringCompare);
}

int basicStringCompare(FileImage a, FileImage b) {
  return a.file.name.compareTo(b.file.name);
}

int regexSequenceCompare(FileImage a, FileImage b) {
  final matchA = imageSequencePattern.firstMatch(a.file.name);
  final matchB = imageSequencePattern.firstMatch(b.file.name);

  if (matchA == null || matchB == null) {
    return 0;
  }

  final numA = int.parse(matchA.group(1)!);
  final numB = int.parse(matchB.group(1)!);
  final int sequenceComparison = numA.compareTo(numB);

  if (sequenceComparison == 0) {
    return a.file.name.compareTo(b.file.name);
  }

  return sequenceComparison;
}
