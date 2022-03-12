import 'dart:ffi';

import 'package:ffi/ffi.dart';

import './extensions/int.dart';
import './ffi/memory.dart';
import './load_library.dart';

class RGB {
  final int r, g, b;
  const RGB(this.r, this.g, this.b);

  RGB copyWith({int? r, int? g, int? b}) {
    return RGB(
      r ?? this.r,
      g ?? this.g,
      b ?? this.b,
    );
  }

  @override
  String toString() {
    return 'RGB: $r/${r.toStrHex()} $g/${g.toStrHex()} $b/${b.toStrHex()}';
  }
}

// Does this glyph completely obscure the background? If so, there's no need
// to emit a background when rasterizing, a small optimization. These are
// also used to track regions into which we must not cellblit.
const int NC_NOBACKGROUND_MASK = 0x8700000000000000;
// if this bit is set, we are *not* using the default background color
const int NC_BGDEFAULT_MASK = 0x0000000040000000;
// extract these bits to get the background RGB value
const int NC_BG_RGB_MASK = 0x0000000000ffffff;
// if this bit *and* NC_BGDEFAULT_MASK are set, we're using a
// palette-indexed background color
const int NC_BG_PALETTE = 0x0000000008000000;
// extract these bits to get the background alpha mask
const int NC_BG_ALPHA_MASK = 0x30000000;

class Channels {
  int _value;

  Channels._(this._value);

  int get value => _value;

  /// initialize a 64-bit channel pair with specified RGB fg/bg
  factory Channels.initializer(int fr, int fg, int fb, int br, int bg, int bb) {
    return Channels._((Channel.initializer(fr, fg, fb).value << 32) + (Channel.initializer(br, bg, bb).value));
  }

  /// Initialize a 64-bit channel pair but only the BG
  factory Channels.initializerBg(int br, int bg, int bb) {
    return Channels._((Channel.initializer(br, bg, bb).value));
  }

  /// Initialize a 64-bit channel pair but only the FG
  factory Channels.initializerFg(int br, int bg, int bb) {
    return Channels._((Channel.initializer(br, bg, bb).value) << 32);
  }

  factory Channels.from(int value) {
    return Channels._(value);
  }

  factory Channels.zero() {
    return Channels._(0);
  }

  /// Creates a new channel pair using 'fchan' as the foreground channel
  /// and 'bchan' as the background channel.
  factory Channels.combine(Channel fchan, Channel bchan) {
    return Channels._(ncInline.ncchannels_combine(fchan.value, bchan.value));
  }

  /// Extract the 32-bit background channel from a channel pair.
  int bchannel() {
    return ncInline.ncchannels_bchannel(_value);
  }

  /// Extract the 32-bit foreground channel from a channel pair.
  int fchannel() {
    return ncInline.ncchannels_fchannel(_value);
  }

  /// Set the r, g, and b channels for the foreground component of this 64-bit
  /// 'channels' variable, and mark it as not using the default color.
  bool setFgRGB8(int r, int g, int b) {
    final chn = allocator<Uint64>();
    chn.value = _value;
    final rc = ncInline.ncchannels_set_fg_rgb8(chn, r, g, b);
    _value = chn.value;
    allocator.free(chn);
    return rc == 0;
  }

  /// Set the r, g, and b channels for the background component of this 64-bit
  /// 'channels' variable, and mark it as not using the default color.
  bool setBgRGB8(int r, int g, int b) {
    final chn = allocator<Uint64>();
    chn.value = _value;
    final rc = ncInline.ncchannels_set_bg_rgb8(chn, r, g, b);
    _value = chn.value;
    allocator.free(chn);
    return rc == 0;
  }

  /// Set an assembled 24 bit channel at once.
  bool setFgRGB(int rgb) {
    final chn = allocator<Uint64>();
    chn.value = _value;
    final rc = ncInline.ncchannels_set_fg_rgb(chn, rgb);
    _value = chn.value;
    allocator.free(chn);
    return rc == 0;
  }

  /// assembled 24-bit RGB value. A value over 0xffffff
  /// will be rejected, with a non-zero return value.
  bool setBgRGB(int rgb) {
    final chn = allocator<Uint64>();
    chn.value = _value;
    final rc = ncInline.ncchannels_set_bg_rgb(chn, rgb);
    _value = chn.value;
    allocator.free(chn);
    return rc == 0;
  }

  /// Extract 24 bits of foreground RGB from 'channels', split into subchannels.
  RGB fgRGB8() {
    return using<RGB>((Arena alloc) {
      final r = alloc<Uint32>();
      final g = alloc<Uint32>();
      final b = alloc<Uint32>();

      ncInline.ncchannels_fg_rgb8(_value, r, g, b);
      return RGB(r.value, g.value, b.value);
    });
  }

