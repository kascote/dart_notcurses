extension ForInt on int {
  String toStrHex({final int padding = 0}) {
    return '0x${toRadixString(16).padLeft(padding, '0')}';
  }
}
