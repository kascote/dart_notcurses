import 'dart:ffi' as ffi;

import 'package:ffi/ffi.dart';

import './channels.dart';
import './ffi/memory.dart';
import './ffi/notcurses_g.dart';
import './load_library.dart';
import './plane.dart';

class CellData {
  final String egc;
  final int stylemask;
  final int channels;

  const CellData(this.egc, this.stylemask, this.channels);
}

/// An nccell corresponds to a single character cell on some plane, which can be
/// occupied by a single grapheme cluster (some root spacing glyph, along with
/// possible combining characters, which might span multiple columns). At any
/// cell, we can have a theoretically arbitrarily long UTF-8 EGC, a foreground
/// color, a background color, and an attribute set. Valid grapheme cluster
/// contents include:
///
///  * A NUL terminator,
///  * A single control character, followed by a NUL terminator,
///  * At most one spacing character, followed by zero or more nonspacing
///    characters, followed by a NUL terminator.
///
/// Multi-column characters can only have a single style/color throughout.
/// Existence is suffering, and thus wcwidth() is not reliable. It's just
/// quoting whether or not the EGC contains a "Wide Asian" double-width
/// character. This is set for some things, like most emoji, and not set for
/// other things, like cuneiform. True display width is a *function of the
/// font and terminal*. Among the longest Unicode codepoints is
///
///    U+FDFD ARABIC LIGATURE BISMILLAH AR-RAHMAN AR-RAHEEM ﷽
///
/// wcwidth() rather optimistically claims this most exalted glyph to occupy
/// a single column. BiDi text is too complicated for me to even get into here.
/// Be assured there are no easy answers; ours is indeed a disturbing Universe.
///
/// Each nccell occupies 16 static bytes (128 bits). The surface is thus ~1.6MB
/// for a (pretty large) 500x200 terminal. At 80x43, it's less than 64KB.
/// Dynamic requirements (the egcpool) can add up to 16MB to an ncplane, but
/// such large pools are unlikely in common use.
///
/// We implement some small alpha compositing. Foreground and background both
/// have two bits of inverted alpha. The actual grapheme written to a cell is
/// the topmost non-zero grapheme. If its alpha is 00, its foreground color is
/// used unchanged. If its alpha is 10, its foreground color is derived entirely
/// from cells underneath it. Otherwise, the result will be a composite.
/// Likewise for the background. If the bottom of a coordinate's zbuffer is
/// reached with a cumulative alpha of zero, the default is used. In this way,
/// a terminal configured with transparent background can be supported through
/// multiple occluding ncplanes. A foreground alpha of 11 requests high-contrast
/// text (relative to the computed background). A background alpha of 11 is
/// currently forbidden.
///
/// Default color takes precedence over palette or RGB, and cannot be used with
/// transparency. Indexed palette takes precedence over RGB. It cannot
/// meaningfully set transparency, but it can be mixed into a cascading color.
/// RGB is used if neither default terminal colors nor palette indexing are in
/// play, and fully supports all transparency options.
class Cell {
  late final ffi.Pointer<nccell> _ptr;

  /// Initialize a new Cell object and creates a pointer to be used
  Cell.init() {
    _ptr = allocator<nccell>();
    ncInline.nccell_init(_ptr);
  }

  /// Release the memory asociated with this Cell
  void destroy(Plane? plane) {
    if (plane != null) plane.releaseCell(this);
    allocator.free(_ptr);
  }

  ffi.Pointer<nccell> get ptr => _ptr;

  /// Extract 24 bits of foreground RGB from 'cl', split into components.
  RGB fgRGB8() {
    return using<RGB>((Arena alloc) {
      final r = alloc<ffi.Uint32>();
      final g = alloc<ffi.Uint32>();
      final b = alloc<ffi.Uint32>();

      ncInline.nccell_fg_rgb8(_ptr, r, g, b);
      return RGB(r.value, g.value, b.value);
    });
  }

  /// Extract 24 bits of background RGB from 'cl', split into components.
  RGB bgRGB8() {
    return using<RGB>((Arena alloc) {
      final r = alloc<ffi.Uint32>();
      final g = alloc<ffi.Uint32>();
      final b = alloc<ffi.Uint32>();

      ncInline.nccell_bg_rgb8(_ptr, r, g, b);
      return RGB(r.value, g.value, b.value);
    });
  }

  /// Set the r, g, and b cell for the foreground component of this 64-bit
  /// 'cl' variable, and mark it as not using the default color.
  bool setFgRGB8(RGB rgb) {
    return ncInline.nccell_set_fg_rgb8(_ptr, rgb.r, rgb.g, rgb.b) >= 0;
  }

  // Set the r, g, and b cell for the background component of this 64-bit
  // 'cl' variable, and mark it as not using the default color.
  bool setBgRGB8(RGB rgb) {
    return ncInline.nccell_set_bg_rgb8(_ptr, rgb.r, rgb.g, rgb.b) >= 0;
  }

  /// Set the r, g, and b cell for the foreground component of this 64-bit
  /// 'cl' variable, and mark it as not using the default color.
  // clipped to [0..255].
  void setFgRGB8Clipped(RGB rgb) {
    ncInline.nccell_set_fg_rgb8_clipped(_ptr, rgb.r, rgb.g, rgb.b);
  }

