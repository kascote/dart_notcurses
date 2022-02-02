import 'dart:ffi' as ffi;
import 'package:characters/characters.dart';

import 'package:ffi/ffi.dart';

import './cell.dart';
import './ffi/memory.dart';
import './ffi/notcurses_g.dart';
import './load_library.dart';
import './notcurses.dart';
import './pixelgeom_data.dart';
import './shared.dart';

class Dimensions {
  final int y;
  final int x;
  const Dimensions(this.y, this.x);

  @override
  String toString() {
    return 'Dim: x $x, y $y';
  }
}

typedef PlaneResizerCB = ffi.Pointer<ffi.NativeFunction<ffi.Int32 Function(ffi.Pointer<ncplane>)>>;
typedef PlaneUserPointer = ffi.Pointer<ffi.Void>;

class Plane {
  final ffi.Pointer<ncplane> _ptr;

  Plane(this._ptr);

  Plane? create({
    /// vertical placement relative to parent plane
    int? y,

    /// horizontal placement relative to parent plane
    int? x,

    /// rows, must be >0 unless NCPLANE_OPTION_MARGINALIZED
    int? rows,

    /// columns, must be >0 unless NCPLANE_OPTION_MARGINALIZED
    int? cols,

    /// user curry, may be NULL
    PlaneUserPointer? userptr,

    /// name (used only for debugging), may be NULL
    String? name,

    /// callback when parent is resized
    PlaneResizerCB? resizerCB,

    /// closure over NCPLANE_OPTION_*
    int? flags,

    /// margins (require NCPLANE_OPTION_MARGINALIZED)
    int? marginB,

    /// margins (require NCPLANE_OPTION_MARGINALIZED)
    int? marginR,
  }) {
    final optsPtr = allocator<ncplane_options>();
    final opts = optsPtr.ref;
    if (y != null) opts.y = y;
    if (x != null) opts.x = x;
    if (rows != null) opts.rows = rows;
    if (cols != null) opts.cols = cols;
    if (name != null) opts.name = name.toNativeUtf8().cast<ffi.Int8>();
    if (flags != null) opts.flags = flags;
    if (marginB != null) opts.margin_b = marginB;
    if (marginR != null) opts.margin_r = marginR;

    final p = Plane(nc.ncplane_create(_ptr, optsPtr));
    allocator.free(opts.name);
    allocator.free(optsPtr);

    if (p._ptr == ffi.nullptr) {
      return null;
    }
    return p;
  }

  /// Returns a pointer to NcPlane to be used by the NotCurses API
  ffi.Pointer<ncplane> get ptr => _ptr;

  /// Destroy a plane. The Standar Plane can not be destroyed. It will be destroyed
  /// by NotCurses when finish.
  void destroy() {
    final std = notCurses().stdplane();
    if (std.ptr != ptr) nc.ncplane_destroy(ptr);
  }

  /// Returns the dimensions of the current plane
  Dimensions dimyx() {
    return using<Dimensions>((Arena alloc) {
      final y = alloc<ffi.Uint32>();
      final x = alloc<ffi.Uint32>();
      nc.ncplane_dim_yx(_ptr, y, x);
      return Dimensions(y.value, x.value);
    });
  }

  /// Returns the X dimension of the plane
  int dimx() {
    return ncInline.ncplane_dim_x(_ptr);
  }

  /// Returns the Y dimension of the plane
  int dimy() {
    return ncInline.ncplane_dim_y(_ptr);
  }

  /// Set the current fore color using RGB specifications. If the
  /// terminal does not support directly-specified 3x8b cells (24-bit "TrueColor",
  /// indicated by the "RGB" terminfo capability), the provided values will be
  /// interpreted in some lossy fashion. None of r, g, or b may exceed 255.
  /// "HP-like" terminals require setting foreground and background at the same
  /// time using "color pairs"; Notcurses will manage color pairs transparently.
  bool setFgRGB8(int r, int g, int b) {
    return nc.ncplane_set_fg_rgb8(_ptr, r, g, b) == 0;
  }

  /// Set the current background color using RGB specifications. If the
  /// terminal does not support directly-specified 3x8b cells (24-bit "TrueColor",
  /// indicated by the "RGB" terminfo capability), the provided values will be
  /// interpreted in some lossy fashion. None of r, g, or b may exceed 255.
  /// "HP-like" terminals require setting foreground and background at the same
  /// time using "color pairs"; Notcurses will manage color pairs transparently.
  bool setBgRGB8(int r, int g, int b) {
    return nc.ncplane_set_bg_rgb8(_ptr, r, g, b) == 0;
  }

  /// Same as [setFgRGB8], but with rgb assembled into a channel (i.e. lower 24 bits).
  bool setFgRGB(int hex) {
    return nc.ncplane_set_fg_rgb(_ptr, hex) == 0;
  }

  /// Same as [setBgRGB8], but with rgb assembled into a channel (i.e. lower 24 bits).
  bool setBgRGB(int hex) {
    return nc.ncplane_set_bg_rgb(_ptr, hex) == 0;
  }

