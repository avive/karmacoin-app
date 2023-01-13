import "dart:convert";

import "package:hex/hex.dart";

/// Returns a shortened display string for binary data. e.g. 0xE012...01EAF
extension FormatHex on List<int> {
  String toShortHexString() {
    if (length < 4) {
      throw const FormatException('data too short');
    }
    return "0x${HEX.encode(take(2).toList())}...${HEX.encode(getRange(length - 2, length).toList())}";
  }

  /// Returns a hex string of the value, e.g. 0x1FE021...
  String toHexString() {
    return "0x${HEX.encode(this)}";
  }

  String toBase64() {
    return base64.encode(this);
  }
}
