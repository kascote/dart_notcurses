import 'dart:ffi' as ffi;
import 'dart:io';
import 'dart:typed_data';

import 'package:dart_notcurses/dart_notcurses.dart';

// ignore: constant_identifier_names
const INT_MAX = 2147483647;
// ignore: non_constant_identifier_names
final U32_SIZE = ffi.sizeOf<ffi.Uint32>();
const pause = 1;

int main() {
  final opts = CursesOptions(loglevel: NcLogLevel.trace, flags: NcOptions.drainInput);
  final notc = NotCurses.core(opts);

  final x = notc.checkPixelSupport();
  if (x < 1) {
    print('no pixel support');
    notc.stop();
    return -1;
  }

  int rc;
  try {
    rc = wipebitmap(notc);
  } catch (e) {
    notc.stop();
    rethrow;
  }

  notc.stop();
  return rc;
}

int wipebitmap(NotCurses notc) {
  final p = notc.stdplane();
  final geom = p.pixelGeom(celldimy: true, celldimx: true);
  final cols = geom.celldimx * 6;
  final rows = geom.celldimy * 6;
  final pixLen = cols * rows * U32_SIZE;
  final i8 = Uint8List(pixLen);
  i8.fillRange(0, pixLen, 0xff);

  final ncv = Visual.fromRGBA(i8, rows, cols * 4, cols);

  if (ncv.notInitialized) {
    return -1;
  }

  final vopts = VisualOptions(
    blitter: NcBlitterE.pixel,
    plane: p,
    flags: NcVisualOptFlags.childplane,
  );

  final pBlit = ncv.blit(notc, vopts);
  if (!pBlit.result) {
    ncv.destroy();
    return -1;
  }

  emit(p, 'Ought see full square');

  if (!notc.render()) {
    ncv.destroy();
    pBlit.value!.destroy();
    return -1;
  }

  sleep(Duration(seconds: pause));

  // -------------------------------------------------------------------

  p.erase();

  for (var y = 1; y < 5; y++) {
    for (var x = 1; x < 5; x++) {
      p.putCharYX(y, x, '*');
    }
  }

  final channels = Channels.zero()
    ..setBgAlpha(NcAlpha.transparent)
    ..setFgAlpha(NcAlpha.transparent);

  p.setBase('', 0, channels);
  p.moveTop();

  emit(p, 'Ought see 16 *s');
  if (!notc.render()) {
    ncv.destroy();
    return -1;
  }

  sleep(Duration(seconds: pause));

  // -------------------------------------------------------------------

  p.erase();

  emit(p, 'Ought see full square');
  if (!notc.render()) {
    ncv.destroy();
    return -1;
  }
  sleep(Duration(seconds: pause));

  // -------------------------------------------------------------------

  p.erase();

  for (var y = 1; y < 5; y++) {
    for (var x = 1; x < 5; x++) {
      p.putCharYX(y, x, ' ');
    }
  }

  emit(p, 'Ought see 16 spaces');
  if (!notc.render()) {
    ncv.destroy();
    return -1;
  }
  sleep(Duration(seconds: pause));

  // -------------------------------------------------------------------

  p.erase();
  pBlit.value!.destroy();

  emit(p, 'Ought see nothing');
  if (!notc.render()) {
    ncv.destroy();
    return -1;
  }
  sleep(Duration(seconds: pause));

  // -------------------------------------------------------------------

  p.erase();

  for (var i = geom.celldimy; i < 5 * geom.celldimy; ++i) {
    final start = (i * 6 * geom.celldimx * U32_SIZE) + (geom.celldimx * U32_SIZE);
    final end = start + (geom.celldimx * 4 * U32_SIZE);
    i8.fillRange(start, end + 1, 0);
  }

  final ncve = Visual.fromRGBA(i8, rows, cols * 4, cols);
  if (ncve.notInitialized) {
    ncv.destroy();
    return -1;
  }

  final sBlit = ncve.blit(notc, vopts);
  if (!sBlit.result) {
    ncv.destroy();
    ncve.destroy();
    return -1;
  }

  emit(p, 'Ought see empty square');
  if (!notc.render()) {
    sBlit.value!.destroy();
    ncv.destroy();
    ncve.destroy();
    return -1;
  }
  sleep(Duration(seconds: pause));

  // -------------------------------------------------------------------

  vopts.plane = sBlit.value;
  p.moveTop();

  final rBlit = ncv.blit(notc, vopts);
  if (!rBlit.result) {
    sBlit.value!.destroy();
    ncv.destroy();
    ncve.destroy();
    return -1;
  }

  emit(p, 'Ought see full square');
  if (!notc.render()) {
    sBlit.value!.destroy();
    rBlit.value!.destroy();
    ncv.destroy();
    ncve.destroy();
    return -1;
  }
  sleep(Duration(seconds: pause));

  // -------------------------------------------------------------------

  for (var y = 1; y < 5; y++) {
    for (var x = 1; x < 5; x++) {
      p.putCharYX(y, x, '*');
    }
  }

  emit(p, 'Ought see 16 *s');
  if (!notc.render()) {
    sBlit.value!.destroy();
    rBlit.value!.destroy();
    ncv.destroy();
    ncve.destroy();
    return -1;
  }
  sleep(Duration(seconds: pause));

  // -------------------------------------------------------------------

  final zPlane = ncv.blit(notc, vopts);
  if (!zPlane.result) {
    sBlit.value!.destroy();
    rBlit.value!.destroy();
    ncv.destroy();
    ncve.destroy();
  }

  emit(p, 'Ought *still* see 16 *s');
  notc.render();
  sleep(Duration(seconds: pause));

  // -------------------------------------------------------------------

  sBlit.value!.moveYX(0, 7);
  emit(p, 'Full square on right');
  notc.render();
  sleep(Duration(seconds: pause));

  // -------------------------------------------------------------------

  sBlit.value!.moveYX(0, 0);
  emit(p, 'Ought see 16 *s');
  notc.render();
  sleep(Duration(seconds: pause));

  // -------------------------------------------------------------------

  sBlit.value!.moveYX(0, 7);
  emit(p, 'Full square on right');
  notc.render();
  sleep(Duration(seconds: pause));

  // -------------------------------------------------------------------

  ncve.destroy();
  ncv.destroy();
  sBlit.value!.destroy();
  rBlit.value!.destroy();
  zPlane.value!.destroy();
  return 0;
}

void emit(Plane p, String value) {
  p.eraseRegion(6, 0, INT_MAX, 0);
  p.putStrYX(6, 0, value);
}
