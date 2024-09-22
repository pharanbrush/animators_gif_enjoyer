import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:super_clipboard/super_clipboard.dart'
    show DataWriterItem, Formats, SystemClipboard;

void copyImageToClipboardAsPng(Image image, String suggestedName) async {
  final byteData = await image.toByteData(format: ImageByteFormat.png);
  if (byteData == null) return;

  final data = byteData.buffer.asUint8List();

  final item = DataWriterItem(suggestedName: suggestedName);
  item.add(Formats.png(data));
  await SystemClipboard.instance?.write([item]);
}

Future<String?> getStringFromClipboard() async {
  var clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
  if (clipboardData == null) return null;

  return clipboardData.text;
}
