import 'package:animators_gif_enjoyer/functionality/gif_frame_advancer.dart';
import 'package:animators_gif_enjoyer/gif_view_pharan/gif_view.dart';
import 'package:animators_gif_enjoyer/main_screen/frame_base.dart';
import 'package:animators_gif_enjoyer/main_screen/main_screen.dart';
import 'package:animators_gif_enjoyer/main_screen/main_screen_widgets.dart';
import 'package:animators_gif_enjoyer/phlutter/value_notifier_extensions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:animators_gif_enjoyer/utils/path_extensions.dart'
    as path_extensions;

mixin GifPlayer<T extends StatefulWidget>
    on State<T>, TickerProvider, FrameBaseStorer<T> {
  final gifController = GifController();
  ImageProvider? gifImageProvider;
  late GifFrameAdvancer gifAdvancer;
  late PlaybackSpeedController playSpeedController = PlaybackSpeedController(
    setter: (timeScale) => gifAdvancer.timeScale = timeScale,
  );

  final ValueNotifier<int> displayedFrame = ValueNotifier(0);
  final ValueNotifier<int> currentFrame = ValueNotifier(0);

  String get displayedCurrentFrameString {
    return (currentFrame.value + displayFrameBaseOffset).toString();
  }

  final ValueNotifier<RangeValues> focusFrameRange =
      ValueNotifier(const RangeValues(0, 100));

  final ValueNotifier<bool> isScrubMode = ValueNotifier(!isPlayOnLoad);
  final ValueNotifier<int> maxFrameIndex = ValueNotifier(100);
  final ValueNotifier<bool> isUsingFocusRange = ValueNotifier(false);

  RangeValues get fullFrameRange =>
      RangeValues(0, maxFrameIndex.value.toDouble());
  RangeValues get primarySliderRange =>
      isUsingFocusRange.value ? focusFrameRange.value : fullFrameRange;

  GifInfo loadedGifInfo = const GifInfo(
    fileSource: '',
    width: 0,
    height: 0,
    frameDuration: Duration.zero,
    isLoaded: false,
  );
  int get lastGifFrame => gifController.frameCount - 1;

  bool get isGifLoaded => loadedGifInfo.isLoaded;
  bool get isPlayModeAvailable => isGifLoaded && !loadedGifInfo.isNonAnimated;

  /// Tries to get the filename of the loaded GIF.
  String tryGetNameFromGifImageProvider({required String defaultName}) {
    final nameWithoutExtension = switch (gifImageProvider) {
      FileImage _ => path_extensions.filenameFromFullPathWithoutExtensions(
          loadedGifInfo.fileSource,
        ),
      NetworkImage _ => path_extensions.filenameFromUrlWithoutExtension(
          loadedGifInfo.fileSource,
        ),
      null => path_extensions
          .filenameFromFullPathWithoutExtensions(loadedGifInfo.fileSource),
      _ => defaultName
    };

    if (nameWithoutExtension == null || nameWithoutExtension.trim().isEmpty) {
      return defaultName;
    }

    return nameWithoutExtension;
  }

  @override
  void initState() {
    gifAdvancer = GifFrameAdvancer(
      tickerProvider: this,
      onFrame: (frameIndex) => onGifFrameAdvance(frameIndex),
    );
    super.initState();
  }

  void onGifFrameAdvance(int frameIndex) {
    setCurrentFrameClamped(frameIndex);
  }

  @override
  void dispose() {
    gifController.dispose();
    gifAdvancer.dispose();
    super.dispose();
  }

  //
  // Playback controls
  //

  void togglePlayPause() {
    setPlayMode(isScrubMode.value);
  }

  void toggleUseFocus() {
    setState(() {
      clampFocusRange();

      bool willSwitchToFocused = !isUsingFocusRange.value;
      final nextRange =
          willSwitchToFocused ? focusFrameRange.value : fullFrameRange;
      clampCurrentFrameWithRange(nextRange);

      isUsingFocusRange.toggle();
    });
  }

  void setPlayMode(bool active) {
    if (!isPlayModeAvailable) {
      isScrubMode.value = true;
      return;
    }

    isScrubMode.value = !active;
    if (active) {
      final range = primarySliderRange;
      final int start = range.start.toInt();
      final int last = range.end.toInt();
      clampCurrentFrame();

      gifAdvancer.pause();
      gifAdvancer.play(
        start: start,
        last: last,
        current: currentFrame.value,
      );
    } else {
      gifAdvancer.pause();
    }
  }

  void onStartLoadNewGif() {
    setPlayMode(false);
  }

  void onGifLoadSuccess() {
    if (isPlayOnLoad) {
      setPlayMode(true);
    }
  }

  void setDisplayedFrame(int frame) {
    gifController.seek(frame);
    gifAdvancer.setCurrent(frame);
    displayedFrame.value = gifController.currentFrame;
  }

  //
  // Frame controls
  //

  void incrementFrame(int incrementSign) {
    if (incrementSign == 0) return;
    setCurrentFrameClamped(currentFrame.value + incrementSign.sign);
  }

  void setCurrentFrameToFirst() {
    setCurrentFrameClamped(primarySliderRange.startInt);
  }

  void setCurrentFrameToLast() {
    setCurrentFrameClamped(primarySliderRange.endInt);
  }

  void setCurrentFrameClamped(int newFrame) {
    currentFrame.value = newFrame;
    clampCurrentFrameAndShow();
  }

  void clampCurrentFrameAndShow() {
    clampCurrentFrame();
    setDisplayedFrame(currentFrame.value);
  }

  void clampFocusRange() {
    final oldValue = focusFrameRange.value;
    final lastFrameIndex = maxFrameIndex.value.toDouble();

    double minValue = oldValue.start;
    if (minValue < 0) minValue = 0;
    if (minValue > lastFrameIndex) minValue = lastFrameIndex;

    double maxValue = oldValue.end;
    if (maxValue < minValue) maxValue = minValue;
    if (maxValue > lastFrameIndex) maxValue = lastFrameIndex;

    focusFrameRange.value = RangeValues(minValue, maxValue);
  }

  void clampCurrentFrameWithRange(RangeValues range) {
    currentFrame.value =
        clampDouble(currentFrame.value.toDouble(), range.start, range.end)
            .toInt();
  }

  void clampCurrentFrame() {
    setState(() {
      final currentRange = primarySliderRange;
      currentFrame.value = clampDouble(currentFrame.value.toDouble(),
              currentRange.start, currentRange.end)
          .toInt();
    });
  }
}

