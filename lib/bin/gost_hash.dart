import 'gost_28147_engine.dart';
import 'hex.dart';
import 'ozdst_1106_digest.dart';

class GostHash {
  static String hashGostString(String text) =>
      Hex.fromBytes(_hash(text.codeUnits));

  static String hashGostFiles(List<int> raw) => Hex.fromBytes(_hash(raw));

  static List<int> _hash(List<int> data, {String sBoxName = "D_A"}) {
    final sbox = GOST28147Engine.getSBox(sBoxName);
    final digest = OzDSt1106Digest(sbox);
    digest.reset();
    digest.updateBuffer(data, 0, data.length);
    final h = List.filled(digest.DigestSize, 0);
    digest.doFinal(h, 0);
    return h;
  }
}
