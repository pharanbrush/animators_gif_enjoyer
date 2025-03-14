import 'dart:io';
import 'dart:ui' as ui;

import 'package:file_selector/file_selector.dart' as file_selector;
import 'package:flutter/foundation.dart';
import 'package:sanitize_filename/sanitize_filename.dart';

typedef AccumulatedFilesCallback = void Function(int totalFilesAccumulated);
typedef FilesDoneCheckCallback = void Function(
    int totalFiles, Directory? directory);
typedef VoidCallback = void Function();

///
/// Asks for a folder to save to, then saves each image as a png.
/// The pngs are named [prefix]_index for each image index in the list.
///
Future<void> savePngSequenceFromImageList(
  List<ui.Image> images, {
  required String prefix,
  bool useSubfolder = true,
  bool useBaseZero = true,
  AccumulatedFilesCallback? onFileSaveProgress,
  VoidCallback? onExportStart,
  VoidCallback? onSomeFilesNotSaved,
  FilesDoneCheckCallback? onExportCanceled,
  ValueListenable? exportCancel,
  FilesDoneCheckCallback? onExportSuccess,
}) async {
  final selectedFolderPath = await file_selector.getDirectoryPath(
      confirmButtonText:
          'Export Here'); // Doesn't have an end Platform.pathSeparator
  if (selectedFolderPath == null) return;

  final cleanPrefix = sanitizeFilename(prefix);
  final separator = Platform.pathSeparator;
  final saveFolderPathWithoutFinalSeparator =
      '$selectedFolderPath${useSubfolder ? '$separator$cleanPrefix' : ''}';

  int index = useBaseZero ? 0 : 1;

  int digits = images.length.toString().length + 1;
  bool someFilesWereNotSaved = false;
  onExportStart?.call();
  bool canceled = false;
  for (final image in images) {
    final fullFilePath = //
        '$saveFolderPathWithoutFinalSeparator$separator' //
        '${cleanPrefix}_' //
        '${index.toString().padLeft(digits, '0')}' //
        '.png';

    final savedFile = await saveUiImageAsPngFile(
      image: image,
      fullFilePath: fullFilePath,
    );

    if (savedFile == null) {
      someFilesWereNotSaved = true;
    }
    index++;
    onFileSaveProgress?.call(index);
    if (exportCancel != null && exportCancel.value) {
      canceled = true;
      break;
    }
  }

  if (canceled) {
    if (onExportCanceled != null) {
      final outputDirectory = Directory(saveFolderPathWithoutFinalSeparator);
      final exists = await outputDirectory.exists();
      if (exists) {
        onExportCanceled.call(index, outputDirectory);
      } else {
        onExportCanceled.call(index, null);
      }
    }

    return;
  }

  if (someFilesWereNotSaved) {
    onSomeFilesNotSaved?.call();
  }

  if (onExportSuccess != null) {
    final outputDirectory = Directory(saveFolderPathWithoutFinalSeparator);
    final exists = await outputDirectory.exists();
    if (exists) {
      onExportSuccess.call(index, outputDirectory);
    } else {
      onExportSuccess.call(index, null);
    }
  }
  //print('dummy: saving done');
}

Future<File?> saveUiImageAsPngFile({
  required ui.Image image,
  required String fullFilePath,
}) async {
  // await Future.delayed(const Duration(milliseconds: 100));
  // print('dummy saving: $fullFilePath');
  // return null;

  try {
    final file = await File(fullFilePath).create(
      recursive: true,
      exclusive: false,
    );

    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return null;

    //print('saving: $fullFilePath');
    return file.writeAsBytes(byteData.buffer.asUint8List());
  } catch (e) {
    return null;
  }
}