  /// Extract 24 bits of background RGB from 'channels', split into subchannels.
  RGB bgRGB8() {
    return using<RGB>((Arena alloc) {
      final r = alloc<Uint32>();
      final g = alloc<Uint32>();
      final b = alloc<Uint32>();
      ncInline.ncchannels_bg_rgb8(_value, r, g, b);
      return RGB(r.value, g.value, b.value);
    });
  }

  /// Extract 24 bits of foreground RGB from 'channels', shifted to LSBs.
  int fgRGB() {
    return ncInline.ncchannels_fg_rgb(_value);
  }

  /// Extract 24 bits of background RGB from 'channels', shifted to LSBs.
  int bgRGB() {
    return ncInline.ncchannels_bg_rgb(_value);
  }

  /// Estract palette index foreground color
  int fgPalindex() {
    return ncInline.ncchannels_fg_palindex(_value);
  }

  /// Estract palette index background color
  int bgPalindex() {
    return ncInline.ncchannels_bg_palindex(_value);
  }

  /// Set the cell's foreground palette index, set the foreground palette index
  /// bit, set it foreground-opaque, and clear the foreground default color bit.
  bool setFgPalindex(int ndx) {
    final chn = allocator<Uint64>();
    chn.value = _value;
    final rc = ncInline.ncchannels_set_fg_palindex(chn, ndx);
    _value = chn.value;
    allocator.free(chn);
    return rc == 0;
  }

  /// Set the cell's background palette index, set the background palette index
  /// bit, set it background-opaque, and clear the background default color bit.
  bool setBgPalindex(int ndx) {
    final chn = allocator<Uint64>();
    chn.value = _value;
    final rc = ncInline.ncchannels_set_bg_palindex(chn, ndx);
    _value = chn.value;
    allocator.free(chn);
    return rc == 0;
  }

  /// Set the 2-bit alpha component of the foreground channel.
  bool setFgAlpha(int alpha) {
    final chn = allocator<Uint64>();
    chn.value = _value;
    final rc = ncInline.ncchannels_set_fg_alpha(chn, alpha);
    _value = chn.value;
    allocator.free(chn);
    return rc == 0;
  }

  /// Set the 2-bit alpha component of the background channel.
  bool setBgAlpha(int alpha) {
    final chn = allocator<Uint64>();
    chn.value = _value;
    final rc = ncInline.ncchannels_set_bg_alpha(chn, alpha);
    _value = chn.value;
    allocator.free(chn);
    return rc == 0;
  }

  /// Extract 2 bits of foreground alpha from 'channels', shifted to LSBs.
  int fgAlpha() {
    return ncInline.ncchannels_fg_alpha(_value);
  }

  /// Extract 2 bits of background alpha from 'cl', shifted to LSBs.
  int bgAlpha() {
    return ncInline.ncchannels_bg_alpha(_value);
  }

  /// Mark the background channel as using its default color.
  void setBgDefault() {
    final chn = allocator<Uint64>();
    chn.value = _value;
    ncInline.ncchannels_set_bg_default(chn);
    _value = chn.value;
    allocator.free(chn);
  }

  /// Mark the foreground channel as using its default color.
  void setFgDefault() {
    final chn = allocator<Uint64>();
    chn.value = _value;
    ncInline.ncchannels_set_fg_default(chn);
    _value = chn.value;
    allocator.free(chn);
  }

  /// Returns the channels with the fore- and background's color information
  /// swapped, but without touching housekeeping bits. Alpha is retained unless
  /// it would lead to an illegal state: HIGHCONTRAST, TRANSPARENT, and BLEND
  /// are taken to OPAQUE unless the new value is RGB.
  int reverse() {
    return ncInline.ncchannels_reverse(_value);
  }

  /// Set the alpha and coloring bits of a channel pair from another channel pair.
  void setChannels(int channel) {
    final chn = allocator<Uint64>();
    chn.value = _value;
    ncInline.ncchannels_set_channels(chn, channel);
    _value == chn.value;
    allocator.free(chn);
  }

  /// Extract the background alpha and coloring bits from a 64-bit channel pair.
  int channels() {
    return ncInline.ncchannels_channels(_value);
  }
}

class Channel {
  int _value;
  Channel._(this._value);
  int get value => _value;

  /// initialize a 32-bit channel pair with specified RGB
  factory Channel.initializer(int r, int g, int b) {
    return Channel._((r << 16) + (g << 8) + b + NC_BGDEFAULT_MASK);
  }

