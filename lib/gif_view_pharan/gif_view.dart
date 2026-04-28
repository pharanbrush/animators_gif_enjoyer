import 'dart:async';
import 'dart:ui';

import 'package:animators_gif_enjoyer/functionality/avif_enjoyer.dart'
    as avif_enjoyer;
import 'package:animators_gif_enjoyer/phlutter/dart/uri_paths.dart'
    as uri_paths;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;

///
/// Originally created by
///
/// ─▄▀─▄▀
/// ──▀──▀
/// █▀▀▀▀▀█▄
/// █░░░░░█─█
/// ▀▄▄▄▄▄▀▀
///
/// Rafaelbarbosatec
/// on 23/09/21
///

/// tbh I deleted most of the methods, members and functionality
/// since I'm handling a lot of the actual controls in the app code.
/// -Pharan

class AnimationFrame {
  final ImageInfo imageInfo;
  final Duration duration;

  const AnimationFrame(this.imageInfo, this.duration);
}

/// Loads a [AnimationFrame] List from a [FileImage] List that can then be passed
/// to [FrameController.load].
Future<List<AnimationFrame>> loadAnimationFramesFromImages({
  required List<FileImage> fileImages,
  ValueChanged<Object?>? onError,
  Duration? frameDuration,
}) async {
  const defaultDuration = Duration(milliseconds: 40); // 40ms is 25 fps
  final appliedFrameDuration = frameDuration ?? defaultDuration;
  final frameList = <AnimationFrame>[];

  try {
    int width = 0;
    int height = 0;

    for (var fileImage in fileImages) {
      Uint8List? data;

      data = await fileImage.file.readAsBytes();
      Codec codec = await instantiateImageCodec(
        data,
        allowUpscaling: false,
      );

      for (int i = 0, n = codec.frameCount; i < n; i++) {
        FrameInfo frameInfo = await codec.getNextFrame();

        if (width == 0) {
          width = frameInfo.image.width;
          height = frameInfo.image.height;
        } else {
          if (frameInfo.image.width != width ||
              frameInfo.image.height != height) {
            throw const FormatException(
              "Folder containing images of varying sizes was rejected.",
            );
          }
        }

        frameList.add(
          AnimationFrame(
            ImageInfo(image: frameInfo.image),
            appliedFrameDuration,
          ),
        );
      }
    }
  } catch (e) {
    if (onError == null) {
      rethrow;
    } else {
      onError(e);
    }
  }

  return frameList;
}

/// Loads a [AnimationFrame] List from an ImageProvider which can then be passed
/// to [FrameController.load].
Future<List<AnimationFrame>> loadFrames({
  required ImageProvider provider,
  ValueChanged<Object?>? onError,
  ValueChanged<double>? onProgressPercent,
}) async {
  final frameList = <AnimationFrame>[];
  try {
    Uint8List? data;

    switch (provider) {
      // case NetworkImage ni:
      //   {
      //     final Uri resolvedUri = Uri.base.resolve(ni.url);
      //     Map<String, String> headers = {};
      //     ni.headers?.forEach((String name, String value) {
      //       headers[name] = value;
      //     });

      //     if (onProgressPercent != null) {
      //       final streamedResponse = await http.Client().send(
      //         http.Request('GET', resolvedUri),
      //       );

      //       final total = streamedResponse.contentLength ?? 0;
      //       int received = 0;
      //       final List<int> bytes = [];
      //       bool isDownloadDone = false;
      //       streamedResponse.stream
      //           .listen((value) {
      //             bytes.addAll(value);
      //             received += value.length;
      //           })
      //           .onDone(() {
      //             isDownloadDone = true;
      //           });

      //       while (!isDownloadDone) {
      //         if (total > 0) {
      //           onProgressPercent(received.toDouble() / total.toDouble());
      //         }
      //         await Future.delayed(const Duration(milliseconds: 100));
      //       }
      //       onProgressPercent(1);

      //       data = Uint8List.fromList(bytes);
      //     } else {
      //       final response = await http.get(resolvedUri, headers: headers);
      //       data = response.bodyBytes;
      //     }
      //   }

      case AssetImage ai:
        {
          AssetBundleImageKey key = await ai.obtainKey(
            const ImageConfiguration(),
          );
          final d = await key.bundle.load(key.name);
          data = d.buffer.asUint8List();
        }

      case MemoryImage mi:
        data = mi.bytes;

      case FileImage fi:
        data = await fi.file.readAsBytes();
    }

    if (data == null) {
      return [];
    }

    // This part overrides the use of dart::ui.Codec
    // for formats that it doesn't support.
    if (isProviderHasFileExtension(provider, extension: 'avif')) {
      debugPrint("[gif_view] AVIF detected. Loading frames with avif_enjoyer.");
      return await avif_enjoyer.loadAnimationFramesFromAvifFrames(
        data,
        onProgressPercent: onProgressPercent,
      );
    }

    final Codec codec = await instantiateImageCodec(
      data,
      allowUpscaling: false,
    );

    for (int i = 0, n = codec.frameCount; i < n; i++) {
      FrameInfo frameInfo = await codec.getNextFrame();
      frameList.add(
        AnimationFrame(
          ImageInfo(image: frameInfo.image),
          frameInfo.duration,
        ),
      );
    }
  } catch (e) {
    if (onError == null) {
      rethrow;
    } else {
      onError(e);
    }
  }

  return frameList;
}

bool isProviderHasFileExtension(
  ImageProvider provider, {
  required String extension,
}) {
  Uri? sourceUri;
  switch (provider) {
    case NetworkImage ni:
      final Uri resolvedUri = Uri.base.resolve(ni.url);
      sourceUri = resolvedUri;
    case FileImage fi:
      sourceUri = fi.file.uri;
  }

  if (sourceUri != null) {
    final providerExtension = uri_paths.getExtensionFromUri(sourceUri);
    if (providerExtension != null) {
      return providerExtension.toLowerCase().startsWith(extension);
    }
  }

  return false;
}

class FrameController extends ChangeNotifier {
  FrameController({
    required this.currentFrameListenable,
  });

  final ValueListenable<int> currentFrameListenable;

  List<AnimationFrame> _frames = [];

  List<AnimationFrame> get frames => _frames;

  int get currentFrame => currentFrameListenable.value;

  AnimationFrame get currentFrameData => _frames[currentFrame];
  int get frameCount => _frames.length;

  @override
  void dispose() {
    tryDisposeFrames();
    super.dispose();
  }

  void tryDisposeFrames() {
    for (var f in _frames) {
      f.imageInfo.dispose();
    }
  }

  void load(List<AnimationFrame> frames, {bool updateFrames = false}) {
    tryDisposeFrames();

    _frames = frames;
    if (!updateFrames) {
      notifyListeners();
    }
  }
}