  /// Same as [setFgRGB8], but clipped to [0..255].
  void setFgRGB8Clipped(int r, int g, int b) {
    nc.ncplane_set_fg_rgb8_clipped(_ptr, r, g, b);
  }

  /// Same as [setBgRGB8], but clipped to [0..255].
  void setBgRGB8Clipped(int r, int g, int b) {
    nc.ncplane_set_bg_rgb8_clipped(_ptr, r, g, b);
  }

  /// Use the default color for the foreground.
  void setFgDefault() {
    nc.ncplane_set_fg_default(_ptr);
  }

  /// Use the default color for the background.
  void setBgDefault() {
    nc.ncplane_set_bg_default(_ptr);
  }

  /// Set the alpha parameters for ncplane 'n'.
  void setFgAlpha(int value) {
    nc.ncplane_set_fg_alpha(_ptr, value);
  }

  /// Set the alpha parameters for ncplane 'n'.
  void setBgAlpha(int value) {
    nc.ncplane_set_bg_alpha(_ptr, value);
  }

  /// Set the ncplane's foreground palette index
  int setFgPalIndex(int idx) {
    return nc.ncplane_set_fg_palindex(_ptr, idx);
  }

  /// Set the ncplane's background palette index
  int setBgPalIndex(int idx) {
    return nc.ncplane_set_bg_palindex(_ptr, idx);
  }

  /// Write a series of EGCs to the specified location, using the current style.
  /// They will be interpreted as a series of columns (according to the definition
  /// of ncplane_putc()). Advances the cursor by some positive number of columns
  /// (though not beyond the end of the plane); this number is returned on success.
  /// On error, a non-positive number is returned, indicating the number of columns
  /// which were written before the error.
  int putStrYX(int y, int x, String value) {
    final gclusters = value.toNativeUtf8().cast<ffi.Int8>();
    final rc = ncInline.ncplane_putstr_yx(_ptr, y, x, gclusters);
    allocator.free(gclusters);
    return rc;
  }

  /// Write a series of EGCs to the current location, using the current style.
  /// They will be interpreted as a series of columns (according to the definition
  /// of ncplane_putc()). Advances the cursor by some positive number of columns
  /// (though not beyond the end of the plane); this number is returned on success.
  /// On error, a non-positive number is returned, indicating the number of columns
  /// which were written before the error.
  int putStr(String value) {
    final gclusters = value.toNativeUtf8().cast<ffi.Int8>();
    final rc = ncInline.ncplane_putstr(_ptr, gclusters);
    allocator.free(gclusters);
    return rc;
  }

  /// Write a series of EGCs aligned to the plane.
  int putStrAligned(int y, int align, String value) {
    final egs = value.toNativeUtf8().cast<ffi.Int8>();
    final rc = ncInline.ncplane_putstr_aligned(_ptr, y, align, egs);
    allocator.free(egs);
    return rc;
  }

  /// Return the column at which 'c' cols ought start in order to be aligned
  /// according to 'align' within ncplane 'n'. Return -INT_MAX on invalid
  /// 'align'. Undefined behavior on negative 'c'.
  int ncPlaneHalign(int align, int c) {
    return ncInline.ncplane_halign(_ptr, align, c);
  }

  /// Return the row at which 'r' rows ought start in order to be aligned
  /// according to 'align' within ncplane 'n'. Return -INT_MAX on invalid
  /// 'align'. Undefined behavior on negative 'r'.
  int ncPlaneValign(int align, int r) {
    return ncInline.ncplane_valign(_ptr, align, r);
  }

  // Return the offset into 'availu' at which 'u' ought be output given the
  // requirements of 'align'. Return -INT_MAX on invalid 'align'. Undefined
  // behavior on negative 'availu' or 'u'.
  int ncAlign(int availu, int align, int u) {
    return ncInline.notcurses_align(availu, align, u);
  }

  /// Erase every cell in the ncplane (each cell is initialized to the null glyph
  /// and the default channels/styles). All cells associated with this ncplane are
  /// invalidated, and must not be used after the call, *excluding* the base cell.
  /// The cursor is homed. The plane's active attributes are unaffected.
  void erase() {
    nc.ncplane_erase(_ptr);
  }

  /// Erase every cell in the region starting at {ystart, xstart} and having size
  /// {|ylen|x|xlen|} for non-zero lengths. If ystart and/or xstart are -1, the current
  /// cursor position along that axis is used; other negative values are an error. A
  /// negative ylen means to move up from the origin, and a negative xlen means to move
  /// left from the origin. A positive ylen moves down, and a positive xlen moves right.
  /// A value of 0 for the length erases everything along that dimension. It is an error
  /// if the starting coordinate is not in the plane, but the ending coordinate may be
  /// outside the plane.
  ///
  /// For example, on a plane of 20 rows and 10 columns, with the cursor at row 10 and
  /// column 5, the following would hold:
  ///
  ///  (-1, -1, 0, 1): clears the column to the right of the cursor (column 6)
  ///  (-1, -1, 0, -1): clears the column to the left of the cursor (column 4)
  ///  (-1, -1, INT_MAX, 0): clears all rows with or below the cursor (rows 10--19)
  ///  (-1, -1, -INT_MAX, 0): clears all rows with or above the cursor (rows 0--10)
  ///  (-1, 4, 3, 3): clears from row 5, column 4 through row 7, column 6
  ///  (-1, 4, -3, -3): clears from row 5, column 4 through row 3, column 2
  ///  (4, -1, 0, 3): clears columns 5, 6, and 7
  ///  (-1, -1, 0, 0): clears the plane *if the cursor is in a legal position*
  ///  (0, 0, 0, 0): clears the plane in all cases
  bool eraseRegion(int ystart, int xstart, int ylen, int xlen) {
    return nc.ncplane_erase_region(ptr, ystart, xstart, ylen, xlen) == 0;
  }

