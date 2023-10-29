import 'dart:ui';

import 'package:animators_gif_enjoyer/gif_view_pharan/gif_view.dart';
import 'package:animators_gif_enjoyer/interface/shortcuts.dart';
import 'package:animators_gif_enjoyer/utils/download_file.dart';
import 'package:animators_gif_enjoyer/utils/open_file.dart';
import 'package:animators_gif_enjoyer/utils/phclipboard.dart' as phclipboard;
import 'package:animators_gif_enjoyer/utils/value_notifier_extensions.dart';
import 'package:contextual_menu/contextual_menu.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

const appName = "Animator's GIF Enjoyer Deluxe";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    minimumSize: Size.square(460),
    size: Size.square(500),
    center: true,
    title: appName,
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const MyApp());
}

const grayColor = Color(0x55000000);
const grayStyle = TextStyle(color: grayColor);
const double smallTextSize = 12;
const smallGrayStyle = TextStyle(color: grayColor, fontSize: smallTextSize);
const Color focusRangeColor = Colors.green;
const Color interfaceColor = Colors.blue; //Colors.deepPurple

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: interfaceColor,
        ),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: appName),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final FocusNode mainWindowFocus = FocusNode();

  late final GifController gifController;
  ImageProvider? gifImageProvider;
  String filename = '';

  Duration? frameDuration;

  final ValueNotifier<RangeValues> focusFrameRange =
      ValueNotifier(const RangeValues(0, 100));
  final ValueNotifier<int> currentFrame = ValueNotifier(0);
  final ValueNotifier<int> displayedFrame = ValueNotifier(0);
  final ValueNotifier<int> maxFrameIndex = ValueNotifier(100);
  final ValueNotifier<bool> isUsingFocusRange = ValueNotifier(false);
  final ValueNotifier<bool> isGifDownloading = ValueNotifier(false);

  bool get isGifLoaded => gifImageProvider != null;

  RangeValues get primarySliderRange => isUsingFocusRange.value
      ? focusFrameRange.value
      : RangeValues(0, maxFrameIndex.value.toDouble());

  final Map<Type, Action<Intent>> shortcutActions = {};
  late List<(Type, Object? Function(Intent))> shortcutIntentActions = [
    (PreviousIntent, (_) => incrementFrame(-1)),
    (NextIntent, (_) => incrementFrame(1)),
    (CopyIntent, (_) => tryCopyFrameToClipboard()),
    (PasteAndGoIntent, (_) => tryLoadClipboardPath()),
  ];

  @override
  void initState() {
    gifController = GifController(
      autoPlay: false,
      loop: true,
    );
    downloadGifUrlTextController = TextEditingController();

    super.initState();
  }

  @override
  void dispose() {
    downloadGifUrlTextController.dispose();
    super.dispose();
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
      body: shortcutsWrapper(
        child: Center(
          child: Column(
            children: [
              Expanded(
                child: ValueListenableBuilder(
                  valueListenable: isGifDownloading,
                  builder: (_, isCurrentlyDownloading, __) {
                    if (isCurrentlyDownloading) {
                      return const SizedBox.square(
                        dimension: 150,
                        child: CircularProgressIndicator(),
                      );
                    }

                    return isGifLoaded
                        ? loadedInterface(context)
                        : unloadedInterface(context);
                  },
                ),
              ),
              SizedBox(
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Tooltip(
                        message:
                            'GIF frames are each encoded with intervals in 10 millisecond increments.\n'
                            'This makes their actual framerate potentially variable,\n'
                            'and often not precisely fitting common video framerates.',
                        child: Text(
                          getFramerateLabel(),
                          style: smallGrayStyle,
                        ),
                      ),
                      const Spacer(),
                      Wrap(
                        direction: Axis.horizontal,
                        spacing: 8,
                        children: [
                          // const IconButton.filled(
                          //   onPressed: null,
                          //   icon: Icon(Icons.play_arrow),
                          // ),
                          Tooltip(
                            message: 'Open GIF file...\n'
                                'Or use ${Phshortcuts.shortcutString(Phshortcuts.pasteAndGo)} to paste a link to a GIF.',
                            child: IconButton.filled(
                              onPressed: () => openNewFile(),
                              icon: const Icon(Icons.file_open_outlined),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget unloadedInterface(BuildContext context) {
    return Align(
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
    );
  }

  Widget loadedInterface(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: GifViewContainer(
            gifImageProvider: gifImageProvider,
            gifController: gifController,
            copyImageHandler: () => tryCopyFrameToClipboard(),
          ),
        ),
        Column(
          children: [
            ValueListenableBuilder(
              valueListenable: currentFrame,
              builder: (_, currentFrameValue, __) {
                final bigStyle = Theme.of(context).textTheme.headlineMedium;
                final bigStyleGray =
                    bigStyle?.copyWith(color: grayColor) ?? grayStyle;

                final separator = Text(' - ', style: bigStyleGray);

                return Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    separator,
                    Text('$currentFrameValue', style: bigStyle),
                    separator,
                  ],
                );
              },
            ),
            const Text('frame', style: smallGrayStyle)
          ],
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: SizedBox(
            width: double.infinity,
            child: MainSlider(
              toggleUseFocus: toggleUseFocus,
              primarySliderRange: primarySliderRange,
              isUsingFocusRange: isUsingFocusRange,
              currentFrame: currentFrame,
              gifController: gifController,
              enabled: isGifLoaded,
              onChange: updateGifViewFrame,
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

            return Visibility(
              maintainInteractivity: false,
              maintainSemantics: false,
              visible: isUseCustomRange,
              child: Column(
                children: [
                  FrameRangeSlider(
                    startEnd: focusFrameRange,
                    maxFrameIndex: maxFrameIndex,
                    enabled: gifImageProvider != null,
                    onChange: () => clampCurrentFrame(),
                    onChangeRangeStart: () =>
                        setDisplayedFrame(focusFrameRange.value.startInt),
                    onChangeRangeEnd: () =>
                        setDisplayedFrame(focusFrameRange.value.endInt),
                    onChangeTapUp: () => setDisplayedFrame(currentFrame.value),
                  ),
                  Text(
                    'Custom range: ${frameCount.toInt()} frames. ~$rangeSecondsString',
                    style: const TextStyle(color: focusRangeColor),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
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
      isUsingFocusRange.toggle();
    });
  }

  void clampFocusRange() {
    final oldValue = focusFrameRange.value;
    double minValue = oldValue.start;
    minValue = minValue.clamp(0, maxFrameIndex.value.toDouble());

    double maxValue = oldValue.end;
    if (maxValue < minValue) maxValue = maxFrameIndex.value.toDouble();

    focusFrameRange.value = RangeValues(minValue, maxValue);
  }

  void clampCurrentFrame() {
    setState(() {
      currentFrame.value = clampDouble(currentFrame.value.toDouble(),
              focusFrameRange.value.start, focusFrameRange.value.end)
          .toInt();
    });
  }

  void setDisplayedFrame(int frame) {
    gifController.seek(frame);
    displayedFrame.value = gifController.currentFrame;
  }

  String getFramerateLabel() {
    if (!isGifLoaded) {
      return 'No gif loaded';
    }

    const browserDefault = 100;

    switch (frameDuration) {
      case null:
        return 'Variable frame durations';
      case <= const Duration(milliseconds: 10):
        return '${frameDuration!.inMilliseconds} milliseconds per frame. '
            'Browsers usually interpret this as $browserDefault milliseconds.';
      default:
        final frameInterval = frameDuration!.inMilliseconds;
        final fps = 1000.0 / frameInterval;
        return '$frameInterval milliseconds per frame. '
            '(~${fps.toStringAsFixed(2)} fps)';
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

  late TextEditingController downloadGifUrlTextController;

  void downloadGifSubmit(String? url) {
    Navigator.of(context).pop(url);
    downloadGifUrlTextController.text = '';
  }

  void loadGifFromProvider(
    ImageProvider provider,
    String sourceFilename,
  ) async {
    try {
      isGifDownloading.value = true;
      final frames = await loadGifFrames(provider: provider);
      gifImageProvider = provider;
      frameDuration = getFrameDuration(frames);
      gifController.load(frames);
      int lastFrame = frames.length - 1;

      setState(() {
        focusFrameRange.value = RangeValues(0, lastFrame.toDouble());
        maxFrameIndex.value = lastFrame;
        currentFrame.value = 0;
        filename = sourceFilename;
        isGifDownloading.value = false;

        if (gifImageProvider is NetworkImage) {
          popupMessage('Download complete');
        }
      });
    } catch (e) {
      showGifLoadFailedAlert(e.toString());
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

    if (isUrlString(clipboardString)) {
      var provider = NetworkImage(clipboardString);
      loadGifFromProvider(provider, clipboardString);
    } else {
      popupMessage('Pasted text was not a proper URL:\n "$clipboardString"');
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
}

class GifViewContainer extends StatelessWidget {
  GifViewContainer({
    super.key,
    required this.gifImageProvider,
    required this.gifController,
    required this.copyImageHandler,
  });

  final ImageProvider<Object>? gifImageProvider;
  final GifController gifController;
  final VoidCallback copyImageHandler;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onSecondaryTap: () => popUpContextualMenu(menu),
      child: GifView(
        loadingWidget: const CircularProgressIndicator(
          semanticsLabel: 'Circular progress indicator',
          color: Colors.blue,
        ),
        image: gifImageProvider!,
        controller: gifController,
      ),
    );
  }

  late final Menu menu = Menu(
    items: [
      MenuItem(
        label: 'Copy frame image',
        onClick: (_) => copyImageHandler(),
      ),
      MenuItem.separator(),
      MenuItem(label: 'Bunger', disabled: true),
    ],
  );
}

class FrameRangeSlider extends StatelessWidget {
  const FrameRangeSlider({
    super.key,
    required this.startEnd,
    required this.maxFrameIndex,
    this.enabled = true,
    this.onChange,
    this.onChangeRangeStart,
    this.onChangeRangeEnd,
    this.onChangeTapUp,
  });

  final VoidCallback? onChange;
  final VoidCallback? onChangeRangeStart;
  final VoidCallback? onChangeRangeEnd;
  final VoidCallback? onChangeTapUp;
  final ValueNotifier<RangeValues> startEnd;
  final ValueNotifier<int> maxFrameIndex;
  final bool enabled;

  static const mainSliderTheme = SliderThemeData(
    trackHeight: 2,
    thumbShape: RoundSliderThumbShape(
      disabledThumbRadius: 3,
      enabledThumbRadius: 4,
    ),
  );

  static final focusTheme = ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: focusRangeColor),
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Row(
        children: [
          const Text('0', style: smallGrayStyle),
          Expanded(
            child: Theme(
              data: focusTheme,
              child: SliderTheme(
                data: mainSliderTheme,
                child: ValueListenableBuilder(
                  valueListenable: startEnd,
                  builder: (_, currentStartEnd, __) {
                    return RangeSlider(
                      values: currentStartEnd,
                      min: 0,
                      max: maxFrameIndex.value.toDouble(),
                      labels: RangeLabels('${currentStartEnd.startInt}',
                          '${currentStartEnd.endInt}'),
                      onChanged: enabled
                          ? (newValue) {
                              final oldValue = startEnd.value;

                              final pushedValue = RangeValues(
                                newValue.start.floorToDouble(),
                                newValue.end.floorToDouble(),
                              );
                              startEnd.value = pushedValue;

                              onChange?.call();

                              if (oldValue.startInt != newValue.startInt) {
                                onChangeRangeStart?.call();
                              } else if (oldValue.endInt != newValue.endInt) {
                                onChangeRangeEnd?.call();
                              }
                            }
                          : null,
                      onChangeEnd:
                          enabled ? (_) => onChangeTapUp?.call() : null,
                    );
                  },
                ),
              ),
            ),
          ),
          Text('${maxFrameIndex.value}', style: smallGrayStyle),
        ],
      ),
    );
  }
}

class MainSlider extends StatelessWidget {
  const MainSlider({
    super.key,
    required this.toggleUseFocus,
    required this.primarySliderRange,
    required this.isUsingFocusRange,
    required this.currentFrame,
    required this.gifController,
    required this.enabled,
    required this.onChange,
  });

  final VoidCallback toggleUseFocus;
  final RangeValues primarySliderRange;
  final ValueNotifier<bool> isUsingFocusRange;
  final ValueNotifier<int> currentFrame;
  final GifController gifController;
  final VoidCallback onChange;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ToggleFocusButton(
          label: '${primarySliderRange.startInt}',
          handleToggle: () => toggleUseFocus(),
          isFocusing: isUsingFocusRange.value,
        ),
        ValueListenableBuilder(
          valueListenable: currentFrame,
          builder: (_, currentFrameValue, __) {
            final sliderMin = primarySliderRange.start;
            final sliderMax = primarySliderRange.end;

            const int minFramesBeforeShrink = 7;
            const int reallyShortFrames = 4;
            const double maximumSpacePerFrame = 40;
            final limitedFrameCount = sliderMax - sliderMin;

            final double width = switch (limitedFrameCount) {
              (< reallyShortFrames) => reallyShortFrames * maximumSpacePerFrame,
              (< minFramesBeforeShrink) =>
                limitedFrameCount * maximumSpacePerFrame,
              _ => minFramesBeforeShrink * maximumSpacePerFrame
            };

            var slider = Slider(
              min: sliderMin,
              max: sliderMax,
              value: currentFrameValue.toDouble(),
              label: '$currentFrameValue',
              onChanged: (newValue) {
                if (!enabled) return;
                currentFrame.value = newValue.toInt();
                onChange();
              },
            );

            return SliderTheme(
              data: const SliderThemeData(trackHeight: 10),
              child: SizedBox(
                width: width,
                child: slider,
              ),
            );
          },
        ),
        ToggleFocusButton(
          label: '${primarySliderRange.endInt}',
          handleToggle: () => toggleUseFocus(),
          isFocusing: isUsingFocusRange.value,
        ),
      ],
    );
  }
}

class ToggleFocusButton extends StatelessWidget {
  const ToggleFocusButton({
    super.key,
    required this.label,
    required this.handleToggle,
    required this.isFocusing,
  });

  final String label;
  final VoidCallback handleToggle;
  final bool isFocusing;

  @override
  Widget build(BuildContext context) {
    const customFocusStyle = TextStyle(color: focusRangeColor);

    return Tooltip(
      message: isFocusing
          ? 'Click to disable frame range'
          : 'Click to use custom frame range',
      child: TextButton(
        style: const ButtonStyle(
          padding:
              MaterialStatePropertyAll(EdgeInsets.symmetric(horizontal: 0)),
        ),
        onPressed: handleToggle,
        child: Text(
          label,
          style: isFocusing ? customFocusStyle : grayStyle,
        ),
      ),
    );
  }
}

extension RangeValuesExtensions on RangeValues {
  int get endInt => end.toInt();
  int get startInt => start.toInt();

  double get rangeSize => end - start;
}
