import 'dart:io';
import 'dart:math';
import 'package:dart_notcurses/dart_notcurses.dart';

const int max_rand = 0x7ffff;

int main(List<String> args) {
  var rc = 0;
  NotCurses? nc;

  try {
    if (args.isEmpty) {
      print('pixel: need an image file name');
      return -1;
    }

    nc = NotCurses(CursesOptions(
      marginT: 2,
      marginR: 2,
      marginB: 2,
      marginL: 2,
      flags: NcDirectOptions.inhibitSetlocale,
    ));

    if (nc.checkPixelSupport() <= 0) {
      print('pixel graphics not supported');
      rc = -1;
    }
    rc = handle(nc, args[0]);
  } catch (e, s) {
    if (nc != null) nc.stop();
    print(e);
    print(s);
    rc = -1;
  } finally {
    if (nc != null) nc.stop();
    rc = 0;
  }

  return rc;
}

int handle(NotCurses nc, String fname) {
  final rnd = Random();
  final visual = Visual.fromFile(fname);
  if (visual.notInitialized) {
    return -1;
  }

  final std = nc.stdplane();
  final dim = std.dimyx();

  for (var y = 0; y < dim.y; y += 15) {
    for (var x = 0; x < dim.x; x += 15) {
      var channels = Channels.initializer(
        rnd.nextInt(max_rand) % 256,
        rnd.nextInt(max_rand) % 256,
        100,
        rnd.nextInt(max_rand) % 256,
        100,
        140,
      );
      std.setBase('a', 0, channels);

      final vopts = VisualOptions(
        plane: std,
        y: y,
        x: x,
        scaling: NcScaleE.noneHires,
        blitter: NcBlitterE.pixel,
        flags: NcVisualOptFlags.childplane | NcVisualOptFlags.nodegrade,
      );

      final nv = visual.blit(nc, vopts);
      if (!nv.result) {
        visual.destroy();
        return -1;
      }

      nc.render();
      sleep(Duration(milliseconds: 500));
      channels = Channels.initializer(
        rnd.nextInt(max_rand) % 256,
        rnd.nextInt(max_rand) % 256,
        100,
        rnd.nextInt(max_rand) % 256,
        100,
        140,
      );
      std.setBase('a', 0, channels);
      nc.render();
      sleep(Duration(milliseconds: 500));
      nv.value!.destroy();
    }
  }

  return 0;
}
