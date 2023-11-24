import 'dart:io';
import 'dart:ui' as ui;

import 'package:file_selector/file_selector.dart' as file_selector;

typedef AccumulatedFilesCallback = void Function(int totalFilesSaved);
typedef FilesDoneCheckCallback = void Function(
    int totalFiles, Directory? directory);

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
  ui.VoidCallback? onSomeFilesNotSaved,
  FilesDoneCheckCallback? onSaveSuccess,
}) async {
  final selectedFolderPath = await file_selector.getDirectoryPath(
      confirmButtonText:
          'Export Here'); // Doesn't have an end Platform.pathSeparator
  if (selectedFolderPath == null) return;

  final separator = Platform.pathSeparator;
  final saveFolderPathWithoutFinalSeparator =
      '$selectedFolderPath${useSubfolder ? '$separator$prefix' : ''}';

  int index = useBaseZero ? 0 : 1;

  int digits = images.length.toString().length + 1;
  bool someFilesWereNotSaved = false;
  for (final image in images) {
    final fullFilePath = //
        '$saveFolderPathWithoutFinalSeparator$separator' //
        '${prefix}_' //
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
  }

  if (someFilesWereNotSaved) {
    onSomeFilesNotSaved?.call();
  }

  if (onSaveSuccess != null) {
    final outputDirectory = Directory(saveFolderPathWithoutFinalSeparator);
    final exists = await outputDirectory.exists();
    if (exists) {
      onSaveSuccess.call(index, outputDirectory);
    } else {
      onSaveSuccess.call(index, null);
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
