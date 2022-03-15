import 'dart:ffi' as ffi;

import 'package:ffi/ffi.dart';

import './direct.dart';
import './ffi/memory.dart';
import './ffi/notcurses_g.dart';
import './key.dart';
import './load_library.dart';
import './plane.dart';
import './ptypes.dart';
import './shared.dart';

/// Configuration options to be used when create a new NotCurses intance
class CursesOptions {
  /// NcLogLevel options
  final int loglevel;
  final int marginT, marginR, marginB, marginL;
  final int flags;

  CursesOptions({
    this.loglevel = LogLevel.silent,
    this.marginT = 0,
    this.marginR = 0,
    this.marginB = 0,
    this.marginL = 0,
    this.flags = 0,
  });
}

class Version {
  final int major, minor, patch, tweak;
  const Version(this.major, this.minor, this.patch, this.tweak);

  @override
  String toString() {
    return '$major.$minor.$patch.$tweak';
  }
}

class Capabilities {
  final int colors;
  final bool utf8;
  final bool rgb;
  final bool canChangeColors;
  final bool halfblocks;
  final bool quadrants;
  final bool sextants;
  final bool braille;

  const Capabilities({
    this.colors = 0,
    this.utf8 = false,
    this.rgb = false,
    this.canChangeColors = false,
    this.halfblocks = false,
    this.quadrants = false,
    this.sextants = false,
    this.braille = false,
  });

  @override
  String toString() {
    return '''
        colors: $colors
        utf8: $utf8
        canChangeColors: $canChangeColors
        halfblocks: $halfblocks
        quadrants: $quadrants
        sextants: $sextants
        braille: $braille
      ''';
  }
}

class NotCurses {
  late final ffi.Pointer<notcurses> _ptr;

  NotCurses([CursesOptions? opts]) {
    final ffi.Pointer<notcurses_options> optPtr = opts == null ? ffi.nullptr : _makeOptionsPtr(opts);
    _ptr = nc.notcurses_init(optPtr, ffi.nullptr);
    if (optPtr != ffi.nullptr) {
      allocator.free(optPtr);
    }
  }

  NotCurses.fromPtr(ffi.Pointer<notcurses> value) {
    _ptr = value;
  }

  NotCurses.core([CursesOptions? opts]) {
    final ffi.Pointer<notcurses_options> optPtr = opts == null ? ffi.nullptr : _makeOptionsPtr(opts);
    _ptr = nc.notcurses_core_init(optPtr, ffi.nullptr);
    if (optPtr != ffi.nullptr) {
      allocator.free(optPtr);
    }
  }

  ffi.Pointer<notcurses> get ptr => _ptr;

  ffi.Pointer<notcurses_options> _makeOptionsPtr(CursesOptions opts) {
    final opsPtr = allocator<notcurses_options>();
    final ref = opsPtr.ref;
    ref.termtype = ffi.nullptr; // TODO: need to resolve the FD
    ref.loglevel = opts.loglevel;
    ref.margin_t = opts.marginT;
    ref.margin_l = opts.marginL;
    ref.margin_b = opts.marginB;
    ref.margin_r = opts.marginR;
    ref.flags = opts.flags;
    return opsPtr;
  }

  /// Returns true if NotCurses was initialized without problems
  bool get initialized => _ptr != ffi.nullptr;

  /// Returns true if NotCurses was not initialized
  bool get notInitialized => _ptr == ffi.nullptr;

  /// Renders and rasterizes the standard pile in one shot. Blocking call.
  bool render() {
    return ncInline.notcurses_render(_ptr) == 0;
  }

  /// Destroy a Notcurses context
  bool stop() {
    return nc.notcurses_stop(_ptr) == 0;
  }

  /// Get a reference to the standard plane (one matching our current idea of the
  /// terminal size) for this terminal. The standard plane always exists, and its
  /// origin is always at the uppermost, leftmost cell of the terminal.
  Plane stdplane() {
    return Plane.fromPtr(nc.notcurses_stdplane(_ptr));
  }

  /// Enable or disable the terminal's cursor, if supported, placing it at
  /// 'y', 'x'. Immediate effect (no need for a call to notcurses_render()).
  /// It is an error if 'y', 'x' lies outside the standard plane. Can be
  /// called while already visible to move the cursor.
  bool cursorEnable({int y = 0, int x = 0}) {
    return nc.notcurses_cursor_enable(_ptr, y, x) == 0;
  }

  /// Disable the hardware cursor. It is an error to call this while the
  /// cursor is already disabled.
  bool cursorDisable() {
    return nc.notcurses_cursor_disable(_ptr) == 0;
  }

  /// Lex a margin argument according to the standard Notcurses definition. There
  /// can be either a single number, which will define all margins equally, or
  /// there can be four numbers separated by commas.
  bool lexMargins(String margins, CursesOptions? opts) {
    final op = margins.toNativeUtf8().cast<ffi.Int8>();
    final ffi.Pointer<notcurses_options> optPtr = opts == null ? ffi.nullptr : _makeOptionsPtr(opts);
    final rc = nc.notcurses_lex_margins(op, optPtr);
    allocator.free(op);
    if (optPtr != ffi.nullptr) {
      allocator.free(optPtr);
    }
    return rc == 0;
  }

