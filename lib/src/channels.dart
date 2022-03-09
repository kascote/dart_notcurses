// ignore_for_file: constant_identifier_names

import 'dart:ffi';

import 'package:ffi/ffi.dart';

import './extensions/int.dart';
import './ffi/memory.dart';
import './load_library.dart';
import 'shared.dart';

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

abstract class Channels {
  /// initialize a 64-bit channel pair with specified RGB fg/bg
  static int initializer(int fr, int fg, int fb, int br, int bg, int bb) {
    return (Channel.initializer(fr, fg, fb) << 32) + (Channel.initializer(br, bg, bb));
  }

  /// Extract the 32-bit background channel from a channel pair.
  static int bchannel(int channels) {
    return ncInline.ncchannels_bchannel(channels);
  }

  /// Extract the 32-bit foreground channel from a channel pair.
  static int fchannel(int channels) {
    return ncInline.ncchannels_fchannel(channels);
  }

  /// Set the r, g, and b channels for the foreground component of this 64-bit
  /// 'channels' variable, and mark it as not using the default color.
  static NcResult<bool, int> setFgRGB8(int channels, int r, int g, int b) {
    final chn = allocator<Uint64>();
    chn.value = channels;
    final rc = ncInline.ncchannels_set_fg_rgb8(chn, r, g, b);
    final res = NcResult(rc == 0, chn.value);
    allocator.free(chn);
    return res;
  }

  static NcResult<bool, int> setBgRGB8(int channels, int r, int g, int b) {
    final chn = allocator<Uint64>();
    chn.value = channels;
    final rc = ncInline.ncchannels_set_bg_rgb8(chn, r, g, b);
    final res = NcResult(rc == 0, chn.value);
    allocator.free(chn);
    return res;
  }

  /// Set an assembled 24 bit channel at once.
  static NcResult<bool, int> setFgRGB(int channels, int rgb) {
    final chn = allocator<Uint64>();
    chn.value = channels;
    final rc = ncInline.ncchannels_set_fg_rgb(chn, rgb);
    final res = NcResult(rc == 0, chn.value);
    allocator.free(chn);
    return res;
  }

  /// assembled 24-bit RGB value. A value over 0xffffff
  /// will be rejected, with a non-zero return value.
  static NcResult<bool, int> setBgRGB(int channels, int rgb) {
    final chn = allocator<Uint64>();
    chn.value = channels;
    final rc = ncInline.ncchannels_set_bg_rgb(chn, rgb);
    final res = NcResult(rc == 0, chn.value);
    allocator.free(chn);
    return res;
  }

  /// Extract 24 bits of foreground RGB from 'channels', split into subchannels.
  static RGB fgRGB8(int channels) {
    return using<RGB>((Arena alloc) {
      final r = alloc<Uint32>();
      final g = alloc<Uint32>();
      final b = alloc<Uint32>();

      ncInline.ncchannels_fg_rgb8(channels, r, g, b);
      return RGB(r.value, g.value, b.value);
    });
  }

  /// Extract 24 bits of background RGB from 'channels', split into subchannels.
  static RGB bgRGB8(int channels) {
    return using<RGB>((Arena alloc) {
      final r = alloc<Uint32>();
      final g = alloc<Uint32>();
      final b = alloc<Uint32>();
      ncInline.ncchannels_bg_rgb8(channels, r, g, b);
      return RGB(r.value, g.value, b.value);
    });
  }

  /// Extract 24 bits of foreground RGB from 'channels', shifted to LSBs.
  static int fgRGB(int channels) {
    return ncInline.ncchannels_fg_rgb(channels);
  }

  /// Extract 24 bits of background RGB from 'channels', shifted to LSBs.
  static int bgRGB(int channels) {
    return ncInline.ncchannels_bg_rgb(channels);
  }

  /// Estract palette index foreground color
  static int fgPalindex(int channels) {
    return ncInline.ncchannels_fg_palindex(channels);
  }

  /// Estract palette index background color
  static int bgPalindex(int channels) {
    return ncInline.ncchannels_bg_palindex(channels);
  }

