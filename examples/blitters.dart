import 'dart:io';
import 'package:dart_notcurses/dart_notcurses.dart';

int main(List<String> args) {
  final opts = CursesOptions(
    loglevel: LogLevel.trace,
    flags: OptionFlags.drainInput | OptionFlags.noAlternateScreen,
  );
  final notc = NotCurses(opts);

  if (notc.notInitialized) {
    stderr.writeln('error initializing notcurses');
    return -1;
  }

  if (!notc.canPixel()) {
    stderr.writeln('pixel blitter not supported');
    return -1;
  }

  if (args.isEmpty) {
    notc.stop();
    stderr.writeln('usage: blitters file [files...]');
    return -1;
  }

  int rc;
  try {
    rc = blts(notc, args);
  } catch (e) {
    notc.stop();
    stderr.writeln(e);
    rethrow;
  }

  notc.stop();
  return rc;
}

int blts(NotCurses notc, List<String> args) {
  final std = notc.stdplane();

  final blitters = [
    Blitter.defaultt,
    Blitter.blit_1x1,
    Blitter.blit_2x1,
    Blitter.blit_2x2,
    Blitter.blit_3x2,
    Blitter.braille,
    Blitter.pixel,
  ];

  for (var i = 0; i < blitters.length; ++i) {
    final blitter = blitters[i];

    for (int scaling = Scale.none; scaling <= Scale.stretch; ++scaling) {
      for (int i = 0; i < args.length; ++i) {
        std.erase();
        final fname = args[i];
        final ncv = Visual.fromFile(fname);
        if (ncv.notInitialized) {
          stderr.writeln('ERROR: creating visual');
          return -1;
        }
        notc.render();
        final vopts = VisualOptions(
          plane: std,
          blitter: blitter,
          scaling: scaling,
          flags: VisualOptionFlags.childplane,
        );

        final cn = ncv.blit(notc, vopts);
        if (cn == null) {
          ncv.destroy();
          stderr.writeln('ERROR: creating blitting visual');
          return -1;
        }

        notc.render();
        sleep(Duration(milliseconds: 500));

        cn.destroy();
        ncv.destroy();
      }
    }
  }

  return 0;
}
