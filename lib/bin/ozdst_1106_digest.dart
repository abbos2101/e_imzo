import 'gost_28147_engine.dart';
import 'key_parameter.dart';
import 'parameters_with_sbox.dart';

class OzDSt1106Digest {
  static const _DIGEST_LENGTH = 32;

  final _H = List.filled(32, 0);
  final _L = List.filled(32, 0);
  final _M = List.filled(32, 0);
  final _Sum = List.filled(32, 0);
  final List<List<int>> _C = List.filled(4, List.filled(0, 0));

  final _xBuf = List.filled(32, 0);
  int _xBufOff = 0;
  int _byteCount = 0;

  final _cipher = GOST28147Engine();
  List<int> _sBox = [];

  static _arraycopy(
    List<int> inp,
    int inOff,
    List<int> out,
    int outOff,
    int length,
  ) {
    for (int i = 0; i < length; i++) {
      if (i + inOff >= inp.length) break;
      out[i + outOff] = inp[i + inOff];
    }
  }

  OzDSt1106Digest(List<int> sBoxParam) {
    _sBox = List.filled(sBoxParam.length, 0);
    _arraycopy(sBoxParam, 0, _sBox, 0, sBoxParam.length);
    _cipher.init(true, ParametersWithSBox(null, _sBox));
    reset();
  }

  String get AlgorithmName => "OzDSt1106";

  int get DigestSize => OzDSt1106Digest._DIGEST_LENGTH;

  void updateByte(int inp) {
    _xBuf[_xBufOff++] = inp;
    if (_xBufOff == _xBuf.length) {
      _sumByteArray(_xBuf); // calc sum M
      _processBlock(_xBuf, 0);
      _xBufOff = 0;
    }
    _byteCount++;
  }

  void updateBuffer(List<int> inp, int inOff, int len) {
    while ((_xBufOff != 0) && (len > 0)) {
      updateByte(inp[inOff]);
      inOff++;
      len--;
    }

    while (len > _xBuf.length) {
      _arraycopy(inp, inOff, _xBuf, 0, _xBuf.length);
      _sumByteArray(_xBuf); // calc sum M
      _processBlock(_xBuf, 0);
      inOff += _xBuf.length;
      len -= _xBuf.length;
      _byteCount += _xBuf.length;
    }

    // load in the remainder.
    while (len > 0) {
      updateByte(inp[inOff]);
      inOff++;
      len--;
    }
  }

  // (i + 1 + 4(k - 1)) = 8i + k      i = 0-3, k = 1-8
  final _K = List.filled(32, 0);

  List<int> _P(List<int> inp) {
    for (int k = 0; k < 8; k++) {
      _K[4 * k] = inp[k];
      _K[1 + 4 * k] = inp[8 + k];
      _K[2 + 4 * k] = inp[16 + k];
      _K[3 + 4 * k] = inp[24 + k];
    }
    return _K;
  }

  //A (x) = (x0 ^ x1) || x3 || x2 || x1
  final _a = List.filled(8, 0);

  List<int> _A(List<int> inp) {
    for (int j = 0; j < 8; j++) {
      _a[j] = (inp[j] ^ inp[j + 8]) & 0xFF;
    }
    _arraycopy(inp, 8, inp, 0, 24);
    _arraycopy(_a, 0, inp, 24, 8);
    return inp;
  }

  //Encrypt function, ECB mode
  void _E(List<int> key, List<int> s, int sOff, List<int> inp, int inOff) {
    _cipher.init(true, KeyParameter(key));
    _cipher.processBlock(inp, inOff, s, sOff);
  }

  // (in:) n16||..||n1 ==> (out:) n1^n2^n3^n4^n13^n16||n16||..||n2
  final _wS = List.filled(16, 0);
  final _w_S = List.filled(16, 0);

  void _fw(List<int> inp) {
    _cpyBytesToShort(inp, _wS);
    _w_S[15] = (_wS[0] ^ _wS[1] ^ _wS[2] ^ _wS[3] ^ _wS[12] ^ _wS[15]) & 0xFFFF;
    _arraycopy(_wS, 1, _w_S, 0, 15);
    _cpyShortToBytes(_w_S, inp);
  }

  final _S = List.filled(32, 0);
  final _U = List.filled(32, 0);
  var _V = List.filled(32, 0);
  final _W = List.filled(32, 0);

  // block processing
  void _processBlock(List<int> inp, int inOff) {
    _arraycopy(inp, inOff, _M, 0, 32);

    //key step 1

    // H = h3 || h2 || h1 || h0
    // S = s3 || s2 || s1 || s0
    _arraycopy(_H, 0, _U, 0, 32);
    _arraycopy(_M, 0, _V, 0, 32);

    for (int j = 0; j < 32; j++) {
      _W[j] = (_U[j] ^ _V[j]) & 0xFF;
    }

    // Encrypt gost28147-ECB
    _E(_P(_W), _S, 0, _H, 0); // s0 = EK0 [h0]

    //keys step 2,3,4
    for (int i = 1; i < 4; i++) {
      List<int> tmpA = _A(_U);
      for (int j = 0; j < 32; j++) {
        _U[j] = (tmpA[j] ^ _C[i][j]) & 0xFF;
      }
      _V = _A(_A(_V));
      for (int j = 0; j < 32; j++) {
        _W[j] = (_U[j] ^ _V[j]) & 0xFF;
      }
      // Encrypt gost28147-ECB
      _E(_P(_W), _S, i * 8, _H, i * 8); // si = EKi [hi]
    }

    // x(M, H) = y61(H^y(M^y12(S)))
    for (int n = 0; n < 12; n++) {
      _fw(_S);
    }
    for (int n = 0; n < 32; n++) {
      _S[n] = (_S[n] ^ _M[n]) & 0xFF;
    }

    _fw(_S);

    for (int n = 0; n < 32; n++) {
      _S[n] = (_H[n] ^ _S[n]) & 0xFF;
    }
    for (int n = 0; n < 61; n++) {
      _fw(_S);
    }
    _arraycopy(_S, 0, _H, 0, _H.length);
  }

