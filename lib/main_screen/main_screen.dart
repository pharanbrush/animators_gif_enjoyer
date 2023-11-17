import 'package:animators_gif_enjoyer/gif_view_pharan/gif_view.dart';
import 'package:animators_gif_enjoyer/interface/shortcuts.dart';
import 'package:animators_gif_enjoyer/main.dart';
import 'package:animators_gif_enjoyer/main_screen/main_screen_widgets.dart';
import 'package:animators_gif_enjoyer/main_screen/theme.dart';
import 'package:animators_gif_enjoyer/phlutter/image_drop_target.dart';
import 'package:animators_gif_enjoyer/phlutter/material_state_property_utils.dart';
import 'package:animators_gif_enjoyer/phlutter/modal_panel.dart';
import 'package:animators_gif_enjoyer/phlutter/window_manager_titlebar.dart';
import 'package:animators_gif_enjoyer/utils/build_info.dart';
import 'package:animators_gif_enjoyer/utils/download_file.dart';
import 'package:animators_gif_enjoyer/utils/gif_frame_advancer.dart';
import 'package:animators_gif_enjoyer/utils/open_file.dart';
import 'package:animators_gif_enjoyer/utils/phclipboard.dart' as phclipboard;
import 'package:animators_gif_enjoyer/phlutter/value_notifier_extensions.dart';
import 'package:animators_gif_enjoyer/utils/preferences.dart';
import 'package:contextual_menu/contextual_menu.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    this.initialTheme,
  });

  final String? initialTheme;

  @override
  Widget build(BuildContext context) {
    return ThemeContext(
      initialThemeData: getThemeFromString(initialTheme ?? defaultThemeString),
      child: Builder(
        builder: (context) {
          Widget app(ThemeData themeData) {
            return MaterialApp(
              title: appName,
              debugShowCheckedModeBanner: false,
              theme: themeData,
              home: MyHomePage(initialThemeString: initialTheme),
            );
          }

          ThemeContext? themeContext = ThemeContext.of(context);

          if (themeContext == null) {
            return app(getThemeFromString(defaultThemeString));
          }

          return ValueListenableBuilder(
            valueListenable: themeContext.themeData,
            builder: (_, themeDataValue, ___) => app(themeDataValue),
          );
        },
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    super.key,
    this.initialThemeString,
  });

  final String? initialThemeString;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

const bool isPlayOnLoad = true;

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin, SnackbarShower {
  final FocusNode mainWindowFocus = FocusNode(canRequestFocus: true);
  late GifFrameAdvancer gifAdvancer;

  late final GifController gifController;
  ImageProvider? gifImageProvider;
  String filename = '';

  Duration? frameDuration;
  Size imageSize = Size.zero;

  late final ValueNotifier<String> themeString;
  int _queuedThemeSaveId = 0;

  final ValueNotifier<RangeValues> focusFrameRange =
      ValueNotifier(const RangeValues(0, 100));
  final ValueNotifier<int> currentFrame = ValueNotifier(0);
  final ValueNotifier<int> displayedFrame = ValueNotifier(0);
  final ValueNotifier<int> maxFrameIndex = ValueNotifier(100);
  final ValueNotifier<bool> isUsingFocusRange = ValueNotifier(false);
  final ValueNotifier<bool> isGifDownloading = ValueNotifier(false);
  final ValueNotifier<double> gifDownloadPercent = ValueNotifier(0.0);
  final ValueNotifier<bool> isScrubMode = ValueNotifier(!isPlayOnLoad);
  final ValueNotifier<bool> isAlwaysOnTop = ValueNotifier(false);

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
    textPanelBuilder: (
      context,
      textController,
      onTextFieldSubmitted,
      onSubmitButtonPressed,
    ) {
      return EnjoyerBottomTextPanel(
        textController: textController,
        onTextFieldSubmitted: onTextFieldSubmitted,
        onSubmitButtonPressed: onSubmitButtonPressed,
      );
    },
  );

  //
  //  Lifecycle
  //

  @override
  void initState() {
    themeString =
        ValueNotifier(widget.initialThemeString ?? defaultThemeString);

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

    void tryLoadFromWindowsOpenWith() {
      if (fileToLoadFromMainArgs.isNotEmpty) {
        try {
          tryLoadGifFromFilePath(fileToLoadFromMainArgs);
        } finally {
          fileToLoadFromMainArgs = '';
        }
      }
    }

    tryLoadFromWindowsOpenWith();
    onSecondWindow = () => tryLoadFromWindowsOpenWith();

    initializePackageInfo();

    themeString.addListener(updateAppTheme);
    isAlwaysOnTop.addListener(updateAlwaysOnTop);
  }

  @override
  void dispose() {
    gifAdvancer.dispose();

    themeString.removeListener(updateAppTheme);
    isAlwaysOnTop.removeListener(updateAlwaysOnTop);
    super.dispose();
  }

  void handleEscapeIntent() {
    if (bottomTextPanel.isOpen) return;
    _exitApplication();
  }

  void _exitApplication() {
    //SystemChannels.platform.invokeMethod<void>('SystemNavigator.pop');

    // This is the dirty workaround for a nonfunctional application exit method on Flutter Windows.
    // For more info: https://github.com/flutter/flutter/issues/66631
    // debugger();
    // exit(0);

    //Separate workaround that uses window_manager since already it's a dependency.
    windowManager.close();
  }

  void updateAlwaysOnTop() {
    windowManager.setAlwaysOnTop(isAlwaysOnTop.value);
  }

  void updateAppTheme() {
    final themeContext = ThemeContext.of(context);
    if (themeContext == null) {
      return;
    }

    themeContext.themeData.value = getThemeFromString(themeString.value);

    void queueSaveThemetoPreferences() async {
      int getLatestSaveCommandId() => _queuedThemeSaveId;
      int saveCommandId = DateTime.now().millisecondsSinceEpoch;
      _queuedThemeSaveId = saveCommandId;

      for (int i = 0; i < 5; i++) {
        await Future.delayed(const Duration(milliseconds: 250));
        if (getLatestSaveCommandId() != saveCommandId) return;
      }

      if (getLatestSaveCommandId() == saveCommandId) {
        storeThemeStringPreference(themeString.value);
      }
    }

    queueSaveThemetoPreferences();
  }

  //
  // Build methods
  //

  @override
  Widget build(BuildContext context) {
    final windowContents = Stack(
      children: [
        shortcutsWrapper(child: mainLayer(context)),
        topLeftControls(context),
        bottomTextPanel.widget(),
        fileDropTarget(context),
      ],
    );

    final titleBar = WindowTitlebar(
      title: appName,
      titleColor: Theme.of(context).colorScheme.mutedSurfaceColor,
      iconWidget: Image.memory(appIconDataBytes),
      includeTopWindowResizer: false,
      extraWidgets: [
        ValueListenableBuilder(
          valueListenable: isAlwaysOnTop,
          builder: (_, value, __) {
            return IconButton(
              tooltip: value
                  ? 'Click to disable Keep window on top'
                  : 'Click to enable Keep window on top',
              icon: value
                  ? const Icon(Icons.picture_in_picture_alt)
                  : const Icon(Icons.picture_in_picture_alt_outlined),
              onPressed: () => isAlwaysOnTop.toggle(),
            );
          },
        ),
      ],
    );

    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              titleBar,
              Expanded(child: windowContents),
            ],
          ),
          const WindowResizeFrame(),
        ],
      ),
    );
  }

  Widget topLeftControls(BuildContext context) {
    final grayColor = Theme.of(context).colorScheme.faintGrayColor;
    const double iconSize = 16;
    const double buttonSize = 34;
    final iconButtonTheme = IconButtonThemeData(
      style: ButtonStyle(
        minimumSize:
            const MaterialStatePropertyAll(Size(buttonSize, buttonSize)),
        shape: const MaterialStatePropertyAll(appButtonShape),
        iconSize: const MaterialStatePropertyAll(iconSize),
        iconColor: hoverColors(
          idle: grayColor,
          hover: grayColor.withAlpha(0xFF),
        ),
      ),
    );

    return Positioned(
      left: 0,
      top: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 2,
          horizontal: 2,
        ),
        child: IconButtonTheme(
          data: iconButtonTheme,
          child: Column(
            children: [
              IconButton(
                icon: const Icon(Icons.lightbulb_outline),
                tooltip: 'Cycle interface brightness',
                onPressed: cycleTheme,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void cycleTheme() {
    themeString.value = getNextCycleTheme(themeString.value);
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
      onDoubleTap: () => openNewFile(),
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
                  BottomPlayPauseButton(
                    isScrubMode: isScrubMode,
                    onPressed: () => togglePlayPause(),
                  ),
                Tooltip(
                  message: 'Open GIF file...\n'
                      'Or use ${Phshortcuts.shortcutString(Phshortcuts.pasteAndGo)} to paste a link to a GIF.',
                  child: IconButton(
                    onPressed: () => openNewFile(),
                    color: Theme.of(context).colorScheme.mutedSurfaceColor,
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

  Widget fileDropTarget(BuildContext context) {
    return ImageDropTarget(
      dragImagesHandler: (details) {
        if (details.files.isEmpty) return;
        final file = details.files[0];
        if (!file.name.endsWith('.gif')) {
          showSnackbar(label: 'Not a GIF');
        }

        tryLoadGifFromFilePath(file.path);
      },
    );
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

  //
  // UI Controls
  //

  void closeAllPanels() {
    bottomTextPanel.close();
  }

  void openTextPanelAndPaste() async {
    final pastedText = await phclipboard.getStringFromClipboard();
    if (pastedText != null) {
      bottomTextPanel.openWithText(pastedText);
    }
  }

  void setDisplayedFrame(int frame) {
    gifController.seek(frame);
    displayedFrame.value = gifController.currentFrame;
  }

  void tryCopyFrameToClipboard() {
    if (!isGifLoaded) return;
    final image = gifController.currentFrameData.imageInfo.image;
    final suggestedName = "gifFrameg${gifController.currentFrame}.png";
    phclipboard.copyImageToClipboardAsPng(image, suggestedName);
  }

  //
  // Model controls
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

  void updateGifViewFrame() {
    gifController.seek(currentFrame.value);
  }

  //
  // Frame controls
  //

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

  static bool isFpsWhole(double fps) {
    return fps.floorToDouble() == fps;
  }

  //
  // UI info methods
  //

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

  //
  // Load Operations
  //

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

      frameDuration = readFrameDuration(frames);

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
          showSnackbar(label: 'Download complete');
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
            showSnackbar(
              label: 'Cannot access : $source \n'
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

  static Duration? readFrameDuration(List<GifFrame> frames) {
    var duration = frames[0].duration;
    for (var frame in frames) {
      if (duration != frame.duration) return null;
    }
    return duration;
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
      showSnackbar(label: errorMessage ?? "Can't load url:\n$url");
    }
  }

  //
  // Screen messages
  //

  void showGifLoadFailedAlert(String errorText) {
    showSnackbar(
      label: 'GIF loading failed\n'
          '$errorText',
    );
  }
}

mixin SnackbarShower<T extends StatefulWidget> on State<T> {
  static const IconData emptyIcon = Icons.check_box_outline_blank;
  static const IconData errorIcon = Icons.error_outline;
  static const IconData okIcon = Icons.check;
  static const IconData deleteIcon = Icons.delete;
  static const IconData undoIcon = Icons.undo;
  static const IconData saveIcon = Icons.save_alt;
  static const IconData copyIcon = Icons.copy;

  void showSnackbar({
    required String label,
    Icon? icon,
    SnackBarAction? action,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();

    messenger.showSnackBar(
      SnackBar(
        content: IconTheme(
          data: IconThemeData(
            color: Theme.of(context).colorScheme.onInverseSurface,
          ),
          child: Row(
            children: [
              if (icon != null)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: icon,
                ),
              Flexible(child: Text(label)),
            ],
          ),
        ),
        action: action,
      ),
    );
  }
}
