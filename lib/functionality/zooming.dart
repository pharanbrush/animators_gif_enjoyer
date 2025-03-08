import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../phlutter/windows/scroll_listener.dart';

const double minZoomingPixelDimension = 22; // Size of a Discord inline emote

mixin Zoomer {
  final zoomLevelNotifier = ValueNotifier<double>(
    ScrollZoomContainer.defaultZoom,
  );
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
