import 'dart:developer';
import 'dart:io';
import 'dart:ui';

import 'package:animators_gif_enjoyer/gif_view_pharan/gif_view.dart';
import 'package:animators_gif_enjoyer/interface/shortcuts.dart';
import 'package:animators_gif_enjoyer/main.dart';
import 'package:animators_gif_enjoyer/main_screen/main_screen_widgets.dart';
import 'package:animators_gif_enjoyer/main_screen/theme.dart';
import 'package:animators_gif_enjoyer/phlutter/image_drop_target.dart';
import 'package:animators_gif_enjoyer/phlutter/modal_panel.dart';
import 'package:animators_gif_enjoyer/utils/build_info.dart';
import 'package:animators_gif_enjoyer/utils/download_file.dart';
import 'package:animators_gif_enjoyer/utils/gif_frame_advancer.dart';
import 'package:animators_gif_enjoyer/utils/open_file.dart';
import 'package:animators_gif_enjoyer/utils/phclipboard.dart' as phclipboard;
import 'package:animators_gif_enjoyer/utils/value_notifier_extensions.dart';
import 'package:contextual_menu/contextual_menu.dart';
import 'package:flutter/material.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ThemeContext(
      child: Builder(
        builder: (context) {
          Widget app(ThemeMode themeMode) {
            return MaterialApp(
              title: appName,
              debugShowCheckedModeBanner: false,
              theme: getEnjoyerTheme(),
              darkTheme: getEnjoyerThemeDark(),
              themeMode: ThemeMode.system,
              home: const MyHomePage(title: appName),
            );
          }

          ThemeContext? themeContext = ThemeContext.of(context);

          if (themeContext == null) {
            return app(ThemeMode.system);
          }

          return ValueListenableBuilder(
            valueListenable: themeContext.themeMode,
            builder: (_, themeModeValue, ___) => app(themeModeValue),
          );
        },
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

const bool isPlayOnLoad = true;

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  final FocusNode mainWindowFocus = FocusNode(canRequestFocus: true);
  late GifFrameAdvancer gifAdvancer;

  late final GifController gifController;
  ImageProvider? gifImageProvider;
  String filename = '';

  Duration? frameDuration;
  Size imageSize = Size.zero;

  final ValueNotifier<RangeValues> focusFrameRange =
      ValueNotifier(const RangeValues(0, 100));
  final ValueNotifier<int> currentFrame = ValueNotifier(0);
  final ValueNotifier<int> displayedFrame = ValueNotifier(0);
  final ValueNotifier<int> maxFrameIndex = ValueNotifier(100);
  final ValueNotifier<bool> isUsingFocusRange = ValueNotifier(false);
  final ValueNotifier<bool> isGifDownloading = ValueNotifier(false);
  final ValueNotifier<double> gifDownloadPercent = ValueNotifier(0.0);
  final ValueNotifier<bool> isScrubMode = ValueNotifier(!isPlayOnLoad);

  bool get isGifLoaded => gifImageProvider != null;

  RangeValues get fullFrameRange =>
      RangeValues(0, maxFrameIndex.value.toDouble());
  RangeValues get primarySliderRange =>
      isUsingFocusRange.value ? focusFrameRange.value : fullFrameRange;

  final Map<Type, Action<Intent>> shortcutActions = {};
  late List<(Type, Object? Function(Intent))> shortcutIntentActions = [
    (PreviousIntent, (_) => incrementFrame(-1)),
    (NextIntent, (_) => incrementFrame(1)),
    (CopyIntent, (_) => tryCopyFrameToClipboard()),
    (OpenTextMenu, (_) => bottomTextPanel.open()),
    (PasteAndGoIntent, (_) => openTextPanelAndPaste()),
    (PlayPauseIntent, (_) => togglePlayPause()),
    (EscapeIntent, (_) => handleEscapeIntent()),
  ];

  late final ModalTextPanel bottomTextPanel = ModalTextPanel(
    onClosed: () {
      mainWindowFocus.requestFocus();
    },
    onTextSubmitted: (value) {
      tryLoadGifFromUrl(value);
    },
    transitionBuilder: (child, animation) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      );
    },
    textPanelBuilder: bottomTextPanelBuilder,
  );

  Widget bottomTextPanelBuilder(
    BuildContext context,
    TextEditingController textController,
    Function(String) onTextFieldSubmitted,
    VoidCallback onSubmitButtonPressed,
  ) {
    return Stack(
      children: [
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Material(
            type: MaterialType.canvas,
            borderRadius: const BorderRadius.only(
              topLeft: borderRadiusRadius,
              topRight: borderRadiusRadius,
            ),
            elevation: 20,
            child: Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Material(
                    type: MaterialType.canvas,
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: textController,
                            style: const TextStyle(fontSize: 13),
                            decoration: const InputDecoration(
                              hintText: 'Enter GIF link',
                              border: OutlineInputBorder(
                                borderSide: BorderSide(
                                    width: 0, style: BorderStyle.none),
                              ),
                            ),
                            autocorrect: false,
                            onSubmitted: onTextFieldSubmitted,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: IconButton(
                            onPressed: onSubmitButtonPressed,
                            icon: const Icon(Icons.send),
                            tooltip: 'Download GIF from Link',
                          ),
                        )
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  void initState() {
    gifAdvancer = GifFrameAdvancer(
      tickerProvider: this,
      onFrame: (frameIndex) {
        setCurrentFrame(frameIndex);
      },
    );
    gifController = GifController(
      autoPlay: false,
      loop: true,
    );

    super.initState();

    tryLoadFromWindowsOpenWith();
    onSecondWindow = () => tryLoadFromWindowsOpenWith();

    tryGetPackageInfo();
  }

  void tryGetPackageInfo() async {
    initializePackageInfo();
  }

  void tryLoadFromWindowsOpenWith() {
    if (fileToLoadFromMainArgs.isNotEmpty) {
      try {
        tryLoadGifFromFilePath(fileToLoadFromMainArgs);
      } finally {
        fileToLoadFromMainArgs = '';
      }
    }
  }

  @override
  void dispose() {
    gifAdvancer.dispose();
    super.dispose();
  }

  void setCurrentFrame(int newFrame) {
    currentFrame.value = newFrame;
    clampCurrentFrame();
    setDisplayedFrame(newFrame);
  }

  void incrementFrame(int incrementSign) {
    if (incrementSign > 0) {
      currentFrame.value += 1;
    } else if (incrementSign < 0) {
      currentFrame.value -= 1;
    }

    clampCurrentFrame();
    updateGifViewFrame();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Stack(
          children: [
            shortcutsWrapper(child: mainLayer(context)),
            bottomTextPanel.widget(),
            fileDropTarget(context),
          ],
        ),
      ),
    );
  }

  Widget fileDropTarget(BuildContext context) {
    return ImageDropTarget(
      dragImagesHandler: (details) {
        if (details.files.isEmpty) return;
        final file = details.files[0];
        if (!file.name.endsWith('.gif')) {
          popupMessage('Not a GIF');
        }

        tryLoadGifFromFilePath(file.path);
      },
    );
  }

  Widget mainLayer(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ValueListenableBuilder(
            valueListenable: isGifDownloading,
            builder: (_, isCurrentlyDownloading, __) {
              if (isCurrentlyDownloading) {
                return Center(
                  child: SizedBox.square(
                    dimension: 150,
                    child: ValueListenableBuilder(
                      valueListenable: gifDownloadPercent,
                      builder: (_, value, __) {
                        return CircularProgressIndicator(
                          value: value < 0.1 ? null : value,
                          strokeWidth: 8,
                          strokeCap: StrokeCap.round,
                        );
                      },
                    ),
                  ),
                );
              }

              return isGifLoaded
                  ? loadedInterface(context)
                  : unloadedInterface(context);
            },
          ),
        ),
        bottomBarWidget()
      ],
    );
  }

  Widget bottomBarWidget() {
    return SizedBox(
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 4,
              children: [
                getFramerateTooltip(),
                Text(
                  getGifInfoBottomLabel(),
                  style: Theme.of(context).smallGrayStyle,
                ),
              ],
            ),
            const Spacer(),
            Wrap(
              direction: Axis.horizontal,
              spacing: 8,
              children: [
                if (isGifLoaded)
                  ValueListenableBuilder(
                    valueListenable: isScrubMode,
                    builder: (_, isPausedAndScrubbing, __) {
                      return IconButton(
                        style: const ButtonStyle(
                          maximumSize: MaterialStatePropertyAll(
                            Size(100, 100),
                          ),
                        ),
                        onPressed: () => togglePlayPause(),
                        tooltip:
                            'Toggle play/pause.\nYou can also click on the gif.',
                        icon: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15.0),
                          child: Icon(
                            isPausedAndScrubbing
                                ? Icons.play_arrow
                                : Icons.pause,
                          ),
                        ),
                      );
                    },
                  ),
                Tooltip(
                  message: 'Open GIF file...\n'
                      'Or use ${Phshortcuts.shortcutString(Phshortcuts.pasteAndGo)} to paste a link to a GIF.',
                  child: IconButton(
                    onPressed: () => openNewFile(),
                    icon: const Icon(Icons.file_open_outlined),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget unloadedInterface(BuildContext context) {
    Menu unloadedMenu() {
      return Menu(
        items: [
          MenuItem(
            label: 'Open GIF...',
            onClick: (_) => openNewFile(),
          ),
          MenuItem(
            label: 'Paste to address bar...',
            onClick: (_) => openTextPanelAndPaste(),
          ),
          MenuItem.separator(),
          themeSubmenu(context),
          MenuItem.separator(),
          if (packageInfo != null)
            MenuItem(
              label: 'Build $buildName',
              disabled: true,
            )
        ],
      );
    }

    return GestureDetector(
      onSecondaryTap: () => popUpContextualMenu(unloadedMenu()),
      child: Container(
        decoration:
            BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor),
        child: Align(
          alignment: Alignment.center,
          child: Material(
            type: MaterialType.transparency,
            child: SizedBox(
              height: 200,
              width: 300,
              child: Center(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Load a GIF!',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Use the button on the lower right.\n'
                      'Or drag and drop a GIF into the window.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget loadedInterface(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: isScrubMode,
      builder: (_, __, ___) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => togglePlayPause(),
                child: GifViewContainer(
                  gifImageProvider: gifImageProvider,
                  gifController: gifController,
                  copyImageHandler: () => tryCopyFrameToClipboard(),
                  openImageHandler: () => openNewFile(),
                  pasteHandler: () => openTextPanelAndPaste(),
                ),
              ),
            ),
            Column(
              children: [
                ValueListenableBuilder(
                  valueListenable: currentFrame,
                  builder: (_, currentFrameValue, __) {
                    final bigStyle = Theme.of(context).textTheme.headlineMedium;
                    final bigStyleGray = bigStyle?.copyWith(
                            color: Theme.of(context).colorScheme.grayColor) ??
                        Theme.of(context).grayStyle;

                    final separator = Text(' - ', style: bigStyleGray);

                    return Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        separator,
                        Text(
                          '$currentFrameValue',
                          style: isScrubMode.value ? bigStyle : bigStyleGray,
                        ),
                        separator,
                      ],
                    );
                  },
                ),
                Text('frame', style: Theme.of(context).smallGrayStyle)
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: isScrubMode.value ? null : () => setPlayMode(false),
                  child: MainSlider(
                    toggleUseFocus: toggleUseFocus,
                    primarySliderRange: primarySliderRange,
                    isUsingFocusRange: isUsingFocusRange,
                    currentFrame: currentFrame,
                    gifController: gifController,
                    enabled: isGifLoaded && isScrubMode.value,
                    onChange: updateGifViewFrame,
                  ),
                ),
              ),
            ),
            ValueListenableBuilder(
              valueListenable: isUsingFocusRange,
              builder: (_, isUseCustomRange, __) {
                final double frameCount = focusFrameRange.value.rangeSize + 1;
                final rangeSeconds = frameDuration != null
                    ? (frameCount *
                        frameDuration!.inMilliseconds.toDouble() *
                        0.001)
                    : -1;

                final String rangeSecondsString = rangeSeconds >= 0
                    ? '${rangeSeconds.toStringAsFixed(2)} seconds'
                    : '';

                const double buttonSize = 25;
                const double buttonSpace = 4;

                return Visibility(
                  maintainInteractivity: false,
                  maintainSemantics: false,
                  visible: isUseCustomRange,
                  child: Column(
                    children: [
                      FrameRangeSlider(
                        startEnd: focusFrameRange,
                        maxFrameIndex: maxFrameIndex,
                        enabled: isGifLoaded && isScrubMode.value,
                        onChange: () => clampCurrentFrame(),
                        onChangeRangeStart: () =>
                            setDisplayedFrame(focusFrameRange.value.startInt),
                        onChangeRangeEnd: () =>
                            setDisplayedFrame(focusFrameRange.value.endInt),
                        onChangeTapUp: () =>
                            setDisplayedFrame(currentFrame.value),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (isScrubMode.value)
                            const SizedBox(width: buttonSize + buttonSpace + 3),
                          Text(
                            'Custom range: ${frameCount.toInt()} frames. ~$rangeSecondsString',
                            style: const TextStyle(color: focusRangeColor),
                          ),
                          isScrubMode.value
                              ? Padding(
                                  padding:
                                      const EdgeInsets.only(left: buttonSpace),
                                  child: IconButton(
                                    style: const ButtonStyle(
                                      minimumSize: MaterialStatePropertyAll(
                                        Size(buttonSize, buttonSize),
                                      ),
                                    ),
                                    tooltip: 'Disable frame range',
                                    iconSize: 12,
                                    onPressed: () => toggleUseFocus(),
                                    icon: const Icon(Icons.close),
                                  ),
                                )
                              : const SizedBox(height: buttonSize + 3),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  void closeAllPanels() {
    bottomTextPanel.close();
  }

  void togglePlayPause() {
    setPlayMode(isScrubMode.value);
  }

  void setPlayMode(bool active) {
    if (!isGifLoaded) return;

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

  void openTextPanelAndPaste() async {
    final pastedText = await phclipboard.getStringFromClipboard();
    if (pastedText != null) {
      bottomTextPanel.openWithText(pastedText);
    }
  }

  void updateGifViewFrame() {
    gifController.seek(currentFrame.value);
  }

  Widget shortcutsWrapper({required Widget child}) {
    if (shortcutActions.isEmpty) {
      for (var (intentType, callback) in shortcutIntentActions) {
        shortcutActions[intentType] = CallbackAction(onInvoke: callback);
      }
    }

    return Shortcuts(
      shortcuts: Phshortcuts.intentMap,
      child: Actions(
        actions: shortcutActions,
        child: Focus(
          focusNode: mainWindowFocus,
          autofocus: true,
          child: child,
        ),
      ),
    );
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

  void setDisplayedFrame(int frame) {
    gifController.seek(frame);
    displayedFrame.value = gifController.currentFrame;
  }

  static bool isFpsWhole(double fps) {
    return fps.floorToDouble() == fps;
  }

  Widget getFramerateTooltip() {
    if (!isGifLoaded) return const SizedBox.shrink();
    if (frameDuration == null) return const SizedBox.shrink();

    final frameMilliseconds = frameDuration!.inMilliseconds;
    final fpsDouble = 1000.0 / frameMilliseconds;
    if (frameMilliseconds > 0 && isFpsWhole(fpsDouble)) {
      return const SizedBox.shrink();
    }

    String message =
        'GIF frames are each encoded with intervals in 10 millisecond increments.\n'
        'This makes their actual framerate potentially variable,\n'
        'and often not precisely fitting common video framerates.';
    if (frameMilliseconds <= 10) {
      message = 'Browsers usually reinterpret delays\n'
          'below 20 milliseconds as 100 milliseconds.';
    }

    return Tooltip(
      message: message,
      child: Icon(
        Icons.info_outline,
        size: 13,
        color: Theme.of(context).colorScheme.grayColor,
      ),
    );
  }

  String getGifInfoBottomLabel() {
    if (!isGifLoaded) {
      return '';
    }

    return '${getFramerateLabel()}- ${getImageDimensionsLabel()}';
  }

  String getImageDimensionsLabel() {
    if (!isGifLoaded) {
      return '';
    }

    return '${imageSize.width.toInt()}x${imageSize.height.toInt()}px';
  }

  String getFramerateLabel() {
    if (!isGifLoaded) {
      return '';
    }

    const millisecondsUnit = 'ms';
    
    switch (frameDuration) {
      case null:
        return 'Variable frame durations';
      case <= const Duration(milliseconds: 10):
        return '${frameDuration!.inMilliseconds} $millisecondsUnit per frame.';
      default:
        final frameInterval = frameDuration!.inMilliseconds;
        final fps = 1000.0 / frameInterval;
        return '~${fps.toStringAsFixed(2)} fps '
            '($frameInterval $millisecondsUnit per frame.) ';
    }
  }

  static Duration? getFrameDuration(List<GifFrame> frames) {
    var duration = frames[0].duration;
    for (var frame in frames) {
      if (duration != frame.duration) return null;
    }
    return duration;
  }

  void tryCopyFrameToClipboard() {
    if (!isGifLoaded) return;
    final image = gifController.currentFrameData.imageInfo.image;
    final suggestedName = "gifFrameg${gifController.currentFrame}.png";
    phclipboard.copyImageToClipboardAsPng(image, suggestedName);
  }

  void openNewFile() async {
    var (gifImage, name) = await openGifImageFile();
    if (gifImage == null || name == null) return;

    loadGifFromProvider(gifImage, name);
  }

  void loadGifFromProvider(
    ImageProvider provider,
    String source,
  ) async {
    setPlayMode(false);

    try {
      final isDownload = provider is NetworkImage;
      isGifDownloading.value = isDownload;
      final frames = await loadGifFrames(
        provider: provider,
        onProgressPercent: isDownload
            ? (downloadPercent) {
                gifDownloadPercent.value = downloadPercent;
              }
            : null,
      );
      gifImageProvider = provider;

      frameDuration = getFrameDuration(frames);

      final image = frames[0].imageInfo.image;
      imageSize = Size(image.width.toDouble(), image.height.toDouble());

      gifController.load(frames);
      gifAdvancer.setFrames(frames);
      int lastFrame = frames.length - 1;

      setState(() {
        focusFrameRange.value = RangeValues(0, lastFrame.toDouble());
        maxFrameIndex.value = lastFrame;
        currentFrame.value = 0;
        filename = source;
        isGifDownloading.value = false;

        if (gifImageProvider is NetworkImage) {
          popupMessage('Download complete');
        }

        if (isPlayOnLoad) {
          setPlayMode(true);
        }
      });
    } catch (e) {
      if (gifImageProvider is NetworkImage) {
        try {
          var uri = Uri.parse(source);
          if (uri.host.contains('tenor') && !uri.path.endsWith('gif')) {
            popupMessage(
              'Cannot access : $source \n'
              '(Tenor embed links currently do not work.)',
            );
          }
        } catch (m) {
          showGifLoadFailedAlert(e.toString());
        }
      } else {
        showGifLoadFailedAlert(e.toString());
      }

      isGifDownloading.value = false;
    }
  }

  void showGifLoadFailedAlert(String errorText) {
    popupMessage(
      'GIF loading failed\n'
      '$errorText',
    );
  }

  void tryLoadClipboardPath() async {
    final clipboardString = await phclipboard.getStringFromClipboard();
    if (clipboardString == null) return;

    tryLoadGifFromUrl(
      clipboardString,
      errorMessage: 'Pasted text was not a proper URL:\n "$clipboardString"',
    );
  }

  void tryLoadGifFromFilePath(String path) {
    if (path.isEmpty) return;
    loadGifFromProvider(getFileImageFromPath(path), path);
  }

  void tryLoadGifFromUrl(String url, {String? errorMessage}) {
    if (url.isEmpty) {
      return;
    }

    if (isUrlString(url)) {
      var provider = NetworkImage(url);
      loadGifFromProvider(provider, url);
    } else {
      popupMessage(errorMessage ?? "Can't load url:\n$url");
    }
  }

  void popupMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        showCloseIcon: true,
        content: Text(message),
      ),
    );
  }

  void handleEscapeIntent() {
    if (bottomTextPanel.isOpen) return;
    _exitApplication();
  }

  void _exitApplication() {
    //SystemChannels.platform.invokeMethod<void>('SystemNavigator.pop');

    // This is the dirty workaround for a nonfunctional application exit method on Flutter Windows.
    // For more info: https://github.com/flutter/flutter/issues/66631
    debugger();
    exit(0);
  }
}