  /// Set the cell's foreground palette index, set the foreground palette index
  /// bit, set it foreground-opaque, and clear the foreground default color bit.
  static NcResult<bool, int> setFgPalindex(int channels, int ndx) {
    final chn = allocator<Uint64>();
    chn.value = channels;
    final rc = ncInline.ncchannels_set_fg_palindex(chn, ndx);
    final res = NcResult(rc == 0, chn.value);
    allocator.free(chn);
    return res;
  }

  /// Set the cell's background palette index, set the background palette index
  /// bit, set it background-opaque, and clear the background default color bit.
  static NcResult<bool, int> setBgPalindex(int channels, int ndx) {
    final chn = allocator<Uint64>();
    chn.value = channels;
    final rc = ncInline.ncchannels_set_bg_palindex(chn, ndx);
    final res = NcResult(rc == 0, chn.value);
    allocator.free(chn);
    return res;
  }

  /// Set the 2-bit alpha component of the foreground channel.
  static NcResult<bool, int> setFgAlpha(int channels, int alpha) {
    final chn = allocator<Uint64>();
    chn.value = channels;
    final rc = ncInline.ncchannels_set_fg_alpha(chn, alpha);
    final res = NcResult(rc == 0, chn.value);
    allocator.free(chn);
    return res;
  }

  /// Set the 2-bit alpha component of the background channel.
  static NcResult<bool, int> setBgAlpha(int channels, int alpha) {
    final chn = allocator<Uint64>();
    chn.value = channels;
    final rc = ncInline.ncchannels_set_bg_alpha(chn, alpha);
    final res = NcResult(rc == 0, chn.value);
    allocator.free(chn);
    return res;
  }

  /// Extract 2 bits of foreground alpha from 'channels', shifted to LSBs.
  static int fgAlpha(int channels) {
    return ncInline.ncchannels_fg_alpha(channels);
  }

  /// Extract 2 bits of background alpha from 'cl', shifted to LSBs.
  static int bgAlpha(int channels) {
    return ncInline.ncchannels_bg_alpha(channels);
  }

  /// Mark the background channel as using its default color.
  static int setBgDefault(int channel) {
    final chn = allocator<Uint64>();
    chn.value = channel;
    final rc = ncInline.ncchannels_set_bg_default(chn);
    allocator.free(chn);
    return rc;
  }

  /// Mark the foreground channel as using its default color.
  static int setFgDefault(int channel) {
    final chn = allocator<Uint64>();
    chn.value = channel;
    final rc = ncInline.ncchannels_set_fg_default(chn);
    allocator.free(chn);
    return rc;
  }

  /// Returns the channels with the fore- and background's color information
  /// swapped, but without touching housekeeping bits. Alpha is retained unless
  /// it would lead to an illegal state: HIGHCONTRAST, TRANSPARENT, and BLEND
  /// are taken to OPAQUE unless the new value is RGB.
  static int reverse(int channel) {
    return ncInline.ncchannels_reverse(channel);
  }

  /// Set the alpha and coloring bits of a channel pair from another channel pair.
  static int setChannels(int dst, int channel) {
    final chn = allocator<Uint64>();
    chn.value = channel;
    final rc = ncInline.ncchannels_set_channels(chn, channel);
    allocator.free(chn);
    return rc;
  }

  /// Extract the background alpha and coloring bits from a 64-bit channel pair.
  static int channels(int channel) {
    return ncInline.ncchannels_channels(channel);
  }

  /// Creates a new channel pair using 'fchan' as the foreground channel
  /// and 'bchan' as the background channel.
  static int combine(int fchan, int bchan) {
    return ncInline.ncchannels_combine(fchan, bchan);
  }
}

abstract class Channel {
  /// initialize a 32-bit channel pair with specified RGB
  static int initializer(int r, int g, int b) {
    return (r << 16) + (g << 8) + b + NC_BGDEFAULT_MASK;
  }

  /// Extract the 8-bit red component from a 32-bit channel. Only valid if
  /// ncchannel_rgb_p() would return true for the channel.
  static int R(int channel) {
    return ncInline.ncchannel_r(channel);
  }

  /// Extract the 8-bit green component from a 32-bit channel. Only valid if
  /// ncchannel_rgb_p() would return true for the channel.
  static int G(int channel) {
    return ncInline.ncchannel_g(channel);
  }

  /// Extract the 8-bit blue component from a 32-bit channel. Only valid if
  /// ncchannel_rgb_p() would return true for the channel.
  static int B(int channel) {
    return ncInline.ncchannel_b(channel);
  }

