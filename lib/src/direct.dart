import 'dart:ffi' as ffi;
import 'package:characters/characters.dart';
import 'package:ffi/ffi.dart';

import './channels.dart';
import './ffi/memory.dart';
import './ffi/notcurses_g.dart';
import './key.dart';
import './load_library.dart';
import './notcurses.dart';
import './pixelgeom_data.dart';
import './plane.dart';
import './shared.dart';
import './visual.dart';

/// Direct mode allows you to use Notcurses together with standard I/O. While
/// the cursor can still be moved arbitrarily, direct mode is intended to be used
/// with newline-delimited, scrolling output. Direct mode has no concept of frame
/// rendering; output is intended to appear immediately (subject to buffering). It
/// is still necessary to have a valid `TERM` environment variable identifying a
/// valid terminfo database entry for the running terminal.
///
/// You can usually simply pass `NULL`, `NULL`, and 0. This will use the terminal
/// entry specified by the `TERM` environment variable, and write to `stdout`. If
/// the terminfo entry cannot be loaded, `ncdirect_init()` will fail. Otherwise,
/// the active style (italics, reverse video, etc.) will be reset to the default,
/// and all `ncdirect` functions are available to use. When done with the context,
/// call `ncdirect_stop()` to release its resources, and restore the terminal's
/// preserved status.
///
/// The cursor is not moved by initialization. If your program was invoked as
/// `ncdirect-demo` from an interactive shell, the cursor is most likely to be
/// on the first column of the line following your command prompt, exactly where
/// a program like `ls` would start its output.
///
/// The terminal will scroll on output just like it normally does, and if you have
/// a scrollback buffer, any output you generate will be present there. Remember:
/// direct mode simply *styles* standard output. With that said, the cursor can be
/// freely controlled in direct mode, and moved arbitrarily within the viewing
/// region. Dimensions of the terminal can be acquired with `ncdirect_dim_y()` and
/// `ncdirect_dim_x()` (if you initialized direct mode with a file not attached to
/// a terminal, Notcurses will simulate a 80x24 canvas). The cursor's location is
/// found with `ncdirect_cursor_yx()` (this function fails if run on a
/// non-terminal, or if the terminal does not support this capability).
class Direct {
  late final String termType;
  late final int flags;
  late final ffi.Pointer<ncdirect> _ptr;

  /// Initialize a direct-mode Notcurses context on the connected terminal at 'fp'.
  /// 'fp' must be a tty. You'll usually want stdout. Direct mode supports a
  /// limited subset of Notcurses routines which directly affect 'fp', and neither
  /// supports nor requires notcurses_render(). This can be used to add color and
  /// styling to text in the standard output paradigm. 'flags' is a bitmask over
  /// NCDIRECT_OPTION_*.
  /// Returns NULL on error, including any failure initializing terminfo.
  Direct({this.termType = '', this.flags = 0}) {
    final ffi.Pointer<ffi.Int8> i8 = termType.isEmpty ? ffi.nullptr.cast() : termType.toNativeUtf8().cast();
    _ptr = nc.ncdirect_init(i8, ffi.nullptr, flags);
    if (termType.isNotEmpty) {
      allocator.free(i8);
    }
  }

  /// The same as ncdirect_init(), but without any multimedia functionality,
  /// allowing for a svelter binary. Link with notcurses-core if this is used.
  Direct.core({String termType = '', int flags = 0}) {
    final ffi.Pointer<ffi.Int8> i8 = termType.isEmpty ? ffi.nullptr.cast() : termType.toNativeUtf8().cast();
    _ptr = nc.ncdirect_core_init(i8, ffi.nullptr, flags);
    if (termType.isNotEmpty) {
      allocator.free(i8);
    }
  }

  bool get notInitialized => _ptr == ffi.nullptr;
  bool get initialized => _ptr != ffi.nullptr;

  /// Release 'nc' and any associated resources. 0 on success, non-0 on failure.
  bool stop() {
    return nc.ncdirect_stop(_ptr) == 0;
  }

  /// Read a newline-delimited chunk of text, after printing the
  /// prompt. The newline itself, if present, is included. Returns NULL on error.
  String? readline([String prompt = '']) {
    final i8 = prompt.toNativeUtf8().cast<ffi.Int8>();
    final result = nc.ncdirect_readline(_ptr, i8);
    allocator.free(i8);

    if (result == ffi.nullptr) {
      return null;
    }
    final rc = result.cast<Utf8>().toDartString();
    allocator.free(result);

    return rc;
  }

