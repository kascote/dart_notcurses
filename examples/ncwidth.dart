import 'dart:io';

import 'package:characters/characters.dart';
import 'package:dart_notcurses/dart_notcurses.dart';

int main(List<String> args) {
  if (args.isEmpty) {
    print('ncwidth [string]');
    print('\tshow character information about the string passed');
    return -1;
  }

  final nc = Direct.core(flags: NcDirectOptions.verbose);

  try {
    var totalCols = 0;
    var totalBytes = 0;
    final characters = args[0].characters;
    var i = 0;
    for (final chr in characters) {
      final code = chr.runes.elementAt(0);
      final hex = code.toStrHex(padding: 4);
      final width = chr.characters.length;
      final bytes = chr.runes.length;
      nc.putStr('$hex $width ${String.fromCharCode(code)}\t', 0);
      if (++i % 4 == 0) {
        nc.putStr('\n', 0);
      }
      totalCols += width;
      totalBytes += bytes;
    }
    nc.putStr('\n', 0);
    var origDim = nc.cursorYX();
    if (origDim == null) {
      return -1;
    }
    stdout.write(args[0]);
    final finalDim = nc.cursorYX();
    if (finalDim == null) {
      return -1;
    }
    final realcols = (finalDim.x - origDim.x) + nc.dimx() * (finalDim.y - origDim.y);
    nc.putStr(
        '\niterated wcwidth: $totalCols total bytes: $totalBytes wcswidth: ${characters.length} true width: $realcols\n\n',
        0);

    // throw up a background color for invisible glyphs
    origDim = nc.cursorYX();
    if (origDim == null) return -1;
    final chan = Channels.initializer(0xff, 0xff, 0xff, 0, 0x80, 0);
    var scrolls = 0, newscrolls = 0;
    final arg = args[0].characters;
    for (var i = 0; i < arg.length; i++) {
      final cols = nc.putEgc(arg.elementAt(i), chan);
      if (cols.result < 0) {
        break;
      }
      /* stdout.flush(); */

      var newyx = nc.cursorYX();
      if (newyx == null) break;

      if (newyx.y != origDim!.y) {
        newyx = newyx.copyWith(x: newyx.x + nc.dimx() * (newyx.y - origDim.y));
      }
      if ((origDim.x + cols.result) != newyx.x) {
        newscrolls = 0;
        ++scrolls;
        for (int k = 0; k < scrolls; ++k) {
          if (newyx!.y >= nc.dimy()) {
            ++newscrolls;
            stdout.write('\v');
          } else {
            nc.cursorDown();
            newyx = newyx.copyWith(y: newyx.y + 1);
          }
        }

        stdout.write('True width: ${newyx!.x - origDim.x} wcwidth: ${cols.result} [${cols.value}]');
        nc.cursorMoveYX(newyx.y - newscrolls, newyx.x);
      }

      origDim = newyx.copyWith(y: newyx.y + newscrolls, x: newyx.x);
    }
    for (i = 0; i < scrolls + 1; ++i) {
      nc.putStr('\n', 0);
    }

    nc.setFgDefault();
    nc.setBgDefault();

    for (var z = 0; z < realcols && z < nc.dimx(); ++z) {
      nc.putStr('${z % 10}', 0);
    }
    if (realcols < nc.dimx()) {
      nc.putStr('\n', 0);
    }
    if (realcols > 20) {
      for (var z = 0; z < realcols && z < nc.dimx(); ++z) {
        if (z % 10 == 0) {
          stdout.write(' ');
        } else {
          stdout.write(z / 10);
        }
        stdout.write('\n');
      }
    }
  } catch (e, stackTrace) {
    print(e);
    print(stackTrace);
  } finally {
    nc.stop();
  }

  return 0;
}
