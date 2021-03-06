import 'package:characters/characters.dart';
import 'package:dart_notcurses/dart_notcurses.dart';

int main() {
  final nc = NotCurses(CursesOptions(
    flags: OptionFlags.noAlternateScreen |
        OptionFlags.preserveCursor |
        OptionFlags.noClearBitmaps |
        OptionFlags.drainInput |
        OptionFlags.suppressBanners,
  ));
  if (nc.notInitialized) return -1;

  nc.miceEnable(MiceEvents.allEvents);

  final List<String> indent = [];
  final stdn = nc.stdplane();
  if (stdn.dimx() < 80) {
    stdn
      ..setFgRGB(0xff5349)
      ..setStyles(Style.bold)
      ..putStr('This program requires at least 80 columns.\n');
    nc
      ..render()
      ..stop();
    return -1;
  }

  stdn
    ..setFgAlpha(Alpha.highcontrast)
    ..setFgRGB(0xffffff)
    ..setScrolling(true);

  finishLine(stdn);
  finishLine(stdn);
  tinfoDebugStyles(nc, stdn, indent.join());
  tinfoDebugBitmaps(nc, stdn, indent);
  unicodeDumper(nc, stdn, indent);

  if (nc.canPixel()) {
    displayLogo(nc, stdn);
  }

  nc
    ..render()
    ..stop();
  return 0;
}

void tinfoDebugStyles(NotCurses nc, Plane plane, String idt) {
  plane.putStr(idt);
  tinfoDebugStyle(plane, 'bold', Style.bold, ' ');
  tinfoDebugStyle(plane, 'ital', Style.italic, ' ');
  tinfoDebugStyle(plane, 'struck', Style.struck, ' ');
  tinfoDebugStyle(plane, 'ucurl', Style.undercurl, ' ');
  tinfoDebugStyle(plane, 'uline', Style.underline, ' ');

  finishLine(plane);
  plane.putStr(idt);
}

void tinfoDebugStyle(Plane plane, String name, int style, String char) {
  final nc = plane.notCurses();
  final support = nc.supportedStyles() & style == style;
  if (!support) plane.setStyles(Style.italic);

  plane
    ..setStyles(style)
    ..putStr(name)
    ..setStyles(Style.bold)
    ..putWc(capboolbool(nc.canUtf8(), support))
    ..setStyles(Style.none)
    ..putChar(char);
}

String capboolbool(bool utf8, bool cap) {
  return cap ? '+' : '-';
}

void finishLine(Plane plane) {
  var x = plane.cursorYX().x;
  while (x++ < 80) {
    plane.putChar(' ');
  }
  if (plane.dimx() > 80) plane.putChar('\n');
}

void tinfoDebugBitmaps(NotCurses nc, Plane plane, List<String> indent) {
  final idt = indent.join();
  final nc = plane.notCurses();
  final fg = nc.defaultForeground();
  if (fg == null) {
    plane.putStr('${idt}no know default fg ');
  } else {
    plane.putStr('${idt}default fg ${fg.toStrHex()} ');
  }

  final bg = nc.defaultBackground();
  if (bg == null) {
    plane.putStr('${idt}no know default bg ');
  } else {
    plane.putStr('${idt}default bg ${bg.toStrHex()}');
  }

  finishLine(plane);

  final blit = nc.checkPixelSupport();

  switch (PixelImple.fromValue(blit)) {
    case 'none':
      plane.putStr('${idt}no bitmap graphics detected');
      break;
    case 'sixel':
      plane.putStr('${idt}sixel - can not retrieve info yet');
      break;
    case 'linuxfb':
      plane.putStr('${idt}framebuffer graphics supported');
      break;
    case 'iTerm2':
      plane.putStr('${idt}iTerm2 graphics supported');
      break;
    case 'kittyStatic':
      plane.putStr('${idt}rgba pixel graphics support');
      break;
    case 'kittyAnimated':
      plane.putStr('${idt}1st gen rgba pixel animation support');
      break;
    case 'kittySelfref':
      plane.putStr('${idt}2nd gen rgba pixel animation support');
      break;
  }

  finishLine(plane);
}

