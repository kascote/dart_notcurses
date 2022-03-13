import 'dart:ffi' as ffi;
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import './ffi/memory.dart';
import './ffi/notcurses_g.dart';
import './load_library.dart';
import './notcurses.dart';
import './plane.dart';
import './shared.dart';

class VisualOptions {
  // if no ncplane is provided, one will be created using the exact size
  // necessary to render the source with perfect fidelity (this might be
  // smaller or larger than the rendering area). if NCVISUAL_OPTION_CHILDPLANE
  // is provided, this must be non-NULL, and will be interpreted as the parent.
  Plane? plane;
  // the scaling is ignored if no ncplane is provided (it ought be NCSCALE_NONE
  // in this case). otherwise, the source is stretched/scaled relative to the
  // provided ncplane.
  int? scaling;
  // if an ncplane is provided, y and x specify where the visual will be
  // rendered on that plane. otherwise, they specify where the created ncplane
  // will be placed relative to the standard plane's origin. x is an ncalign_e
  // value if NCVISUAL_OPTION_HORALIGNED is provided. y is an ncalign_e if
  // NCVISUAL_OPTION_VERALIGNED is provided.
  int? y;
  int? x;
  // the region of the visual that ought be rendered. for the entire visual,
  // pass an origin of 0, 0 and a size of 0, 0 (or the true height and width).
  // these numbers are all in terms of ncvisual pixels. negative values are
  // prohibited.
  int? begy;
  int? begx; // origin of rendered region in pixels
  int? leny;
  int? lenx; // size of rendered region in pixels
  // use NCBLIT_DEFAULT if you don't care, an appropriate blitter will be
  // chosen for your terminal, given your scaling. NCBLIT_PIXEL is never
  // chosen for NCBLIT_DEFAULT.
  int? blitter; // glyph set to use (maps input to output cells)
  int? flags; // bitmask over NCVISUAL_OPTION_*
  int? transcolor; // treat this color as transparent under NCVISUAL_OPTION_ADDALPHA
  // pixel offsets within the cell. if NCBLIT_PIXEL is used, the bitmap will
  // be drawn offset from the upper-left cell's origin by these amounts. it is
  // an error if either number exceeds the cell-pixel geometry in its
  // dimension. if NCBLIT_PIXEL is not used, these fields are ignored.
  // this functionality can be used for smooth bitmap movement.
  int? pxoffy;
  int? pxoffx;

  VisualOptions({
    this.plane,
    this.scaling,
    this.y,
    this.x,
    this.begy,
    this.begx,
    this.leny,
    this.lenx,
    this.blitter,
    this.flags,
    this.transcolor,
    this.pxoffy,
    this.pxoffx,
  });

  /// return a pointer to the Visual Options
  /// take care, this pointer must be deallocated
  /// this function is intented to be used only from the api
  //TODO: hide this
  ffi.Pointer<ncvisual_options> toPtr([ffi.Allocator alloc = allocator]) {
    final optsPtr = alloc<ncvisual_options>();
    final optsRef = optsPtr.ref;
    if (y != null) optsRef.y = y!;
    if (x != null) optsRef.x = x!;
    if (begy != null) optsRef.begy = begy!;
    if (begx != null) optsRef.begx = begx!;
    if (leny != null) optsRef.leny = leny!;
    if (lenx != null) optsRef.lenx = lenx!;
    if (blitter != null) optsRef.blitter = blitter!;
    if (flags != null) optsRef.flags = flags!;
    if (transcolor != null) optsRef.transcolor = transcolor!;
    if (pxoffy != null) optsRef.pxoffy = pxoffy!;
    if (pxoffx != null) optsRef.pxoffx = pxoffx!;
    if (scaling != null) optsRef.scaling = scaling!;
    if (plane != null && plane!.ptr != ffi.nullptr) optsRef.n = plane!.ptr;

    return optsPtr;
  }

  @override
  String toString() {
    print(' plane: $plane');
    print(' scaling: $scaling');
    print(' y: $y');
    print(' x: $x');
    print(' begy: $begy');
    print(' begx: $begx');
    print(' leny: $lenx');
    print(' blitter: $blitter');
    print(' flags: $flags');
    print(' transcolor: $transcolor');
    print(' pxoffy: $pxoffy');
    print(' pxoffx: $pxoffx');
    return super.toString();
  }
}