  /// Direct mode. This API can be used to colorize and stylize output generated
  /// outside of notcurses, without ever calling notcurses_render(). These should
  /// not be intermixed with standard Notcurses rendering.
  bool setFgRGB(int rgb) {
    return nc.ncdirect_set_fg_rgb(_ptr, rgb) == 0;
  }

  bool setBgRGB(int rgb) {
    return nc.ncdirect_set_bg_rgb(_ptr, rgb) == 0;
  }

  bool setFgPalindex(int index) {
    return nc.ncdirect_set_fg_palindex(_ptr, index) == 0;
  }

  bool setBgPalindex(int index) {
    return nc.ncdirect_set_bg_palindex(_ptr, index) == 0;
  }

  bool setBgRGB8(int r, int g, int b) {
    return ncInline.ncdirect_set_bg_rgb8(_ptr, r, g, b) == 0;
  }

  bool setFgRGB8(int r, int g, int b) {
    return ncInline.ncdirect_set_fg_rgb8(_ptr, r, g, b) == 0;
  }

  bool setFgDefault() {
    return nc.ncdirect_set_fg_default(_ptr) == 0;
  }

  bool setBgDefault() {
    return nc.ncdirect_set_bg_default(_ptr) == 0;
  }

  /// Returns the number of simultaneous colors claimed to be supported, or 1 if
  /// there is no color support. Note that several terminal emulators advertise
  /// more colors than they actually support, downsampling internally.
  int paletteSize() {
    return nc.ncdirect_palette_size(_ptr);
  }

  /// Output the string |utf8| according to the channels |channels|. Note that
  /// ncdirect_putstr() does not explicitly flush output buffers, so it will not
  /// necessarily be immediately visible. Returns EOF on error.
  int putStr(String value, [Channels? channels]) {
    final i8 = value.toNativeUtf8().cast<ffi.Int8>();
    final rc = nc.ncdirect_putstr(_ptr, channels != null ? channels.value : 0, i8);
    allocator.free(i8);
    return rc;
  }

  /// Output a single EGC (this might be several characters) from |utf8|,
  /// according to the channels |channels|. On success, the number of columns
  /// thought to have been used is returned, and if |sbytes| is not NULL,
  /// the number of bytes consumed will be written there.
  /// NcResult.result will be < 0 if error or the totals of columns
  /// the cursor moved
  /// NcResult.value will be the total bytes of the string printed
  NcResult<int, int> putEgc(String value, [Channels? channels]) {
    final i8 = value.toNativeUtf8().cast<ffi.Int8>();
    final sbytes = allocator<ffi.Int32>();
    final rc = nc.ncdirect_putegc(_ptr, channels != null ? channels.value : 0, i8, sbytes);
    final bytesLen = sbytes.value;

    allocator.free(i8);
    allocator.free(sbytes);
    return NcResult(rc, bytesLen);
  }

  /// Force a flush. Returns 0 on success, -1 on failure.
  bool flush() {
    return nc.ncdirect_flush(_ptr) == 0;
  }

  /// Get the current number of rows.
  int dimx() {
    return nc.ncdirect_dim_x(_ptr);
  }

  /// Get the current number of columns.
  int dimy() {
    return nc.ncdirect_dim_y(_ptr);
  }

  /// Returns a 16-bit bitmask of supported curses-style attributes
  /// (NCSTYLE_UNDERLINE, NCSTYLE_BOLD, etc.) The attribute is only
  /// indicated as supported if the terminal can support it together with color.
  /// For more information, see the "ncv" capability in terminfo(5).
  int supportedStyles() {
    return nc.ncdirect_supported_styles(_ptr);
  }

  int setStyles(int stylebits) {
    return nc.ncdirect_set_styles(_ptr, stylebits);
  }

  int onStyles(int stylebits) {
    return nc.ncdirect_on_styles(_ptr, stylebits);
  }

  int offStyles(int stylebits) {
    return nc.ncdirect_off_styles(_ptr, stylebits);
  }

  int styles() {
    return nc.ncdirect_styles(_ptr);
  }

  /// Move the cursor in direct mode. -1 to retain current location on that axis.
  bool cursorMoveYX(int y, int x) {
    return nc.ncdirect_cursor_move_yx(_ptr, y, x) == 0;
  }

  bool cursorEnable() {
    return nc.ncdirect_cursor_enable(_ptr) == 0;
  }

  bool cursorDisable() {
    return nc.ncdirect_cursor_disable(_ptr) == 0;
  }

