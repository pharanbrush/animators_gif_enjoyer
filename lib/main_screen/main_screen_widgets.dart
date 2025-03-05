import 'dart:math' as math;

import 'package:animators_gif_enjoyer/gif_view_pharan/gif_view.dart';
import 'package:animators_gif_enjoyer/main_screen/gif_enjoyer_preferences.dart'
    as gif_enjoyer_preferences;
import 'package:animators_gif_enjoyer/main_screen/menu_items.dart'
    as menu_items;
import 'package:animators_gif_enjoyer/main_screen/theme.dart';
import 'package:animators_gif_enjoyer/phlutter/windows/scroll_listener.dart';
import 'package:animators_gif_enjoyer/utils/build_info.dart' as build_info;
import 'package:contextual_menu/contextual_menu.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

const delayedTooltipDelay = Duration(milliseconds: 200);
const slowTooltipDelay = Duration(milliseconds: 600);

class GifViewContainer extends StatelessWidget {
  const GifViewContainer({
    super.key,
    required this.gifImageProvider,
    required this.gifController,
    required this.copyImageHandler,
    required this.openImageHandler,
    required this.pasteHandler,
    required this.exportPngSequenceHandler,
    this.allowWideSliderNotifier,
    this.isAppBusy = false,
    this.zoomLevelNotifier,
    this.fitZoomGetter,
    this.hardMinZoomGetter,
    this.hardMaxZoomGetter,
  });

  final ImageProvider<Object>? gifImageProvider;
  final GifController gifController;
  final VoidCallback copyImageHandler;
  final VoidCallback openImageHandler;
  final VoidCallback pasteHandler;
  final VoidCallback exportPngSequenceHandler;
  final double Function()? fitZoomGetter;
  final double Function()? hardMinZoomGetter;
  final double Function()? hardMaxZoomGetter;
  final ValueNotifier<double>? zoomLevelNotifier;
  final ValueNotifier<bool>? allowWideSliderNotifier;
  final bool isAppBusy;

  @override
  Widget build(BuildContext context) {
    return ScrollZoomContainer(
      notifier: zoomLevelNotifier,
      fitZoomGetter: fitZoomGetter,
      hardMaxZoomGetter: hardMaxZoomGetter,
      hardMinZoomGetter: hardMinZoomGetter,
      child: GestureDetector(
        onSecondaryTap: () => popUpContextualMenu(menu(context)),
        child: GifView(
          image: gifImageProvider!,
          controller: gifController,
        ),
      ),
    );
  }

  Menu menu(BuildContext context) {
    return Menu(
      items: [
        MenuItem(
          label: 'Copy frame image',
          onClick: (_) => copyImageHandler(),
        ),
        menu_items.revealMenuItem(gifImageProvider),
        MenuItem.separator(),
        MenuItem(
          label: 'Open GIF...',
          onClick: (_) => openImageHandler(),
          disabled: isAppBusy,
        ),
        MenuItem(
          label: 'Paste to address bar...',
          onClick: (_) => pasteHandler(),
          disabled: isAppBusy,
        ),
        MenuItem.separator(),
        MenuItem.submenu(
          label: 'Advanced',
          submenu: Menu(
            items: [
              MenuItem(
                label: 'Export PNG Sequence...',
                onClick: (_) => exportPngSequenceHandler(),
                disabled: isAppBusy,
              ),
              MenuItem.separator(),
              if (allowWideSliderNotifier != null)
                menu_items.allowWideSliderMenuItem(allowWideSliderNotifier!),
              menu_items.allowMultipleWindowsMenuItem(),
              menu_items.rememberWindowSizeMenuItem(),
            ],
          ),
        ),
        if (build_info.packageInfo != null) ...menu_items.aboutItem
      ],
    );
  }
}

class ZoomConstraintsContainerBuilder extends StatelessWidget {
  const ZoomConstraintsContainerBuilder({
    super.key,
    required this.contentWidth,
    required this.contentHeight,
    required this.minPixelDimension,
    this.maxZoomFillContainerFactor = 3,
    required this.builder,
  });

  final double contentWidth;
  final double contentHeight;
  final double minPixelDimension;
  final double maxZoomFillContainerFactor;
  final Widget Function(
    BuildContext context,
    double Function() getFitZoom,
    double Function() getMinZoom,
    double Function() getMaxZoom,
  ) builder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final containerSize = constraints.biggest;

