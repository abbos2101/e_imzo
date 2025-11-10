import 'bin/crc32.dart';
import 'bin/gost_hash.dart';

abstract class EImzo {
  const EImzo._();

  static String qrcodeAuth({
    required String challenge,
    required String siteId,
    required String documentId,
  }) {
    final docHash = GostHash.hashGostString(challenge);
    var code = siteId + documentId + docHash;
    final crc32 = Crc32.calcHex(code);
    code += crc32;

    return code;
  }

  static String deeplinkAuth({
    required String challenge,
    required String siteId,
    required String documentId,
  }) {
    final code = qrcodeAuth(
      challenge: challenge,
      siteId: siteId,
      documentId: documentId,
    );

    return "eimzo://sign?qc=$code";
  }
}