  /// Extract the 24-bit RGB value from a 32-bit channel.
  /// Only valid if ncchannel_rgb_p() would return true for the channel.
  static int rgb(int channel) {
    return ncInline.ncchannel_rgb(channel);
  }

  /// Extract the three 8-bit R/G/B components from a 32-bit channel.
  /// Only valid if ncchannel_rgb_p() would return true for the channel.
  static RGB rgb8(int channel) {
    return using<RGB>((Arena alloc) {
      final r = alloc<Uint32>();
      final g = alloc<Uint32>();
      final b = alloc<Uint32>();
      ncInline.ncchannel_rgb8(channel, r, g, b);
      return RGB(r.value, g.value, b.value);
    });
  }

  /// Set the three 8-bit components of a 32-bit channel, and mark it as not using
  /// the default color. Retain the other bits unchanged. Any value greater than
  /// 255 will result in a return of -1 and no change to the channel.
  static bool setRGB8(int channel, int r, int g, int b) {
    final chn = allocator<Uint32>();
    chn.value = channel;
    final rc = ncInline.ncchannel_set_rgb8(chn, r, g, b);
    allocator.free(chn);
    return rc == 0;
  }

  /// Set the 32-bit rgb of a 32-bit channel, and mark it as not using
  /// the default color. Retain the other bits unchanged. Any value greater than
  /// 0xffffff will result in a return of -1 and no change to the channel.
  static bool setRGB32(int channel, int rgb) {
    final chn = allocator<Uint32>();
    chn.value = channel;
    final rc = ncInline.ncchannel_set(chn, rgb);
    allocator.free(chn);
    return rc == 0;
  }

  /// Set the three 8-bit components of a 32-bit channel, and mark it as not using
  /// the default color. Retain the other bits unchanged. r, g, and b will be
  /// clipped to the range [0..255].
  static void setRgb8Clipped(int channel, int r, int g, int b) {
    final chn = allocator<Uint32>();
    chn.value = channel;
    ncInline.ncchannel_set_rgb8_clipped(chn, r, g, b);
    allocator.free(chn);
  }

  /// Extract the 2-bit alpha component from a 32-bit channel. It is not
  /// shifted down, and can be directly compared to NCALPHA_* values.
  static int alpha(int channel) {
    return ncInline.ncchannel_alpha(channel);
  }

  /// Set the 2-bit alpha component of the 32-bit channel. Background channels
  /// must not be set to NCALPHA_HIGHCONTRAST. It is an error if alpha contains
  /// any bits other than NCALPHA_*.
  static bool setAlpha(int channel, int alpha) {
    final chn = allocator<Uint32>();
    chn.value = channel;
    final rc = ncInline.ncchannel_set_alpha(chn, alpha);
    allocator.free(chn);
    return rc == 0;
  }

  /// Is this channel using the "default color" rather than RGB/palette-indexed?
  static bool defaultP(int channel) {
    return ncInline.ncchannel_default_p(channel) != 0;
  }

  /// Mark the channel as using its default color. Alpha is set opaque.
  static int setDefault(int channel) {
    final chn = allocator<Uint32>();
    chn.value = channel;
    ncInline.ncchannel_set_default(chn);
    final rc = chn.value;
    allocator.free(chn);
    return rc;
  }

  /// Is this channel using palette-indexed color?
  static bool palindexP(int channel) {
    return ncInline.ncchannel_palindex_p(channel) != 0;
  }

  /// Extract the palette index from a channel. Only valid if
  /// ncchannel_palindex_p() would return true for the channel.
  static int palindex(int channel) {
    return ncInline.ncchannel_palindex(channel);
  }

  /// Mark the channel as using the specified palette color. It is an error if
  /// the index is greater than NCPALETTESIZE. Alpha is set opaque.
  static bool setPalindex(int channel, int idx) {
    final chn = allocator<Uint32>();
    chn.value = channel;
    final rc = ncInline.ncchannel_set_palindex(chn, idx);
    allocator.free(chn);
    return rc == 0;
  }

  /// Is this channel using RGB color?
  static bool rgbP(int channel) {
    return ncInline.ncchannel_rgb_p(channel) != 0;
  }
}
