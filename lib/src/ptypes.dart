import './ffi/notcurses_g.dart';

/// Log level values to be used on CursesOptions.loglevel
abstract class NcLogLevel {
  /// print nothing once fullscreen service begins
  static const silent = ncloglevel_e.NCLOGLEVEL_SILENT;

  /// default. print diagnostics before we crash/exit
  static const panic = ncloglevel_e.NCLOGLEVEL_PANIC;

  /// we're hanging around, but we've had a horrible fault
  static const fatal = ncloglevel_e.NCLOGLEVEL_FATAL;

  /// we can't keep doing this, but we can do other things
  static const error = ncloglevel_e.NCLOGLEVEL_ERROR;

  /// you probably don't want what's happening to happen
  static const warning = ncloglevel_e.NCLOGLEVEL_WARNING;

  /// "standard information"
  static const info = ncloglevel_e.NCLOGLEVEL_INFO;

  /// "detailed information"
  static const verbose = ncloglevel_e.NCLOGLEVEL_VERBOSE;

  /// this is honestly a bit much
  static const debug = ncloglevel_e.NCLOGLEVEL_DEBUG;

  /// there's probably a better way to do what you want
  static const trace = ncloglevel_e.NCLOGLEVEL_TRACE;
}

abstract class NcPlaneOptionFlags {
  /// Horizontal alignment relative to the parent plane. Use ncalign_e for 'x'.
  static const int horaligned = NCPLANE_OPTION_HORALIGNED;

  /// Vertical alignment relative to the parent plane. Use ncalign_e for 'y'.
  static const int veraligned = NCPLANE_OPTION_VERALIGNED;

  /// Maximize relative to the parent plane, modulo the provided margins. The
  /// margins are best-effort; the plane will always be at least 1 column by
  /// 1 row. If the margins can be effected, the plane will be sized to all
  /// remaining space. 'y' and 'x' are overloaded as the top and left margins
  /// when this flag is used. 'rows' and 'cols' must be 0 when this flag is
  /// used. This flag is exclusive with both of the alignment flags.
  static const int marginalized = NCPLANE_OPTION_MARGINALIZED;

  /// If this plane is bound to a scrolling plane, it ought *not* scroll along
  /// with the parent (it will still move with the parent, maintaining its
  /// relative position, if the parent is moved to a new location).
  static const int fixed = NCPLANE_OPTION_FIXED;

  /// Enable automatic growth of the plane to accommodate output. Creating a
  /// plane with this flag is equivalent to immediately calling
  /// ncplane_set_autogrow(p, true) following plane creation.
  static const int autogrow = NCPLANE_OPTION_AUTOGROW;

  /// Enable vertical scrolling of the plane to accommodate output. Creating a
  /// plane with this flag is equivalent to immediately calling
  /// ncplane_set_scrolling(p, true) following plane creation.
  static const int vscroll = NCPLANE_OPTION_VSCROLL;
}

abstract class NcMiceEvents {
  static const int noEvents = NCMICE_NO_EVENTS;
  static const int moveEvent = NCMICE_MOVE_EVENT;
  static const int buttonEvent = NCMICE_BUTTON_EVENT;
  static const int dragEvent = NCMICE_DRAG_EVENT;
  static const int allEvents = NCMICE_ALL_EVENTS;
}

