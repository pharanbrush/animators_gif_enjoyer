import 'dart:io';
import 'dart:ui';

import 'package:animators_gif_enjoyer/gif_view_pharan/gif_view.dart';
import 'package:animators_gif_enjoyer/interface/shortcuts.dart';
import 'package:animators_gif_enjoyer/utils/value_notifier_extensions.dart';
import 'package:file_selector/file_selector.dart';
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

  bool get isGifLoaded => gifImageProvider != null;

  RangeValues get primarySliderRange => isUsingFocusRange.value
      ? focusFrameRange.value
      : RangeValues(0, maxFrameIndex.value.toDouble());

  final Map<Type, Action<Intent>> shortcutActions = {};
  late List<(Type, Object? Function(Intent))> shortcutIntentActions = [
    (PreviousIntent, (_) => incrementFrame(-1)),
    (NextIntent, (_) => incrementFrame(1)),
  ];

  @override
  void initState() {
    gifController = GifController(
      autoPlay: false,
      loop: true,
    );

    super.initState();
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
                child: isGifLoaded
                    ? loadedInterface(context)
                    : unloadedInterface(context),
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
                          const Tooltip(
                            message: 'Download GIF...',
                            child: IconButton.filled(
                              onPressed: null,
                              icon: Icon(Icons.download),
                            ),
                          ),
                          Tooltip(
                            message: 'Open GIF file...',
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
        if (isGifLoaded)
          Expanded(
            child: GifView(
              image: gifImageProvider!,
              controller: gifController,
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
            final double rangeSeconds = frameDuration != null
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
        return '${frameDuration!.inMilliseconds} milliseconds per frame. '
            '(~${(1000.0 / frameDuration!.inMilliseconds).toStringAsFixed(2)} fps)';
    }
  }

  static Duration? getFrameDuration(List<GifFrame> frames) {
    var duration = frames[0].duration;
    for (var frame in frames) {
      if (duration != frame.duration) return null;
    }

    return duration;
  }

  void openNewFile() async {
    const typeGroup = XTypeGroup(
      label: 'GIFs',
      extensions: ['gif'],
    );

    final file = await openFile(acceptedTypeGroups: const [typeGroup]);
    if (file == null) return;

    final gifImage = FileImage(File(file.path));

    loadGifFromProvider(gifImage, file.name);
  }

  void loadGifFromProvider(
      ImageProvider provider, String sourceFilename) async {
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
    });
  }
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

            return SliderTheme(
              data: const SliderThemeData(
                trackHeight: 10,
              ),
              child: SizedBox(
                width: width,
                child: Slider(
                  min: sliderMin,
                  max: sliderMax,
                  value: currentFrameValue.toDouble(),
                  label: '$currentFrameValue',
                  onChanged: (newValue) {
                    if (!enabled) return;
                    currentFrame.value = newValue.toInt();
                    onChange();
                  },
                ),
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
