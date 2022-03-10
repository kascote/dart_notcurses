import 'dart:async';
import 'dart:io';

import 'package:dart_notcurses/dart_notcurses.dart';

// ignore: constant_identifier_names
const MILISECS_IN_SEC = 1000;
var done = false;
var start = DateTime.now().millisecondsSinceEpoch;
var mux = false;
var y = 0;

Future<void> main() async {
  final nc = NotCurses(CursesOptions(
    marginT: 2,
    marginL: 2,
    marginR: 2,
    marginB: 2,
    loglevel: NcLogLevel.error,
    flags: NcOptions.inhibitSetlocale,
  ));

  if (nc.notInitialized) {
    stderr.writeln('error initializing nocurses');
    return;
  }

  nc.miceEnable(NcMiceEvents.allEvents);

  final stdPlane = setupPlane(nc);
  if (stdPlane == null) {
    return;
  }
  final plot = setupPlotPlane(stdPlane);
  if (plot == null) {
    return;
  }

  Timer.periodic(Duration(milliseconds: 150), (Timer t) {
    if (done) {
      t.cancel();
    } else {
      if (!mux) {
        final sec = ((DateTime.now().millisecondsSinceEpoch - start) / 1000).floor();
        mux = true;
        plot.addSample(sec, 0);
        nc.render();
        mux = false;
      }
    }
  });

  // this will not work with screen resize
  final dim = stdPlane.dimyx();

  try {
    Future.doWhile(() {
      final res = nc.getNonBlocking();
      if (res.result < 0) {
        stderr.writeln('can not get input from keyboard');
        return false;
      }
      final key = res.value!;

      // getNonBlocking returned with no value
      if (key.id == 0) {
        key.destroy();
        // needed for event loop to not stuck. there is another way ?
        return Future.delayed(Duration(), () => true);
      }

      // CTRL+D exit app
      if (key.hasCtrl(68)) {
        key.destroy();
        return false;
      }

      clearEOL(stdPlane);
      keyHandler(stdPlane, key);
      if (!dimRows(stdPlane, dim)) return false;

      // add sample to Plot
      final sec = ((DateTime.now().millisecondsSinceEpoch - start) / 1000).floor();
      if (!mux) {
        mux = true;
        plot.addSample(sec, 1);
        mux = false;
      }

      // render and update next row to paint
      if (!nc.render()) return false;
      if (++y >= dim.y) y = 0;

      key.destroy();
      // continue event loop
      return Future.delayed(Duration(), () => true);
    }).then((dynamic _) {
      done = true;
      plot.destroy();
      nc.stop();
      return true;
    });
  } catch (e) {
    stderr.writeln(e);
    nc.stop();
  }
}

void clearEOL(Plane stdPlane) {
  final cPos = stdPlane.cursorYX();
  final d = stdPlane.dimyx();
  for (var i = cPos.x; i < d.x; ++i) {
    stdPlane.putChar(' ');
  }
}

Plane? setupPlane(NotCurses n) {
  final stdPlane = n.stdplane();
  final dim = stdPlane.dimyx();

  stdPlane.setFgRGB8(0, 0, 0);
  stdPlane.setBgRGB8(0xbb, 0x64, 0xbb); // #bb64bb
  stdPlane.stylesOn(NcStyle.underline);

  if (stdPlane.putStrAligned(dim.y - 1, NcAlignE.center, 'mash keys, yo. give that mouse some waggle! ctrl+d exits.') <
      0) {
    stderr.writeln('error writting to screen');
    return null;
  }

  stdPlane.setStyles(NcStyle.none);
  stdPlane.setBgDefault();
  if (!n.render()) {
    stderr.writeln('error rendering');
    return null;
  }

  return stdPlane;
}