/// Plots. Given a rectilinear area, an ncplot can graph samples along some axis.
/// There is some underlying independent variable--this could be e.g. measurement
/// sequence number, or measurement time. Samples are tagged with this variable, which
/// should never fall, but may grow non-monotonically. The desired range in terms
/// of the underlying independent variable is provided at creation time. The
/// desired domain can be specified, or can be autosolved. Granularity of the
/// dependent variable depends on glyph selection.
///
/// For instance, perhaps we're sampling load as a time series. We want to
/// display an hour's worth of samples in 40 columns and 5 rows. We define the
/// x-axis to be the independent variable, time. We'll stamp at second
/// granularity. In this case, there are 60 * 60 == 3600 total elements in the
/// range. Each column will thus cover a 90s span. Using vertical blocks (the
/// most granular glyph), we have 8 * 5 == 40 levels of domain. If we report the
/// following samples, starting at 0, using autosolving, we will observe:
///
/// 60   -- 1%       |domain:   1--1, 0: 20 levels
/// 120  -- 50%      |domain:  1--50, 0: 0 levels, 1: 40 levels
/// 180  -- 50%      |domain:  1--50, 0: 0 levels, 1: 40 levels, 2: 40 levels
/// 240  -- 100%     |domain:  1--75, 0: 1, 1: 27, 2: 40
/// 271  -- 100%     |domain: 1--100, 0: 0, 1: 20, 2: 30, 3: 40
/// 300  -- 25%      |domain:  1--75, 0: 0, 1: 27, 2: 40, 3: 33
///
/// At the end, we have data in 4 90s spans: [0--89], [90--179], [180--269], and
/// [270--359]. The first two spans have one sample each, while the second two
/// have two samples each. Samples within a span are averaged (FIXME we could
/// probably do better), so the results are 0, 50, 75, and 62.5. Scaling each of
/// these out of 90 and multiplying by 40 gets our resulting levels. The final
/// domain is 75 rather than 100 due to the averaging of 100+25/2->62.5 in the
/// third span, at which point the maximum span value is once again 75.
///
/// The 20 levels at first is a special case. When the domain is only 1 unit,
/// and autoscaling is in play, assign 50%.
///
/// This options structure works for both the ncuplot (uint64_t) and ncdplot
/// (double) types.
abstract class NcPlotOptionsFlags {
  /// show labels for dependent axis
  static const int labelTickSD = NCPLOT_OPTION_LABELTICKSD;

  /// exponential dependent axis
  static const int exponentialD = NCPLOT_OPTION_EXPONENTIALD;

  /// independent axis is vertical
  static const int verticalI = NCPLOT_OPTION_VERTICALI;

  /// fail rather than degrade blitter
  static const int noDegrade = NCPLOT_OPTION_NODEGRADE;

  /// use domain detection only for max
  static const int detectMaxOnly = NCPLOT_OPTION_DETECTMAXONLY;

  /// print the most recent sample
  static const int printSample = NCPLOT_OPTION_PRINTSAMPLE;
}

abstract class NcBlitterE {
  /// let the ncvisual pick
  static const int defaultt = ncblitter_e.NCBLIT_DEFAULT;

  /// space, compatible with ASCII
  static const int blit_1x1 = ncblitter_e.NCBLIT_1x1;

  /// halves + 1x1 (space)     ▄▀
  static const int blit_2x1 = ncblitter_e.NCBLIT_2x1;

  /// quadrants + 2x1          ▗▐ ▖▀▟▌▙
  static const int blit_2x2 = ncblitter_e.NCBLIT_2x2;

  /// sextants (*NOT* 2x2)     🬀🬁🬂🬃🬄🬅🬆🬇🬈🬉🬊🬋🬌🬍🬎🬏🬐🬑🬒🬓🬔🬕🬖🬗🬘🬙🬚🬛🬜🬝🬞
  static const int blit_3x2 = ncblitter_e.NCBLIT_3x2;
  // 4 rows, 2 cols (braille) ⡀⡄⡆⡇⢀⣀⣄⣆⣇⢠⣠⣤⣦⣧⢰⣰⣴⣶⣷⢸⣸⣼⣾⣿
  static const int braille = ncblitter_e.NCBLIT_BRAILLE;
  // pixel graphics
  static const int pixel = ncblitter_e.NCBLIT_PIXEL;

  /// these blitters are suitable only for plots, not general media
  /// four vertical levels     █▆▄▂
  static const int blit_4x1 = ncblitter_e.NCBLIT_4x1;

  /// these blitters are suitable only for plots, not general media
  /// eight vertical levels    █▇▆▅▄▃▂▁
  static const int blit_8x1 = ncblitter_e.NCBLIT_8x1;
}

/// Alignment within a plane or terminal. Left/right-justified, or centered.
abstract class NcAlignE {
  static const int unaligned = ncalign_e.NCALIGN_UNALIGNED;
  static const int left = ncalign_e.NCALIGN_LEFT;
  static const int center = ncalign_e.NCALIGN_CENTER;
  static const int right = ncalign_e.NCALIGN_RIGHT;

  static int get top => left;
  static int get bottom => right;
}

abstract class NcEventType {
  static const int unknown = ncintype_e.NCTYPE_UNKNOWN;
  static const int press = ncintype_e.NCTYPE_PRESS;
  static const int repeat = ncintype_e.NCTYPE_REPEAT;
  static const int release = ncintype_e.NCTYPE_RELEASE;
}