  // Set the r, g, and b cell for the background component of this 64-bit
  // 'cl' variable, and mark it as not using the default color.
  // clipped to [0..255].
  void setBgRGB8Clipped(RGB rgb) {
    ncInline.nccell_set_bg_rgb8_clipped(_ptr, rgb.r, rgb.g, rgb.b);
  }

  /// Set the r, g, and b cell for the foreground component of this 64-bit
  /// 'cl' variable, and mark it as not using the default color.
  bool setFgRGB(int color) {
    return ncInline.nccell_set_fg_rgb(_ptr, color) != -1;
  }

  // Same, but with an assembled 24-bit RGB value. A value over 0xffffff
  // will be rejected, with a non-zero return value.
  bool setBgRGB(int color) {
    return ncInline.nccell_set_bg_rgb(_ptr, color) != -1;
  }

  /// return the number of columns occupied by 'c'. see ncstrwidth() for an
  /// equivalent for multiple EGCs.
  int cols() {
    return ncInline.nccell_cols(_ptr);
  }

  /// Set the specified style bits for the nccell 'c', whether they're actively
  /// supported or not. Only the lower 16 bits are meaningful.
  void setStyles(int stylebits) {
    ncInline.nccell_set_styles(_ptr, stylebits);
  }

  /// Extract the style bits from the nccell.
  int styles() {
    return ncInline.nccell_styles(_ptr);
  }

  /// Add the specified styles (in the LSBs) to the nccell's existing spec,
  /// whether they're actively supported or not.
  void onStyles(int stylebits) {
    ncInline.nccell_on_styles(_ptr, stylebits);
  }

  /// Remove the specified styles (in the LSBs) from the nccell's existing spec.
  void offStyles(int stylebits) {
    ncInline.nccell_off_styles(_ptr, stylebits);
  }

  /// Use the default color for the foreground.
  void setFgDefault() {
    ncInline.nccell_set_bg_default(_ptr);
  }

  /// Use the default color for the background.
  void setBgDefault() {
    ncInline.nccell_set_bg_default(_ptr);
  }

  int setFgAlpha(int alpha) {
    return ncInline.nccell_set_fg_alpha(_ptr, alpha);
  }

  int setBgAlpha(int alpha) {
    return ncInline.nccell_set_bg_alpha(_ptr, alpha);
  }

  /// Is the cell part of a multicolumn element?
  bool isDoubleWideP() {
    return ncInline.nccell_double_wide_p(_ptr) != 0;
  }

  /// Extract 24 bits of foreground RGB from 'cl', shifted to LSBs.
  int fgRGB() {
    return ncInline.nccell_fg_rgb(_ptr);
  }

  /// Extract 24 bits of background RGB from 'cl', shifted to LSBs.
  int bgRGB() {
    return ncInline.nccell_bg_rgb(_ptr);
  }

  /// Extract 2 bits of foreground alpha from 'cl', shifted to LSBs.
  int fgAlpha() {
    return ncInline.nccell_fg_alpha(_ptr);
  }

  /// Extract 2 bits of background alpha from 'cl', shifted to LSBs.
  int bgAlpha() {
    return ncInline.nccell_bg_alpha(_ptr);
  }

  /// Is the foreground using the "default foreground color"?
  bool fgDefaultP() {
    return ncInline.nccell_fg_default_p(_ptr) != 0;
  }

  /// Is the background using the "default background color"? The "default
  /// background color" must generally be used to take advantage of
  /// terminal-effected transparency.
  bool bgDefaultP() {
    return ncInline.nccell_bg_default_p(_ptr) != 0;
  }

  /// Set the cell's foreground palette index, set the foreground palette index
  /// bit, set it foreground-opaque, and clear the foreground default color bit.
  int setFgPalindex(int idx) {
    return ncInline.nccell_set_fg_palindex(_ptr, idx);
  }

  /// Set the cell's background palette index, set the background palette index
  /// bit, set it background-opaque, and clear the background default color bit.
  int setBgPalindex(int idx) {
    return ncInline.nccell_set_bg_palindex(_ptr, idx);
  }

  /// the cell's foreground palette index, set the foreground palette index
  /// bit, set it foreground-opaque, and clear the foreground default color bit.
  int fgPalindex(int idx) {
    return ncInline.nccell_fg_palindex(_ptr);
  }

  /// cell's background palette index, set the background palette index
  /// bit, set it background-opaque, and clear the background default color bit.
  int bgPalindex(int idx) {
    return ncInline.nccell_bg_palindex(_ptr);
  }

  /// is the cell using the default pallete (?)
  bool fgPalindexP() {
    return ncInline.nccell_fg_palindex_p(_ptr) != 0;
  }

  /// is the cell using the default pallete (?)
  bool bgPalindexP() {
    return ncInline.nccell_bg_palindex_p(_ptr) != 0;
  }

  @override
  String toString() {
    final r = _ptr.ref;
    return 'Cell: ${r.width} ${r.gcluster} ${r.channels} ${r.stylemask}';
  }
}
