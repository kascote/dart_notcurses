import 'dart:io';

import 'package:dart_notcurses/dart_notcurses.dart';

int main() {
  final nc = NotCurses.core();
  if (nc.notInitialized) {
    stderr.writeln('can not intialize notcurses');
    return -1;
  }

  while (true) {
    final res = nc.getBlocking();
    if (res.result < 0) break;
    final key = res.value!;
    final utf8 = nc.ucsToUtf8(key.id);

    print('Read input: [${keyView(key)}] $utf8');

    // CTRL+D exit app
    if (key.hasCtrl(68)) {
      key.destroy();
      break;
    }

    key.destroy();
  }

  nc.stop();
  return 0;
}

String keyView(Key key) {
  final keys = StringBuffer();
  keys.write(key.hasShift() ? 'S' : 's');
  keys.write(key.hasAlt() ? 'A' : 'a');
  keys.write(key.hasCtrl() ? 'C' : 'c');
  keys.write(key.hasSuper() ? 'U' : 'u');
  keys.write(key.hasHyper() ? 'H' : 'h');
  keys.write(key.hasMeta() ? 'M' : 'm');
  keys.write(' ');
  return keys.toString();
}
