import 'package:dart_notcurses/dart_notcurses.dart';

int main() {
  final nc = Direct.core(flags: NcDirectOptions.drainInput);

  try {
    for (int i = 1; i < 15; ++i) {
      final c1 = Channels.zero()..setFgRGB8(0x0, 0x10 * i, 0xff);
      final c2 = Channels.zero()..setFgRGB8(0x10 * i, 0x0, 0x0);
      if (nc.hlineInterp('-', i, c1, c2) < i) {
        return -1;
      }
      nc.setFgDefault();
      nc.setBgDefault();
      nc.putStr('\n');
    }

    for (int i = 1; i < 15; ++i) {
      final c1 = Channels.zero()..setFgRGB8(0x0, 0x10 * i, 0xff);
      final c2 = Channels.zero()..setFgRGB8(0x10 * i, 0x0, 0x0);
      if (nc.vlineInterp('|', i, c1, c2) < i) {
        return -1;
      }
      nc.setFgDefault();
      nc.setBgDefault();

      if (i < 14) {
        if (!nc.cursorUp(i)) {
          return -1;
        }
      }
    }
    nc.putStr('\n');
    final ul = Channels.zero()..setFgRGB8(0xff, 0x0, 0xff);
    final ur = Channels.zero()..setFgRGB8(0x0, 0xff, 0x0);
    final ll = Channels.zero()..setFgRGB8(0x0, 0x0, 0xff);
    final lr = Channels.zero()..setFgRGB8(0xff, 0x0, 0x0);

    if (!nc.roundedBox(ul, ur, ll, lr, ylen: 10, xlen: 10)) {
      return -1;
    }
    nc.cursorUp(9);
    if (!nc.doubleBox(ul, ur, ll, lr, ylen: 10, xlen: 20)) {
      return -1;
    }

    nc.putStr('\n');
  } catch (e, stackTrace) {
    print(e);
    print(stackTrace);
  } finally {
    nc.stop();
  }

  return 0;
}