Plot? setupPlotPlane(Plane stdPlane) {
  const plotHeight = 6;
  const plotWidth = 56;
  final dim = stdPlane.dimyx();

  final pplane = stdPlane.create(
    y: dim.y - plotHeight - 1,
    x: NcAlignE.center,
    rows: plotHeight,
    cols: plotWidth,
    name: 'plot',
    flags: NcPlaneOptionFlags.horaligned,
    marginB: 0,
    marginR: 0,
  );

  if (pplane == null) {
    stderr.writeln('error creating plane');
    return null;
  }

  final minc = Channels.setFgRGB8(0, 0x40, 0x50, 0xb0); // #4050b0
  final maxc = Channels.setFgRGB8(0, 0x40, 0xff, 0xd0); // #40ffd0
  final plot = Plot.create(
      pplane,
      PlotOptions(
        miny: 0,
        maxy: 0,
        minchannels: minc.result ? minc.value : 0,
        maxchannels: maxc.result ? maxc.value : 0,
        gridtype: NcBlitterE.pixel,
        flags: NcPlotOptionsFlags.labelTickSD | NcPlotOptionsFlags.printSample,
      ));
  if (plot == null) {
    stderr.writeln('error creating plot');
    return null;
  }

  return plot;
}

void keyHandler(Plane stdPlane, Key key) {
  if (!stdPlane.cursorMoveYX(y, 0)) {
    stderr.writeln('can not move cursor to $y,0');
    return;
  }

  stdPlane.setFgRGB8(0xd0, 0xd0, 0xd0); // #d0d0d0

  final keys = StringBuffer();
  keys.write(key.hasShift() ? 'S' : 's');
  keys.write(key.hasAlt() ? 'A' : 'a');
  keys.write(key.hasCtrl() ? 'C' : 'c');
  keys.write(key.hasSuper() ? 'U' : 'u');
  keys.write(key.hasHyper() ? 'H' : 'h');
  keys.write(key.hasMeta() ? 'M' : 'm');
  keys.write(key.hasCapslock() ? 'X' : 'x');
  keys.write(key.hasNumlock() ? '#' : '.');
  keys.write(evTypeToChar(key));
  keys.write(' ');

  stdPlane.putStr(keys.toString());

  if (key.id < 0x80) {
    stdPlane.setFgRGB8(0x80, 0xfa, 0x40); // #80fa40
    if (stdPlane.putStr("ASCII: [${key.id.toStrHex(padding: 4)} (${key.id})] '${key.keyStr}'") < 0) return;
  } else {
    if (key.keySynthesizedP()) {
      stdPlane.setFgRGB8(0xfa, 0x40, 0x80); // #fa4080
      if (stdPlane.putStr("Special: [${key.id.toStrHex(padding: 4)} (${key.id})] '${ncKeyStr(key.id)}'") < 0) return;

      if (key.keyMouseP()) {
        if (stdPlane.putStrAligned(-1, NcAlignE.right, ' x: ${key.x} y: ${key.y}') < 0) return;
      }
    } else {
      stdPlane.setFgRGB8(0x40, 0x80, 0xfa); // #4080fa
      stdPlane.putStr("Unicode: [${key.id.toStrHex(padding: 3)}] '${key.utf8List}'");
    }
  }
}

String evTypeToChar(Key k) {
  switch (k.evType) {
    case NcEventType.unknown:
      return 'u';
    case NcEventType.press:
      return 'P';
    case NcEventType.repeat:
      return 'R';
    case NcEventType.release:
      return 'L';
  }
  return 'X';
}

// Dim all text on the plane by the same amount. This will stack for
// older text, and thus clearly indicate the current output.
bool dimRows(Plane n, Dimensions dim) {
  final c = Cell.init();
  for (int y = 0; y < dim.y; ++y) {
    for (int x = 0; x < dim.x; ++x) {
      if (n.atYXcell(y, x, c) < 0) {
        n.releaseCell(c);
        c.destroy(null);
        return false;
      }

      final _rgb = c.fgRGB8();
      final r = _rgb.r - (_rgb.r / 32).floor();
      final g = _rgb.g - (_rgb.g / 32).floor();
      final b = _rgb.b - (_rgb.b / 32).floor();
      final rgb = RGB(
        r > 247 ? 0 : r,
        g > 247 ? 0 : g,
        b > 247 ? 0 : b,
      );

      if (!c.setFgRGB8(rgb)) {
        n.releaseCell(c);
        c.destroy(null);
        return false;
      }
      if (n.putcYX(y, x, c) < 0) {
        n.releaseCell(c);
        c.destroy(null);
        return false;
      }
      if (c.isDoubleWideP()) {
        ++x;
      }
      n.releaseCell(c);
    }
  }
  c.destroy(null);
  return true;
}
