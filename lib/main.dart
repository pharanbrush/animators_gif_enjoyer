import 'dart:io';
import 'dart:ui';

import 'package:animators_gif_enjoyer/gif_view_pharan/gif_view.dart';
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

const grayStyle = TextStyle(color: Color(0x55000000));

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
  FileImage? gifImageProvider;
  String filename = '';

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
      isUsingFocusRange.value = !isUsingFocusRange.value;
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
                        bigStyle?.copyWith(color: const Color(0x55000000)) ??
                            grayStyle;

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
                const Text('Frame')
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                width: double.infinity,
                child: Row(
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
                          (< reallyShortFrames) =>
                            reallyShortFrames * maximumSpacePerFrame,
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
                                if (!isGifLoaded) return;
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
                        onChangeRangeStart: () => setDisplayedFrame(
                            focusFrameRange.value.start.toInt()),
                        onChangeRangeEnd: () => setDisplayedFrame(
                            focusFrameRange.value.end.toInt()),
                        onChangeTapUp: () =>
                            setDisplayedFrame(currentFrame.value),
                      ),
                      const Text('Custom frame range'),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 75),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          openNewImage();
        },
        tooltip: 'Load GIF',
        child: const Icon(Icons.file_open),
      ),
    );
  }

  void clampCurrentFrame() {
    setState(() {
      currentFrame.value = clampDouble(currentFrame.value.toDouble(),
              focusFrameRange.value.start, focusFrameRange.value.end)
          .toInt();
    });
  }

  void openNewImage() async {
    const typeGroup = XTypeGroup(
      label: 'GIFs',
      extensions: ['gif'],
    );

    final file = await openFile(acceptedTypeGroups: const [typeGroup]);
    if (file == null) return;

    final gifImage = FileImage(File(file.path));
    gifImageProvider = gifImage;

    final frames = await loadGifFrames(provider: gifImage);
    gifController.load(frames);
    int lastFrame = frames.length - 1;

    setState(() {
      focusFrameRange.value = RangeValues(0, lastFrame.toDouble());
      maxFrameIndex.value = lastFrame;
      currentFrame.value = 0;
      filename = file.name;
    });
  }
}

const Color focusRangeColor = Colors.green;

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
          const Text('0', style: grayStyle),
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
          Text('${maxFrameIndex.value.toInt()}', style: grayStyle),
        ],
      ),
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
    const grayStyle = TextStyle(color: Color(0x55000000));
    const customFocusStyle = TextStyle(color: focusRangeColor);

    return TextButton(
      style: const ButtonStyle(
        padding: MaterialStatePropertyAll(EdgeInsets.symmetric(horizontal: 0)),
      ),
      onPressed: handleToggle,
      child: Text(
        label,
        //'${primarySliderRange.start.toInt()}',
        style: isFocusing ? customFocusStyle : grayStyle,
      ),
    );
  }
}
