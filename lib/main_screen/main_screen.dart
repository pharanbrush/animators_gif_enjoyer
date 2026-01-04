import 'dart:ui' as ui;

import 'package:animators_gif_enjoyer/functionality/frame_sliders.dart';
import 'package:animators_gif_enjoyer/functionality/gif_frame_info.dart'
    as gif_frame_info;
import 'package:animators_gif_enjoyer/functionality/zooming.dart';
import 'package:animators_gif_enjoyer/gif_view_pharan/gif_view.dart';
import 'package:animators_gif_enjoyer/interface/shortcuts.dart';
import 'package:animators_gif_enjoyer/main.dart';
import 'package:animators_gif_enjoyer/main_screen/exporter_mixins.dart';
import 'package:animators_gif_enjoyer/main_screen/frame_base.dart';
import 'package:animators_gif_enjoyer/main_screen/gif_enjoyer_preferences.dart';
import 'package:animators_gif_enjoyer/main_screen/gif_enjoyer_preferences.dart'
    as gif_enjoyer_preferences;
import 'package:animators_gif_enjoyer/main_screen/gif_mixins.dart';
import 'package:animators_gif_enjoyer/main_screen/menu_items.dart'
    as menu_items;
import 'package:animators_gif_enjoyer/main_screen/snackbar_mixins.dart';
import 'package:animators_gif_enjoyer/phlutter/app_theme_cycler.dart';
import 'package:animators_gif_enjoyer/main_screen/main_screen_widgets.dart';
import 'package:animators_gif_enjoyer/main_screen/theme.dart' as app_theme;
import 'package:animators_gif_enjoyer/phlutter/remember_window_size.dart';
import 'package:animators_gif_enjoyer/phlutter/windows/image_drop_target.dart';
import 'package:animators_gif_enjoyer/phlutter/material_state_property_utils.dart';
import 'package:animators_gif_enjoyer/phlutter/modal_panel.dart';
import 'package:animators_gif_enjoyer/phlutter/windows/windows_phwindow.dart';
import 'package:animators_gif_enjoyer/utils/build_info.dart' as build_info;
import 'package:animators_gif_enjoyer/functionality/download_file.dart';
import 'package:animators_gif_enjoyer/functionality/open_file.dart'
    as open_file;
import 'package:animators_gif_enjoyer/phlutter/phclipboard.dart' as phclipboard;
import 'package:animators_gif_enjoyer/utils/plural.dart';
import 'package:animators_gif_enjoyer/functionality/reveal_file_source.dart';
import 'package:animators_gif_enjoyer/functionality/save_image_as_png.dart';
import 'package:contextual_menu/contextual_menu.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
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
    return FrameBaseContext(
      child: ThemeContext(
        initialThemeData: app_theme
            .getThemeFromString(initialTheme ?? app_theme.defaultThemeString),
        child: Builder(
          builder: (context) {
            Widget app(ThemeData themeData) {
              return MaterialApp(
                title: appName,
                debugShowCheckedModeBanner: false,
                theme: themeData,
                home: GifEnjoyerMainPage(initialThemeString: initialTheme),
              );
            }

            ThemeContext? themeContext = ThemeContext.of(context);

            if (themeContext == null) {
              return app(
                  app_theme.getThemeFromString(app_theme.defaultThemeString));
            }

            return ValueListenableBuilder(
              valueListenable: themeContext.themeData,
              builder: (_, themeDataValue, ___) => app(themeDataValue),
            );
          },
        ),
      ),
    );
  }
}

class GifEnjoyerMainPage extends StatefulWidget {
  const GifEnjoyerMainPage({
    super.key,
    this.initialThemeString,
  });

  final String? initialThemeString;

  @override
  State<GifEnjoyerMainPage> createState() => GifEnjoyerMainPageState();
}

const bool isPlayOnLoad = true;