  /// Write the specified text to the plane, breaking lines sensibly, beginning at
  /// the specified line. Returns the number of columns written. When breaking a
  /// line, the line will be cleared to the end of the plane (the last line will
  /// *not* be so cleared). The number of bytes written from the input is written
  /// to '*bytes' if it is not NULL. Cleared columns are included in the return
  /// value, but *not* included in the number of bytes written. Leaves the cursor
  /// at the end of output. A partial write will be accomplished as far as it can;
  /// determine whether the write completed by inspecting '*bytes'. Can output to
  /// multiple rows even in the absence of scrolling, but not more rows than are
  /// available. With scrolling enabled, arbitrary amounts of data can be emitted.
  /// All provided whitespace is preserved -- ncplane_puttext() followed by an
  /// appropriate ncplane_contents() will read back the original output.
  ///
  /// If 'y' is -1, the first row of output is taken relative to the current
  /// cursor: it will be left-, right-, or center-aligned in whatever remains
  /// of the row. On subsequent rows -- or if 'y' is not -1 -- the entire row can
  /// be used, and alignment works normally.
  ///
  /// A newline at any point will move the cursor to the next row.
  int putText(int y, int align, String value) {
    final v = value.toNativeUtf8().cast<ffi.Int8>();
    final rc = nc.ncplane_puttext(_ptr, y, align, v, ffi.nullptr);
    allocator.free(v);
    return rc;
  }

  /// Replace the cell at the specified coordinates with the provided EGC, and
  /// advance the cursor by the width of the cluster (but not past the end of the
  /// plane). On success, returns the number of columns the cursor was advanced.
  /// On failure, -1 is returned. The number of bytes converted from gclust is
  /// written to 'sbytes' if non-NULL.
  NcResult<int, int> putEgcYX(int y, int x, String value) {
    final sbytes = allocator<ffi.Uint64>();
    final charC = value.toNativeUtf8().cast<ffi.Int8>();
    final rc = nc.ncplane_putegc_yx(_ptr, y, x, charC, sbytes);
    final res = NcResult<int, int>(rc, sbytes.value);

    allocator.free(charC);
    allocator.free(sbytes);
    return res;
  }

  /// Replace the cell at the current location with the provided EGC, and
  /// advance the cursor by the width of the cluster (but not past the end of the
  /// plane). On success, returns the number of columns the cursor was advanced.
  /// On failure, -1 is returned. The number of bytes converted from gclust is
  /// written to 'sbytes' if non-NULL.
  NcResult<int, int> putEgc(String value) {
    return putEgcYX(-1, -1, value);
    /* final sbytes = allocator<ffi.Uint64>();
    final charC = value.toNativeUtf8().cast<ffi.Int8>();
    final rc = nc.ncplane_putegc_yx(_ptr, -1, -1, charC, sbytes);
    final res = NcResult<int, int>(rc, sbytes.value);

    allocator.free(charC);
    allocator.free(sbytes);
    return res; */
  }

  /// Set the specified style bits for the ncplane 'n', whether they're actively
  /// supported or not.
  void setStyles(int styles) {
    nc.ncplane_set_styles(_ptr, styles);
  }

  /// Add the specified styles to the ncplane's existing spec.
  void stylesOn(int styles) {
    nc.ncplane_on_styles(_ptr, styles);
  }

  /// Remove the specified styles from the ncplane's existing spec.
  void stylesOff(int styles) {
    nc.ncplane_off_styles(_ptr, styles);
  }

  /// Retrieve pixel geometry for the display region ('pxy', 'pxx'), each cell
  /// ('celldimy', 'celldimx'), and the maximum displayable bitmap ('maxbmapy',
  /// 'maxbmapx'). If bitmaps are not supported, or if there is no artificial
  /// limit on bitmap size, 'maxbmapy' and 'maxbmapx' will be 0. Any of the
  /// geometry arguments may be NULL.
  NcPixelGeomData pixelGeom({
    bool pxy = false,
    bool pxx = false,
    bool celldimy = false,
    bool celldimx = false,
    bool maxbmapy = false,
    bool maxbmapx = false,
  }) {
    return NcPixelGeomData(
      this,
      pxy: pxy,
      pxx: pxx,
      celldimy: celldimy,
      celldimx: celldimx,
      maxbmapy: maxbmapy,
      maxbmapx: maxbmapx,
    );
  }

