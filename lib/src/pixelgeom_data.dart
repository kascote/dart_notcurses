import 'dart:ffi';

import 'package:ffi/ffi.dart';

import './load_library.dart';
import './plane.dart';

class NcPixelGeomData {
  late final int _pxy;
  late final int _pxx;
  late final int _celldimy;
  late final int _celldimx;
  late final int _maxbmapy;
  late final int _maxbmapx;

  NcPixelGeomData(
    Plane plane, {
    bool pxy = false,
    bool pxx = false,
    bool celldimy = false,
    bool celldimx = false,
    bool maxbmapy = false,
    bool maxbmapx = false,
  }) {
    using((Arena alloc) {
      final __pxy = pxy ? alloc<Uint32>() : nullptr;
      final __pxx = pxx ? alloc<Uint32>() : nullptr;
      final __celldimy = celldimy ? alloc<Uint32>() : nullptr;
      final __celldimx = celldimx ? alloc<Uint32>() : nullptr;
      final __maxbmapy = maxbmapy ? alloc<Uint32>() : nullptr;
      final __maxbmapx = maxbmapx ? alloc<Uint32>() : nullptr;

      nc.ncplane_pixel_geom(plane.ptr, __pxy, __pxx, __celldimy, __celldimx, __maxbmapy, __maxbmapx);

      _pxy = pxy ? __pxy.value : -1;
      _pxx = pxx ? __pxx.value : -1;
      _celldimy = celldimy ? __celldimy.value : -1;
      _celldimx = celldimx ? __celldimx.value : -1;
      _maxbmapy = maxbmapy ? __maxbmapy.value : -1;
      _maxbmapx = maxbmapx ? __maxbmapx.value : -1;
    });
  }

  int get pxy => _pxy;
  int get pxx => _pxx;
  int get celldimy => _celldimy;
  int get celldimx => _celldimx;
  int get maxbmapy => _maxbmapy;
  int get maxbmapx => _maxbmapx;
}