        double getRawFitZoom() {
          final fitWidthZoom = containerSize.width / contentWidth;
          final fitHeightZoom = containerSize.height / contentHeight;
          return math.min(fitWidthZoom, fitHeightZoom);
        }

        final rawFitZoom = getRawFitZoom();

        double virtualContentWidth = contentWidth;
        double virtualContentHeight = contentHeight;

        // When content is set to fit,
        // contentWidth and contentHeight will not be representative
        // of the screen dimensions of the content.
        if (rawFitZoom < 1) {
          if (contentWidth > contentHeight) {
            virtualContentWidth = containerSize.width;
            virtualContentHeight =
                virtualContentWidth * contentHeight / contentWidth;
          } else {
            virtualContentHeight = containerSize.height;
            virtualContentWidth =
                virtualContentHeight * contentWidth / contentHeight;
          }
        }

        double getMinZoom() {
          final minWidthZoom = minPixelDimension / virtualContentWidth;
          final minHeightZoom = minPixelDimension / virtualContentHeight;
          return math.min(minWidthZoom, minHeightZoom);
        }

        double getFitZoom() => (rawFitZoom < 1) ? 1 : rawFitZoom;

        double getMaxZoom() {
          bool isHeightShorter = virtualContentWidth > virtualContentHeight;
          final fillZoom = isHeightShorter
              ? (containerSize.height / virtualContentHeight)
              : (containerSize.width / virtualContentWidth);
          return fillZoom * maxZoomFillContainerFactor;
        }

        return builder(
          context,
          getFitZoom,
          getMinZoom,
          getMaxZoom,
        );
      },
    );
  }
}

class ScrollZoomContainer extends StatefulWidget {
  const ScrollZoomContainer({
    super.key,
    required this.child,
    this.notifier,
    this.overzoomThreshold = 10,
    this.fitZoomGetter,
    this.hardMinZoomGetter,
    this.hardMaxZoomGetter,
  });

  static const defaultZoom = 1.0;
  final double Function()? fitZoomGetter;
  final double Function()? hardMinZoomGetter;
  final double Function()? hardMaxZoomGetter;
  final Widget child;
  final ValueNotifier<double>? notifier;
  final int overzoomThreshold;

  @override
  State<ScrollZoomContainer> createState() => _ScrollZoomContainerState();
}

class _ScrollZoomContainerState extends State<ScrollZoomContainer> {
  static const zoomLevels = <double>[
    0.01,
    0.1,
    0.25,
    0.5,
    ScrollZoomContainer.defaultZoom,
    1.5,
    2,
    3,
    4,
    8,
    12,
    16,
    24,
    32,
  ];

  int overZoomIntentionCount = 0;
  late ValueNotifier<double> notifier;

  @override
  void initState() {
    notifier = widget.notifier ??
        ValueNotifier<double>(ScrollZoomContainer.defaultZoom);
    super.initState();
  }

  double findZoomLevelAfter(double current) {
    const epsilon = 0.001;
    for (final level in zoomLevels) {
      if (level > current + epsilon) return level;
    }

    return zoomLevels.last;
  }

  double findZoomLevelBefore(double current) {
    const epsilon = 0.001;
    for (final level in zoomLevels.reversed) {
      if (level < current - epsilon) return level;
    }

    double.minPositive;

    return zoomLevels.first;
  }

  void increment() {
    final currentValue = notifier.value;
    final possibleNextZoom = findZoomLevelAfter(currentValue);
    if (widget.fitZoomGetter != null) {
      final fitZoom = widget.fitZoomGetter!.call();
      if (currentValue <= fitZoom && possibleNextZoom > fitZoom) {
        if (overZoomIntentionCount < widget.overzoomThreshold) {
          overZoomIntentionCount++;
          notifier.value = fitZoom;
          return;
        }
      }
    }

    overZoomIntentionCount = 0;
    if (widget.hardMaxZoomGetter != null) {
      notifier.value = math.min(
        possibleNextZoom,
        widget.hardMaxZoomGetter!.call(),
      );
      return;
    }

    notifier.value = possibleNextZoom;
  }