/// How to scale an ncvisual during rendering. NCSCALE_NONE will apply no
/// scaling. NCSCALE_SCALE scales a visual to the plane's size, maintaining
/// aspect ratio. NCSCALE_STRETCH stretches and scales the image in an attempt
/// to fill the entirety of the plane. NCSCALE_NONE_HIRES and
/// NCSCALE_SCALE_HIRES behave like their counterparts, but admit blitters
/// which don't preserve aspect ratio.
abstract class NcScaleE {
  static const int none = ncscale_e.NCSCALE_NONE;
  static const int scale = ncscale_e.NCSCALE_SCALE;
  static const int stretch = ncscale_e.NCSCALE_STRETCH;
  static const int noneHires = ncscale_e.NCSCALE_NONE_HIRES;
  static const int scaleHires = ncscale_e.NCSCALE_SCALE_HIRES;
}

/// if you want reverse video, try ncchannels_reverse(). if you want blink, try
/// ncplane_pulse(). if you want protection, put things on a different plane.
abstract class NcStyle {
  static const int mask = NCSTYLE_MASK;
  static const int italic = NCSTYLE_ITALIC;
  static const int underline = NCSTYLE_UNDERLINE;
  static const int undercurl = NCSTYLE_UNDERCURL;
  static const int bold = NCSTYLE_BOLD;
  static const int struck = NCSTYLE_STRUCK;
  static const int none = NCSTYLE_NONE;
}

// background cannot be highcontrast, only foreground
abstract class NcAlpha {
  static const int highcontrast = NCALPHA_HIGHCONTRAST; // 0x30000000
  static const int transparent = NCALPHA_TRANSPARENT; // 0x20000000;
  static const int blend = NCALPHA_BLEND; // 0x10000000;
  static const int opaque = NCALPHA_OPAQUE; // 0x00000000;
}

/// Bits for notcurses_options->flags.
abstract class NcOptions {
  /// notcurses_init() will call setlocale() to inspect the current locale. If
  /// that locale is "C" or "POSIX", it will call setlocale(LC_ALL, "") to set
  /// the locale according to the LANG environment variable. Ideally, this will
  /// result in UTF8 being enabled, even if the client app didn't call
  /// setlocale() itself. Unless you're certain that you're invoking setlocale()
  /// prior to notcurses_init(), you should not set this bit. Even if you are
  /// invoking setlocale(), this behavior shouldn't be an issue unless you're
  /// doing something weird (setting a locale not based on LANG).
  static const int inhibitSetlocale = NCOPTION_INHIBIT_SETLOCALE;

  /// We typically try to clear any preexisting bitmaps. If we ought *not* try
  /// to do this, pass NCOPTION_NO_CLEAR_BITMAPS. Note that they might still
  /// get cleared even if this is set, and they might not get cleared even if
  /// this is not set. It's a tough world out there.
  static const int noClearBitmaps = NCOPTION_NO_CLEAR_BITMAPS;

  /// We typically install a signal handler for SIGWINCH that generates a resize
  /// event in the notcurses_get() queue. Set to inhibit this handler.
  static const int noWinchSighandler = NCOPTION_NO_WINCH_SIGHANDLER;

  /// We typically install a signal handler for SIG{INT, ILL, SEGV, ABRT, TERM,
  /// QUIT} that restores the screen, and then calls the old signal handler. Set
  /// to inhibit registration of these signal handlers.
  static const int noQuitSighandlers = NCOPTION_NO_QUIT_SIGHANDLERS;

  /// Initialize the standard plane's virtual cursor to match the physical cursor
  /// at context creation time. Together with NCOPTION_NO_ALTERNATE_SCREEN and a
  /// scrolling standard plane, this facilitates easy scrolling-style programs in
  /// rendered mode.
  static const int preserveCursor = NCOPTION_PRESERVE_CURSOR;

  /// Notcurses typically prints version info in notcurses_init() and performance
  /// info in notcurses_stop(). This inhibits that output.
  static const int suppressBanners = NCOPTION_SUPPRESS_BANNERS;

  /// If smcup/rmcup capabilities are indicated, Notcurses defaults to making use
  /// of the "alternate screen". This flag inhibits use of smcup/rmcup.
  static const int noAlternateScreen = NCOPTION_NO_ALTERNATE_SCREEN;