class GifEnjoyerMainPageState extends State<GifEnjoyerMainPage>
    with
        SingleTickerProviderStateMixin,
        WindowListener,
        SnackbarShower,
        FrameBaseStorer,
        GifPlayer,
        GifLoader,
        ThemeCycler,
        GifEnjoyerWindowPreferences,
        WindowSizeRememberer,
        Zoomer,
        Exporter {
  final FocusNode mainWindowFocus = FocusNode(canRequestFocus: true);
  late GifEnjoyerMainPageStateShortcuts shortcuts =
      GifEnjoyerMainPageStateShortcuts(this);

  bool get isAppBusy =>
      (inProgressExport != null) || (inProgressLoadingProcess != null);

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
    super.initState();

    void tryLoadFromWindowsOpenWith() {
      if (appFileToLoadFromMainArgs.isNotEmpty) {
        try {
          tryLoadGifFromFilePath(appFileToLoadFromMainArgs);
        } finally {
          appFileToLoadFromMainArgs = '';
        }
      }
    }

    tryLoadFromWindowsOpenWith();
    onSecondWindow = () => tryLoadFromWindowsOpenWith();

    build_info.initializePackageInfo();
  }

  @override
  void onGifLoadSuccess() {
    super.onGifLoadSuccess();
    zoomLevelNotifier.value = ScrollZoomContainer.defaultZoom;
  }

  @override
  void onGifDownloadSuccess() {
    showSnackbar(
      label: 'Download complete',
      icon: const Icon(SnackbarShower.okIcon),
    );
  }

  @override
  void onGifLoadError(String errorMessage) {
    showGifLoadFailedAlert(errorMessage);
  }

  void handleEscapeIntent() {
    if (bottomTextPanel.isOpen) return;
    if (isAppBusy) {
      return;
    }
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

  //
  // Build methods
  //

  @override
  Widget build(BuildContext context) {
    final mainLayerWidget = shortcuts.shortcutsWrapper(
      child: Focus(
        focusNode: mainWindowFocus,
        autofocus: true,
        child: mainLayer(context),
      ),
    );

    final windowContents = <Widget>[
      mainLayerWidget,
      topLeftControls(context),
      bottomTextPanel.widget(),
      fileDropTarget(context),
    ];

    return WindowsPhwindow(
      title: appName,
      titleColor: Theme.of(context).colorScheme.mutedSurfaceColor,
      iconWidget: Image.memory(app_theme.appIconDataBytes),
      addExtraResizingFrame: true,
      child: Stack(
        children: windowContents,
      ),
    );
  }

  Widget topLeftControls(BuildContext context) {
    const double iconSize = 16;
    const double buttonSize = 34;
    const Size size = Size(buttonSize, buttonSize);
    const buttonSizeProperty = WidgetStatePropertyAll(size);

    final buttonContentColor = Theme.of(context).colorScheme.faintGrayColor;
    final contentColorProperty = hoverColors(
      idle: buttonContentColor,
      hover: buttonContentColor.withAlpha(0xFF),
    );
    final buttonStyle = ButtonStyle(
      minimumSize: buttonSizeProperty,
      maximumSize: buttonSizeProperty,
      fixedSize: buttonSizeProperty,
      shape: const WidgetStatePropertyAll(app_theme.appButtonShape),
      iconSize: const WidgetStatePropertyAll(iconSize),
      iconColor: contentColorProperty,
      foregroundColor: contentColorProperty,
      textStyle: WidgetStatePropertyAll(
        Theme.of(context).textTheme.labelSmall!.copyWith(
              overflow: TextOverflow.visible,
            ),
      ),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 0),
      ),
    );
    final activeColor = Theme.of(context).colorScheme.tertiary;
    final activeButtonStyle = ButtonStyle(
      foregroundColor: hoverColors(
        idle: activeColor.withValues(alpha: 0.75),
        hover: activeColor,
      ),
    );
    final iconButtonTheme = IconButtonThemeData(style: buttonStyle);
    final textButtonTheme = TextButtonThemeData(style: buttonStyle);

    final cycleThemeButton = IconButton(
      icon: const Icon(Icons.lightbulb_outline),
      tooltip: 'Cycle interface brightness',
      onPressed: cycleTheme,
    );

    final cyclePlaybackSpeedButton = ValueListenableBuilder(
      valueListenable: playSpeedController.valueListenable,
      builder: (_, __, ___) {
        if (!isPlayModeAvailable) {
          return const SizedBox.shrink();
        }

        return Tooltip(
          message: 'Change playback speed',
          child: GestureDetector(
            onTertiaryTapDown: (_) => playSpeedController.resetSpeed(),
            child: TextButton(
              style:
                  playSpeedController.isDefaultSpeed ? null : activeButtonStyle,
              child: Text('${playSpeedController.currentSpeedString}x'),
              onPressed: () => playSpeedController.cycleNextSpeed(),
            ),
          ),
        );
      },
    );

    final zoomButton = ValueListenableBuilder(
      valueListenable: zoomLevelNotifier,
      builder: (_, __, ___) {
        if (zoomLevelNotifier.value != 1) {
          return IconButton(
            icon: const Icon(Icons.youtube_searched_for),
            tooltip: 'Reset zoom',
            onPressed: () => zoomLevelNotifier.value = 1.0,
          );
        } else {
          return const SizedBox.shrink();
        }
      },
    );

    final List<Widget> buttons = isGifLoaded
        ? [
            cycleThemeButton,
            cyclePlaybackSpeedButton,
            zoomButton,
          ]
        : [
            cycleThemeButton,
          ];

    return Positioned(
      left: 0,
      top: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 2,
          horizontal: 2,
        ),
        child: TooltipTheme(
          data: Theme.of(context).tooltipTheme.copyWith(
                verticalOffset: 35,
                waitDuration: delayedTooltipDelay,
              ),
          child: TextButtonTheme(
            data: textButtonTheme,
            child: IconButtonTheme(
              data: iconButtonTheme,
              child: Column(
                children: buttons,
              ),
            ),
          ),
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
                return gifDownloadingIndicator(context);
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

  Widget gifDownloadingIndicator(BuildContext context) {
    return Center(
      child: SizedBox.square(
        dimension: 150,
        child: ValueListenableBuilder(
          valueListenable: gifDownloadPercent,
          builder: (_, percentDownloaded, __) {
            return CircularProgressIndicator(
              value: percentDownloaded < 0.1 ? null : percentDownloaded,
              strokeWidth: 8,
              strokeCap: StrokeCap.round,
            );
          },
        ),
      ),
    );
  }

  Widget unloadedInterface(BuildContext context) {
    Menu unloadedMenu() {
      return Menu(
        items: [
          MenuItem(
            label: menu_items.openGifLabel,
            onClick: (_) => openNewFile(),
          ),
          MenuItem(
            label: menu_items.pasteToAddressBarLabel,
            onClick: (_) => openTextPanelAndPaste(),
          ),
          MenuItem.separator(),
          MenuItem.submenu(
            label: menu_items.advancedLabel,
            submenu: Menu(
              items: [
                MenuItem(
                  label: menu_items.openImageSequenceFolderLabel,
                  onClick: (_) => userOpenImageSequenceFolder(),
                ),
                MenuItem.separator(),
                menu_items.allowMultipleWindowsMenuItem(),
                menu_items.rememberWindowSizeMenuItem(),
              ],
            ),
          ),
          MenuItem.separator(),
          if (build_info.packageInfo != null)
            MenuItem(
              label: 'Build ${build_info.buildName}',
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

  Menu loadedMenu(BuildContext context) {
    return Menu(
      items: [
        MenuItem(
          label: menu_items.copyFrameImageLabel,
          onClick: (_) => tryCopyFrameToClipboard(),
        ),
        menu_items.revealMenuItem(
          gifImageProvider,
          source: loadedGifInfo.fileSource,
        ),
        MenuItem.separator(),
        MenuItem(
          label: menu_items.openGifLabel,
          onClick: (_) => openNewFile(),
          disabled: isAppBusy,
        ),
        MenuItem(
          label: menu_items.pasteToAddressBarLabel,
          onClick: (_) => openTextPanelAndPaste(),
          disabled: isAppBusy,
        ),
        MenuItem.separator(),
        MenuItem.submenu(
          label: menu_items.advancedLabel,
          submenu: Menu(
            items: [
              MenuItem(
                label: menu_items.exportPngSequenceLabel,
                onClick: (_) => tryExportPngSequence(),
                disabled: isAppBusy,
              ),
              MenuItem(
                label: menu_items.openImageSequenceFolderLabel,
                onClick: (_) => userOpenImageSequenceFolder(),
                disabled: isAppBusy,
              ),
              MenuItem.separator(),
              menu_items.allowWideSliderMenuItem(allowWideSliderNotifier),
              MenuItem.separator(),
              menu_items.allowMultipleWindowsMenuItem(),
              menu_items.rememberWindowSizeMenuItem(),
            ],
          ),
        ),
        if (build_info.packageInfo != null) ...menu_items.aboutItem
      ],
    );
  }

  Widget loadedInterface(BuildContext context) {
    final displayedFrameBaseOffset =
        FrameBaseContext.of(context)?.frameBase.value ?? 0;

    return ValueListenableBuilder(
      valueListenable: isScrubMode,
      builder: (_, __, ___) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: ZoomConstraintsContainerBuilder(
                minPixelDimension: minZoomingPixelDimension,
                contentWidth: loadedGifInfo.width.toDouble(),
                contentHeight: loadedGifInfo.height.toDouble(),
                builder: (_, getFitZoom, getMinZoom, getMaxZoom) {
                  return GestureDetector(
                    onTap: () => togglePlayPause(),
                    onSecondaryTap: () =>
                        popUpContextualMenu(loadedMenu(context)),
                    child: GifViewContainer(
                      gifImageProvider: gifImageProvider,
                      gifController: gifController,
                      zoomLevelNotifier: zoomLevelNotifier,
                      isAppBusy: isAppBusy,
                      allowWideSliderNotifier: allowWideSliderNotifier,
                      fitZoomGetter: getFitZoom,
                      hardMaxZoomGetter: getMaxZoom,
                      hardMinZoomGetter: getMinZoom,
                    ),
                  );
                },
              ),
            ),
            Column(
              children: [
                ValueListenableBuilder(
                  valueListenable: currentFrame,
                  builder: (_, __, ___) {
                    final bigStyle = Theme.of(context).textTheme.headlineMedium;
                    final bigStyleGray = bigStyle?.copyWith(
                            color: Theme.of(context).colorScheme.grayColor) ??
                        Theme.of(context).grayStyle;

                    final separator = Text(' - ', style: bigStyleGray);

                    return GestureDetector(
                      onSecondaryTap: () {
                        final frameBaseContext = FrameBaseContext.of(context);
                        final currentFrameBase = displayFrameBaseOffset;
                        if (frameBaseContext == null) return;

                        Menu menu(BuildContext context) {
                          return Menu(
                            items: currentFrameBase != 0
                                ? [
                                    MenuItem(
                                      label: 'Switch to zero-based frames',
                                      onClick: (_) => setDisplayFrameBase(0),
                                      checked: currentFrameBase == 0,
                                    )
                                  ]
                                : [
                                    MenuItem(
                                      label: 'Switch to one-based frames',
                                      onClick: (_) => setDisplayFrameBase(1),
                                      checked: currentFrameBase == 1,
                                    ),
                                  ],
                          );
                        }

                        popUpContextualMenu(menu(context));
                      },
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          separator,
                          Text(
                            displayedCurrentFrameString,
                            style: isScrubMode.value ? bigStyle : bigStyleGray,
                          ),
                          separator,
                        ],
                      ),
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
                    enabled: isPlayModeAvailable && isScrubMode.value,
                    allowWideNotifier: allowWideSliderNotifier,
                    toggleWideSlider: () =>
                        gif_enjoyer_preferences.toggleAllowWideSliderPreference(
                            allowWideSliderNotifier),
                    onChange: clampCurrentFrameAndShow,
                    displayedFrameOffset: displayedFrameBaseOffset,
                  ),
                ),
              ),
            ),
            ValueListenableBuilder(
              valueListenable: isUsingFocusRange,
              builder: (_, isUseCustomRange, __) {
                final double frameCount = focusFrameRange.value.rangeSize + 1;
                final rangeSeconds = loadedGifInfo.frameDuration != null
                    ? (frameCount *
                        loadedGifInfo.frameDuration!.inMilliseconds.toDouble() *
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
                        displayedFrameOffset: displayedFrameBaseOffset,
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
                            style: const TextStyle(
                                color: app_theme.focusRangeColor),
                          ),
                          isScrubMode.value
                              ? Padding(
                                  padding:
                                      const EdgeInsets.only(left: buttonSpace),
                                  child: IconButton(
                                    style: const ButtonStyle(
                                      minimumSize: WidgetStatePropertyAll(
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
                bottomBarGifInfo(context),
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
                    icon: const Icon(FluentIcons.folder_open_24_regular),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget bottomBarGifInfo(BuildContext context) {
    if (!isGifLoaded) return const SizedBox.shrink();
    final smallGrayStyle = Theme.of(context).smallGrayStyle;

    final isAnimatedWithVariableFps = //
        !loadedGifInfo.isNonAnimated && //
            loadedGifInfo.frameDuration == null;

    String getImageDimensionsLabel() {
      return '${loadedGifInfo.width}x${loadedGifInfo.height}px';
    }

    if (isAnimatedWithVariableFps) {
      return DefaultTextStyle(
        style: smallGrayStyle,
        child: Row(
          children: [
            const Text('Variable frame times. '),
            ValueListenableBuilder(
              valueListenable: currentFrame,
              builder: (_, __, ___) {
                return Text(
                  '(current: ${gifController.currentFrameData.duration.inMilliseconds} ms)',
                );
              },
            ),
            Text('- ${getImageDimensionsLabel()}'),
          ],
        ),
      );
    }

    return Text(
      '${gif_frame_info.getFramerateLabel(loadedGifInfo)}- ${getImageDimensionsLabel()}',
      style: smallGrayStyle,
    );
  }

  Widget fileDropTarget(BuildContext context) {
    return ImageDropTarget(
      dragImagesHandler: (details) {
        if (details.files.isEmpty) return;
        final file = details.files[0];

        final mimeType = file.mimeType;
        if (mimeType == null && open_file.isFolder(file.path)) {
          openImageSequenceFolder(file.path);
          return;
        }

        if (!open_file.isAcceptedFile(filename: file.name)) {
          showSnackbar(
            label: 'Not a GIF',
            icon: const Icon(SnackbarShower.errorIcon),
          );

          if (!open_file.isInformallyAcceptedFile(filename: file.name)) {
            return;
          }
        }

        tryLoadGifFromFilePath(file.path);
      },
    );
  }

  //
  // UI Controls
  //

  void closeAllPanels() {
    bottomTextPanel.close();
  }

  void openTextPanelAndPaste() async {
    if (inProgressExport != null) return;

    final pastedText = await phclipboard.getStringFromClipboard();
    if (pastedText != null) {
      bottomTextPanel.openWithText(pastedText);
    }
  }

  void tryCopyFrameToClipboard() {
    if (!isGifLoaded) return;
    final image = gifController.currentFrameData.imageInfo.image;
    final suggestedName = "gifFrameg${gifController.currentFrame}.png";
    phclipboard.copyImageToClipboardAsPng(image, suggestedName);
  }

  //
  // UI info methods
  //

  Widget getFramerateTooltip() {
    if (!isGifLoaded ||
        !gif_frame_info.showWeirdFramerateWarning(loadedGifInfo)) {
      return const SizedBox.shrink();
    }

    final message = gif_frame_info.getFramerateTooltipMessage(loadedGifInfo);

    return Tooltip(
      message: message,
      child: Icon(
        Icons.info_outline,
        size: 13,
        color: Theme.of(context).colorScheme.grayColor,
      ),
    );
  }

  //
  // Load Operations
  //

  void openNewFile() async {
    if (isAppBusy) return;

    var (gifImage, name) = await open_file.userOpenFilePickerForImages();
    if (gifImage == null || name == null) return;

    loadGifFromProvider(gifImage, name);
  }

  void tryLoadClipboardPath() async {
    final clipboardString = await phclipboard.getStringFromClipboard();
    if (clipboardString == null) return;

    tryLoadGifFromUrl(
      clipboardString,
      errorMessage: 'Pasted text was not a proper URL:\n "$clipboardString"',
    );
  }

  void tryExportPngSequence() async {
    if (!isGifLoaded) return;
    if (isAppBusy) return;

    final imageList = gifController.frames
        .map<ui.Image>((frame) => frame.imageInfo.image)
        .toList(growable: false);

    final gifPrefix =
        tryGetNameFromGifImageProvider(defaultName: 'gif_enjoyer');

    final totalFramesDouble = imageList.length.toDouble();
    inProgressExport = savePngSequenceFromImageList(
      imageList,
      prefix: gifPrefix,
      useSubfolder: true,
      useBaseZero: displayFrameBaseOffset == 0,
      exportCancel: isExportCancelled,
      onExportStart: () {
        exportPercentProgress.value = 0;
        showProgressSnackbar(
          icon: const Icon(Icons.save_alt),
          label: 'Exporting PNGs...',
          progressListenable: exportPercentProgress,
          action: SnackBarAction(
            label: 'Cancel',
            onPressed: () => cancelExport(),
          ),
        );
      },
      onFileSaveProgress: (totalFilesSaved) {
        updateExportPercentProgress(
          totalFilesSaved.toDouble() / totalFramesDouble,
        );
      },
      onExportCanceled: (totalFiles, directory) {
        showSnackbar(
          icon: const Icon(SnackbarShower.canceledIcon),
          label: 'Export canceled.',
          action: (directory == null)
              ? null
              : SnackBarAction(
                  label: 'Open folder',
                  onPressed: () => revealDirectoryInExplorer(directory),
                ),
        );
      },
      onExportSuccess: (totalFiles, directory) {
        showSnackbar(
          label:
              'PNG Sequence exported: $totalFiles image${pluralS(totalFiles)}',
          icon: const Icon(SnackbarShower.okIcon),
          action: (directory == null)
              ? null
              : SnackBarAction(
                  label: 'Open folder',
                  onPressed: () => revealDirectoryInExplorer(directory),
                ),
        );
      },
    )
      ..onError(
        (error, stackTrace) {
          setState(() {
            clearExportStatus();
          });
          showSnackbar(
            icon: const Icon(SnackbarShower.errorIcon),
            label: 'Error exporting PNG sequence.',
          );
        },
      )
      ..whenComplete(
        () => setState(() {
          clearExportStatus();
        }),
      );
    setState(() {});
  }

  void userOpenImageSequenceFolder() async {
    if (isAppBusy) return;

    try {
      var folderPath = await open_file.openFolderSelectorForFileImages();
      if (folderPath == null) return;
      openImageSequenceFolder(folderPath);
    } catch (e) {
      inProgressLoadingProcess = null;
      showSnackbar(
        label: e.toString(),
        icon: const Icon(SnackbarShower.errorIcon),
      );
    }
  }

  void openImageSequenceFolder(String folderPath) async {
    if (isAppBusy) return;
    if (folderPath.isEmpty || !open_file.isFolder(folderPath)) {
      inProgressLoadingProcess = null;
      showSnackbar(
        label: "Could not find folder : '$folderPath'",
        icon: const Icon(SnackbarShower.errorIcon),
      );
      return;
    }

    try {
      var fileImagesProcess = open_file.loadFolderAsFileImages(folderPath);

      inProgressLoadingProcess = fileImagesProcess;
      var fileImages = await fileImagesProcess;
      inProgressLoadingProcess = null;

      if (fileImages == null) return;
      if (fileImages.isEmpty) {
        showSnackbar(
          label: 'Could not find any images in folder.',
          icon: const Icon(SnackbarShower.errorIcon),
        );
        return;
      }

      var frameDuration = const Duration(milliseconds: 40);
      var framerateProcess = open_file.tryGetFramerateFromFolder(folderPath);
      inProgressLoadingProcess = framerateProcess;
      int possibleFramerate = await framerateProcess;
      inProgressLoadingProcess = null;

      final frameMicroseconds = (1000000 / possibleFramerate).round();
      frameDuration = Duration(microseconds: frameMicroseconds);

      var gifFrameLoading = loadGifFramesFromImages(
        fileImages: fileImages,
        frameDuration: frameDuration,
      );

      inProgressLoadingProcess = gifFrameLoading;
      var gifFrames = await gifFrameLoading;
      inProgressLoadingProcess = null;

      await loadGifFromGifFrames(
        gifFrames,
        folderPath,
        isImageSequence: true,
        isGif: false,
      );

      final frameCount = gifFrames.length;
      showSnackbar(
        label:
            'Loaded image sequence with $frameCount frame${pluralS(frameCount)} at $possibleFramerate fps.',
        icon: const Icon(SnackbarShower.okIcon),
      );
    } catch (e) {
      inProgressLoadingProcess = null;
      showSnackbar(
        label: e.toString(),
        icon: const Icon(SnackbarShower.errorIcon),
      );
    }
  }

  void tryLoadGifFromFilePath(String path) {
    if (isAppBusy) return;

    if (path.trim().isEmpty) return;
    loadGifFromProvider(open_file.getFileImageFromPath(path), path);
  }

  void tryLoadGifFromUrl(String url, {String? errorMessage}) {
    if (isAppBusy) return;

    if (url.trim().isEmpty) {
      return;
    }

    if (isUrlString(url)) {
      var provider = NetworkImage(url);
      loadGifFromProvider(provider, url);
    } else {
      showSnackbar(
          label: errorMessage ?? "Can't load url:\n$url",
          icon: const Icon(SnackbarShower.errorIcon));
    }
  }

  //
  // Screen messages
  //

  void showGifLoadFailedAlert(String errorText) {
    showSnackbar(
      label: 'GIF loading failed\n'
          '$errorText',
      icon: const Icon(SnackbarShower.canceledIcon),
    );
  }

  @override
  String get defaultThemeString => app_theme.defaultThemeString;
  @override
  String? get initialThemeString => widget.initialThemeString;
  @override
  ThemeData getThemeFromString(String themeName) =>
      app_theme.getThemeFromString(themeName);
  @override
  String getNextCycleTheme(String currentValue) =>
      app_theme.getNextCycleTheme(currentValue);
}

class GifEnjoyerMainPageStateShortcuts {
  GifEnjoyerMainPageStateShortcuts(this.state);

  final GifEnjoyerMainPageState state;

  final Map<Type, Action<Intent>> shortcutActions = {};
  late List<(Type, Object? Function(Intent))> shortcutIntentActions = [
    (PreviousIntent, (_) => state.incrementFrame(-1)),
    (NextIntent, (_) => state.incrementFrame(1)),
    (CopyIntent, (_) => state.tryCopyFrameToClipboard()),
    (OpenTextMenu, (_) => state.bottomTextPanel.open()),
    (PasteAndGoIntent, (_) => state.openTextPanelAndPaste()),
    (PlayPauseIntent, (_) => state.togglePlayPause()),
    (EscapeIntent, (_) => state.handleEscapeIntent()),
    (FirstFrameIntent, (_) => state.setCurrentFrameToFirst()),
    (LastFrameIntent, (_) => state.setCurrentFrameToLast()),
  ];

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
        child: child,
      ),
    );
  }
}
