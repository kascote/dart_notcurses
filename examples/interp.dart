import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:dart_notcurses/dart_notcurses.dart';

int main() {
  final nc = NotCurses();
  if (nc.notInitialized) {
    stderr.writeln('can not intialize notcurses');
    return -1;
  }

  final std = nc.stdplane();
  final geom = std.pixelGeom(celldimy: true, celldimx: true);
  interp(nc, geom);

  nc.stop();
  return 0;
}

bool interp(NotCurses nc, NcPixelGeomData geom) {
  final rnd = Random();
  final std = nc.stdplane();
  final rows = 6;
  final cols = 12;
  std.putStrYX(0, 0, 'cellpix: ${geom.celldimy}/${geom.celldimx}');
  std.putStrYX(10, 0, 'press any key to continue');

  final rands = geom.celldimy * geom.celldimx * 3;
  final randrgb = Uint8List(rands);

  for (var r = 0; r < rands; ++r) {
    randrgb[r] = rnd.nextInt(255);
  }

  var ncv = Visual.fromRgbPacked(randrgb, geom.celldimy, geom.celldimx * 3, geom.celldimx, 0xff);
  if (ncv.notInitialized) {
    stderr.writeln('can not initialize visual from rgb');
    return false;
  }

  final vopts = VisualOptions(
    plane: std,
    y: 1,
    blitter: Blitter.pixel,
    flags: VisualOptionFlags.childplane | VisualOptionFlags.nodegrade,
  );

  final ncvp = ncv.blit(nc, vopts);
  if (ncvp == null) {
    stderr.writeln('can not blit visual');
    ncv.destroy();
    return false;
  }

  var leftMargin = 1;
  final scalep = std.create(PlaneOptions(y: 3, x: leftMargin, rows: rows, cols: cols));
  vopts.y = 0;
  vopts.plane = scalep;
  vopts.scaling = Scale.stretch;

  final blitScale = ncv.blit(nc, vopts);
  if (blitScale == null) {
    stderr.writeln('can not blit scale');
    scalep!.destroy();
    ncvp.destroy();
    ncv.destroy();
    return false;
  }

  std.putStrYX(2, 4, 'scale');
  leftMargin += scalep!.dimx() + 1;
  final scalepni = std.create(PlaneOptions(y: 3, x: leftMargin, rows: rows, cols: cols));
  vopts.plane = scalepni;
  vopts.flags = VisualOptionFlags.nointerpolate;

  final blitScaleNo = ncv.blit(nc, vopts);
  if (blitScaleNo == null) {
    stderr.writeln('can not blit scale no');
    blitScale.destroy();
    scalep.destroy();
    scalepni!.destroy();
    ncvp.destroy();
    ncv.destroy();
    return false;
  }

  std.putStrYX(2, 15, 'scale(no)');
  leftMargin += scalepni!.dimx() + 1;
  final resizep = std.create(PlaneOptions(y: 3, x: leftMargin, rows: rows, cols: cols));
  if (resizep == null) {
    stderr.writeln('can not create resized plane');
    blitScale.destroy();
    blitScaleNo.destroy();
    scalep.destroy();
    scalepni.destroy();
    ncvp.destroy();
    ncv.destroy();
    return false;
  }

  if (!ncv.resize(rows * geom.celldimy, cols * geom.celldimx)) {
    stderr.writeln('can not resize plane');
    blitScale.destroy();
    blitScaleNo.destroy();
    scalep.destroy();
    scalepni.destroy();
    ncvp.destroy();
    ncv.destroy();
    return false;
  }

  vopts.flags = 0;
  vopts.plane = resizep;
  vopts.scaling = Scale.none;
  final blitResize = ncv.blit(nc, vopts);
  if (blitResize == null) {
    stderr.writeln('can not blit resize');
    blitScale.destroy();
    blitScaleNo.destroy();
    scalep.destroy();
    scalepni.destroy();
    ncvp.destroy();
    ncv.destroy();
    return false;
  }
  std.putStrYX(2, 30, 'resize');

  ncv.destroy();
  ncv = Visual.fromRgbPacked(randrgb, geom.celldimy, geom.celldimx * 3, geom.celldimx, 0xff);
  leftMargin += scalepni.dimx() + 1;

  final inflatep = std.create(PlaneOptions(y: 3, x: leftMargin, rows: rows, cols: cols));
  if (inflatep == null) {
    stderr.writeln('can not create resized plane 2');
    blitScale.destroy();
    blitScaleNo.destroy();
    blitResize.destroy();
    scalep.destroy();
    ncvp.destroy();
    ncv.destroy();
    return false;
  }
  vopts.plane = inflatep;
  if (!ncv.reisizeNonInterpolative(rows * geom.celldimy, cols * geom.celldimx)) {
    stderr.writeln('can not resize non interpolative');
    blitScale.destroy();
    blitScaleNo.destroy();
    blitResize.destroy();
    scalep.destroy();
    ncvp.destroy();
    ncv.destroy();
    return false;
  }

  final blitResizeNo = ncv.blit(nc, vopts);
  if (blitResizeNo == null) {
    stderr.writeln('can not blit resize no');
    blitScale.destroy();
    blitScaleNo.destroy();
    blitResize.destroy();
    scalep.destroy();
    ncvp.destroy();
    ncv.destroy();
    return false;
  }

  std.putStrYX(2, 41, 'resize(no)');

  nc.render();

  final k = nc.getBlocking();
  k.value!.destroy();

  ncv.destroy();
  ncvp.destroy();
  blitScale.destroy();
  blitScaleNo.destroy();
  blitResize.destroy();
  blitResizeNo.destroy();
  scalep.destroy();

  return true;
}