  /// Do not modify the font. Notcurses might attempt to change the font slightly,
  /// to support certain glyphs (especially on the Linux console). If this is set,
  /// no such modifications will be made. Note that font changes will not affect
  /// anything but the virtual console/terminal in which Notcurses is running.
  static const int noFontChanges = NCOPTION_NO_FONT_CHANGES;

  /// Input may be freely dropped. This ought be provided when the program does not
  /// intend to handle input. Otherwise, input can accumulate in internal buffers,
  /// eventually preventing Notcurses from processing terminal messages.
  static const int drainInput = NCOPTION_DRAIN_INPUT;

  /// Prepare the standard plane in scrolling mode, useful for CLIs. This is
  /// equivalent to calling ncplane_set_scrolling(notcurses_stdplane(nc), true).
  static const int scrolling = NCOPTION_SCROLLING;

  /// "CLI mode" is just setting these four options.
  /// noAlternateScreen, noClearBitmaps, preserveCursor, scrolling
  static const int cliMode = NCOPTION_CLI_MODE;
}

abstract class NcBox {
  static const int maskTop = NCBOXMASK_TOP;
  static const int maskRight = NCBOXMASK_RIGHT;
  static const int maskBottom = NCBOXMASK_BOTTOM;
  static const int maskLeft = NCBOXMASK_LEFT;
  static const int gradTop = NCBOXGRAD_TOP;
  static const int gradRight = NCBOXGRAD_RIGHT;
  static const int gradBottom = NCBOXGRAD_BOTTOM;
  static const int gradLeft = NCBOXGRAD_LEFT;
  static const int cornerMask = NCBOXCORNER_MASK;
  static const int cornerShift = NCBOXCORNER_SHIFT;
}

/// used with the modifiers bitmask. definitions come straight from the kitty
/// keyboard protocol.
abstract class NcKeyMod {
  static const int shift = 1;
  static const int alt = 2;
  static const int ctrl = 4;
  static const int superx = 8;
  static const int hyper = 16;
  static const int meta = 32;
  static const int capslock = 64;
  static const int numlock = 128;
}

abstract class NcReaderOptions {
  static const int horscroll = NCREADER_OPTION_HORSCROLL;
  static const int verscroll = NCREADER_OPTION_VERSCROLL;
  static const int nocdmkeys = NCREADER_OPTION_NOCMDKEYS;
  static const int cursor = NCREADER_OPTION_CURSOR;
}

abstract class NcScale {
  static const int none = ncscale_e.NCSCALE_NONE;
  static const int scale = ncscale_e.NCSCALE_SCALE;
  static const int stretch = ncscale_e.NCSCALE_STRETCH;
  static const int noneHires = ncscale_e.NCSCALE_NONE_HIRES;
  static const int scaleHires = ncscale_e.NCSCALE_SCALE_HIRES;
}

abstract class NcVisualOptFlags {
  /// fail rather than degrade
  static const int nodegrade = NCVISUAL_OPTION_NODEGRADE;

  /// use NCALPHA_BLEND with visual
  static const int blend = NCVISUAL_OPTION_BLEND;

  /// x is an alignment, not absolute
  static const int horaligned = NCVISUAL_OPTION_HORALIGNED;

  /// y is an alignment, not absolute
  static const int veraligned = NCVISUAL_OPTION_VERALIGNED;

  /// transcolor is in effect
  static const int addalpha = NCVISUAL_OPTION_ADDALPHA;

  /// interpret n as parent
  static const int childplane = NCVISUAL_OPTION_CHILDPLANE;

  /// non-interpolative scaling
  static const int nointerpolate = NCVISUAL_OPTION_NOINTERPOLATE;
}

class NcPixelImpleE {
  final int value;
  const NcPixelImpleE._(this.value);

  // https://github.com/dart-lang/sdk/issues/3059
  static const names = [
    'none',
    'sixel',
    'linuxfb',
    'iTerm2',
    'kittyStatic',
    'kittyAnimated',
    'kittySelfref',
  ];

  static const none = NcPixelImpleE._(0);
  static const sixel = NcPixelImpleE._(1); // sixel
  static const linuxfb = NcPixelImpleE._(2); // linux framebuffer
  static const iterm2 = NcPixelImpleE._(3); // iTerm2
  static const kittyStatic = NcPixelImpleE._(4); // kitty pre-0.20.0
  static const kittyAnimated = NcPixelImpleE._(5); // kitty pre-0.22.0
  static const kittySelfref = NcPixelImpleE._(6); // kitty 0.22.0+, wezterm

