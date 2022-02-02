import 'dart:ffi' as ffi;

import './ffi/memory.dart';
import './ffi/notcurses_g.dart';
import './load_library.dart';

const int _preterUnicodeBase = 1115000;
int preterunicode(int w) => w + _preterUnicodeBase;

abstract class NcKey {
  static final int invalid = preterunicode(0);
  static final int resize = preterunicode(1); // we received SIGWINCH
  static final int up = preterunicode(2);
  static final int right = preterunicode(3);
  static final int down = preterunicode(4);
  static final int left = preterunicode(5);
  static final int ins = preterunicode(6);
  static final int del = preterunicode(7);
  static final int backspace = preterunicode(8); // backspace (sometimes)
  static final int pgdown = preterunicode(9);
  static final int pgup = preterunicode(10);
  static final int home = preterunicode(11);
  static final int end = preterunicode(12);
  static final int f00 = preterunicode(20);
  static final int f01 = preterunicode(21);
  static final int f02 = preterunicode(22);
  static final int f03 = preterunicode(23);
  static final int f04 = preterunicode(24);
  static final int f05 = preterunicode(25);
  static final int f06 = preterunicode(26);
  static final int f07 = preterunicode(27);
  static final int f08 = preterunicode(28);
  static final int f09 = preterunicode(29);
  static final int f10 = preterunicode(30);
  static final int f11 = preterunicode(31);
  static final int f12 = preterunicode(32);
  static final int f13 = preterunicode(33);
  static final int f14 = preterunicode(34);
  static final int f15 = preterunicode(35);
  static final int f16 = preterunicode(36);
  static final int f17 = preterunicode(37);
  static final int f18 = preterunicode(38);
  static final int f19 = preterunicode(39);
  static final int f20 = preterunicode(40);
  static final int f21 = preterunicode(41);
  static final int f22 = preterunicode(42);
  static final int f23 = preterunicode(43);
  static final int f24 = preterunicode(44);
  static final int f25 = preterunicode(45);
  static final int f26 = preterunicode(46);
  static final int f27 = preterunicode(47);
  static final int f28 = preterunicode(48);
  static final int f29 = preterunicode(49);
  static final int f30 = preterunicode(50);
  static final int f31 = preterunicode(51);
  static final int f32 = preterunicode(52);
  static final int f33 = preterunicode(53);
  static final int f34 = preterunicode(54);
  static final int f35 = preterunicode(55);
  static final int f36 = preterunicode(56);
  static final int f37 = preterunicode(57);
  static final int f38 = preterunicode(58);
  static final int f39 = preterunicode(59);
  static final int f40 = preterunicode(60);
  static final int f41 = preterunicode(61);
  static final int f42 = preterunicode(62);
  static final int f43 = preterunicode(63);
  static final int f44 = preterunicode(64);
  static final int f45 = preterunicode(65);
  static final int f46 = preterunicode(66);
  static final int f47 = preterunicode(67);
  static final int f48 = preterunicode(68);
  static final int f49 = preterunicode(69);
  static final int f50 = preterunicode(70);
  static final int f51 = preterunicode(71);
  static final int f52 = preterunicode(72);
  static final int f53 = preterunicode(73);
  static final int f54 = preterunicode(74);
  static final int f55 = preterunicode(75);
  static final int f56 = preterunicode(76);
  static final int f57 = preterunicode(77);
  static final int f58 = preterunicode(78);
  static final int f59 = preterunicode(79);
  static final int f60 = preterunicode(80);
  // ... leave room for up to 100 function keys, egads
  static final int enter = preterunicode(121);
  static final int cls = preterunicode(122); // "clear-screen or erase"
  static final int dleft = preterunicode(123); // down + left on keypad
  static final int dright = preterunicode(124);
  static final int uleft = preterunicode(125); // up + left on keypad
  static final int uright = preterunicode(126);
  static final int center = preterunicode(127); // the most truly neutral of keypresses
  static final int begin = preterunicode(128);
  static final int cancel = preterunicode(129);
  static final int close = preterunicode(130);
  static final int command = preterunicode(131);
  static final int copy = preterunicode(132);
  static final int exit = preterunicode(133);
  static final int print = preterunicode(134);
  static final int refresh = preterunicode(135);
  static final int separator = preterunicode(136);
  // these keys aren't generally available outside of the kitty protocol
  static final int capsLock = preterunicode(150);
  static final int scrollLock = preterunicode(151);
  static final int numLock = preterunicode(152);
  static final int printScreen = preterunicode(153);
  static final int pause = preterunicode(154);
  static final int menu = preterunicode(155);
  // media keys, similarly only available through kitty's protocol
  static final int mediaPlay = preterunicode(158);
  static final int mediaPause = preterunicode(159);
  static final int mediaPpause = preterunicode(160);
  static final int mediaRev = preterunicode(161);
  static final int mediaStop = preterunicode(162);
  static final int mediaFf = preterunicode(163);
  static final int mediaRewind = preterunicode(164);
  static final int mediaNext = preterunicode(165);
  static final int mediaPrev = preterunicode(166);
  static final int mediaRecord = preterunicode(167);
  static final int mediaLvol = preterunicode(168);
  static final int mediaRvol = preterunicode(169);
  static final int mediaMute = preterunicode(170);
  // modifiers when pressed by themselves. this ordering comes from the Kitty
  // keyboard protocol, and mustn't be changed without updating handlers.
  static final int lshift = preterunicode(171);
  static final int lctrl = preterunicode(172);
  static final int lalt = preterunicode(173);
  static final int lsuper = preterunicode(174);
  static final int lhyper = preterunicode(175);
  static final int lmeta = preterunicode(176);
  static final int rshift = preterunicode(177);
  static final int rctrl = preterunicode(178);
  static final int ralt = preterunicode(179);
  static final int rsuper = preterunicode(180);
  static final int rhyper = preterunicode(181);
  static final int rmeta = preterunicode(182);
  static final int l3shift = preterunicode(183);
  static final int l5shift = preterunicode(184);
  // mouse events. We encode which button was pressed into the char32_t,
  // but position information is embedded in the larger ncinput event.
  static final int motion = preterunicode(200); // no buttons pressed
  static final int button1 = preterunicode(201);
  static final int button2 = preterunicode(202);
  static final int button3 = preterunicode(203);
  static final int button4 = preterunicode(204); // scrollwheel up
  static final int button5 = preterunicode(205); // scrollwheel down
  static final int button6 = preterunicode(206);
  static final int button7 = preterunicode(207);
  static final int button8 = preterunicode(208);
  static final int button9 = preterunicode(209);
  static final int button10 = preterunicode(210);
  static final int button11 = preterunicode(211);

