import 'dart:math';

import 'package:animators_gif_enjoyer/gif_view_pharan/gif_view.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart' as rendering;

import 'package:flutter_avif/flutter_avif.dart' as flutter_avif;

/// Loads a [AnimationFrame] List from an [AvifFrameInfo] List that can then be passed
/// to [GifFrameController.load].
/// This allows the app to hook into flutter_avif.
Future<List<AnimationFrame>> loadGifFramesFromAvifFrames(
  Uint8List bytes, {
  void Function(double percentProgress)? onProgressPercent,
}) async {
  final frameList = <AnimationFrame>[];
  debugPrint("[avif_enjoyer] Now attempting to load AVIF bytes.");

  // This is a modified inlined version of flutter_avif.decodeAvif(bytes).
  // To avoid the intermediate AvifFrameInfo list.
  final key = Random().nextInt(4294967296);
  final codec = flutter_avif.MultiFrameAvifCodec(key: key, avifBytes: bytes);
  await codec.ready();

  onProgressPercent?.call(0);
  debugPrint("[avif] AVIF Codec ready. Starting loading.");

  final frameCount = codec.frameCount;
  final frameCountDouble = frameCount.toDouble();
  for (int i = 0; i < frameCount; i += 1) {
    final frame = await codec.getNextFrame();
    frameList.add(
      AnimationFrame(rendering.ImageInfo(image: frame.image), frame.duration),
    );

    onProgressPercent?.call(i / frameCountDouble);
  }

  onProgressPercent?.call(1);

  codec.dispose();

  debugPrint("[avif_enjoyer] Completed. Now returning frames.");

  return frameList;
}
