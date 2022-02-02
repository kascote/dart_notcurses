import 'dart:ffi';
import 'dart:io';

import './ffi/notcurses_g.dart';
import './ffi/notcurses_inline_g.dart';

final LibraryHandler openLibrary = LibraryHandler._();

NcFfi? _ncffi;
NcFfi get nc {
  return _ncffi ??= NcFfi(openLibrary.openNotcurses());
}

NcFfiInline? _ncffiInline;
NcFfiInline get ncInline {
  return _ncffiInline ??= NcFfiInline(openLibrary.openNotcursesInline());
}

// TODO: this is using the default directory path where Brew install on OSX.
// need to sopport ways to override this path.
// - sqlite add a method that receive the new path
class LibraryHandler {
  LibraryHandler._();

  DynamicLibrary openNotcurses() {
    if (Platform.isMacOS) {
      return DynamicLibrary.open('/usr/local/opt/notcurses/lib/libnotcurses.dylib');
    }

    throw UnsupportedError('Unsupported platform: ${Platform.operatingSystem}');
  }

  DynamicLibrary openNotcursesInline() {
    if (Platform.isMacOS) {
      return DynamicLibrary.open('/usr/local/opt/notcurses/lib/libnotcurses-ffi.dylib');
    }

    throw UnsupportedError('Unsupported platform: ${Platform.operatingSystem}');
  }
}
