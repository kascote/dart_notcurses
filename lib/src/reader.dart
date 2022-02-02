import 'dart:ffi' as ffi;

import 'package:ffi/ffi.dart';

import './ffi/memory.dart';
import './ffi/notcurses_g.dart';
import './key.dart';
import './load_library.dart';
import './plane.dart';

class ReaderOptions {
  int channels;

  /// StyleMask
  int attrWord;

  /// NcReaderOptions
  int flags;

  ReaderOptions(this.channels, this.attrWord, this.flags);
}

class Reader {
  final ffi.Pointer<ncreader> _ptr;

  Reader._(this._ptr);

  /// ncreaders provide freeform input in a (possibly multiline) region, supporting
  /// optional readline keybindings. takes ownership of 'n', destroying it on any
  /// error (ncreader_destroy() otherwise destroys the ncplane).
  factory Reader.create(Plane plane, ReaderOptions opts) {
    final op = allocator<ncreader_options>();
    op.ref
      ..tchannels = opts.channels
      ..tattrword = opts.attrWord
      ..flags = opts.flags;
    return Reader._(nc.ncreader_create(plane.ptr, op));
  }

  String destroy() {
    final contents = allocator<ffi.Pointer<ffi.Int8>>();
    nc.ncreader_destroy(_ptr, contents);
    final rc = contents.value.cast<Utf8>().toDartString();
    allocator.free(contents);
    return rc;
  }

  /// empty the ncreader of any user input, and home the cursor.
  int clear() {
    return nc.ncreader_clear(_ptr);
  }

  Plane readerPlane() {
    return Plane(nc.ncreader_plane(_ptr));
  }

  /// Atttempt to move in the specified direction. Returns 0 if a move was
  /// successfully executed, -1 otherwise. Scrolling is taken into account.
  bool moveLeft() {
    return nc.ncreader_move_left(_ptr) == 0;
  }

  /// Atttempt to move in the specified direction. Returns 0 if a move was
  /// successfully executed, -1 otherwise. Scrolling is taken into account.
  bool moveRight() {
    return nc.ncreader_move_right(_ptr) == 0;
  }

  /// Atttempt to move in the specified direction. Returns 0 if a move was
  /// successfully executed, -1 otherwise. Scrolling is taken into account.
  bool moveUp() {
    return nc.ncreader_move_up(_ptr) == 0;
  }

  /// Atttempt to move in the specified direction. Returns 0 if a move was
  /// successfully executed, -1 otherwise. Scrolling is taken into account.
  bool moveDown() {
    return nc.ncreader_move_down(_ptr) == 0;
  }

  /// Destructively write the provided EGC to the current cursor location. Move
  /// the cursor as necessary, scrolling if applicable.
  bool writeEgc(String value) {
    final ugc = value.toNativeUtf8().cast<ffi.Int8>();
    final rc = nc.ncreader_write_egc(_ptr, ugc);
    allocator.free(ugc);
    return rc == 0;
  }

  /// Offer the input to the ncreader. If it's relevant, this function returns
  /// true, and the input ought not be processed further. Almost all inputs
  /// are relevant to an ncreader, save synthesized ones.
  bool offerInput(Key key) {
    return nc.ncreader_offer_input(_ptr, key.ptr) != 0;
  }

  String contents() {
    final egc = nc.ncreader_contents(_ptr);
    return egc.cast<Utf8>().toDartString();
  }
}
