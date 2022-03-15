import 'package:dart_notcurses/dart_notcurses.dart';

void main(List<String> args) {
  NotCurses? nc;

  try {
    nc = NotCurses.core(CursesOptions(
      flags: OptionFlags.cliMode | OptionFlags.suppressBanners | OptionFlags.drainInput,
      loglevel: LogLevel.silent,
    ));

    if (nc.notInitialized) {
      return;
    }

    final std = nc.stdplane();

    std.setStyles(Style.none);
    std.putStr('a = none\n');

    std.setStyles(Style.italic);
    std.putStr('a ═ italic\n');
    std.setStyles(Style.bold);
    std.putStr('a ═ bold\n');
    std.setStyles(Style.undercurl);
    std.putStr('a ═ undercurl\n');
    std.setStyles(Style.underline);
    std.putStr('a ═ underline\n');
    std.setStyles(Style.struck);
    std.putStr('a ═ struck\n');
    std.setStyles(Style.italic | Style.bold);
    std.putStr('a ═ italic bold\n');
    std.setStyles(Style.italic | Style.bold | Style.struck);
    std.putStr('a ═ italic bold struck\n');
    std.setStyles(Style.italic | Style.undercurl);
    std.putStr('a ═ italic undercurl\n');
    std.setStyles(Style.italic | Style.underline);
    std.putStr('a ═ italic underline\n');
    std.setStyles(Style.italic | Style.struck);
    std.putStr('a ═ italic struck\n');
    std.setStyles(Style.struck | Style.bold);
    std.putStr('a ═ struck bold\n');
    std.setStyles(Style.struck | Style.bold | Style.italic);
    std.putStr('a ═ struck bold italic\n');
    std.setStyles(Style.struck | Style.undercurl);
    std.putStr('a ═ struck undercurl\n');
    std.setStyles(Style.struck | Style.underline);
    std.putStr('a ═ struck underline\n');
    std.setStyles(Style.bold | Style.undercurl);
    std.putStr('a ═ bold undercurl\n');
    std.setStyles(Style.bold | Style.underline);
    std.putStr('a ═ bold underline\n');
    std.setStyles(Style.bold | Style.undercurl | Style.italic);
    std.putStr('a ═ bold undercurl italic\n');
    std.setStyles(Style.bold | Style.underline | Style.italic);
    std.putStr('a ═ bold underline italic\n');
    std.setStyles(Style.struck | Style.undercurl | Style.italic);
    std.putStr('a ═ struck undercurl italic\n');
    std.setStyles(Style.struck | Style.underline | Style.italic);
    std.putStr('a ═ struck underline italic\n');
    std.setStyles(Style.struck | Style.undercurl | Style.bold);
    std.putStr('a ═ struck undercurl bold\n');
    std.setStyles(Style.struck | Style.underline | Style.bold);
    std.putStr('a ═ struck underline bold\n');
    std.setStyles(Style.bold | Style.underline | Style.italic | Style.struck);
    std.putStr('a ═ bold underline italic struck\n');
    std.setStyles(Style.bold | Style.undercurl | Style.italic | Style.struck);
    std.putStr('a ═ bold undercurl italic struck\n');
    std.setStyles(Style.none);
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