void unicodeDumper(NotCurses nc, Plane plane, List<String> indent) {
  final idt = indent.join();
  if (!nc.canUtf8()) {
    plane.putStr('can not print utf8');
    return;
  }

  // all NCHALFBLOCKS are contained within NCQUADBLOCKS
  plane.putStr('$idt${Sequences.quadblocks}???');
  // ???????????????????????????????????????? (on Windows, these will be encoded as UTF-16 surrogate
  // pairs due to a 16-bit wchar_t.
  sexViz(plane, Sequences.sexblocks, '???', '??????${Sequences.segdigits}\u2157\u2158\u2159\u215a\u215b');
  vertViz(plane, '???', Sequences.eighthsr.characters.elementAt(0), Sequences.eighthsl[0], '???', '???????????????????????????????');
  plane.putStr('$idt????????? ?????? ?????? ?????? ?????? ???');
  sexViz(plane, Sequences.sexblocks.substring(31), '???',
      '??????\u00bc\u00bd\u00be\u2150\u2151\u2152\u2153\u2154\u2155\u2156\u215c\u215d\u215e\u215f\u2189');
  vertViz(plane, '???', Sequences.eighthsr.characters.elementAt(1), Sequences.eighthsl[1], '???', '???????????????????????????????');
  plane.putStr('$idt????????? ');
  triviz(
      plane,
      Sequences.whitesquaresw,
      Sequences.whitecirclesw,
      Sequences.diagonalsw,
      Sequences.diagonalsw.characters.skip(4).toString(),
      Sequences.circulararcsw,
      Sequences.whitetrianglesw,
      Sequences.shadetrianglesw,
      Sequences.blacktrianglesw,
      Sequences.boxlightw,
      Sequences.boxlightw.characters.skip(4).toString(),
      Sequences.boxheavyw,
      Sequences.boxheavyw.characters.skip(4).toString(),
      Sequences.boxroundw,
      Sequences.boxroundw.characters.skip(4).toString(),
      Sequences.boxdoublew,
      Sequences.boxdoublew.characters.skip(4).toString(),
      Sequences.boxouterw,
      Sequences.boxouterw.characters.skip(4).toString(),
      Sequences.chessblack,
      '???????????????????????????',
      Sequences.arroww);
  vertViz(plane, '???', Sequences.eighthsr.characters.elementAt(2), Sequences.eighthsl[2], '???', '??????????????????????????????');
  plane.putStr('$idt????????? ');

  triviz(
      plane,
      Sequences.whitesquaresw.characters.skip(2).toString(),
      Sequences.whitecirclesw.characters.skip(2).toString(),
      Sequences.diagonalsw.characters.skip(2).toString(),
      Sequences.diagonalsw.characters.skip(6).toString(),
      Sequences.circulararcsw.characters.skip(2).toString(),
      Sequences.whitetrianglesw.characters.skip(2).toString(),
      Sequences.shadetrianglesw.characters.skip(2).toString(),
      Sequences.blacktrianglesw.characters.skip(2).toString(),
      Sequences.boxlightw.characters.skip(2).toString(),
      Sequences.boxlightw.characters.skip(5).toString(),
      Sequences.boxheavyw.characters.skip(2).toString(),
      Sequences.boxheavyw.characters.skip(5).toString(),
      Sequences.boxroundw.characters.skip(2).toString(),
      Sequences.boxroundw.characters.skip(5).toString(),
      Sequences.boxdoublew.characters.skip(2).toString(),
      Sequences.boxdoublew.characters.skip(5).toString(),
      Sequences.boxouterw.characters.skip(2).toString(),
      Sequences.boxouterw.characters.skip(5).toString(),
      Sequences.chessblack.characters.skip(3).toString(),
      '???????????????????????????',
      '????????????????????????');
  vertViz(plane, '???', Sequences.eighthsr.characters.elementAt(3), Sequences.eighthsl[3], '???', '??????????????????????????????');
  brailleViz(
    plane,
    '???',
    Sequences.brailleegcs,
    '???',
    idt,
    '??????',
    Sequences.eighthsr.characters.elementAt(4),
    Sequences.eighthsl[4],
    '??????????????????????????????',
  );
  brailleViz(
    plane,
    '???',
    Sequences.brailleegcs.characters.skip(64).toString(),
    '???',
    idt,
    '??????',
    Sequences.eighthsr.characters.elementAt(5),
    Sequences.eighthsl[5],
    '??????????????????????????????',
  );
  brailleViz(
    plane,
    '???',
    Sequences.brailleegcs.characters.skip(128).toString(),
    '???',
    idt,
    '??????',
    Sequences.eighthsr.characters.elementAt(6),
    Sequences.eighthsl[6],
    '??????????????????????????????',
  );
  brailleViz(
    plane,
    '???',
    Sequences.brailleegcs.characters.skip(192).toString(),
    '???',
    idt,
    '??????',
    Sequences.eighthsr.characters.elementAt(7),
    Sequences.eighthsl[7],
    '??????????????????????????????',
  );
  legacyViz(plane, indent.join(), '??????????????????????????????', Sequences.anglesbr, Sequences.anglesbl);
  wviz(plane, Sequences.digitssubw);
  wviz(plane, ' ???');
  wviz(plane, Sequences.eighthsb);
  // ???????????????????????????????????????????????????
  wviz(plane, '\u{1FB6B}\u239e????????????????????????????????????????????');

  if (plane.dimx() > 80) {
    plane.putChar('\n');
  }

  legacyViz(plane, indent.join(), '??????????????????????????????', Sequences.anglestr, Sequences.anglestl);
  wviz(plane, Sequences.digitssuperw);
  wviz(plane, ' ???');
  wviz(plane, Sequences.eighthst);
  // ???????????????????????????????????????????????????
  wviz(plane, '\u{1FB69}\u23a0????????????????????????????????????????????');
  if (plane.dimx() > 80) {
    plane.putChar('\n');
  }
  emojiViz(plane);

  final d = plane.cursorYX();
  final ur = Channels.initializer(0xff, 0xff, 0xff, 0x1B, 0xd8, 0x8E);
  final lr = Channels.initializer(0xff, 0xff, 0xff, 0xdB, 0x18, 0x8E);
  final ul = Channels.initializer(0xff, 0xff, 0xff, 0x19, 0x19, 0x70);
  final ll = Channels.initializer(0xff, 0xff, 0xff, 0x19, 0x19, 0x70);
  plane.stain(d.y - 16, 0, 15, 80, ul, ur, ll, lr);
  plane.setStyles(Style.bold | Style.italic);
  plane.cursorMoveYX(d.y - 12, 55);
  wviz(plane, '????????????https://notcurses.com');
  plane.setStyles(Style.none);
}

