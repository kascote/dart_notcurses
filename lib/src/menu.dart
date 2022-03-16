import 'dart:ffi' as ffi;
import 'dart:io';

import 'package:ffi/ffi.dart';

import './channels.dart';
import './ffi/memory.dart';
import './ffi/notcurses_g.dart';
import './key.dart';
import './load_library.dart';
import './plane.dart';
import './shared.dart';

abstract class MenuOptionFlags {
  static const int top = 0x0000;
  static const int bottom = 0x0001; // NCMENU_OPTION_BOTTOM - bottom row (as opposed to top row)
  static const int hidding = 0x0002; // NCMENU_OPTION_HIDING - hide the menu when not unrolled
}

class MenuOptions {
  Channels headerChannels;
  Channels sectionChannels;
  int flags;

  MenuOptions({
    Channels? headerChannels,
    Channels? sectionChannels,
    this.flags = MenuOptionFlags.top,
  })  : headerChannels = headerChannels ?? Channels.zero(),
        sectionChannels = sectionChannels ?? Channels.zero();
}

class MenuItem {
  String handle;
  String description;
  String? shortcutKey;

  /// NcKeyMod
  int? shortcutModifier;

  MenuItem(this.handle, this.description, {this.shortcutKey, this.shortcutModifier});
}

class MenuSection {
  String name;
  List<MenuItem> items;
  String? shortcutKey;

  /// NcKeyMod
  int? shortcutModifier;

  MenuSection(this.name, this.items, {this.shortcutKey, this.shortcutModifier});
}

class Menu {
  List<MenuSection> sections;
  MenuOptions options;
  ffi.Pointer<ncmenu> _ptr = ffi.nullptr;
  final Map<int, String> _itemShorcuts = {};

  Menu(this.sections, this.options);

  /// Create a new menu on the given [Plane]
  void create(Plane plane) {
    using((Arena alloc) {
      ncinput makeShortcut(String key, int? mod) {
        final itemSC = alloc<ncinput>();
        itemSC.ref.id = key.codeUnitAt(0);
        if (mod != null) {
          itemSC.ref.modifiers = mod;
        }
        return itemSC.ref;
      }

      final pSections = alloc<ncmenu_section>(sections.length);

      var rs = 0;
      for (final section in sections) {
        final pItems = alloc<ncmenu_item>(section.items.length);

        var ri = 0;
        for (final item in section.items) {
          if (item.handle.isEmpty) {
            pItems[ri].desc = ffi.nullptr;
          } else {
            pItems[ri].desc = item.description.toNativeUtf8(allocator: alloc).cast();

            if (item.shortcutKey != null) {
              pItems[ri].shortcut = makeShortcut(item.shortcutKey!, item.shortcutModifier);
              final ik = (item.shortcutKey!.codeUnitAt(0) << 8) |
                  ((item.shortcutModifier == null) ? 0 : item.shortcutModifier!);
              _itemShorcuts[ik] = item.handle;
            }
          }
          ri++;
        }

        pSections[rs]
          ..name = section.name.toNativeUtf8(allocator: alloc).cast()
          ..items = pItems
          ..itemcount = section.items.length;
        if (section.shortcutKey != null) {
          pSections[rs].shortcut = makeShortcut(section.shortcutKey!, section.shortcutModifier);
        }

        rs++;
      }

      final opts = alloc<ncmenu_options>();
      opts.ref
        ..sections = pSections
        ..sectioncount = sections.length
        ..headerchannels = options.headerChannels.value
        ..sectionchannels = options.sectionChannels.value
        ..flags = options.flags;

      _ptr = nc.ncmenu_create(plane.ptr, opts);
      if (_ptr == ffi.nullptr) {
        stderr.writeln('error creating menu');
      }
    });
  }

  /// Unroll the specified menu section, making the menu visible if it was
  /// invisible, and rolling up any menu section that is already unrolled.
  bool unrollSection(int sectionIdx) {
    return nc.ncmenu_unroll(_ptr, sectionIdx) == 0;
  }

