import 'dart:async';
import 'dart:ui';

import 'package:animators_gif_enjoyer/functionality/avif_enjoyer.dart'
    as avif_enjoyer;
import 'package:animators_gif_enjoyer/utils/path_extensions.dart'
    as path_extensions;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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

enum GifStatus { loading, playing, stopped, paused, reversing }

class GifFrame {
  final ImageInfo imageInfo;
  final Duration duration;

  const GifFrame(this.imageInfo, this.duration);
}

/// Loads a [GifFrame] List from a [FileImage] List that can then be passed
/// to [GifController.load].
Future<List<GifFrame>> loadGifFramesFromImages({
  required List<FileImage> fileImages,
  ValueChanged<Object?>? onError,
  Duration? frameDuration,
}) async {
  const defaultDuration = Duration(milliseconds: 40); // 40ms is 25 fps
  final appliedFrameDuration = frameDuration ?? defaultDuration;
  final frameList = <GifFrame>[];

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
          GifFrame(
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

/// Loads a [GifFrame] List from an ImageProvider which can then be passed
/// to [GifController.load].
Future<List<GifFrame>> loadGifFrames({
  required ImageProvider provider,
  ValueChanged<Object?>? onError,
  ValueChanged<double>? onProgressPercent,
}) async {
  final frameList = <GifFrame>[];
  try {
    Uint8List? data;

    switch (provider) {
      case NetworkImage ni:
        {
          final Uri resolvedUri = Uri.base.resolve(ni.url);
          Map<String, String> headers = {};
          ni.headers?.forEach((String name, String value) {
            headers[name] = value;
          });

          if (onProgressPercent != null) {
            final streamedResponse =
                await http.Client().send(http.Request('GET', resolvedUri));

            final total = streamedResponse.contentLength ?? 0;
            int received = 0;
            final List<int> bytes = [];
            bool isDownloadDone = false;
            streamedResponse.stream.listen((value) {
              bytes.addAll(value);
              received += value.length;
            }).onDone(() {
              isDownloadDone = true;
            });

            while (!isDownloadDone) {
              if (total > 0) {
                onProgressPercent(received.toDouble() / total.toDouble());
              }
              await Future.delayed(const Duration(milliseconds: 100));
            }
            onProgressPercent(1);

            data = Uint8List.fromList(bytes);
          } else {
            final response = await http.get(resolvedUri, headers: headers);
            data = response.bodyBytes;
          }
        }

      case AssetImage ai:
        {
          AssetBundleImageKey key =
              await ai.obtainKey(const ImageConfiguration());
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
      debugPrint("[avif] AVIF detected. Loading frames.");
      return await avif_enjoyer.loadGifFramesFromAvifFrames(
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
        GifFrame(
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
    final providerExtension = path_extensions.getExtensionFromUri(sourceUri);
    if (providerExtension != null) {
      return providerExtension.toLowerCase().startsWith(extension);
    }
  }

  return false;
}

class GifView extends StatefulWidget {
  final GifController? controller;
  final ImageProvider? image;
  final double? height;
  final double? width;
  final BoxFit? fit;
  final Color? color;
  final BlendMode? colorBlendMode;
  final AlignmentGeometry alignment;
  final ImageRepeat repeat;
  final Rect? centerSlice;
  final bool matchTextDirection;
  final bool invertColors;
  final FilterQuality filterQuality;
  final bool isAntiAlias;
  final ValueChanged<Object?>? onError;

  GifView.network(
    String url, {
    super.key,
    this.controller,
    this.height,
    this.width,
    this.fit,
    this.color,
    this.colorBlendMode,
    this.alignment = Alignment.center,
    this.repeat = ImageRepeat.noRepeat,
    this.centerSlice,
    this.matchTextDirection = false,
    this.invertColors = false,
    this.filterQuality = FilterQuality.low,
    this.isAntiAlias = false,
    this.onError,
    double scale = 1.0,
    Map<String, String>? headers,
  }) : image = NetworkImage(url, scale: scale, headers: headers);

  GifView.asset(
    String asset, {
    super.key,
    this.controller,
    this.height,
    this.width,
    this.fit,
    this.color,
    this.colorBlendMode,
    this.alignment = Alignment.center,
    this.repeat = ImageRepeat.noRepeat,
    this.centerSlice,
    this.matchTextDirection = false,
    this.invertColors = false,
    this.filterQuality = FilterQuality.low,
    this.isAntiAlias = false,
    this.onError,
    String? package,
    AssetBundle? bundle,
  }) : image = AssetImage(asset, package: package, bundle: bundle);

  GifView.memory(
    Uint8List bytes, {
    super.key,
    this.controller,
    this.height,
    this.width,
    this.fit,
    this.color,
    this.colorBlendMode,
    this.alignment = Alignment.center,
    this.repeat = ImageRepeat.noRepeat,
    this.centerSlice,
    this.matchTextDirection = false,
    this.invertColors = false,
    this.filterQuality = FilterQuality.low,
    this.isAntiAlias = false,
    this.onError,
    double scale = 1.0,
  }) : image = MemoryImage(bytes, scale: scale);

  const GifView({
    super.key,
    required this.image,
    this.controller,
    this.height,
    this.width,
    this.fit,
    this.color,
    this.colorBlendMode,
    this.alignment = Alignment.center,
    this.repeat = ImageRepeat.noRepeat,
    this.centerSlice,
    this.matchTextDirection = false,
    this.invertColors = false,
    this.filterQuality = FilterQuality.low,
    this.isAntiAlias = false,
    this.onError,
  });

  @override
  GifViewState createState() => GifViewState();
}

class GifViewState extends State<GifView> with TickerProviderStateMixin {
  late GifController controller;

  @override
  void initState() {
    controller = widget.controller ?? GifController();
    controller.addListener(_listener);
    // Future.delayed(Duration.zero, _loadImage);
    super.initState();
  }

  // @override
  // void didUpdateWidget(covariant GifView oldWidget) {
  //   super.didUpdateWidget(oldWidget);
  //   if (oldWidget.image != widget.image) {
  //     _loadImage(updateFrames: true);
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return RawImage(
      image: controller.currentFrameData.imageInfo.image,
      width: widget.width,
      height: widget.height,
      scale: controller.currentFrameData.imageInfo.scale,
      fit: widget.fit,
      color: widget.color,
      colorBlendMode: widget.colorBlendMode,
      alignment: widget.alignment,
      repeat: widget.repeat,
      centerSlice: widget.centerSlice,
      matchTextDirection: widget.matchTextDirection,
      invertColors: widget.invertColors,
      filterQuality: widget.filterQuality,
      isAntiAlias: widget.isAntiAlias,
    );
  }

  // FutureOr _loadImage({bool updateFrames = false}) async {
  //   final imageProvider = widget.image;

  //   if (imageProvider == null) return;
  //   final frames = await loadGifFrames(
  //     provider: imageProvider,
  //     onError: widget.onError,
  //   );
  //   controller.load(frames, updateFrames: updateFrames);
  // }

  @override
  void dispose() {
    controller.removeListener(_listener);
    super.dispose();
  }

  void _listener() {
    if (mounted) {
      setState(() {});
    }
  }
}

class GifController extends ChangeNotifier {
  List<GifFrame> _frames = [];
  int _currentFrame = 0;

  List<GifFrame> get frames => _frames;
  int get currentFrame => _currentFrame;
  set currentFrame(int newValue) {
    _currentFrame = newValue.clamp(0, frameCount);
  }

  GifFrame get currentFrameData => _frames[currentFrame];
  int get frameCount => _frames.length;

  @override
  void dispose() {
    tryDisposeFrames();
    super.dispose();
  }

  void seek(int index) {
    currentFrame = index;
    notifyListeners();
  }

  void tryDisposeFrames() {
    for (var f in _frames) {
      f.imageInfo.dispose();
    }
  }

  void load(List<GifFrame> frames, {bool updateFrames = false}) {
    tryDisposeFrames();

    _frames = frames;
    currentFrame = 0;
    if (!updateFrames) {
      notifyListeners();
    }
  }
}