  bool cursorUp([int num = 1]) {
    return nc.ncdirect_cursor_up(_ptr, num) == 0;
  }

  bool cursorLeft([int num = 1]) {
    return nc.ncdirect_cursor_left(_ptr, num) == 0;
  }

  bool cursorRight([int num = 1]) {
    return nc.ncdirect_cursor_right(_ptr, num) == 0;
  }

  bool cursorDown([int num = 1]) {
    return nc.ncdirect_cursor_down(_ptr, num) == 0;
  }

  /// Get the cursor position, when supported. This requires writing to the
  /// terminal, and then reading from it. If the terminal doesn't reply, or
  /// doesn't reply in a way we understand, the results might be deleterious.
  Dimensions? cursorYX() {
    final yp = allocator<ffi.Uint32>();
    final xp = allocator<ffi.Uint32>();
    final res = nc.ncdirect_cursor_yx(_ptr, yp, xp);
    if (res < 0) {
      return null;
    }
    final rc = Dimensions(yp.value, xp.value);
    allocator.free(yp);
    allocator.free(xp);
    return rc;
  }

  /// Push the cursor location to the terminal's stack. The depth of this
  /// stack, and indeed its existence, is terminal-dependent.
  bool cursorPush() {
    return nc.ncdirect_cursor_push(_ptr) == 0;
  }

  /// Pop the cursor location from the terminal's stack. The depth of this
  /// stack, and indeed its existence, is terminal-dependent.
  bool cursorPop() {
    return nc.ncdirect_cursor_pop(_ptr) == 0;
  }

  /// Clear the screen.
  bool clear() {
    return nc.ncdirect_clear(_ptr) == 0;
  }

