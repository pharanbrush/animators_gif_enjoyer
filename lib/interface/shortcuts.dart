import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Phshortcuts {
  static String shortcutString(SingleActivator shortcut) {
    var keyString = shortcut.trigger.keyLabel;
    return '${shortcut.control ? 'Ctrl+' : ''}${shortcut.shift ? 'Shift+' : ''}$keyString';
  }

  static const previous = SingleActivator(LogicalKeyboardKey.arrowLeft);
  static const next = SingleActivator(LogicalKeyboardKey.arrowRight);

  static const previous2 = SingleActivator(LogicalKeyboardKey.keyK);
  static const next2 = SingleActivator(LogicalKeyboardKey.keyJ);

  static const previous3 = SingleActivator(LogicalKeyboardKey.keyA);
  static const next3 = SingleActivator(LogicalKeyboardKey.keyD);

  static const previous4 = SingleActivator(LogicalKeyboardKey.comma);
  static const next4 = SingleActivator(LogicalKeyboardKey.period);

  static const previous5 = SingleActivator(LogicalKeyboardKey.navigatePrevious);
  static const next5 = SingleActivator(LogicalKeyboardKey.navigateNext);

  static const playPause = SingleActivator(LogicalKeyboardKey.keyP);
  static const playPause2 = SingleActivator(LogicalKeyboardKey.space);

  static const restart = SingleActivator(LogicalKeyboardKey.keyR);
  static const openTextMenu = SingleActivator(LogicalKeyboardKey.f2);
  static const openTextMenu2 =
      SingleActivator(LogicalKeyboardKey.keyT, control: true);

  static const copy = SingleActivator(LogicalKeyboardKey.keyC, control: true);
  static const pasteAndGo = SingleActivator(
    LogicalKeyboardKey.keyV,
    control: true,
    //shift: true,
  );

  static const firstFrame = SingleActivator(LogicalKeyboardKey.home);
  static const lastFrame = SingleActivator(LogicalKeyboardKey.end);

  static const openFile =
      SingleActivator(LogicalKeyboardKey.keyO, control: true);
  static const openFolder =
      SingleActivator(LogicalKeyboardKey.keyO, control: true, shift: true);
  static const alwaysOnTop =
      SingleActivator(LogicalKeyboardKey.keyT, control: true);

  static const revealInExplorer =
      SingleActivator(LogicalKeyboardKey.enter, shift: true);

  static const preferences =
      SingleActivator(LogicalKeyboardKey.comma, control: true);

  static const toggleSounds = SingleActivator(LogicalKeyboardKey.keyM);
  static const toggleSimplifiedInterface =
      SingleActivator(LogicalKeyboardKey.keyH);
  static const help = SingleActivator(LogicalKeyboardKey.f1);

  static const escape = SingleActivator(LogicalKeyboardKey.escape);

  static const intentMap = <ShortcutActivator, Intent>{
    Phshortcuts.openFile: OpenFilesIntent(),
    Phshortcuts.openFolder: OpenFolderIntent(),
    Phshortcuts.previous: PreviousIntent(),
    Phshortcuts.next: NextIntent(),
    Phshortcuts.previous2: PreviousIntent(),
    Phshortcuts.next2: NextIntent(),
    Phshortcuts.previous3: PreviousIntent(),
    Phshortcuts.next3: NextIntent(),
    Phshortcuts.previous4: PreviousIntent(),
    Phshortcuts.next4: NextIntent(),
    Phshortcuts.previous5: PreviousIntent(),
    Phshortcuts.next5: NextIntent(),
    Phshortcuts.playPause: PlayPauseIntent(),
    Phshortcuts.playPause2: PlayPauseIntent(),
    Phshortcuts.openTextMenu: OpenTextMenu(),
    Phshortcuts.restart: RestartIntent(),
    Phshortcuts.firstFrame: FirstFrameIntent(),
    Phshortcuts.lastFrame: LastFrameIntent(),
    // Phshortcuts.help: HelpIntent(),
    // Phshortcuts.toggleSimplifiedInterface: SimpleInterfaceToggleIntent(),
    // Phshortcuts.alwaysOnTop: AlwaysOnTopIntent(),
    // Phshortcuts.toggleSounds: ToggleSoundIntent(),
    Phshortcuts.escape: EscapeIntent(),
    Phshortcuts.revealInExplorer: RevealInExplorerIntent(),
    // Phshortcuts.preferences: OpenPreferencesIntent(),
    Phshortcuts.copy: CopyIntent(),
    Phshortcuts.pasteAndGo: PasteAndGoIntent(),
  };
}

class CopyIntent extends Intent {
  const CopyIntent();
}

class PasteAndGoIntent extends Intent {
  const PasteAndGoIntent();
}

class EscapeIntent extends Intent {
  const EscapeIntent();
}

class ToggleSoundIntent extends Intent {
  const ToggleSoundIntent();
}

class NextIntent extends Intent {
  const NextIntent();
}

class PreviousIntent extends Intent {
  const PreviousIntent();
}

class FirstFrameIntent extends Intent {
  const FirstFrameIntent();
}

class LastFrameIntent extends Intent {
  const LastFrameIntent();
}

class PlayPauseIntent extends Intent {
  const PlayPauseIntent();
}

class RestartIntent extends Intent {
  const RestartIntent();
}

class OpenFilesIntent extends Intent {
  const OpenFilesIntent();
}

class OpenFolderIntent extends Intent {
  const OpenFolderIntent();
}

class HelpIntent extends Intent {
  const HelpIntent();
}

class OpenTextMenu extends Intent {
  const OpenTextMenu();
}

class SimpleInterfaceToggleIntent extends Intent {
  const SimpleInterfaceToggleIntent();
}

class AlwaysOnTopIntent extends Intent {
  const AlwaysOnTopIntent();
}

class RevealInExplorerIntent extends Intent {
  const RevealInExplorerIntent();
}

class OpenPreferencesIntent extends Intent {
  const OpenPreferencesIntent();
}
