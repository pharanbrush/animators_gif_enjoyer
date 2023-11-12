import 'dart:async';
import 'dart:ui';

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

enum GifStatus { loading, playing, stopped, paused, reversing }

class GifFrame {
  final ImageInfo imageInfo;
  final Duration duration;

  const GifFrame(this.imageInfo, this.duration);
}

/// Loads a List<GifFrame> from an ImageProvider which can then be passed
/// to [GifController.load].
Future<List<GifFrame>> loadGifFrames({
  required ImageProvider provider,
  int? customFrameRate,
  ValueChanged<Object?>? onError,
  ValueChanged<double>? onProgressPercent,
}) async {
  List<GifFrame> frameList = [];
  try {
    Uint8List? data;

    // if (_providerIsCacheable(provider)) {
    //   String key = _getImageKeyFor(provider);
    //   if (_cache.containsKey(key)) {
    //     frameList = _cache[key]!;
    //     return frameList;
    //   }
    // }

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
              if (total > 0) {
                onProgressPercent(received.toDouble() / total.toDouble());
              }
            }).onDone(() {
              isDownloadDone = true;
            });

            while (!isDownloadDone) {
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

    Codec codec = await instantiateImageCodec(
      data,
      allowUpscaling: false,
    );

    if (customFrameRate == null) {
      for (int i = 0, n = codec.frameCount; i < n; i++) {
        FrameInfo frameInfo = await codec.getNextFrame();
        frameList.add(
          GifFrame(
            ImageInfo(image: frameInfo.image),
            frameInfo.duration,
          ),
        );
      }
    } else {
      final customFrameDuration =
          Duration(milliseconds: (1000.0 / customFrameRate).ceil());
      for (int i = 0, n = codec.frameCount; i < n; i++) {
        FrameInfo frameInfo = await codec.getNextFrame();
        frameList.add(
          GifFrame(
            ImageInfo(image: frameInfo.image),
            customFrameDuration,
          ),
        );
      }
    }

    // if (_providerIsCacheable(provider)) {
    //   String key = _getImageKeyFor(provider);
    //   _cache.putIfAbsent(key, () => frameList);
    // }
  } catch (e) {
    if (onError == null) {
      rethrow;
    } else {
      onError(e);
    }
  }
  return frameList;
}

// final Map<String, List<GifFrame>> _cache = {};

// bool _providerIsCacheable(ImageProvider provider) {
//   switch (provider) {
//     // ignore: unused_local_variable
//     case NetworkImage n:
//     // ignore: unused_local_variable
//     case AssetImage a:
//     // ignore: unused_local_variable
//     case MemoryImage m:
//       return true;
//     default:
//       return false;
//   }
// }

// String _getImageKeyFor(ImageProvider provider) {
//   switch (provider) {
//     case NetworkImage ni:
//       return ni.url;
//     case AssetImage ai:
//       return ai.assetName;
//     case MemoryImage mi:
//       return mi.bytes.toString();
//     case FileImage fi:
//       return fi.file.path;
//     default:
//       return "";
//   }
// }

class GifView extends StatefulWidget {
  final GifController? controller;
  final int? frameRate;
  final ImageProvider image;
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

  /// The widget shown while the image data is still being loaded or processed.
  // final Widget? loadingWidget;
  // final bool useLoadingFadeAnimation;
  // final Duration? loadingFadeDuration;

  GifView.network(
    String url, {
    super.key,
    this.controller,
    this.frameRate,
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
    // this.loadingWidget,
    // this.useLoadingFadeAnimation = true,
    // this.loadingFadeDuration,
    double scale = 1.0,
    Map<String, String>? headers,
  }) : image = NetworkImage(url, scale: scale, headers: headers);

  GifView.asset(
    String asset, {
    super.key,
    this.controller,
    this.frameRate,
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
    // this.loadingWidget,
    // this.useLoadingFadeAnimation = true,
    // this.loadingFadeDuration,
    String? package,
    AssetBundle? bundle,
  }) : image = AssetImage(asset, package: package, bundle: bundle);

  GifView.memory(
    Uint8List bytes, {
    super.key,
    this.controller,
    this.frameRate = 15,
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
    // this.loadingWidget,
    // this.useLoadingFadeAnimation = true,
    // this.loadingFadeDuration,
    double scale = 1.0,
  }) : image = MemoryImage(bytes, scale: scale);