/// describes all geometries of an ncvisual: those which are inherent, and those
/// dependent upon a given rendering regime. pixy and pixx are the true internal
/// pixel geometry, taken directly from the load (and updated by
/// ncvisual_resize()). cdimy/cdimx are the cell-pixel geometry *at the time
/// of this call* (it can change with a font change, in which case all values
/// other than pixy/pixx are invalidated). rpixy/rpixx are the pixel geometry as
/// handed to the blitter, following any scaling. scaley/scalex are the number
/// of input pixels drawn to a single cell; when using NCBLIT_PIXEL, they are
/// equivalent to cdimy/cdimx. rcelly/rcellx are the cell geometry as written by
/// the blitter, following any padding (there is padding whenever rpix{y, x} is
/// not evenly divided by scale{y, x}, and also sometimes for Sixel).
/// maxpixely/maxpixelx are defined only when NCBLIT_PIXEL is used, and specify
/// the largest bitmap that the terminal is willing to accept. blitter is the
/// blitter which will be used, a function of the requested blitter and the
/// blitters actually supported by this environment. if no ncvisual was
/// supplied, only cdimy/cdimx are filled in.
class VisualGeom {
  int? pixy; // true pixel geometry of ncvisual data
  int? pixx;
  int? cdimy; // terminal cell geometry when this was calculated
  int? cdimx;
  int? rpixy; // rendered pixel geometry (per visual_options)
  int? rpixx;
  int? rcelly; // rendered cell geometry (per visual_options)
  int? rcellx;
  int? scaley; // source pixels per filled cell
  int? scalex;
  int? begy; // upper-left corner of used region
  int? begx;
  int? leny; // geometry of used region
  int? lenx;
  int? maxpixely;
  int? maxpixelx; // only defined for NCBLIT_PIXEL
  int? blitter;

  VisualGeom({
    int pixy = 0,
    int pixx = 0,
    int cdimy = 0,
    int cdimx = 0,
    int rpixy = 0,
    int rpixx = 0,
    int rcelly = 0,
    int rcellx = 0,
    int scaley = 0,
    int scalex = 0,
    int begy = 0,
    int begx = 0,
    int leny = 0,
    int lenx = 0,
    int maxpixely = 0,
    int maxpixelx = 0,
    int blitter = 0,
  });

  VisualGeom.fromPtr(ffi.Pointer<ncvgeom> geom) {
    final _g = geom.ref;
    pixy = _g.pixy;
    pixx = _g.pixx;
    cdimy = _g.cdimy;
    cdimx = _g.cdimx;
    rpixy = _g.rpixy;
    rpixx = _g.rpixx;
    rcelly = _g.rcelly;
    rcellx = _g.rcellx;
    scaley = _g.scaley;
    scalex = _g.scalex;
    begy = _g.begy;
    begx = _g.begx;
    leny = _g.leny;
    lenx = _g.lenx;
    maxpixely = _g.maxpixely;
    maxpixelx = _g.maxpixelx;
    blitter = _g.blitter;
  }
}

class Visual {
  final ffi.Pointer<ncvisual> _ptr;

  Visual._(this._ptr);

  /// Open a visual at 'file', extract a codec and parameters, decode the first
  /// image to memory.
  factory Visual.fromFile(String path) {
    final i8 = path.toNativeUtf8().cast<ffi.Int8>();
    final v = nc.ncvisual_from_file(i8);
    allocator.free(i8);
    return Visual._(v);
  }

  factory Visual.fromPtr(ffi.Pointer<ncvisual> vptr) {
    return Visual._(vptr);
  }

  /// Prepare an ncvisual, and its underlying plane, based off RGBA content in
  /// memory at 'rgba'. 'rgba' is laid out as 'rows' lines, each of which is
  /// 'rowstride' bytes in length. Each line has 'cols' 32-bit 8bpc RGBA pixels
  /// followed by possible padding (there will be 'rowstride' - 'cols' * 4 bytes
  /// of padding). The total size of 'rgba' is thus (rows * rowstride) bytes, of
  /// which (rows * cols * 4) bytes are actual non-padding data.
  factory Visual.fromRGBA(Uint8List rgba, int rows, int rowstride, int cols) {
    final pRgba = allocator<ffi.Uint8>(rgba.length);
    for (var i = 0; i < rgba.length; i++) {
      pRgba[i] = rgba[i];
    }
    final rc = Visual._(nc.ncvisual_from_rgba(pRgba.cast(), rows, rowstride, cols));
    allocator.free(pRgba);
    return rc;
  }