  /// Move the cursor to the specified position (the cursor needn't be visible).
  /// Pass -1 as either coordinate to hold that axis constant. Returns -1 if the
  /// move would place the cursor outside the plane.
  bool cursorMoveYX(int y, int x) {
    return nc.ncplane_cursor_move_yx(_ptr, y, x) == 0;
  }

  /// Move the cursor relative to the current cursor position (the cursor needn't
  /// be visible). Returns -1 on error, including target position exceeding the
  /// plane's dimensions.
  bool cursorMoveRel(int y, int x) {
    return nc.ncplane_cursor_move_yx(_ptr, y, x) == 0;
  }

  /// Move the cursor to 0, 0. Can't fail.
  void cursorHome() {
    nc.ncplane_home(_ptr);
  }

  /// Get the current position of the cursor within n. y and/or x may be NULL.
  Dimensions cursorYX() {
    return using<Dimensions>((Arena alloc) {
      final y = alloc<ffi.Uint32>();
      final x = alloc<ffi.Uint32>();
      nc.ncplane_cursor_yx(_ptr, y, x);
      return Dimensions(y.value, x.value);
    });
  }

  /// Get the current Y position of the cursor within planen
  int cursorY() {
    return ncInline.ncplane_cursor_y(_ptr);
  }

  /// Get the current X position of the cursor within planen
  int cursorX() {
    return ncInline.ncplane_cursor_x(_ptr);
  }

  /// Replace the cell at the specified coordinates with the provided cell 'c',
  /// and advance the cursor by the width of the cell (but not past the end of the
  /// plane). On success, returns the number of columns the cursor was advanced.
  /// 'cell' must already be associated with 'plane'. On failure, -1 is returned.
  int putcYX(int y, int x, Cell c) {
    return nc.ncplane_putc_yx(_ptr, y, x, c.ptr);
  }

  /// Replace the cell at the current cursor position with the provided cell 'c',
  /// and advance the cursor by the width of the cell (but not past the end of the
  /// plane). On success, returns the number of columns the cursor was advanced.
  /// 'cell' must already be associated with 'plane'. On failure, -1 is returned.
  int putc(Cell c) {
    return putcYX(-1, -1, c);
  }

  /// Replace the cell at the specified coordinates with the provided 7-bit char
  /// 'c'. Advance the cursor by 1. On success, returns 1. On failure, returns -1.
  /// This works whether the underlying char is signed or unsigned.
  int putCharYX(int y, int x, String value) {
    final styles = nc.ncplane_styles(_ptr);
    final channels = nc.ncplane_channels(_ptr);
    final res = primeCell(value, styles, channels);
    if (res.result < 0) return res.result;
    final cell = res.value!;
    final rc = putcYX(y, x, cell);
    cell.destroy(this);
    return rc;
  }

  /// Replace the cell at the current cursor position with the provided 7-bit char
  /// 'c'. Advance the cursor by 1. On success, returns 1. On failure, returns -1.
  /// This works whether the underlying char is signed or unsigned.
  int putChar(String value) {
    return putCharYX(-1, -1, value);
  }

  /// ncplane_putstr(), but following a conversion from wchar_t to UTF-8 multibyte.
  /// FIXME do this as a loop over ncplane_putegc_yx and save the big allocation+copy
  int putWstrYX(int y, int x, String value) {
    final gcluster = value.toNativeUtf8().cast<ffi.Int32>();
    final rc = ncInline.ncplane_putwstr_yx(_ptr, y, x, gcluster);
    allocator.free(gcluster);
    return rc;
  }

  int putWstrAligned(int y, int align, String value) {
    final gcluster = value.toNativeUtf8().cast<ffi.Int32>();
    final rc = ncInline.ncplane_putwstr_aligned(_ptr, y, align, gcluster);
    allocator.free(gcluster);
    return rc;
  }

  int putWstr(String value) {
    final gcluster = value.toNativeUtf8().cast<ffi.Int32>();
    final rc = ncInline.ncplane_putwstr(_ptr, gcluster);
    allocator.free(gcluster);
    return rc;
  }

  /// Replace the cell at the specified coordinates with the provided UTF-32
  /// 'u'. Advance the cursor by the character's width as reported by wcwidth().
  /// On success, returns the number of columns written. On failure, returns -1.
  int putUtf32YX(int y, int x, String value) {
    final gcluster = value.runes.elementAt(0);
    return ncInline.ncplane_pututf32_yx(_ptr, y, x, gcluster);
  }

  int putWcYX(int y, int x, String value) {
    final w = value.runes.elementAt(0);
    return ncInline.ncplane_putwc_yx(_ptr, y, x, w);
  }

  int putWc(String value) {
    final w = value.runes.elementAt(0);
    return ncInline.ncplane_putwc(_ptr, w);
  }