  String get name => names[value];
  static String fromValue(int v) => names[v];
}

abstract class NcDirectOptions {
  static const inhibitSetlocale = 1;
  static const inhibitCbreak = 2;
  static const drainInput = 4;
  static const noQuitSighandlers = 8;
  static const verbose = 16;
  static const veryVerbose = 32;
}

abstract class NcSeqs {
// unicode box-drawing characters
  static const String boxlightw = '┌┐└┘─│';
  static const String boxheavyw = '┏┓┗┛━┃';
  static const String boxroundw = '╭╮╰╯─│';
  static const String boxdoublew = '╔╗╚╝═║';
  static const String boxasciiw = '/\\\\/-|';
  static const String boxouterw = '🭽🭾🭼🭿▁🭵🭶🭰';

  // 4-cycles around an interior core
  static const String whitesquaresw = '◲◱◳◰';
  static const String whitecirclesw = '◶◵◷◴';
  static const String circulararcsw = '◜◝◟◞';
  static const String whitetrianglesw = '◿◺◹◸';
  static const String blacktrianglesw = '◢◣◥◤';
  static const String shadetrianglesw = '🮞🮟🮝🮜';

  // 4-cycles around an exterior core
  static const String blackarrowheadsw = '⮝⮟⮜⮞';
  static const String lightarrowheadsw = '⮙⮛⮘⮚';
  static const String arrowdoublew = '⮅⮇⮄⮆';
  static const String arrowdashedw = '⭫⭭⭪⭬';
  static const String arrowcircledw = '⮉⮋⮈⮊';
  static const String arrowanticlockw = '⮏⮍⮎⮌';
  static const String boxdraww = '╵╷╴╶';
  static const String boxdrawheavyw = '╹╻╸╺';

  // 8-cycles around an exterior core
  static const String arroww = '⭡⭣⭠⭢⭧⭩⭦⭨';
  static const String diagonalsw = '🮣🮠🮡🮢🮤🮥🮦🮧';

  // superscript and subscript digits
  static const String digitssuperw = '⁰¹²³⁴⁵⁶⁷⁸⁹';
  static const String digitssubw = '₀₁₂₃₄₅₆₇₈₉';

// unicode fucking loves asterisks
  static const String asterisks5 = '🞯🞰🞱🞲🞳🞴';
  static const String asterisks6 = '🞵🞶🞷🞸🞹🞺';
  static const String asterisks8 = '🞻🞼✳🞽🞾🞿';