  /// ncvisual_from_rgba(), but the pixels are 3-byte RGB. A is filled in
  /// throughout using 'alpha'.
  factory Visual.fromRgbPacked(Uint8List rgb, int rows, int rowstride, int cols, int alpha) {
    final pRgb = allocator<ffi.Uint8>(rgb.length);
    for (var i = 0; i < rgb.length; i++) {
      pRgb[i] = rgb[i];
    }
    final rc = Visual._(nc.ncvisual_from_rgb_packed(pRgb.cast(), rows, rowstride, cols, alpha));
    allocator.free(pRgb);
    return rc;
  }

  /// ncvisual_from_rgba(), but the pixels are 4-byte RGBx. A is filled in
  /// throughout using 'alpha'. rowstride must be a multiple of 4.
  factory Visual.fromRgbLoose(Uint8List rgba, int rows, int rowstride, int cols, int alpha) {
    final pRgb = allocator<ffi.Uint8>(rgba.length);
    for (var i = 0; i < rgba.length; i++) {
      pRgb[i] = rgba[i];
    }
    final rc = Visual._(nc.ncvisual_from_rgb_loose(pRgb.cast(), rows, rowstride, cols, alpha));
    allocator.free(pRgb);
    return rc;
  }

  /// ncvisual_from_rgba(), but 'bgra' is arranged as BGRA. note that this is a
  /// byte-oriented layout, despite being bunched in 32-bit pixels; the lowest
  /// memory address ought be B, and A is reached by adding 3 to that address.
  factory Visual.fromBgra(Uint8List bgra, int rows, int rowstride, int cols) {
    final pRgb = allocator<ffi.Uint8>(bgra.length);
    for (var i = 0; i < bgra.length; i++) {
      pRgb[i] = bgra[i];
    }
    final rc = Visual._(nc.ncvisual_from_bgra(pRgb.cast(), rows, rowstride, cols));
    allocator.free(pRgb);
    return rc;
  }

  /// ncvisual_from_rgba(), but 'data' is 'pstride'-byte palette-indexed pixels,
  /// arranged in 'rows' lines of 'rowstride' bytes each, composed of 'cols'
  /// pixels. 'palette' is an array of at least 'palsize' ncchannels.
  factory Visual.fromPalidx(
      Uint8List data, int rows, int rowstride, int cols, int palsize, int palstride, Uint32List palette) {
    final pRgb = allocator<ffi.Uint8>(data.length);
    for (var i = 0; i < data.length; i++) {
      pRgb[i] = data[i];
    }
    final pltte = allocator<ffi.Uint32>(palette.length);
    for (var i = 0; i < palette.length; i++) {
      pltte[i] = palette[i];
    }

    final rc = Visual._(nc.ncvisual_from_palidx(pRgb.cast(), rows, rowstride, cols, palsize, palstride, pltte));
    allocator.free(pRgb);
    allocator.free(pltte);
    return rc;
  }

  /// Promote an ncplane 'n' to an ncvisual. The plane may contain only spaces,
  /// half blocks, and full blocks. The latter will be checked, and any other
  /// glyph will result in a NULL being returned. This function exists so that
  /// planes can be subjected to ncvisual transformations. If possible, it's
  /// better to create the ncvisual from memory using ncvisual_from_rgba().
  /// Lengths of 0 are interpreted to mean "all available remaining area".
  factory Visual.fromPlane(Plane plane, int blit, int begy, int begx, int leny, int lenx) {
    return Visual._(nc.ncvisual_from_plane(plane.ptr, blit, begy, begx, leny, lenx));
  }

  /// Construct an ncvisual from a nul-terminated Sixel control sequence.
  factory Visual.fromSizel(String sixel, int leny, int lenx) {
    final i8 = sixel.toNativeUtf8().cast<ffi.Int8>();
    final rc = nc.ncvisual_from_sixel(i8, leny, lenx);
    allocator.free(i8);
    return Visual._(rc);
  }

  void destroy() {
    nc.ncvisual_destroy(_ptr);
  }

  bool get initialized => _ptr != ffi.nullptr;
  bool get notInitialized => _ptr == ffi.nullptr;

  ffi.Pointer<ncvisual> get ptr => _ptr;

  /// Scale the visual to 'rows' X 'columns' pixels, using the best scheme
  /// available. This is a lossy transformation, unless the size is unchanged.
  bool resize(int rows, int cols) {
    return nc.ncvisual_resize(_ptr, rows, cols) == 0;
  }