  /// Write the first Unicode character from 'w' at the current cursor position,
  /// using the plane's current styling. In environments where wchar_t is only
  /// 16 bits (Windows, essentially), a single Unicode might require two wchar_t
  /// values forming a surrogate pair. On environments with 32-bit wchar_t, this
  /// should not happen. If w[0] is a surrogate, it is decoded together with
  /// w[1], and passed as a single reconstructed UTF-32 character to
  /// ncplane_pututf32(); 'wchars' will get a value of 2 in this case. 'wchars'
  /// otherwise gets a value of 1. A surrogate followed by an invalid pairing
  /// will set 'wchars' to 2, but return -1 immediately.
  NcResult<int, int> putWcUtf32(int w, int wchars) {
    final wptrwPtr = allocator<ffi.Int32>();
    final wcharsPtr = allocator<ffi.Uint32>();
    wptrwPtr.value = w;
    wcharsPtr.value = wchars;
    final rc = ncInline.ncplane_putwc_utf32(_ptr, wptrwPtr, wcharsPtr);
    final chr = wcharsPtr.value;
    allocator.free(wptrwPtr);
    allocator.free(wcharsPtr);
    return NcResult(rc, chr);
  }

  /// Retrieve the current contents of the specified cell into 'c'. This cell is
  /// invalidated if the associated plane is destroyed. Returns the number of
  /// bytes in the EGC, or -1 on error. Unlike ncplane_at_yx(), when called upon
  /// the secondary columns of a wide glyph, the return can be distinguished from
  /// the primary column (nccell_wide_right_p(c) will return true). It is an
  /// error to call this on a sprixel plane (unlike ncplane_at_yx()).
  bool atYXcell(int y, int x, Cell cell) {
    return nc.ncplane_at_yx_cell(_ptr, y, x, cell.ptr) >= 0;
  }

  /// All planes are created with scrolling disabled. Scrolling can be dynamically
  /// controlled with ncplane_set_scrolling(). Returns true if scrolling was
  /// previously enabled, or false if it was disabled.
  bool setScrolling(bool enabled) {
    return nc.ncplane_set_scrolling(_ptr, enabled ? 1 : 0) > 0;
  }

  /// Retrieves the [NotCurses] references for this plane
  NotCurses notCurses() {
    return NotCurses.fromPtr(nc.ncplane_notcurses(_ptr));
  }

  /// Set the ncplane's base nccell. It will be used for purposes of rendering
  /// anywhere that the ncplane's gcluster is 0. Note that the base cell is not
  /// affected by ncplane_erase(). 'egc' must be an extended grapheme cluster.
  /// Returns the number of bytes copied out of 'gcluster', or -1 on failure.
  int setBase(String char, int stylemask, int channels) {
    final egc = char.toNativeUtf8().cast<ffi.Int8>();
    final rc = nc.ncplane_set_base(_ptr, egc, stylemask, channels);
    allocator.free(egc);
    return rc;
  }

  /// Return the plane above this one, or NULL if this is at the top.
  Plane? above() {
    final rc = nc.ncplane_above(_ptr);
    return rc == ffi.nullptr ? null : Plane(rc);
  }

  // Return the plane below this one, or NULL if this is at the bottom.
  Plane? below() {
    final rc = nc.ncplane_below(_ptr);
    return rc == ffi.nullptr ? null : Plane(rc);
  }

  /// Splice ncplane 'n' out of the z-buffer, and reinsert it below 'below'.
  /// Returns non-zero if 'n' is already in the desired location. 'n' and
  /// 'below' must not be the same plane. If 'below' is NULL, 'n' is moved to
  /// the top of its pile.
  bool moveBelow(Plane? below) {
    final b = below == null ? ffi.nullptr : below.ptr;
    return nc.ncplane_move_below(ptr, b) == 0;
  }

  /// Splice ncplane 'n' out of the z-buffer, and reinsert it above 'above'.
  /// Returns non-zero if 'n' is already in the desired location. 'n' and
  /// 'above' must not be the same plane. If 'above' is NULL, 'n' is moved
  /// to the bottom of its pile.
  bool moveAbove(Plane? above) {
    final a = above == null ? ffi.nullptr : above.ptr;
    return nc.ncplane_move_above(ptr, a) == 0;
  }

  /// Splice ncplane 'n' out of the z-buffer; reinsert it at the top.
  void moveTop() {
    ncInline.ncplane_move_top(ptr);
  }

  /// Splice ncplane 'n' out of the z-buffer; reinsert it at the bottom.
  void moveBottom() {
    ncInline.ncplane_move_bottom(ptr);
  }

  /// Move this plane relative to the standard plane, or the plane to which it is
  /// bound (if it is bound to a plane). It is an error to attempt to move the
  /// standard plane.
  bool moveYX(int y, int x) {
    return nc.ncplane_move_yx(ptr, y, x) == 0;
  }

  //-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
  // Lines
  //-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