  /// Enable mice events according to 'eventmask'; an eventmask of 0 will disable
  /// all mice tracking. On failure, -1 is returned. On success, 0 is returned, and
  /// mouse events will be published to notcurses_get().
  bool miceEnable(int miceEvents) {
    return nc.notcurses_mice_enable(_ptr, miceEvents) == 0;
  }

  /// Disable mouse events. Any events in the input queue can still be delivered.
  bool miceDisable() {
    return nc.notcurses_mice_enable(_ptr, MiceEvents.noEvents) == 0;
  }

  /// Read a UTF-32-encoded Unicode codepoint from input. This might only be part
  /// of a larger EGC. Provide a NULL 'ts' to block at length, and otherwise a
  /// timespec specifying an absolute deadline calculated using CLOCK_MONOTONIC.
  /// Returns a single Unicode code point, or a synthesized special key constant,
  /// or (uint32_t)-1 on error. Returns 0 on a timeout. If an event is processed,
  /// the return value is the 'id' field from that event. 'ni' may be NULL.
  NcResult<int, Key?> getBlocking() {
    final k = Key();
    final rc = nc.notcurses_get(_ptr, ffi.nullptr, k.ptr);
    if (rc < 0) {
      k.destroy();
      return NcResult(rc, null);
    }
    return NcResult(rc, k);
  }

  /// Acquire up to 'vcount' ncinputs at the vector 'ni'. The number read will be
  /// returned, or -1 on error without any reads, 0 on timeout.
  // TODO: need to figure the right inteface
  /* NcResult<int, List<ncinput>> getVec(Key key, int count) {
    final keyArray = allocator<ncinput>(count);
    final rc = nc.notcurses_getvec(_ptr, ffi.nullptr, key.ptr, count);
    if (rc == -1) {
      allocator.free(keyArray);
      return NcResult(rc, []);
    }
    
    return NcResult(rc, List<ncinput>.generate(count, (i) => keyArray[i]));
  } */

  /// 'ni' may be NULL if the caller is uninterested in event details. If no event
  /// is immediately ready, returns 0.
  NcResult<int, Key?> getNonBlocking({bool keyInfo = true}) {
    if (keyInfo) {
      final k = Key();
      final rc = ncInline.notcurses_get_nblock(_ptr, k.ptr);
      return NcResult(rc, k);
    }
    final rc = ncInline.notcurses_get_nblock(_ptr, ffi.nullptr);
    return NcResult(rc, null);
  }

  /// Get a file descriptor suitable for input event poll()ing. When this
  /// descriptor becomes available, you can call notcurses_get_nblock(),
  /// and input ought be ready. This file descriptor is *not* necessarily
  /// the file descriptor associated with stdin (but it might be!).
  int getInputReadyFD() {
    return nc.notcurses_inputready_fd(_ptr);
  }

  /// Restore signals originating from the terminal's line discipline, i.e.
  /// SIGINT (^C), SIGQUIT (^\), and SIGTSTP (^Z), if disabled.
  int lineSigsEnable() {
    return nc.notcurses_linesigs_enable(_ptr);
  }

  // Disable signals originating from the terminal's line discipline, i.e.
  // SIGINT (^C), SIGQUIT (^\), and SIGTSTP (^Z). They are enabled by default.
  int lineSigsDisable() {
    return nc.notcurses_linesigs_disable(_ptr);
  }

  /// Cannot be inline, as we want to get the versions of the actual Notcurses
  /// library we loaded, not what we compile against.
  Version version() {
    return using<Version>((Arena alloc) {
      final major = alloc<ffi.Int32>();
      final minor = alloc<ffi.Int32>();
      final patch = alloc<ffi.Int32>();
      final tweak = alloc<ffi.Int32>();
      nc.notcurses_version_components(major, minor, patch, tweak);
      return Version(major.value, minor.value, patch.value, tweak.value);
    });
  }

  /// Get the default foreground color, if it is known. Returns -1 on error
  /// (unknown foreground). On success, returns 0, writing the RGB value to
  /// 'fg' (if non-NULL)
  int? defaultForeground() {
    return using<int?>((Arena alloc) {
      final ptr = alloc<ffi.Uint32>();
      final rc = nc.notcurses_default_foreground(_ptr, ptr);
      if (rc < 0) return null;
      return ptr.value;
    });
  }

  /// Get the default background color, if it is known. Returns -1 on error
  /// (unknown background). On success, returns 0, writing the RGB value to
  /// 'bg' (if non-NULL) and setting 'bgtrans' high iff the background color
  /// is treated as transparent.
  int? defaultBackground() {
    return using<int?>((Arena alloc) {
      final ptr = alloc<ffi.Uint32>();
      final rc = nc.notcurses_default_background(_ptr, ptr);
      if (rc < 0) return null;
      return ptr.value;
    });
  }

