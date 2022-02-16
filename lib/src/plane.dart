import 'dart:ffi' as ffi;
import 'dart:typed_data';

import 'package:characters/characters.dart';
import 'package:ffi/ffi.dart';

import './cell.dart';
import './channels.dart';
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

  /// Create a new ncplane bound to plane 'n', at the offset 'y'x'x' (relative to
  /// the origin of 'n') and the specified size. The number of 'rows' and 'cols'
  /// must both be positive. This plane is initially at the top of the z-buffer,
  /// as if ncplane_move_top() had been called on it. The void* 'userptr' can be
  /// retrieved (and reset) later. A 'name' can be set, used in debugging.
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

  /// Extract 24 bits of foreground RGB from 'n', split into components.
  NcResult<int, RGB> fgRGB8() {
    return using<NcResult<int, RGB>>((Arena alloc) {
      final r = alloc<ffi.Uint32>();
      final g = alloc<ffi.Uint32>();
      final b = alloc<ffi.Uint32>();
      final rc = ncInline.ncplane_fg_rgb8(_ptr, r, g, b);
      return NcResult(rc, RGB(r.value, g.value, b.value));
    });
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

  /// Extract 24 bits of background RGB from 'n', split into components.
  NcResult<int, RGB> bgRGB8() {
    return using<NcResult<int, RGB>>((Arena alloc) {
      final r = alloc<ffi.Uint32>();
      final g = alloc<ffi.Uint32>();
      final b = alloc<ffi.Uint32>();
      final rc = ncInline.ncplane_bg_rgb8(_ptr, r, g, b);
      return NcResult(rc, RGB(r.value, g.value, b.value));
    });
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

  // Extract 2 bits of foreground alpha from 'struct ncplane', shifted to LSBs.
  int fgAlpha() {
    return ncInline.ncplane_fg_alpha(_ptr);
  }

  /// Set the alpha parameters for ncplane 'n'.
  void setFgAlpha(int value) {
    nc.ncplane_set_fg_alpha(_ptr, value);
  }

  /// Extract 2 bits of background alpha from 'struct ncplane', shifted to LSBs.
  int bgAlpha() {
    return ncInline.ncplane_bg_alpha(_ptr);
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

  /// Return the current styling for this ncplane.
  int styles() {
    return nc.ncplane_styles(_ptr);
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
  // TODO bring this class inside
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
  int atYXcell(int y, int x, Cell cell) {
    return nc.ncplane_at_yx_cell(_ptr, y, x, cell.ptr);
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

  /// Move this plane relative to its current location. Negative values move up
  /// and left, respectively. Pass 0 to hold an axis constant.
  bool moveRelative(int y, int x) {
    return ncInline.ncplane_move_rel(_ptr, y, x) == 0;
  }

  /// Splice ncplane 'n' and its bound planes out of the z-buffer, and reinsert
  /// them above 'targ'. Relative order will be maintained between the
  /// reinserted planes. For a plane E bound to C, with z-ordering A B C D E,
  /// moving the C family to the top results in C E A B D, while moving it to
  /// the bottom results in A B D C E.
  bool moveFamilyAbove(Plane plane) {
    return nc.ncplane_move_family_above(_ptr, plane.ptr) == 0;
  }

  /// Splice ncplane 'n' and its bound planes out of the z-buffer, and reinsert
  /// them below 'targ'. Relative order will be maintained between the
  /// reinserted planes. For a plane E bound to C, with z-ordering A B C D E,
  /// moving the C family to the top results in C E A B D, while moving it to
  /// the bottom results in A B D C E.
  bool moveFamilyBelow(Plane plane) {
    return nc.ncplane_move_family_below(_ptr, plane.ptr) == 0;
  }

  /// Splice ncplane 'n' and its bound planes out of the z-buffer, and reinsert
  /// it at the top. Relative order will be maintained between the
  /// reinserted planes. For a plane E bound to C, with z-ordering A B C D E,
  /// moving the C family to the top results in C E A B D, while moving it to
  /// the bottom results in A B D C E.
  void moveFamilyTop() {
    ncInline.ncplane_move_family_top(_ptr);
  }

  /// Splice ncplane 'n' and its bound planes out of the z-buffer, and reinsert
  /// it at the bottom. Relative order will be maintained between the
  /// reinserted planes. For a plane E bound to C, with z-ordering A B C D E,
  /// moving the C family to the top results in C E A B D, while moving it to
  /// the bottom results in A B D C E.
  void moveFamilyBottom() {
    ncInline.ncplane_move_family_bottom(_ptr);
  }

  /// Get the origin of plane 'n' relative to its bound plane, or pile (if 'n' is
  /// a root plane). To get absolute coordinates, use ncplane_abs_yx().
  Dimensions yx() {
    return using<Dimensions>((Arena alloc) {
      final y = alloc<ffi.Int32>();
      final x = alloc<ffi.Int32>();
      nc.ncplane_yx(_ptr, y, x);
      return Dimensions(y.value, x.value);
    });
  }

  /// Get the origin Y of plane 'n' relative to its bound plane, or pile (if 'n' is
  /// a root plane).
  int y() {
    return nc.ncplane_y(_ptr);
  }

  /// Get the origin X of plane 'n' relative to its bound plane, or pile (if 'n' is
  /// a root plane).
  int x() {
    return nc.ncplane_x(_ptr);
  }

  /// Get the absolute coordinates of plane relative to its pile.
  Dimensions absYX() {
    return using<Dimensions>((Arena alloc) {
      final y = alloc<ffi.Int32>();
      final x = alloc<ffi.Int32>();
      nc.ncplane_abs_yx(_ptr, y, x);
      return Dimensions(y.value, x.value);
    });
  }

  /// Get the absolute Y coordinate of plane relative to its pile.
  int absY() {
    return nc.ncplane_abs_y(_ptr);
  }

  /// Get the absolute X coordinate of plane relative to its pile.
  int absX() {
    return nc.ncplane_abs_x(_ptr);
  }

  /// The standard plane cannot be reparented; we return NULL in that case.
  /// If provided |newparent|==|n|, we are moving |n| to its own pile. If |n|
  /// is already bound to |newparent|, this is a no-op, and we return |n|.
  /// This is essentially a wrapper around ncplane_reparent_family() that first
  /// reparents any children to the parent of 'n', or makes them root planes if
  /// 'n' is a root plane.
  Plane? reparent(Plane newparent) {
    final newp = nc.ncplane_reparent(_ptr, newparent.ptr);
    if (newp == ffi.nullptr) return null;
    return Plane(newp);
  }

  /// Move a Plane and to a another one. The new parent can not be a child of the current plane.
  Plane? reparentFamily(Plane newparent) {
    final newp = nc.ncplane_reparent_family(_ptr, newparent.ptr);
    if (newp == ffi.nullptr) return null;
    return Plane(newp);
  }

  /// Return true iff 'n' is a proper descendent of 'ancestor'.
  bool descendantP(Plane ancestor) {
    return ncInline.ncplane_descendant_p(_ptr, ancestor.ptr) != 0;
  }

  /// Resize the specified ncplane. The four parameters 'keepy', 'keepx',
  /// 'keepleny', and 'keeplenx' define a subset of the ncplane to keep,
  /// unchanged. This may be a region of size 0, though none of these four
  /// parameters may be negative. 'keepx' and 'keepy' are relative to the ncplane.
  /// They must specify a coordinate within the ncplane's totality. 'yoff' and
  /// 'xoff' are relative to 'keepy' and 'keepx', and place the upper-left corner
  /// of the resized ncplane. Finally, 'ylen' and 'xlen' are the dimensions of the
  /// ncplane after resizing. 'ylen' must be greater than or equal to 'keepleny',
  /// and 'xlen' must be greater than or equal to 'keeplenx'. It is an error to
  /// attempt to resize the standard plane. If either of 'keepleny' or 'keeplenx'
  /// is non-zero, both must be non-zero.
  ///
  /// Essentially, the kept material does not move. It serves to anchor the
  /// resized plane. If there is no kept material, the plane can move freely.
  bool resize(int keepy, int keepx, int keepleny, int keeplenx, int yoff, int xoff, int ylen, int xlen) {
    return nc.ncplane_resize(_ptr, keepy, keepx, keepleny, keeplenx, yoff, xoff, ylen, xlen) == 0;
  }

  /// realign the plane 'n' against its parent, using the alignments specified
  /// with NCPLANE_OPTION_HORALIGNED and/or NCPLANE_OPTION_VERALIGNED.
  bool resizeRealign() {
    return nc.ncplane_resize_realign(_ptr) == 0;
  }

  /// resize the plane to the visual region's size (used for the standard plane).
  bool resizeMaximize() {
    return nc.ncplane_resize_maximize(_ptr) == 0;
  }

  /// resize the plane to its parent's size, attempting to enforce the margins
  /// supplied along with NCPLANE_OPTION_MARGINALIZED.
  bool resizeMarginalized() {
    return nc.ncplane_resize_marginalized(_ptr) == 0;
  }

  /// move the plane such that it is entirely within its parent, if possible.
  /// no resizing is performed.
  bool resizePlaceWithin() {
    return nc.ncplane_resize_placewithin(_ptr) == 0;
  }

  /// Duplicate an existing ncplane. The new plane will have the same geometry,
  /// will duplicate all content, and will start with the same rendering state.
  /// The new plane will be immediately above the old one on the z axis, and will
  /// be bound to the same parent (unless 'n' is a root plane, in which case the
  /// new plane will be bound to it). Bound planes are *not* duplicated; the new
  /// plane is bound to the parent of 'n', but has no bound planes.
  Plane dup(Plane plane) {
    // TODO: figure how send the 'opaque' param that is a Void* to let the user
    // store some information on the pane
    return Plane(nc.ncplane_dup(plane.ptr, ffi.nullptr));
  }

  /// Get the plane to which the plane 'n' is bound, if any.
  Plane? parent() {
    final p = nc.ncplane_parent(_ptr);
    if (p == ffi.nullptr) return null;
    return Plane(p);
  }

  /// Set the ncplane's base nccell to 'c'. The base cell is used for purposes of
  /// rendering anywhere that the ncplane's gcluster is 0. Note that the base cell
  /// is not affected by ncplane_erase(). 'c' must not be a secondary cell from a
  /// multicolumn EGC.
  int setBaseCell(Cell c) {
    return nc.ncplane_set_base_cell(_ptr, c.ptr);
  }

  /// Retrieve the current contents of the cell under the cursor. The EGC is
  /// returned, or NULL on error. The stylemask and channels are written to
  /// 'stylemask' and 'channels', respectively.
  CellData? atCursor() {
    return using<CellData?>((Arena alloc) {
      final pstyle = alloc<ffi.Uint16>();
      final pchannel = alloc<ffi.Uint64>();
      final pi8 = nc.ncplane_at_cursor(_ptr, pstyle, pchannel);
      if (pi8 == ffi.nullptr) return null;
      final rc = CellData(pi8.cast<Utf8>().toDartString(), pstyle.value, pchannel.value);
      malloc.free(pi8);
      return rc;
    });
  }

  /// Retrieve the current contents of the cell under the cursor into 'c'. This
  /// cell is invalidated if the associated plane is destroyed. Returns the number
  /// of bytes in the EGC, or -1 on error.
  NcResult<int, Cell?> atCursorCell() {
    final c = Cell.init();
    final rc = nc.ncplane_at_cursor_cell(_ptr, c.ptr);
    if (rc == -1) {
      c.destroy(null);
      return NcResult(-1, null);
    }
    return NcResult(rc, c);
  }

  /// Retrieve the current contents of the specified cell. The EGC is returned, or
  /// NULL on error. This EGC must be free()d by the caller. The stylemask and
  /// channels are written to 'stylemask' and 'channels', respectively. The return
  /// represents how the cell will be used during rendering, and thus integrates
  /// any base cell where appropriate. If called upon the secondary columns of a
  /// wide glyph, the EGC will be returned (i.e. this function does not distinguish
  /// between the primary and secondary columns of a wide glyph). If called on a
  /// sprixel plane, its control sequence is returned for all valid locations.
  CellData? atYX(int y, int x) {
    return using<CellData?>((Arena alloc) {
      final pstyle = alloc<ffi.Uint16>();
      final pchannel = alloc<ffi.Uint64>();
      final pi8 = nc.ncplane_at_yx(_ptr, y, x, pstyle, pchannel);
      if (pi8 == ffi.nullptr) return null;
      final rc = CellData(pi8.cast<Utf8>().toDartString(), pstyle.value, pchannel.value);
      calloc.free(pi8);
      return rc;
    });
  }

  /// Create an RGBA flat array from the selected region of the ncplane 'nc'.
  /// Start at the plane's 'begy'x'begx' coordinate (which must lie on the
  /// plane), continuing for 'leny'x'lenx' cells. Either or both of 'leny' and
  /// 'lenx' can be specified as 0 to go through the boundary of the plane.
  /// Only glyphs from the specified ncblitset may be present. If 'pxdimy' and/or
  /// 'pxdimx' are non-NULL, they will be filled in with the total pixel geometry.
  Uint32List? asRGBA(int blit, int begy, int begx, int leny, int lenx) {
    return using<Uint32List?>((Arena alloc) {
      final pxdimy = alloc<ffi.Uint32>();
      final pxdimx = alloc<ffi.Uint32>();
      final rgbaSize = ffi.sizeOf<ffi.Uint32>() * lenx * pxdimx.value * leny * pxdimy.value;
      final u32 = nc.ncplane_as_rgba(_ptr, blit, begy, begx, leny, lenx, pxdimy, pxdimx);
      if (u32 == ffi.nullptr) return null;

      final u32List = Uint32List.fromList(u32.asTypedList(rgbaSize));
      allocator.free(u32);

      return u32List;
    });
  }

  /// Create a flat string from the EGCs of the selected region of the ncplane
  /// 'n'. Start at the plane's 'begy'x'begx' coordinate (which must lie on the
  /// plane), continuing for 'leny'x'lenx' cells. Either or both of 'leny' and
  /// 'lenx' can be specified as 0 to go through the boundary of the plane.
  /// -1 can be specified for 'begx'/'begy' to use the current cursor location.
  String contents(int begy, int begx, int leny, int lenx) {
    final egc = nc.ncplane_contents(_ptr, begy, begx, leny, lenx);
    final rc = egc.cast<Utf8>().toDartString();
    allocator.free(egc);
    return rc;
  }

  // TODO:
  /* void* ncplane_set_userptr(struct ncplane* n, void* opaque);
  void* ncplane_userptr(struct ncplane* n); */

  /// provided a coordinate relative to the origin of 'src', map it to the same
  /// absolute coordinate relative to the origin of 'dst'. either or both of 'y'
  /// and 'x' may be NULL. if 'dst' is NULL, it is taken to be the standard plane.
  Dimensions translate(Plane? dst, int y, int x) {
    return using<Dimensions>((Arena alloc) {
      final py = alloc<ffi.Int32>();
      final px = alloc<ffi.Int32>();
      final dp = dst != null ? dst.ptr : ffi.nullptr;
      nc.ncplane_translate(_ptr, dp, py, px);
      return Dimensions(py.value, px.value);
    });
  }

  /// Fed absolute 'y'/'x' coordinates, determine whether that coordinate is
  /// within the ncplane 'n'. If not, return false. If so, return true. Either
  /// way, translate the absolute coordinates relative to 'n'. If the point is not
  /// within 'n', these coordinates will not be within the dimensions of the plane.
  NcResult<bool, Dimensions> translateAbs(int y, int x) {
    return using<NcResult<bool, Dimensions>>((Arena alloc) {
      final py = alloc<ffi.Int32>();
      final px = alloc<ffi.Int32>();
      final rc = nc.ncplane_translate_abs(_ptr, py, px) != 0;
      return NcResult(rc, Dimensions(py.value, px.value));
    });
  }

  /// Get the current channels or attribute word for ncplane 'n'.
  int channels() {
    return nc.ncplane_channels(_ptr);
  }

  /// Set the current channels or attribute word for ncplane 'n'.
  void setChannels(int channels) {
    nc.ncplane_set_channels(_ptr, channels);
  }

  /// Extract the background alpha and coloring bits from a 64-bit channel
  /// pair as a single 32-bit value.
  int bchannel() {
    return ncInline.ncplane_bchannel(_ptr);
  }

  /// Extract the foreground alpha and coloring bits from a 64-bit channel
  /// pair as a single 32-bit value.
  int fchannel() {
    return ncInline.ncplane_fchannel(_ptr);
  }

  /// Convert the plane's content to greyscale.
  void greyscale() {
    nc.ncplane_greyscale(_ptr);
  }

  /// Merge the ncplane 'src' down onto the ncplane 'dst'. This is most rigorously
  /// defined as "write to 'dst' the frame that would be rendered were the entire
  /// stack made up only of the specified subregion of 'src' and, below it, the
  /// subregion of 'dst' having the specified origin. Supply -1 to indicate the
  /// current cursor position in the relevant dimension. Merging is independent of
  /// the position of 'src' viz 'dst' on the z-axis. It is an error to define a
  /// subregion that is not entirely contained within 'src'. It is an error to
  /// define a target origin such that the projected subregion is not entirely
  /// contained within 'dst'.  Behavior is undefined if 'src' and 'dst' are
  /// equivalent. 'dst' is modified, but 'src' remains unchanged. Neither 'src'
  /// nor 'dst' may have sprixels. Lengths of 0 mean "everything left".
  bool mergeDown(Plane dst, int begsrcy, int begsrcx, int leny, int lenx, int dsty, int dstx) {
    return nc.ncplane_mergedown(_ptr, dst.ptr, begsrcy, begsrcx, leny, lenx, dsty, dstx) != 0;
  }

  /// Merge the entirety of 'src' down onto the ncplane 'dst'. If 'src' does not
  /// intersect with 'dst', 'dst' will not be changed, but it is not an error.
  bool mergeDownSimple(Plane dst) {
    return nc.ncplane_mergedown_simple(_ptr, dst.ptr) != 0;
  }

  /// By default, planes are created with autogrow disabled. Autogrow can be
  /// dynamically controlled with ncplane_set_autogrow(). Returns true if
  /// autogrow was previously enabled, or false if it was disabled.
  bool setAutogrow(bool status) {
    return nc.ncplane_set_autogrow(_ptr, status ? 1 : 0) != 0;
  }

  /// Returns current autogrow status
  bool getAutogrow() {
    return nc.ncplane_autogrow_p(_ptr) != 0;
  }

  /// Effect |r| scroll events on the plane |n|. Returns an error if |n| is not
  /// a scrolling plane, and otherwise returns the number of lines scrolled.
  int scrollUp(int r) {
    return nc.ncplane_scrollup(_ptr, r);
  }

  /// Scroll |n| up until |child| is no longer hidden beneath it. Returns an
  /// error if |child| is not a child of |n|, or |n| is not scrolling, or |child|
  /// is fixed. Returns the number of scrolling events otherwise (might be 0).
  /// If the child plane is not fixed, it will likely scroll as well.
  int scrollUpChild(Plane child) {
    return nc.ncplane_scrollup_child(_ptr, child.ptr);
  }

  // Rotate the plane π/2 radians clockwise. This cannot
  // be performed on arbitrary planes, because glyphs cannot be arbitrarily
  // rotated. The glyphs which can be rotated are limited: line-drawing
  // characters, spaces, half blocks, and full blocks. The plane must have
  // an even number of columns. Use the ncvisual rotation for a more
  // flexible approach.
  int rotateCW() {
    return nc.ncplane_rotate_cw(_ptr);
  }

  // Rotate the plane π/2 radians counterclockwise. This cannot
  // be performed on arbitrary planes, because glyphs cannot be arbitrarily
  // rotated. The glyphs which can be rotated are limited: line-drawing
  // characters, spaces, half blocks, and full blocks. The plane must have
  // an even number of columns. Use the ncvisual rotation for a more
  // flexible approach.
  int rotateCCW() {
    return nc.ncplane_rotate_ccw(_ptr);
  }

  // Change the name of 't'. Returns -1 if 'newname' is NULL, and 0 otherwise.
  bool setName(String name) {
    final n = name.toNativeUtf8().cast<ffi.Int8>();
    final rc = nc.ncplane_set_name(_ptr, n) != 0;
    allocator.free(n);
    return rc;
  }

  /// Return a heap-allocated copy of the plane's name, or NULL if it has none.
  String? name() {
    final i8 = nc.ncplane_name(_ptr);
    if (i8 == ffi.nullptr) return null;

    final rc = i8.cast<Utf8>().toDartString();
    allocator.free(i8);
    return rc;
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
