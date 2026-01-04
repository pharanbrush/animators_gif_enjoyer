import 'package:animators_gif_enjoyer/gif_view_pharan/gif_view.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart' as rendering;

import 'package:flutter_avif/flutter_avif.dart' as flutter_avif;

/// Loads a [GifFrame] List from an [AvifFrameInfo] List that can then be passed
/// to [GifController.load].
/// This allows the app to hook into flutter_avif.
Future<List<GifFrame>> loadGifFramesFromAvifFrames(Uint8List bytes) async {
  final avifFrames = await flutter_avif.decodeAvif(bytes);

  final frameList = <GifFrame>[];
  for (final frame in avifFrames) {
    frameList.add(
      GifFrame(
        rendering.ImageInfo(image: frame.image),
        frame.duration,
      ),
    );
  }

  return frameList;
}
