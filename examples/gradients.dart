import 'dart:io';

import 'package:dart_notcurses/dart_notcurses.dart';

int main() {
  final opts = CursesOptions(
    loglevel: LogLevel.error,
    flags: OptionFlags.drainInput,
  );
  final nc = NotCurses(opts);
  if (nc.notInitialized) {
    return -1;
  }

  bool rc = false;
  try {
    rc = gradientA(nc) && gradStriations(nc) && gradHigh(nc);
  } catch (e) {
    print(e);
  } finally {
    nc.stop();
  }

  return rc ? 0 : -1;
}

bool gradientA(NotCurses nc) {
  final p = nc.stdplane();
  final ul = Channels.initializer(0, 0, 0, 0xff, 0xff, 0xff);
  final ur = Channels.initializer(0, 0xff, 0xff, 0xff, 0, 0);
  final ll = Channels.initializer(0xff, 0, 0, 0, 0xff, 0xff);
  final lr = Channels.initializer(0xff, 0xff, 0xff, 0, 0, 0);

  if (p.gradient(0, 0, 0, 0, 'A', Style.none, ul, ur, ll, lr) <= 0) {
    return false;
  }

  if (!nc.render()) return false;

  sleep(Duration(seconds: 1));

  return true;
}

bool gradStriations(NotCurses nc) {
  final p = nc.stdplane();
  final ul = Channels.initializer(0, 0, 0, 0xff, 0xff, 0xff);
  final ur = Channels.initializer(0, 0xff, 0xff, 0xff, 0, 0);
  final ll = Channels.initializer(0xff, 0, 0, 0, 0xff, 0xff);
  final lr = Channels.initializer(0xff, 0xff, 0xff, 0, 0, 0);

  if (p.gradient(0, 0, 0, 0, '▄', Style.none, ul, ur, ll, lr) <= 0) {
    return false;
  }

  if (!nc.render()) {
    return false;
  }
  sleep(Duration(seconds: 1));

  if (p.gradient(0, 0, 0, 0, '▀', Style.none, ul, ur, ll, lr) <= 0) {
    return false;
  }

  if (!nc.render()) {
    return false;
  }
  sleep(Duration(seconds: 1));

  return true;
}

bool gradHigh(NotCurses nc) {
  final p = nc.stdplane();
  final ul = Channel.initializer(0, 0, 0);
  final ur = Channel.initializer(0, 0xff, 0xff);
  final ll = Channel.initializer(0xff, 0, 0);
  final lr = Channel.initializer(0xff, 0xff, 0xff);

  if (p.gradient2x1(0, 0, 0, 0, ul, ur, ll, lr) <= 0) {
    return false;
  }

  if (!nc.render()) {
    return false;
  }
  sleep(Duration(seconds: 1));

  return true;
}
