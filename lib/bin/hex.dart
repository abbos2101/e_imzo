abstract class Hex {
  const Hex._();

  static String fromBytes(List<int> data) {
    final sb = StringBuffer();
    for (int i = 0; i < data.length; i++) {
      sb.write(data[i].toRadixString(16).padLeft(2, "0").toUpperCase());
    }
    return sb.toString();
  }
}
