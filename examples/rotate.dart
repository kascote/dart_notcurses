import 'dart:io';
import 'package:dart_notcurses/dart_notcurses.dart';

const int max_rand = 0x7ffff;
const double M_PI = 3.141592653589793115997963468544185161590576171875;

int main(List<String> args) {
  var rc = 0;
  NotCurses? nc;

  try {
    if (args.isEmpty) {
      print('rorate: need an image file name');
      return -1;
    }

    nc = NotCurses(CursesOptions(
        marginT: 2,
        marginR: 2,
        marginB: 2,
        marginL: 2,
        flags: NcOptions.drainInput | NcOptions.noAlternateScreen | NcOptions.suppressBanners,
        loglevel: NcLogLevel.silent));

    if (nc.checkPixelSupport() <= 0) {
      print('pixel graphics not supported');
      rc = -1;
    }
    rc = handle(nc, args[0]) ? 0 : -1;
  } catch (e, s) {
    if (nc != null) nc.initialized & nc.stop();
    print(e);
    print(s);
    rc = -1;
  } finally {
    if (nc != null) nc.initialized & nc.stop();
    rc = 0;
  }

  return rc;
}

bool handle(NotCurses nc, String fname) {
  final std = nc.stdplane();
  final dim = std.dimyx();
  final n = std.dup(std);
  final visual = Visual.fromFile(fname);
  if (visual.notInitialized) {
    return false;
  }
  final vopts = VisualOptions(plane: n);
  final blt = visual.blit(nc, vopts);
  if (blt == null) {
    visual.destroy();
    return false;
  }

  nc.render();
  sleep(Duration(milliseconds: 100));
  n.erase();

  final rc = visual.geom(nc, vopts);
  if (rc == null) {
    visual.destroy();
    return false;
  }

  if (!visual.resize(dim.y * rc.scaley!, dim.x * rc.scalex!)) {
    visual.destroy();
    return false;
  }
  final blit = visual.blit(nc, vopts);
  if (blit == null) {
    visual.destroy();
    return false;
  }

  nc.render();
  sleep(Duration(milliseconds: 100));

  vopts.x = NcAlignE.center;
  vopts.y = NcAlignE.center;
  vopts.flags = NcVisualOptFlags.horaligned | NcVisualOptFlags.veraligned | NcVisualOptFlags.childplane;
  vopts.plane = nc.stdplane();
  var failed = false;
  for (double i = 0; i < 256; ++i) {
    sleep(Duration(milliseconds: 100));
    if (!visual.rotate(M_PI / ((i / 32) + 2))) {
      failed = true; // FIXME fails after a few dozen iterations
      break;
    }

    final newn = visual.blit(nc, vopts);
    if (newn == null) {
      stderr.writeln('error blit after rotate');
      failed = true;
      break;
    }

    if (!nc.render()) {
      newn.destroy();
      stderr.writeln('error render rotate');
      failed = true;
      break;
    }
    newn.destroy();
  }

  /* blit.value!.destroy(); */
  visual.destroy();

  return failed;
}