  /// Draw horizontal lines using the specified cell, starting at the
  /// current cursor position. The cursor will end at the cell following the last
  /// cell output (even, perhaps counter-intuitively, when drawing vertical
  /// lines), just as if ncplane_putc() was called at that spot. Return the
  /// number of cells drawn on success. On error, return the negative number of
  /// cells drawn. A length of 0 is an error, resulting in a return of -1.
  int hlineInterp(Cell c, int len, int c1, int c2) {
    return nc.ncplane_hline_interp(_ptr, c.ptr, len, c1, c2);
  }

  /// Draw horizontal lines using the specified cell, starting at the
  /// current cursor position. The cursor will end at the cell following the last
  /// cell output (even, perhaps counter-intuitively, when drawing vertical
  /// lines), just as if ncplane_putc() was called at that spot. Return the
  /// number of cells drawn on success. On error, return the negative number of
  /// cells drawn. A length of 0 is an error, resulting in a return of -1.
  int hline(Cell c, int len) {
    return ncInline.ncplane_hline(_ptr, c.ptr, len);
  }

  /// Draw vertical lines using the specified cell, starting at the
  /// current cursor position. The cursor will end at the cell following the last
  /// cell output (even, perhaps counter-intuitively, when drawing vertical
  /// lines), just as if ncplane_putc() was called at that spot. Return the
  /// number of cells drawn on success. On error, return the negative number of
  /// cells drawn. A length of 0 is an error, resulting in a return of -1.
  int vlineInterp(Cell c, int len, int c1, int c2) {
    return nc.ncplane_vline_interp(_ptr, c.ptr, len, c1, c2);
  }

  /// Draw vertical lines using the specified cell, starting at the
  /// current cursor position. The cursor will end at the cell following the last
  /// cell output (even, perhaps counter-intuitively, when drawing vertical
  /// lines), just as if ncplane_putc() was called at that spot. Return the
  /// number of cells drawn on success. On error, return the negative number of
  /// cells drawn. A length of 0 is an error, resulting in a return of -1.
  int vline(Cell c, int len) {
    return ncInline.ncplane_vline(_ptr, c.ptr, len);
  }

  /// Draw a box with its upper-left corner at the current cursor position, and its
  /// lower-right corner at 'ystop'x'xstop'. The 6 cells provided are used to draw the
  /// upper-left, ur, ll, and lr corners, then the horizontal and vertical lines.
  /// 'ctlword' is defined in the least significant byte, where bits [7, 4] are a
  /// gradient mask, and [3, 0] are a border mask:
  ///  * 7, 3: top
  ///  * 6, 2: right
  ///  * 5, 1: bottom
  ///  * 4, 0: left
  /// If the gradient bit is not set, the styling from the hl/vl cells is used for
  /// the horizontal and vertical lines, respectively. If the gradient bit is set,
  /// the color is linearly interpolated between the two relevant corner cells.
  ///
  /// By default, vertexes are drawn whether their connecting edges are drawn or
  /// not. The value of the bits corresponding to NCBOXCORNER_MASK control this,
  /// and are interpreted as the number of connecting edges necessary to draw a
  /// given corner. At 0 (the default), corners are always drawn. At 3, corners
  /// are never drawn (since at most 2 edges can touch a box's corner).
  int box(Cell ul, Cell ur, Cell ll, Cell lr, Cell hline, Cell vline, int ystop, int xstop, int ctlword) {
    return nc.ncplane_box(_ptr, ul.ptr, ur.ptr, ll.ptr, lr.ptr, hline.ptr, vline.ptr, ystop, xstop, ctlword);
  }

  int boxSized(Cell ul, Cell ur, Cell ll, Cell lr, Cell hline, Cell vline, int ylen, int xlen, int ctlword) {
    return ncInline.ncplane_box_sized(_ptr, ul.ptr, ur.ptr, ll.ptr, lr.ptr, hline.ptr, vline.ptr, ylen, xlen, ctlword);
  }

  int perimeter(Cell ul, Cell ur, Cell ll, Cell lr, Cell hline, Cell vline, int ctlword) {
    return ncInline.ncplane_perimeter(_ptr, ul.ptr, ur.ptr, ll.ptr, lr.ptr, hline.ptr, vline.ptr, ctlword);
  }

  /// load up six cells with the EGCs necessary to draw a box. returns 0 on
  /// success, -1 on error. on error, any cells this function might
  /// have loaded before the error are nccell_release()d. There must be at least
  /// six EGCs in gcluster.
  bool cellsLoadBox(int styles, int channels, Cell ul, Cell ur, Cell ll, Cell lr, Cell hl, Cell vl, String gclusters) {
    final u8 = gclusters.toNativeUtf8().cast<ffi.Int8>();
    final rc =
        ncInline.nccells_load_box(_ptr, styles, channels, ul.ptr, ur.ptr, ll.ptr, lr.ptr, hl.ptr, vl.ptr, u8) != 0;
    allocator.free(u8);
    return rc;
  }

  // cellsRoundedBox
  bool cellsRoundedBox(int styles, int channels, Cell ul, Cell ur, Cell ll, Cell lr, Cell hl, Cell vl) {
    return ncInline.nccells_rounded_box(_ptr, styles, channels, ul.ptr, ur.ptr, ll.ptr, lr.ptr, hl.ptr, vl.ptr) != 0;
  }

