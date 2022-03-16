import 'package:dart_notcurses/dart_notcurses.dart';

void main() {
  final nc = Direct.core();
  if (!nc.initialized) {
    return;
  }

  final canUtf8 = nc.canUtf8();
  final ok = '✅';
  final no = '❌';
  final defaultChannel = Channels.defaultColors();
  final okChannel = defaultChannel.copy()..setFgRGB(0x00ff00);
  final noChannel = defaultChannel.copy()..setFgRGB(0xff0000);

  final capabilities = {
    'Utf8': canUtf8,
    'True Color': nc.canTrueColor(),
    'Change Color': nc.canChangeColor(),
    'Fade': nc.canFade(),
    'Open Images': nc.canOpenImages(),
    'Open Videos': nc.canOpenVideos(),
    'Pixel Support': nc.checkPixelSupport(),
    'Half Block': nc.canHalfBlock(),
    'Quadrant': nc.canQuadrant(),
    'Sextant': nc.canSextant(),
    'Braile': nc.canBraile(),
    'GetCursor': nc.canGetCursor(),
  };

  void pLabel(String value) {
    nc.putStr(value.padRight(15), defaultChannel);
  }

  void pCap(bool value) {
    if (canUtf8) {
      nc.putEgc(value ? ok : no);
    } else {
      nc.putStr(value ? 'true' : 'false', value ? okChannel : noChannel);
    }
  }

  pLabel('Terminal: ');
  nc.putStr('${nc.detectTerminal() ?? ''}\n');

  final labels = capabilities.keys;
  for (final label in labels) {
    pLabel('$label: ');
    pCap(capabilities[label]!);
    nc.putStr('\n');
  }

  nc.stop();
}