  /// Roll up any unrolled menu section, and hide the menu if using hiding.
  bool rollup() {
    return nc.ncmenu_rollup(_ptr) == 0;
  }

  /// Unroll the next section (relative to current unrolled). If no
  /// section is unrolled, the first section will be unrolled.
  bool nextSection() {
    return nc.ncmenu_nextsection(_ptr) == 0;
  }

  /// Unroll the previous section (relative to current unrolled). If no
  /// section is unrolled, the first section will be unrolled.
  bool prevSection() {
    return nc.ncmenu_prevsection(_ptr) == 0;
  }

  /// Move to the next item within the currently unrolled section. If no
  /// section is unrolled, the first section will be unrolled.
  bool nextItem() {
    return nc.ncmenu_nextitem(_ptr) == 0;
  }

  /// Move to the previous item within the currently unrolled section. If no
  /// section is unrolled, the first section will be unrolled.
  bool prevItem() {
    return nc.ncmenu_previtem(_ptr) == 0;
  }

  /// Disable or enable a menu item. Returns 0 if the item was found.
  bool itemSetStatus(String section, String item, bool enabled) {
    bool rc = false;
    using((Arena alloc) {
      rc = nc.ncmenu_item_set_status(
            _ptr,
            section.toNativeUtf8(allocator: alloc).cast(),
            item.toNativeUtf8(allocator: alloc).cast(),
            enabled ? 1 : 0,
          ) ==
          0;
    });
    return rc;
  }

  /// Return the selected item description, or NULL if no section is unrolled. If
  /// 'ni' is not NULL, and the selected item has a shortcut, 'ni' will be filled
  /// in with that shortcut--this can allow faster matching.
  NcResult<String?, Key?> selected() {
    final k = Key();
    final rc = nc.ncmenu_selected(_ptr, k.ptr);
    if (rc == ffi.nullptr) {
      k.destroy();
      return NcResult(null, null);
    }
    return NcResult(rc.cast<Utf8>().toDartString(), k);
  }

  /// Return the item description corresponding to the mouse click 'click'. The
  /// item must be on an actively unrolled section, and the click must be in the
  /// area of a valid item. If 'ni' is not NULL, and the selected item has a
  /// shortcut, 'ni' will be filled in with the shortcut.
  NcResult<String?, Key?> mouseSelected(Key click, {bool getShortcut = false}) {
    Key? k;
    final ffi.Pointer<ffi.Int8> rc;
    if (getShortcut) {
      k = Key();
    }
    rc = nc.ncmenu_mouse_selected(_ptr, click.ptr, getShortcut ? k!.ptr : ffi.nullptr);
    if (rc == ffi.nullptr) {
      if (getShortcut) k!.destroy();
      return NcResult(null, null);
    }

    return NcResult(rc.cast<Utf8>().toDartString(), getShortcut ? k : null);
  }

  /// Return the ncplane backing this ncmenu.
  Plane plane() {
    return Plane.fromPtr(nc.ncmenu_plane(_ptr));
  }

  /// Offer the input to the ncmenu. If it's relevant, this function returns true,
  /// and the input ought not be processed further. If it's irrelevant to the
  /// menu, false is returned. Relevant inputs include:
  ///  * mouse movement over a hidden menu
  ///  * a mouse click on a menu section (the section is unrolled)
  ///  * a mouse click outside of an unrolled menu (the menu is rolled up)
  ///  * left or right on an unrolled menu (navigates among sections)
  ///  * up or down on an unrolled menu (navigates among items)
  ///  * escape on an unrolled menu (the menu is rolled up)
  bool offerInput(Key key) {
    return nc.ncmenu_offer_input(_ptr, key.ptr) != 0;
  }

  /// Given a key, check if there is a MenuItem hot key with the same definition
  /// if found, the menu item handle will be returned.
  String? isMenuHotkey(Key key) {
    final ik = (key.id << 8) | key.modifiers;
    return _itemShorcuts[ik];
  }

  /// Free the menu resources
  void destroy() {
    if (_ptr != ffi.nullptr) {
      nc.ncmenu_destroy(_ptr);
      allocator.free(_ptr);
    }
  }
}
