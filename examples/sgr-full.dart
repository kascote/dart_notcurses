import 'package:dart_notcurses/dart_notcurses.dart';

void main(List<String> args) {
  NotCurses? nc;

  try {
    nc = NotCurses.core(CursesOptions(
        flags: NcOptions.cliMode | NcOptions.suppressBanners | NcOptions.drainInput, loglevel: NcLogLevel.silent));

    if (nc.notInitialized) {
      return;
    }

    final std = nc.stdplane();

    std.setStyles(NcStyle.none);
    std.putStr('a = none\n');

    std.setStyles(NcStyle.italic);
    std.putStr('a ═ italic\n');
    std.setStyles(NcStyle.bold);
    std.putStr('a ═ bold\n');
    std.setStyles(NcStyle.undercurl);
    std.putStr('a ═ undercurl\n');
    std.setStyles(NcStyle.underline);
    std.putStr('a ═ underline\n');
    std.setStyles(NcStyle.struck);
    std.putStr('a ═ struck\n');
    std.setStyles(NcStyle.italic | NcStyle.bold);
    std.putStr('a ═ italic bold\n');
    std.setStyles(NcStyle.italic | NcStyle.bold | NcStyle.struck);
    std.putStr('a ═ italic bold struck\n');
    std.setStyles(NcStyle.italic | NcStyle.undercurl);
    std.putStr('a ═ italic undercurl\n');
    std.setStyles(NcStyle.italic | NcStyle.underline);
    std.putStr('a ═ italic underline\n');
    std.setStyles(NcStyle.italic | NcStyle.struck);
    std.putStr('a ═ italic struck\n');
    std.setStyles(NcStyle.struck | NcStyle.bold);
    std.putStr('a ═ struck bold\n');
    std.setStyles(NcStyle.struck | NcStyle.bold | NcStyle.italic);
    std.putStr('a ═ struck bold italic\n');
    std.setStyles(NcStyle.struck | NcStyle.undercurl);
    std.putStr('a ═ struck undercurl\n');
    std.setStyles(NcStyle.struck | NcStyle.underline);
    std.putStr('a ═ struck underline\n');
    std.setStyles(NcStyle.bold | NcStyle.undercurl);
    std.putStr('a ═ bold undercurl\n');
    std.setStyles(NcStyle.bold | NcStyle.underline);
    std.putStr('a ═ bold underline\n');
    std.setStyles(NcStyle.bold | NcStyle.undercurl | NcStyle.italic);
    std.putStr('a ═ bold undercurl italic\n');
    std.setStyles(NcStyle.bold | NcStyle.underline | NcStyle.italic);
    std.putStr('a ═ bold underline italic\n');
    std.setStyles(NcStyle.struck | NcStyle.undercurl | NcStyle.italic);
    std.putStr('a ═ struck undercurl italic\n');
    std.setStyles(NcStyle.struck | NcStyle.underline | NcStyle.italic);
    std.putStr('a ═ struck underline italic\n');
    std.setStyles(NcStyle.struck | NcStyle.undercurl | NcStyle.bold);
    std.putStr('a ═ struck undercurl bold\n');
    std.setStyles(NcStyle.struck | NcStyle.underline | NcStyle.bold);
    std.putStr('a ═ struck underline bold\n');
    std.setStyles(NcStyle.bold | NcStyle.underline | NcStyle.italic | NcStyle.struck);
    std.putStr('a ═ bold underline italic struck\n');
    std.setStyles(NcStyle.bold | NcStyle.undercurl | NcStyle.italic | NcStyle.struck);
    std.putStr('a ═ bold undercurl italic struck\n');
    std.setStyles(NcStyle.none);
    std.putStr('a = none\n');

    if (!nc.render()) {
      return;
    }
  } catch (e, s) {
    if (nc != null) nc.initialized & nc.stop();
    print(e);
    print(s);
  } finally {
    if (nc != null) nc.initialized & nc.stop();
  }
}