  /// Extract the 8-bit red component from a 32-bit channel. Only valid if
  /// ncchannel_rgb_p() would return true for the channel.
  int get r => ncInline.ncchannel_r(_value);

  /// Extract the 8-bit green component from a 32-bit channel. Only valid if
  /// ncchannel_rgb_p() would return true for the channel.
  int get g => ncInline.ncchannel_g(_value);

  /// Extract the 8-bit blue component from a 32-bit channel. Only valid if
  /// ncchannel_rgb_p() would return true for the channel.
  int get b => ncInline.ncchannel_b(_value);

  /// Extract the 24-bit RGB value from a 32-bit channel.
  /// Only valid if ncchannel_rgb_p() would return true for the channel.
  int get rgb => ncInline.ncchannel_rgb(_value);

  /// Is this channel using the "default color" rather than RGB/palette-indexed?
  bool get isUsingDefault => ncInline.ncchannel_default_p(_value) != 0;

  /// Is this channel using palette-indexed color?
  bool get isUsingPalindex => ncInline.ncchannel_palindex_p(_value) != 0;

  /// Is this channel using RGB color?
  bool get isUsingRGB => ncInline.ncchannel_rgb_p(_value) != 0;

  /// Extract the three 8-bit R/G/B components from a 32-bit channel.
  /// Only valid if ncchannel_rgb_p() would return true for the channel.
  RGB rgb8() {
    return using<RGB>((Arena alloc) {
      final r = alloc<Uint32>();
      final g = alloc<Uint32>();
      final b = alloc<Uint32>();
      ncInline.ncchannel_rgb8(_value, r, g, b);
      return RGB(r.value, g.value, b.value);
    });
  }

  /// Set the three 8-bit components of a 32-bit channel, and mark it as not using
  /// the default color. Retain the other bits unchanged. Any value greater than
  /// 255 will result in a return of -1 and no change to the channel.
  bool setRGB8(int r, int g, int b) {
    final chn = allocator<Uint32>();
    chn.value = _value;
    final rc = ncInline.ncchannel_set_rgb8(chn, r, g, b);
    _value = chn.value;
    allocator.free(chn);
    return rc == 0;
  }

  /// Set the 32-bit rgb of a 32-bit channel, and mark it as not using
  /// the default color. Retain the other bits unchanged. Any value greater than
  /// 0xffffff will result in a return of -1 and no change to the channel.
  bool setRGB32(int rgb) {
    final chn = allocator<Uint32>();
    chn.value = _value;
    final rc = ncInline.ncchannel_set(chn, rgb);
    _value = chn.value;
    allocator.free(chn);
    return rc == 0;
  }

  /// Set the three 8-bit components of a 32-bit channel, and mark it as not using
  /// the default color. Retain the other bits unchanged. r, g, and b will be
  /// clipped to the range [0..255].
  void setRgb8Clipped(int r, int g, int b) {
    final chn = allocator<Uint32>();
    chn.value = _value;
    ncInline.ncchannel_set_rgb8_clipped(chn, r, g, b);
    _value = chn.value;
    allocator.free(chn);
  }

  /// Extract the 2-bit alpha component from a 32-bit channel. It is not
  /// shifted down, and can be directly compared to NCALPHA_* values.
  int alpha() {
    return ncInline.ncchannel_alpha(_value);
  }

  /// Set the 2-bit alpha component of the 32-bit channel. Background channels
  /// must not be set to NCALPHA_HIGHCONTRAST. It is an error if alpha contains
  /// any bits other than NCALPHA_*.
  bool setAlpha(int alpha) {
    final chn = allocator<Uint32>();
    chn.value = _value;
    final rc = ncInline.ncchannel_set_alpha(chn, alpha);
    _value = chn.value;
    allocator.free(chn);
    return rc == 0;
  }

  /// Mark the channel as using its default color. Alpha is set opaque.
  void setDefault() {
    final chn = allocator<Uint32>();
    chn.value = _value;
    ncInline.ncchannel_set_default(chn);
    _value = chn.value;
    allocator.free(chn);
  }

  /// Extract the palette index from a channel. Only valid if
  /// ncchannel_palindex_p() would return true for the channel.
  int palindex() {
    return ncInline.ncchannel_palindex(_value);
  }

  /// Mark the channel as using the specified palette color. It is an error if
  /// the index is greater than NCPALETTESIZE. Alpha is set opaque.
  bool setPalindex(int idx) {
    final chn = allocator<Uint32>();
    chn.value = _value;
    final rc = ncInline.ncchannel_set_palindex(chn, idx);
    _value = chn.value;
    allocator.free(chn);
    return rc == 0;
  }
}
