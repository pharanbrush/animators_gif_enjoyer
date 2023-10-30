import 'dart:ui';

import 'package:animators_gif_enjoyer/gif_view_pharan/gif_view.dart';
import 'package:animators_gif_enjoyer/interface/shortcuts.dart';
import 'package:animators_gif_enjoyer/main.dart';
import 'package:animators_gif_enjoyer/main_screen/main_screen_widgets.dart';
import 'package:animators_gif_enjoyer/phlutter/modal_panel.dart';
import 'package:animators_gif_enjoyer/utils/download_file.dart';
import 'package:animators_gif_enjoyer/utils/open_file.dart';
import 'package:animators_gif_enjoyer/utils/phclipboard.dart' as phclipboard;
import 'package:animators_gif_enjoyer/utils/value_notifier_extensions.dart';
import 'package:flutter/material.dart';

const Color interfaceColor = Colors.deepPurple; //Colors.blue;

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
          scrim: const Color(0xDDFFFFFF),
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
  final FocusNode mainWindowFocus = FocusNode(canRequestFocus: true);

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
  final ValueNotifier<double> gifDownloadPercent = ValueNotifier(0.0);

  bool get isGifLoaded => gifImageProvider != null;

  RangeValues get primarySliderRange => isUsingFocusRange.value
      ? focusFrameRange.value
      : RangeValues(0, maxFrameIndex.value.toDouble());

  final Map<Type, Action<Intent>> shortcutActions = {};
  late List<(Type, Object? Function(Intent))> shortcutIntentActions = [
    (PreviousIntent, (_) => incrementFrame(-1)),
    (NextIntent, (_) => incrementFrame(1)),
    (CopyIntent, (_) => tryCopyFrameToClipboard()),
    (OpenTextMenu, (_) => bottomTextPanel.open()),
    (PasteAndGoIntent, (_) => textPanelOpenAndPaste()),
  ];

  late final ModalTextPanel bottomTextPanel = ModalTextPanel(
    onClosed: () {
      mainWindowFocus.requestFocus();
    },
    onTextSubmitted: (value) {
      tryLoadGifFromUrl(value);
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
            elevation: 20,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                          border: OutlineInputBorder(
                            borderSide:
                                BorderSide(width: 0, style: BorderStyle.none),
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
          ),
        ),
      ],
    );
  }

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
      body: Center(
        child: Stack(
          children: [
            shortcutsWrapper(child: mainLayer(context)),
            bottomTextPanel.widget(),
          ],
        ),
      ),
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

  void closeAllPanels() {
    bottomTextPanel.close();
  }

  void textPanelOpenAndPaste() async {
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
      return '';
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

  void loadGifFromProvider(
    ImageProvider provider,
    String source,
  ) async {
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
      gifController.load(frames);
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
}