  // we received SIGCONT
  static final int signal = preterunicode(400);

  // indicates that we have reached the end of input. any further calls
  // will continute to return this immediately.
  static final int eof = preterunicode(500);

  // Synonyms (so far as we're concerned)
  static final int scrollUp = NcKey.button4;
  static final int scrollDown = NcKey.button5;
  static final int returnx = NcKey.enter;

  // Just aliases, ma'am, from the 128 characters common to ASCII+UTF8
  static final int tab = 0x09;
  static final int esc = 0x1b;
  static final int space = 0x20;
}

Map<int, String> keyStrMap = {
  NcKey.resize: 'resize event',
  NcKey.invalid: 'invalid',
  NcKey.left: 'left',
  NcKey.up: 'up',
  NcKey.right: 'right',
  NcKey.down: 'down',
  NcKey.ins: 'insert',
  NcKey.del: 'delete',
  NcKey.pgdown: 'pgdown',
  NcKey.pgup: 'pgup',
  NcKey.home: 'home',
  NcKey.end: 'end',
  NcKey.f00: 'F0',
  NcKey.f01: 'F1',
  NcKey.f02: 'F2',
  NcKey.f03: 'F3',
  NcKey.f04: 'F4',
  NcKey.f05: 'F5',
  NcKey.f06: 'F6',
  NcKey.f07: 'F7',
  NcKey.f08: 'F8',
  NcKey.f09: 'F9',
  NcKey.f10: 'F10',
  NcKey.f11: 'F11',
  NcKey.f12: 'F12',
  NcKey.f13: 'F13',
  NcKey.f14: 'F14',
  NcKey.f15: 'F15',
  NcKey.f16: 'F16',
  NcKey.f17: 'F17',
  NcKey.f18: 'F18',
  NcKey.f19: 'F19',
  NcKey.f20: 'F20',
  NcKey.f21: 'F21',
  NcKey.f22: 'F22',
  NcKey.f23: 'F23',
  NcKey.f24: 'F24',
  NcKey.f25: 'F25',
  NcKey.f26: 'F26',
  NcKey.f27: 'F27',
  NcKey.f28: 'F28',
  NcKey.f29: 'F29',
  NcKey.f30: 'F30',
  NcKey.f31: 'F31',
  NcKey.f32: 'F32',
  NcKey.f33: 'F33',
  NcKey.f34: 'F34',
  NcKey.f35: 'F35',
  NcKey.f36: 'F36',
  NcKey.f37: 'F37',
  NcKey.f38: 'F38',
  NcKey.f39: 'F39',
  NcKey.f40: 'F40',
  NcKey.f41: 'F41',
  NcKey.f42: 'F42',
  NcKey.f43: 'F43',
  NcKey.f44: 'F44',
  NcKey.f45: 'F45',
  NcKey.f46: 'F46',
  NcKey.f47: 'F47',
  NcKey.f48: 'F48',
  NcKey.f49: 'F49',
  NcKey.f50: 'F50',
  NcKey.f51: 'F51',
  NcKey.f52: 'F52',
  NcKey.f53: 'F53',
  NcKey.f54: 'F54',
  NcKey.f55: 'F55',
  NcKey.f56: 'F56',
  NcKey.f57: 'F57',
  NcKey.f58: 'F58',
  NcKey.f59: 'F59',
  NcKey.backspace: 'backspace',
  NcKey.center: 'center',
  NcKey.enter: 'enter',
  NcKey.cls: 'clear',
  NcKey.dleft: 'down+left',
  NcKey.dright: 'down+right',
  NcKey.uleft: 'up+left',
  NcKey.uright: 'up+right',
  NcKey.begin: 'begin',
  NcKey.cancel: 'cancel',
  NcKey.close: 'close',
  NcKey.command: 'command',
  NcKey.copy: 'copy',
  NcKey.exit: 'exit',
  NcKey.print: 'print',
  NcKey.refresh: 'refresh',
  NcKey.separator: 'separator',
  NcKey.capsLock: 'caps lock',
  NcKey.scrollLock: 'scroll lock',
  NcKey.numLock: 'num lock',
  NcKey.printScreen: 'print screen',
  NcKey.pause: 'pause',
  NcKey.menu: 'menu',
  // media keys, similarly only available through kitty's protocol
  NcKey.mediaPlay: 'play',
  NcKey.mediaPause: 'pause',
  NcKey.mediaPpause: 'play-pause',
  NcKey.mediaRev: 'reverse',
  NcKey.mediaStop: 'stop',
  NcKey.mediaFf: 'fast-forward',
  NcKey.mediaRewind: 'rewind',
  NcKey.mediaNext: 'next track',
  NcKey.mediaPrev: 'previous track',
  NcKey.mediaRecord: 'record',
  NcKey.mediaLvol: 'lower volume',
  NcKey.mediaRvol: 'raise volume',
  NcKey.mediaMute: 'mute',
  NcKey.lshift: 'left shift',
  NcKey.lctrl: 'left ctrl',
  NcKey.lalt: 'left alt',
  NcKey.lsuper: 'left super',
  NcKey.lhyper: 'left hyper',
  NcKey.lmeta: 'left meta',
  NcKey.rshift: 'right shift',
  NcKey.rctrl: 'right ctrl',
  NcKey.ralt: 'right alt',
  NcKey.rsuper: 'right super',
  NcKey.rhyper: 'right hyper',
  NcKey.rmeta: 'right meta',
  NcKey.l3shift: 'level 3 shift',
  NcKey.l5shift: 'level 5 shift',
  NcKey.motion: 'mouse (no buttons pressed)',
  NcKey.button1: 'mouse (button 1)',
  NcKey.button2: 'mouse (button 2)',
  NcKey.button3: 'mouse (button 3)',
  NcKey.button4: 'mouse (button 4)',
  NcKey.button5: 'mouse (button 5)',
  NcKey.button6: 'mouse (button 6)',
  NcKey.button7: 'mouse (button 7)',
  NcKey.button8: 'mouse (button 8)',
  NcKey.button9: 'mouse (button 9)',
  NcKey.button10: 'mouse (button 10)',
  NcKey.button11: 'mouse (button 11)',
};

