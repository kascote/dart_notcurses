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

  if (nc.notInitialized) {
    stderr.writeln('error initializing nocurses');
    return;
  }

  final p = nc.stdplane();

  try {
    p.cursorMoveYX(2, 2);
    final c1 = p.primeCell('\u{1F982}', 0, 0);
    if (c1.result < 0) {
      stderr.writeln('error creating cell1');
    } else {
      final x = c1.value!;
      p.hline(x, 20);
      x.destroy(p);
    }

    final c2 = p.primeCell('|', 0, 0);
    if (c2.result < 0) {
      stderr.writeln('error creating cell2');
    } else {
      final x = c2.value!;
      p.vline(x, 20);
      x.destroy(p);
    }

    final ul = p.loadCell('╔').value!
      ..setFgRGB(0xffffff)
      ..setBgRGB(0x002000);

    final ur = p.loadCell('╗').value!
      ..setFgRGB(0x0000ff)
      ..setBgRGB(0x002000);

    final ll = p.loadCell('╚').value!
      ..setFgRGB(0x00ff00)
      ..setBgRGB(0x002000);

    final lr = p.loadCell('╝').value!
      ..setFgRGB(0xff0000)
      ..setBgRGB(0x002000);

    final hline = p.loadCell('═').value!;
    final vline = p.loadCell('║').value!;

    p.cursorMoveYX(15, 15);
    p.box(ul, ur, ll, lr, hline, vline, 30, 30, 16 | 64 | 32 | 128 );
    p.perimeter(ul, ur, ll, lr, hline, vline, 16 | 64 | 32 | 128 );

    ul.destroy(p); ur.destroy(p); ll.destroy(p); lr.destroy(p);
    hline.destroy(p); vline.destroy(p);

    p.cursorMoveYX(5, 5);
    p.roundedBox(0, 0, 10, 10, 0);

    p.cursorMoveYX(5, 50);
    p.putStr('\u5f62'); // (形)
    final cx = Cell.init();
    p.atYXcell(5, 50, cx);
    p.cursorMoveYX(5, 30);

    p.roundedBoxSized(0, 0, 10, 10, 0);

    final gcluster = p.extendedGcluster(cx);
    stderr.writeln(gcluster);
    assert(gcluster == '形');

    nc.render();
    nc.getBlocking();

  } finally {
    nc.stop();
  }
}
