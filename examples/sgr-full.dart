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

    std
      ..setStyles(Style.none)
      ..putStr('a = none\n')
      ..setStyles(Style.italic)
      ..putStr('a ═ italic\n')
      ..setStyles(Style.bold)
      ..putStr('a ═ bold\n')
      ..setStyles(Style.undercurl)
      ..putStr('a ═ undercurl\n')
      ..setStyles(Style.underline)
      ..putStr('a ═ underline\n')
      ..setStyles(Style.struck)
      ..putStr('a ═ struck\n')
      ..setStyles(Style.italic | Style.bold)
      ..putStr('a ═ italic bold\n')
      ..setStyles(Style.italic | Style.bold | Style.struck)
      ..putStr('a ═ italic bold struck\n')
      ..setStyles(Style.italic | Style.undercurl)
      ..putStr('a ═ italic undercurl\n')
      ..setStyles(Style.italic | Style.underline)
      ..putStr('a ═ italic underline\n')
      ..setStyles(Style.italic | Style.struck)
      ..putStr('a ═ italic struck\n')
      ..setStyles(Style.struck | Style.bold)
      ..putStr('a ═ struck bold\n')
      ..setStyles(Style.struck | Style.bold | Style.italic)
      ..putStr('a ═ struck bold italic\n')
      ..setStyles(Style.struck | Style.undercurl)
      ..putStr('a ═ struck undercurl\n')
      ..setStyles(Style.struck | Style.underline)
      ..putStr('a ═ struck underline\n')
      ..setStyles(Style.bold | Style.undercurl)
      ..putStr('a ═ bold undercurl\n')
      ..setStyles(Style.bold | Style.underline)
      ..putStr('a ═ bold underline\n')
      ..setStyles(Style.bold | Style.undercurl | Style.italic)
      ..putStr('a ═ bold undercurl italic\n')
      ..setStyles(Style.bold | Style.underline | Style.italic)
      ..putStr('a ═ bold underline italic\n')
      ..setStyles(Style.struck | Style.undercurl | Style.italic)
      ..putStr('a ═ struck undercurl italic\n')
      ..setStyles(Style.struck | Style.underline | Style.italic)
      ..putStr('a ═ struck underline italic\n')
      ..setStyles(Style.struck | Style.undercurl | Style.bold)
      ..putStr('a ═ struck undercurl bold\n')
      ..setStyles(Style.struck | Style.underline | Style.bold)
      ..putStr('a ═ struck underline bold\n')
      ..setStyles(Style.bold | Style.underline | Style.italic | Style.struck)
      ..putStr('a ═ bold underline italic struck\n')
      ..setStyles(Style.bold | Style.undercurl | Style.italic | Style.struck)
      ..putStr('a ═ bold undercurl italic struck\n')
      ..setStyles(Style.none)
      ..putStr('a = none\n');

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