  const GifView({
    super.key,
    required this.image,
    this.controller,
    this.frameRate = 15,
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
    //this.useLoadingFadeAnimation = true,
    // this.loadingWidget,
    // this.loadingFadeDuration,
  });

  @override
  GifViewState createState() => GifViewState();
}

class GifViewState extends State<GifView> with TickerProviderStateMixin {
  late GifController controller;
  //AnimationController? _loadingFadeAnimationController;

  @override
  void initState() {
    // if (widget.useLoadingFadeAnimation) {
    //   _loadingFadeAnimationController = AnimationController(
    //     vsync: this,
    //     duration:
    //         widget.loadingFadeDuration ?? const Duration(milliseconds: 150),
    //   );
    // }
    controller = widget.controller ?? GifController();
    controller.addListener(_listener);
    Future.delayed(Duration.zero, _loadImage);
    super.initState();
  }

  @override
  void didUpdateWidget(covariant GifView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.image != widget.image) {
      _loadImage(updateFrames: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (controller.status == GifStatus.loading) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: const SizedBox.shrink(), //widget.loadingWidget,
      );
    }

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
      //opacity: _loadingFadeAnimationController,
    );
  }

  FutureOr _loadImage({bool updateFrames = false}) async {
    final frames = await loadGifFrames(
      provider: widget.image,
      customFrameRate: widget.frameRate,
      onError: widget.onError,
    );
    controller.load(frames, updateFrames: updateFrames);
    //_loadingFadeAnimationController?.forward(from: 0);
  }

  @override
  void dispose() {
    controller.stop();
    controller.removeListener(_listener);
    // _loadingFadeAnimationController?.dispose();
    // _loadingFadeAnimationController = null;
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

  List<GifFrame> get frames => _frames;
  int get currentFrame => _currentFrame;
  set currentFrame(int newValue) {
    _currentFrame = newValue.clamp(0, frameCount);
  }

  int _currentFrame = 0;

  GifFrame get currentFrameData => _frames[currentFrame];
  int get frameCount => _frames.length;

  GifStatus status = GifStatus.loading;

  final bool autoPlay;
  final VoidCallback? onFinish;
  final VoidCallback? onStart;
  final ValueChanged<int>? onFrame;

  bool loop;
  bool _inverted;

  GifController({
    this.autoPlay = true,
    this.loop = true,
    bool inverted = false,
    this.onStart,
    this.onFinish,
    this.onFrame,
  }) : _inverted = inverted;

  void _run() {
    switch (status) {
      case GifStatus.playing:
      case GifStatus.reversing:
        _runNextFrame();
        break;

      case GifStatus.stopped:
        onFinish?.call();
        _currentFrame = 0;
        break;
      case GifStatus.loading:
      case GifStatus.paused:
    }
  }

  void _runNextFrame() async {
    await Future.delayed(_frames[_currentFrame].duration);

    if (status == GifStatus.reversing) {
      if (_currentFrame > 0) {
        _currentFrame--;
      } else if (loop) {
        _currentFrame = _frames.length - 1;
      } else {
        status = GifStatus.stopped;
      }
    } else {
      if (_currentFrame < _frames.length - 1) {
        _currentFrame++;
      } else if (loop) {
        _currentFrame = 0;
      } else {
        status = GifStatus.stopped;
      }
    }

    onFrame?.call(_currentFrame);
    notifyListeners();
    _run();
  }

  void play({bool? inverted, int? initialFrame}) {
    if (status == GifStatus.loading) return;
    _inverted = inverted ?? _inverted;

    if (status == GifStatus.stopped || status == GifStatus.paused) {
      status = _inverted ? GifStatus.reversing : GifStatus.playing;

      bool isValidInitialFrame = initialFrame != null &&
          initialFrame > 0 &&
          initialFrame < _frames.length - 1;

      if (isValidInitialFrame) {
        _currentFrame = initialFrame;
      } else {
        _currentFrame = status == GifStatus.reversing ? _frames.length - 1 : 0;
      }
      onStart?.call();
      _run();
    } else {
      status = _inverted ? GifStatus.reversing : GifStatus.playing;
    }
  }

  void stop() {
    status = GifStatus.stopped;
  }

  void pause() {
    status = GifStatus.paused;
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
      status = GifStatus.stopped;
      if (autoPlay) {
        play();
      }
      notifyListeners();
    }
  }
}
