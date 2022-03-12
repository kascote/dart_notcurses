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
    final pInput = p.create(
      y: 10,
      x: 10,
      rows: 1,
      cols: 30,
      name: 'input1',
      flags: NcPlaneOptionFlags.fixed,
    );
    if (pInput == null) {
      stderr.writeln('error creating input plane');
    }
    /* pInput!.perimeterDouble(0, 0, 16 | 64 | 32 | 128); */
    pInput!.setBase('░', 0, Channels.initializerBg(0xaa, 0x44, 0x44)); // #aa4444

    final opts = ReaderOptions(
      Channels.initializerFg(0xcc, 0xaa, 0xff), // #ccaaff
      NcStyle.italic,
      NcReaderOptions.cursor | NcReaderOptions.horscroll,
    );
    final reader = Reader.create(pInput, opts);

    if (!nc.render()) {
      stderr.writeln('error rendering');
      nc.stop();
      return;
    }

    showCursorPos(reader, p);

    while (true) {
      final k = nc.getBlocking();
      if (k.result < 0) {
        break;
      }
      final key = k.value!;
      // CTRL+D exit
      if (key.hasCtrl(68)) {
        key.destroy();
        break;
      }
      reader.offerInput(key);
      showCursorPos(reader, p);

      if (!nc.render()) {
        key.destroy();
        stderr.writeln('error rendering');
        break;
      }
    }

    stderr.writeln(reader.contents());

    reader.destroy();
  } finally {
    nc.stop();
  }
}

void showCursorPos(Reader reader, Plane p) {
  final rPlane = reader.readerPlane();
  final rplaneDim = rPlane.dimyx();
  final tplane = rPlane.above();
  final tplaneDim = tplane!.dimyx();
  final cursor = rPlane.cursorYX();

  p.putStrYX(0, 0,
      'Cursor ${cursor.y}/${cursor.x} ViewGeom ${rplaneDim.y}/${rplaneDim.x} TextGeom ${tplaneDim.y}/${tplaneDim.x}');
}
