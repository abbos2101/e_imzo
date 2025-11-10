import 'cipher_parameters.dart';

class KeyParameter extends CipherParameters {
  final List<int> _key;

  KeyParameter(this._key);

  List<int> get Key => _key;
}