  int roundedBox(int styles, int channels, int ystop, int xstop, int ctlword) {
    return ncInline.ncplane_rounded_box(_ptr, styles, channels, ystop, xstop, ctlword);
  }

  int roundedBoxSized(int styles, int channels, int ylen, int xlen, int ctlword) {
    return ncInline.ncplane_rounded_box_sized(_ptr, styles, channels, ylen, xlen, ctlword);
  }

  bool cellsDoubleBox(int styles, int channels, Cell ul, Cell ur, Cell ll, Cell lr, Cell hl, Cell vl) {
    return ncInline.nccells_double_box(_ptr, styles, channels, ul.ptr, ur.ptr, ll.ptr, lr.ptr, hl.ptr, vl.ptr) != 0;
  }

  int doubleBox(int styles, int channels, int ystop, int xstop, int ctlword) {
    return ncInline.ncplane_double_box(_ptr, styles, channels, ystop, xstop, ctlword);
  }

  int doubleBoxSized(int styles, int channels, int ylen, int xlen, int ctlword) {
    return ncInline.ncplane_double_box_sized(_ptr, styles, channels, ylen, xlen, ctlword);
  }

  int perimeterRounded(int styles, int channels, int ctlword) {
    return ncInline.ncplane_perimeter_rounded(_ptr, styles, channels, ctlword);
  }

  /// Draw a with a double line around the Plane borders
  /// with ctlword can disable some borders
  int perimeterDouble({int styles = 0, int channels = 0, int ctlword = 0}) {
    return ncInline.ncplane_perimeter_double(_ptr, styles, channels, ctlword);
  }

  int asciiBox(int styles, int channels, int ylen, int xlen, int ctlword) {
    return ncInline.ncplane_ascii_box(_ptr, styles, channels, ylen, xlen, ctlword);
  }

  /// Starting at the specified coordinate, if its glyph is different from that of
  /// 'c', 'c' is copied into it, and the original glyph is considered the fill
  /// target. We do the same to all cardinally-connected cells having this same
  /// fill target. Returns the number of cells polyfilled. An invalid initial y, x
  /// is an error. Returns the number of cells filled, or -1 on error.
  int polyfillYX(int y, int x, Cell c) {
    return nc.ncplane_polyfill_yx(_ptr, y, x, c.ptr);
  }

  /// Draw a gradient with its upper-left corner at the position specified by 'y'/'x',
  /// where -1 means the current cursor position in that dimension. The area is
  /// specified by 'ylen'/'xlen', where 0 means "everything remaining below or
  /// to the right, respectively." The glyph composed of 'egc' and 'styles' is
  /// used for all cells. The channels specified by 'ul', 'ur', 'll', and 'lr'
  /// are composed into foreground and background gradients. To do a vertical
  /// gradient, 'ul' ought equal 'ur' and 'll' ought equal 'lr'. To do a
  /// horizontal gradient, 'ul' ought equal 'll' and 'ur' ought equal 'ul'. To
  /// color everything the same, all four channels should be equivalent. The
  /// resulting alpha values are equal to incoming alpha values. Returns the
  /// number of cells filled on success, or -1 on failure.
  /// Palette-indexed color is not supported.
  ///
  /// Preconditions for gradient operations (error otherwise):
  ///
  ///  all: only RGB colors, unless all four channels match as default
  ///  all: all alpha values must be the same
  ///  1x1: all four colors must be the same
  ///  1xN: both top and both bottom colors must be the same (vertical gradient)
  ///  Nx1: both left and both right colors must be the same (horizontal gradient)
  int gradient(int y, int x, int ylen, int xlen, String egc, int styles, int ul, int ur, int ll, int lr) {
    final u8 = egc.characters.elementAt(0).toNativeUtf8().cast<ffi.Int8>();
    final rc = nc.ncplane_gradient(_ptr, y, x, ylen, xlen, u8, styles, ul, ur, ll, lr);
    allocator.free(u8);
    return rc;
  }

  /// Do a high-resolution gradient using upper blocks and synced backgrounds.
  /// This doubles the number of vertical gradations, but restricts you to
  /// half blocks (appearing to be full blocks). Returns the number of cells
  /// filled on success, or -1 on error.
  int gradient2x1(int y, int x, int ylen, int xlen, int ul, int ur, int ll, int lr) {
    return nc.ncplane_gradient2x1(_ptr, y, x, ylen, xlen, ul, ur, ll, lr);
  }

  /// Set the given style throughout the specified region, keeping content and
  /// channels unchanged. The upper left corner is at 'y', 'x', and -1 may be
  /// specified to indicate the cursor's position in that dimension. The area
  /// is specified by 'ylen', 'xlen', and 0 may be specified to indicate everything
  /// remaining to the right and below, respectively. It is an error for any
  /// coordinate to be outside the plane. Returns the number of cells set,
  /// or -1 on failure.
  int format(int y, int x, int ylen, int xlen, int stylemask) {
    return nc.ncplane_format(_ptr, y, x, ylen, xlen, stylemask);
  }