mixin GifLoader on GifPlayer<GifEnjoyerMainPage> {
  Future? inProgressLoadingProcess;

  final ValueNotifier<bool> isGifDownloading = ValueNotifier(false);
  final ValueNotifier<double> gifDownloadPercent = ValueNotifier(0.0);

  void onGifDownloadSuccess();
  void onGifLoadError(String errorMessage);

  Future loadGifFromGifFrames(
    List<GifFrame> frames,
    String source, {
    bool isImageSequence = false,
  }) async {
    onStartLoadNewGif();

    try {
      loadedGifInfo = GifInfo.fromFrames(
        fileSource: source,
        frames: frames,
        isImageSequence: isImageSequence,
      );
      gifController.load(frames);
      gifAdvancer.setFrames(frames);

      setState(() {
        // Reset sensible values for new file.
        gifImageProvider = null;
        resetViewerStateAfterLoad();
      });
    } catch (e) {
      onGifLoadError(e.toString());
      inProgressLoadingProcess = null;
    }
  }

  void resetViewerStateAfterLoad() {
    int lastFrame = lastGifFrame;
    focusFrameRange.value = RangeValues(0, lastFrame.toDouble());
    maxFrameIndex.value = lastFrame;
    currentFrame.value = 0;
    playSpeedController.resetSpeed();
    isGifDownloading.value = false;
    inProgressLoadingProcess = null;
    onGifLoadSuccess();
  }

  void loadGifFromProvider(
    ImageProvider provider,
    String source,
  ) async {
    onStartLoadNewGif();

    try {
      final isDownload = provider is NetworkImage;
      isGifDownloading.value = isDownload;

      var gifDownload = loadGifFrames(
        provider: provider,
        onProgressPercent: isDownload
            ? (downloadPercent) {
                gifDownloadPercent.value = downloadPercent;
              }
            : null,
      );
      inProgressLoadingProcess = gifDownload;
      final frames = await gifDownload;
      gifImageProvider = provider;
      loadedGifInfo = GifInfo.fromFrames(fileSource: source, frames: frames);
      gifController.load(frames);
      gifAdvancer.setFrames(frames);
      inProgressLoadingProcess = null;

      setState(() {
        resetViewerStateAfterLoad();
        if (gifImageProvider is NetworkImage) {
          onGifDownloadSuccess();
        }
      });
    } catch (e) {
      inProgressLoadingProcess = null;

      if (gifImageProvider is NetworkImage) {
        try {
          var uri = Uri.parse(source);
          if (uri.host.contains('tenor') && !uri.path.endsWith('gif')) {
            final gifLinkError = 'Cannot access : $source \n'
                '(Tenor embed links currently do not work.)';
            onGifLoadError(gifLinkError);
          }
        } catch (m) {
          onGifLoadError(e.toString());
        }
      } else {
        onGifLoadError(e.toString());
      }

      isGifDownloading.value = false;
    }
  }
}