  // symbols for legacy computing
  static const String anglesbr = '🭁🭂🭃🭄🭅🭆🭇🭈🭉🭊🭋';
  static const String anglestr = '🭒🭓🭔🭕🭖🭧🭢🭣🭤🭥🭦';
  static const String anglesbl = '🭌🭍🭎🭏🭐🭑🬼🬽🬾🬿🭀';
  static const String anglestl = '🭝🭞🭟🭠🭡🭜🭗🭘🭙🭚🭛';
  static const String eighthsb = ' ▁▂▃▄▅▆▇█';
  static const String eighthst = ' ▔🮂🮃▀🮄🮅🮆█';
  static const String eighthsl = '▏▎▍▌▋▊▉█';
  static const String eighthsr = '▕🮇🮈▐🮉🮊🮋█';
  static const String halfblocks = ' ▀▄█';
  static const String quadblocks = ' ▘▝▀▖▌▞▛▗▚▐▜▄▙▟█';
  static const String sexblocks =
      ' 🬀🬁🬂🬃🬄🬅🬆🬇🬈🬊🬋🬌🬍🬎🬏🬐🬑🬒🬓▌🬔🬕🬖🬗🬘🬙🬚🬛🬜🬝🬞🬟🬠🬡🬢🬣🬤🬥🬦🬧▐🬨🬩🬪🬫🬬🬭🬮🬯🬰🬱🬲🬳🬴🬵🬶🬷🬸🬹🬺🬻█';
  static const String brailleegcs =
      '\u2800\u2801\u2808\u2809\u2802\u2803\u280a\u280b\u2810\u2811\u2818\u2819\u2812\u2813\u281a\u281b'
      '\u2804\u2805\u280c\u280d\u2806\u2807\u280e\u280f\u2814\u2815\u281c\u281d\u2816\u2817\u281e\u281f'
      '\u2820\u2821\u2828\u2829\u2822\u2823\u282a\u282b\u2830\u2831\u2838\u2839\u2832\u2833\u283a\u283b'
      '\u2824\u2825\u282c\u282d\u2826\u2827\u282e\u282f\u2834\u2835\u283c\u283d\u2836\u2837\u283e\u283f'
      '\u2840\u2841\u2848\u2849\u2842\u2843\u284a\u284b\u2850\u2851\u2858\u2859\u2852\u2853\u285a\u285b'
      '\u2844\u2845\u284c\u284d\u2846\u2847\u284e\u284f\u2854\u2855\u285c\u285d\u2856\u2857\u285e\u285f'
      '\u2860\u2861\u2868\u2869\u2862\u2863\u286a\u286b\u2870\u2871\u2878\u2879\u2872\u2873\u287a\u287b'
      '\u2864\u2865\u286c\u286d\u2866\u2867\u286e\u286f\u2874\u2875\u287c\u287d\u2876\u2877\u287e\u287f'
      '\u2880\u2881\u2888\u2889\u2882\u2883\u288a\u288b\u2890\u2891\u2898\u2899\u2892\u2893\u289a\u289b'
      '\u2884\u2885\u288c\u288d\u2886\u2887\u288e\u288f\u2894\u2895\u289c\u289d\u2896\u2897\u289e\u289f'
      '\u28a0\u28a1\u28a8\u28a9\u28a2\u28a3\u28aa\u28ab\u28b0\u28b1\u28b8\u28b9\u28b2\u28b3\u28ba\u28bb'
      '\u28a4\u28a5\u28ac\u28ad\u28a6\u28a7\u28ae\u28af\u28b4\u28b5\u28bc\u28bd\u28b6\u28b7\u28be\u28bf'
      '\u28c0\u28c1\u28c8\u28c9\u28c2\u28c3\u28ca\u28cb\u28d0\u28d1\u28d8\u28d9\u28d2\u28d3\u28da\u28db'
      '\u28c4\u28c5\u28cc\u28cd\u28c6\u28c7\u28ce\u28cf\u28d4\u28d5\u28dc\u28dd\u28d6\u28d7\u28de\u28df'
      '\u28e0\u28e1\u28e8\u28e9\u28e2\u28e3\u28ea\u28eb\u28f0\u28f1\u28f8\u28f9\u28f2\u28f3\u28fa\u28fb'
      '\u28e4\u28e5\u28ec\u28ed\u28e6\u28e7\u28ee\u28ef\u28f4\u28f5\u28fc\u28fd\u28f6\u28f7\u28fe\u28ff';
  static const String segdigits32 =
      '\u0001FBF0\u0001FBF1\u0001FBF2\u0001FBF3\u0001FBF4\u0001FBF5\u0001FBF6\u0001FBF7\u0001FBF8\u0001FBF9';
  static const String segdigits = '🯰🯱🯲🯳🯴🯵🯶🯷🯸🯹';
  static const List<int> segdigitsHex = [
    0x0001FBF0,
    0x0001FBF1,
    0x0001FBF2,
    0x0001FBF3,
    0x0001FBF4,
    0x0001FBF5,
    0x0001FBF6,
    0x0001FBF7,
    0x0001FBF8,
    0x0001FBF9
  ];

  static const String suitsblack = '\u2660\u2663\u2665\u2666'; // ♠♣♥♦
  static const String suitswhite = '\u2661\u2662\u2664\u2667'; // ♡♢♤♧
  static const String chessblack = '\u265f\u265c\u265e\u265d\u265b\u265a'; // ♟♜♞♝♛♚
  static const String chesswhite = '\u265f\u265c\u265e\u265d\u265b\u265a'; // ♙♖♘♗♕♔
  static const String dice = '\u2680\u2681\u2682\u2683\u2684\u2685'; // ⚀⚁⚂⚃⚄⚅
  static const String musicsym = '\u2669\u266A\u266B\u266C\u266D\u266E\u266F'; // ♩♪♫♬♭♮♯

// argh
  static const String boxlight = '┌┐└┘─│';
  static const String boxheavy = '┏┓┗┛━┃';
  static const String boxround = '╭╮╰╯─│';
  static const String boxdouble = '╔╗╚╝═║';
  static const String boxascii = '/\\\\/-|';
  static const String boxouter = '🭽🭾🭼🭿▁🭵🭶🭰';
}