String ncKeyStr(int value) {
  return keyStrMap[value] ?? 'unknown';
}

typedef _CheckModifierCB = int Function(ffi.Pointer<ncinput>);

class Key {
  late final ffi.Pointer<ncinput> ptr;
  List<int>? _utf8;

  Key() : ptr = allocator<ncinput>();

  void destroy() {
    allocator.free(ptr);
  }

  int get id => ptr.ref.id;
  int get x => ptr.ref.x;
  int get y => ptr.ref.y;
  int get evType => ptr.ref.evtype;
  int get modifiers => ptr.ref.modifiers;
  int get ypx => ptr.ref.ypx;
  int get xpx => ptr.ref.xpx;
  List<int> get utf8List {
    _utf8 ??= List<int>.generate(5, ((i) => ptr.ref.utf8[i]));
    return _utf8!;
  }

  String get keyStr {
    final k = id;
    return ((k >= 0x20) && (k < 0x80)) ? String.fromCharCode(k) : '';
  }

  @override
  String toString() {
    final List<String> keys = [
      hasShift() ? 'S' : 's',
      hasCtrl() ? 'C' : 'c',
      hasAlt() ? 'A' : 'a',
      hasMeta() ? 'M' : 'm',
      hasSuper() ? 'Z' : 'z',
      hasHyper() ? 'H' : 'h',
    ];
    return 'Key id:$id yx:($y/$x) px:($ypx/$xpx) type:$evType mod:${keys.join(' ')}';
  }

