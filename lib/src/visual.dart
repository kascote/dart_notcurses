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

class Visual {
  final ffi.Pointer<ncvisual> _ptr;

  Visual._(this._ptr);

  factory Visual.fromFile(String path) {
    final i8 = path.toNativeUtf8().cast<ffi.Int8>();
    final v = nc.ncvisual_from_file(i8);
    allocator.free(i8);
    return Visual._(v);
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

  void destroy() {
    nc.ncvisual_destroy(_ptr);
  }

  bool initialized() {
    return _ptr != ffi.nullptr;
  }

  /// Scale the visual to 'rows' X 'columns' pixels, using the best scheme
  /// available. This is a lossy transformation, unless the size is unchanged.
  int resize(int rows, int cols) {
    return nc.ncvisual_resize(_ptr, rows, cols);
  }

  NcResult<bool, Plane?> blit(NotCurses notc, VisualOptions opts) {
    final optsPtr = _optsPtr(opts);
    final planePtr = nc.ncvisual_blit(notc.ptr, _ptr, optsPtr);
    if (planePtr == ffi.nullptr) {
      allocator.free(optsPtr);
      return NcResult(false, null);
    }
    final p = Plane(planePtr);
    allocator.free(optsPtr);
    return NcResult(true, p);
  }

  ffi.Pointer<ncvisual_options> _optsPtr(VisualOptions opts) {
    final optsPtr = allocator<ncvisual_options>();
    final optsRef = optsPtr.ref;
    if (opts.y != null) optsRef.y = opts.y!;
    if (opts.x != null) optsRef.x = opts.x!;
    if (opts.begy != null) optsRef.begy = opts.begy!;
    if (opts.begx != null) optsRef.begx = opts.begx!;
    if (opts.leny != null) optsRef.leny = opts.leny!;
    if (opts.lenx != null) optsRef.lenx = opts.lenx!;
    if (opts.blitter != null) optsRef.blitter = opts.blitter!;
    if (opts.flags != null) optsRef.flags = opts.flags!;
    if (opts.transcolor != null) optsRef.transcolor = opts.transcolor!;
    if (opts.pxoffy != null) optsRef.pxoffy = opts.pxoffy!;
    if (opts.pxoffx != null) optsRef.pxoffx = opts.pxoffx!;
    if (opts.plane != null && opts.plane!.ptr != ffi.nullptr) optsRef.n = opts.plane!.ptr;

    return optsPtr;
  }
}