  /// Returns the name (and sometimes version) of the terminal, as Notcurses
  /// has been best able to determine.
  String? detectTerminal() {
    final rc = nc.notcurses_detected_terminal(_ptr);
    if (rc == ffi.nullptr) return null;
    final value = rc.cast<Utf8>().toDartString();
    allocator.free(rc);
    return value;
  }

  /// Returns a 16-bit bitmask of supported curses-style attributes
  /// (NCSTYLE_UNDERLINE, NCSTYLE_BOLD, etc.) The attribute is only
  /// indicated as supported if the terminal can support it together with color.
  /// For more information, see the "ncv" capability in terminfo(5).
  int supportedStyles() {
    return nc.notcurses_supported_styles(_ptr);
  }

  /// Returns the number of simultaneous colors claimed to be supported, or 1 if
  /// there is no color support. Note that several terminal emulators advertise
  /// more colors than they actually support, downsampling internally.
  int paletteSize() {
    return nc.notcurses_palette_size(_ptr);
  }

  /// Returns capabilities, derived from terminfo, environment variables, and queries
  Capabilities capabilities() {
    final capPtr = nc.notcurses_capabilities(_ptr);
    final cpr = capPtr.ref;

    return Capabilities(
      colors: cpr.colors,
      utf8: cpr.utf8 > 0,
      rgb: cpr.rgb > 0,
      canChangeColors: cpr.can_change_colors > 0,
      halfblocks: cpr.halfblocks > 0,
      quadrants: cpr.quadrants > 0,
      sextants: cpr.sextants > 0,
      braille: cpr.braille > 0,
    );
  }

  /// Can we emit 24-bit, three-channel RGB foregrounds and backgrounds?
  bool canTrueColor() {
    return ncInline.notcurses_cantruecolor(_ptr) > 0;
  }

  /// Can we fade? Fading requires either the "rgb" or "ccc" terminfo capability.
  bool canFade() {
    return ncInline.notcurses_canfade(_ptr) > 0;
  }

  /// Can we set the "hardware" palette? Requires the "ccc" terminfo capability,
  /// and that the number of colors supported is at least the size of our
  /// ncpalette structure.
  bool canChangeColors() {
    return ncInline.notcurses_canchangecolor(_ptr) > 0;
  }

  /// Can we load images? This requires being built against FFmpeg/OIIO.
  bool canOpenImages() {
    return nc.notcurses_canopen_images(_ptr) != 0;
  }

  /// Can we load videos? This requires being built against FFmpeg.
  bool canOpenVideos() {
    return nc.notcurses_canopen_videos(_ptr) != 0;
  }

  /// Is our encoding UTF-8? Requires LANG being set to a UTF8 locale.
  bool canUtf8() {
    return ncInline.notcurses_canutf8(_ptr) != 0;
  }

  // Can we reliably use Unicode halfblocks? Any Unicode implementation can.
  bool canHalfBlock() {
    return ncInline.notcurses_canhalfblock(_ptr) != 0;
  }

  /// Can we reliably use Unicode quadrants?
  bool canQuadrant() {
    return ncInline.notcurses_canquadrant(_ptr) != 0;
  }

  /// Can we reliably use Unicode 13 sextants?
  bool canSextant() {
    return ncInline.notcurses_cansextant(_ptr) != 0;
  }

  /// Can we reliably use Unicode Braille?
  bool canBraille() {
    return ncInline.notcurses_canbraille(_ptr) != 0;
  }

  /// Can we blit pixel-accurate bitmaps?
  bool canPixel() {
    return ncInline.notcurses_canpixel(_ptr) != 0;
  }

  /// Can we blit pixel-accurate bitmaps?
  /// bitmap support. if we support bitmaps, pixel_implementation will be a
  /// value other than NCPIXEL_NONE.
  int checkPixelSupport() {
    return nc.notcurses_check_pixel_support(_ptr);
  }

  /// input functions like notcurses_get() return ucs32-encoded uint32_t. convert
  /// a series of uint32_t to utf8. result must be at least 4 bytes per input
  /// uint32_t (6 bytes per uint32_t will future-proof against Unicode expansion).
  /// the number of bytes used is returned, or -1 if passed illegal ucs32, or too
  /// small of a buffer.
  String ucsToUtf8(int ucs) {
    final ucsp = allocator<ffi.Uint32>();
    ucsp.value = ucs;
    final resultbuf = allocator<ffi.Uint8>(5);
    final buflen = ffi.sizeOf<ffi.Uint8>();
    nc.notcurses_ucs32_to_utf8(ucsp, 1, resultbuf, buflen);
    final utf8 = resultbuf.cast<Utf8>().toDartString();

    allocator.free(resultbuf);
    allocator.free(ucsp);
    return utf8;
  }
}
