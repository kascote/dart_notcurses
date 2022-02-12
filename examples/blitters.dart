import 'dart:io';
import 'package:dart_notcurses/dart_notcurses.dart';

int main(List<String> args) {
  final opts = CursesOptions(loglevel: NcLogLevel.trace, flags: NcOptions.drainInput | NcOptions.noAlternateScreen);
  final notc = NotCurses(opts);

  if (!notc.initialized()) {
    stderr.writeln('errir initializing notcurses');
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
    NcBlitterE.defaultt,
    NcBlitterE.blit_1x1,
    NcBlitterE.blit_2x1,
    NcBlitterE.blit_2x2,
    NcBlitterE.blit_3x2,
    NcBlitterE.braille,
    NcBlitterE.pixel,
  ];

  for (var i = 0; i < blitters.length; ++i) {
    final blitter = blitters[i];

    for (int scaling = NcScaleE.none; scaling <= NcScale.stretch; ++scaling) {
      for (int i = 0; i < args.length; ++i) {
        std.erase();
        final fname = args[i];
        stderr.writeln('--- load file');
        final ncv = Visual.fromFile(fname);
        if (!ncv.initialized()) {
          stderr.writeln('ERROR: creating visual');
          return -1;
        }
        notc.render();
        final vopts = VisualOptions(
          plane: std,
          blitter: blitter,
          scaling: scaling,
          flags: NcVisualOptFlags.childplane,
        );

        stderr.writeln('--- blit $blitter $scaling ${i+1}');
        final cn = ncv.blit(notc, vopts);
        if (!cn.result) {
          ncv.destroy();
          stderr.writeln('ERROR: creating blitting visual');
          return -1;
        }

        stderr.writeln('--- render');
        notc.render();
        sleep(Duration(milliseconds: 500));

        stderr.writeln('--- destroy 1');
        cn.value!.destroy();
        stderr.writeln('--- destroy 2');
        ncv.destroy();
      }
    }
  }

  return 0;
}
