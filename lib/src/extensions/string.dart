extension ForString on String {
  String padCenter(int width, [String padding = ' ']) {
    final int len = width - length;
    if ((len <= 0) | (width < 0)) {
      return this;
    }
    final int padLen = (len / 2).ceil();
    final t = padLeft(padLen + length, padding);
    return t.padRight(padLen + t.length, padding);
  }
}