class PlaybackSpeedController {
  PlaybackSpeedController({
    required this.setter,
  });

  final void Function(double timeScale) setter;

  static const defaultSpeed = 1.0;
  static const _speeds = <double>[0.25, 0.5, defaultSpeed, 2, 4];

  final _currentSpeed = ValueNotifier<double>(defaultSpeed);

  String get currentSpeedString {
    return switch (_currentSpeed.value) {
      0.5 => '.5',
      < 1 => _currentSpeed.value.toStringAsPrecision(2).substring(1),
      _ => _currentSpeed.value.toInt().toString(),
    };
  }

  ValueListenable<double> get valueListenable => _currentSpeed;

  bool get isDefaultSpeed => _currentSpeed.value == defaultSpeed;

  void cycleNextSpeed() {
    final currentIndex = _speeds.indexOf(_currentSpeed.value);
    if (currentIndex < 0) {
      _setSpeed(defaultSpeed);
      return;
    }

    final nextIndex =
        (currentIndex == _speeds.length - 1) ? 0 : currentIndex + 1;

    _setSpeed(_speeds[nextIndex]);
  }

  void resetSpeed() {
    _setSpeed(defaultSpeed);
  }

  void _setSpeed(double speed) {
    _currentSpeed.value = speed;
    setter(_currentSpeed.value);
  }
}

class GifInfo {
  const GifInfo({
    required this.fileSource,
    required this.width,
    required this.height,
    required this.frameDuration,
    required this.isLoaded,
    this.isImageSequence = false,
    this.isNonAnimated = false,
  });

  GifInfo._fromFramesAndImageInfo({
    required this.fileSource,
    required List<GifFrame> frames,
    required ImageInfo imageInfo,
    this.isImageSequence = false,
  })  : frameDuration = readFrameDuration(frames),
        width = imageInfo.image.width,
        height = imageInfo.image.height,
        isNonAnimated = isNonMoving(frames),
        isLoaded = true;

  GifInfo.fromFrames({
    required fileSource,
    required List<GifFrame> frames,
    isImageSequence = false,
  }) : this._fromFramesAndImageInfo(
          fileSource: fileSource,
          frames: frames,
          imageInfo: frames[0].imageInfo,
          isImageSequence: isImageSequence,
        );

  final String fileSource;
  final int width;
  final int height;
  final Duration? frameDuration;
  final bool isNonAnimated;
  final bool isLoaded;
  final bool isImageSequence;

  Size get imageSize => Size(width.toDouble(), height.toDouble());

  static bool isNonMoving(List<GifFrame> frames) {
    return frames.length <= 1;
  }

  static Duration? readFrameDuration(List<GifFrame> frames) {
    final duration = frames[0].duration;
    for (final frame in frames) {
      if (duration != frame.duration) return null;
    }
    return duration;
  }
}
