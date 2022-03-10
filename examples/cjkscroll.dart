import 'dart:io';

import 'package:dart_notcurses/dart_notcurses.dart';

int main() {
  final opts = CursesOptions(
    loglevel: NcLogLevel.error,
    flags: NcOptions.cliMode, // | NcOptions.inhibitSetlocale,
  );
  final nc = NotCurses.core(opts);
  if (nc.notInitialized) {
    stderr.writeln('can not intialize notcurses');
    return -1;
  }

  final std = nc.stdplane();
  var wc = 0x4e00;

  std.setStyles(NcStyle.bold);
  std.putStr('This program is *not* indicative of real scrolling speed.\n');
  std.putStr('ctrl+d exit\n');
  std.setStyles(NcStyle.none);

  while (true) {
    sleep(Duration(milliseconds: 10));
    if (std.putWc(String.fromCharCode(wc)) <= 0) {
      break;
    }

    if(++wc == 0x9fa5){
      wc = 0x4e00;
    }

    if (!nc.render()) {
      break;
    }

    final key = nc.getNonBlocking();
    // CTRL+D exit
    if ((key.result < 0) || (key.value!.hasCtrl(68))) {
      key.value!.destroy();
      break;
    }

    key.value!.destroy();
  }

  nc.stop();
  return 0;
}