int sexViz(Plane plane, String sex, String r, String post) {
  final sexChars = sex.characters;
  for (int i = 0; i < 31; ++i) {
    if (plane.putWc(sexChars.elementAt(i)) < 0) {
      plane.putChar(' ');
    }
  }

  if (plane.putWc(r) < 0) {
    plane.putChar(' ');
  }

  var wchars = 0;
  final chars = post.runes;
  for (var i = 0; i < chars.length; i += wchars) {
    final rc = plane.putWcUtf32(chars.elementAt(i), wchars);
    if (rc.result < 0) {
      plane.putChar(' ');
    }
    wchars = rc.value;
  }
  return 0;
}

void vertViz(Plane plane, String l, String li, String ri, String r, String trail) {
  if (plane.putWc(l) <= 0) {
    plane.putChar(' ');
  }
  if (plane.putWc(li) <= 0) {
    plane.putWc(' ');
  }
  if (plane.putWc(ri) <= 0) {
    plane.putWc(' ');
  }
  if (plane.putWc(r) <= 0) {
    plane.putWc(' ');
  }
  wviz(plane, trail);

  if (plane.dimx() > 80) {
    plane.putWc('\n');
  }
}

void wviz(Plane plane, String wp) {
  var wchars = 0;
  final chars = wp.runes;
  for (var i = 0; i < chars.length; i += wchars) {
    final rc = plane.putWcUtf32(chars.elementAt(i), wchars);
    if (rc.result < 0) {
      plane.putChar(' ');
    }
    wchars = rc.value;
  }
}

void wvizn(Plane plane, String wp, int nnn) {
  final r = wp.characters;
  for (var n = 0; n < nnn; ++n) {
    if (plane.putWc(r.elementAt(n)) < 0) {
      plane.putChar(' ');
    }
  }
}

void triviz(
    Plane plane,
    String w1,
    String w2,
    String w3,
    String w4,
    String w5,
    String w6,
    String w7,
    String w8,
    String w9,
    String wa,
    String wb,
    String wc,
    String wd,
    String we,
    String wf,
    String w10,
    String w11,
    String w12,
    String w13,
    String w14,
    String w15) {
  wvizn(plane, w1, 2);
  plane.putStr(' ');
  wvizn(plane, w2, 2);
  plane.putStr(' ');
  wvizn(plane, w3, 2);
  plane.putStr(' ');
  wvizn(plane, w4, 2);
  wvizn(plane, w5, 2);
  plane.putStr(' ');
  wvizn(plane, w6, 2);
  plane.putStr(' ');
  wvizn(plane, w7, 2);
  plane.putStr(' ');
  wvizn(plane, w8, 2);
  plane.putStr(' ');
  wvizn(plane, w9, 2);
  wvizn(plane, wa, 1);
  plane.putStr(' ');
  wvizn(plane, wb, 2);
  wvizn(plane, wc, 1);
  plane.putStr(' ');
  wvizn(plane, wd, 2);
  wvizn(plane, we, 1);
  plane.putStr(' ');
  wvizn(plane, wf, 2);
  wvizn(plane, w10, 1);
  plane.putStr(' ');
  wvizn(plane, w11, 2);
  wvizn(plane, w12, 1);
  wvizn(plane, w13, 3); // chess
  wviz(plane, w14);
  wviz(plane, w15);
}

