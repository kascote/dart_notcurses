import 'dart:io';

import 'package:dart_notcurses/dart_notcurses.dart';

void main() {
  final nc = NotCurses(CursesOptions(
    marginT: 2,
    marginL: 2,
    marginR: 2,
    marginB: 2,
    loglevel: NcLogLevel.error,
  ));

  if (!nc.initialized()) {
    stderr.writeln('error initializing nocurses');
    return;
  }

  final p = nc.stdplane();

  p.setBgRGB8Clipped(0, 0, 255);
  p.setFgRGB8Clipped(255, 0, 0);
  p.putStrYX(0, 0, 'Red on blue 😎👿💬');
  p.setBgRGB8Clipped(255, 0, 0);
  p.setFgRGB8Clipped(0, 0, 255);
  p.putStrYX(1, 0, 'Red on blue 😎👿💬');

  final c = Cell.init();
  if (p.atYXcell(1, 0, c) < 0) {
    p.releaseCell(c);
    c.destroy(p);
  } else {
    stderr.writeln('cell 0/0 $c');
    nc.render();
    sleep(Duration(seconds: 2));
  }

  nc.stop();
}