  /// Render the decoded frame according to the provided options (which may be
  /// NULL). The plane used for rendering depends on vopts->n and vopts->flags.
  /// If NCVISUAL_OPTION_CHILDPLANE is set, vopts->n must not be NULL, and the
  /// plane will always be created as a child of vopts->n. If this flag is not
  /// set, and vopts->n is NULL, a new plane is created as root of a new pile.
  /// If the flag is not set and vopts->n is not NULL, we render to vopts->n.
  /// A subregion of the visual can be rendered using 'begx', 'begy', 'lenx', and
  /// 'leny'. Negative values for any of these are an error. It is an error to
  /// specify any region beyond the boundaries of the frame. Returns the (possibly
  /// newly-created) plane to which we drew. Pixels may not be blitted to the
  /// standard plane.
  Plane? blit(NotCurses notc, VisualOptions opts) {
    final optsPtr = opts.toPtr();
    final planePtr = nc.ncvisual_blit(notc.ptr, _ptr, optsPtr);
    allocator.free(optsPtr);
    if (planePtr == ffi.nullptr) return null;

    final p = Plane.fromPtr(planePtr);
    return p;
  }

  /// Scale the visual to 'rows' X 'columns' pixels, using non-interpolative
  /// (naive) scaling. No new colors will be introduced as a result.
  bool reisizeNonInterpolative(int rows, int cols) {
    return nc.ncvisual_resize_noninterpolative(_ptr, rows, cols) == 0;
  }

  /// all-purpose ncvisual geometry solver. one or both of 'nc' and 'n' must be
  /// non-NULL. if 'nc' is NULL, only pixy/pixx will be filled in, with the true
  /// pixel geometry of 'n'. if 'n' is NULL, only cdimy/cdimx, blitter,
  /// scaley/scalex, and maxpixely/maxpixelx are filled in. cdimy/cdimx and
  /// maxpixely/maxpixelx are only ever filled in if we know them.
  VisualGeom? geom(NotCurses notc, VisualOptions vopts) {
    return using<VisualGeom?>((Arena alloc) {
      final _vopts = vopts.toPtr(alloc);
      final _geom = alloc<ncvgeom>();
      final rc = nc.ncvisual_geom(notc.ptr, _ptr, _vopts, _geom);
      if (rc < 0) return null;

      final vgeom = VisualGeom.fromPtr(_geom);
      return vgeom;
    });
  }

  /// extract the next frame from an ncvisual. returns 1 on end of file, 0 on
  /// success, and -1 on failure.
  int decode() {
    return nc.ncvisual_decode(_ptr);
  }

  /// decode the next frame ala ncvisual_decode(), but if we have reached the end,
  /// rewind to the first frame of the ncvisual. a subsequent 'ncvisual_blit()'
  /// will render the first frame, as if the ncvisual had been closed and reopened.
  /// the return values remain the same as those of ncvisual_decode().
  int decodeLoop() {
    return nc.ncvisual_decode_loop(_ptr);
  }

  /// Rotate the visual 'rads' radians. Only M_PI/2 and -M_PI/2 are supported at
  /// the moment, but this might change in the future.
  bool rotate(double rads) {
    return nc.ncvisual_rotate(_ptr, rads) == 0;
  }

  /// Polyfill at the specified location within the ncvisual 'n', using 'rgba'.
  bool polyfillYX(int y, int x, int rgba) {
    return nc.ncvisual_polyfill_yx(_ptr, y, x, rgba) > 0;
  }

  /// Get the specified pixel from the specified ncvisual.
  int? atYX(int y, int x) {
    return using<int?>((Arena alloc) {
      final pixel = alloc<ffi.Uint32>();
      final rc = nc.ncvisual_at_yx(_ptr, y, x, pixel);
      if (rc < 0) return null;
      return pixel.value;
    });
  }

  /// Set the specified pixel in the specified ncvisual.
  bool setYX(int y, int x, int pixel) {
    return nc.ncvisual_set_yx(_ptr, y, x, pixel) == 0;
  }

  /// Create a new plane as prescribed in opts, either as a child of 'vopts->n',
  /// or the root of a new pile if 'vopts->n' is NULL (or 'vopts' itself is NULL).
  /// Blit 'ncv' to the created plane according to 'vopts'. If 'vopts->n' is
  /// non-NULL, NCVISUAL_OPTION_CHILDPLANE must be supplied.
  Plane planeCreate(NotCurses notc, PlaneOptions opts, VisualOptions vopts) {
    return using<Plane>((Arena alloc) {
      final vptr = vopts.toPtr(alloc);
      final pptr = opts.toPtr(alloc);
      final p = Plane.fromPtr(ncInline.ncvisualplane_create(notc.ptr, pptr, _ptr, vptr));
      return p;
    });
  }
}
