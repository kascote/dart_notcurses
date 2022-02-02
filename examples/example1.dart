import 'package:dart_notcurses/dart_notcurses.dart';

void main() {
  final nc = NotCurses(CursesOptions(
    loglevel: NcLogLevel.info,
    flags: 594, // info
  ));

  nc.render();
  nc.canTrueColor();
  nc.stop();
}
