import 'dart:io';
import 'dart:ui';

import 'package:animators_gif_enjoyer/gif_view_pharan/gif_view.dart';
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
          seedColor: Colors.deepPurple,
        ),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
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
  late final GifController gifController;
  ImageProvider? gifImageProvider;
  String filename = '';

  Duration? frameDuration = Duration.zero;

  RangeValues get primarySliderRange => isUsingFocusRange.value
      ? focusFrameRange.value
      : RangeValues(0, maxFrameIndex.value.toDouble());

  final ValueNotifier<RangeValues> focusFrameRange =
      ValueNotifier(const RangeValues(0, 100));
  final ValueNotifier<int> currentFrame = ValueNotifier(0);
  final ValueNotifier<int> displayedFrame = ValueNotifier(0);
  final ValueNotifier<int> maxFrameIndex = ValueNotifier(100);
  final ValueNotifier<bool> isUsingFocusRange = ValueNotifier(false);

  bool get isGifLoaded => gifImageProvider != null;

  @override
  void initState() {
    gifController = GifController(
      autoPlay: false,
      loop: true,
    );

    super.initState();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
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
                        frameDuration != null
                            ? '${frameDuration!.inMilliseconds} milliseconds per frame. (~${(1000.0 / frameDuration!.inMilliseconds).toStringAsFixed(2)} fps)'
                            : 'Variable frame durations',
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
    );
  }

  Widget unloadedInterface(BuildContext context) {
    return const Align(
      alignment: Alignment.center,
      child: Material(
        type: MaterialType.transparency,
        child: SizedBox(
          height: 200,
          width: 300,
          child: Center(
            child: Text(
              'Load a GIF!\n'
              'Click on the button on the lower right.\n'
              'or drag and drop a GIF into the window.',
              textAlign: TextAlign.center,
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
            const Text(
              'Frame',
              style: smallGrayStyle,
            )
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
            ),
          ),
        ),
        ValueListenableBuilder(
          valueListenable: isUsingFocusRange,
          builder: (_, isUseCustomRange, __) {
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
                        setDisplayedFrame(focusFrameRange.value.start.toInt()),
                    onChangeRangeEnd: () =>
                        setDisplayedFrame(focusFrameRange.value.end.toInt()),
                    onChangeTapUp: () => setDisplayedFrame(currentFrame.value),
                  ),
                  const Text(
                    'Custom frame range',
                    style: TextStyle(color: focusRangeColor),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Duration? getFrameDuration(List<GifFrame> frames) {
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

  void loadGifFromProvider(ImageProvider provider, String sourceFilename) async {
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
                data: const SliderThemeData(
                  trackHeight: 2,
                  thumbShape: RoundSliderThumbShape(
                    disabledThumbRadius: 3,
                    enabledThumbRadius: 4,
                  ),
                ),
                child: ValueListenableBuilder(
                  valueListenable: startEnd,
                  builder: (_, currentStartEnd, __) {
                    return RangeSlider(
                      values: currentStartEnd,
                      min: 0,
                      max: maxFrameIndex.value.toDouble(),
                      labels: RangeLabels('${currentStartEnd.start.toInt()}',
                          '${currentStartEnd.end.toInt()}'),
                      onChanged: enabled
                          ? (newValue) {
                              final oldValue = startEnd.value;

                              final pushedValue = RangeValues(
                                newValue.start.floorToDouble(),
                                newValue.end.floorToDouble(),
                              );
                              startEnd.value = pushedValue;

                              onChange?.call();

                              if (oldValue.start.toInt() !=
                                  newValue.start.toInt()) {
                                onChangeRangeStart?.call();
                              } else if (oldValue.end.toInt() !=
                                  newValue.end.toInt()) {
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
          Text('${maxFrameIndex.value.toInt()}', style: smallGrayStyle),
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
  });

  final VoidCallback toggleUseFocus;
  final RangeValues primarySliderRange;
  final ValueNotifier<bool> isUsingFocusRange;
  final ValueNotifier<int> currentFrame;
  final GifController gifController;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ToggleFocusButton(
          label: '${primarySliderRange.start.toInt()}',
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
                    //if (!isGifLoaded) return;
                    currentFrame.value = newValue.toInt();
                    gifController.seek(currentFrame.value);
                  },
                ),
              ),
            );
          },
        ),
        ToggleFocusButton(
          label: '${primarySliderRange.end.toInt()}',
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

    return TextButton(
      style: const ButtonStyle(
        padding: MaterialStatePropertyAll(EdgeInsets.symmetric(horizontal: 0)),
      ),
      onPressed: handleToggle,
      child: Text(
        label,
        style: isFocusing ? customFocusStyle : grayStyle,
      ),
    );
  }
}