  /// Is this uint32_t a synthesized event?
  bool keySynthesizedP() {
    return ncInline.nckey_synthesized_p(id) != 0;
  }

  /// Is the event a synthesized mouse event?
  bool keyMouseP() {
    return ncInline.nckey_mouse_p(id) != 0;
  }

  /// Is this uint32_t from the Private Use Area in the BMP (Plane 0)?
  bool keyPuaP() {
    return ncInline.nckey_pua_p(id) != 0;
  }

  /// Is this uint32_t a Supplementary Private Use Area-A codepoint?
  bool keySuppPuaAP() {
    return ncInline.nckey_supppuaa_p(id) != 0;
  }

  /// Is this uint32_t a Supplementary Private Use Area-B codepoint?
  bool keySuppPuaBP() {
    return ncInline.nckey_supppuab_p(id) != 0;
  }

  // Was 'ni' free of modifiers?
  bool nomodP() {
    return ncInline.ncinput_nomod_p(ptr) != 0;
  }

  bool equalP(Key k) {
    return ncInline.ncinput_equal_p(ptr, k.ptr) != 0;
  }

  bool _checkModifier(_CheckModifierCB cb, [int? key]) {
    final hasMod = cb(ptr) != 0;
    if (key == null) return hasMod;
    return hasMod && ptr.ref.id == key;
  }

  /// check if Shift modifier is active
  /// if a key id is passed, check if the key is present too
  bool hasShift([int? key]) {
    return _checkModifier(ncInline.ncinput_shift_p, key);
  }

  /* bool hasShift([int? key]) {
    final shiftPresent = ncInline.ncinput_shift_p(ptr) != 0;
    if (key == null) return shiftPresent;
    return shiftPresent && ptr.ref.id == key;
  } */

  /// check if Ctrl modifier is active
  /// if a key id is sent, check if the key is present too
  bool hasCtrl([int? key]) {
    return _checkModifier(ncInline.ncinput_ctrl_p, key);
  }

  /// check if Alt modifier is active
  /// if a key id is sent, check if the key is present too
  bool hasAlt([int? key]) {
    return _checkModifier(ncInline.ncinput_alt_p, key);
  }

  /// check if Meta modifier is active
  /// if a key id is sent, check if the key is present too
  bool hasMeta([int? key]) {
    return _checkModifier(ncInline.ncinput_meta_p, key);
  }

  /// check if Super modifier is active
  /// if a key id is sent, check if the key is present too
  bool hasSuper([int? key]) {
    return _checkModifier(ncInline.ncinput_super_p, key);
  }

  /// check if Hyper modifier is active
  /// if a key id is sent, check if the key is present too
  bool hasHyper([int? key]) {
    return _checkModifier(ncInline.ncinput_hyper_p, key);
  }

  /// check if Capslock modifier is active
  bool hasCapslock() {
    return _checkModifier(ncInline.ncinput_capslock_p);
  }

  /// check if Numlock modifier is active
  bool hasNumlock() {
    return _checkModifier(ncInline.ncinput_numlock_p);
  }
}
