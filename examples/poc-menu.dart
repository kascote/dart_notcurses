import 'dart:io';

import 'package:dart_notcurses/dart_notcurses.dart';

const bgChar = '\u28ff';

void main() {
  final nc = NotCurses(CursesOptions(loglevel: NcLogLevel.error));

  if (!nc.initialized()) {
    stderr.writeln('error initializing nocurses');
    return;
  }

  final p = nc.stdplane();
  final mTop = topMenu();
  try {
    mTop.create(p);
    mTop.itemSetStatus('File', 'Close', false);

    p.perimeterDouble();
    nc.miceEnable(NcMiceEvents.allEvents);

    paintBackground(p);
    nc.render();

    while (true) {
      final k = nc.getBlocking();
      if (k.result < 0) {
        break;
      }
      final key = k.value!;
      // Why need different keys between lower and upper case ?
      // this difference need to be handle on user space ?
      if (key.hasCtrl(0x51)) {
        key.destroy();
        break;
      }

      final bool topProcessed = mTop.offerInput(key);
      String topSelectedItem = '';

      final topMouseClick = mTop.mouseSelected(key);
      if (topMouseClick.result != null) {
        topSelectedItem = topMouseClick.result!;
      }

      if (topProcessed || topSelectedItem.isNotEmpty) {
        if (topSelectedItem.isNotEmpty) {
          showSelection(p, 'Mouse Top Menu', topSelectedItem, null);
        }
      } else {
        // discard key release events
        if (key.evType == NcEventType.release) {
          key.destroy();
          nc.render();
          continue;
        }

        final menuOption = mTop.isMenuHotkey(key);
        if (menuOption != null) {
          showSelection(p, 'HotKey Top Menu', menuOption, key);
        }

        if (key.id == NcKey.enter) {
          final rc = mTop.selected();
          if (rc.result != null) {
            rc.value!.destroy();
            showSelection(p, 'Keyboard Top Menu', rc.result!, key);
            mTop.rollup();
          }
        }
      }

      key.destroy();
      if (!nc.render()) {
        stderr.writeln('error rendering');
        break;
      }
    }

    nc.miceDisable();
  } finally {
    mTop.destroy();
    nc.stop();
  }
}

Menu topMenu() {
  final ms = MenuSection(
    'File',
    [
      MenuItem('new-file', 'New File', shortcutKey: 'N', shortcutModifier: NcKeyMod.ctrl),
      MenuItem('open-file', 'Open File', shortcutKey: 'O', shortcutModifier: NcKeyMod.ctrl),
      MenuItem('save-file', 'Save File', shortcutKey: 'S', shortcutModifier: NcKeyMod.ctrl),
      MenuItem('close-file', 'Close', shortcutKey: 'L', shortcutModifier: NcKeyMod.ctrl),
      MenuItem('quit', 'Quit', shortcutKey: 'Q', shortcutModifier: NcKeyMod.ctrl),
    ],
    shortcutKey: 'F',
    shortcutModifier: NcKeyMod.ctrl,
  );
  final ms2 = MenuSection(
      'Edit',
      [
        MenuItem('copy', 'Copy', shortcutKey: 'K', shortcutModifier: NcKeyMod.ctrl),
        MenuItem('paste', 'Paste', shortcutKey: 'V', shortcutModifier: NcKeyMod.ctrl),
        MenuItem('select-all', 'Select All', shortcutKey: 'A', shortcutModifier: NcKeyMod.ctrl),
      ],
      shortcutKey: 'E',
      shortcutModifier: NcKeyMod.ctrl);
  final ms3 = MenuSection(
      'Window',
      [
        MenuItem('window-move-top', 'Move Window top'),
        MenuItem('window-move-bottom', 'Move Window Bottom', shortcutKey: 'B', shortcutModifier: NcKeyMod.ctrl),
        MenuItem('', ''),
        MenuItem('window-close-all', 'Close All')
      ],
      shortcutKey: 'W',
      shortcutModifier: NcKeyMod.ctrl);

  var secChan = Channels.setFgRGB(0, 0xff0000).value; //#ffccaa
  secChan = Channels.setBgRGB(secChan, 0x7f347f).value;
  secChan = Channels.setFgAlpha(secChan, NcAlpha.highcontrast).value;
  secChan = Channels.setBgAlpha(secChan, NcAlpha.blend).value;
  var headChan = Channels.setFgRGB(0, 0xffffff).value;
  headChan = Channels.setBgRGB(headChan, 0x7f347f).value; // #7f347f
  headChan = Channels.setBgAlpha(headChan, NcAlpha.blend).value;

  return Menu(
      [ms, ms2, ms3],
      MenuOptions(
        headerChannels: headChan,
        sectionChannels: secChan,
      ));
}

void showSelection(Plane p, String kind, String menu, Key? key) {
  final dim = p.dimyx();
  final y = (dim.y / 2).floor();

  p.putStrYX(y, 5, '$kind selected ');
  p.setFgRGB(0xffccaa);
  p.putStr(menu);
  p.setFgRGB(0x444444);
  p.setBgRGB(0x000000);
  p.putStr(bgChar.padRight(80, bgChar));

  if (key != null) {
    p.setFgDefault();
    final str = '${key.id.toStrHex(padding: 4)} ${ncKeyStr(key.id)} ${key.keyStr}';
    p.putStrYX(y + 1, 5, str);
    p.setFgRGB(0x444444);
    p.setBgRGB(0x000000);
    p.putStr(bgChar.padRight(80, bgChar));
  } else {
    p.putStrYX(y + 1, 5, bgChar.padRight(80, bgChar));
  }
  p.setFgDefault();
}

void paintBackground(Plane p) {
  final dim = p.dimyx();
  final res = p.loadCell(bgChar);
  if (res.result < 0) {
    stderr.writeln('error loading cell');
    return;
  }
  final c = res.value!;
  c
    ..setFgRGB(0x444444)
    ..setBgRGB(0x000000);
  for (var y = 1; y < dim.y - 1; y++ ) {
    p.cursorMoveYX(y, 1);
    p.hlineInterp(c, dim.x - 2, 0, 0);
  }
}