  static void _intToLittleEndian(int n, List<int> bs, int off) {
    bs[off] = (n) & 0xFF;
    bs[++off] = ((n & 0xFFFFFFFF) >> 8) & 0xFF;
    bs[++off] = ((n & 0xFFFFFFFF) >> 16) & 0xFF;
    bs[++off] = ((n & 0xFFFFFFFF) >> 24) & 0xFF;
  }

  static void _longToLittleEndian(int n, List<int> bs, int off) {
    _intToLittleEndian((n) & 0xffffffff, bs, off);
    // JAVASCIPT CANNOT MAKE (n >>> 32)
    //this.intToLittleEndian((n >>> 32) & 0xffffffff, bs, off + 4);
  }

  void finish() {
    _longToLittleEndian(
      _byteCount * 8,
      _L,
      0,
    ); // get length into L (byteCount * 8 = bitCount)

    while (_xBufOff != 0) {
      updateByte(0 & 0xFF);
    }

    _processBlock(_L, 0);
    _processBlock(_Sum, 0);
  }

  int doFinal(List<int> out, int outOff) {
    finish();
    _arraycopy(_H, 0, out, outOff, _H.length);
    reset();
    return OzDSt1106Digest._DIGEST_LENGTH;
  }

  /// reset the chaining variables to the IV values.
  final List<int> _C2 = [
    0x00,
    0xFF,
    0x00,
    0xFF,
    0x00,
    0xFF,
    0x00,
    0xFF,
    0xFF,
    0x00,
    0xFF,
    0x00,
    0xFF,
    0x00,
    0xFF,
    0x00,
    0x00,
    0xFF,
    0xFF,
    0x00,
    0xFF,
    0x00,
    0x00,
    0xFF,
    0xFF,
    0x00,
    0x00,
    0x00,
    0xFF,
    0xFF,
    0x00,
    0xFF,
  ];

  void reset() {
    for (int i = 0; i < _C.length; i++) {
      _C[i] = List.filled(32, 0);
    }
    _byteCount = 0;
    _xBufOff = 0;

    _H.fillRange(0, _H.length, 0);
    _L.fillRange(0, _L.length, 0);
    _M.fillRange(0, _M.length, 0);
    _C[1].fillRange(0, _C[1].length, 0);
    _C[3].fillRange(0, _C[3].length, 0);
    _Sum.fillRange(0, _Sum.length, 0);
    _xBuf.fillRange(0, _xBuf.length, 0);

    // for (let i = 0; i < this.H.length; i++) {
    //     this.H[i] = 0;  // start vector H
    // }
    // for (let i = 0; i < this.L.length; i++) {
    //     this.L[i] = 0;
    // }
    // for (let i = 0; i < this.M.length; i++) {
    //     this.M[i] = 0;
    // }
    // for (let i = 0; i < this.C[1].length; i++) {
    //     this.C[1][i] = 0;  // real index C = +1 because index array with 0.
    // }
    // for (let i = 0; i < this.C[3].length; i++) {
    //     this.C[3][i] = 0;
    // }
    // for (let i = 0; i < this.Sum.length; i++) {
    //     this.Sum[i] = 0;
    // }
    // for (let i = 0; i < this.xBuf.length; i++) {
    //     this.xBuf[i] = 0;
    // }

    _arraycopy(_C2, 0, _C[2], 0, _C2.length);
  }

  //  256 bitsblock modul -> (Sum + a mod (2^256))
  void _sumByteArray(List<int> inp) {
    int carry = 0;
    for (int i = 0; i != _Sum.length; i++) {
      int sum = (_Sum[i] & 0xff) + (inp[i] & 0xff) + carry;
      _Sum[i] = sum & 0xFF;
      carry = (sum & 0xFFFFFFFF) >> 8;
    }
  }

  void _cpyBytesToShort(List<int> S, List<int> wS) {
    for (int i = 0; i < S.length / 2; i++) {
      wS[i] = (((S[i * 2 + 1] << 8) & 0xFF00) | (S[i * 2] & 0xFF)) & 0xFFFF;
    }
  }

  void _cpyShortToBytes(List<int> wS, List<int> S) {
    for (int i = 0; i < S.length / 2; i++) {
      S[i * 2 + 1] = (wS[i] >> 8) & 0xFF;
      S[i * 2] = wS[i] & 0xFF;
    }
  }

  int get ByteLength => 32;
}