int brailleViz(
    Plane plane, String l, String egcs, String r, String indent, String bounds, String r8, String l8, String trailer) {
  plane.putStr('$indent$l');
  final egsChar = egcs.characters;
  for (int i = 0; i < 64; ++i) {
    if (plane.putWc(egsChar.elementAt(i)) <= 0) {
      plane.putStr(' ');
    }
  }
  plane.putWc(r);
  plane.putWc(bounds[0]);
  if (plane.putWc(r8) <= 0) {
    plane.putStr(' ');
  }
  if (plane.putWc(l8) <= 0) {
    plane.putStr(' ');
  }
  plane.putWc(bounds[1]);
  if (trailer.isNotEmpty) {
    wviz(plane, trailer);
  }
  if (plane.dimx() > 80) {
    plane.putStr('\n');
  }
  return 0;
}

// symbols for legacy computing
int legacyViz(Plane plane, String indent, String eighths, String anglesr, String anglesl) {
  plane.putStr('$indent ');

  wviz(plane, eighths);
  plane.putStr(' ');
  final r = anglesr.runes;
  final l = anglesl.runes;
  var ri = 0;
  var li = 0;

  NcResult<int, int> rc = NcResult(0, 0);
  rc.result = 0;

  while (ri < r.length) {
    rc = plane.putWcUtf32(r.elementAt(ri), rc.result);
    if (rc.result <= 0) {
      plane.putStr(' ');
    }
    ri += rc.result;
    rc = plane.putWcUtf32(l.elementAt(li), rc.result);
    if (rc.result <= 0) {
      plane.putStr(' ');
    }
    li += rc.result;
    plane.putStr(' ');
  }
  return 0;
}

int emojiViz(Plane plane) {
  final List<String> emoji = [
    '\u{1f47e}', // alien monster
    '\u{1f3f4}', // waving black flag
    '\u{1f918}', // sign of the horns
    '\u{1f6ac}', // cigarette, delicious
    '\u{1f30d}', // globe europe/africa
    '\u{1f30e}', // globe americas
    '\u{1f30f}', // globe asia/australia
    '\u{1F946}', // rifle
    '\u{1f4a3}', // bomb
    '\u{1f5e1}', // dagger
    '\u{1F52B}', // pistol
    '\u2697\ufe0f', // alembic
    '\u269b\ufe0f', // atom
    '\u2622\ufe0f', // radiation sign
    '\u2623\ufe0f', // biohazard
    '\u{1F33F}', // herb
    '\u{1F3B1}', // billiards
    '\u{1F3E7}', // automated teller machine
    '\u{1F489}', // syringe
    '\u{1F48A}', // pill
    '\u{1f574}\ufe0f', // man in suit levitating
    '\u{1F4E1}', // satellite antenna
    '\u{1F93B}', // modern pentathlon
    '\u{1F991}', // squid
    '\u{1f1e6}\u{1f1f6}', // regional indicators AQ (antarctica)
    '\u{1f469}\u200d\u{1f52c}', // woman scientist
    '\u{1faa4}', // mouse trap
    '\u{1f6b1}', // non-potable water
    '\u270a\u{1f3ff}', // type-6 raised fist
    '\u{1f52c}', // microscope
    '\u{1f9ec}', // dna double helix
    '\u{1f3f4}\u200d\u2620\ufe0f', // pirate flag
    '\u{1f93d}\u{1f3fc}\u200d\u2640\ufe0f', // type-3 woman playing water polo
  ];
  plane.setBgDefault();

  for (var i = 0; i < emoji.length; i++) {
    if (plane.putEgc(emoji[i]).result < 0) {
      plane.putStr('y');
    }
  }

  var dimX = plane.cursorYX().x;
  while (dimX++ < 80) {
    plane.putStr(' ');
  }
  if (plane.dimx() > 80) {
    plane.putStr('\n');
  }

  return 0;
}

void displayLogo(NotCurses nc, Plane plane) {
  final geom = plane.pixelGeom(celldimy: true, celldimx: true);
  final visual = Visual.fromFile('./resources/notcurses.png');
  if (visual.notInitialized) {
    return;
  }
  if (!visual.resize(3 * geom.celldimy, 24 * geom.celldimx)) {
    visual.destroy();
  }
  final dim = plane.cursorYX();
  final opts = VisualOptions(
    plane: plane,
    y: dim.y - 3,
    x: 55,
    blitter: Blitter.pixel,
    flags: VisualOptionFlags.childplane | VisualOptionFlags.nodegrade,
  );
  visual.blit(nc, opts);
  visual.destroy();
}
