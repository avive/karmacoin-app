import "dart:convert";
import "dart:ffi";
import "package:hex/hex.dart";
import "package:intl/intl.dart";

/// Returns a shortened display string for binary data. e.g. 0xE012...01EAF
extension HexToString on List<int> {
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

extension DecimalFormat on num {
  static final NumberFormat numberFormat = NumberFormat.decimalPattern();

  String format() {
    return numberFormat.format(this);
    //final parts = toString().split('.');
    //return '${numberFormat.format(num.tryParse(parts[0]) ?? 0.0)}.${parts[1]}';
  }
}

/*
extension Int64DecimalFormat on Int64 {
  static final NumberFormat numberFormat = NumberFormat.decimalPattern();

  String formatInt64() {
    return numberFormat.format(this);
    //final parts = toString().split('.');
    //return '${numberFormat.format(num.tryParse(parts[0]) ?? 0.0)}.${parts[1]}';
  }
}*/

extension StringToHex on String {
  List<int> toHex() {
    if (startsWith("0x")) {
      return HEX.decode(substring(2));
    }

    return HEX.decode(this);
  }
}
