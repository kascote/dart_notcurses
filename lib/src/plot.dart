import 'dart:ffi';

import 'package:ffi/ffi.dart';

import './channels.dart';
import './ffi/memory.dart';
import './ffi/notcurses_g.dart';
import './load_library.dart';
import './plane.dart';

class PlotOptions {
  late int miny;
  late int maxy;
  late Channels? minchannels;
  late Channels? maxchannels;
  late int legendstyle;
  late int gridtype;
  late int rangex;
  late String title;
  late int flags;

  PlotOptions({
    this.miny = 0,
    this.maxy = 0,

    /// channels for the minimum levels. linear or exponential
    /// interpolation will be applied across the domain between these two.
    this.minchannels,

    /// channels for the maximum levels. linear or exponential
    /// interpolation will be applied across the domain between these two.
    this.maxchannels,

    /// styling used for the legend, if NCPLOT_OPTION_LABELTICKSD is set
    this.legendstyle = 0,

    /// if you don't care, pass NCBLIT_DEFAULT and get NCBLIT_8x1 (assuming
    /// UTF8) or NCBLIT_1x1 (in an ASCII environment)
    this.gridtype = 0,

    /// independent variable can either be a contiguous range, or a finite set
    /// of keys. for a time range, say the previous hour sampled with second
    /// resolution, the independent variable would be the range [0..3600): 3600.
    /// if rangex is 0, it is dynamically set to the number of columns.
    this.rangex = 0,

    /// optional, printed by the labels
    this.title = '',

    /// bitfield over NCPLOT_OPTION_*
    this.flags = 0,
  });
}

class Plot {
  final Pointer<ncuplot> _ptr;

  Plot._(this._ptr);

  static Plot? create(Plane plane, PlotOptions po) {
    final optsPtr = allocator<ncplot_options>();
    final opts = optsPtr.ref;
    opts.maxchannels = po.maxchannels == null ? 0 : po.maxchannels!.value;
    opts.minchannels = po.minchannels == null ? 0 : po.minchannels!.value;
    opts.legendstyle = po.legendstyle;
    opts.gridtype = po.gridtype;
    opts.rangex = po.rangex;
    opts.flags = po.flags;
    opts.title = po.title.toNativeUtf8().cast<Int8>();

    final p = Plot._(nc.ncuplot_create(plane.ptr, optsPtr, po.miny, po.maxy));
    allocator.free(opts.title);
    allocator.free(optsPtr);

    if (p._ptr == nullptr) {
      return null;
    }

    return p;
  }

  /// Returns the plane for this plot
  Plane plane() {
    return Plane.fromPtr(nc.ncuplot_plane(_ptr));
  }

  /// Add the value corresponding to this x. If x is beyond the current
  /// x window, the x window is advanced to include x, and values passing beyond
  /// the window are lost. The first call will place the initial window. The plot
  /// will be redrawn, but notcurses_render() is not called.
  int addSample(int x, int y) {
    return nc.ncuplot_add_sample(_ptr, x, y);
  }

  /// Replace the value corresponding to this x. If x is beyond the current
  /// x window, the x window is advanced to include x, and values passing beyond
  /// the window are lost. The first call will place the initial window. The plot
  /// will be redrawn, but notcurses_render() is not called.
  void setSample(int x, int y) {
    nc.ncuplot_set_sample(_ptr, x, y);
  }

  /// Allo retrieval of sample data
  int? sample(int x, int y) {
    return using<int?>((Arena alloc) {
      final yPtr = alloc<Uint64>();
      yPtr.value = y;
      if (nc.ncuplot_sample(_ptr, x, yPtr) < 0) return null;
      return yPtr.value;
    });
  }

  /// Release the memory associated with this plot
  void destroy() {
    if (_ptr != nullptr) {
      nc.ncuplot_destroy(_ptr);
    }
  }
}
