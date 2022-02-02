/// Generic class to let return multible values at the same time.
/// Usually used to return the result code of the function call
/// and some other value that on C will be returned by reference.
class NcResult<T, P> {
  late T result;
  late P value;

  NcResult(this.result, this.value);
}

int swap16(int value) {
  return ((value & 0xff) << 8) | ((value & 0xff00) >> 8);
}

int swap32(int value) {
  return ((value & 0x000000ff) << 24) |
      ((value & 0x0000ff00) << 8) |
      ((value & 0x00ff0000) >> 8) |
      ((value & 0xff000000) >> 24);
}