  void decrement() {
    final possibleNextZoom = findZoomLevelBefore(notifier.value);
    if (widget.hardMinZoomGetter != null) {
      notifier.value = math.max(
        possibleNextZoom,
        widget.hardMinZoomGetter!.call(),
      );
      return;
    }

    notifier.value = findZoomLevelBefore(notifier.value);
  }

  void reset() {
    overZoomIntentionCount = 0;
    notifier.value = ScrollZoomContainer.defaultZoom;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTertiaryTapDown: (_) => reset(),
      child: ScrollListener(
        onScrollUp: increment,
        onScrollDown: decrement,
        child: Container(
          color: Colors.transparent,
          child: SizedBox.expand(
            child: ValueListenableBuilder(
              valueListenable: notifier,
              builder: (_, value, ___) {
                return FittedBox(
                  fit: BoxFit.scaleDown,
                  child: AnimatedScale(
                    duration:
                        const Duration(milliseconds: 300), //Durations.medium1,
                    scale: value,
                    curve: Curves.easeOutQuart, //Easing.standardDecelerate,
                    child: widget.child,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class BottomPlayPauseButton extends StatelessWidget {
  const BottomPlayPauseButton({
    super.key,
    required this.isScrubMode,
    this.onPressed,
  });

  final ValueListenable<bool> isScrubMode;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: isScrubMode,
      builder: (_, isPausedAndScrubbing, __) {
        return Tooltip(
          message: 'Toggle play/pause.\nYou can also click on the gif.',
          waitDuration: slowTooltipDelay,
          child: IconButton(
            style: const ButtonStyle(
              maximumSize: WidgetStatePropertyAll(Size(100, 100)),
            ),
            onPressed: onPressed,
            icon: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0),
              child: Icon(
                color: Theme.of(context).colorScheme.mutedSurfaceColor,
                isPausedAndScrubbing ? Icons.play_arrow : Icons.pause,
              ),
            ),
          ),
        );
      },
    );
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
    this.displayedFrameOffset = 0,
  });

  final VoidCallback? onChange;
  final VoidCallback? onChangeRangeStart;
  final VoidCallback? onChangeRangeEnd;
  final VoidCallback? onChangeTapUp;
  final ValueNotifier<RangeValues> startEnd;
  final ValueNotifier<int> maxFrameIndex;
  final bool enabled;
  final int displayedFrameOffset;

  static const mainSliderTheme = SliderThemeData(
    trackHeight: 2,
    thumbShape: RoundSliderThumbShape(
      disabledThumbRadius: 3,
      enabledThumbRadius: 4,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Row(
        children: [
          Text(
            '$displayedFrameOffset',
            style: Theme.of(context).smallGrayStyle,
          ),
          Expanded(
            child: Theme(
              data: focusTheme,
              child: SliderTheme(
                data: mainSliderTheme.copyWith(
                  thumbColor: focusTheme.colorScheme.inversePrimary,
                ),
                child: ValueListenableBuilder(
                  valueListenable: startEnd,
                  builder: (_, currentStartEnd, __) {
                    return RangeSlider(
                      values: currentStartEnd,
                      min: 0,
                      max: maxFrameIndex.value.toDouble(),
                      labels: RangeLabels(
                        '${(currentStartEnd.startInt + displayedFrameOffset)}',
                        '${(currentStartEnd.endInt + displayedFrameOffset)}',
                      ),
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
          Text(
            '${(maxFrameIndex.value + displayedFrameOffset)}',
            style: Theme.of(context).smallGrayStyle,
          ),
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
    required this.allowWideNotifier,
    this.displayedFrameOffset = 0,
  });

  final int displayedFrameOffset;
  final VoidCallback toggleUseFocus;
  final RangeValues primarySliderRange;
  final ValueNotifier<bool> isUsingFocusRange;
  final ValueNotifier<int> currentFrame;
  final ValueNotifier<bool> allowWideNotifier;
  final GifController gifController;
  final VoidCallback onChange;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, BoxConstraints boxConstraints) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ToggleFocusButton(
            label: '${(primarySliderRange.startInt + displayedFrameOffset)}',
            handleToggle: () => toggleUseFocus(),
            isFocusing: isUsingFocusRange.value,
            enabled: enabled,
          ),
          ValueListenableBuilder(
              valueListenable: allowWideNotifier,
              builder: (_, allowWideValue, __) {
                return ValueListenableBuilder(
                  valueListenable: currentFrame,
                  builder: (_, currentFrameValue, __) {
                    final sliderMin = primarySliderRange.start;
                    final sliderMax = primarySliderRange.end;

                    const int minFramesBeforeShrink = 7;
                    const int reallyFewFrames = 4;
                    const double maximumSpacePerFrame = 40;
                    final limitedFrameCount = sliderMax - sliderMin;

                    final double wideWidth = boxConstraints.maxWidth - 180;

                    final double width = allowWideValue
                        ? wideWidth
                        : switch (limitedFrameCount) {
                            (< reallyFewFrames) =>
                              reallyFewFrames * maximumSpacePerFrame,
                            (< minFramesBeforeShrink) =>
                              limitedFrameCount * maximumSpacePerFrame,
                            _ => minFramesBeforeShrink * maximumSpacePerFrame
                          };

                    var slider = Slider(
                      min: sliderMin,
                      max: sliderMax,
                      value: currentFrameValue.toDouble(),
                      label: '${(currentFrameValue + displayedFrameOffset)}',
                      onChanged: enabled
                          ? (newValue) {
                              currentFrame.value = newValue.toInt();
                              onChange();
                            }
                          : null,
                    );

                    return SliderTheme(
                      data: SliderThemeData(
                        thumbColor: Theme.of(context).colorScheme.secondary,
                        trackHeight: enabled ? 10 : 2,
                        thumbShape: const RoundSliderThumbShape(
                          disabledThumbRadius: 0,
                          elevation: 2,
                        ),
                      ),
                      child: GestureDetector(
                        onTertiaryTapDown: (_) async {
                          gif_enjoyer_preferences
                              .storeAllowWideSliderPreference(
                                  !allowWideNotifier.value);
                          allowWideNotifier.value =
                              await gif_enjoyer_preferences
                                  .getAllowWideSliderPreference();
                        },
                        child: SizedBox(
                          width: width,
                          child: Focus(
                            canRequestFocus: false,
                            autofocus: false,
                            skipTraversal: true,
                            descendantsAreFocusable: false,
                            descendantsAreTraversable: false,
                            child: ScrollListener(
                              onScrollUp: () => increment(currentFrame, 1),
                              onScrollDown: () => increment(currentFrame, -1),
                              child: slider,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              }),
          ToggleFocusButton(
            label: '${(primarySliderRange.endInt + displayedFrameOffset)}',
            handleToggle: () => toggleUseFocus(),
            isFocusing: isUsingFocusRange.value,
            enabled: enabled,
          ),
        ],
      );
    });
  }

  void increment(ValueNotifier<int> notifier, int incrementSign) {
    notifier.value = notifier.value + incrementSign.sign;
    onChange();
  }
}

class ToggleFocusButton extends StatelessWidget {
  const ToggleFocusButton({
    super.key,
    required this.label,
    required this.handleToggle,
    required this.isFocusing,
    required this.enabled,
  });

  final String label;
  final VoidCallback handleToggle;
  final bool isFocusing;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    const customFocusStyle = TextStyle(color: focusRangeColor);

    return Tooltip(
      preferBelow: false,
      message: !enabled
          ? ''
          : isFocusing
              ? 'Click to disable frame range'
              : 'Click to use custom frame range',
      child: TextButton(
        style: const ButtonStyle(
          padding:
              WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 0)),
        ),
        onPressed: enabled ? handleToggle : null,
        child: Text(
          label,
          style: isFocusing ? customFocusStyle : Theme.of(context).grayStyle,
        ),
      ),
    );
  }
}

class EnjoyerBottomTextPanel extends StatelessWidget {
  const EnjoyerBottomTextPanel({
    super.key,
    required this.textController,
    required this.onTextFieldSubmitted,
    required this.onSubmitButtonPressed,
  });

  final TextEditingController textController;
  final Function(String) onTextFieldSubmitted;
  final VoidCallback onSubmitButtonPressed;

  @override
  Widget build(BuildContext context) {
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
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
}

extension RangeValuesExtensions on RangeValues {
  int get endInt => end.toInt();
  int get startInt => start.toInt();

  double get rangeSize => end - start;
}
