import 'cipher_parameters.dart';

class ParametersWithSBox extends CipherParameters {
  final CipherParameters? _parameters;
  final List<int> _sBox;
  ParametersWithSBox(this._parameters, this._sBox);
  List<int> get SBox => _sBox;
  CipherParameters? get Parameters => _parameters;
}
