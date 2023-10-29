import 'dart:ui';

import 'package:super_clipboard/super_clipboard.dart'
    show DataWriterItem, ClipboardWriter, Formats;

void copyImageToClipboardAsPng(Image image, String suggestedName) async {
  final byteData = await image.toByteData(format: ImageByteFormat.png);
  if (byteData == null) return;

  final data = byteData.buffer.asUint8List();

  final item = DataWriterItem(suggestedName: suggestedName);
  item.add(Formats.png(data));
  await ClipboardWriter.instance.write([item]);
}
