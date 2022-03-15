import 'dart:io';

import 'package:dart_notcurses/dart_notcurses.dart';

void main() {
  final nc = NotCurses(CursesOptions(
    marginT: 2,
    marginL: 2,
    marginR: 2,
    marginB: 2,
    loglevel: LogLevel.error,
  ));

  if (nc.notInitialized) {
    stderr.writeln('error initializing nocurses');
    return;
  }

  final p = nc.stdplane();

  try {
    p.cursorMoveYX(2, 2);
    // draw a horizontal line using an scorpion emoji
    final c1 = p.primeCell('\u{1F982}');
    if (c1.result < 0) {
      stderr.writeln('error creating cell1');
    } else {
      final x = c1.value!;
      p.hline(x, 10);
      x.destroy(p);
    }
    //---

    // draw a vertical line using ascii
    final c2 = p.primeCell('|');
    if (c2.result < 0) {
      stderr.writeln('error creating cell2');
    } else {
      final x = c2.value!;
      p.vline(x, 10);
      x.destroy(p);
    }
    //---

    // draw a box and a perimeter around the termninal using
    // loaded cells with custom colors and interpolating the colors
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

    p.cursorMoveYX(10, 10);
    p.box(
      ul,
      ur,
      ll,
      lr,
      hline,
      vline,
      30,
      30,
      BoxFlags.gradTop | BoxFlags.gradBottom | BoxFlags.gradRight | BoxFlags.gradLeft,
    );
    p.perimeter(
      ul,
      ur,
      ll,
      lr,
      hline,
      vline,
      BoxFlags.gradTop | BoxFlags.gradBottom | BoxFlags.gradRight | BoxFlags.gradLeft,
    );

    ul.destroy(p);
    ur.destroy(p);
    ll.destroy(p);
    lr.destroy(p);
    hline.destroy(p);
    vline.destroy(p);
    //---

    // draw a rounded box at 5,5 with default styles and channels colors
    p.cursorMoveYX(5, 5);
    p.roundedBox(10, 10);
    //---

    // write a character and read it later
    p.cursorMoveYX(5, 50);
    p.putStr('\u5f62'); // (形)
    final cx = Cell.init();
    p.atYXcell(5, 50, cx);
    p.cursorMoveYX(5, 30);
    final gcluster = p.extendedGcluster(cx);
    stderr.writeln(gcluster);
    assert(gcluster == '形');
    //---

    nc.render();
    shine(nc, p);
    nc.getBlocking();
  } finally {
    nc.stop();
  }
}

void shine(NotCurses nc, Plane p) {
  final ul = p.loadCell('╔').value!
    ..setFgRGB(0xffffff)
    ..setBgRGB(0x080808);

  final ur = p.loadCell('╗').value!
    ..setFgRGB(0x444444)
    ..setBgRGB(0x080808);

  final ll = p.loadCell('╚').value!
    ..setFgRGB(0x444444)
    ..setBgRGB(0x080808);

  final lr = p.loadCell('╝').value!
    ..setFgRGB(0x444444)
    ..setBgRGB(0x080808);

  final hline = p.loadCell('═').value!;
  final vline = p.loadCell('║').value!;

  final steps = [
    [ul, ur],
    [ur, lr],
    [lr, ll],
    [ll, ul],
  ];
  var done = false;

  while (!done) {
    for (final step in steps) {
      for (var x = 0x000000; x <= 0xbbbbbb; x += 0x111111) {
        step[0].setFgRGB(0xffffff - x);
        step[1].setFgRGB(0x444444 + x);

        p.cursorMoveYX(10, 35);
        p.boxSized(
          steps[0][0],
          steps[1][0],
          steps[2][1],
          steps[2][0],
          hline,
          vline,
          10,
          20,
          BoxFlags.gradTop | BoxFlags.gradBottom | BoxFlags.gradRight | BoxFlags.gradLeft,
        );

        nc.render();
        sleep(Duration(milliseconds: 50));
        final k = nc.getNonBlocking(keyInfo: false);
        if (k.result != 0) {
          done = true;
          break;
        }
      }
      if (done) break;
    }
  }

  ul.destroy(p);
  ur.destroy(p);
  ll.destroy(p);
  lr.destroy(p);
  hline.destroy(p);
  vline.destroy(p);
}