  /// Set the given channels throughout the specified region, keeping content and
  /// channels unchanged. The upper left corner is at 'y', 'x', and -1 may be
  /// specified to indicate the cursor's position in that dimension. The area
  /// is specified by 'ylen', 'xlen', and 0 may be specified to indicate everything
  /// remaining to the right and below, respectively. It is an error for any
  /// coordinate to be outside the plane. Returns the number of cells set,
  /// or -1 on failure.
  int stain(int y, int x, int ylen, int xlen, int ul, int ur, int ll, int lr) {
    return nc.ncplane_stain(_ptr, y, x, ylen, xlen, ul, ur, ll, lr);
  }

  //-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
  // Cells
  //-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

  /// Breaks the UTF-8 string in 'gcluster' down, setting up the nccell 'c'.
  /// Returns the number of bytes copied out of 'gcluster', or -1 on failure. The
  /// styling of the cell is left untouched, but any resources are released.
  NcResult<int, Cell?> loadCell(String value) {
    final c = Cell.init();
    final u8 = value.toNativeUtf8().cast<ffi.Int8>();
    final rc = nc.nccell_load(_ptr, c.ptr, u8);
    allocator.free(u8);
    if (rc < 0) {
      c.destroy(this);
      return NcResult(rc, null);
    }
    return NcResult(rc, c);
  }

  void releaseCell(Cell c) {
    nc.nccell_release(_ptr, c.ptr);
  }

  /// nccell_load(), plus blast the styling with 'attr' and 'channels'.
  NcResult<int, Cell?> primeCell(String value, int stylemask, int channels) {
    final c = Cell.init();
    final u8 = value.toNativeUtf8().cast<ffi.Int8>();
    final rc = ncInline.nccell_prime(_ptr, c.ptr, u8, stylemask, channels);
    allocator.free(u8);
    if (rc < 0) {
      c.destroy(this);
      return NcResult(rc, null);
    }
    return NcResult(rc, c);
  }

  /// Duplicate one cell onto another when they share a plane. Convenience wrapper.
  NcResult<bool, Cell?> duplicateCell(Cell c) {
    final targ = Cell.init();
    final rc = nc.nccell_duplicate(_ptr, targ.ptr, c.ptr);
    if (rc != 0) {
      targ.destroy(this);
      return NcResult(false, null);
    }
    return NcResult(true, targ);
  }

  /// Returns true if the two nccells are distinct EGCs, attributes, or channels.
  /// The actual egcpool index needn't be the same--indeed, the planes needn't even
  /// be the same. Only the expanded EGC must be equal. The EGC must be bit-equal;
  /// it would probably be better to test whether they're Unicode-equal FIXME.
  /// probably needs be fixed up for sprixels FIXME.
  bool compareCell(Cell c1, Plane n2, Cell c2) {
    return ncInline.nccellcmp(_ptr, c1.ptr, n2.ptr, c2.ptr) != 0;
  }

  /// return a pointer to the NUL-terminated EGC referenced by 'c'. this pointer
  /// can be invalidated by any further operation on the plane 'n', so...watch out!
  String extendedGcluster(Cell c) {
    final i8 = nc.nccell_extended_gcluster(_ptr, c.ptr);
    return i8.cast<Utf8>().toDartString();
  }

  /// copy the UTF8-encoded EGC out of the nccell. the result is not tied to any
  /// ncplane, and persists across erases / destruction.
  String strDupcell(Cell c) {
    final i8 = ncInline.nccell_strdup(_ptr, c.ptr);
    return i8.cast<Utf8>().toDartString();
  }

  // Load a 7-bit char 'ch' into the nccell 'c'. Returns the number of bytes
  // used, or -1 on error.
  int loadCharCell(Cell c, String value) {
    return ncInline.nccell_load_char(_ptr, c.ptr, value.codeUnitAt(0));
  }

  /// Load a UTF-8 encoded EGC of up to 4 bytes into the nccell 'c'. Returns the
  /// number of bytes used, or -1 on error.
  int loadEgc32(Cell c, String value) {
    return ncInline.nccell_load_egc32(_ptr, c.ptr, value.runes.elementAt(0));
  }

  /// Load a UCS-32 codepoint into the nccell 'c'. Returns the number of bytes
  /// used, or -1 on error.
  int loadUcs32(Cell c, String value) {
    return ncInline.nccell_load_ucs32(_ptr, c.ptr, value.runes.elementAt(0));
  }

  // FIXME: how to return this values ? what is the nice api ?
  /// Extract the three elements of a nccell.
  /* int extractCell(Cell c) {
    ffi.Pointer<ffi.Uint16> u16 = allocator<ffi.Uint16>();
    ffi.Pointer<ffi.Uint64> u64 = allocator<ffi.Uint64>();
    var i8 = ncInline.nccell_extract(plane, c.ptr, u16, u64);

    to return
    String str = i8.cast<Utf8>().toDartString();
    u16.value
    u64.value

    allocator.free(u16);
    allocator.free(u64);
    /// ???
  } */

}
