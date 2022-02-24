import 'package:dart_notcurses/dart_notcurses.dart';

int main() {
  final nc = Direct.core(flags: NcDirectOptions.drainInput);

  try {
    for (int i = 1; i < 15; ++i) {
      final c1 = Channels.setFgRGB8(0, 0x0, 0x10 * i, 0xff);
      final c2 = Channels.setFgRGB8(0, 0x10 * i, 0x0, 0x0);
      if (!c1.result | !c2.result) {
        return -1;
      }
      if (nc.hlineInterp('-', i, c1.value, c2.value) < i) {
        return -1;
      }
      nc.setFgDefault();
      nc.setBgDefault();
      nc.putStr('\n', 0);
    }

    for (int i = 1; i < 15; ++i) {
      final c1 = Channels.setFgRGB8(0, 0x0, 0x10 * i, 0xff);
      final c2 = Channels.setFgRGB8(0, 0x10 * i, 0x0, 0x0);
      if (!c1.result | !c2.result) {
        return -1;
      }
      if (nc.vlineInterp('|', i, c1.value, c2.value) < i) {
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
    nc.putStr('\n', 0);
    final ul = Channels.setFgRGB8(0, 0xff, 0x0, 0xff);
    final ur = Channels.setFgRGB8(0, 0x0, 0xff, 0x0);
    final ll = Channels.setFgRGB8(0, 0x0, 0x0, 0xff);
    final lr = Channels.setFgRGB8(0, 0xff, 0x0, 0x0);

    if (!nc.roundedBox(ul.value, ur.value, ll.value, lr.value, 10, 10, 0)) {
      return -1;
    }
    nc.cursorUp(9);
    if (!nc.doubleBox(ul.value, ur.value, ll.value, lr.value, 10, 20, 0)) {
      return -1;
    }

    nc.putStr('\n', 0);
  } catch (e, stackTrace) {
    print(e);
    print(stackTrace);
  } finally {
    nc.stop();
  }

  return 0;
}