  /// returns terminal capabilities
  Capabilities capabilities() {
    final capPtr = nc.ncdirect_capabilities(_ptr);
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

  /// Draw horizontal lines using the specified channels, interpolating
  /// between them as we go. The EGC may not use more than one column. For a
  /// horizontal line, |len| cannot exceed the screen width minus the cursor's
  /// offset. All lines start at the current cursor position.
  int hlineInterp(String egc, int len, Channels chan1, Channels chan2) {
    final i8 = egc.characters.elementAt(0).toNativeUtf8().cast<ffi.Int8>();
    final rc = nc.ncdirect_hline_interp(_ptr, i8, len, chan1.value, chan2.value);
    allocator.free(i8);
    return rc;
  }

  /// Draw vertical lines using the specified channels, interpolating
  /// between them as we go. The EGC may not use more than one column.
  /// For a vertical line, |len| may be as long as you'd like; the screen
  /// will scroll as necessary. All lines start at the current cursor position.
  int vlineInterp(String egc, int len, Channels chan1, Channels chan2) {
    final i8 = egc.characters.elementAt(0).toNativeUtf8().cast<ffi.Int8>();
    final rc = nc.ncdirect_vline_interp(_ptr, i8, len, chan1.value, chan2.value);
    allocator.free(i8);
    return rc;
  }

  /// Draw a box with its upper-left corner at the current cursor position, having
  /// dimensions |ylen|x|xlen|. See ncplane_box() for more information. The
  /// minimum box size is 2x2, and it cannot be drawn off-screen. |wchars| is an
  /// array of 6 wide characters: UL, UR, LL, LR, HL, VL.
  bool box(int ul, int ur, int ll, int lr, String wchars, int ylen, int xlen, int ctlword) {
    final i8 = wchars.characters.elementAt(0).toNativeUtf8().cast<ffi.Int32>();
    final rc = nc.ncdirect_box(_ptr, ul, ur, ll, lr, i8, ylen, xlen, ctlword) == 0;
    allocator.free(i8);
    return rc;
  }

  bool lightBox(int ul, int ur, int ll, int lr, int ylen, int xlen, int ctlword) {
    return ncInline.ncdirect_light_box(_ptr, ul, ur, ll, lr, ylen, xlen, ctlword) == 0;
  }

  bool heavyBox(int ul, int ur, int ll, int lr, int ylen, int xlen, int ctlword) {
    return ncInline.ncdirect_heavy_box(_ptr, ul, ur, ll, lr, ylen, xlen, ctlword) == 0;
  }

  bool asciiBox(int ul, int ur, int ll, int lr, int ylen, int xlen, int ctlword) {
    return ncInline.ncdirect_ascii_box(_ptr, ul, ur, ll, lr, ylen, xlen, ctlword) == 0;
  }

  bool roundedBox(Channels ul, Channels ur, Channels ll, Channels lr, {int ylen = 1, int xlen = 1, int ctlword = 0}) {
    return nc.ncdirect_rounded_box(_ptr, ul.value, ur.value, ll.value, lr.value, ylen, xlen, ctlword) == 0;
  }

  bool doubleBox(Channels ul, Channels ur, Channels ll, Channels lr, {int ylen = 1, int xlen = 1, int ctlword = 0}) {
    return nc.ncdirect_double_box(_ptr, ul.value, ur.value, ll.value, lr.value, ylen, xlen, ctlword) == 0;
  }

  /// Provide a NULL 'ts' to block at length, a 'ts' of 0 for non-blocking
  /// operation, and otherwise an absolute deadline in terms of CLOCK_MONOTONIC.
  /// Returns a single Unicode code point, a synthesized special key constant,
  /// or (uint32_t)-1 on error. Returns 0 on a timeout. If an event is processed,
  /// the return value is the 'id' field from that event. 'ni' may be NULL.
  NcResult<int, Key?> get([int? sec, int? nsec]) {
    final k = Key();
    final ts = _makeTs(sec, nsec);
    final rc = nc.ncdirect_get(_ptr, ts, k.ptr);
    if (rc < 0) {
      k.destroy();
      return NcResult(rc, null);
    }
    if (!_notHasTs(sec, nsec)) allocator.free(ts);
    return NcResult(rc, k);
  }

  ffi.Pointer<timespec> _makeTs(int? sec, int? nsec) {
    if (_notHasTs(sec, nsec)) return ffi.nullptr;

    final ts = allocator<timespec>();
    ts.ref
      ..tv_sec = sec ?? 0
      ..tv_nsec = nsec ?? 0;
    return ts;
  }

  bool _notHasTs(int? sec, int? nsec) {
    return (sec == null && nsec == null);
  }

  /// Get a file descriptor suitable for input event poll()ing. When this
  /// descriptor becomes available, you can call ncdirect_get_nblock(),
  /// and input ought be ready. This file descriptor is *not* necessarily
  /// the file descriptor associated with stdin (but it might be!).
  int inputReadyFD() {
    return nc.ncdirect_inputready_fd(_ptr);
  }

  /// 'ni' may be NULL if the caller is uninterested in event details. If no event
  /// is ready, returns 0.
  NcResult<int, Key?> getNblock() {
    final k = Key();
    final rc = ncInline.ncdirect_get_nblock(_ptr, k.ptr);
    if (rc < 0) {
      k.destroy();
      return NcResult(rc, null);
    }
    return NcResult(rc, k);
  }

  /// 'ni' may be NULL if the caller is uninterested in event details. Blocks
  /// until an event is processed or a signal is received.
  NcResult<int, Key?> getBlocking() {
    final k = Key();
    final rc = ncInline.ncdirect_get_blocking(_ptr, k.ptr);
    if (rc < 0) {
      k.destroy();
      return NcResult(rc, null);
    }
    return NcResult(rc, k);
  }

  /// Display an image using the specified blitter and scaling. The image may
  /// be arbitrarily many rows -- the output will scroll -- but will only occupy
  /// the column of the cursor, and those to the right. The render/raster process
  /// can be split by using ncdirect_render_frame() and ncdirect_raster_frame().
  bool renderImage(String filename, int align, int blitter, int scale) {
    final fname = filename[0].toNativeUtf8().cast<ffi.Int8>();
    final rc = nc.ncdirect_render_image(_ptr, fname, align, blitter, scale) == 0;
    allocator.free(fname);
    return rc;
  }

  /// Render an image using the specified blitter and scaling, but do not write
  /// the result. The image may be arbitrarily many rows -- the output will scroll
  /// -- but will only occupy the column of the cursor, and those to the right.
  /// To actually write (and free) this, invoke ncdirect_raster_frame(). 'maxx'
  /// and 'maxy' (cell geometry, *not* pixel), if greater than 0, are used for
  /// scaling; the terminal's geometry is otherwise used.
  // TODO: review this, Plane is an alias, check ncdirectv
  Plane? renderFrame(String filename, int blitter, int scale, int maxy, int maxx) {
    final fname = filename[0].toNativeUtf8().cast<ffi.Int8>();
    final rc = nc.ncdirect_render_frame(_ptr, fname, blitter, scale, maxy, maxx);
    allocator.free(fname);
    if (rc == ffi.nullptr) return null;
    return Plane.fromPtr(rc);
  }

  /// Takes the result of ncdirect_render_frame() and writes it to the output,
  /// freeing it on all paths.
  bool rasterFrame(Plane ncdv, int align) {
    final rc = nc.ncdirect_raster_frame(_ptr, ncdv.ptr, align) == 0;
    ncdv.destroy();
    return rc;
  }

  /// Load media from disk, but do not yet render it (presumably because you want
  /// to get its geometry via ncdirectf_geom(), or to use the same file with
  /// ncdirect_render_loaded_frame() multiple times). You must destroy the result
  /// with ncdirectf_free();
  // TODO: review this, Visual is an alias, check ncdirectf
  Visual? visualFromFile(String filename) {
    final fname = filename[0].toNativeUtf8().cast<ffi.Int8>();
    final rc = nc.ncdirectf_from_file(_ptr, fname);
    allocator.free(fname);
    if (rc == ffi.nullptr) return null;
    return Visual.fromPtr(rc);
  }

  /// Free a ncdirectf returned from ncdirectf_from_file().
  void visualFree(Visual frame) {
    nc.ncdirectf_free(frame.ptr);
  }

  /// Same as ncdirect_render_frame(), except 'frame' must already have been
  /// loaded. A loaded frame may be rendered in different ways before it is
  /// destroyed.
  Plane? visualRender(Visual frame, VisualOptions vopts) {
    final optr = vopts.toPtr();
    final pp = nc.ncdirectf_render(_ptr, frame.ptr, optr);
    allocator.free(optr);
    if (pp == ffi.nullptr) return null;
    return Plane.fromPtr(pp);
  }

  /// Having loaded the frame 'frame', get the geometry of a potential render.
  NcPixelGeomData? visualGeom(Visual frame, VisualOptions vopts) {
    final optr = vopts.toPtr();
    final geomp = allocator<ncvgeom>();
    final rc = nc.ncdirectf_geom(_ptr, frame.ptr, optr, geomp);
    allocator.free(optr);
    allocator.free(geomp);

    if (rc < 0) return null;
    return NcPixelGeomData.fromPtr(geomp);
  }

  // TODO: ncdirect_stream

  String? detectTerminal() {
    final rc = nc.ncdirect_detected_terminal(_ptr);
    if (rc == ffi.nullptr) return null;
    final value = rc.cast<Utf8>().toDartString();
    allocator.free(rc);
    return value;
  }

  /// Can we directly specify RGB values per cell, or only use palettes?
  bool canTrueColor() {
    return ncInline.ncdirect_cantruecolor(_ptr) != 0;
  }

  /// Can we set the "hardware" palette? Requires the "ccc" terminfo capability.
  bool canChangeColor() {
    return ncInline.ncdirect_canchangecolor(_ptr) != 0;
  }

  /// Can we fade? Fading requires either the "rgb" or "ccc" terminfo capability.
  bool canFade() {
    return ncInline.ncdirect_canfade(_ptr) != 0;
  }

  /// Can we load images? This requires being built against FFmpeg/OIIO.
  bool canOpenImages() {
    return ncInline.ncdirect_canopen_images(_ptr) != 0;
  }

  /// Can we load videos? This requires being built against FFmpeg.
  bool canOpenVideos() {
    return ncInline.ncdirect_canopen_videos(_ptr) != 0;
  }

  /// Is our encoding UTF-8? Requires LANG being set to a UTF8 locale.
  bool canUtf8() {
    return nc.ncdirect_canutf8(_ptr) != 0;
  }

  /// Can we blit pixel-accurate bitmaps?
  bool checkPixelSupport() {
    return nc.ncdirect_check_pixel_support(_ptr) != 0;
  }

  /// Can we reliably use Unicode halfblocks?
  bool canHalfBlock() {
    return ncInline.ncdirect_canhalfblock(_ptr) != 0;
  }

  /// Can we reliably use Unicode quadrants?
  bool canQuadrant() {
    return ncInline.ncdirect_canquadrant(_ptr) != 0;
  }

  /// Can we reliably use Unicode 13 sextants?
  bool canSextant() {
    return ncInline.ncdirect_cansextant(_ptr) != 0;
  }

  /// Can we reliably use Unicode Braille?
  bool canBraile() {
    return ncInline.ncdirect_canbraille(_ptr) != 0;
  }

  /// Is there support for acquiring the cursor's current position? Requires the
  /// u7 terminfo capability, and that we are connected to an actual terminal.
  bool canGetCursor() {
    return nc.ncdirect_canget_cursor(_ptr) != 0;
  }
}
