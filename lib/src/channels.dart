// ignore_for_file: constant_identifier_names

import 'dart:ffi';

import 'package:ffi/ffi.dart';

import './extensions/int.dart';
import './ffi/memory.dart';
import './load_library.dart';
import 'shared.dart';

class RGB {
  int r, g, b;
  RGB(this.r, this.g, this.b);

  @override
  String toString() {
    return 'RGB: r [$r/${r.toStrHex()}], g [$g/${g.toStrHex()}], b [$b/${b.toStrHex()}]';
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
  static RGB getFgRGB8(int channels) {
    return using<RGB>((Arena alloc) {
      final r = alloc<Uint32>();
      final g = alloc<Uint32>();
      final b = alloc<Uint32>();

      ncInline.ncchannels_fg_rgb8(channels, r, g, b);
      return RGB(r.value, g.value, b.value);
    });
  }

  /// Extract 24 bits of background RGB from 'channels', split into subchannels.
  static RGB getBgRGB8(int channels) {
    return using<RGB>((Arena alloc) {
      final r = alloc<Uint32>();
      final g = alloc<Uint32>();
      final b = alloc<Uint32>();
      ncInline.ncchannels_bg_rgb8(channels, r, g, b);
      return RGB(r.value, g.value, b.value);
    });
  }

  /// Extract 24 bits of foreground RGB from 'channels', shifted to LSBs.
  static int getFgRGB(int channels) {
    return ncInline.ncchannels_fg_rgb(channels);
  }

  /// Extract 24 bits of background RGB from 'channels', shifted to LSBs.
  static int getBgRGB(int channels) {
    return ncInline.ncchannels_bg_rgb(channels);
  }

  /// Estract palette index foreground color
  static int getFgPalindex(int channels) {
    return ncInline.ncchannels_fg_palindex(channels);
  }

  /// Estract palette index background color
  static int getBgPalindex(int channels) {
    return ncInline.ncchannels_bg_palindex(channels);
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
  static int getFgAlpha(int channels) {
    return ncInline.ncchannels_fg_alpha(channels);
  }

  /// Extract 2 bits of background alpha from 'cl', shifted to LSBs.
  static int getBgAlpha(int channels) {
    return ncInline.ncchannels_bg_alpha(channels);
  }
}

abstract class Channel {
  /// initialize a 32-bit channel pair with specified RGB
  static int initializer(int r, int g, int b) {
    return (r << 16) + (g << 8) + b + NC_BGDEFAULT_MASK;
  }

  /// Set the three 8-bit components of a 32-bit channel, and mark it as not using
  /// the default color. Retain the other bits unchanged. Any value greater than
  /// 255 will result in a return of -1 and no change to the channel.
  static NcResult<bool, int> setRGB8(int channel, int r, int g, int b) {
    final chn = allocator<Uint64>();
    chn.value = channel;
    final rc = ncInline.ncchannels_set_bg_rgb8(chn, r, g, b);
    final rst = NcResult<bool, int>(rc == 0, chn.value);
    allocator.free(chn);
    return rst;
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
}
