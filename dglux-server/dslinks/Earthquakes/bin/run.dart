import "dart:collection";
import "dart:async";
import "dart:convert";
import "dart:typed_data";
import "dart:math";
import "dart:math" as _A;
import "dart:io";
import "dart:io" as _B;
import "dart:isolate";
import "dart:mirrors";
class ArgParser {
  final Map<String, Option> _options;
  final Map<String, ArgParser> _commands;
  final Map<String, Option> options;
  final Map<String, ArgParser> commands;
  final _optionsAndSeparators = [];
  final bool allowTrailingOptions;
  factory ArgParser({bool allowTrailingOptions: false}) => new ArgParser.__A(<String, Option>{}, <String, ArgParser>{}, allowTrailingOptions: allowTrailingOptions);
  ArgParser.__A(Map<String, Option> options_A, Map<String, ArgParser> commands_A, {bool allowTrailingOptions: false}) : this._options = options_A, this.options = new UnmodifiableMapView(options_A), this._commands = commands_A, this.commands = new UnmodifiableMapView(commands_A), this.allowTrailingOptions = allowTrailingOptions != null ? allowTrailingOptions : false;
  void addFlag(String name_A, {String abbr, String help, bool defaultsTo: false, bool negatable: true, void callback(bool value), bool hide: false}) {
    _addOption(name_A, abbr, help, null, null, null, defaultsTo, callback, OptionType.FLAG, negatable: negatable, hide: hide);
  }
  void addOption(String name_A, {String abbr, String help, String valueHelp, List<String> allowed, Map<String, String> allowedHelp, String defaultsTo, void callback(value), bool allowMultiple: false, bool splitCommas, bool hide: false}) {
    if (!allowMultiple && splitCommas != null) {
      throw new ArgumentError('splitCommas may not be set if allowMultiple is false.');
    }
    _addOption(name_A, abbr, help, valueHelp, allowed, allowedHelp, defaultsTo, callback, allowMultiple ? OptionType.MULTIPLE : OptionType.SINGLE, splitCommas: splitCommas, hide: hide);
  }
  void _addOption(String name_A, String abbr, String help, String valueHelp, List<String> allowed, Map<String, String> allowedHelp, defaultsTo, void callback_A(value), OptionType type_A, {bool negatable: false, bool splitCommas, bool hide: false}) {
    if (_options.containsKey(name_A)) {
      throw new ArgumentError('Duplicate option "${name_A}".');
    }
    if (abbr != null) {
      var existing = findByAbbreviation(abbr);
      if (existing != null) {
        throw new ArgumentError('Abbreviation "${abbr}" is already used by "${existing.name}".');
      }
    }
    var option = newOption(name_A, abbr, help, valueHelp, allowed, allowedHelp, defaultsTo, callback_A, type_A, negatable: negatable, splitCommas: splitCommas, hide: hide);
    _options[name_A] = option;
    _optionsAndSeparators.add(option);
  }
  ArgResults parse_D(List<String> args) => new Parser(null, this, args.toList()).parse_D();
  String get usage => new Usage(_optionsAndSeparators).generate_A();
  Option findByAbbreviation(String abbr) {
    return options.values.firstWhere((option) => option.abbreviation == abbr, orElse: () => null);
  }
}
ArgResults newArgResults(ArgParser parser, Map<String, dynamic> parsed, String name_A, ArgResults command_A, List<String> rest, List<String> arguments_A) {
  return new ArgResults.__B(parser, parsed, name_A, command_A, rest, arguments_A);
}
class ArgResults {
  final ArgParser _parser;
  final Map<String, dynamic> _parsed;
  final String name;
  final ArgResults command;
  final List<String> rest;
  final List<String> arguments;
  ArgResults.__B(this._parser, this._parsed, this.name, this.command, List<String> rest_A, List<String> arguments_A) : this.rest = new UnmodifiableListView(rest_A), this.arguments = new UnmodifiableListView(arguments_A);
  operator[](String name_A) {
    if (!_parser.options.containsKey(name_A)) {
      throw new ArgumentError('Could not find an option named "${name_A}".');
    }
    return _parser.options[name_A].getOrDefault(_parsed[name_A]);
  }
  Iterable<String> get options {
    var result_A = new Set<String>.from(_parsed.keys);
    _parser.options.forEach((name_A, option) {
      if (option.defaultValue != null) result_A.add(name_A);
    });
    return result_A;
  }
}
abstract class BaseClient implements Client {
  Future<Response> get(url, {Map<String, String> headers}) => _sendUnstreamed("GET", url, headers);
  Future<String> read(url, {Map<String, String> headers}) {
    return get(url, headers: headers).then((response_B) {
      _checkResponseSuccess(url, response_B);
      return response_B.body;
    });
  }
  Future<StreamedResponse> send(BaseRequest request_B);
  Future<Response> _sendUnstreamed(String method_A, url, Map<String, String> headers_A, [body, Encoding encoding_A]) async {
    if (url is String) url = Uri.parse(url);
    var request_B = new Request(method_A, url);
    if (headers_A != null) request_B.headers.addAll(headers_A);
    if (encoding_A != null) request_B.encoding = encoding_A;
    if (body != null) {
      if (body is String) {
        request_B.body = body;
      } else if (body is List) {
        request_B.bodyBytes = DelegatingList.typed(body);
      } else if (body is Map) {
        request_B.bodyFields = DelegatingMap.typed_A(body);
      } else {
        throw new ArgumentError('Invalid request body "${body}".');
      }
    }
    return Response.fromStream(await send(request_B));
  }
  void _checkResponseSuccess(url, Response response_B) {
    if (response_B.statusCode < 400) return;
    var message_A = "Request to ${url} failed with status ${response_B.statusCode}";
    if (response_B.reasonPhrase != null) {
      message_A = "${message_A}: ${response_B.reasonPhrase}";
    }
    if (url is String) url = Uri.parse(url);
    throw new ClientException("${message_A}.", url);
  }
  void close() {}
}
abstract class BaseRequest {
  final String method;
  final Uri url;
  int get contentLength => _contentLength_A;
  int _contentLength_A;
  set contentLength(int value_A) {
    if (value_A != null && value_A < 0) {
      throw new ArgumentError("Invalid content length ${value_A}.");
    }
    _checkFinalized();
    _contentLength_A = value_A;
  }
  bool get persistentConnection => _persistentConnection_A;
  bool _persistentConnection_A = true;
  set persistentConnection(bool value_A) {
    _checkFinalized();
    _persistentConnection_A = value_A;
  }
  bool get followRedirects => _followRedirects_A;
  bool _followRedirects_A = true;
  set followRedirects(bool value_A) {
    _checkFinalized();
    _followRedirects_A = value_A;
  }
  int get maxRedirects => _maxRedirects_A;
  int _maxRedirects_A = 5;
  set maxRedirects(int value_A) {
    _checkFinalized();
    _maxRedirects_A = value_A;
  }
  final Map<String, String> headers;
  bool get finalized => _finalized;
  bool _finalized = false;
  BaseRequest(this.method, this.url) : headers = new LinkedHashMap(equals: (key1, key2) => key1.toLowerCase() == key2.toLowerCase(), hashCode: (key_A) => key_A.toLowerCase().hashCode);
  ByteStream finalize() {
    if (finalized) throw new StateError("Can't finalize a finalized Request.");
    _finalized = true;
    return null;
  }
  void _checkFinalized() {
    if (!finalized) return;
    throw new StateError("Can't modify a finalized Request.");
  }
  String toString() => "${method} ${url}";
}
abstract class BaseResponse {
  final BaseRequest request;
  final int statusCode;
  final String reasonPhrase;
  final int contentLength;
  final Map<String, String> headers;
  final bool isRedirect;
  final bool persistentConnection;
  BaseResponse(this.statusCode, {this.contentLength, this.request, this.headers: const{}, this.isRedirect: false, this.persistentConnection: true, this.reasonPhrase}) {
    if (statusCode < 100) {
      throw new ArgumentError("Invalid status code ${statusCode}.");
    } else if (contentLength != null && contentLength < 0) {
      throw new ArgumentError("Invalid content length ${contentLength}.");
    }
  }
}
abstract class BigInteger {
  static bool _useJsBigint = () {
    if (0.0 is int) {
      return true;
    }
    try {
      return 3.modInverse(7) == -1;
    } catch (err) {
      return true;
    }
    return false;
  }();
  static BigInteger get ZERO_A {
    if (_useJsBigint) {
      return BigIntegerV8.nbv(0);
    } else {
      return BigIntegerDartvm.nbv_A(0);
    }
  }
  static BigInteger get ONE_A {
    if (_useJsBigint) {
      return BigIntegerV8.nbv(1);
    } else {
      return BigIntegerDartvm.nbv_A(1);
    }
  }
  static BigInteger get TWO {
    if (_useJsBigint) {
      return BigIntegerV8.nbv(2);
    } else {
      return BigIntegerDartvm.nbv_A(2);
    }
  }
  static BigInteger get THREE {
    if (_useJsBigint) {
      return BigIntegerV8.nbv(3);
    } else {
      return BigIntegerDartvm.nbv_A(3);
    }
  }
  factory BigInteger([a, b, c]) {
    if (_useJsBigint) {
      return new BigIntegerV8(a, b, c);
    } else {
      return new BigIntegerDartvm(a, b, c);
    }
  }
  factory BigInteger.fromBytes_A(int signum_A, List<int> magnitude_A) {
    if (_useJsBigint) {
      return new BigIntegerV8.fromBytes_C(signum_A, magnitude_A);
    } else {
      return new BigIntegerDartvm.fromBytes_B(signum_A, magnitude_A);
    }
  }
}
class BigIntegerDartvm implements BigInteger {
  static BigIntegerDartvm nbv_A(int i) {
    return new BigIntegerDartvm(i);
  }
  int data;
  BigIntegerDartvm([a, b, c]) {
    if (a != null) {
      if (a is int) {
        data = a;
      } else if (a is num) {
        data = a.toInt();
      } else if (a is List) {
        this.fromByteArray(a);
      } else {
        this.fromString_A(a, b);
      }
    }
  }
  factory BigIntegerDartvm.fromBytes_B(int signum_A, List<int> magnitude_A) {
    BigIntegerDartvm self = new BigIntegerDartvm();
    if (signum_A != 0) {
      self.fromByteArray(magnitude_A, true);
    } else {
      self.fromByteArray(magnitude_A, false);
    }
    if (signum_A < 0) {
      self.data = -self.data;
    }
    return self;
  }
  void copyTo(BigIntegerDartvm r) {
    r.data = data;
  }
  void fromInt(int x_A) {
    data = x_A;
  }
  void fromString_A(String s, int b) {
    data = int.parse(s, radix: b, onError: (str) => 0);
  }
  void fromByteArray(List s, [bool fixsign = false]) {
    if (s == null || s.length == 0) {
      data = 0;
      return;
    }
    bool neg = false;
    if (!fixsign && s[0] & 0xFF > 0x7F) {
      neg = true;
    }
    if (neg) {
      int v = 0;
      for (int byte in s) {
        v = (v << 8) | (~((byte & 0xFF) - 256));
      }
      data = ~v;
    } else {
      int v = 0;
      for (int byte in s) {
        v = (v << 8) | (byte & 0xFF);
      }
      data = v;
    }
  }
  String toString([int b = 10]) {
    return data.toRadixString(b);
  }
  negate_op() {
    return new BigIntegerDartvm(-data);
  }
  BigIntegerDartvm abs() {
    return (data < 0) ? this.negate_op() : this.clone();
  }
  int compareTo(a) {
    if (a is num) {
      return data.compareTo(a);
    }
    if (a is BigIntegerDartvm) {
      return data.compareTo(a.data);
    }
    return 0;
  }
  int nbits(x_A) {
    var r = 1, t;
    if (x_A is num) x_A = x_A.toInt();
    if ((t = x_A >> 16) != 0) {
      x_A = t;
      r += 16;
    }
    if ((t = x_A >> 8) != 0) {
      x_A = t;
      r += 8;
    }
    if ((t = x_A >> 4) != 0) {
      x_A = t;
      r += 4;
    }
    if ((t = x_A >> 2) != 0) {
      x_A = t;
      r += 2;
    }
    if ((t = x_A >> 1) != 0) {
      x_A = t;
      r += 1;
    }
    return r;
  }
  int bitLength() {
    return data.bitLength;
  }
  void lShiftTo(int n, r) {
    r.data = data << n;
  }
  void rShiftTo(int n, r) {
    r.data = data >> n;
  }
  void subTo(a, r) {
    r.data = data - a.data;
  }
  void multiplyTo(a, r) {
    r.data = data * a.data;
  }
  void squareTo(r) {
    r.data = data * data;
  }
  divRemTo(BigIntegerDartvm m, BigIntegerDartvm q, BigIntegerDartvm r) {
    q.data = data ~/ m.data;
    r.data = data % m.data;
  }
  mod(a) {
    return new BigIntegerDartvm(data % a.data);
  }
  isEven() {
    return data.isEven;
  }
  isOdd() {
    return data.isOdd;
  }
  clone() {
    return new BigIntegerDartvm(this.data);
  }
  int intValue() {
    return data;
  }
  int signum() {
    return data.sign;
  }
  String toRadix([int b = 10]) {
    return data.toRadixString(b);
  }
  void fromRadix(s, b) {
    data = int.parse(s, radix: b, onError: (str) => 0);
  }
  List<int> toByteArray() {
    String str;
    bool neg = false;
    if (data < 0) {
      str = (~data).toRadixString(16);
      neg = true;
    } else {
      str = data.toRadixString(16);
    }
    int p = 0;
    int len = str.length;
    int blen = (len + 1) ~/ 2;
    int boff = 0;
    List bytes_A;
    if (neg) {
      if (len & 1 == 1) {
        p = -1;
      }
      int byte0 = ~int.parse(str.substring(0, p + 2), radix: 16);
      if (byte0 < -128) byte0 += 256;
      if (byte0 >= 0) {
        boff = 1;
        bytes_A = new List<int>(blen + 1);
        bytes_A[0] = -1;
        bytes_A[1] = byte0;
      } else {
        bytes_A = new List<int>(blen);
        bytes_A[0] = byte0;
      }
      for (int i = 1; i < blen; ++i) {
        int byte = ~int.parse(str.substring(p + (i << 1), p + (i << 1) + 2), radix: 16);
        if (byte < -128) byte += 256;
        bytes_A[i + boff] = byte;
      }
    } else {
      if (len & 1 == 1) {
        p = -1;
      }
      int byte0 = int.parse(str.substring(0, p + 2), radix: 16);
      if (byte0 > 127) byte0 -= 256;
      if (byte0 < 0) {
        boff = 1;
        bytes_A = new List<int>(blen + 1);
        bytes_A[0] = 0;
        bytes_A[1] = byte0;
      } else {
        bytes_A = new List<int>(blen);
        bytes_A[0] = byte0;
      }
      for (int i = 1; i < blen; ++i) {
        int byte = int.parse(str.substring(p + (i << 1), p + (i << 1) + 2), radix: 16);
        if (byte > 127) byte -= 256;
        bytes_A[i + boff] = byte;
      }
    }
    return bytes_A;
  }
  BigIntegerDartvm min(BigIntegerDartvm a) {
    return (this.compareTo(a) < 0) ? this : a;
  }
  BigIntegerDartvm max(BigIntegerDartvm a) {
    return (this.compareTo(a) > 0) ? this : a;
  }
  void bitwiseTo(BigIntegerDartvm a, Function op, BigIntegerDartvm r) {
    r.data = op(data, a.data);
  }
  op_and(x_A, y_A) {
    return x_A & y_A;
  }
  and(a) {
    return new BigIntegerDartvm(data & a.data);
  }
  op_or(x_A, y_A) {
    return x_A | y_A;
  }
  or(a) {
    return new BigIntegerDartvm(data | a.data);
  }
  op_xor(x_A, y_A) {
    return x_A ^ y_A;
  }
  xor(a) {
    return new BigIntegerDartvm(data ^ a.data);
  }
  not() {
    return new BigIntegerDartvm(~data);
  }
  shiftLeft(int n) {
    return new BigIntegerDartvm(data << n);
  }
  shiftRight(int n) {
    return new BigIntegerDartvm(data >> n);
  }
  int lbit(int x_A) {
    if (x_A == 0) return -1;
    int r = 0;
    while ((x_A & 0xffffffff) == 0) {
      x_A >>= 32;
      r += 32;
    }
    if ((x_A & 0xffff) == 0) {
      x_A >>= 16;
      r += 16;
    }
    if ((x_A & 0xff) == 0) {
      x_A >>= 8;
      r += 8;
    }
    if ((x_A & 0xf) == 0) {
      x_A >>= 4;
      r += 4;
    }
    if ((x_A & 3) == 0) {
      x_A >>= 2;
      r += 2;
    }
    if ((x_A & 1) == 0) ++r;
    return r;
  }
  getLowestSetBit() {
    return lbit(data);
  }
  int get lowestSetBit => getLowestSetBit();
  testBit(n) {
    return ((data & (1 << n)) != 0);
  }
  addTo(a, r) {
    r.data = data + a.data;
  }
  BigIntegerDartvm add(a) {
    return new BigIntegerDartvm(data + a.data);
  }
  BigIntegerDartvm subtract(a) {
    return new BigIntegerDartvm(data - a.data);
  }
  BigIntegerDartvm multiply(a) {
    return new BigIntegerDartvm(data * a.data);
  }
  BigIntegerDartvm divide(a) {
    return new BigIntegerDartvm(data ~/ a.data);
  }
  BigIntegerDartvm remainder(BigIntegerDartvm a) {
    return new BigIntegerDartvm(data.remainder(a.data));
  }
  dMultiply(n) {
    data *= n;
  }
  dAddOffset(n, w_A) {
    if (w_A == 0) {
      data += n;
    } else {
      throw 'dAddOffset(${n},${w_A}) not implemented';
    }
  }
  modPow(BigIntegerDartvm e, BigIntegerDartvm m) {
    return new BigIntegerDartvm(data.modPow(e.data, m.data));
  }
  BigIntegerDartvm modInverse(BigIntegerDartvm m) {
    return new BigIntegerDartvm(data.modInverse(m.data));
  }
  BigIntegerDartvm operator+(BigIntegerDartvm other) => add(other);
  BigIntegerDartvm operator-(BigIntegerDartvm other) => subtract(other);
  BigIntegerDartvm operator*(BigIntegerDartvm other) => multiply(other);
  BigIntegerDartvm operator%(BigIntegerDartvm other) => mod(other);
  BigIntegerDartvm operator/(BigIntegerDartvm other) => divide(other);
  BigIntegerDartvm operator~/(BigIntegerDartvm other) => divide(other);
  BigIntegerDartvm operator-() => this.negate_op();
  bool operator<(BigIntegerDartvm other) => compareTo(other) < 0 ? true : false;
  bool operator<=(BigIntegerDartvm other) => compareTo(other) <= 0 ? true : false;
  bool operator>(BigIntegerDartvm other) => compareTo(other) > 0 ? true : false;
  bool operator>=(BigIntegerDartvm other) => compareTo(other) >= 0 ? true : false;
  bool operator==(other) => compareTo(other) == 0 ? true : false;
  BigIntegerDartvm operator&(BigIntegerDartvm other) => and(other);
  BigIntegerDartvm operator|(BigIntegerDartvm other) => or(other);
  BigIntegerDartvm operator^(BigIntegerDartvm other) => xor(other);
  BigIntegerDartvm operator~() => not();
  BigIntegerDartvm operator<<(int shiftAmount) => shiftLeft(shiftAmount);
  BigIntegerDartvm operator>>(int shiftAmount) => shiftRight(shiftAmount);
}
class Classic {
  BigIntegerV8 m;
  Classic(this.m);
  convert(x_A) {
    if (x_A.s < 0 || x_A.compareTo(this.m) >= 0) {
      return x_A.mod(this.m);
    } else {
      return x_A;
    }
  }
  revert(x_A) {
    return x_A;
  }
  reduce(x_A) {
    x_A.divRemTo(this.m, null, x_A);
  }
  mulTo(x_A, y_A, r) {
    x_A.multiplyTo(y_A, r);
    this.reduce(r);
  }
  sqrTo(x_A, r) {
    x_A.squareTo(r);
    this.reduce(r);
  }
}
class Montgomery {
  BigIntegerV8 m;
  var mp;
  var mpl;
  var mph;
  var um;
  var mt2;
  Montgomery(this.m) {
    this.mp = m.invDigit();
    this.mpl = this.mp & 0x7fff;
    this.mph = this.mp >> 15;
    this.um = (1 << (BigIntegerV8.BI_DB - 15)) - 1;
    this.mt2 = 2 * m.t;
  }
  BigIntegerV8 convert(BigIntegerV8 x_A) {
    var r = BigIntegerV8.nbi();
    x_A.abs().dlShiftTo(this.m.t, r);
    r.divRemTo(this.m, null, r);
    if (x_A.s < 0 && r.compareTo(BigIntegerV8.ZERO_B) > 0) this.m.subTo(r, r);
    return r;
  }
  BigIntegerV8 revert(BigIntegerV8 x_A) {
    var r = BigIntegerV8.nbi();
    x_A.copyTo(r);
    this.reduce(r);
    return r;
  }
  void reduce(x_A) {
    var x_array = x_A.array;
    while (x_A.t <= this.mt2) {
      x_array[x_A.t++] = 0;
    }
    for (var i = 0; i < this.m.t; ++i) {
      var j = x_array[i] & 0x7fff;
      var u0 = (j * this.mpl + (((j * this.mph + (x_array[i] >> 15) * this.mpl) & this.um) << 15)) & BigIntegerV8.BI_DM;
      j = i + this.m.t;
      x_array[j] += this.m.am(0, u0, x_A, i, 0, this.m.t);
      while (x_array[j] >= BigIntegerV8.BI_DV) {
        x_array[j] -= BigIntegerV8.BI_DV;
        x_array[++j]++;
      }
    }
    x_A.clamp();
    x_A.drShiftTo(this.m.t, x_A);
    if (x_A.compareTo(this.m) >= 0) {
      x_A.subTo(this.m, x_A);
    }
  }
  sqrTo(x_A, r) {
    x_A.squareTo(r);
    this.reduce(r);
  }
  mulTo(x_A, y_A, r) {
    x_A.multiplyTo(y_A, r);
    this.reduce(r);
  }
}
class Barrett {
  BigIntegerV8 m;
  BigIntegerV8 r2;
  BigIntegerV8 q3;
  var mu;
  Barrett(this.m) {
    this.r2 = BigIntegerV8.nbi();
    this.q3 = BigIntegerV8.nbi();
    BigIntegerV8.ONE_B.dlShiftTo(2 * m.t, this.r2);
    this.mu = this.r2.divide(m);
  }
  BigIntegerV8 convert(BigIntegerV8 x_A) {
    if (x_A.s < 0 || x_A.t > 2 * this.m.t) {
      return x_A.mod(this.m);
    } else if (x_A.compareTo(this.m) < 0) {
      return x_A;
    } else {
      var r = BigIntegerV8.nbi();
      x_A.copyTo(r);
      this.reduce(r);
      return r;
    }
  }
  revert(x_A) {
    return x_A;
  }
  void reduce(BigIntegerV8 x_A) {
    x_A.drShiftTo(this.m.t - 1, this.r2);
    if (x_A.t > this.m.t + 1) {
      x_A.t = this.m.t + 1;
      x_A.clamp();
    }
    this.mu.multiplyUpperTo(this.r2, this.m.t + 1, this.q3);
    this.m.multiplyLowerTo(this.q3, this.m.t + 1, this.r2);
    while (x_A.compareTo(this.r2) < 0) {
      x_A.dAddOffset(1, this.m.t + 1);
    }
    x_A.subTo(this.r2, x_A);
    while (x_A.compareTo(this.m) >= 0) {
      x_A.subTo(this.m, x_A);
    }
  }
  sqrTo(x_A, r) {
    x_A.squareTo(r);
    this.reduce(r);
  }
  mulTo(x_A, y_A, r) {
    x_A.multiplyTo(y_A, r);
    this.reduce(r);
  }
}
class JSArray<T_A> {
  operator[](var index_A) {
    return data[index_A];
  }
  operator[]=(var index_A, var value_A) {
    if (index_A > data.length - 1) {
      data.length = index_A + 1;
    }
    return data[index_A] = value_A;
  }
  List<T_A> data = new List<T_A>();
}
class BigIntegerV8 implements BigInteger {
  static int dbits;
  static int BI_DB;
  static int BI_DM;
  static int BI_DV;
  static int BI_FP;
  static int BI_FV;
  static int BI_F1;
  static int BI_F2;
  static BigIntegerV8 nbi() {
    return new BigIntegerV8(null, null, null);
  }
  static BigIntegerV8 nbv(int i) {
    var r = nbi();
    r.fromInt(i);
    return r;
  }
  static BigIntegerV8 get ZERO_B => nbv(0);
  static BigIntegerV8 get ONE_B => nbv(1);
  static final List<int> _lowprimes = const[2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71, 73, 79, 83, 89, 97, 101, 103, 107, 109, 113, 127, 131, 137, 139, 149, 151, 157, 163, 167, 173, 179, 181, 191, 193, 197, 199, 211, 223, 227, 229, 233, 239, 241, 251, 257, 263, 269, 271, 277, 281, 283, 293, 307, 311, 313, 317, 331, 337, 347, 349, 353, 359, 367, 373, 379, 383, 389, 397, 401, 409, 419, 421, 431, 433, 439, 443, 449, 457, 461, 463, 467, 479, 487, 491, 499, 503, 509];
  static int _lplim;
  static int canary = 0xdeadbeefcafe;
  static bool _j_lm;
  JSArray<int> array;
  Function am;
  static var BI_RM = "0123456789abcdefghijklmnopqrstuvwxyz";
  static Map BI_RC;
  int t;
  var s;
  BigIntegerV8([a, b, c]) {
    _init(28);
    am = _am3;
    this.array = new JSArray<int>();
    if (a != null) {
      if (a is int) {
        this.fromString_A(a.toString(), 10);
      } else if (a is num) {
        this.fromString_A(a.toInt().toString(), 10);
      } else if (b == null && a is! String) {
        this.fromString_A(a, 256);
      } else {
        this.fromString_A(a, b);
      }
    }
  }
  factory BigIntegerV8.fromBytes_C(int signum_A, List<int> magnitude_A) {
    if (signum_A == 0) throw new ArgumentError("Argument signum must not be zero");
    if ((magnitude_A[0] & 0x80) != 0) {
      magnitude_A = new Uint8List(1 + magnitude_A.length)
          ..[0] = 0
          ..setRange(1, 1 + magnitude_A.length, magnitude_A);
    }
    var self = new BigIntegerV8(magnitude_A);
    return (signum_A < 0) ? -self : self;
  }
  _am3(i, x_A, w_A, j, c, n) {
    var this_array = this.array;
    var w_array = w_A.array;
    var xl = x_A.toInt() & 0x3fff, xh = x_A.toInt() >> 14;
    while (--n >= 0) {
      var l = this_array[i] & 0x3fff;
      var h = this_array[i++] >> 14;
      var m = xh * l + h * xl;
      l = xl * l + ((m & 0x3fff) << 14) + w_array[j] + c;
      c = (l >> 28) + (m >> 14) + xh * h;
      w_array[j++] = l & 0xfffffff;
    }
    return c;
  }
  static _setupEngine(int bits) {
    dbits = bits;
    BI_DB = dbits;
    BI_DM = ((1 << dbits) - 1);
    BI_DV = (1 << dbits);
    BI_FP = 52;
    BI_FV = pow(2, BI_FP);
    BI_F1 = BI_FP - dbits;
    BI_F2 = 2 * dbits - BI_FP;
  }
  static _init(int bits) {
    if (BI_RC != null) return;
    BI_RC = new Map();
    _j_lm = ((canary & 0xffffff) == 0xefcafe);
    _setupDigitConversions();
    _lplim = (1 << 26) ~/ _lowprimes[_lowprimes.length - 1];
    _setupEngine(bits);
  }
  static _setupDigitConversions() {
    BI_RM = "0123456789abcdefghijklmnopqrstuvwxyz";
    BI_RC = new Map();
    int rr, vv;
    rr = "0".codeUnitAt(0);
    for (vv = 0; vv <= 9; ++vv) BI_RC[rr++] = vv;
    rr = "a".codeUnitAt(0);
    for (vv = 10; vv < 36; ++vv) BI_RC[rr++] = vv;
    rr = "A".codeUnitAt(0);
    for (vv = 10; vv < 36; ++vv) BI_RC[rr++] = vv;
  }
  _int2char(n) {
    return BI_RM[n];
  }
  _intAt(s_A, i) {
    var c = BI_RC[s_A.codeUnitAt(i)];
    return (c == null) ? -1 : c;
  }
  void copyTo(BigIntegerV8 r) {
    var this_array = this.array;
    var r_array = r.array;
    for (var i = this.t - 1; i >= 0; --i) r_array[i] = this_array[i];
    r.t = this.t;
    r.s = this.s;
  }
  void fromInt(int x_A) {
    var this_array = this.array;
    this.t = 1;
    this.s = (x_A < 0) ? -1 : 0;
    if (x_A > 0) {
      this_array[0] = x_A;
    } else if (x_A < -1) {
      this_array[0] = x_A + BI_DV;
    } else {
      this.t = 0;
    }
  }
  void fromString_A(s_A, int b) {
    var this_array = this.array;
    var k;
    if (b == 16) {
      k = 4;
    } else if (b == 8) {
      k = 3;
    } else if (b == 256) {
      k = 8;
    } else if (b == 2) {
      k = 1;
    } else if (b == 32) {
      k = 5;
    } else if (b == 4) {
      k = 2;
    } else {
      this.fromRadix(s_A, b);
      return;
    }
    this.t = 0;
    this.s = 0;
    var i = s_A.length, mi = false, sh = 0;
    while (--i >= 0) {
      var x_A = (k == 8) ? s_A[i] & 0xff : _intAt(s_A, i);
      if (x_A < 0) {
        if (s_A[i] == "-") mi = true;
        continue;
      }
      mi = false;
      if (sh == 0) {
        this_array[this.t++] = x_A;
      } else if (sh + k > BI_DB) {
        this_array[this.t - 1] |= (x_A & ((1 << (BI_DB - sh)) - 1)) << sh;
        this_array[this.t++] = (x_A >> (BI_DB - sh));
      } else {
        this_array[this.t - 1] |= x_A << sh;
      }
      sh += k;
      if (sh >= BI_DB) sh -= BI_DB;
    }
    if (k == 8 && (s_A[0] & 0x80) != 0) {
      this.s = -1;
      if (sh > 0) this_array[this.t - 1] |= ((1 << (BI_DB - sh)) - 1) << sh;
    }
    this.clamp();
    if (mi) BigIntegerV8.ZERO_B.subTo(this, this);
  }
  String toString([int b]) {
    var this_array = this.array;
    if (this.s < 0) {
      return "-${this.negate_op().toString(b)}";
    }
    var k;
    if (b == 16) {
      k = 4;
    } else if (b == 8) {
      k = 3;
    } else if (b == 2) {
      k = 1;
    } else if (b == 32) {
      k = 5;
    } else if (b == 4) {
      k = 2;
    } else {
      return this.toRadix(b);
    }
    var km = (1 << k) - 1, d, m = false, r = "", i = this.t;
    var p = BI_DB - (i * BI_DB) % k;
    if (i-- > 0) {
      if (p < BI_DB && (d = this_array[i] >> p) > 0) {
        m = true;
        r = _int2char(d);
      }
      while (i >= 0) {
        if (p < k) {
          d = (this_array[i] & ((1 << p) - 1)) << (k - p);
          d |= this_array[--i] >> (p += BI_DB - k);
        } else {
          d = (this_array[i].toInt() >> (p -= k.toInt()).toInt()) & km.toInt();
          if (p <= 0) {
            p += BI_DB;
            --i;
          }
        }
        if (d > 0) m = true;
        if (m) r = "${r}${_int2char(d)}";
      }
    }
    return m ? r : "0";
  }
  negate_op() {
    var r = nbi();
    BigIntegerV8.ZERO_B.subTo(this, r);
    return r;
  }
  BigIntegerV8 abs() {
    return (this.s < 0) ? this.negate_op() : this;
  }
  int compareTo(a) {
    if (a is num) {
      a = new BigIntegerV8(a);
    }
    var this_array = this.array;
    var a_array = a.array;
    var r = this.s - a.s;
    if (r != 0) return r;
    var i = this.t;
    r = i - a.t;
    if (r != 0) return r;
    while (--i >= 0) if ((r = this_array[i] - a_array[i]) != 0) return r;
    return 0;
  }
  int nbits(x_A) {
    var r = 1, t_A;
    if (x_A is num) x_A = x_A.toInt();
    if ((t_A = x_A >> 16) != 0) {
      x_A = t_A;
      r += 16;
    }
    if ((t_A = x_A >> 8) != 0) {
      x_A = t_A;
      r += 8;
    }
    if ((t_A = x_A >> 4) != 0) {
      x_A = t_A;
      r += 4;
    }
    if ((t_A = x_A >> 2) != 0) {
      x_A = t_A;
      r += 2;
    }
    if ((t_A = x_A >> 1) != 0) {
      x_A = t_A;
      r += 1;
    }
    return r;
  }
  int bitLength() {
    var this_array = this.array;
    if (this.t <= 0) return 0;
    return BI_DB * (this.t - 1) + nbits(this_array[this.t - 1] ^ (this.s & BI_DM));
  }
  void dlShiftTo(n, r) {
    var this_array = this.array;
    var r_array = r.array;
    var i;
    for (i = this.t - 1; i >= 0; --i) r_array[i + n] = this_array[i];
    for (i = n - 1; i >= 0; --i) r_array[i] = 0;
    r.t = this.t + n;
    r.s = this.s;
  }
  void drShiftTo(n, r) {
    var this_array = this.array;
    var r_array = r.array;
    for (var i = n; i < this.t; ++i) r_array[i - n] = this_array[i];
    r.t = _A.max(this.t - n, 0);
    r.s = this.s;
  }
  void lShiftTo(n, r) {
    var this_array = this.array;
    var r_array = r.array;
    var bs = n % BI_DB;
    var cbs = BI_DB - bs;
    var bm = (1 << cbs) - 1;
    int ds = n ~/ BI_DB;
    var c = (this.s << bs) & BI_DM;
    var i;
    for (i = this.t - 1; i >= 0; --i) {
      r_array[i + ds + 1] = (this_array[i] >> cbs) | c;
      c = (this_array[i] & bm) << bs;
    }
    for (i = ds - 1; i >= 0; --i) r_array[i] = 0;
    r_array[ds] = c;
    r.t = this.t + ds + 1;
    r.s = this.s;
    r.clamp();
  }
  void rShiftTo(n, r) {
    var this_array = this.array;
    var r_array = r.array;
    r.s = this.s;
    var ds = n ~/ BI_DB;
    if (ds >= this.t) {
      r.t = 0;
      return;
    }
    var bs = n % BI_DB;
    var cbs = BI_DB - bs;
    var bm = (1 << bs) - 1;
    r_array[0] = this_array[ds] >> bs;
    for (var i = ds + 1; i < this.t; ++i) {
      r_array[i - ds - 1] |= (this_array[i] & bm) << cbs;
      r_array[i - ds] = this_array[i] >> bs;
    }
    if (bs > 0) r_array[this.t - ds - 1] |= (this.s & bm) << cbs;
    r.t = this.t - ds;
    r.clamp();
  }
  void clamp() {
    var this_array = this.array;
    var c = this.s & BI_DM;
    while (this.t > 0 && this_array[this.t - 1] == c) {
      --this.t;
    }
  }
  void subTo(a, r) {
    var this_array = this.array;
    var r_array = r.array;
    var a_array = a.array;
    int i = 0;
    int c = 0;
    int m = _A.min(a.t, this.t);
    while (i < m) {
      c += (this_array[i].toInt() - a_array[i].toInt()).toInt();
      r_array[i++] = c & BI_DM;
      c >>= BI_DB;
      if (c == 4294967295) {
        c = -1;
      }
    }
    if (a.t < this.t) {
      c -= a.s;
      while (i < this.t) {
        c += this_array[i];
        r_array[i++] = c & BI_DM;
        c >>= BI_DB;
        if (c == 4294967295) {
          c = -1;
        }
      }
      c += this.s;
    } else {
      c += this.s;
      while (i < a.t) {
        c -= a_array[i];
        r_array[i++] = c & BI_DM;
        c >>= BI_DB;
        if (c == 4294967295) {
          c = -1;
        }
      }
      c -= a.s;
    }
    r.s = (c < 0) ? -1 : 0;
    if (c < -1) {
      r_array[i++] = BI_DV + c;
    } else if (c > 0) {
      r_array[i++] = c;
    }
    r.t = i;
    r.clamp();
  }
  bool _debugging = true;
  void multiplyTo(a, r) {
    var this_array = this.array;
    var r_array = r.array;
    BigIntegerV8 x_A = this.abs();
    BigIntegerV8 y_A = a.abs();
    var y_array = y_A.array;
    var i = x_A.t;
    r.t = i + y_A.t;
    while (--i >= 0) r_array[i] = 0;
    for (i = 0; i < y_A.t; ++i) r_array[i + x_A.t] = x_A.am(0, y_array[i], r, i, 0, x_A.t);
    r.s = 0;
    r.clamp();
    if (this.s != a.s) {
      BigIntegerV8.ZERO_B.subTo(r, r);
    }
  }
  void squareTo(r) {
    var x_A = this.abs();
    var x_array = x_A.array;
    var r_array = r.array;
    var i = r.t = 2 * x_A.t;
    while (--i >= 0) r_array[i] = 0;
    for (i = 0; i < x_A.t - 1; ++i) {
      var c = x_A.am(i, x_array[i], r, 2 * i, 0, 1);
      if ((r_array[i + x_A.t] += x_A.am(i + 1, 2 * x_array[i], r, 2 * i + 1, c, x_A.t - i - 1)) >= BI_DV) {
        r_array[i + x_A.t] -= BI_DV;
        r_array[i + x_A.t + 1] = 1;
      }
    }
    if (r.t > 0) r_array[r.t - 1] += x_A.am(i, x_array[i], r, 2 * i, 0, 1);
    r.s = 0;
    r.clamp();
  }
  divRemTo(BigIntegerV8 m, q, BigIntegerV8 r) {
    var pm = m.abs();
    if (pm.t <= 0) return;
    var pt = this.abs();
    if (pt.t < pm.t) {
      if (q != null) q.fromInt(0);
      if (r != null) this.copyTo(r);
      return;
    }
    if (r == null) r = nbi();
    var y_A = nbi(), ts_A = this.s, ms = m.s;
    var pm_array = pm.array;
    var nsh = BI_DB - nbits(pm_array[pm.t - 1]);
    if (nsh > 0) {
      pm.lShiftTo(nsh, y_A);
      pt.lShiftTo(nsh, r);
    } else {
      pm.copyTo(y_A);
      pt.copyTo(r);
    }
    var ys = y_A.t;
    var y_array = y_A.array;
    var y0 = y_array[ys - 1];
    if (y0 == 0) return;
    var yt = y0 * (1 << BI_F1) + ((ys > 1) ? y_array[ys - 2] >> BI_F2 : 0);
    var d1 = BI_FV / yt, d2 = (1 << BI_F1) / yt, e = 1 << BI_F2;
    var i = r.t, j = i - ys;
    BigIntegerV8 t_A = (q == null) ? nbi() : q;
    y_A.dlShiftTo(j, t_A);
    var r_array = r.array;
    if (r.compareTo(t_A) >= 0) {
      r_array[r.t++] = 1;
      r.subTo(t_A, r);
    }
    BigIntegerV8.ONE_B.dlShiftTo(ys, t_A);
    t_A.subTo(y_A, y_A);
    while (y_A.t < ys) y_array[y_A.t++] = 0;
    while (--j >= 0) {
      var qd = (r_array[--i] == y0) ? BI_DM : (r_array[i] * d1 + (r_array[i - 1] + e) * d2).floor();
      if ((r_array[i] += y_A.am(0, qd, r, j, 0, ys)) < qd) {
        y_A.dlShiftTo(j, t_A);
        r.subTo(t_A, r);
        while (r_array[i] < --qd) r.subTo(t_A, r);
      }
    }
    if (q != null) {
      r.drShiftTo(ys, q);
      if (ts_A != ms) BigIntegerV8.ZERO_B.subTo(q, q);
    }
    r.t = ys;
    r.clamp();
    if (nsh > 0) r.rShiftTo(nsh, r);
    if (ts_A < 0) BigIntegerV8.ZERO_B.subTo(r, r);
  }
  mod(a) {
    var r = nbi();
    this.abs().divRemTo(a, null, r);
    if (this.s < 0 && r.compareTo(BigIntegerV8.ZERO_B) > 0) a.subTo(r, r);
    return r;
  }
  invDigit() {
    var this_array = this.array;
    if (this.t < 1) return 0;
    var x_A = this_array[0];
    if ((x_A & 1) == 0) return 0;
    var y_A = x_A & 3;
    y_A = (y_A * (2 - (x_A & 0xf) * y_A)) & 0xf;
    y_A = (y_A * (2 - (x_A & 0xff) * y_A)) & 0xff;
    y_A = (y_A * (2 - (((x_A & 0xffff) * y_A) & 0xffff))) & 0xffff;
    y_A = (y_A * (2 - x_A * y_A % BI_DV)) % BI_DV;
    return (y_A > 0) ? BI_DV - y_A : -y_A;
  }
  isEven() {
    var this_array = this.array;
    return ((this.t > 0) ? (this_array[0] & 1) : this.s) == 0;
  }
  isOdd() => !isEven();
  clone() {
    var r = nbi();
    this.copyTo(r);
    return r;
  }
  int intValue() {
    var this_array = this.array;
    if (this.s < 0) {
      if (this.t == 1) {
        return this_array[0] - BI_DV;
      } else if (this.t == 0) return -1;
    } else if (this.t == 1) {
      return this_array[0];
    } else if (this.t == 0) return 0;
    return ((this_array[1] & ((1 << (32 - BI_DB)) - 1)) << BI_DB) | this_array[0];
  }
  int chunkSize(r) {
    return (LN2 * BI_DB / log(r)).floor().toInt();
  }
  int signum() {
    var this_array = this.array;
    if (this.s < 0) {
      return -1;
    } else if (this.t <= 0 || (this.t == 1 && this_array[0] <= 0)) {
      return 0;
    } else {
      return 1;
    }
  }
  String toRadix([int b = 10]) {
    if (b == null) b = 10;
    if (this.signum() == 0 || b < 2 || b > 36) return "0";
    var cs = this.chunkSize(b);
    int a = pow(b, cs);
    var d = nbv(a), y_A = nbi(), z_A = nbi(), r = "";
    this.divRemTo(d, y_A, z_A);
    while (y_A.signum() > 0) {
      r = "${(a + z_A.intValue()).toInt().toRadixString(b).substring(1)}${r}";
      y_A.divRemTo(d, y_A, z_A);
    }
    return "${z_A.intValue().toRadixString(b)}${r}";
  }
  void fromRadix(s_A, b) {
    this.fromInt(0);
    if (b == null) b = 10;
    var cs = this.chunkSize(b);
    num d = pow(b, cs);
    bool mi = false;
    int j = 0, w_A = 0;
    for (var i = 0; i < s_A.length; ++i) {
      var x_A = _intAt(s_A, i);
      if (x_A < 0) {
        if (s_A is String) {
          if (s_A[0] == "-" && this.signum() == 0) {
            mi = true;
          }
        }
        continue;
      }
      w_A = b * w_A + x_A;
      if (++j >= cs) {
        this.dMultiply(d);
        this.dAddOffset(w_A, 0);
        j = 0;
        w_A = 0;
      }
    }
    if (j > 0) {
      this.dMultiply(pow(b, j));
      if (w_A != 0) {
        this.dAddOffset(w_A, 0);
      }
    }
    if (mi) {
      BigIntegerV8.ZERO_B.subTo(this, this);
    }
  }
  List<int> toByteArray() {
    var this_array = this.array;
    var i = this.t;
    JSArray<int> r = new JSArray<int>();
    r[0] = this.s;
    var p = BI_DB - (i * BI_DB) % 8, d, k = 0;
    if (i-- > 0) {
      if (p < BI_DB && (d = this_array[i] >> p) != (this.s & BI_DM) >> p) {
        r[k++] = d | (this.s << (BI_DB - p));
      }
      while (i >= 0) {
        if (p < 8) {
          d = (this_array[i] & ((1 << p) - 1)) << (8 - p);
          d |= this_array[--i] >> (p += BI_DB - 8);
        } else {
          d = (this_array[i] >> (p -= 8)) & 0xff;
          if (p <= 0) {
            p += BI_DB;
            --i;
          }
        }
        if ((d & 0x80) != 0) d |= -256;
        if (k == 0 && (this.s & 0x80) != (d & 0x80)) ++k;
        if (k > 0 || d != this.s) r[k++] = d;
      }
    }
    return r.data;
  }
  BigIntegerV8 min(BigIntegerV8 a) {
    return (this.compareTo(a) < 0) ? this : a;
  }
  BigIntegerV8 max(BigIntegerV8 a) {
    return (this.compareTo(a) > 0) ? this : a;
  }
  void bitwiseTo(BigIntegerV8 a, Function op, BigIntegerV8 r) {
    var this_array = this.array;
    var a_array = a.array;
    var r_array = r.array;
    var i, f, m = _A.min(a.t, this.t);
    for (i = 0; i < m; ++i) r_array[i] = op(this_array[i], a_array[i]);
    if (a.t < this.t) {
      f = a.s & BI_DM;
      for (i = m; i < this.t; ++i) r_array[i] = op(this_array[i], f);
      r.t = this.t;
    } else {
      f = this.s & BI_DM;
      for (i = m; i < a.t; ++i) r_array[i] = op(f, a_array[i]);
      r.t = a.t;
    }
    r.s = op(this.s, a.s);
    r.clamp();
  }
  op_and(x_A, y_A) {
    return x_A & y_A;
  }
  and(a) {
    var r = nbi();
    this.bitwiseTo(a, op_and, r);
    return r;
  }
  op_or(x_A, y_A) {
    return x_A | y_A;
  }
  or(a) {
    var r = nbi();
    this.bitwiseTo(a, op_or, r);
    return r;
  }
  op_xor(x_A, y_A) {
    return x_A ^ y_A;
  }
  xor(a) {
    var r = nbi();
    this.bitwiseTo(a, op_xor, r);
    return r;
  }
  not() {
    var this_array = this.array;
    var r = nbi();
    var r_array = r.array;
    for (var i = 0; i < this.t; ++i) {
      r_array[i] = BI_DM & ~this_array[i];
    }
    r.t = this.t;
    r.s = ~this.s;
    return r;
  }
  shiftLeft(n) {
    var r = nbi();
    if (n < 0) {
      this.rShiftTo(-n, r);
    } else {
      this.lShiftTo(n, r);
    }
    return r;
  }
  shiftRight(n) {
    var r = nbi();
    if (n < 0) {
      this.lShiftTo(-n, r);
    } else {
      this.rShiftTo(n, r);
    }
    return r;
  }
  lbit(x_A) {
    if (x_A == 0) return -1;
    var r = 0;
    if ((x_A & 0xffff) == 0) {
      x_A >>= 16;
      r += 16;
    }
    if ((x_A & 0xff) == 0) {
      x_A >>= 8;
      r += 8;
    }
    if ((x_A & 0xf) == 0) {
      x_A >>= 4;
      r += 4;
    }
    if ((x_A & 3) == 0) {
      x_A >>= 2;
      r += 2;
    }
    if ((x_A & 1) == 0) ++r;
    return r;
  }
  getLowestSetBit() {
    var this_array = this.array;
    for (var i = 0; i < this.t; ++i) if (this_array[i] != 0) return i * BI_DB + lbit(this_array[i]);
    if (this.s < 0) return this.t * BI_DB;
    return -1;
  }
  int get lowestSetBit => getLowestSetBit();
  testBit(n) {
    var this_array = this.array;
    int j = n ~/ BI_DB;
    if (j >= this.t) return (this.s != 0);
    return ((this_array[j] & (1 << (n % BI_DB))) != 0);
  }
  addTo(a, r) {
    var this_array = this.array;
    var a_array = a.array;
    var r_array = r.array;
    var i = 0, c = 0, m = _A.min(a.t, this.t);
    while (i < m) {
      c += this_array[i] + a_array[i];
      r_array[i++] = c & BI_DM;
      c >>= BI_DB;
    }
    if (a.t < this.t) {
      c += a.s;
      while (i < this.t) {
        c += this_array[i];
        r_array[i++] = c & BI_DM;
        c >>= BI_DB;
      }
      c += this.s;
    } else {
      c += this.s;
      while (i < a.t) {
        c += a_array[i];
        r_array[i++] = c & BI_DM;
        c >>= BI_DB;
      }
      c += a.s;
    }
    r.s = (c < 0) ? -1 : 0;
    if (c > 0) {
      r_array[i++] = c;
    } else if (c < -1) r_array[i++] = BI_DV + c;
    r.t = i;
    r.clamp();
  }
  BigIntegerV8 add(a) {
    var r = nbi();
    this.addTo(a, r);
    return r;
  }
  BigIntegerV8 subtract(a) {
    var r = nbi();
    this.subTo(a, r);
    return r;
  }
  BigIntegerV8 multiply(a) {
    var r = nbi();
    this.multiplyTo(a, r);
    return r;
  }
  BigIntegerV8 divide(a) {
    var r = nbi();
    this.divRemTo(a, r, null);
    return r;
  }
  BigIntegerV8 remainder(BigIntegerV8 a) {
    BigIntegerV8 r = nbi();
    this.divRemTo(a, null, r);
    return (r.signum() >= 0) ? r : (r + a);
  }
  dMultiply(n) {
    var this_array = this.array;
    this_array[this.t] = this.am(0, n - 1, this, 0, 0, this.t);
    ++this.t;
    this.clamp();
  }
  dAddOffset(n, w_A) {
    var this_array = this.array;
    while (this.t <= w_A) this_array[this.t++] = 0;
    this_array[w_A] += n;
    while (this_array[w_A] >= BI_DV) {
      this_array[w_A] -= BI_DV;
      if (++w_A >= this.t) this_array[this.t++] = 0;
      ++this_array[w_A];
    }
  }
  multiplyLowerTo(a, n, r) {
    var r_array = r.array;
    var a_array = a.array;
    var i = _A.min(this.t + a.t, n);
    r.s = 0;
    r.t = i;
    while (i > 0) r_array[--i] = 0;
    var j;
    for (j = r.t - this.t; i < j; ++i) r_array[i + this.t] = this.am(0, a_array[i], r, i, 0, this.t);
    for (j = _A.min(a.t, n); i < j; ++i) this.am(0, a_array[i], r, i, 0, n - i);
    r.clamp();
  }
  multiplyUpperTo(a, n, r) {
    var r_array = r.array;
    var a_array = a.array;
    --n;
    var i = r.t = this.t + a.t - n;
    r.s = 0;
    while (--i >= 0) r_array[i] = 0;
    for (i = _A.max(n - this.t, 0); i < a.t; ++i) {
      r_array[this.t + i - n] = this.am(n - i, a_array[i], r, 0, 0, this.t + i - n);
    }
    r.clamp();
    r.drShiftTo(1, r);
  }
  modPow(BigIntegerV8 e, BigIntegerV8 m) {
    var e_array = e.array;
    var i = e.bitLength(), k, r = nbv(1), z_A;
    if (i <= 0) {
      return r;
    } else if (i < 18) {
      k = 1;
    } else if (i < 48) {
      k = 3;
    } else if (i < 144) {
      k = 4;
    } else if (i < 768) {
      k = 5;
    } else {
      k = 6;
    }
    if (i < 8) {
      z_A = new Classic(m);
    } else if (m.isEven()) {
      z_A = new Barrett(m);
    } else {
      z_A = new Montgomery(m);
    }
    var g = new Map(), n = 3, k1 = k - 1, km = (1 << k) - 1;
    g[1] = z_A.convert(this);
    if (k > 1) {
      var g2 = nbi();
      z_A.sqrTo(g[1], g2);
      while (n <= km) {
        g[n] = nbi();
        z_A.mulTo(g2, g[n - 2], g[n]);
        n += 2;
      }
    }
    var j = e.t - 1, w_A, is1 = true, r2 = nbi(), t_A;
    i = nbits(e_array[j]) - 1;
    while (j >= 0) {
      if (i >= k1) {
        w_A = (e_array[j] >> (i - k1)) & km;
      } else {
        w_A = (e_array[j] & ((1 << (i + 1)) - 1)) << (k1 - i);
        if (j > 0) w_A |= e_array[j - 1] >> (BI_DB + i - k1);
      }
      n = k;
      while ((w_A & 1) == 0) {
        w_A >>= 1;
        --n;
      }
      if ((i -= n) < 0) {
        i += BI_DB;
        --j;
      }
      if (is1) {
        g[w_A].copyTo(r);
        is1 = false;
      } else {
        while (n > 1) {
          z_A.sqrTo(r, r2);
          z_A.sqrTo(r2, r);
          n -= 2;
        }
        if (n > 0) z_A.sqrTo(r, r2); else {
          t_A = r;
          r = r2;
          r2 = t_A;
        }
        z_A.mulTo(r2, g[w_A], r);
      }
      while (j >= 0 && (e_array[j] & (1 << i)) == 0) {
        z_A.sqrTo(r, r2);
        t_A = r;
        r = r2;
        r2 = t_A;
        if (--i < 0) {
          i = BI_DB - 1;
          --j;
        }
      }
    }
    return z_A.revert(r);
  }
  BigIntegerV8 modInverse(BigIntegerV8 m) {
    var ac = m.isEven();
    if ((this.isEven() && ac) || m.signum() == 0) return BigIntegerV8.ZERO_B;
    var u = m.clone(), v = this.clone();
    if (v.signum() < 0) v = -v;
    var a = nbv(1), b = nbv(0), c = nbv(0), d = nbv(1);
    while (u.signum() != 0) {
      while (u.isEven()) {
        u.rShiftTo(1, u);
        if (ac) {
          if (!a.isEven() || !b.isEven()) {
            a.addTo(this, a);
            b.subTo(m, b);
          }
          a.rShiftTo(1, a);
        } else if (!b.isEven()) b.subTo(m, b);
        b.rShiftTo(1, b);
      }
      while (v.isEven()) {
        v.rShiftTo(1, v);
        if (ac) {
          if (!c.isEven() || !d.isEven()) {
            c.addTo(this, c);
            d.subTo(m, d);
          }
          c.rShiftTo(1, c);
        } else if (!d.isEven()) d.subTo(m, d);
        d.rShiftTo(1, d);
      }
      if (u.compareTo(v) >= 0) {
        u.subTo(v, u);
        if (ac) a.subTo(c, a);
        b.subTo(d, b);
      } else {
        v.subTo(u, v);
        if (ac) c.subTo(a, c);
        d.subTo(b, d);
      }
    }
    if (v.compareTo(BigIntegerV8.ONE_B) != 0) return BigIntegerV8.ZERO_B;
    if (d.compareTo(m) >= 0) return _adjust(d.subtract(m), m);
    if (d.signum() < 0) d.addTo(m, d); else return _adjust(d, m);
    if (d.signum() < 0) return _adjust(d.add(m), m); else return _adjust(d, m);
  }
  _adjust(val, m) => (signum() < 0) ? (m - val) : val;
  BigIntegerV8 operator+(BigIntegerV8 other) => add(other);
  BigIntegerV8 operator-(BigIntegerV8 other) => subtract(other);
  BigIntegerV8 operator*(BigIntegerV8 other) => multiply(other);
  BigIntegerV8 operator%(BigIntegerV8 other) => remainder(other);
  BigIntegerV8 operator/(BigIntegerV8 other) => divide(other);
  BigIntegerV8 operator~/(BigIntegerV8 other) => divide(other);
  BigIntegerV8 operator-() => this.negate_op();
  bool operator<(BigIntegerV8 other) => compareTo(other) < 0 ? true : false;
  bool operator<=(BigIntegerV8 other) => compareTo(other) <= 0 ? true : false;
  bool operator>(BigIntegerV8 other) => compareTo(other) > 0 ? true : false;
  bool operator>=(BigIntegerV8 other) => compareTo(other) >= 0 ? true : false;
  bool operator==(other) => compareTo(other) == 0 ? true : false;
  BigIntegerV8 operator&(BigIntegerV8 other) => and(other);
  BigIntegerV8 operator|(BigIntegerV8 other) => or(other);
  BigIntegerV8 operator^(BigIntegerV8 other) => xor(other);
  BigIntegerV8 operator~() => not();
  BigIntegerV8 operator<<(int shiftAmount) => shiftLeft(shiftAmount);
  BigIntegerV8 operator>>(int shiftAmount) => shiftRight(shiftAmount);
}
class ByteStream extends StreamView<List<int>> {
  ByteStream(Stream<List<int>> stream_A) : super(stream_A);
  factory ByteStream.fromBytes_D(List<int> bytes_A) => new ByteStream(new Stream.fromIterable([bytes_A]));
  Future<Uint8List> toBytes() {
    var completer = new Completer<Uint8List>();
    var sink_A = new ByteConversionSink.withCallback((bytes_A) => completer.complete(new Uint8List.fromList(bytes_A)));
    listen(sink_A.add, onError: completer.completeError, onDone: sink_A.close, cancelOnError: true);
    return completer.future;
  }
}
typedef C _Canonicalize<C, K>(K _0);
typedef bool _IsValidKey(Object _0);
class CanonicalizedMap<C, K, V> implements Map<K, V> {
  final _Canonicalize<C, K> _canonicalize;
  final _IsValidKey _isValidKeyFn;
  final _base = new Map<C, Pair<K, V>>();
  CanonicalizedMap.from_A(Map<K, V> other, C canonicalize(K key), {bool isValidKey(Object key)}) : _canonicalize = canonicalize, _isValidKeyFn = isValidKey {
    addAll(other);
  }
  V operator[](Object key_A) {
    if (!_isValidKey(key_A)) return null;
    var pair = _base[_canonicalize(key_A as K)];
    return pair == null ? null : pair.last;
  }
  void operator[]=(K key_A, V value_A) {
    if (!_isValidKey(key_A)) return;
    _base[_canonicalize(key_A)] = new Pair(key_A, value_A);
  }
  void addAll(Map<K, V> other) {
    other.forEach((key_A, value_A) => this[key_A] = value_A);
  }
  void clear() {
    _base.clear();
  }
  bool containsKey(Object key_A) {
    if (!_isValidKey(key_A)) return false;
    return _base.containsKey(_canonicalize(key_A as K));
  }
  bool containsValue(Object value_A) => _base.values.any((pair) => pair.last == value_A);
  void forEach(void f(K key, V value)) {
    _base.forEach((key_A, pair) => f(pair.first, pair.last));
  }
  bool get isEmpty => _base.isEmpty;
  bool get isNotEmpty => _base.isNotEmpty;
  Iterable<K> get keys => _base.values.map((pair) => pair.first);
  int get length => _base.length;
  V putIfAbsent(K key_A, V ifAbsent()) {
    return _base.putIfAbsent(_canonicalize(key_A), () => new Pair(key_A, ifAbsent())).last;
  }
  V remove(Object key_A) {
    if (!_isValidKey(key_A)) return null;
    var pair = _base.remove(_canonicalize(key_A as K));
    return pair == null ? null : pair.last;
  }
  Iterable<V> get values => _base.values.map((pair) => pair.last);
  String toString() => Maps.mapToString(this);
  bool _isValidKey(Object key_A) => (key_A == null || key_A is K) && (_isValidKeyFn == null || _isValidKeyFn(key_A));
}
class CaseInsensitiveMap<V> extends CanonicalizedMap<String, String, V> {
  CaseInsensitiveMap.from_B(Map<String, V> other) : super.from_A(other, (key_A) => key_A.toLowerCase(), isValidKey: (key_A) => key_A != null);
}
abstract class CipherParameters {}
abstract class AsymmetricKey {}
abstract class PublicKey implements AsymmetricKey {}
abstract class PrivateKey implements AsymmetricKey {}
class AsymmetricKeyPair<B extends PublicKey, V extends PrivateKey> {
  final B publicKey;
  final V privateKey;
  AsymmetricKeyPair(this.publicKey, this.privateKey);
}
abstract class KeyGenerator {}
abstract class SecureRandom {
  static final registry = new Registry<SecureRandom>();
  factory SecureRandom([String algorithmName_A = ""]) => registry.create(algorithmName_A);
}
abstract class BlockCipher {}
abstract class Digest {}
abstract class ECDomainParameters {}
abstract class ECFieldElement {}
abstract class ECPoint {}
abstract class ECCurve {}
abstract class ECAsymmetricKey implements AsymmetricKey {
  final ECDomainParameters parameters;
  ECAsymmetricKey(this.parameters);
}
class ECPrivateKey extends ECAsymmetricKey implements PrivateKey {
  final BigInteger d;
  ECPrivateKey(this.d, ECDomainParameters parameters_A) : super(parameters_A);
  bool operator==(other) {
    if (other == null) return false;
    if (other is! ECPrivateKey) return false;
    return (other.parameters == this.parameters) && (other.d == this.d);
  }
  int get hashCode {
    return parameters.hashCode + d.hashCode;
  }
}
class ECPublicKey extends ECAsymmetricKey implements PublicKey {
  final ECPoint Q;
  ECPublicKey(this.Q, ECDomainParameters parameters_A) : super(parameters_A);
  bool operator==(other) {
    if (other == null) return false;
    if (other is! ECPublicKey) return false;
    return (other.parameters == this.parameters) && (other.Q == this.Q);
  }
  int get hashCode {
    return parameters.hashCode + Q.hashCode;
  }
}
class Registry<T_A> {
  final _staticFactories = new Map<String, Function>();
  final _dynamicFactories = new List<Function>();
  operator[]=(String algorithmName, T_A factory_A(String)) => registerStaticFactory(algorithmName, factory_A);
  void registerStaticFactory(String algorithmName, T_A factory_A(String)) {
    _staticFactories[algorithmName] = factory_A;
  }
  T_A create(String algorithmName) {
    var factory_A = _staticFactories[algorithmName];
    if (factory_A != null) {
      return factory_A(algorithmName);
    } else {
      for (factory_A in _dynamicFactories) {
        var algorithm_A = factory_A(algorithmName);
        if (algorithm_A != null) {
          return algorithm_A;
        }
      }
    }
    throw new UnsupportedError("No algorithm with that name registered: ${algorithmName}");
  }
}
class AESFastEngine extends BaseBlockCipher {
  static const _BLOCK_SIZE_A = 16;
  bool _forEncryption;
  List<List<int>> _workingKey;
  int _ROUNDS;
  int _C0;
  int _C1;
  int _C2;
  int _C3;
  int get blockSize => _BLOCK_SIZE_A;
  void reset() {
    _ROUNDS = 0;
    _C0 = _C1 = _C2 = _C3 = 0;
    _forEncryption = false;
    _workingKey = null;
  }
  void init(bool forEncryption, KeyParameter params) {
    var key_A = params.key;
    int KC = (key_A.lengthInBytes / 4).floor();
    if (((KC != 4) && (KC != 6) && (KC != 8)) || ((KC * 4) != key_A.lengthInBytes)) {
      throw new ArgumentError("Key length must be 128/192/256 bits");
    }
    this._forEncryption = forEncryption;
    _ROUNDS = KC + 6;
    _workingKey = new List.generate(_ROUNDS + 1, (int i) => new List<int>(4));
    var keyView = new ByteData.view(params.key.buffer);
    for (var i = 0, t = 0; i < key_A.lengthInBytes; i += 4, t++) {
      var value_A = unpack32(keyView, i, Endianness.LITTLE_ENDIAN);
      _workingKey[t >> 2][t & 3] = value_A;
    }
    int k = (_ROUNDS + 1) << 2;
    for (int i = KC; i < k; i++) {
      int temp = _workingKey[(i - 1) >> 2][(i - 1) & 3].toInt();
      if ((i % KC) == 0) {
        temp = _subWord(_shift(temp, 8)) ^ _rcon[((i / KC) - 1).floor()];
      } else if ((KC > 6) && ((i % KC) == 4)) {
        temp = _subWord(temp);
      }
      var value_A = _workingKey[(i - KC) >> 2][(i - KC) & 3] ^ temp;
      _workingKey[i >> 2][i & 3] = value_A;
    }
    if (!forEncryption) {
      for (var j = 1; j < _ROUNDS; j++) {
        for (var i = 0; i < 4; i++) {
          var value_A = _inv_mcol(_workingKey[j][i].toInt());
          _workingKey[j][i] = value_A;
        }
      }
    }
  }
  int processBlock(Uint8List inp, int inpOff, Uint8List out, int outOff) {
    if (_workingKey == null) {
      throw new StateError("AES engine not initialised");
    }
    if ((inpOff + (32 / 2)) > inp.lengthInBytes) {
      throw new ArgumentError("Input buffer too short");
    }
    if ((outOff + (32 / 2)) > out.lengthInBytes) {
      throw new ArgumentError("Output buffer too short");
    }
    var inpView = new ByteData.view(inp.buffer);
    var outView = new ByteData.view(out.buffer);
    if (_forEncryption) {
      _unpackBlock(inpView, inpOff);
      _encryptBlock(_workingKey);
      _packBlock(outView, outOff);
    } else {
      _unpackBlock(inpView, inpOff);
      _decryptBlock(_workingKey);
      _packBlock(outView, outOff);
    }
    return _BLOCK_SIZE_A;
  }
  void _encryptBlock(List<List<int>> KW) {
    int r, r0, r1, r2, r3;
    _C0 ^= KW[0][0].toInt();
    _C1 ^= KW[0][1].toInt();
    _C2 ^= KW[0][2].toInt();
    _C3 ^= KW[0][3].toInt();
    r = 1;
    while (r < _ROUNDS - 1) {
      r0 = _T0[_C0 & 255] ^ _T1[(_C1 >> 8) & 255] ^ _T2[(_C2 >> 16) & 255] ^ _T3[(_C3 >> 24) & 255] ^ KW[r][0].toInt();
      r1 = _T0[_C1 & 255] ^ _T1[(_C2 >> 8) & 255] ^ _T2[(_C3 >> 16) & 255] ^ _T3[(_C0 >> 24) & 255] ^ KW[r][1].toInt();
      r2 = _T0[_C2 & 255] ^ _T1[(_C3 >> 8) & 255] ^ _T2[(_C0 >> 16) & 255] ^ _T3[(_C1 >> 24) & 255] ^ KW[r][2].toInt();
      r3 = _T0[_C3 & 255] ^ _T1[(_C0 >> 8) & 255] ^ _T2[(_C1 >> 16) & 255] ^ _T3[(_C2 >> 24) & 255] ^ KW[r][3].toInt();
      r++;
      _C0 = _T0[r0 & 255] ^ _T1[(r1 >> 8) & 255] ^ _T2[(r2 >> 16) & 255] ^ _T3[(r3 >> 24) & 255] ^ KW[r][0].toInt();
      _C1 = _T0[r1 & 255] ^ _T1[(r2 >> 8) & 255] ^ _T2[(r3 >> 16) & 255] ^ _T3[(r0 >> 24) & 255] ^ KW[r][1].toInt();
      _C2 = _T0[r2 & 255] ^ _T1[(r3 >> 8) & 255] ^ _T2[(r0 >> 16) & 255] ^ _T3[(r1 >> 24) & 255] ^ KW[r][2].toInt();
      _C3 = _T0[r3 & 255] ^ _T1[(r0 >> 8) & 255] ^ _T2[(r1 >> 16) & 255] ^ _T3[(r2 >> 24) & 255] ^ KW[r][3].toInt();
      r++;
    }
    r0 = _T0[_C0 & 255] ^ _T1[(_C1 >> 8) & 255] ^ _T2[(_C2 >> 16) & 255] ^ _T3[(_C3 >> 24) & 255] ^ KW[r][0].toInt();
    r1 = _T0[_C1 & 255] ^ _T1[(_C2 >> 8) & 255] ^ _T2[(_C3 >> 16) & 255] ^ _T3[(_C0 >> 24) & 255] ^ KW[r][1].toInt();
    r2 = _T0[_C2 & 255] ^ _T1[(_C3 >> 8) & 255] ^ _T2[(_C0 >> 16) & 255] ^ _T3[(_C1 >> 24) & 255] ^ KW[r][2].toInt();
    r3 = _T0[_C3 & 255] ^ _T1[(_C0 >> 8) & 255] ^ _T2[(_C1 >> 16) & 255] ^ _T3[(_C2 >> 24) & 255] ^ KW[r][3].toInt();
    r++;
    _C0 = (_S[r0 & 255] & 255) ^ ((_S[(r1 >> 8) & 255] & 255) << 8) ^ ((_S[(r2 >> 16) & 255] & 255) << 16) ^ (_S[(r3 >> 24) & 255] << 24) ^ KW[r][0].toInt();
    _C1 = (_S[r1 & 255] & 255) ^ ((_S[(r2 >> 8) & 255] & 255) << 8) ^ ((_S[(r3 >> 16) & 255] & 255) << 16) ^ (_S[(r0 >> 24) & 255] << 24) ^ KW[r][1].toInt();
    _C2 = (_S[r2 & 255] & 255) ^ ((_S[(r3 >> 8) & 255] & 255) << 8) ^ ((_S[(r0 >> 16) & 255] & 255) << 16) ^ (_S[(r1 >> 24) & 255] << 24) ^ KW[r][2].toInt();
    _C3 = (_S[r3 & 255] & 255) ^ ((_S[(r0 >> 8) & 255] & 255) << 8) ^ ((_S[(r1 >> 16) & 255] & 255) << 16) ^ (_S[(r2 >> 24) & 255] << 24) ^ KW[r][3].toInt();
  }
  void _decryptBlock(List<List<int>> KW) {
    int r, r0, r1, r2, r3;
    _C0 ^= KW[_ROUNDS][0].toInt();
    _C1 ^= KW[_ROUNDS][1].toInt();
    _C2 ^= KW[_ROUNDS][2].toInt();
    _C3 ^= KW[_ROUNDS][3].toInt();
    r = _ROUNDS - 1;
    while (r > 1) {
      r0 = _Tinv0[_C0 & 255] ^ _Tinv1[(_C3 >> 8) & 255] ^ _Tinv2[(_C2 >> 16) & 255] ^ _Tinv3[(_C1 >> 24) & 255] ^ KW[r][0].toInt();
      r1 = _Tinv0[_C1 & 255] ^ _Tinv1[(_C0 >> 8) & 255] ^ _Tinv2[(_C3 >> 16) & 255] ^ _Tinv3[(_C2 >> 24) & 255] ^ KW[r][1].toInt();
      r2 = _Tinv0[_C2 & 255] ^ _Tinv1[(_C1 >> 8) & 255] ^ _Tinv2[(_C0 >> 16) & 255] ^ _Tinv3[(_C3 >> 24) & 255] ^ KW[r][2].toInt();
      r3 = _Tinv0[_C3 & 255] ^ _Tinv1[(_C2 >> 8) & 255] ^ _Tinv2[(_C1 >> 16) & 255] ^ _Tinv3[(_C0 >> 24) & 255] ^ KW[r][3].toInt();
      r--;
      _C0 = _Tinv0[r0 & 255] ^ _Tinv1[(r3 >> 8) & 255] ^ _Tinv2[(r2 >> 16) & 255] ^ _Tinv3[(r1 >> 24) & 255] ^ KW[r][0].toInt();
      _C1 = _Tinv0[r1 & 255] ^ _Tinv1[(r0 >> 8) & 255] ^ _Tinv2[(r3 >> 16) & 255] ^ _Tinv3[(r2 >> 24) & 255] ^ KW[r][1].toInt();
      _C2 = _Tinv0[r2 & 255] ^ _Tinv1[(r1 >> 8) & 255] ^ _Tinv2[(r0 >> 16) & 255] ^ _Tinv3[(r3 >> 24) & 255] ^ KW[r][2].toInt();
      _C3 = _Tinv0[r3 & 255] ^ _Tinv1[(r2 >> 8) & 255] ^ _Tinv2[(r1 >> 16) & 255] ^ _Tinv3[(r0 >> 24) & 255] ^ KW[r][3].toInt();
      r--;
    }
    r0 = _Tinv0[_C0 & 255] ^ _Tinv1[(_C3 >> 8) & 255] ^ _Tinv2[(_C2 >> 16) & 255] ^ _Tinv3[(_C1 >> 24) & 255] ^ KW[r][0].toInt();
    r1 = _Tinv0[_C1 & 255] ^ _Tinv1[(_C0 >> 8) & 255] ^ _Tinv2[(_C3 >> 16) & 255] ^ _Tinv3[(_C2 >> 24) & 255] ^ KW[r][1].toInt();
    r2 = _Tinv0[_C2 & 255] ^ _Tinv1[(_C1 >> 8) & 255] ^ _Tinv2[(_C0 >> 16) & 255] ^ _Tinv3[(_C3 >> 24) & 255] ^ KW[r][2].toInt();
    r3 = _Tinv0[_C3 & 255] ^ _Tinv1[(_C2 >> 8) & 255] ^ _Tinv2[(_C1 >> 16) & 255] ^ _Tinv3[(_C0 >> 24) & 255] ^ KW[r][3].toInt();
    _C0 = (_Si[r0 & 255] & 255) ^ ((_Si[(r3 >> 8) & 255] & 255) << 8) ^ ((_Si[(r2 >> 16) & 255] & 255) << 16) ^ (_Si[(r1 >> 24) & 255] << 24) ^ KW[0][0].toInt();
    _C1 = (_Si[r1 & 255] & 255) ^ ((_Si[(r0 >> 8) & 255] & 255) << 8) ^ ((_Si[(r3 >> 16) & 255] & 255) << 16) ^ (_Si[(r2 >> 24) & 255] << 24) ^ KW[0][1].toInt();
    _C2 = (_Si[r2 & 255] & 255) ^ ((_Si[(r1 >> 8) & 255] & 255) << 8) ^ ((_Si[(r0 >> 16) & 255] & 255) << 16) ^ (_Si[(r3 >> 24) & 255] << 24) ^ KW[0][2].toInt();
    _C3 = (_Si[r3 & 255] & 255) ^ ((_Si[(r2 >> 8) & 255] & 255) << 8) ^ ((_Si[(r1 >> 16) & 255] & 255) << 16) ^ (_Si[(r0 >> 24) & 255] << 24) ^ KW[0][3].toInt();
  }
  void _unpackBlock(ByteData view_A, int off) {
    _C0 = unpack32(view_A, off, Endianness.LITTLE_ENDIAN);
    _C1 = unpack32(view_A, off + 4, Endianness.LITTLE_ENDIAN);
    _C2 = unpack32(view_A, off + 8, Endianness.LITTLE_ENDIAN);
    _C3 = unpack32(view_A, off + 12, Endianness.LITTLE_ENDIAN);
  }
  void _packBlock(ByteData view_A, int off) {
    pack32(_C0, view_A, off, Endianness.LITTLE_ENDIAN);
    pack32(_C1, view_A, off + 4, Endianness.LITTLE_ENDIAN);
    pack32(_C2, view_A, off + 8, Endianness.LITTLE_ENDIAN);
    pack32(_C3, view_A, off + 12, Endianness.LITTLE_ENDIAN);
  }
}
int _shift(int r, int shift) => rotr32(r, shift);
const int _m1 = 0x80808080;
const int _m2 = 0x7f7f7f7f;
const int _m3 = 0x0000001b;
int _FFmulX(int x_A) {
  var lsr = shiftr32((x_A & _m1), 7);
  return (((x_A & _m2) << 1) ^ lsr * _m3);
}
int _inv_mcol(int x_A) {
  int f2 = _FFmulX(x_A);
  int f4 = _FFmulX(f2);
  int f8 = _FFmulX(f4);
  int f9 = x_A ^ f8;
  return f2 ^ f4 ^ f8 ^ _shift(f2 ^ f9, 8) ^ _shift(f4 ^ f9, 16) ^ _shift(f9, 24);
}
int _subWord(int x_A) {
  return (_S[x_A & 255] & 255 | ((_S[(x_A >> 8) & 255] & 255) << 8) | ((_S[(x_A >> 16) & 255] & 255) << 16) | _S[(x_A >> 24) & 255] << 24);
}
final _S = [99, 124, 119, 123, 242, 107, 111, 197, 48, 1, 103, 43, 254, 215, 171, 118, 202, 130, 201, 125, 250, 89, 71, 240, 173, 212, 162, 175, 156, 164, 114, 192, 183, 253, 147, 38, 54, 63, 247, 204, 52, 165, 229, 241, 113, 216, 49, 21, 4, 199, 35, 195, 24, 150, 5, 154, 7, 18, 128, 226, 235, 39, 178, 117, 9, 131, 44, 26, 27, 110, 90, 160, 82, 59, 214, 179, 41, 227, 47, 132, 83, 209, 0, 237, 32, 252, 177, 91, 106, 203, 190, 57, 74, 76, 88, 207, 208, 239, 170, 251, 67, 77, 51, 133, 69, 249, 2, 127, 80, 60, 159, 168, 81, 163, 64, 143, 146, 157, 56, 245, 188, 182, 218, 33, 16, 255, 243, 210, 205, 12, 19, 236, 95, 151, 68, 23, 196, 167, 126, 61, 100, 93, 25, 115, 96, 129, 79, 220, 34, 42, 144, 136, 70, 238, 184, 20, 222, 94, 11, 219, 224, 50, 58, 10, 73, 6, 36, 92, 194, 211, 172, 98, 145, 149, 228, 121, 231, 200, 55, 109, 141, 213, 78, 169, 108, 86, 244, 234, 101, 122, 174, 8, 186, 120, 37, 46, 28, 166, 180, 198, 232, 221, 116, 31, 75, 189, 139, 138, 112, 62, 181, 102, 72, 3, 246, 14, 97, 53, 87, 185, 134, 193, 29, 158, 225, 248, 152, 17, 105, 217, 142, 148, 155, 30, 135, 233, 206, 85, 40, 223, 140, 161, 137, 13, 191, 230, 66, 104, 65, 153, 45, 15, 176, 84, 187, 22];
final _Si = [82, 9, 106, 213, 48, 54, 165, 56, 191, 64, 163, 158, 129, 243, 215, 251, 124, 227, 57, 130, 155, 47, 255, 135, 52, 142, 67, 68, 196, 222, 233, 203, 84, 123, 148, 50, 166, 194, 35, 61, 238, 76, 149, 11, 66, 250, 195, 78, 8, 46, 161, 102, 40, 217, 36, 178, 118, 91, 162, 73, 109, 139, 209, 37, 114, 248, 246, 100, 134, 104, 152, 22, 212, 164, 92, 204, 93, 101, 182, 146, 108, 112, 72, 80, 253, 237, 185, 218, 94, 21, 70, 87, 167, 141, 157, 132, 144, 216, 171, 0, 140, 188, 211, 10, 247, 228, 88, 5, 184, 179, 69, 6, 208, 44, 30, 143, 202, 63, 15, 2, 193, 175, 189, 3, 1, 19, 138, 107, 58, 145, 17, 65, 79, 103, 220, 234, 151, 242, 207, 206, 240, 180, 230, 115, 150, 172, 116, 34, 231, 173, 53, 133, 226, 249, 55, 232, 28, 117, 223, 110, 71, 241, 26, 113, 29, 41, 197, 137, 111, 183, 98, 14, 170, 24, 190, 27, 252, 86, 62, 75, 198, 210, 121, 32, 154, 219, 192, 254, 120, 205, 90, 244, 31, 221, 168, 51, 136, 7, 199, 49, 177, 18, 16, 89, 39, 128, 236, 95, 96, 81, 127, 169, 25, 181, 74, 13, 45, 229, 122, 159, 147, 201, 156, 239, 160, 224, 59, 77, 174, 42, 245, 176, 200, 235, 187, 60, 131, 83, 153, 97, 23, 43, 4, 126, 186, 119, 214, 38, 225, 105, 20, 99, 85, 33, 12, 125];
final _rcon = [0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80, 0x1b, 0x36, 0x6c, 0xd8, 0xab, 0x4d, 0x9a, 0x2f, 0x5e, 0xbc, 0x63, 0xc6, 0x97, 0x35, 0x6a, 0xd4, 0xb3, 0x7d, 0xfa, 0xef, 0xc5, 0x91];
final _T0 = [0xa56363c6, 0x847c7cf8, 0x997777ee, 0x8d7b7bf6, 0x0df2f2ff, 0xbd6b6bd6, 0xb16f6fde, 0x54c5c591, 0x50303060, 0x03010102, 0xa96767ce, 0x7d2b2b56, 0x19fefee7, 0x62d7d7b5, 0xe6abab4d, 0x9a7676ec, 0x45caca8f, 0x9d82821f, 0x40c9c989, 0x877d7dfa, 0x15fafaef, 0xeb5959b2, 0xc947478e, 0x0bf0f0fb, 0xecadad41, 0x67d4d4b3, 0xfda2a25f, 0xeaafaf45, 0xbf9c9c23, 0xf7a4a453, 0x967272e4, 0x5bc0c09b, 0xc2b7b775, 0x1cfdfde1, 0xae93933d, 0x6a26264c, 0x5a36366c, 0x413f3f7e, 0x02f7f7f5, 0x4fcccc83, 0x5c343468, 0xf4a5a551, 0x34e5e5d1, 0x08f1f1f9, 0x937171e2, 0x73d8d8ab, 0x53313162, 0x3f15152a, 0x0c040408, 0x52c7c795, 0x65232346, 0x5ec3c39d, 0x28181830, 0xa1969637, 0x0f05050a, 0xb59a9a2f, 0x0907070e, 0x36121224, 0x9b80801b, 0x3de2e2df, 0x26ebebcd, 0x6927274e, 0xcdb2b27f, 0x9f7575ea, 0x1b090912, 0x9e83831d, 0x742c2c58, 0x2e1a1a34, 0x2d1b1b36, 0xb26e6edc, 0xee5a5ab4, 0xfba0a05b, 0xf65252a4, 0x4d3b3b76, 0x61d6d6b7, 0xceb3b37d, 0x7b292952, 0x3ee3e3dd, 0x712f2f5e, 0x97848413, 0xf55353a6, 0x68d1d1b9, 0x00000000, 0x2cededc1, 0x60202040, 0x1ffcfce3, 0xc8b1b179, 0xed5b5bb6, 0xbe6a6ad4, 0x46cbcb8d, 0xd9bebe67, 0x4b393972, 0xde4a4a94, 0xd44c4c98, 0xe85858b0, 0x4acfcf85, 0x6bd0d0bb, 0x2aefefc5, 0xe5aaaa4f, 0x16fbfbed, 0xc5434386, 0xd74d4d9a, 0x55333366, 0x94858511, 0xcf45458a, 0x10f9f9e9, 0x06020204, 0x817f7ffe, 0xf05050a0, 0x443c3c78, 0xba9f9f25, 0xe3a8a84b, 0xf35151a2, 0xfea3a35d, 0xc0404080, 0x8a8f8f05, 0xad92923f, 0xbc9d9d21, 0x48383870, 0x04f5f5f1, 0xdfbcbc63, 0xc1b6b677, 0x75dadaaf, 0x63212142, 0x30101020, 0x1affffe5, 0x0ef3f3fd, 0x6dd2d2bf, 0x4ccdcd81, 0x140c0c18, 0x35131326, 0x2fececc3, 0xe15f5fbe, 0xa2979735, 0xcc444488, 0x3917172e, 0x57c4c493, 0xf2a7a755, 0x827e7efc, 0x473d3d7a, 0xac6464c8, 0xe75d5dba, 0x2b191932, 0x957373e6, 0xa06060c0, 0x98818119, 0xd14f4f9e, 0x7fdcdca3, 0x66222244, 0x7e2a2a54, 0xab90903b, 0x8388880b, 0xca46468c, 0x29eeeec7, 0xd3b8b86b, 0x3c141428, 0x79dedea7, 0xe25e5ebc, 0x1d0b0b16, 0x76dbdbad, 0x3be0e0db, 0x56323264, 0x4e3a3a74, 0x1e0a0a14, 0xdb494992, 0x0a06060c, 0x6c242448, 0xe45c5cb8, 0x5dc2c29f, 0x6ed3d3bd, 0xefacac43, 0xa66262c4, 0xa8919139, 0xa4959531, 0x37e4e4d3, 0x8b7979f2, 0x32e7e7d5, 0x43c8c88b, 0x5937376e, 0xb76d6dda, 0x8c8d8d01, 0x64d5d5b1, 0xd24e4e9c, 0xe0a9a949, 0xb46c6cd8, 0xfa5656ac, 0x07f4f4f3, 0x25eaeacf, 0xaf6565ca, 0x8e7a7af4, 0xe9aeae47, 0x18080810, 0xd5baba6f, 0x887878f0, 0x6f25254a, 0x722e2e5c, 0x241c1c38, 0xf1a6a657, 0xc7b4b473, 0x51c6c697, 0x23e8e8cb, 0x7cdddda1, 0x9c7474e8, 0x211f1f3e, 0xdd4b4b96, 0xdcbdbd61, 0x868b8b0d, 0x858a8a0f, 0x907070e0, 0x423e3e7c, 0xc4b5b571, 0xaa6666cc, 0xd8484890, 0x05030306, 0x01f6f6f7, 0x120e0e1c, 0xa36161c2, 0x5f35356a, 0xf95757ae, 0xd0b9b969, 0x91868617, 0x58c1c199, 0x271d1d3a, 0xb99e9e27, 0x38e1e1d9, 0x13f8f8eb, 0xb398982b, 0x33111122, 0xbb6969d2, 0x70d9d9a9, 0x898e8e07, 0xa7949433, 0xb69b9b2d, 0x221e1e3c, 0x92878715, 0x20e9e9c9, 0x49cece87, 0xff5555aa, 0x78282850, 0x7adfdfa5, 0x8f8c8c03, 0xf8a1a159, 0x80898909, 0x170d0d1a, 0xdabfbf65, 0x31e6e6d7, 0xc6424284, 0xb86868d0, 0xc3414182, 0xb0999929, 0x772d2d5a, 0x110f0f1e, 0xcbb0b07b, 0xfc5454a8, 0xd6bbbb6d, 0x3a16162c];
final _T1 = [0x6363c6a5, 0x7c7cf884, 0x7777ee99, 0x7b7bf68d, 0xf2f2ff0d, 0x6b6bd6bd, 0x6f6fdeb1, 0xc5c59154, 0x30306050, 0x01010203, 0x6767cea9, 0x2b2b567d, 0xfefee719, 0xd7d7b562, 0xabab4de6, 0x7676ec9a, 0xcaca8f45, 0x82821f9d, 0xc9c98940, 0x7d7dfa87, 0xfafaef15, 0x5959b2eb, 0x47478ec9, 0xf0f0fb0b, 0xadad41ec, 0xd4d4b367, 0xa2a25ffd, 0xafaf45ea, 0x9c9c23bf, 0xa4a453f7, 0x7272e496, 0xc0c09b5b, 0xb7b775c2, 0xfdfde11c, 0x93933dae, 0x26264c6a, 0x36366c5a, 0x3f3f7e41, 0xf7f7f502, 0xcccc834f, 0x3434685c, 0xa5a551f4, 0xe5e5d134, 0xf1f1f908, 0x7171e293, 0xd8d8ab73, 0x31316253, 0x15152a3f, 0x0404080c, 0xc7c79552, 0x23234665, 0xc3c39d5e, 0x18183028, 0x969637a1, 0x05050a0f, 0x9a9a2fb5, 0x07070e09, 0x12122436, 0x80801b9b, 0xe2e2df3d, 0xebebcd26, 0x27274e69, 0xb2b27fcd, 0x7575ea9f, 0x0909121b, 0x83831d9e, 0x2c2c5874, 0x1a1a342e, 0x1b1b362d, 0x6e6edcb2, 0x5a5ab4ee, 0xa0a05bfb, 0x5252a4f6, 0x3b3b764d, 0xd6d6b761, 0xb3b37dce, 0x2929527b, 0xe3e3dd3e, 0x2f2f5e71, 0x84841397, 0x5353a6f5, 0xd1d1b968, 0x00000000, 0xededc12c, 0x20204060, 0xfcfce31f, 0xb1b179c8, 0x5b5bb6ed, 0x6a6ad4be, 0xcbcb8d46, 0xbebe67d9, 0x3939724b, 0x4a4a94de, 0x4c4c98d4, 0x5858b0e8, 0xcfcf854a, 0xd0d0bb6b, 0xefefc52a, 0xaaaa4fe5, 0xfbfbed16, 0x434386c5, 0x4d4d9ad7, 0x33336655, 0x85851194, 0x45458acf, 0xf9f9e910, 0x02020406, 0x7f7ffe81, 0x5050a0f0, 0x3c3c7844, 0x9f9f25ba, 0xa8a84be3, 0x5151a2f3, 0xa3a35dfe, 0x404080c0, 0x8f8f058a, 0x92923fad, 0x9d9d21bc, 0x38387048, 0xf5f5f104, 0xbcbc63df, 0xb6b677c1, 0xdadaaf75, 0x21214263, 0x10102030, 0xffffe51a, 0xf3f3fd0e, 0xd2d2bf6d, 0xcdcd814c, 0x0c0c1814, 0x13132635, 0xececc32f, 0x5f5fbee1, 0x979735a2, 0x444488cc, 0x17172e39, 0xc4c49357, 0xa7a755f2, 0x7e7efc82, 0x3d3d7a47, 0x6464c8ac, 0x5d5dbae7, 0x1919322b, 0x7373e695, 0x6060c0a0, 0x81811998, 0x4f4f9ed1, 0xdcdca37f, 0x22224466, 0x2a2a547e, 0x90903bab, 0x88880b83, 0x46468cca, 0xeeeec729, 0xb8b86bd3, 0x1414283c, 0xdedea779, 0x5e5ebce2, 0x0b0b161d, 0xdbdbad76, 0xe0e0db3b, 0x32326456, 0x3a3a744e, 0x0a0a141e, 0x494992db, 0x06060c0a, 0x2424486c, 0x5c5cb8e4, 0xc2c29f5d, 0xd3d3bd6e, 0xacac43ef, 0x6262c4a6, 0x919139a8, 0x959531a4, 0xe4e4d337, 0x7979f28b, 0xe7e7d532, 0xc8c88b43, 0x37376e59, 0x6d6ddab7, 0x8d8d018c, 0xd5d5b164, 0x4e4e9cd2, 0xa9a949e0, 0x6c6cd8b4, 0x5656acfa, 0xf4f4f307, 0xeaeacf25, 0x6565caaf, 0x7a7af48e, 0xaeae47e9, 0x08081018, 0xbaba6fd5, 0x7878f088, 0x25254a6f, 0x2e2e5c72, 0x1c1c3824, 0xa6a657f1, 0xb4b473c7, 0xc6c69751, 0xe8e8cb23, 0xdddda17c, 0x7474e89c, 0x1f1f3e21, 0x4b4b96dd, 0xbdbd61dc, 0x8b8b0d86, 0x8a8a0f85, 0x7070e090, 0x3e3e7c42, 0xb5b571c4, 0x6666ccaa, 0x484890d8, 0x03030605, 0xf6f6f701, 0x0e0e1c12, 0x6161c2a3, 0x35356a5f, 0x5757aef9, 0xb9b969d0, 0x86861791, 0xc1c19958, 0x1d1d3a27, 0x9e9e27b9, 0xe1e1d938, 0xf8f8eb13, 0x98982bb3, 0x11112233, 0x6969d2bb, 0xd9d9a970, 0x8e8e0789, 0x949433a7, 0x9b9b2db6, 0x1e1e3c22, 0x87871592, 0xe9e9c920, 0xcece8749, 0x5555aaff, 0x28285078, 0xdfdfa57a, 0x8c8c038f, 0xa1a159f8, 0x89890980, 0x0d0d1a17, 0xbfbf65da, 0xe6e6d731, 0x424284c6, 0x6868d0b8, 0x414182c3, 0x999929b0, 0x2d2d5a77, 0x0f0f1e11, 0xb0b07bcb, 0x5454a8fc, 0xbbbb6dd6, 0x16162c3a];
final _T2 = [0x63c6a563, 0x7cf8847c, 0x77ee9977, 0x7bf68d7b, 0xf2ff0df2, 0x6bd6bd6b, 0x6fdeb16f, 0xc59154c5, 0x30605030, 0x01020301, 0x67cea967, 0x2b567d2b, 0xfee719fe, 0xd7b562d7, 0xab4de6ab, 0x76ec9a76, 0xca8f45ca, 0x821f9d82, 0xc98940c9, 0x7dfa877d, 0xfaef15fa, 0x59b2eb59, 0x478ec947, 0xf0fb0bf0, 0xad41ecad, 0xd4b367d4, 0xa25ffda2, 0xaf45eaaf, 0x9c23bf9c, 0xa453f7a4, 0x72e49672, 0xc09b5bc0, 0xb775c2b7, 0xfde11cfd, 0x933dae93, 0x264c6a26, 0x366c5a36, 0x3f7e413f, 0xf7f502f7, 0xcc834fcc, 0x34685c34, 0xa551f4a5, 0xe5d134e5, 0xf1f908f1, 0x71e29371, 0xd8ab73d8, 0x31625331, 0x152a3f15, 0x04080c04, 0xc79552c7, 0x23466523, 0xc39d5ec3, 0x18302818, 0x9637a196, 0x050a0f05, 0x9a2fb59a, 0x070e0907, 0x12243612, 0x801b9b80, 0xe2df3de2, 0xebcd26eb, 0x274e6927, 0xb27fcdb2, 0x75ea9f75, 0x09121b09, 0x831d9e83, 0x2c58742c, 0x1a342e1a, 0x1b362d1b, 0x6edcb26e, 0x5ab4ee5a, 0xa05bfba0, 0x52a4f652, 0x3b764d3b, 0xd6b761d6, 0xb37dceb3, 0x29527b29, 0xe3dd3ee3, 0x2f5e712f, 0x84139784, 0x53a6f553, 0xd1b968d1, 0x00000000, 0xedc12ced, 0x20406020, 0xfce31ffc, 0xb179c8b1, 0x5bb6ed5b, 0x6ad4be6a, 0xcb8d46cb, 0xbe67d9be, 0x39724b39, 0x4a94de4a, 0x4c98d44c, 0x58b0e858, 0xcf854acf, 0xd0bb6bd0, 0xefc52aef, 0xaa4fe5aa, 0xfbed16fb, 0x4386c543, 0x4d9ad74d, 0x33665533, 0x85119485, 0x458acf45, 0xf9e910f9, 0x02040602, 0x7ffe817f, 0x50a0f050, 0x3c78443c, 0x9f25ba9f, 0xa84be3a8, 0x51a2f351, 0xa35dfea3, 0x4080c040, 0x8f058a8f, 0x923fad92, 0x9d21bc9d, 0x38704838, 0xf5f104f5, 0xbc63dfbc, 0xb677c1b6, 0xdaaf75da, 0x21426321, 0x10203010, 0xffe51aff, 0xf3fd0ef3, 0xd2bf6dd2, 0xcd814ccd, 0x0c18140c, 0x13263513, 0xecc32fec, 0x5fbee15f, 0x9735a297, 0x4488cc44, 0x172e3917, 0xc49357c4, 0xa755f2a7, 0x7efc827e, 0x3d7a473d, 0x64c8ac64, 0x5dbae75d, 0x19322b19, 0x73e69573, 0x60c0a060, 0x81199881, 0x4f9ed14f, 0xdca37fdc, 0x22446622, 0x2a547e2a, 0x903bab90, 0x880b8388, 0x468cca46, 0xeec729ee, 0xb86bd3b8, 0x14283c14, 0xdea779de, 0x5ebce25e, 0x0b161d0b, 0xdbad76db, 0xe0db3be0, 0x32645632, 0x3a744e3a, 0x0a141e0a, 0x4992db49, 0x060c0a06, 0x24486c24, 0x5cb8e45c, 0xc29f5dc2, 0xd3bd6ed3, 0xac43efac, 0x62c4a662, 0x9139a891, 0x9531a495, 0xe4d337e4, 0x79f28b79, 0xe7d532e7, 0xc88b43c8, 0x376e5937, 0x6ddab76d, 0x8d018c8d, 0xd5b164d5, 0x4e9cd24e, 0xa949e0a9, 0x6cd8b46c, 0x56acfa56, 0xf4f307f4, 0xeacf25ea, 0x65caaf65, 0x7af48e7a, 0xae47e9ae, 0x08101808, 0xba6fd5ba, 0x78f08878, 0x254a6f25, 0x2e5c722e, 0x1c38241c, 0xa657f1a6, 0xb473c7b4, 0xc69751c6, 0xe8cb23e8, 0xdda17cdd, 0x74e89c74, 0x1f3e211f, 0x4b96dd4b, 0xbd61dcbd, 0x8b0d868b, 0x8a0f858a, 0x70e09070, 0x3e7c423e, 0xb571c4b5, 0x66ccaa66, 0x4890d848, 0x03060503, 0xf6f701f6, 0x0e1c120e, 0x61c2a361, 0x356a5f35, 0x57aef957, 0xb969d0b9, 0x86179186, 0xc19958c1, 0x1d3a271d, 0x9e27b99e, 0xe1d938e1, 0xf8eb13f8, 0x982bb398, 0x11223311, 0x69d2bb69, 0xd9a970d9, 0x8e07898e, 0x9433a794, 0x9b2db69b, 0x1e3c221e, 0x87159287, 0xe9c920e9, 0xce8749ce, 0x55aaff55, 0x28507828, 0xdfa57adf, 0x8c038f8c, 0xa159f8a1, 0x89098089, 0x0d1a170d, 0xbf65dabf, 0xe6d731e6, 0x4284c642, 0x68d0b868, 0x4182c341, 0x9929b099, 0x2d5a772d, 0x0f1e110f, 0xb07bcbb0, 0x54a8fc54, 0xbb6dd6bb, 0x162c3a16];
final _T3 = [0xc6a56363, 0xf8847c7c, 0xee997777, 0xf68d7b7b, 0xff0df2f2, 0xd6bd6b6b, 0xdeb16f6f, 0x9154c5c5, 0x60503030, 0x02030101, 0xcea96767, 0x567d2b2b, 0xe719fefe, 0xb562d7d7, 0x4de6abab, 0xec9a7676, 0x8f45caca, 0x1f9d8282, 0x8940c9c9, 0xfa877d7d, 0xef15fafa, 0xb2eb5959, 0x8ec94747, 0xfb0bf0f0, 0x41ecadad, 0xb367d4d4, 0x5ffda2a2, 0x45eaafaf, 0x23bf9c9c, 0x53f7a4a4, 0xe4967272, 0x9b5bc0c0, 0x75c2b7b7, 0xe11cfdfd, 0x3dae9393, 0x4c6a2626, 0x6c5a3636, 0x7e413f3f, 0xf502f7f7, 0x834fcccc, 0x685c3434, 0x51f4a5a5, 0xd134e5e5, 0xf908f1f1, 0xe2937171, 0xab73d8d8, 0x62533131, 0x2a3f1515, 0x080c0404, 0x9552c7c7, 0x46652323, 0x9d5ec3c3, 0x30281818, 0x37a19696, 0x0a0f0505, 0x2fb59a9a, 0x0e090707, 0x24361212, 0x1b9b8080, 0xdf3de2e2, 0xcd26ebeb, 0x4e692727, 0x7fcdb2b2, 0xea9f7575, 0x121b0909, 0x1d9e8383, 0x58742c2c, 0x342e1a1a, 0x362d1b1b, 0xdcb26e6e, 0xb4ee5a5a, 0x5bfba0a0, 0xa4f65252, 0x764d3b3b, 0xb761d6d6, 0x7dceb3b3, 0x527b2929, 0xdd3ee3e3, 0x5e712f2f, 0x13978484, 0xa6f55353, 0xb968d1d1, 0x00000000, 0xc12ceded, 0x40602020, 0xe31ffcfc, 0x79c8b1b1, 0xb6ed5b5b, 0xd4be6a6a, 0x8d46cbcb, 0x67d9bebe, 0x724b3939, 0x94de4a4a, 0x98d44c4c, 0xb0e85858, 0x854acfcf, 0xbb6bd0d0, 0xc52aefef, 0x4fe5aaaa, 0xed16fbfb, 0x86c54343, 0x9ad74d4d, 0x66553333, 0x11948585, 0x8acf4545, 0xe910f9f9, 0x04060202, 0xfe817f7f, 0xa0f05050, 0x78443c3c, 0x25ba9f9f, 0x4be3a8a8, 0xa2f35151, 0x5dfea3a3, 0x80c04040, 0x058a8f8f, 0x3fad9292, 0x21bc9d9d, 0x70483838, 0xf104f5f5, 0x63dfbcbc, 0x77c1b6b6, 0xaf75dada, 0x42632121, 0x20301010, 0xe51affff, 0xfd0ef3f3, 0xbf6dd2d2, 0x814ccdcd, 0x18140c0c, 0x26351313, 0xc32fecec, 0xbee15f5f, 0x35a29797, 0x88cc4444, 0x2e391717, 0x9357c4c4, 0x55f2a7a7, 0xfc827e7e, 0x7a473d3d, 0xc8ac6464, 0xbae75d5d, 0x322b1919, 0xe6957373, 0xc0a06060, 0x19988181, 0x9ed14f4f, 0xa37fdcdc, 0x44662222, 0x547e2a2a, 0x3bab9090, 0x0b838888, 0x8cca4646, 0xc729eeee, 0x6bd3b8b8, 0x283c1414, 0xa779dede, 0xbce25e5e, 0x161d0b0b, 0xad76dbdb, 0xdb3be0e0, 0x64563232, 0x744e3a3a, 0x141e0a0a, 0x92db4949, 0x0c0a0606, 0x486c2424, 0xb8e45c5c, 0x9f5dc2c2, 0xbd6ed3d3, 0x43efacac, 0xc4a66262, 0x39a89191, 0x31a49595, 0xd337e4e4, 0xf28b7979, 0xd532e7e7, 0x8b43c8c8, 0x6e593737, 0xdab76d6d, 0x018c8d8d, 0xb164d5d5, 0x9cd24e4e, 0x49e0a9a9, 0xd8b46c6c, 0xacfa5656, 0xf307f4f4, 0xcf25eaea, 0xcaaf6565, 0xf48e7a7a, 0x47e9aeae, 0x10180808, 0x6fd5baba, 0xf0887878, 0x4a6f2525, 0x5c722e2e, 0x38241c1c, 0x57f1a6a6, 0x73c7b4b4, 0x9751c6c6, 0xcb23e8e8, 0xa17cdddd, 0xe89c7474, 0x3e211f1f, 0x96dd4b4b, 0x61dcbdbd, 0x0d868b8b, 0x0f858a8a, 0xe0907070, 0x7c423e3e, 0x71c4b5b5, 0xccaa6666, 0x90d84848, 0x06050303, 0xf701f6f6, 0x1c120e0e, 0xc2a36161, 0x6a5f3535, 0xaef95757, 0x69d0b9b9, 0x17918686, 0x9958c1c1, 0x3a271d1d, 0x27b99e9e, 0xd938e1e1, 0xeb13f8f8, 0x2bb39898, 0x22331111, 0xd2bb6969, 0xa970d9d9, 0x07898e8e, 0x33a79494, 0x2db69b9b, 0x3c221e1e, 0x15928787, 0xc920e9e9, 0x8749cece, 0xaaff5555, 0x50782828, 0xa57adfdf, 0x038f8c8c, 0x59f8a1a1, 0x09808989, 0x1a170d0d, 0x65dabfbf, 0xd731e6e6, 0x84c64242, 0xd0b86868, 0x82c34141, 0x29b09999, 0x5a772d2d, 0x1e110f0f, 0x7bcbb0b0, 0xa8fc5454, 0x6dd6bbbb, 0x2c3a1616];
final _Tinv0 = [0x50a7f451, 0x5365417e, 0xc3a4171a, 0x965e273a, 0xcb6bab3b, 0xf1459d1f, 0xab58faac, 0x9303e34b, 0x55fa3020, 0xf66d76ad, 0x9176cc88, 0x254c02f5, 0xfcd7e54f, 0xd7cb2ac5, 0x80443526, 0x8fa362b5, 0x495ab1de, 0x671bba25, 0x980eea45, 0xe1c0fe5d, 0x02752fc3, 0x12f04c81, 0xa397468d, 0xc6f9d36b, 0xe75f8f03, 0x959c9215, 0xeb7a6dbf, 0xda595295, 0x2d83bed4, 0xd3217458, 0x2969e049, 0x44c8c98e, 0x6a89c275, 0x78798ef4, 0x6b3e5899, 0xdd71b927, 0xb64fe1be, 0x17ad88f0, 0x66ac20c9, 0xb43ace7d, 0x184adf63, 0x82311ae5, 0x60335197, 0x457f5362, 0xe07764b1, 0x84ae6bbb, 0x1ca081fe, 0x942b08f9, 0x58684870, 0x19fd458f, 0x876cde94, 0xb7f87b52, 0x23d373ab, 0xe2024b72, 0x578f1fe3, 0x2aab5566, 0x0728ebb2, 0x03c2b52f, 0x9a7bc586, 0xa50837d3, 0xf2872830, 0xb2a5bf23, 0xba6a0302, 0x5c8216ed, 0x2b1ccf8a, 0x92b479a7, 0xf0f207f3, 0xa1e2694e, 0xcdf4da65, 0xd5be0506, 0x1f6234d1, 0x8afea6c4, 0x9d532e34, 0xa055f3a2, 0x32e18a05, 0x75ebf6a4, 0x39ec830b, 0xaaef6040, 0x069f715e, 0x51106ebd, 0xf98a213e, 0x3d06dd96, 0xae053edd, 0x46bde64d, 0xb58d5491, 0x055dc471, 0x6fd40604, 0xff155060, 0x24fb9819, 0x97e9bdd6, 0xcc434089, 0x779ed967, 0xbd42e8b0, 0x888b8907, 0x385b19e7, 0xdbeec879, 0x470a7ca1, 0xe90f427c, 0xc91e84f8, 0x00000000, 0x83868009, 0x48ed2b32, 0xac70111e, 0x4e725a6c, 0xfbff0efd, 0x5638850f, 0x1ed5ae3d, 0x27392d36, 0x64d90f0a, 0x21a65c68, 0xd1545b9b, 0x3a2e3624, 0xb1670a0c, 0x0fe75793, 0xd296eeb4, 0x9e919b1b, 0x4fc5c080, 0xa220dc61, 0x694b775a, 0x161a121c, 0x0aba93e2, 0xe52aa0c0, 0x43e0223c, 0x1d171b12, 0x0b0d090e, 0xadc78bf2, 0xb9a8b62d, 0xc8a91e14, 0x8519f157, 0x4c0775af, 0xbbdd99ee, 0xfd607fa3, 0x9f2601f7, 0xbcf5725c, 0xc53b6644, 0x347efb5b, 0x7629438b, 0xdcc623cb, 0x68fcedb6, 0x63f1e4b8, 0xcadc31d7, 0x10856342, 0x40229713, 0x2011c684, 0x7d244a85, 0xf83dbbd2, 0x1132f9ae, 0x6da129c7, 0x4b2f9e1d, 0xf330b2dc, 0xec52860d, 0xd0e3c177, 0x6c16b32b, 0x99b970a9, 0xfa489411, 0x2264e947, 0xc48cfca8, 0x1a3ff0a0, 0xd82c7d56, 0xef903322, 0xc74e4987, 0xc1d138d9, 0xfea2ca8c, 0x360bd498, 0xcf81f5a6, 0x28de7aa5, 0x268eb7da, 0xa4bfad3f, 0xe49d3a2c, 0x0d927850, 0x9bcc5f6a, 0x62467e54, 0xc2138df6, 0xe8b8d890, 0x5ef7392e, 0xf5afc382, 0xbe805d9f, 0x7c93d069, 0xa92dd56f, 0xb31225cf, 0x3b99acc8, 0xa77d1810, 0x6e639ce8, 0x7bbb3bdb, 0x097826cd, 0xf418596e, 0x01b79aec, 0xa89a4f83, 0x656e95e6, 0x7ee6ffaa, 0x08cfbc21, 0xe6e815ef, 0xd99be7ba, 0xce366f4a, 0xd4099fea, 0xd67cb029, 0xafb2a431, 0x31233f2a, 0x3094a5c6, 0xc066a235, 0x37bc4e74, 0xa6ca82fc, 0xb0d090e0, 0x15d8a733, 0x4a9804f1, 0xf7daec41, 0x0e50cd7f, 0x2ff69117, 0x8dd64d76, 0x4db0ef43, 0x544daacc, 0xdf0496e4, 0xe3b5d19e, 0x1b886a4c, 0xb81f2cc1, 0x7f516546, 0x04ea5e9d, 0x5d358c01, 0x737487fa, 0x2e410bfb, 0x5a1d67b3, 0x52d2db92, 0x335610e9, 0x1347d66d, 0x8c61d79a, 0x7a0ca137, 0x8e14f859, 0x893c13eb, 0xee27a9ce, 0x35c961b7, 0xede51ce1, 0x3cb1477a, 0x59dfd29c, 0x3f73f255, 0x79ce1418, 0xbf37c773, 0xeacdf753, 0x5baafd5f, 0x146f3ddf, 0x86db4478, 0x81f3afca, 0x3ec468b9, 0x2c342438, 0x5f40a3c2, 0x72c31d16, 0x0c25e2bc, 0x8b493c28, 0x41950dff, 0x7101a839, 0xdeb30c08, 0x9ce4b4d8, 0x90c15664, 0x6184cb7b, 0x70b632d5, 0x745c6c48, 0x4257b8d0];
final _Tinv1 = [0xa7f45150, 0x65417e53, 0xa4171ac3, 0x5e273a96, 0x6bab3bcb, 0x459d1ff1, 0x58faacab, 0x03e34b93, 0xfa302055, 0x6d76adf6, 0x76cc8891, 0x4c02f525, 0xd7e54ffc, 0xcb2ac5d7, 0x44352680, 0xa362b58f, 0x5ab1de49, 0x1bba2567, 0x0eea4598, 0xc0fe5de1, 0x752fc302, 0xf04c8112, 0x97468da3, 0xf9d36bc6, 0x5f8f03e7, 0x9c921595, 0x7a6dbfeb, 0x595295da, 0x83bed42d, 0x217458d3, 0x69e04929, 0xc8c98e44, 0x89c2756a, 0x798ef478, 0x3e58996b, 0x71b927dd, 0x4fe1beb6, 0xad88f017, 0xac20c966, 0x3ace7db4, 0x4adf6318, 0x311ae582, 0x33519760, 0x7f536245, 0x7764b1e0, 0xae6bbb84, 0xa081fe1c, 0x2b08f994, 0x68487058, 0xfd458f19, 0x6cde9487, 0xf87b52b7, 0xd373ab23, 0x024b72e2, 0x8f1fe357, 0xab55662a, 0x28ebb207, 0xc2b52f03, 0x7bc5869a, 0x0837d3a5, 0x872830f2, 0xa5bf23b2, 0x6a0302ba, 0x8216ed5c, 0x1ccf8a2b, 0xb479a792, 0xf207f3f0, 0xe2694ea1, 0xf4da65cd, 0xbe0506d5, 0x6234d11f, 0xfea6c48a, 0x532e349d, 0x55f3a2a0, 0xe18a0532, 0xebf6a475, 0xec830b39, 0xef6040aa, 0x9f715e06, 0x106ebd51, 0x8a213ef9, 0x06dd963d, 0x053eddae, 0xbde64d46, 0x8d5491b5, 0x5dc47105, 0xd406046f, 0x155060ff, 0xfb981924, 0xe9bdd697, 0x434089cc, 0x9ed96777, 0x42e8b0bd, 0x8b890788, 0x5b19e738, 0xeec879db, 0x0a7ca147, 0x0f427ce9, 0x1e84f8c9, 0x00000000, 0x86800983, 0xed2b3248, 0x70111eac, 0x725a6c4e, 0xff0efdfb, 0x38850f56, 0xd5ae3d1e, 0x392d3627, 0xd90f0a64, 0xa65c6821, 0x545b9bd1, 0x2e36243a, 0x670a0cb1, 0xe757930f, 0x96eeb4d2, 0x919b1b9e, 0xc5c0804f, 0x20dc61a2, 0x4b775a69, 0x1a121c16, 0xba93e20a, 0x2aa0c0e5, 0xe0223c43, 0x171b121d, 0x0d090e0b, 0xc78bf2ad, 0xa8b62db9, 0xa91e14c8, 0x19f15785, 0x0775af4c, 0xdd99eebb, 0x607fa3fd, 0x2601f79f, 0xf5725cbc, 0x3b6644c5, 0x7efb5b34, 0x29438b76, 0xc623cbdc, 0xfcedb668, 0xf1e4b863, 0xdc31d7ca, 0x85634210, 0x22971340, 0x11c68420, 0x244a857d, 0x3dbbd2f8, 0x32f9ae11, 0xa129c76d, 0x2f9e1d4b, 0x30b2dcf3, 0x52860dec, 0xe3c177d0, 0x16b32b6c, 0xb970a999, 0x489411fa, 0x64e94722, 0x8cfca8c4, 0x3ff0a01a, 0x2c7d56d8, 0x903322ef, 0x4e4987c7, 0xd138d9c1, 0xa2ca8cfe, 0x0bd49836, 0x81f5a6cf, 0xde7aa528, 0x8eb7da26, 0xbfad3fa4, 0x9d3a2ce4, 0x9278500d, 0xcc5f6a9b, 0x467e5462, 0x138df6c2, 0xb8d890e8, 0xf7392e5e, 0xafc382f5, 0x805d9fbe, 0x93d0697c, 0x2dd56fa9, 0x1225cfb3, 0x99acc83b, 0x7d1810a7, 0x639ce86e, 0xbb3bdb7b, 0x7826cd09, 0x18596ef4, 0xb79aec01, 0x9a4f83a8, 0x6e95e665, 0xe6ffaa7e, 0xcfbc2108, 0xe815efe6, 0x9be7bad9, 0x366f4ace, 0x099fead4, 0x7cb029d6, 0xb2a431af, 0x233f2a31, 0x94a5c630, 0x66a235c0, 0xbc4e7437, 0xca82fca6, 0xd090e0b0, 0xd8a73315, 0x9804f14a, 0xdaec41f7, 0x50cd7f0e, 0xf691172f, 0xd64d768d, 0xb0ef434d, 0x4daacc54, 0x0496e4df, 0xb5d19ee3, 0x886a4c1b, 0x1f2cc1b8, 0x5165467f, 0xea5e9d04, 0x358c015d, 0x7487fa73, 0x410bfb2e, 0x1d67b35a, 0xd2db9252, 0x5610e933, 0x47d66d13, 0x61d79a8c, 0x0ca1377a, 0x14f8598e, 0x3c13eb89, 0x27a9ceee, 0xc961b735, 0xe51ce1ed, 0xb1477a3c, 0xdfd29c59, 0x73f2553f, 0xce141879, 0x37c773bf, 0xcdf753ea, 0xaafd5f5b, 0x6f3ddf14, 0xdb447886, 0xf3afca81, 0xc468b93e, 0x3424382c, 0x40a3c25f, 0xc31d1672, 0x25e2bc0c, 0x493c288b, 0x950dff41, 0x01a83971, 0xb30c08de, 0xe4b4d89c, 0xc1566490, 0x84cb7b61, 0xb632d570, 0x5c6c4874, 0x57b8d042];
final _Tinv2 = [0xf45150a7, 0x417e5365, 0x171ac3a4, 0x273a965e, 0xab3bcb6b, 0x9d1ff145, 0xfaacab58, 0xe34b9303, 0x302055fa, 0x76adf66d, 0xcc889176, 0x02f5254c, 0xe54ffcd7, 0x2ac5d7cb, 0x35268044, 0x62b58fa3, 0xb1de495a, 0xba25671b, 0xea45980e, 0xfe5de1c0, 0x2fc30275, 0x4c8112f0, 0x468da397, 0xd36bc6f9, 0x8f03e75f, 0x9215959c, 0x6dbfeb7a, 0x5295da59, 0xbed42d83, 0x7458d321, 0xe0492969, 0xc98e44c8, 0xc2756a89, 0x8ef47879, 0x58996b3e, 0xb927dd71, 0xe1beb64f, 0x88f017ad, 0x20c966ac, 0xce7db43a, 0xdf63184a, 0x1ae58231, 0x51976033, 0x5362457f, 0x64b1e077, 0x6bbb84ae, 0x81fe1ca0, 0x08f9942b, 0x48705868, 0x458f19fd, 0xde94876c, 0x7b52b7f8, 0x73ab23d3, 0x4b72e202, 0x1fe3578f, 0x55662aab, 0xebb20728, 0xb52f03c2, 0xc5869a7b, 0x37d3a508, 0x2830f287, 0xbf23b2a5, 0x0302ba6a, 0x16ed5c82, 0xcf8a2b1c, 0x79a792b4, 0x07f3f0f2, 0x694ea1e2, 0xda65cdf4, 0x0506d5be, 0x34d11f62, 0xa6c48afe, 0x2e349d53, 0xf3a2a055, 0x8a0532e1, 0xf6a475eb, 0x830b39ec, 0x6040aaef, 0x715e069f, 0x6ebd5110, 0x213ef98a, 0xdd963d06, 0x3eddae05, 0xe64d46bd, 0x5491b58d, 0xc471055d, 0x06046fd4, 0x5060ff15, 0x981924fb, 0xbdd697e9, 0x4089cc43, 0xd967779e, 0xe8b0bd42, 0x8907888b, 0x19e7385b, 0xc879dbee, 0x7ca1470a, 0x427ce90f, 0x84f8c91e, 0x00000000, 0x80098386, 0x2b3248ed, 0x111eac70, 0x5a6c4e72, 0x0efdfbff, 0x850f5638, 0xae3d1ed5, 0x2d362739, 0x0f0a64d9, 0x5c6821a6, 0x5b9bd154, 0x36243a2e, 0x0a0cb167, 0x57930fe7, 0xeeb4d296, 0x9b1b9e91, 0xc0804fc5, 0xdc61a220, 0x775a694b, 0x121c161a, 0x93e20aba, 0xa0c0e52a, 0x223c43e0, 0x1b121d17, 0x090e0b0d, 0x8bf2adc7, 0xb62db9a8, 0x1e14c8a9, 0xf1578519, 0x75af4c07, 0x99eebbdd, 0x7fa3fd60, 0x01f79f26, 0x725cbcf5, 0x6644c53b, 0xfb5b347e, 0x438b7629, 0x23cbdcc6, 0xedb668fc, 0xe4b863f1, 0x31d7cadc, 0x63421085, 0x97134022, 0xc6842011, 0x4a857d24, 0xbbd2f83d, 0xf9ae1132, 0x29c76da1, 0x9e1d4b2f, 0xb2dcf330, 0x860dec52, 0xc177d0e3, 0xb32b6c16, 0x70a999b9, 0x9411fa48, 0xe9472264, 0xfca8c48c, 0xf0a01a3f, 0x7d56d82c, 0x3322ef90, 0x4987c74e, 0x38d9c1d1, 0xca8cfea2, 0xd498360b, 0xf5a6cf81, 0x7aa528de, 0xb7da268e, 0xad3fa4bf, 0x3a2ce49d, 0x78500d92, 0x5f6a9bcc, 0x7e546246, 0x8df6c213, 0xd890e8b8, 0x392e5ef7, 0xc382f5af, 0x5d9fbe80, 0xd0697c93, 0xd56fa92d, 0x25cfb312, 0xacc83b99, 0x1810a77d, 0x9ce86e63, 0x3bdb7bbb, 0x26cd0978, 0x596ef418, 0x9aec01b7, 0x4f83a89a, 0x95e6656e, 0xffaa7ee6, 0xbc2108cf, 0x15efe6e8, 0xe7bad99b, 0x6f4ace36, 0x9fead409, 0xb029d67c, 0xa431afb2, 0x3f2a3123, 0xa5c63094, 0xa235c066, 0x4e7437bc, 0x82fca6ca, 0x90e0b0d0, 0xa73315d8, 0x04f14a98, 0xec41f7da, 0xcd7f0e50, 0x91172ff6, 0x4d768dd6, 0xef434db0, 0xaacc544d, 0x96e4df04, 0xd19ee3b5, 0x6a4c1b88, 0x2cc1b81f, 0x65467f51, 0x5e9d04ea, 0x8c015d35, 0x87fa7374, 0x0bfb2e41, 0x67b35a1d, 0xdb9252d2, 0x10e93356, 0xd66d1347, 0xd79a8c61, 0xa1377a0c, 0xf8598e14, 0x13eb893c, 0xa9ceee27, 0x61b735c9, 0x1ce1ede5, 0x477a3cb1, 0xd29c59df, 0xf2553f73, 0x141879ce, 0xc773bf37, 0xf753eacd, 0xfd5f5baa, 0x3ddf146f, 0x447886db, 0xafca81f3, 0x68b93ec4, 0x24382c34, 0xa3c25f40, 0x1d1672c3, 0xe2bc0c25, 0x3c288b49, 0x0dff4195, 0xa8397101, 0x0c08deb3, 0xb4d89ce4, 0x566490c1, 0xcb7b6184, 0x32d570b6, 0x6c48745c, 0xb8d04257];
final _Tinv3 = [0x5150a7f4, 0x7e536541, 0x1ac3a417, 0x3a965e27, 0x3bcb6bab, 0x1ff1459d, 0xacab58fa, 0x4b9303e3, 0x2055fa30, 0xadf66d76, 0x889176cc, 0xf5254c02, 0x4ffcd7e5, 0xc5d7cb2a, 0x26804435, 0xb58fa362, 0xde495ab1, 0x25671bba, 0x45980eea, 0x5de1c0fe, 0xc302752f, 0x8112f04c, 0x8da39746, 0x6bc6f9d3, 0x03e75f8f, 0x15959c92, 0xbfeb7a6d, 0x95da5952, 0xd42d83be, 0x58d32174, 0x492969e0, 0x8e44c8c9, 0x756a89c2, 0xf478798e, 0x996b3e58, 0x27dd71b9, 0xbeb64fe1, 0xf017ad88, 0xc966ac20, 0x7db43ace, 0x63184adf, 0xe582311a, 0x97603351, 0x62457f53, 0xb1e07764, 0xbb84ae6b, 0xfe1ca081, 0xf9942b08, 0x70586848, 0x8f19fd45, 0x94876cde, 0x52b7f87b, 0xab23d373, 0x72e2024b, 0xe3578f1f, 0x662aab55, 0xb20728eb, 0x2f03c2b5, 0x869a7bc5, 0xd3a50837, 0x30f28728, 0x23b2a5bf, 0x02ba6a03, 0xed5c8216, 0x8a2b1ccf, 0xa792b479, 0xf3f0f207, 0x4ea1e269, 0x65cdf4da, 0x06d5be05, 0xd11f6234, 0xc48afea6, 0x349d532e, 0xa2a055f3, 0x0532e18a, 0xa475ebf6, 0x0b39ec83, 0x40aaef60, 0x5e069f71, 0xbd51106e, 0x3ef98a21, 0x963d06dd, 0xddae053e, 0x4d46bde6, 0x91b58d54, 0x71055dc4, 0x046fd406, 0x60ff1550, 0x1924fb98, 0xd697e9bd, 0x89cc4340, 0x67779ed9, 0xb0bd42e8, 0x07888b89, 0xe7385b19, 0x79dbeec8, 0xa1470a7c, 0x7ce90f42, 0xf8c91e84, 0x00000000, 0x09838680, 0x3248ed2b, 0x1eac7011, 0x6c4e725a, 0xfdfbff0e, 0x0f563885, 0x3d1ed5ae, 0x3627392d, 0x0a64d90f, 0x6821a65c, 0x9bd1545b, 0x243a2e36, 0x0cb1670a, 0x930fe757, 0xb4d296ee, 0x1b9e919b, 0x804fc5c0, 0x61a220dc, 0x5a694b77, 0x1c161a12, 0xe20aba93, 0xc0e52aa0, 0x3c43e022, 0x121d171b, 0x0e0b0d09, 0xf2adc78b, 0x2db9a8b6, 0x14c8a91e, 0x578519f1, 0xaf4c0775, 0xeebbdd99, 0xa3fd607f, 0xf79f2601, 0x5cbcf572, 0x44c53b66, 0x5b347efb, 0x8b762943, 0xcbdcc623, 0xb668fced, 0xb863f1e4, 0xd7cadc31, 0x42108563, 0x13402297, 0x842011c6, 0x857d244a, 0xd2f83dbb, 0xae1132f9, 0xc76da129, 0x1d4b2f9e, 0xdcf330b2, 0x0dec5286, 0x77d0e3c1, 0x2b6c16b3, 0xa999b970, 0x11fa4894, 0x472264e9, 0xa8c48cfc, 0xa01a3ff0, 0x56d82c7d, 0x22ef9033, 0x87c74e49, 0xd9c1d138, 0x8cfea2ca, 0x98360bd4, 0xa6cf81f5, 0xa528de7a, 0xda268eb7, 0x3fa4bfad, 0x2ce49d3a, 0x500d9278, 0x6a9bcc5f, 0x5462467e, 0xf6c2138d, 0x90e8b8d8, 0x2e5ef739, 0x82f5afc3, 0x9fbe805d, 0x697c93d0, 0x6fa92dd5, 0xcfb31225, 0xc83b99ac, 0x10a77d18, 0xe86e639c, 0xdb7bbb3b, 0xcd097826, 0x6ef41859, 0xec01b79a, 0x83a89a4f, 0xe6656e95, 0xaa7ee6ff, 0x2108cfbc, 0xefe6e815, 0xbad99be7, 0x4ace366f, 0xead4099f, 0x29d67cb0, 0x31afb2a4, 0x2a31233f, 0xc63094a5, 0x35c066a2, 0x7437bc4e, 0xfca6ca82, 0xe0b0d090, 0x3315d8a7, 0xf14a9804, 0x41f7daec, 0x7f0e50cd, 0x172ff691, 0x768dd64d, 0x434db0ef, 0xcc544daa, 0xe4df0496, 0x9ee3b5d1, 0x4c1b886a, 0xc1b81f2c, 0x467f5165, 0x9d04ea5e, 0x015d358c, 0xfa737487, 0xfb2e410b, 0xb35a1d67, 0x9252d2db, 0xe9335610, 0x6d1347d6, 0x9a8c61d7, 0x377a0ca1, 0x598e14f8, 0xeb893c13, 0xceee27a9, 0xb735c961, 0xe1ede51c, 0x7a3cb147, 0x9c59dfd2, 0x553f73f2, 0x1879ce14, 0x73bf37c7, 0x53eacdf7, 0x5f5baafd, 0xdf146f3d, 0x7886db44, 0xca81f3af, 0xb93ec468, 0x382c3424, 0xc25f40a3, 0x1672c31d, 0xbc0c25e2, 0x288b493c, 0xff41950d, 0x397101a8, 0x08deb30c, 0xd89ce4b4, 0x6490c156, 0x7b6184cb, 0xd570b632, 0x48745c6c, 0xd04257b8];
abstract class BaseBlockCipher implements BlockCipher {
  Uint8List process(Uint8List data_A) {
    var out = new Uint8List(blockSize);
    var len = processBlock(data_A, 0, out, 0);
    return out.sublist(0, len);
  }
}
abstract class BaseDigest implements Digest {
  Uint8List process(Uint8List data_A) {
    update(data_A, 0, data_A.length);
    var out = new Uint8List(digestSize);
    var len = doFinal(out, 0);
    return out.sublist(0, len);
  }
}
abstract class MD4FamilyDigest extends BaseDigest {
  final _byteCount = new Register64(0);
  final _wordBuffer = new Uint8List(4);
  int _wordBufferOffset;
  final Endianness _endian;
  final _packedStateSize;
  final state;
  final buffer;
  int bufferOffset;
  MD4FamilyDigest(this._endian, int stateSize, int bufferSize_A, [int packedStateSize = null]) : _packedStateSize = (packedStateSize == null) ? stateSize : packedStateSize, state = new List<int>(stateSize), buffer = new List<int>(bufferSize_A) {
    reset();
  }
  void resetState();
  void processBlock();
  void reset() {
    _byteCount.set(0);
    _wordBufferOffset = 0;
    _wordBuffer.fillRange(0, _wordBuffer.length, 0);
    bufferOffset = 0;
    buffer.fillRange(0, buffer.length, 0);
    resetState();
  }
  void updateByte(int inp) {
    _wordBuffer[_wordBufferOffset++] = clip8(inp);
    _processWordIfBufferFull();
    _byteCount.sum(1);
  }
  void update(Uint8List inp, int inpOff, int len) {
    var nbytes;
    nbytes = _processUntilNextWord(inp, inpOff, len);
    inpOff += nbytes;
    len -= nbytes;
    nbytes = _processWholeWords(inp, inpOff, len);
    inpOff += nbytes;
    len -= nbytes;
    _processBytes(inp, inpOff, len);
  }
  int doFinal(Uint8List out, int outOff) {
    var bitLength_A = new Register64(_byteCount)
        ..shiftl(3);
    _processPadding();
    _processLength(bitLength_A);
    _doProcessBlock();
    _packState(out, outOff);
    reset();
    return digestSize;
  }
  void _processWord(Uint8List inp, int inpOff) {
    buffer[bufferOffset++] = unpack32(inp, inpOff, _endian);
    if (bufferOffset == 16) {
      _doProcessBlock();
    }
  }
  void _doProcessBlock() {
    processBlock();
    bufferOffset = 0;
    buffer.fillRange(0, 16, 0);
  }
  void _processBytes(Uint8List inp, int inpOff, int len) {
    while (len > 0) {
      updateByte(inp[inpOff]);
      inpOff++;
      len--;
    }
  }
  int _processWholeWords(Uint8List inp, int inpOff, int len) {
    int processed_A = 0;
    while (len > _wordBuffer.length) {
      _processWord(inp, inpOff);
      inpOff += _wordBuffer.length;
      len -= _wordBuffer.length;
      _byteCount.sum(_wordBuffer.length);
      processed_A += 4;
    }
    return processed_A;
  }
  int _processUntilNextWord(Uint8List inp, int inpOff, int len) {
    var processed_A = 0;
    while ((_wordBufferOffset != 0) && (len > 0)) {
      updateByte(inp[inpOff]);
      inpOff++;
      len--;
      processed_A++;
    }
    return processed_A;
  }
  void _processWordIfBufferFull() {
    if (_wordBufferOffset == _wordBuffer.length) {
      _processWord(_wordBuffer, 0);
      _wordBufferOffset = 0;
    }
  }
  void _processPadding() {
    updateByte(128);
    while (_wordBufferOffset != 0) {
      updateByte(0);
    }
  }
  void _processLength(Register64 bitLength_A) {
    if (bufferOffset > 14) {
      _doProcessBlock();
    }
    switch (_endian) {
      case Endianness.LITTLE_ENDIAN:
        buffer[14] = bitLength_A.lo32;
        buffer[15] = bitLength_A.hi32;
        break;

      case Endianness.BIG_ENDIAN:
        buffer[14] = bitLength_A.hi32;
        buffer[15] = bitLength_A.lo32;
        break;

      default:
        throw new StateError("Invalid endianness: ${_endian}");
    }
  }
  void _packState(Uint8List out, int outOff) {
    for (int i = 0; i < _packedStateSize; i++) {
      pack32(state[i], out, (outOff + i * 4), _endian);
    }
  }
}
class SHA256Digest extends MD4FamilyDigest implements Digest {
  static const _DIGEST_LENGTH = 32;
  SHA256Digest() : super(Endianness.BIG_ENDIAN, 8, 64);
  final algorithmName = "SHA-256";
  final digestSize = _DIGEST_LENGTH;
  void resetState() {
    state[0] = 0x6a09e667;
    state[1] = 0xbb67ae85;
    state[2] = 0x3c6ef372;
    state[3] = 0xa54ff53a;
    state[4] = 0x510e527f;
    state[5] = 0x9b05688c;
    state[6] = 0x1f83d9ab;
    state[7] = 0x5be0cd19;
  }
  void processBlock() {
    for (var t = 16; t < 64; t++) {
      buffer[t] = clip32(_Theta1(buffer[t - 2]) + buffer[t - 7] + _Theta0(buffer[t - 15]) + buffer[t - 16]);
    }
    var a = state[0];
    var b = state[1];
    var c = state[2];
    var d = state[3];
    var e = state[4];
    var f = state[5];
    var g = state[6];
    var h = state[7];
    var t = 0;
    for (var i = 0; i < 8; i++) {
      h = clip32(h + _Sum1(e) + _Ch(e, f, g) + _K[t] + buffer[t]);
      d = clip32(d + h);
      h = clip32(h + _Sum0(a) + _Maj(a, b, c));
      ++t;
      g = clip32(g + _Sum1(d) + _Ch(d, e, f) + _K[t] + buffer[t]);
      c = clip32(c + g);
      g = clip32(g + _Sum0(h) + _Maj(h, a, b));
      ++t;
      f = clip32(f + _Sum1(c) + _Ch(c, d, e) + _K[t] + buffer[t]);
      b = clip32(b + f);
      f = clip32(f + _Sum0(g) + _Maj(g, h, a));
      ++t;
      e = clip32(e + _Sum1(b) + _Ch(b, c, d) + _K[t] + buffer[t]);
      a = clip32(a + e);
      e = clip32(e + _Sum0(f) + _Maj(f, g, h));
      ++t;
      d = clip32(d + _Sum1(a) + _Ch(a, b, c) + _K[t] + buffer[t]);
      h = clip32(h + d);
      d = clip32(d + _Sum0(e) + _Maj(e, f, g));
      ++t;
      c = clip32(c + _Sum1(h) + _Ch(h, a, b) + _K[t] + buffer[t]);
      g = clip32(g + c);
      c = clip32(c + _Sum0(d) + _Maj(d, e, f));
      ++t;
      b = clip32(b + _Sum1(g) + _Ch(g, h, a) + _K[t] + buffer[t]);
      f = clip32(f + b);
      b = clip32(b + _Sum0(c) + _Maj(c, d, e));
      ++t;
      a = clip32(a + _Sum1(f) + _Ch(f, g, h) + _K[t] + buffer[t]);
      e = clip32(e + a);
      a = clip32(a + _Sum0(b) + _Maj(b, c, d));
      ++t;
    }
    state[0] = clip32(state[0] + a);
    state[1] = clip32(state[1] + b);
    state[2] = clip32(state[2] + c);
    state[3] = clip32(state[3] + d);
    state[4] = clip32(state[4] + e);
    state[5] = clip32(state[5] + f);
    state[6] = clip32(state[6] + g);
    state[7] = clip32(state[7] + h);
  }
  int _Ch(int x_A, int y_A, int z_A) => (x_A & y_A) ^ ((~x_A) & z_A);
  int _Maj(int x_A, int y_A, int z_A) => (x_A & y_A) ^ (x_A & z_A) ^ (y_A & z_A);
  int _Sum0(int x_A) => rotr32(x_A, 2) ^ rotr32(x_A, 13) ^ rotr32(x_A, 22);
  int _Sum1(int x_A) => rotr32(x_A, 6) ^ rotr32(x_A, 11) ^ rotr32(x_A, 25);
  int _Theta0(int x_A) => rotr32(x_A, 7) ^ rotr32(x_A, 18) ^ shiftr32(x_A, 3);
  int _Theta1(int x_A) => rotr32(x_A, 17) ^ rotr32(x_A, 19) ^ shiftr32(x_A, 10);
  static final _K = [0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5, 0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174, 0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da, 0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967, 0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85, 0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070, 0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3, 0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2];
}
class ECDomainParametersImpl implements ECDomainParameters {
  final String domainName;
  final ECCurve curve;
  final List<int> seed;
  final ECPoint G;
  final BigInteger n;
  BigInteger _h_A;
  ECDomainParametersImpl(this.domainName, this.curve, this.G, this.n, [this._h_A = null, this.seed = null]) {
    if (_h_A == null) {
      _h_A = BigInteger.ONE_A;
    }
  }
}
abstract class ECFieldElementBase implements ECFieldElement {
  BigInteger toBigInteger();
  int get fieldSize;
  int get byteLength => ((fieldSize + 7) ~/ 8);
  ECFieldElementBase operator+(ECFieldElementBase b);
  ECFieldElementBase operator-(ECFieldElementBase b);
  ECFieldElementBase operator*(ECFieldElementBase b);
  ECFieldElementBase operator/(ECFieldElementBase b);
  ECFieldElementBase operator-();
  ECFieldElementBase square();
  ECFieldElementBase sqrt();
  String toString() => toBigInteger().toString();
}
abstract class ECPointBase implements ECPoint {
  final ECCurveBase curve;
  final ECFieldElementBase x;
  final ECFieldElementBase y;
  final bool isCompressed;
  final ECMultiplier _multiplier;
  PreCompInfo _preCompInfo;
  ECPointBase(this.curve, this.x, this.y, this.isCompressed, [this._multiplier = _FpNafMultiplier]);
  bool get isInfinity => (x == null && y == null);
  void set preCompInfo(PreCompInfo preCompInfo_A) {
    _preCompInfo = preCompInfo_A;
  }
  bool operator==(other) {
    if (other is ECPointBase) {
      if (isInfinity) {
        return other.isInfinity;
      }
      return x == other.x && y == other.y;
    }
    return false;
  }
  String toString() => "(${x},${y})";
  int get hashCode {
    if (isInfinity) {
      return 0;
    }
    return x.hashCode ^ y.hashCode;
  }
  Uint8List getEncoded([bool compressed = true]);
  ECPointBase operator+(ECPointBase b);
  ECPointBase operator-(ECPointBase b);
  ECPointBase operator-();
  ECPointBase twice();
  ECPointBase operator*(BigInteger k) {
    if (k.signum() < 0) {
      throw new ArgumentError("The multiplicator cannot be negative");
    }
    if (isInfinity) {
      return this;
    }
    if (k.signum() == 0) {
      return curve.infinity;
    }
    return _multiplier(this, k, _preCompInfo);
  }
}
abstract class ECCurveBase implements ECCurve {
  ECFieldElementBase _a;
  ECFieldElementBase _b;
  ECCurveBase(BigInteger a_A, BigInteger b_A) {
    this._a = fromBigInteger(a_A);
    this._b = fromBigInteger(b_A);
  }
  ECFieldElementBase get a => _a;
  ECFieldElementBase get b => _b;
  int get fieldSize;
  ECPointBase get infinity;
  ECFieldElementBase fromBigInteger(BigInteger x_A);
  ECPointBase createPoint(BigInteger x_A, BigInteger y_A, [bool withCompression = false]);
  ECPointBase decompressPoint(int yTilde, BigInteger X1);
  ECPointBase decodePoint(List<int> encoded) {
    ECPointBase p = null;
    int expectedLength = (fieldSize + 7) ~/ 8;
    switch (encoded[0]) {
      case 0x00:
        if (encoded.length != 1) {
          throw new ArgumentError("Incorrect length for infinity encoding");
        }
        p = infinity;
        break;

      case 0x02: case 0x03:
        if (encoded.length != (expectedLength + 1)) {
          throw new ArgumentError("Incorrect length for compressed encoding");
        }
        int yTilde = encoded[0] & 1;
        var X1 = _fromArray(encoded, 1, expectedLength);
        p = decompressPoint(yTilde, X1);
        break;

      case 0x04: case 0x06: case 0x07:
        if (encoded.length != (2 * expectedLength + 1)) {
          throw new ArgumentError("Incorrect length for uncompressed/hybrid encoding");
        }
        BigInteger X1 = _fromArray(encoded, 1, expectedLength);
        BigInteger Y1 = _fromArray(encoded, 1 + expectedLength, expectedLength);
        p = createPoint(X1, Y1, false);
        break;

      default:
        throw new ArgumentError("Invalid point encoding 0x" + encoded[0].toRadixString(16));
    }
    return p;
  }
  BigInteger _fromArray(List<int> buf, int off, int length_A) {
    return new BigInteger.fromBytes_A(1, buf.sublist(off, off + length_A));
  }
}
abstract class PreCompInfo {}
typedef ECPointBase ECMultiplier(ECPointBase _0, BigInteger _1, PreCompInfo _2);
ECPointBase _FpNafMultiplier(ECPointBase p, BigInteger k, PreCompInfo preCompInfo) {
  BigInteger e = k;
  BigInteger h = e * BigInteger.THREE;
  ECPointBase neg = -p;
  ECPointBase R = p;
  for (var i = h.bitLength() - 2; i > 0; --i) {
    R = R.twice();
    var hBit = h.testBit(i);
    var eBit = e.testBit(i);
    if (hBit != eBit) {
      R += (hBit ? p : neg);
    }
  }
  return R;
}
class ECFieldElement_A extends ECFieldElementBase {
  final BigInteger q;
  final BigInteger x;
  ECFieldElement_A(this.q, this.x) {
    if (x >= q) {
      throw new ArgumentError("Value x must be smaller than q");
    }
  }
  int get fieldSize => q.bitLength();
  BigInteger toBigInteger() => x;
  ECFieldElement_A operator+(ECFieldElement_A b) => new ECFieldElement_A(q, (x + b.toBigInteger()) % q);
  ECFieldElement_A operator-(ECFieldElement_A b) => new ECFieldElement_A(q, (x - b.toBigInteger()) % q);
  ECFieldElement_A operator*(ECFieldElement_A b) => new ECFieldElement_A(q, (x * b.toBigInteger()) % q);
  ECFieldElement_A operator/(ECFieldElement_A b) => new ECFieldElement_A(q, (x * b.toBigInteger().modInverse(q)) % q);
  ECFieldElement_A operator-() => new ECFieldElement_A(q, -x % q);
  ECFieldElement_A square() => new ECFieldElement_A(q, x.modPow(BigInteger.TWO, q));
  ECFieldElement_A sqrt() {
    if (!q.testBit(0)) {
      throw new UnimplementedError("Not implemented yet");
    }
    if (q.testBit(1)) {
      var z_A = new ECFieldElement_A(q, x.modPow((q >> 2) + BigInteger.ONE_A, q));
      return z_A.square() == this ? z_A : null;
    }
    var qMinusOne = q - BigInteger.ONE_A;
    var legendreExponent = qMinusOne >> 1;
    if (x.modPow(legendreExponent, q) != BigInteger.ONE_A) {
      return null;
    }
    var u = qMinusOne >> 2;
    var k = (u << 1) + BigInteger.ONE_A;
    var Q = x;
    var fourQ = (Q >> 2) % q;
    var U, V;
    var rand = new SecureRandom();
    do {
      BigInteger P;
      do {
        P = rand.nextBigInteger(q.bitLength());
      } while ((P >= q) || (((P * P) - fourQ).modPow(legendreExponent, q) != qMinusOne));
      List<BigInteger> result_A = _lucasSequence(q, P, Q, k);
      U = result_A[0];
      V = result_A[1];
      if (((V * V) % q) == fourQ) {
        if (V.testBit(0)) {
          V = V + q;
        }
        V = (V >> 1);
        return new ECFieldElement_A(q, V);
      }
    } while ((U == BigInteger.ONE_A) || (U == qMinusOne));
    return null;
  }
  List<BigInteger> _lucasSequence(BigInteger p, BigInteger P, BigInteger Q, BigInteger k) {
    var n = k.bitLength();
    var s = k.lowestSetBit;
    BigInteger Uh = BigInteger.ONE_A;
    BigInteger Vl = BigInteger.TWO;
    BigInteger Vh = P;
    BigInteger Ql = BigInteger.ONE_A;
    BigInteger Qh = BigInteger.ONE_A;
    for (var j = n - 1; j >= (s + 1); j--) {
      Ql = (Ql * Qh) % p;
      if (k.testBit(j)) {
        Qh = (Ql * Q) % p;
        Uh = (Uh * Vh) % p;
        Vl = ((Vh * Vl) - (P * Ql)) % p;
        Vh = ((Vh * Vh) - (Qh << 1)) % p;
      } else {
        Qh = Ql;
        Uh = ((Uh * Vl) - Ql) % p;
        Vh = ((Vh * Vl) - (P * Ql)) % p;
        Vl = ((Vl * Vl) - (Ql << 1)) % p;
      }
    }
    Ql = (Ql * Qh) % p;
    Qh = (Ql * Q) % p;
    Uh = ((Uh * Vl) - Ql) % p;
    Vl = ((Vh * Vl) - (P * Ql)) % p;
    Ql = (Ql * Qh) % p;
    for (var j = 1; j <= s; j++) {
      Uh = (Uh * Vl) % p;
      Vl = ((Vl * Vl) - (Ql << 1)) % p;
      Ql = (Ql * Ql) % p;
    }
    return [Uh, Vl];
  }
  bool operator==(other) {
    if (other is ECFieldElement_A) {
      return (q == other.q) && (x == other.x);
    }
    return false;
  }
  int get hashCode => q.hashCode ^ x.hashCode;
}
class ECPoint_A extends ECPointBase {
  ECPoint_A(ECCurve_A curve, ECFieldElement_A x_A, ECFieldElement_A y_A, [bool withCompression = false]) : super(curve, x_A, y_A, withCompression, _WNafMultiplier) {
    if ((x_A != null && y_A == null) || (x_A == null && y_A != null)) {
      throw new ArgumentError("Exactly one of the field elements is null");
    }
  }
  Uint8List getEncoded([bool compressed = true]) {
    if (isInfinity) {
      return new Uint8List.fromList([1]);
    }
    var qLength = x.byteLength;
    if (compressed) {
      int PC;
      if (y.toBigInteger().testBit(0)) {
        PC = 0x03;
      } else {
        PC = 0x02;
      }
      Uint8List X = _x9IntegerToBytes(x.toBigInteger(), qLength);
      Uint8List PO = new Uint8List(X.length + 1);
      PO[0] = PC.toInt();
      PO.setAll(1, X);
      return PO;
    } else {
      Uint8List X = _x9IntegerToBytes(x.toBigInteger(), qLength);
      Uint8List Y = _x9IntegerToBytes(y.toBigInteger(), qLength);
      Uint8List PO = new Uint8List(X.length + Y.length + 1);
      PO[0] = 0x04;
      PO.setAll(1, X);
      PO.setAll(X.length + 1, Y);
      return PO;
    }
  }
  ECPoint_A operator+(ECPoint_A b) {
    if (isInfinity) {
      return b;
    }
    if (b.isInfinity) {
      return this;
    }
    if (x == b.x) {
      if (y == b.y) {
        return twice();
      }
      return curve.infinity;
    }
    var gamma = (b.y - y) / (b.x - x);
    var x3 = (gamma.square() - x) - b.x;
    var y3 = (gamma * (x - x3)) - y;
    return new ECPoint_A(curve, x3, y3, isCompressed);
  }
  ECPoint_A twice() {
    if (isInfinity) {
      return this;
    }
    if (y.toBigInteger() == 0) {
      return this.curve.infinity;
    }
    var TWO_A = curve.fromBigInteger(BigInteger.TWO);
    var THREE_A = curve.fromBigInteger(BigInteger.THREE);
    var gamma = ((x.square() * THREE_A) + curve.a) / (y * TWO_A);
    var x3 = gamma.square() - (x * TWO_A);
    var y3 = (gamma * (x - x3)) - y;
    return new ECPoint_A(curve, x3, y3, isCompressed);
  }
  ECPoint_A operator-(ECPoint_A b) {
    if (b.isInfinity) {
      return this;
    }
    return this + (-b);
  }
  ECPoint_A operator-() {
    return new ECPoint_A(curve, x, -y, isCompressed);
  }
}
class ECCurve_A extends ECCurveBase {
  final BigInteger q;
  ECPoint_A _infinity;
  ECCurve_A(this.q, BigInteger a, BigInteger b) : super(a, b) {
    _infinity = new ECPoint_A(this, null, null);
  }
  int get fieldSize => q.bitLength();
  ECPoint_A get infinity => _infinity;
  ECFieldElement_A fromBigInteger(BigInteger x_A) => new ECFieldElement_A(this.q, x_A);
  ECPoint_A createPoint(BigInteger x_A, BigInteger y_A, [bool withCompression = false]) => new ECPoint_A(this, fromBigInteger(x_A), fromBigInteger(y_A), withCompression);
  ECPoint_A decompressPoint(int yTilde, BigInteger X1) {
    var x_A = fromBigInteger(X1);
    var alpha = (x_A * ((x_A * x_A) + a)) + b;
    ECFieldElement_A beta = alpha.sqrt();
    if (beta == null) {
      throw new ArgumentError("Invalid point compression");
    }
    var betaValue = beta.toBigInteger();
    var bit0 = betaValue.testBit(0) ? 1 : 0;
    if (bit0 != yTilde) {
      beta = fromBigInteger(q - betaValue);
    }
    return new ECPoint_A(this, x_A, beta, true);
  }
  bool operator==(other) {
    if (other is ECCurve_A) {
      return q == other.q && a == other.a && b == other.b;
    }
    return false;
  }
  int get hashCode => a.hashCode ^ b.hashCode ^ q.hashCode;
}
class _WNafPreCompInfo implements PreCompInfo {
  List<ECPoint_A> preComp;
  ECPoint_A twiceP;
}
ECPoint_A _WNafMultiplier(ECPoint_A p, BigInteger k, PreCompInfo preCompInfo) {
  _WNafPreCompInfo wnafPreCompInfo = preCompInfo;
  if ((preCompInfo == null) && (preCompInfo is! _WNafPreCompInfo)) {
    wnafPreCompInfo = new _WNafPreCompInfo();
  }
  var m = k.bitLength();
  var width_A;
  var reqPreCompLen;
  if (m < 13) {
    width_A = 2;
    reqPreCompLen = 1;
  } else {
    if (m < 41) {
      width_A = 3;
      reqPreCompLen = 2;
    } else {
      if (m < 121) {
        width_A = 4;
        reqPreCompLen = 4;
      } else {
        if (m < 337) {
          width_A = 5;
          reqPreCompLen = 8;
        } else {
          if (m < 897) {
            width_A = 6;
            reqPreCompLen = 16;
          } else {
            if (m < 2305) {
              width_A = 7;
              reqPreCompLen = 32;
            } else {
              width_A = 8;
              reqPreCompLen = 127;
            }
          }
        }
      }
    }
  }
  var preCompLen = 1;
  var preComp = wnafPreCompInfo.preComp;
  var twiceP = wnafPreCompInfo.twiceP;
  if (preComp == null) {
    preComp = new List<ECPoint_A>.filled(1, p);
  } else {
    preCompLen = preComp.length;
  }
  if (twiceP == null) {
    twiceP = p.twice();
  }
  if (preCompLen < reqPreCompLen) {
    List<ECPoint_A> oldPreComp = preComp;
    preComp = new List<ECPoint_A>(reqPreCompLen);
    preComp.setAll(0, oldPreComp);
    for (int i = preCompLen; i < reqPreCompLen; i++) {
      preComp[i] = twiceP + (preComp[i - 1]);
    }
  }
  var wnaf = _windowNaf(width_A, k);
  var l = wnaf.length;
  var q = p.curve.infinity;
  for (int i = l - 1; i >= 0; i--) {
    q = q.twice();
    if (wnaf[i] != 0) {
      if (wnaf[i] > 0) {
        q += preComp[(wnaf[i] - 1) ~/ 2];
      } else {
        q -= preComp[(-wnaf[i] - 1) ~/ 2];
      }
    }
  }
  wnafPreCompInfo.preComp = preComp;
  wnafPreCompInfo.twiceP = twiceP;
  p.preCompInfo = wnafPreCompInfo;
  return q;
}
List<int> _windowNaf(int width_A, BigInteger k) {
  List<int> wnaf = new List<int>(k.bitLength() + 1);
  int pow2wB = (1 << width_A);
  BigInteger pow2wBI = new BigInteger(pow2wB);
  int i = 0;
  int length_A = 0;
  while (k.signum() > 0) {
    if (k.testBit(0)) {
      BigInteger remainder_A = k.mod(pow2wBI);
      if (remainder_A.testBit(width_A - 1)) {
        wnaf[i] = remainder_A.intValue() - pow2wB;
      } else {
        wnaf[i] = remainder_A.intValue();
      }
      wnaf[i] %= 0x100;
      if ((wnaf[i] & 0x80) != 0) {
        wnaf[i] = wnaf[i] - 256;
      }
      k = k - new BigInteger(wnaf[i]);
      length_A = i;
    } else {
      wnaf[i] = 0;
    }
    k = k.shiftRight(1);
    i++;
  }
  length_A++;
  List<int> wnafShort = new List<int>(length_A);
  wnafShort.setAll(0, wnaf.sublist(0, length_A));
  return wnafShort;
}
Uint8List _x9IntegerToBytes(BigInteger s, int qLength) {
  Uint8List bytes_A = new Uint8List.fromList(s.toByteArray());
  if (qLength < bytes_A.length) {
    return bytes_A.sublist(bytes_A.length - qLength);
  } else if (qLength > bytes_A.length) {
    return new Uint8List(qLength)
        ..setAll(qLength - bytes_A.length, bytes_A);
  }
  return bytes_A;
}
class ECKeyGenerator implements KeyGenerator {
  ECDomainParameters _params;
  SecureRandom _random;
  void init(CipherParameters params) {
    ECKeyGeneratorParameters ecparams;
    if (params is ParametersWithRandom) {
      _random = params.random;
      ecparams = params.parameters;
    } else {
      _random = new SecureRandom();
      ecparams = params;
    }
    _params = ecparams.domainParameters;
  }
  AsymmetricKeyPair generateKeyPair() {
    var n = _params.n;
    var nBitLength = n.bitLength();
    var d;
    do {
      d = _random.nextBigInteger(nBitLength);
    } while (d == BigInteger.ZERO_A || (d >= n));
    var Q = _params.G * d;
    return new AsymmetricKeyPair(new ECPublicKey(Q, _params), new ECPrivateKey(d, _params));
  }
}
class ECKeyGeneratorParameters extends KeyGeneratorParameters {
  ECDomainParameters _domainParameters;
  ECKeyGeneratorParameters(ECDomainParameters domainParameters_A) : super(domainParameters_A.n.bitLength()) {
    _domainParameters = domainParameters_A;
  }
  ECDomainParameters get domainParameters => _domainParameters;
}
abstract class KeyGeneratorParameters implements CipherParameters {
  final int bitStrength;
  KeyGeneratorParameters(this.bitStrength);
}
class KeyParameter extends CipherParameters {
  final Uint8List key;
  KeyParameter(this.key);
}
class ParametersWithIV<UnderlyingParameters extends CipherParameters> implements CipherParameters {
  final Uint8List iv;
  final UnderlyingParameters parameters;
  ParametersWithIV(this.parameters, this.iv);
}
class ParametersWithRandom<UnderlyingParameters extends CipherParameters> implements CipherParameters {
  final UnderlyingParameters parameters;
  final SecureRandom random;
  ParametersWithRandom(this.parameters, this.random);
}
class BlockCtrRandom extends SecureRandomBase implements SecureRandom {
  final BlockCipher cipher;
  Uint8List _input;
  Uint8List _output;
  var _used;
  BlockCtrRandom(this.cipher) {
    _input = new Uint8List(cipher.blockSize);
    _output = new Uint8List(cipher.blockSize);
    _used = _output.length;
  }
  void seed(ParametersWithIV<CipherParameters> params) {
    _used = _output.length;
    _input.setAll(0, params.iv);
    cipher.init(true, params.parameters);
  }
  int nextUint8() {
    if (_used == _output.length) {
      cipher.processBlock(_input, 0, _output, 0);
      _used = 0;
      _incrementInput();
    }
    return clip8(_output[_used++]);
  }
  void _incrementInput() {
    int offset_A = _input.length;
    do {
      offset_A--;
      _input[offset_A] += 1;
    } while (_input[offset_A] == 0);
  }
}
abstract class SecureRandomBase implements SecureRandom {
  BigInteger nextBigInteger(int bitLength_A) {
    return new BigInteger.fromBytes_A(1, _randomBits(bitLength_A));
  }
  List<int> _randomBits(int numBits) {
    if (numBits < 0) {
      throw new ArgumentError("numBits must be non-negative");
    }
    var numBytes = (numBits + 7) ~/ 8;
    var randomBits = new Uint8List(numBytes);
    if (numBytes > 0) {
      for (var i = 0; i < numBytes; i++) {
        randomBits[i] = nextUint8();
      }
      int excessBits = 8 * numBytes - numBits;
      randomBits[0] &= (1 << (8 - excessBits)) - 1;
    }
    return randomBits;
  }
}
const _MASK_5 = 0x1F;
const _MASK_6 = 0x3F;
const _MASK_8_A = 0xFF;
const _MASK_32_A = 0xFFFFFFFF;
final _MASK32_HI_BITS = [0xFFFFFFFF, 0x7FFFFFFF, 0x3FFFFFFF, 0x1FFFFFFF, 0x0FFFFFFF, 0x07FFFFFF, 0x03FFFFFF, 0x01FFFFFF, 0x00FFFFFF, 0x007FFFFF, 0x003FFFFF, 0x001FFFFF, 0x000FFFFF, 0x0007FFFF, 0x0003FFFF, 0x0001FFFF, 0x0000FFFF, 0x00007FFF, 0x00003FFF, 0x00001FFF, 0x00000FFF, 0x000007FF, 0x000003FF, 0x000001FF, 0x000000FF, 0x0000007F, 0x0000003F, 0x0000001F, 0x0000000F, 0x00000007, 0x00000003, 0x00000001, 0x00000000];
int clip8(int x_A) => (x_A & _MASK_8_A);
int clip32(int x_A) => (x_A & _MASK_32_A);
int shiftl32(int x_A, int n) {
  assert((x_A >= 0) && (x_A <= _MASK_32_A));
  n &= _MASK_5;
  x_A &= _MASK32_HI_BITS[n];
  return ((x_A << n) & _MASK_32_A);
}
int shiftr32(int x_A, int n) {
  assert((x_A >= 0) && (x_A <= _MASK_32_A));
  n &= _MASK_5;
  return (x_A >> n);
}
int rotr32(int x_A, int n) {
  assert(n >= 0);
  assert((x_A >= 0) && (x_A <= _MASK_32_A));
  n &= _MASK_5;
  return (x_A >> n) | shiftl32(x_A, (32 - n));
}
void pack32(int x_A, dynamic out, int offset_A, Endianness endian) {
  assert((x_A >= 0) && (x_A <= _MASK_32_A));
  if (out is! ByteData) {
    out = new ByteData.view(out.buffer);
  }
  (out as ByteData).setUint32(offset_A, x_A, endian);
}
int unpack32(dynamic inp, int offset_A, Endianness endian) {
  if (inp is! ByteData) {
    inp = new ByteData.view(inp.buffer);
  }
  return (inp as ByteData).getUint32(offset_A, endian);
}
class Register64 {
  int _hi32;
  int _lo32;
  Register64([dynamic hiOrLo32OrY = 0, int lo32_A = null]) {
    set(hiOrLo32OrY, lo32_A);
  }
  int get lo32 => _lo32;
  int get hi32 => _hi32;
  bool operator==(Register64 y_A) => ((_hi32 == y_A._hi32) && (_lo32 == y_A._lo32));
  bool operator<(Register64 y_A) => ((_hi32 < y_A._hi32) || ((_hi32 == y_A._hi32) && (_lo32 < y_A._lo32)));
  bool operator<=(Register64 y_A) => ((this < y_A) || (this == y_A));
  bool operator>(Register64 y_A) => ((_hi32 > y_A._hi32) || ((_hi32 == y_A._hi32) && (_lo32 > y_A._lo32)));
  bool operator>=(Register64 y_A) => ((this > y_A) || (this == y_A));
  void set(dynamic hiOrLo32OrY, [int lo32_A = null]) {
    if (lo32_A == null) {
      if (hiOrLo32OrY is Register64) {
        _hi32 = hiOrLo32OrY._hi32;
        _lo32 = hiOrLo32OrY._lo32;
      } else {
        assert(hiOrLo32OrY <= _MASK_32_A);
        _hi32 = 0;
        _lo32 = hiOrLo32OrY;
      }
    } else {
      assert(hiOrLo32OrY <= _MASK_32_A);
      assert(lo32_A <= _MASK_32_A);
      _hi32 = hiOrLo32OrY;
      _lo32 = lo32_A;
    }
  }
  void sum(dynamic y_A) {
    if (y_A is int) {
      y_A &= _MASK_32_A;
      int slo32 = (_lo32 + y_A);
      _lo32 = (slo32 & _MASK_32_A);
      if (slo32 != _lo32) {
        _hi32++;
        _hi32 &= _MASK_32_A;
      }
    } else {
      int slo32 = (_lo32 + y_A._lo32);
      _lo32 = (slo32 & _MASK_32_A);
      int carry = ((slo32 != _lo32) ? 1 : 0);
      _hi32 = (((_hi32 + y_A._hi32 + carry) as int) & _MASK_32_A);
    }
  }
  void not() {
    _hi32 = (~_hi32 & _MASK_32_A);
    _lo32 = (~_lo32 & _MASK_32_A);
  }
  void and(Register64 y_A) {
    _hi32 &= y_A._hi32;
    _lo32 &= y_A._lo32;
  }
  void or(Register64 y_A) {
    _hi32 |= y_A._hi32;
    _lo32 |= y_A._lo32;
  }
  void xor(Register64 y_A) {
    _hi32 ^= y_A._hi32;
    _lo32 ^= y_A._lo32;
  }
  void shiftl(int n) {
    n &= _MASK_6;
    if (n == 0) {} else if (n >= 32) {
      _hi32 = shiftl32(_lo32, (n - 32));
      _lo32 = 0;
    } else {
      _hi32 = shiftl32(_hi32, n);
      _hi32 |= _lo32 >> (32 - n);
      _lo32 = shiftl32(_lo32, n);
    }
  }
  String toString() {
    var sb = new StringBuffer();
    _padWrite(sb, _hi32);
    _padWrite(sb, _lo32);
    return sb.toString();
  }
  void _padWrite(StringBuffer sb, int value_A) {
    var str = value_A.toRadixString(16);
    for (var i = (8 - str.length); i > 0; i--) {
      sb.write("0");
    }
    sb.write(str);
  }
}
abstract class Client {
  factory Client() {
    assertSupported("IOClient");
    return new IOClient();
  }
}
const String RED = '\u001b[31m';
const String NONE_A = '\u001b[0m';
abstract class Hash {}
class CryptoUtils {
  static String bytesToBase64_A(List<int> bytes_A, {bool urlSafe: false, bool addLineSeparator: false}) {
    return _CryptoUtils_A.bytesToBase64_B(bytes_A, urlSafe, addLineSeparator);
  }
  static List<int> base64StringToBytes_A(String input_A) {
    return _CryptoUtils_A.base64StringToBytes_B(input_A);
  }
}
const Base64Codec_A BASE64_A = const Base64Codec_A();
const List<int> _decodeTable_A = const[-2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -1, -2, -2, -1, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, 62, -2, 62, -2, 63, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, -2, -2, -2, 0, -2, -2, -2, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, -2, -2, -2, -2, 63, -2, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2];
const String _encodeTableUrlSafe_A = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_";
const String _encodeTable_A = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
const int _LINE_LENGTH = 76;
const int _CR_A = 13;
const int _LF_A = 10;
const List<int> _PAD_BYTES = const[61];
const List<int> _ENCODED_PAD_BYTES = const[37, 51, 68];
const String _PAD = "=";
const String _ENCODED_PAD = "%3D";
class Base64Codec_A extends Codec<List<int>, String> {
  final bool _urlSafe_A;
  final bool _addLineSeparator;
  final bool _encodePaddingCharacter;
  const Base64Codec_A({bool urlSafe: false, bool addLineSeparator: false, bool encodePaddingCharacter: false}) : _urlSafe_A = urlSafe, _addLineSeparator = addLineSeparator, _encodePaddingCharacter = encodePaddingCharacter;
  String get name => "base64";
  String encode(List<int> bytes_A, {bool urlSafe, bool addLineSeparator, bool encodePaddingCharacter}) {
    if (urlSafe == null) urlSafe = _urlSafe_A;
    if (addLineSeparator == null) addLineSeparator = _addLineSeparator;
    if (encodePaddingCharacter == null) {
      encodePaddingCharacter = _encodePaddingCharacter;
    }
    return new Base64Encoder_A(urlSafe: urlSafe, addLineSeparator: addLineSeparator, encodePaddingCharacter: encodePaddingCharacter).convert(bytes_A);
  }
  Base64Encoder_A get encoder => new Base64Encoder_A(urlSafe: _urlSafe_A, addLineSeparator: _addLineSeparator, encodePaddingCharacter: _encodePaddingCharacter);
  Base64Decoder_A get decoder => new Base64Decoder_A();
}
class Base64Encoder_A extends Converter<List<int>, String> {
  final bool _urlSafe_A;
  final bool _addLineSeparator;
  final bool _encodePaddingCharacter;
  final List<int> _pad;
  const Base64Encoder_A({bool urlSafe: false, bool addLineSeparator: false, bool encodePaddingCharacter: false}) : _urlSafe_A = urlSafe, _addLineSeparator = addLineSeparator, _encodePaddingCharacter = encodePaddingCharacter, _pad = encodePaddingCharacter == true ? _ENCODED_PAD_BYTES : _PAD_BYTES;
  String convert(List<int> bytes_A, [int start_A = 0, int end_A]) {
    int bytes_length = bytes_A.length;
    RangeError.checkValidRange(start_A, end_A, bytes_length);
    if (end_A == null) end_A = bytes_length;
    int length_A = end_A - start_A;
    if (length_A == 0) {
      return "";
    }
    final String lookup_A = _urlSafe_A ? _encodeTableUrlSafe_A : _encodeTable_A;
    final int remainderLength = length_A.remainder(3);
    final int chunkLength = length_A - remainderLength;
    int baseOutputLength = ((length_A ~/ 3) * 4);
    int remainderOutputLength;
    if (_encodePaddingCharacter) {
      remainderOutputLength = ((remainderLength > 0) ? 6 : 0);
    } else {
      remainderOutputLength = ((remainderLength > 0) ? 4 : 0);
    }
    int outputLength = baseOutputLength + remainderOutputLength;
    if (_addLineSeparator) {
      outputLength += ((outputLength - 1) ~/ _LINE_LENGTH) << 1;
    }
    List<int> out = new List<int>(outputLength);
    int j = 0, i = start_A, c = 0;
    while (i < chunkLength) {
      int x_A = ((bytes_A[i++] << 16) & 0x00FFFFFF) | ((bytes_A[i++] << 8) & 0x00FFFFFF) | bytes_A[i++];
      out[j++] = lookup_A.codeUnitAt(x_A >> 18);
      out[j++] = lookup_A.codeUnitAt((x_A >> 12) & 0x3F);
      out[j++] = lookup_A.codeUnitAt((x_A >> 6) & 0x3F);
      out[j++] = lookup_A.codeUnitAt(x_A & 0x3F);
      if (_addLineSeparator && ++c == 19 && j < outputLength - 2) {
        out[j++] = _CR_A;
        out[j++] = _LF_A;
        c = 0;
      }
    }
    if (remainderLength == 1) {
      int x_A = bytes_A[i];
      out[j++] = lookup_A.codeUnitAt(x_A >> 2);
      out[j++] = lookup_A.codeUnitAt((x_A << 4) & 0x3F);
      out.setRange(j, j + _pad.length, _pad);
      out.setRange(j + _pad.length, j + 2 * _pad.length, _pad);
    } else if (remainderLength == 2) {
      int x_A = bytes_A[i];
      int y_A = bytes_A[i + 1];
      out[j++] = lookup_A.codeUnitAt(x_A >> 2);
      out[j++] = lookup_A.codeUnitAt(((x_A << 4) | (y_A >> 4)) & 0x3F);
      out[j++] = lookup_A.codeUnitAt((y_A << 2) & 0x3F);
      out.setRange(j, j + _pad.length, _pad);
    }
    return new String.fromCharCodes(out);
  }
  _Base64EncoderSink_A startChunkedConversion(Sink<String> sink_A) {
    StringConversionSink stringSink;
    if (sink_A is StringConversionSink) {
      stringSink = sink_A;
    } else {
      stringSink = new StringConversionSink.from(sink_A);
    }
    return new _Base64EncoderSink_A(stringSink, _urlSafe_A, _addLineSeparator);
  }
}
class _Base64EncoderSink_A extends ChunkedConversionSink<List<int>> {
  final Base64Encoder_A _encoder_A;
  final ChunkedConversionSink<String> _outSink;
  final List<int> _buffer_A = new List<int>();
  int _bufferCount = 0;
  _Base64EncoderSink_A(this._outSink, urlSafe_A, addLineSeparator) : _encoder_A = new Base64Encoder_A(urlSafe: urlSafe_A, addLineSeparator: addLineSeparator);
  void add(List<int> chunk) {
    var nextBufferCount = (chunk.length + _bufferCount) % 3;
    int decodableLength = _bufferCount + chunk.length - nextBufferCount;
    if (_bufferCount + chunk.length > _buffer_A.length) {
      _buffer_A.replaceRange(_bufferCount, _buffer_A.length, chunk.sublist(0, _buffer_A.length - _bufferCount));
      _buffer_A.addAll(chunk.sublist(_buffer_A.length - _bufferCount));
    } else {
      _buffer_A.replaceRange(_bufferCount, _bufferCount + chunk.length, chunk);
    }
    _outSink.add(_encoder_A.convert(_buffer_A, 0, decodableLength));
    _buffer_A.removeRange(0, decodableLength);
    _bufferCount = nextBufferCount;
  }
  void close() {
    if (_bufferCount > 0) {
      _outSink.add(_encoder_A.convert(_buffer_A.sublist(0, _bufferCount)));
    }
    _outSink.close();
  }
}
class Base64Decoder_A extends Converter<String, List<int>> {
  const Base64Decoder_A();
  List<int> convert(String input_A) {
    int length_A = input_A.length;
    if (length_A == 0) {
      return new Uint8List(0);
    }
    int normalLength = 0;
    int i = 0;
    while (i < length_A) {
      int codeUnit = input_A.codeUnitAt(i);
      int c = _decodeTable_A[codeUnit];
      if (c == -2) {
        if (codeUnit == _ENCODED_PAD_BYTES[0] && i < length_A - 2 && input_A.codeUnitAt(i + 1) == _ENCODED_PAD_BYTES[1] && input_A.codeUnitAt(i + 2) == _ENCODED_PAD_BYTES[2]) {
          normalLength++;
          i += 2;
        } else {
          throw new FormatException('Invalid character', input_A, i);
        }
      }
      if (c >= 0) normalLength++;
      i++;
    }
    if (normalLength % 4 != 0) {
      throw new FormatException('''Size of Base 64 characters in Input
          must be a multiple of 4''', input_A, normalLength);
    }
    int padLength = 0;
    i = length_A - 1;
    while (i >= 0) {
      int currentCodeUnit = input_A.codeUnitAt(i);
      if (currentCodeUnit == _ENCODED_PAD_BYTES[2] && i >= 2 && input_A.codeUnitAt(i - 1) == _ENCODED_PAD_BYTES[1] && input_A.codeUnitAt(i - 2) == _ENCODED_PAD_BYTES[0]) {
        padLength++;
        i -= 2;
      } else if (_decodeTable_A[currentCodeUnit] > 0) {
        break;
      } else if (currentCodeUnit == _PAD_BYTES[0]) {
        padLength++;
      }
      i--;
    }
    int outputLength = ((normalLength * 6) >> 3) - padLength;
    List<int> out = new Uint8List(outputLength);
    for (int i = 0, o = 0; o < outputLength;) {
      int x_A = 0;
      for (int j = 4; j > 0;) {
        int c = _decodeTable_A[input_A.codeUnitAt(i++)];
        if (c >= 0) {
          x_A = ((x_A << 6) & 0x00FFFFFF) | c;
          j--;
        }
      }
      out[o++] = x_A >> 16;
      if (o < outputLength) {
        out[o++] = (x_A >> 8) & 0xFF;
        if (o < outputLength) out[o++] = x_A & 0xFF;
      }
    }
    return out;
  }
  _Base64DecoderSink_A startChunkedConversion(Sink<List<int>> sink_A) {
    if (sink_A is! ByteConversionSink) {
      sink_A = new ByteConversionSink.from(sink_A);
    }
    return new _Base64DecoderSink_A(sink_A);
  }
}
class _Base64DecoderSink_A extends ChunkedConversionSink<String> {
  final Base64Decoder_A _decoder_A = new Base64Decoder_A();
  final ChunkedConversionSink<List<int>> _outSink;
  String _unconverted = "";
  _Base64DecoderSink_A(this._outSink);
  void add(String chunk) {
    if (chunk.isEmpty) return;
    if (_unconverted.isNotEmpty) {
      chunk = _unconverted + chunk;
    }
    chunk = chunk.replaceAll(_ENCODED_PAD, _PAD);
    int decodableLength = chunk.length;
    if (chunk.length > 3 && chunk.contains(_ENCODED_PAD[0], chunk.length - 2)) {
      decodableLength = chunk.lastIndexOf(_ENCODED_PAD[0]);
    }
    decodableLength -= decodableLength % 4;
    _unconverted = chunk.substring(decodableLength);
    if (decodableLength > 0) {
      _outSink.add(_decoder_A.convert(chunk.substring(0, decodableLength)));
    }
  }
  void close() {
    if (_unconverted.isNotEmpty) {
      _outSink.add(_decoder_A.convert(_unconverted));
    }
    _outSink.close();
  }
}
abstract class _CryptoUtils_A {
  static String bytesToBase64_B(List<int> bytes_A, [bool urlSafe_A = false, bool addLineSeparator = false]) {
    return BASE64_A.encode(bytes_A, urlSafe: urlSafe_A, addLineSeparator: addLineSeparator);
  }
  static List<int> base64StringToBytes_B(String input_A) {
    return BASE64_A.decode(input_A);
  }
}
const _MASK_8_B = 0xff;
const _MASK_32_B = 0xffffffff;
const _BITS_PER_BYTE_A = 8;
const _BYTES_PER_WORD_A = 4;
int _rotl32_A(int val, int shift) {
  var mod_shift = shift & 31;
  return ((val << mod_shift) & _MASK_32_B) | ((val & _MASK_32_B) >> (32 - mod_shift));
}
abstract class _HashBase_A implements Hash {
  final int _chunkSizeInWords_A;
  final int _digestSizeInWords_A;
  final bool _bigEndianWords_A;
  final Uint32List _currentChunk_A;
  final Uint32List _h_B;
  int _lengthInBytes_A = 0;
  List<int> _pendingData_A;
  bool _digestCalled_A = false;
  _HashBase_A(int chunkSizeInWords, int digestSizeInWords, bool this._bigEndianWords_A) : _pendingData_A = [], _currentChunk_A = new Uint32List(chunkSizeInWords), _h_B = new Uint32List(digestSizeInWords), _chunkSizeInWords_A = chunkSizeInWords, _digestSizeInWords_A = digestSizeInWords;
  void add(List<int> data_A) {
    if (_digestCalled_A) {
      throw new StateError('Hash update method called after digest was retrieved');
    }
    _lengthInBytes_A += data_A.length;
    _pendingData_A.addAll(data_A);
    _iterate_A();
  }
  List<int> close() {
    if (_digestCalled_A) {
      return _resultAsBytes_A();
    }
    _digestCalled_A = true;
    _finalizeData_A();
    _iterate_A();
    assert(_pendingData_A.length == 0);
    return _resultAsBytes_A();
  }
  int get blockSize {
    return _chunkSizeInWords_A * _BYTES_PER_WORD_A;
  }
  void _updateHash_A(Uint32List m);
  int _add32_A(x_A, y_A) => (x_A + y_A) & _MASK_32_B;
  int _roundUp_A(val, n) => (val + n - 1) & -n;
  List<int> _resultAsBytes_A() {
    var result_A = [];
    for (var i = 0; i < _h_B.length; i++) {
      result_A.addAll(_wordToBytes_A(_h_B[i]));
    }
    return result_A;
  }
  void _bytesToChunk_A(List<int> data_A, int dataIndex) {
    assert((data_A.length - dataIndex) >= (_chunkSizeInWords_A * _BYTES_PER_WORD_A));
    for (var wordIndex = 0; wordIndex < _chunkSizeInWords_A; wordIndex++) {
      var w3 = _bigEndianWords_A ? data_A[dataIndex] : data_A[dataIndex + 3];
      var w2 = _bigEndianWords_A ? data_A[dataIndex + 1] : data_A[dataIndex + 2];
      var w1 = _bigEndianWords_A ? data_A[dataIndex + 2] : data_A[dataIndex + 1];
      var w0 = _bigEndianWords_A ? data_A[dataIndex + 3] : data_A[dataIndex];
      dataIndex += 4;
      var word = (w3 & 0xff) << 24;
      word |= (w2 & _MASK_8_B) << 16;
      word |= (w1 & _MASK_8_B) << 8;
      word |= (w0 & _MASK_8_B);
      _currentChunk_A[wordIndex] = word;
    }
  }
  List<int> _wordToBytes_A(int word) {
    List bytes_A = new List<int>(_BYTES_PER_WORD_A);
    bytes_A[0] = (word >> (_bigEndianWords_A ? 24 : 0)) & _MASK_8_B;
    bytes_A[1] = (word >> (_bigEndianWords_A ? 16 : 8)) & _MASK_8_B;
    bytes_A[2] = (word >> (_bigEndianWords_A ? 8 : 16)) & _MASK_8_B;
    bytes_A[3] = (word >> (_bigEndianWords_A ? 0 : 24)) & _MASK_8_B;
    return bytes_A;
  }
  void _iterate_A() {
    var len = _pendingData_A.length;
    var chunkSizeInBytes = _chunkSizeInWords_A * _BYTES_PER_WORD_A;
    if (len >= chunkSizeInBytes) {
      var index_A = 0;
      for (; (len - index_A) >= chunkSizeInBytes; index_A += chunkSizeInBytes) {
        _bytesToChunk_A(_pendingData_A, index_A);
        _updateHash_A(_currentChunk_A);
      }
      _pendingData_A = _pendingData_A.sublist(index_A, len);
    }
  }
  void _finalizeData_A() {
    _pendingData_A.add(0x80);
    var contentsLength = _lengthInBytes_A + 9;
    var chunkSizeInBytes = _chunkSizeInWords_A * _BYTES_PER_WORD_A;
    var finalizedLength = _roundUp_A(contentsLength, chunkSizeInBytes);
    var zeroPadding = finalizedLength - contentsLength;
    for (var i = 0; i < zeroPadding; i++) {
      _pendingData_A.add(0);
    }
    var lengthInBits = _lengthInBytes_A * _BITS_PER_BYTE_A;
    assert(lengthInBits < pow(2, 32));
    if (_bigEndianWords_A) {
      _pendingData_A.addAll(_wordToBytes_A(0));
      _pendingData_A.addAll(_wordToBytes_A(lengthInBits & _MASK_32_B));
    } else {
      _pendingData_A.addAll(_wordToBytes_A(lengthInBits & _MASK_32_B));
      _pendingData_A.addAll(_wordToBytes_A(0));
    }
  }
}
class SHA1 extends _HashBase_A {
  final Uint32List _w_A;
  SHA1() : _w_A = new Uint32List(80), super(16, 5, true) {
    _h_B[0] = 0x67452301;
    _h_B[1] = 0xEFCDAB89;
    _h_B[2] = 0x98BADCFE;
    _h_B[3] = 0x10325476;
    _h_B[4] = 0xC3D2E1F0;
  }
  void _updateHash_A(Uint32List m) {
    assert(m.length == 16);
    var a = _h_B[0];
    var b = _h_B[1];
    var c = _h_B[2];
    var d = _h_B[3];
    var e = _h_B[4];
    for (var i = 0; i < 80; i++) {
      if (i < 16) {
        _w_A[i] = m[i];
      } else {
        var n = _w_A[i - 3] ^ _w_A[i - 8] ^ _w_A[i - 14] ^ _w_A[i - 16];
        _w_A[i] = _rotl32_A(n, 1);
      }
      var t = _add32_A(_add32_A(_rotl32_A(a, 5), e), _w_A[i]);
      if (i < 20) {
        t = _add32_A(_add32_A(t, (b & c) | (~b & d)), 0x5A827999);
      } else if (i < 40) {
        t = _add32_A(_add32_A(t, (b ^ c ^ d)), 0x6ED9EBA1);
      } else if (i < 60) {
        t = _add32_A(_add32_A(t, (b & c) | (b & d) | (c & d)), 0x8F1BBCDC);
      } else {
        t = _add32_A(_add32_A(t, b ^ c ^ d), 0xCA62C1D6);
      }
      e = d;
      d = c;
      c = _rotl32_A(b, 30);
      b = a;
      a = t & _MASK_32_B;
    }
    _h_B[0] = _add32_A(a, _h_B[0]);
    _h_B[1] = _add32_A(b, _h_B[1]);
    _h_B[2] = _add32_A(c, _h_B[2]);
    _h_B[3] = _add32_A(d, _h_B[3]);
    _h_B[4] = _add32_A(e, _h_B[4]);
  }
}
class BrokerDiscoveryClient {
  RawDatagramSocket _socket_A;
  BrokerDiscoveryClient();
  Future init([bool broadcast_A = false]) async {
    _socket_A = await RawDatagramSocket.bind("0.0.0.0", broadcast_A ? 1900 : 0);
    _socket_A.multicastHops = 10;
    _socket_A.broadcastEnabled = true;
    _socket_A.listen((RawSocketEvent event) {
      if (event == RawSocketEvent.READ) {
        var packet = _socket_A.receive();
        _socket_A.writeEventsEnabled = true;
        if (packet == null) {
          return;
        }
        var data_A = UTF8.decode(packet.data);
        _onMessage(packet, data_A);
      } else if (event == RawSocketEvent.CLOSED) {
        if (!_brokerController.isClosed) {
          _brokerController.close();
        }
      }
    });
    _socket_A.writeEventsEnabled = true;
    var interfaces = await NetworkInterface.list();
    try {
      for (var interface in interfaces) {
        try {
          _socket_A.joinMulticast(new InternetAddress("239.255.255.230"), interface: interface);
        } catch (e) {
          _socket_A.joinMulticast(new InternetAddress("239.255.255.230"), interface: interface);
        }
      }
    } catch (e) {
      _socket_A.joinMulticast(new InternetAddress("239.255.255.230"));
    }
  }
  Stream<String> discover({Duration timeout: const Duration(seconds: 5)}) {
    _send("DISCOVER", "239.255.255.230", 1900);
    Stream<String> stream_A = _brokerController.stream;
    new Future.delayed(timeout, () {
      close();
    });
    return stream_A;
  }
  void _send(String content, String address_A, int port_A) {
    _socket_A.send(UTF8.encode(content), new InternetAddress(address_A), port_A);
  }
  void _onMessage(Datagram packet, String msg_A) {
    var parts = msg_A.split(" ");
    var type_A = parts[0];
    var argument = parts.skip(1).join(" ");
    if (type_A == "BROKER") {
      _brokerController.add(argument);
    } else if (type_A == "DISCOVER") {
      _discoverController.add(new BrokerDiscoverRequest(this, packet));
    }
  }
  StreamController<BrokerDiscoverRequest> _discoverController = new StreamController.broadcast();
  StreamController<String> _brokerController = new StreamController.broadcast();
  void close() {
    _socket_A.close();
  }
}
class BrokerDiscoverRequest {
  final BrokerDiscoveryClient client;
  final Datagram packet;
  BrokerDiscoverRequest(this.client, this.packet);
}
typedef void OptionResultsHandler(ArgResults _0);
typedef dynamic _TwoArgumentProfileFunction(String _0, SimpleNodeProvider _1);
class LinkProvider {
  HttpClientLink link_A;
  NodeProvider provider;
  PrivateKey_A privateKey;
  String brokerUrl;
  File _nodesFile;
  String prefix;
  List<String> args;
  bool isRequester = false;
  String command = "link";
  bool isResponder = true;
  Map<String, dynamic> defaultNodes;
  Map<String, Function> profiles;
  bool enableHttp = true;
  bool encodePrettyJson = false;
  bool strictOptions = false;
  bool exitOnFailure = true;
  bool loadNodesJson = true;
  String defaultLogLevel = "INFO";
  String logTag;
  bool savePrivateKey = false;
  Requester overrideRequester;
  Responder overrideResponder;
  Map linkData;
  String home;
  String token;
  LinkProvider(this.args, this.prefix, {this.isRequester: false, this.command: "link", this.isResponder: true, this.defaultNodes, Map<String, dynamic> nodes, this.profiles, this.provider, this.enableHttp: true, this.encodePrettyJson: false, bool autoInitialize: true, this.strictOptions: false, this.exitOnFailure: true, this.loadNodesJson: true, this.defaultLogLevel: "INFO", this.savePrivateKey: true, this.overrideRequester, this.overrideResponder, NodeProvider nodeProvider, this.linkData}) {
    exitOnFailure = Zone.current["dslink.runtime.config"] is! Map;
    if (nodeProvider != null) {
      provider = nodeProvider;
    }
    if (nodes != null) {
      defaultNodes = nodes;
    }
    if (autoInitialize) {
      init();
    }
  }
  String _basePath = Directory.current.path;
  String _watchFile;
  String _logFile;
  bool _configured = false;
  String _logLevelToName(Level level_A) {
    return level_A.name.toLowerCase();
  }
  bool configure({ArgParser argp, OptionResultsHandler optionsHandler}) {
    _configured = true;
    if (link_A != null) {
      link_A.close();
      link_A = null;
    }
    if (argp == null) {
      argp = new ArgParser(allowTrailingOptions: !strictOptions);
    }
    argp.addOption("broker", abbr: "b", help: "Broker URL", defaultsTo: "http://127.0.0.1:8080/conn");
    argp.addOption("name", abbr: "n", help: "Link Name");
    argp.addOption("home", help: "Home");
    argp.addOption("token", help: "Token");
    argp.addOption("base-path", help: "Base Path for DSLink");
    argp.addOption("watch-file", help: "Watch File for DSLink", hide: true);
    argp.addOption("log-file", help: "Log File for DSLink");
    List<String> logLevelNames = Level.LEVELS.map(_logLevelToName).toList();
    logLevelNames.addAll(["auto", "debug"]);
    argp.addOption("log", abbr: "l", allowed: logLevelNames, help: "Log Level", defaultsTo: "AUTO");
    argp.addFlag("help", abbr: "h", help: "Displays this Help Message", negatable: false);
    argp.addFlag("discover", abbr: "d", help: "Automatically Discover a Broker", negatable: false);
    ArgResults opts = argp.parse_D(args);
    if (opts["log"] == "auto") {
      if (DEBUG_MODE) {
        updateLogLevel("all");
      } else {
        updateLogLevel(defaultLogLevel);
      }
    } else {
      updateLogLevel(opts["log"]);
    }
    if (opts["base-path"] != null) {
      _basePath = opts["base-path"];
      if (_basePath.endsWith("/")) {
        _basePath = _basePath.substring(0, _basePath.length - 1);
      }
    }
    if (opts["watch-file"] != null) {
      _watchFile = opts["watch-file"];
    }
    _logFile = opts["log-file"];
    if (_logFile != null) {
      var file_A = new File(_logFile);
      if (!file_A.existsSync()) {
        file_A.createSync(recursive: true);
      }
      logger.clearListeners();
      IOSink out = _logFileOut = file_A.openWrite(mode: FileMode.APPEND);
      logger.onRecord.listen((record) {
        out.writeln("[${new DateTime.now()}][${record.level.name}] ${record.message}");
        if (record.error != null) {
          out.writeln(record.error);
        }
        if (record.stackTrace != null) {
          out.writeln(record.stackTrace);
        }
        out.flush();
      });
    }
    if (_watchFile != null) {
      var file_A = new File(_watchFile);
      StreamSubscription sub;
      sub = file_A.watch(events: FileSystemEvent.DELETE).listen((__I) {
        close();
        sub.cancel();
        if (_logFileOut != null) {
          try {
            _logFileOut.close();
          } catch (e) {}
        }
      });
    }
    if (const bool.fromEnvironment("dslink.debugger.console", defaultValue: false)) {
      readStdinLines().listen((String cmd) {
        if (cmd == "list-stored-nodes") {
          if (provider is SimpleNodeProvider) {
            SimpleNodeProvider prov = provider;
            print(prov.nodes.keys.join("\n"));
          } else {
            print("Not a SimpleNodeProvider.");
          }
        } else if (cmd == "list-stub-nodes") {
          if (provider is SimpleNodeProvider) {
            SimpleNodeProvider prov = provider;
            for (var node in prov.nodes.values) {
              Path p = new Path(node.path);
              if (prov.nodes[p.parentPath] == null) {
                print(node.path);
              } else if (!prov.nodes[p.parentPath].children.containsKey(p.name)) {
                print(node.path);
              }
            }
          } else {
            print("Not a SimpleNodeProvider.");
          }
        }
      });
    }
    {
      var runtimeConfig = Zone.current["dslink.runtime.config"];
      if (runtimeConfig != null) {
        var closeHandler = () {
          close();
          if (_logFileOut != null) {
            try {
              _logFileOut.close();
            } catch (e) {}
          }
        };
        runtimeConfig["closeHandler"] = closeHandler;
      }
    }
    String helpStr = "usage: ${command} [--broker URL] [--log LEVEL] [--name NAME] [--discover]";
    if (opts["help"]) {
      print(helpStr);
      print(argp.usage);
      if (exitOnFailure) {
        exit(1);
      } else {
        return false;
      }
    }
    brokerUrl = opts["broker"];
    if (brokerUrl == null && !opts["discover"]) {
      print("No Broker URL Specified. One of [--broker, --discover] is required.");
      print(helpStr);
      print(argp.usage);
      if (exitOnFailure) {
        exit(1);
      } else {
        return false;
      }
    }
    String name_A = opts["name"];
    home = opts["home"];
    token = opts["token"];
    if (name_A != null) {
      if (name_A.endsWith("-")) {
        prefix = name_A;
      } else {
        prefix = "${name_A}-";
      }
    }
    File dslinkFile = new File("${_basePath}/dslink.json");
    if (dslinkFile.existsSync()) {
      var e;
      try {
        String configStr = dslinkFile.readAsStringSync();
        dslinkJson = DsJson.decode_A(configStr);
      } catch (err) {
        e = err;
      }
      if (dslinkJson == null) {
        logger.severe("Invalid dslink.json", e);
        if (exitOnFailure) {
          exit(1);
        } else {
          return false;
        }
      }
    } else {
      dslinkJson = {};
    }
    if (brokerUrl != null) {
      if (!brokerUrl.startsWith("http")) {
        brokerUrl = "http://${brokerUrl}";
      }
    }
    File keyFile = getConfig_A("key") == null ? new File("${_basePath}/.dslink.key") : new File.fromUri(Uri.parse(getConfig_A("key")));
    String key_A;
    try {
      key_A = keyFile.readAsStringSync();
      privateKey = new PrivateKey_A.loadFromString(key_A);
    } catch (err) {}
    if (key_A == null || key_A.length != 131) {
      if (DSRandom.instance.needsEntropy) {
        String macs;
        if (Platform.isWindows) {
          macs = Process.runSync("getmac", []).stdout.toString();
        } else {
          try {
            macs = Process.runSync("arp", ["-an"]).stdout.toString();
          } catch (e) {
            try {
              var envs = "";
              for (var i in Platform.environment.keys) {
                envs += "${i}=${Platform.environment[i]}\n";
              }
              macs = envs;
            } catch (e) {}
          }
        }
        DSRandom.instance.addEntropy(macs);
      }
      privateKey = new PrivateKey_A.generateSync();
      key_A = privateKey.saveToString();
      if (savePrivateKey) {
        keyFile.writeAsStringSync(key_A);
      }
    }
    if (opts["discover"]) {
      _discoverBroker = true;
    }
    if (optionsHandler != null) {
      optionsHandler(opts);
    }
    return true;
  }
  Future<String> chooseBroker(Stream<String> brokers) async {
    return await brokers.first;
  }
  bool _discoverBroker = false;
  String get remotePath => link_A.remotePath;
  IOSink _logFileOut;
  bool _reconnecting = false;
  void init() {
    if (!_configured) {
      if (!configure()) {
        return;
      }
    }
    if (_initialized) {
      return;
    }
    _initialized = true;
    if (profiles != null) {
      for (var key_A in profiles.keys.toList()) {
        var value_A = profiles[key_A];
        if (value_A is _TwoArgumentProfileFunction) {
          profiles[key_A] = (String path_A) {
            return value_A(path_A, provider);
          };
        }
      }
    }
    if (provider == null) {
      provider = new SimpleNodeProvider(null, profiles);
      (provider as SimpleNodeProvider).setPersistFunction(saveAsync);
    }
    loadNodesFile();
    void doRun() {
      link_A = createHttpLink();
      _ready = true;
      if (_connectOnReady) {
        connect();
      }
    }
    if (_discoverBroker) {
      var discovery = new BrokerDiscoveryClient();
      new Future(() async {
        await discovery.init();
        try {
          var broker = await chooseBroker(discovery.discover());
          logger.info("Discovered Broker at ${broker}");
          brokerUrl = broker;
          doRun();
        } catch (e, stack) {
          logger.severe("Failed to discover a broker.", e, stack);
          exit(1);
        }
      });
    } else {
      doRun();
    }
  }
  HttpClientLink createHttpLink() {
    var client = new HttpClientLink(brokerUrl, prefix, privateKey, isRequester: isRequester, isResponder: isResponder, nodeProvider: provider, overrideRequester: overrideRequester, overrideResponder: overrideResponder, home: home, token: token, linkData: linkData);
    client.logName = logTag;
    return client;
  }
  void loadNodesFile() {
    if (provider is SerializableNodeProvider && !_reconnecting) {
      _nodesFile = getConfig_A("nodes") == null ? new File("${_basePath}/nodes.json") : new File.fromUri(Uri.parse(getConfig_A("nodes")));
      Map<String, dynamic> loadedNodesData;
      if (loadNodesJson) {
        _nodesFile = getConfig_A("nodes") == null ? new File("${_basePath}/nodes.json") : new File.fromUri(Uri.parse(getConfig_A("nodes")));
        try {
          String nodesStr = _nodesFile.readAsStringSync();
          var json = DsJson.decode_A(nodesStr);
          if (json is Map<String, dynamic>) {
            loadedNodesData = json;
          }
        } catch (err) {}
      }
      if (loadedNodesData != null) {
        onNodesDeserialized(loadedNodesData);
        (provider as SerializableNodeProvider).init(loadedNodesData);
      } else if (defaultNodes != null) {
        (provider as SerializableNodeProvider).init(defaultNodes);
      }
    }
  }
  Map dslinkJson;
  Object getConfig_A(String key_A) {
    if (dslinkJson != null && dslinkJson["configs"] is Map && dslinkJson["configs"][key_A] is Map && dslinkJson["configs"][key_A].containsKey("value")) {
      return dslinkJson["configs"][key_A]["value"];
    }
    return null;
  }
  void onNodesDeserialized(Map json) {}
  bool _initialized = false;
  bool _ready = false;
  bool _connectOnReady = false;
  Future connect() {
    if (_connectedCompleter == null) {
      _connectedCompleter = new Completer();
    }
    if (!_configured || !_initialized) {
      init();
    }
    if (_ready) {
      link_A.onConnected.then(_connectedCompleter.complete);
      if (link_A != null) link_A.connect();
    } else {
      _connectOnReady = true;
    }
    return _connectedCompleter.future;
  }
  Completer _connectedCompleter;
  Requester get requester => link_A.requester;
  Future<Requester> get onRequesterReady => link_A.onRequesterReady;
  void close() {
    _connectedCompleter = null;
    if (link_A != null) {
      link_A.close();
      link_A = null;
      _initialized = false;
      _reconnecting = true;
    }
  }
  void save() {
    if (_nodesFile != null && provider != null) {
      if (provider is! SerializableNodeProvider) {
        return;
      }
      _nodesFile.writeAsStringSync(DsJson.encode_A((provider as SerializableNodeProvider).save(), pretty: encodePrettyJson));
    }
  }
  Future saveAsync() async {
    if (_nodesFile != null && provider != null) {
      if (provider is! SerializableNodeProvider) {
        return;
      }
      var count_A = 0;
      while (_isAsyncSave) {
        await new Future.delayed(const Duration(milliseconds: 5));
        count_A++;
        if (count_A == 100) {
          break;
        }
      }
      var encoded = DsJson.encode_A((provider as SerializableNodeProvider).save(), pretty: encodePrettyJson);
      _isAsyncSave = true;
      await _nodesFile.writeAsString(encoded);
      _isAsyncSave = false;
    }
  }
  bool _isAsyncSave = false;
  LocalNode getNode(String path_A) {
    return provider.getNode(path_A);
  }
  LocalNode addNode(String path_A, Map m) {
    if (provider is! MutableNodeProvider) {
      throw new Exception("Unable to Modify Node Provider: It is not mutable.");
    }
    return (provider as MutableNodeProvider).addNode(path_A, m);
  }
  void removeNode(String path_A) {
    if (provider is! MutableNodeProvider) {
      throw new Exception("Unable to Modify Node Provider: It is not mutable.");
    }
    (provider as MutableNodeProvider).removeNode(path_A);
  }
  void updateValue(String path_A, dynamic value_A) {
    if (provider is! MutableNodeProvider) {
      throw new Exception("Unable to Modify Node Provider: It is not mutable.");
    }
    (provider as MutableNodeProvider).updateValue(path_A, value_A);
  }
  LocalNode operator[](String path_A) => provider[path_A];
  LocalNode operator~() => this["/"];
}
class HttpClientLink extends ClientLink {
  Completer<Requester> _onRequesterReadyCompleter = new Completer<Requester>();
  Completer _onConnectedCompleter = new Completer();
  Future<Requester> get onRequesterReady => _onRequesterReadyCompleter.future;
  Future get onConnected => _onConnectedCompleter.future;
  String remotePath;
  final String dsId;
  final String home;
  final String token;
  final PrivateKey_A privateKey;
  String tokenHash;
  Requester requester;
  Responder responder;
  bool useStandardWebSocket = true;
  String logName;
  ECDH _nonce;
  ECDH get nonce => _nonce;
  WebSocketConnection _wsConnection;
  static const Map<String, int> saltNameMap = const{'salt': 0, 'saltS': 1, 'saltL': 2};
  final List<String> salts = new List<String>(3);
  updateSalt(String salt, [int saltId = 0]) {
    salts[saltId] = salt;
  }
  String _wsUpdateUri;
  String _conn;
  bool enableAck = false;
  Map linkData;
  List formats = ['msgpack', 'json'];
  String format_A = 'json';
  HttpClientLink(this._conn, String dsIdPrefix, PrivateKey_A privateKey_A, {NodeProvider nodeProvider, bool isRequester: true, bool isResponder: true, Requester overrideRequester, Responder overrideResponder, this.home, this.token, this.linkData, List formats}) : privateKey = privateKey_A, dsId = '${Path.escapeName(dsIdPrefix)}${privateKey_A.publicKey.qHash64}' {
    if (isRequester) {
      if (overrideRequester != null) {
        requester = overrideRequester;
      } else {
        requester = new Requester();
      }
    }
    if (formats == null && const String.fromEnvironment("dsa.codec.formats") != null) {
      var formatString = const String.fromEnvironment("dsa.codec.formats");
      formats = formatString.split(",");
    }
    if (formats != null) {
      this.formats = formats;
    }
    if (isResponder) {
      if (overrideResponder != null) {
        responder = overrideResponder;
      } else if (nodeProvider != null) {
        responder = new Responder(nodeProvider);
      }
    }
    if (token != null && token.length > 16) {
      String tokenId = token.substring(0, 16);
      String hashStr = CryptoProvider.sha256(toUTF8('${dsId}${token}'));
      tokenHash = '&token=${tokenId}${hashStr}';
    }
  }
  int _connDelay = 0;
  connect() async {
    if (_closed_A) {
      return;
    }
    lockCryptoProvider();
    DsTimer.timerCancel(initWebsocket);
    HttpClient client = new HttpClient();
    client.badCertificateCallback = (X509Certificate cert, String host_A, int port_A) {
      return true;
    };
    String connUrl = '${_conn}?dsId=${Uri.encodeComponent(dsId)}';
    if (home != null) {
      connUrl = '${connUrl}&home=${home}';
    }
    if (tokenHash != null) {
      connUrl = '${connUrl}${tokenHash}';
    }
    Uri connUri = Uri.parse(connUrl);
    logger.info(formatLogMessage("Connecting to ${_conn}"));
    try {
      HttpClientRequest request_B = await client.postUrl(connUri);
      Map requestJson = {'publicKey': privateKey.publicKey.qBase64, 'isRequester': requester != null, 'isResponder': responder != null, 'formats': formats, 'version': DSA_VERSION, 'enableWebSocketCompression': true};
      if (linkData != null) {
        requestJson['linkData'] = linkData;
      }
      logger.finest(formatLogMessage("Handshake Request: ${requestJson}"));
      logger.fine(formatLogMessage("ID: ${dsId}"));
      request_B.add(toUTF8(DsJson.encode_A(requestJson)));
      HttpClientResponse response_B = await request_B.close();
      List<int> merged = await response_B.fold(<int>[], foldList);
      String rslt = const Utf8Decoder().convert(merged);
      Map serverConfig = DsJson.decode_A(rslt);
      logger.finest(formatLogMessage("Handshake Response: ${serverConfig}"));
      saltNameMap.forEach((name_A, idx) {
        salts[idx] = serverConfig[name_A];
      });
      String tempKey = serverConfig['tempKey'];
      if (tempKey == null) {
        _nonce = const DummyECDH();
      } else {
        _nonce = await privateKey.getSecret(tempKey);
      }
      enableAck = serverConfig.containsKey('version');
      remotePath = serverConfig['path'];
      if (serverConfig['wsUri'] is String) {
        _wsUpdateUri = '${connUri.resolve(serverConfig['wsUri'])}?dsId=${Uri.encodeComponent(dsId)}'.replaceFirst('http', 'ws');
        if (home != null) {
          _wsUpdateUri = '${_wsUpdateUri}&home=${home}';
        }
      }
      if (serverConfig['format'] is String) {
        format_A = serverConfig['format'];
      }
      initWebsocket(false);
      _connDelay = 0;
      _wsDelay = 0;
    } catch (err) {
      DsTimer.timerOnceAfter(connect, (_connDelay == 0 ? 20 : _connDelay * 500));
      if (_connDelay < 30) _connDelay++;
    }
  }
  int _wsDelay = 0;
  initWebsocket([bool reconnect = true]) async {
    if (_closed_A) return;
    try {
      String wsUrl = '${_wsUpdateUri}&auth=${_nonce.hashSalt(salts[0])}&format=${format_A}';
      if (tokenHash != null) {
        wsUrl = '${wsUrl}${tokenHash}';
      }
      var socket_A = await HttpHelper.connectToWebSocket(wsUrl, useStandardWebSocket: useStandardWebSocket);
      _wsConnection = new WebSocketConnection(socket_A, clientLink: this, enableTimeout: true, enableAck: enableAck, useCodec: DsCodec.getCodec(format_A));
      logger.info(formatLogMessage("Connected"));
      if (!_onConnectedCompleter.isCompleted) {
        _onConnectedCompleter.complete();
      }
      if (responder != null) {
        responder.connection = _wsConnection.responderChannel;
      }
      if (requester != null) {
        _wsConnection.onRequesterReady.then((channel) {
          requester.connection = channel;
          if (!_onRequesterReadyCompleter.isCompleted) {
            _onRequesterReadyCompleter.complete(requester);
          }
        });
      }
      _wsConnection.onDisconnected.then((connection_A) {
        initWebsocket();
      });
    } catch (error_A, stack) {
      logger.fine(formatLogMessage("Error while initializing WebSocket"), error_A, stack);
      if (error_A is WebSocketException && (error_A.message.contains('not upgraded to websocket') || error_A.message.contains('(401)'))) {
        DsTimer.timerOnceAfter(connect, 20);
      } else if (reconnect) {
        DsTimer.timerOnceAfter(initWebsocket, _wsDelay == 0 ? 20 : _wsDelay * 500);
        if (_wsDelay < 30) _wsDelay++;
      }
    }
  }
  bool _closed_A = false;
  void close() {
    if (_closed_A) return;
    _onConnectedCompleter = new Completer();
    _closed_A = true;
    if (_wsConnection != null) {
      _wsConnection.close();
      _wsConnection = null;
    }
  }
}
abstract class Connection {
  ConnectionChannel get responderChannel;
  Future<ConnectionChannel> get onRequesterReady;
  Future<bool> get onDisconnected;
  void requireSend();
  void addConnCommand(String key_A, Object value_A);
  void close();
  DsCodec codec = DsCodec.defaultCodec;
  ListQueue<ConnectionAckGroup> pendingAcks = new ListQueue<ConnectionAckGroup>();
  void ack(int ackId) {
    ConnectionAckGroup findAckGroup;
    for (ConnectionAckGroup ackGroup in pendingAcks) {
      if (ackGroup.ackId == ackId) {
        findAckGroup = ackGroup;
        break;
      } else if (ackGroup.ackId < ackId) {
        findAckGroup = ackGroup;
      }
    }
    if (findAckGroup != null) {
      int ts_A = (new DateTime.now()).millisecondsSinceEpoch;
      do {
        ConnectionAckGroup ackGroup = pendingAcks.removeFirst();
        ackGroup.ackAll(ackId, ts_A);
        if (ackGroup == findAckGroup) {
          break;
        }
      } while (findAckGroup != null);
    }
  }
}
class ProcessorResult {
  List<Map> messages;
  List<ConnectionProcessor> processors;
  ProcessorResult(this.messages, this.processors);
}
class ConnectionAckGroup {
  int ackId;
  int startTime;
  int expectedAckTime;
  List<ConnectionProcessor> processors;
  ConnectionAckGroup(this.ackId, this.startTime, this.processors);
  void ackAll(int ackid, int time) {
    for (ConnectionProcessor processor in processors) {
      processor.ackReceived(ackId, startTime, time);
    }
  }
}
abstract class ConnectionChannel {}
abstract class BaseLink {
  Requester get requester;
  Responder get responder;
  ECDH get nonce;
  Future<Requester> get onRequesterReady;
  void close();
}
abstract class ClientLink extends BaseLink {
  PrivateKey_A get privateKey;
  updateSalt(String salt, [int saltId = 0]);
  String get logName => null;
  String formatLogMessage(String msg_A) {
    if (logName != null) {
      return "[${logName}] ${msg_A}";
    }
    return msg_A;
  }
  connect();
}
class StreamStatus {
  static const String initialize = "initialize";
  static const String open_A = "open";
  static const String closed_A = "closed";
}
class ErrorPhase {
  static const String request_A = "request";
  static const String response_A = "response";
}
class DSError {
  String type;
  String detail;
  String msg;
  String path;
  String phase;
  DSError(this.type, {this.msg, this.detail, this.path, this.phase: ErrorPhase.response_A});
  DSError.fromMap(Map m) {
    if (m["type"] is String) {
      type = m["type"];
    }
    if (m["msg"] is String) {
      msg = m["msg"];
    }
    if (m["path"] is String) {
      path = m["path"];
    }
    if (m["phase"] is String) {
      phase = m["phase"];
    }
    if (m["detail"] is String) {
      detail = m["detail"];
    }
  }
  Map serialize() {
    Map rslt = {};
    if (msg != null) {
      rslt["msg"] = msg;
    }
    if (type != null) {
      rslt["type"] = type;
    }
    if (path != null) {
      rslt["path"] = path;
    }
    if (phase == ErrorPhase.request_A) {
      rslt["phase"] = ErrorPhase.request_A;
    }
    if (detail != null) {
      rslt["detail"] = detail;
    }
    return rslt;
  }
  static final DSError PERMISSION_DENIED = new DSError("permissionDenied");
  static final DSError INVALID_METHOD = new DSError("invalidMethod");
  static final DSError INVALID_PATH = new DSError("invalidPath");
  static final DSError INVALID_PATHS = new DSError("invalidPaths");
  static final DSError INVALID_VALUE = new DSError("invalidValue");
  static final DSError DISCONNECTED = new DSError("disconnected", phase: ErrorPhase.request_A);
}
class PassiveChannel implements ConnectionChannel {
  final StreamController<List> onReceiveController = new StreamController<List>();
  Stream<List> get onReceive => onReceiveController.stream;
  List<Function> _processors = [];
  final Connection conn;
  PassiveChannel(this.conn, [this.connected = false]) {}
  ConnectionHandler handler;
  void sendWhenReady(ConnectionHandler handler_A) {
    this.handler = handler_A;
    conn.requireSend();
  }
  ProcessorResult getSendingData(int currentTime, int waitingAckId) {
    if (handler != null) {
      ProcessorResult rslt = handler.getSendingData(currentTime, waitingAckId);
      return rslt;
    }
    return null;
  }
  bool _isReady = false;
  bool connected = true;
  final Completer<ConnectionChannel> onDisconnectController = new Completer<ConnectionChannel>();
  Future<ConnectionChannel> get onDisconnected => onDisconnectController.future;
  final Completer<ConnectionChannel> onConnectController = new Completer<ConnectionChannel>();
  Future<ConnectionChannel> get onConnected => onConnectController.future;
}
abstract class ConnectionProcessor {
  static const int ACK_WAIT_COUNT = 64;
  static const int DEFAULT_CACHE_SIZE = 1024;
}
abstract class ConnectionHandler {
  ConnectionChannel _conn_A;
  StreamSubscription _connListener;
  ConnectionChannel get connection => _conn_A;
  set connection(ConnectionChannel conn) {
    if (_connListener != null) {
      _connListener.cancel();
      _connListener = null;
      _onDisconnected(_conn_A);
    }
    _conn_A = conn;
    _connListener = _conn_A.onReceive.listen(onData);
    _conn_A.onDisconnected.then(_onDisconnected);
    if (_conn_A.connected) {
      onReconnected();
    } else {
      _conn_A.onConnected.then((conn) => onReconnected());
    }
  }
  void _onDisconnected(ConnectionChannel conn) {
    if (_conn_A == conn) {
      if (_connListener != null) {
        _connListener.cancel();
        _connListener = null;
      }
      onDisconnected();
      _conn_A = null;
    }
  }
  void onDisconnected();
  void onReconnected() {
    if (_pendingSend) {
      _conn_A.sendWhenReady(this);
    }
  }
  void onData(List m);
  List<Map> _toSendList = <Map>[];
  void addToSendList(Map m) {
    _toSendList.add(m);
    if (!_pendingSend) {
      if (_conn_A != null) {
        _conn_A.sendWhenReady(this);
      }
      _pendingSend = true;
    }
  }
  List<ConnectionProcessor> _processors = [];
  void addProcessor(ConnectionProcessor processor) {
    _processors.add(processor);
    if (!_pendingSend) {
      if (_conn_A != null) {
        _conn_A.sendWhenReady(this);
      }
      _pendingSend = true;
    }
  }
  bool _pendingSend = false;
  ProcessorResult getSendingData(int currentTime, int waitingAckId) {
    _pendingSend = false;
    List<ConnectionProcessor> processors = _processors;
    _processors = [];
    for (ConnectionProcessor proc in processors) {
      proc.startSendingData(currentTime, waitingAckId);
    }
    List<Map> rslt = _toSendList;
    _toSendList = [];
    return new ProcessorResult(rslt, processors);
  }
  void clearProcessors() {
    _processors.length = 0;
    _pendingSend = false;
  }
}
class Node {
  Node profile;
  Map<String, Object> attributes = {};
  Node();
  Object getAttribute(String name_A) {
    if (attributes.containsKey(name_A)) {
      return attributes[name_A];
    }
    if (profile != null && profile.attributes.containsKey(name_A)) {
      return profile.attributes[name_A];
    }
    return null;
  }
  Map<String, Object> configs = {r'$is': 'node'};
  Object getConfig_A(String name_A) {
    if (configs.containsKey(name_A)) {
      return configs[name_A];
    }
    if (profile != null && profile.configs.containsKey(name_A)) {
      return profile.configs[name_A];
    }
    return null;
  }
  Map<String, Node> children = {};
  void addChild(String name_A, Node node) {
    children[name_A] = node;
  }
  String removeChild(dynamic input_A) {
    if (input_A is String) {
      children.remove(getChild(input_A));
      return input_A;
    } else if (input_A is Node) {
      children.remove(input_A);
    } else {
      throw new Exception("Invalid Input");
    }
    return null;
  }
  Node getChild(String name_A) {
    if (children.containsKey(name_A)) {
      return children[name_A];
    }
    if (profile != null && profile.children.containsKey(name_A)) {
      return profile.children[name_A];
    }
    return null;
  }
  Object get(String name_A) {
    if (name_A.startsWith(r'$')) {
      return getConfig_A(name_A);
    }
    if (name_A.startsWith('@')) {
      return getAttribute(name_A);
    }
    return getChild(name_A);
  }
  Map<String, dynamic> getSimpleMap() {
    var rslt = <String, dynamic>{};
    if (configs.containsKey(r'$is')) {
      rslt[r'$is'] = configs[r'$is'];
    }
    if (configs.containsKey(r'$type')) {
      rslt[r'$type'] = configs[r'$type'];
    }
    if (configs.containsKey(r'$name')) {
      rslt[r'$name'] = configs[r'$name'];
    }
    if (configs.containsKey(r'$invokable')) {
      rslt[r'$invokable'] = configs[r'$invokable'];
    }
    if (configs.containsKey(r'$writable')) {
      rslt[r'$writable'] = configs[r'$writable'];
    }
    return rslt;
  }
}
class Path {
  static final RegExp invalidChar = new RegExp(r'[\\\?\*|"<>:]');
  static final RegExp invalidNameChar = new RegExp(r'[\/\\\?\*|"<>:]');
  static String escapeName(String str) {
    if (str.contains(invalidNameChar)) {
      return Uri.encodeComponent(str);
    }
    return str;
  }
  static Path getValidPath(Object path_A, [String basePath]) {
    if (path_A is String) {
      Path p = new Path(path_A);
      if (p.valid) {
        return p
            ..mergeBasePath(basePath);
      }
    }
    return null;
  }
  static Path getValidNodePath(Object path_A, [String basePath]) {
    if (path_A is String) {
      Path p = new Path(path_A);
      if (p.valid && p.isNode) {
        return p
            ..mergeBasePath(basePath);
      }
    }
    return null;
  }
  String path;
  String parentPath;
  Path get parent => new Path(parentPath);
  Path child(String name_A) => new Path((path.endsWith("/") ? path.substring(0, path.length - 1) : path) + "/" + (name_A.startsWith("/") ? name_A.substring(1) : name_A));
  String name;
  bool valid = true;
  Path(this.path) {
    _parse_A();
  }
  void _parse_A() {
    if (path == '' || path.contains(invalidChar) || path.contains('//')) {
      valid = false;
    }
    if (path == '/') {
      valid = true;
      name = '/';
      parentPath = '';
      return;
    }
    if (path.endsWith('/')) {
      path = path.substring(0, path.length - 1);
    }
    int pos = path.lastIndexOf('/');
    if (pos < 0) {
      name = path;
      parentPath = '';
    } else if (pos == 0) {
      parentPath = '/';
      name = path.substring(1);
    } else {
      parentPath = path.substring(0, pos);
      name = path.substring(pos + 1);
      if (parentPath.contains(r'/$') || parentPath.contains('/@')) {
        valid = false;
      }
    }
  }
  bool get isAbsolute {
    return name == '/' || parentPath.startsWith('/');
  }
  bool get isRoot {
    return name == '/';
  }
  bool get isConfig {
    return name.startsWith(r'$');
  }
  bool get isAttribute {
    return name.startsWith(r'@');
  }
  bool get isNode {
    return !name.startsWith(r'@') && !name.startsWith(r'$');
  }
  void mergeBasePath(String base_A, [bool force = false]) {
    if (base_A == null) {
      return;
    }
    if (!isAbsolute) {
      if (parentPath == '') {
        parentPath = base_A;
      } else {
        parentPath = '${base_A}/${parentPath}';
      }
      path = '${parentPath}/${name}';
    } else if (force) {
      if (name == '') {
        path = base_A;
        _parse_A();
      } else {
        parentPath = '${base_A}${parentPath}';
        path = '${parentPath}/${name}';
      }
    }
  }
}
class Permission {
  static const int NONE_B = 0;
  static const int LIST = 1;
  static const int READ_A = 2;
  static const int WRITE_A = 3;
  static const int CONFIG = 4;
  static const int NEVER = 5;
  static const List<String> names = const['none', 'list', 'read', 'write', 'config', 'never'];
  static const Map<String, int> nameParser = const{'none': NONE_B, 'list': LIST, 'read': READ_A, 'write': WRITE_A, 'config': CONFIG, 'never': NEVER};
  static int parse_A(Object obj, [int defaultVal = NEVER]) {
    if (obj is String && nameParser.containsKey(obj)) {
      return nameParser[obj];
    }
    return defaultVal;
  }
}
class TableColumn {
  String type;
  String name;
  Object defaultValue;
  TableColumn(this.name, this.type, [this.defaultValue]);
  Map<String, dynamic> getData() {
    var rslt = <String, dynamic>{"type": type, "name": name};
    if (defaultValue != null) {
      rslt["default"] = defaultValue;
    }
    return rslt;
  }
  static List<Map<String, dynamic>> serializeColumns(List list_A) {
    var rslts = <Map<String, dynamic>>[];
    for (Object m in list_A) {
      if (m is Map<String, dynamic>) {
        rslts.add(m);
      } else if (m is TableColumn) {
        rslts.add(m.getData());
      }
    }
    return rslts;
  }
  static List<TableColumn> parseColumns(List list_A) {
    List<TableColumn> rslt = <TableColumn>[];
    for (Object m in list_A) {
      if (m is Map && m["name"] is String) {
        String type_A = "string";
        if (m["type"] is String) {
          type_A = m["type"];
        }
        rslt.add(new TableColumn(m["name"], type_A, m["default"]));
      } else if (m is TableColumn) {
        rslt.add(m);
      } else {
        return null;
      }
    }
    return rslt;
  }
}
class Table {}
class TableColumns {}
class TableMetadata {}
typedef T_A ValueUpdateCallback<T_A>(ValueUpdate _0);
class ValueUpdate {
  static final String TIME_ZONE = () {
    int timeZoneOffset_A = (new DateTime.now()).timeZoneOffset.inMinutes;
    String s = "+";
    if (timeZoneOffset_A < 0) {
      timeZoneOffset_A = -timeZoneOffset_A;
      s = "-";
    }
    int hh = timeZoneOffset_A ~/ 60;
    int mm = timeZoneOffset_A % 60;
    return "${s}${hh < 10 ? '0' : ''}${hh}:${mm < 10 ? "0" : ''}${mm}";
  }();
  static String _lastTsStr;
  static int _lastTs = 0;
  static String getTs() {
    DateTime d = new DateTime.now();
    if (d.millisecondsSinceEpoch == _lastTs) {
      return _lastTsStr;
    }
    _lastTs = d.millisecondsSinceEpoch;
    _lastTsStr = "${d.toIso8601String()}${TIME_ZONE}";
    return _lastTsStr;
  }
  int waitingAck = -1;
  Object value;
  String ts;
  DateTime _timestamp;
  String status;
  int count;
  num sum;
  num min;
  num max;
  DateTime created;
  ValueUpdate(this.value, {this.ts, Map meta, this.status, this.count: 1, this.sum: double.NAN, this.min: double.NAN, this.max: double.NAN}) {
    if (ts == null) {
      ts = getTs();
    }
    created = new DateTime.now();
    if (meta != null) {
      if (meta["count"] is int) {
        count = meta["count"];
      } else if (value == null) {
        count = 0;
      }
      if (meta["status"] is String) {
        status = meta["status"];
      }
      if (meta["sum"] is num) {
        sum = meta["sum"];
      }
      if (meta["max"] is num) {
        max = meta["max"];
      }
      if (meta["min"] is num) {
        min = meta["min"];
      }
    }
    if (value is num && count == 1) {
      if (sum != sum) sum = value;
      if (max != max) max = value;
      if (min != min) min = value;
    }
  }
  ValueUpdate.merge(ValueUpdate oldUpdate, ValueUpdate newUpdate) {
    value = newUpdate.value;
    ts = newUpdate.ts;
    status = newUpdate.status;
    count = oldUpdate.count + newUpdate.count;
    sum = oldUpdate.sum;
    if (!newUpdate.sum.isNaN) {
      if (sum == sum) {
        sum = newUpdate.sum;
      } else {
        sum += newUpdate.sum;
      }
    }
    min = oldUpdate.min;
    if (min.isNaN || newUpdate.min < min) {
      min = newUpdate.min;
    }
    max = oldUpdate.min;
    if (max.isNaN || newUpdate.max > max) {
      max = newUpdate.max;
    }
    created = newUpdate.created;
  }
  Duration _latency;
  void mergeAdd(ValueUpdate newUpdate) {
    value = newUpdate.value;
    ts = newUpdate.ts;
    status = newUpdate.status;
    count += newUpdate.count;
    if (!newUpdate.sum.isNaN) {
      if (sum == sum) {
        sum += newUpdate.sum;
      } else {
        sum = newUpdate.sum;
      }
    }
    if (min != min || newUpdate.min < min) {
      min = newUpdate.min;
    }
    if (max != max || newUpdate.max > max) {
      max = newUpdate.max;
    }
  }
  Map toMap() {
    Map m = {"ts": ts, "value": value};
    if (count == 0) {
      m["count"] = 0;
    } else if (count > 1) {
      m["count"] = count;
      if (sum.isFinite) {
        m["sum"] = sum;
      }
      if (max.isFinite) {
        m["max"] = max;
      }
      if (min.isFinite) {
        m["min"] = min;
      }
    }
    return m;
  }
  Object storedData;
}
class WebSocketConnection extends Connection {
  PassiveChannel _responderChannel;
  ConnectionChannel get responderChannel => _responderChannel;
  PassiveChannel _requesterChannel;
  Completer<ConnectionChannel> onRequestReadyCompleter = new Completer<ConnectionChannel>();
  Future<ConnectionChannel> get onRequesterReady => onRequestReadyCompleter.future;
  Completer<bool> _onDisconnectedCompleter = new Completer<bool>();
  Future<bool> get onDisconnected => _onDisconnectedCompleter.future;
  final ClientLink clientLink;
  final WebSocket socket;
  bool _onDoneHandled = false;
  WebSocketConnection(this.socket, {this.clientLink, bool enableTimeout: false, bool enableAck: true, DsCodec useCodec}) {
    if (useCodec != null) {
      codec = useCodec;
    }
    _responderChannel = new PassiveChannel(this, true);
    _requesterChannel = new PassiveChannel(this, true);
    socket.listen(onData, onDone: _onDone_A);
    socket.add(codec.blankData);
    if (!enableAck) {
      nextMsgId = -1;
    }
    if (enableTimeout) {
      pingTimer = new Timer.periodic(const Duration(seconds: 20), onPingTimer);
    }
  }
  Timer pingTimer;
  bool _dataSent = false;
  int _dataReceiveCount = 0;
  static bool throughputEnabled = false;
  static int dataIn = 0;
  static int messageIn = 0;
  static int dataOut = 0;
  static int messageOut = 0;
  static int frameIn = 0;
  static int frameOut = 0;
  void onPingTimer(Timer t) {
    if (_dataReceiveCount >= 3) {
      this.close();
      return;
    }
    _dataReceiveCount++;
    if (_dataSent) {
      _dataSent = false;
      return;
    }
    this.addConnCommand(null, null);
  }
  void requireSend() {
    if (!_sending) {
      _sending = true;
      DsTimer.callLater(_send_A);
    }
  }
  Map _serverCommand;
  void addConnCommand(String key_A, Object value_A) {
    if (_serverCommand == null) {
      _serverCommand = {};
    }
    if (key_A != null) {
      _serverCommand[key_A] = value_A;
    }
    requireSend();
  }
  void onData(dynamic data_A) {
    frameIn++;
    if (_onDisconnectedCompleter.isCompleted) {
      return;
    }
    if (!onRequestReadyCompleter.isCompleted) {
      onRequestReadyCompleter.complete(_requesterChannel);
    }
    _dataReceiveCount = 0;
    Map m;
    if (data_A is List<int>) {
      try {
        m = codec.decodeBinaryFrame(data_A as List<int>);
        if (logger.isLoggable(Level.FINEST)) {
          logger.finest(formatLogMessage("receive: ${m}"));
        }
      } catch (err, stack) {
        logger.fine(formatLogMessage("Failed to decode binary data in WebSocket Connection"), err, stack);
        close();
        return;
      }
      if (throughputEnabled) {
        dataIn += data_A.length;
      }
      data_A = null;
      bool needAck = false;
      if (m["responses"] is List && (m["responses"] as List).length > 0) {
        needAck = true;
        _requesterChannel.onReceiveController.add(m["responses"]);
      }
      if (m["requests"] is List && (m["requests"] as List).length > 0) {
        needAck = true;
        _responderChannel.onReceiveController.add(m["requests"]);
      }
      if (m["ack"] is int) {
        ack(m["ack"]);
      }
      if (needAck) {
        Object msgId = m["msg"];
        if (msgId != null) {
          addConnCommand("ack", msgId);
        }
      }
    } else if (data_A is String) {
      try {
        m = codec.decodeStringFrame(data_A);
        if (logger.isLoggable(Level.FINEST)) {
          logger.finest(formatLogMessage("receive: ${m}"));
        }
      } catch (err, stack) {
        logger.severe(formatLogMessage("Failed to decode string data from WebSocket Connection"), err, stack);
        close();
        return;
      }
      if (throughputEnabled) {
        dataIn += data_A.length;
      }
      if (m["salt"] is String && clientLink != null) {
        clientLink.updateSalt(m["salt"]);
      }
      bool needAck = false;
      if (m["responses"] is List && (m["responses"] as List).length > 0) {
        needAck = true;
        _requesterChannel.onReceiveController.add(m["responses"]);
        if (throughputEnabled) {
          for (Map resp in m["responses"]) {
            if (resp["updates"] is List) {
              int len = resp["updates"].length;
              if (len > 0) {
                messageIn += len;
              } else {
                messageIn += 1;
              }
            } else {
              messageIn += 1;
            }
          }
        }
      }
      if (m["requests"] is List && (m["requests"] as List).length > 0) {
        needAck = true;
        _responderChannel.onReceiveController.add(m["requests"]);
        if (throughputEnabled) {
          messageIn += m["requests"].length;
        }
      }
      if (m["ack"] is int) {
        ack(m["ack"]);
      }
      if (needAck) {
        Object msgId = m["msg"];
        if (msgId != null) {
          addConnCommand("ack", msgId);
        }
      }
    }
  }
  int nextMsgId = 1;
  bool _sending = false;
  void _send_A() {
    _sending = false;
    bool needSend = false;
    Map m;
    if (_serverCommand != null) {
      m = _serverCommand;
      _serverCommand = null;
      needSend = true;
    } else {
      m = {};
    }
    var pendingAck = <ConnectionProcessor>[];
    int ts_A = (new DateTime.now()).millisecondsSinceEpoch;
    ProcessorResult rslt = _responderChannel.getSendingData(ts_A, nextMsgId);
    if (rslt != null) {
      if (rslt.messages.length > 0) {
        m["responses"] = rslt.messages;
        needSend = true;
        if (throughputEnabled) {
          for (Map resp in rslt.messages) {
            if (resp["updates"] is List) {
              int len = resp["updates"].length;
              if (len > 0) {
                messageOut += len;
              } else {
                messageOut += 1;
              }
            } else {
              messageOut += 1;
            }
          }
        }
      }
      if (rslt.processors.length > 0) {
        pendingAck.addAll(rslt.processors);
      }
    }
    rslt = _requesterChannel.getSendingData(ts_A, nextMsgId);
    if (rslt != null) {
      if (rslt.messages.length > 0) {
        m["requests"] = rslt.messages;
        needSend = true;
        if (throughputEnabled) {
          messageOut += rslt.messages.length;
        }
      }
      if (rslt.processors.length > 0) {
        pendingAck.addAll(rslt.processors);
      }
    }
    if (needSend) {
      if (nextMsgId != -1) {
        if (pendingAck.length > 0) {
          pendingAcks.add(new ConnectionAckGroup(nextMsgId, ts_A, pendingAck));
        }
        m["msg"] = nextMsgId;
        if (nextMsgId < 0x7FFFFFFF) {
          ++nextMsgId;
        } else {
          nextMsgId = 1;
        }
      }
      addData(m);
      _dataSent = true;
      frameOut++;
    }
  }
  void addData(Map m) {
    Object encoded = codec.encodeFrame(m);
    if (logger.isLoggable(Level.FINEST)) {
      logger.finest(formatLogMessage("send: ${m}"));
    }
    if (throughputEnabled) {
      if (encoded is String) {
        dataOut += encoded.length;
      } else if (encoded is List<int>) {
        dataOut += encoded.length;
      } else {
        logger.warning(formatLogMessage("invalid data frame"));
      }
    }
    socket.add(encoded);
  }
  bool printDisconnectedMessage = true;
  void _onDone_A() {
    if (_onDoneHandled) {
      return;
    }
    _onDoneHandled = true;
    if (printDisconnectedMessage) {
      logger.info(formatLogMessage("Disconnected"));
    }
    if (!_requesterChannel.onReceiveController.isClosed) {
      _requesterChannel.onReceiveController.close();
    }
    if (!_requesterChannel.onDisconnectController.isCompleted) {
      _requesterChannel.onDisconnectController.complete(_requesterChannel);
    }
    if (!_responderChannel.onReceiveController.isClosed) {
      _responderChannel.onReceiveController.close();
    }
    if (!_responderChannel.onDisconnectController.isCompleted) {
      _responderChannel.onDisconnectController.complete(_responderChannel);
    }
    if (!_onDisconnectedCompleter.isCompleted) {
      _onDisconnectedCompleter.complete(false);
    }
    if (pingTimer != null) {
      pingTimer.cancel();
    }
  }
  String formatLogMessage(String msg_A) {
    if (clientLink != null) {
      return clientLink.formatLogMessage(msg_A);
    }
    if (logName != null) {
      return "[${logName}] ${msg_A}";
    }
    return msg_A;
  }
  String logName;
  void close() {
    if (socket.readyState == WebSocket.OPEN || socket.readyState == WebSocket.CONNECTING) {
      socket.close();
    }
    _onDone_A();
  }
}
const bool _tcpNoDelay = const bool.fromEnvironment("dsa.io.tcpNoDelay", defaultValue: true);
Stream<String> readStdinText() {
  return const Utf8Decoder().bind(_B.stdin);
}
Stream<String> readStdinLines() {
  var stream_A = readStdinText();
  return const LineSplitter().bind(stream_A);
}
class HttpHelper {
  static const String _webSocketGUID_A = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11";
  static const bool enableStandardWebSocket = const bool.fromEnvironment("calzone.build", defaultValue: false) || const bool.fromEnvironment("websocket.standard", defaultValue: true);
  static Future<WebSocket> connectToWebSocket(String url, {Iterable<String> protocols, Map<String, dynamic> headers, HttpClient httpClient, bool useStandardWebSocket}) async {
    Uri uri_A = Uri.parse(url);
    if (useStandardWebSocket == null) {
      useStandardWebSocket = enableStandardWebSocket;
    }
    if (useStandardWebSocket == true && uri_A.scheme != "wss") {
      return await WebSocket.connect(url, protocols: protocols, headers: headers);
    }
    if (uri_A.scheme != "ws" && uri_A.scheme != "wss") {
      throw new WebSocketException("Unsupported URL scheme '${uri_A.scheme}'");
    }
    Random random = new Random();
    Uint8List nonceData = new Uint8List(16);
    for (int i = 0; i < 16; i++) {
      nonceData[i] = random.nextInt(256);
    }
    String nonce_A = CryptoUtils.bytesToBase64_A(nonceData);
    int port_A = uri_A.port;
    if (port_A == 0) {
      port_A = uri_A.scheme == "wss" ? 443 : 80;
    }
    uri_A = new Uri(scheme: uri_A.scheme == "wss" ? "https" : "http", userInfo: uri_A.userInfo, host: uri_A.host, port: port_A, path: uri_A.path, query: uri_A.query);
    HttpClient _client = httpClient == null ? (new HttpClient()
        ..badCertificateCallback = (a, b, c) => true) : httpClient;
    return _client.openUrl("GET", uri_A).then((HttpClientRequest request_B) async {
      if (uri_A.userInfo != null && !uri_A.userInfo.isEmpty) {
        String auth = CryptoUtils.bytesToBase64_A(UTF8.encode(uri_A.userInfo));
        request_B.headers.set(HttpHeaders.AUTHORIZATION, "Basic ${auth}");
      }
      if (headers != null) {
        headers.forEach((field, value_A) => request_B.headers.add(field, value_A));
      }
      request_B.headers
          ..set(HttpHeaders.CONNECTION, "Upgrade")
          ..set(HttpHeaders.UPGRADE, "websocket")
          ..set("Sec-WebSocket-Key", nonce_A)
          ..set("Cache-Control", "no-cache")
          ..set("Sec-WebSocket-Version", "13");
      if (protocols != null) {
        request_B.headers.add("Sec-WebSocket-Protocol", protocols.toList());
      }
      return request_B.close();
    }).then((response_B) {
      return response_B;
    }).then((HttpClientResponse response_B) {
      void error_A(String message_A) {
        response_B.detachSocket().then((Socket socket_A) {
          socket_A.destroy();
        });
        throw new WebSocketException(message_A);
      }
      if (response_B.statusCode != HttpStatus.SWITCHING_PROTOCOLS || response_B.headers[HttpHeaders.CONNECTION] == null || !response_B.headers[HttpHeaders.CONNECTION].any((value_A) => value_A.toLowerCase() == "upgrade") || response_B.headers.value(HttpHeaders.UPGRADE).toLowerCase() != "websocket") {
        error_A("Connection to '${uri_A}' was not upgraded to websocket");
      }
      String accept = response_B.headers.value("Sec-WebSocket-Accept");
      if (accept == null) {
        error_A("Response did not contain a 'Sec-WebSocket-Accept' header");
      }
      SHA1 sha1 = new SHA1();
      sha1.add("${nonce_A}${_webSocketGUID_A}".codeUnits);
      List<int> expectedAccept = sha1.close();
      List<int> receivedAccept = CryptoUtils.base64StringToBytes_A(accept);
      if (expectedAccept.length != receivedAccept.length) {
        error_A("Response header 'Sec-WebSocket-Accept' is the wrong length");
      }
      for (int i = 0; i < expectedAccept.length; i++) {
        if (expectedAccept[i] != receivedAccept[i]) {
          error_A("Bad response 'Sec-WebSocket-Accept' header");
        }
      }
      var protocol_A = response_B.headers.value('Sec-WebSocket-Protocol');
      return response_B.detachSocket().then((socket_A) {
        socket_A.setOption(SocketOption.TCP_NODELAY, _tcpNoDelay);
        return new WebSocket.fromUpgradedSocket(socket_A, protocol: protocol_A, serverSide: false);
      });
    });
  }
}
CryptoProvider _CRYPTO_PROVIDER = DartCryptoProvider.INSTANCE;
bool _isCryptoProviderLocked = false;
lockCryptoProvider() => _isCryptoProviderLocked = true;
abstract class CryptoProvider {
  static String sha256(List<int> list_A) {
    Uint8List bytes_A = ByteDataUtil.list2Uint8List(list_A);
    return _CRYPTO_PROVIDER.base64_sha256(bytes_A);
  }
}
abstract class ECDH {
  String hashSalt(String salt);
}
abstract class PublicKey_A {
  String get qBase64;
  String get qHash64;
  PublicKey_A();
}
abstract class PrivateKey_A {
  factory PrivateKey_A.generateSync() => _CRYPTO_PROVIDER.generateSync_A();
  factory PrivateKey_A.loadFromString(String str) => _CRYPTO_PROVIDER.loadFromString_A(str);
}
abstract class DSRandom {
  static DSRandom get instance => _CRYPTO_PROVIDER.random;
}
class DummyECDH implements ECDH {
  final String encodedPublicKey = "";
  const DummyECDH();
  String hashSalt(String salt) {
    return '';
  }
}
class ECDHIsolate {
  static bool get running => _ecdh_isolate != null;
  static Isolate _ecdh_isolate;
  static SendPort _isolatePort;
  static ECDHIsolateRequest _waitingReq;
  static void _checkRequest() {
    if (_waitingReq == null && _requests.length > 0) {
      _waitingReq = _requests.removeFirst();
      _isolatePort.send([_waitingReq.publicKeyRemote.ecPublicKey.Q.getEncoded(false), _waitingReq.oldPrivate]);
    }
  }
  static ListQueue<ECDHIsolateRequest> _requests = new ListQueue<ECDHIsolateRequest>();
  static Future<ECDH> _sendRequest(PublicKey_A publicKeyRemote, String oldprivate) {
    var req = new ECDHIsolateRequest(publicKeyRemote, oldprivate);
    _requests.add(req);
    _checkRequest();
    return req.future;
  }
}
class ECDHIsolateRequest {
  PublicKeyImpl publicKeyRemote;
  String oldPrivate;
  ECDHIsolateRequest(this.publicKeyRemote, this.oldPrivate);
  Completer<ECDH> _completer_A = new Completer<ECDH>();
  Future<ECDH> get future => _completer_A.future;
}
ECDomainParameters __secp256r1;
ECDomainParameters get _secp256r1 {
  if (__secp256r1 != null) {
    return __secp256r1;
  }
  BigInteger q = new BigInteger("ffffffff00000001000000000000000000000000ffffffffffffffffffffffff", 16);
  BigInteger a = new BigInteger("ffffffff00000001000000000000000000000000fffffffffffffffffffffffc", 16);
  BigInteger b = new BigInteger("5ac635d8aa3a93e7b3ebbd55769886bc651d06b0cc53b0f63bce3c3e27d2604b", 16);
  BigInteger g = new BigInteger("046b17d1f2e12c4247f8bce6e563a440f277037d812deb33a0f4a13945d898c2964fe342e2fe1a7f9b8ee7eb4a7c0f9e162bce33576b315ececbb6406837bf51f5", 16);
  BigInteger n = new BigInteger("ffffffff00000000ffffffffffffffffbce6faada7179e84f3b9cac2fc632551", 16);
  BigInteger h = new BigInteger("1", 16);
  BigInteger seed = new BigInteger("c49d360886e704936a6678e1139d26b7819f7e90", 16);
  var seedBytes = seed.toByteArray();
  var curve = new ECCurve_A(q, a, b);
  return new ECDomainParametersImpl("secp256r1", curve, curve.decodePoint(g.toByteArray()), n, h, seedBytes);
}
class DartCryptoProvider implements CryptoProvider {
  static final DartCryptoProvider INSTANCE = new DartCryptoProvider();
  final DSRandomImpl random = new DSRandomImpl();
  ECPrivateKey _cachedPrivate;
  ECPublicKey _cachedPublic;
  int _cachedTime = -1;
  Future<ECDH> getSecret(PublicKey_A publicKeyRemote) async {
    if (ECDHIsolate.running) {
      return ECDHIsolate._sendRequest(publicKeyRemote, "");
    }
    var gen = new ECKeyGenerator();
    var rsapars = new ECKeyGeneratorParameters(_secp256r1);
    var params = new ParametersWithRandom(rsapars, random);
    gen.init(params);
    var pair = gen.generateKeyPair() as AsymmetricKeyPair<ECPublicKey, ECPrivateKey>;
    PublicKeyImpl publicKeyRemoteImpl;
    if (publicKeyRemote is! PublicKeyImpl) {
      throw "Not a PublicKeyImpl: ${publicKeyRemoteImpl}";
    } else {
      publicKeyRemoteImpl = publicKeyRemote;
    }
    var Q2 = publicKeyRemoteImpl.ecPublicKey.Q * pair.privateKey.d;
    return new ECDHImpl(pair.privateKey, pair.publicKey, Q2);
  }
  Future<PrivateKey_A> generate_A() async {
    return generateSync_A();
  }
  PrivateKey_A generateSync_A() {
    var gen = new ECKeyGenerator();
    var rsapars = new ECKeyGeneratorParameters(_secp256r1);
    var params = new ParametersWithRandom(rsapars, random);
    gen.init(params);
    var pair = gen.generateKeyPair();
    return new PrivateKeyImpl(pair.privateKey, pair.publicKey);
  }
  PrivateKey_A loadFromString_A(String str) {
    if (str.contains(" ")) {
      List ss = str.split(" ");
      var d = new BigInteger.fromBytes_A(1, Base64.decode_B(ss[0]));
      ECPrivateKey pri = new ECPrivateKey(d, _secp256r1);
      var Q = _secp256r1.curve.decodePoint(Base64.decode_B(ss[1]));
      ECPublicKey pub = new ECPublicKey(Q, _secp256r1);
      return new PrivateKeyImpl(pri, pub);
    } else {
      var d = new BigInteger.fromBytes_A(1, Base64.decode_B(str));
      ECPrivateKey pri = new ECPrivateKey(d, _secp256r1);
      return new PrivateKeyImpl(pri);
    }
  }
  String base64_sha256(Uint8List bytes_A) {
    SHA256Digest sha256_A = new SHA256Digest();
    Uint8List hashed = sha256_A.process(new Uint8List.fromList(bytes_A));
    return Base64.encode_B(hashed);
  }
}
class ECDHImpl extends ECDH {
  Uint8List bytes_A;
  ECPrivateKey _ecPrivateKey;
  ECPublicKey _ecPublicKey;
  ECDHImpl(this._ecPrivateKey, this._ecPublicKey, ECPoint Q2) {
    bytes_A = bigintToUint8List(Q2.x.toBigInteger());
    if (bytes_A.length > 32) {
      bytes_A = bytes_A.sublist(bytes_A.length - 32);
    } else if (bytes_A.length < 32) {
      var newbytes = new Uint8List(32);
      int dlen = 32 - bytes_A.length;
      for (int i = 0; i < bytes_A.length; ++i) {
        newbytes[i + dlen] = bytes_A[i];
      }
      for (int i = 0; i < dlen; ++i) {
        newbytes[i] = 0;
      }
      bytes_A = newbytes;
    }
  }
  String hashSalt(String salt) {
    Uint8List encoded = toUTF8(salt);
    Uint8List raw_A = new Uint8List(encoded.length + bytes_A.length);
    int i;
    for (i = 0; i < encoded.length; i++) {
      raw_A[i] = encoded[i];
    }
    for (var x_A = 0; x_A < bytes_A.length; x_A++) {
      raw_A[i] = bytes_A[x_A];
      i++;
    }
    SHA256Digest sha256_A = new SHA256Digest();
    var hashed = sha256_A.process(raw_A);
    return Base64.encode_B(hashed);
  }
}
class PublicKeyImpl extends PublicKey_A {
  ECPublicKey ecPublicKey;
  String qBase64;
  String qHash64;
  PublicKeyImpl(this.ecPublicKey) {
    List<int> bytes_A = ecPublicKey.Q.getEncoded(false);
    qBase64 = Base64.encode_B(bytes_A);
    SHA256Digest sha256_A = new SHA256Digest();
    qHash64 = Base64.encode_B(sha256_A.process(bytes_A));
  }
}
class PrivateKeyImpl implements PrivateKey_A {
  PublicKey_A publicKey;
  ECPrivateKey ecPrivateKey;
  ECPublicKey ecPublicKey;
  PrivateKeyImpl(this.ecPrivateKey, [this.ecPublicKey]) {
    if (ecPublicKey == null) {
      ecPublicKey = new ECPublicKey(_secp256r1.G * ecPrivateKey.d, _secp256r1);
    }
    publicKey = new PublicKeyImpl(ecPublicKey);
  }
  String saveToString() {
    return "${Base64.encode_B(bigintToUint8List(ecPrivateKey.d))} ${publicKey.qBase64}";
  }
  Future<ECDHImpl> getSecret(String key_A) async {
    ECPoint p = ecPrivateKey.parameters.curve.decodePoint(Base64.decode_B(key_A));
    ECPublicKey publicKey_A = new ECPublicKey(p, _secp256r1);
    var Q2 = publicKey_A.Q * ecPrivateKey.d;
    return new ECDHImpl(ecPrivateKey, ecPublicKey, Q2);
  }
}
class DSRandomImpl extends SecureRandomBase implements DSRandom {
  bool get needsEntropy => true;
  BlockCtrRandom _delegate_A;
  AESFastEngine _aes;
  DSRandomImpl([int seed_A = -1]) {
    _aes = new AESFastEngine();
    _delegate_A = new BlockCtrRandom(_aes);
    Random r = new Random();
    final keyBytes = [r.nextInt(256), r.nextInt(256), r.nextInt(256), r.nextInt(256), r.nextInt(256), r.nextInt(256), r.nextInt(256), r.nextInt(256), r.nextInt(256), r.nextInt(256), r.nextInt(256), r.nextInt(256), r.nextInt(256), r.nextInt(256), r.nextInt(256), r.nextInt(256)];
    final key_A = new KeyParameter(new Uint8List.fromList(keyBytes));
    r = new Random((new DateTime.now()).millisecondsSinceEpoch);
    final iv = new Uint8List.fromList([r.nextInt(256), r.nextInt(256), r.nextInt(256), r.nextInt(256), r.nextInt(256), r.nextInt(256), r.nextInt(256), r.nextInt(256)]);
    final params = new ParametersWithIV<CipherParameters>(key_A, iv);
    _delegate_A.seed(params);
  }
  void seed(CipherParameters params) {
    if (params is ParametersWithIV<CipherParameters>) {
      _delegate_A.seed(params);
    } else {
      throw "${params} is not a ParametersWithIV implementation.";
    }
  }
  void addEntropy(String str) {
    List<int> utf = const Utf8Encoder().convert(str);
    int length2 = (utf.length).ceil() * 16;
    if (length2 > utf.length) {
      utf = utf.toList();
      while (length2 > utf.length) {
        utf.add(0);
      }
    }
    final bytes_A = new Uint8List.fromList(utf);
    final out = new Uint8List(16);
    for (var offset_A = 0; offset_A < bytes_A.lengthInBytes;) {
      var len = _aes.processBlock(bytes_A, offset_A, out, 0);
      offset_A += len;
    }
  }
  int nextUint8() {
    return _delegate_A.nextUint8();
  }
}
Uint8List bigintToUint8List(BigInteger input_A) {
  List<int> rslt = input_A.toByteArray();
  if (rslt.length > 32 && rslt[0] == 0) {
    rslt = rslt.sublist(1);
  }
  int len = rslt.length;
  for (int i = 0; i < len; ++i) {
    if (rslt[i] < 0) {
      rslt[i] &= 0xff;
    }
  }
  return new Uint8List.fromList(rslt);
}
class DefaultDefNodes {
  static final Map _defaultDefs = {"node": {}, "static": {}, "getHistory": {r"$invokable": "read", r"$result": "table", r"$params": [{"name": "Timerange", "type": "string", "editor": "daterange"}, {"name": "Interval", "type": "enum", "default": "none", "editor": buildEnumType(["default", "none", "1Y", "3N", "1N", "1W", "1D", "12H", "6H", "4H", "3H", "2H", "1H", "30M", "15M", "10M", "5M", "1M", "30S", "15S", "10S", "5S", "1S"])}, {"name": "Rollup", "default": "none", "type": buildEnumType(["none", "avg", "min", "max", "sum", "first", "last", "count", "delta"])}], r"$columns": [{"name": "timestamp", "type": "time"}, {"name": "value", "type": "dynamic"}]}};
  static final Map<String, Node> nameMap = () {
    var rslt = new Map<String, Node>();
    _defaultDefs.forEach((String k, Map m) {
      String path_A = '/defs/profile/${k}';
      RemoteDefNode node = new RemoteDefNode(path_A);
      m.forEach((String n, Object v) {
        if (n.startsWith(r'$')) {
          node.configs[n] = v;
        } else if (n.startsWith('@')) {
          node.attributes[n] = v;
        }
      });
      node.listed = true;
      rslt[k] = node;
    });
    return rslt;
  }();
}
class RemoteNodeCache {
  Map<String, RemoteNode> _nodes = new Map<String, RemoteNode>();
  RemoteNodeCache() {}
  RemoteNode getRemoteNode(String path_A) {
    if (!_nodes.containsKey(path_A)) {
      if (path_A.startsWith('defs')) {
        _nodes[path_A] = new RemoteDefNode(path_A);
      } else {
        _nodes[path_A] = new RemoteNode(path_A);
      }
    }
    return _nodes[path_A];
  }
  void clear() {
    _nodes.clear();
  }
  Node getDefNode(String path_A, String defName) {
    if (DefaultDefNodes.nameMap.containsKey(defName)) {
      return DefaultDefNodes.nameMap[defName];
    }
    return getRemoteNode(path_A);
  }
  RemoteNode updateRemoteChildNode(RemoteNode parent_A, String name_A, Map m) {
    String path_A;
    if (parent_A.remotePath == '/') {
      path_A = '/${name_A}';
    } else {
      path_A = '${parent_A.remotePath}/${name_A}';
    }
    RemoteNode rslt;
    if (_nodes.containsKey(path_A)) {
      rslt = _nodes[path_A];
      rslt.updateRemoteChildData(m, this);
    } else {
      rslt = new RemoteNode(path_A);
      _nodes[path_A] = rslt;
      rslt.updateRemoteChildData(m, this);
    }
    return rslt;
  }
}
class RemoteNode extends Node {
  final String remotePath;
  bool listed = false;
  String name;
  ListController _listController;
  ReqSubscribeController _subscribeController;
  bool get hasValueUpdate {
    if (_subscribeController == null) {
      return false;
    }
    return _subscribeController._lastUpdate != null;
  }
  ValueUpdate get lastValueUpdate {
    if (hasValueUpdate) {
      return _subscribeController._lastUpdate;
    } else {
      return null;
    }
  }
  RemoteNode(this.remotePath) {
    _getRawName();
  }
  void _getRawName() {
    if (remotePath == '/') {
      name = '/';
    } else {
      name = remotePath.split('/').last;
    }
  }
  Stream<RequesterListUpdate> _list_A(Requester requester) {
    if (_listController == null) {
      _listController = createListController(requester);
    }
    return _listController.stream;
  }
  ListController createListController(Requester requester) {
    return new ListController(this, requester);
  }
  void _subscribe_A(Requester requester, callback_A(ValueUpdate update), int qos) {
    if (_subscribeController == null) {
      _subscribeController = new ReqSubscribeController(this, requester);
    }
    _subscribeController.listen(callback_A, qos);
  }
  void _unsubscribe(Requester requester, callback_A(ValueUpdate update)) {
    if (_subscribeController != null) {
      _subscribeController.unlisten(callback_A);
    }
  }
  Stream<RequesterInvokeUpdate> _invoke(Map params, Requester requester, [int maxPermission = Permission.CONFIG, RequestConsumer fetchRawReq]) {
    return new InvokeController(this, requester, params, maxPermission, fetchRawReq)._stream_A;
  }
  void updateRemoteChildData(Map m, RemoteNodeCache cache) {
    String childPathPre;
    if (remotePath == '/') {
      childPathPre = '/';
    } else {
      childPathPre = '${remotePath}/';
    }
    m.forEach((String key_A, value_A) {
      if (key_A.startsWith(r'$')) {
        configs[key_A] = value_A;
      } else if (key_A.startsWith('@')) {
        attributes[key_A] = value_A;
      } else if (value_A is Map) {
        Node node = cache.getRemoteNode('${childPathPre}/${key_A}');
        children[key_A] = node;
        if (node is RemoteNode) {
          node.updateRemoteChildData(value_A, cache);
        }
      }
    });
  }
  void resetNodeCache() {
    configs.clear();
    attributes.clear();
    children.clear();
  }
  Map save({bool includeValue: true}) {
    var map_A = {};
    map_A.addAll(configs);
    map_A.addAll(attributes);
    for (String key_A in children.keys) {
      Node node = children[key_A];
      map_A[key_A] = node is RemoteNode ? node.save() : node.getSimpleMap();
    }
    if (includeValue && _subscribeController != null && _subscribeController._lastUpdate != null) {
      map_A["?value"] = _subscribeController._lastUpdate.value;
      map_A["?value_timestamp"] = _subscribeController._lastUpdate.ts;
    }
    return map_A;
  }
}
class RemoteDefNode extends RemoteNode {
  RemoteDefNode(String path_A) : super(path_A);
}
class Request_A {
  final Requester requester;
  final int rid;
  final Map data;
  final RequestUpdater updater;
  bool _isClosed_A = false;
  bool get isClosed => _isClosed_A;
  Request_A(this.requester, this.rid, this.updater, this.data);
  String streamStatus = StreamStatus.initialize;
  void resend() {
    requester.addToSendList(data);
  }
  void _update(Map m) {
    if (m["stream"] is String) {
      streamStatus = m["stream"];
    }
    List updates;
    List columns;
    Map meta_A;
    if (m["updates"] is List) {
      updates = m["updates"];
    }
    if (m["columns"] is List) {
      columns = m["columns"];
    }
    if (m["meta"] is Map) {
      meta_A = m["meta"];
    }
    if (streamStatus == StreamStatus.closed_A) {
      requester._requests_A.remove(rid);
    }
    DSError error_A;
    if (m.containsKey("error") && m["error"] is Map) {
      error_A = new DSError.fromMap(m["error"]);
      requester._errorController.add(error_A);
    }
    updater.onUpdate(streamStatus, updates, columns, meta_A, error_A);
  }
  void _close_A([DSError error_A]) {
    if (streamStatus != StreamStatus.closed_A) {
      streamStatus = StreamStatus.closed_A;
      updater.onUpdate(StreamStatus.closed_A, null, null, null, error_A);
    }
  }
  void close() {
    requester.closeRequest(this);
  }
}
class RequesterInvokeUpdate extends RequesterUpdate {
  List rawColumns;
  List<TableColumn> columns;
  List updates;
  DSError error;
  Map meta;
  RequesterInvokeUpdate(this.updates, this.rawColumns, this.columns, String streamStatus, {this.meta, this.error}) : super(streamStatus);
  List<List> _rows;
  List<List> get rows {
    int colLen = -1;
    if (columns != null) {
      colLen = columns.length;
    }
    if (_rows == null) {
      _rows = [];
      if (updates == null) {
        return _rows;
      }
      for (Object obj in updates) {
        List<dynamic> row;
        if (obj is List) {
          if (obj.length < colLen) {
            row = obj.toList();
            for (int i = obj.length; i < colLen; ++i) {
              row.add(columns[i].defaultValue);
            }
          } else if (obj.length > colLen) {
            if (colLen == -1) {
              row = obj.toList();
            } else {
              row = obj.sublist(0, colLen);
            }
          } else {
            row = obj;
          }
        } else if (obj is Map) {
          row = [];
          if (columns == null) {
            Map map_A = obj;
            List<String> keys_A = map_A.keys.map((k) => k.toString()).toList();
            columns = keys_A.map((x_A) => new TableColumn(x_A, "dynamic")).toList();
          }
          if (columns != null) {
            for (TableColumn column_A in columns) {
              if (obj.containsKey(column_A.name)) {
                row.add(obj[column_A.name]);
              } else {
                row.add(column_A.defaultValue);
              }
            }
          }
        }
        _rows.add(row);
      }
    }
    return _rows;
  }
}
class InvokeController implements RequestUpdater {
  static List<TableColumn> getNodeColumns(RemoteNode node_A) {
    Object columns = node_A.getConfig_A(r'$columns');
    if (columns is! List && node_A.profile != null) {
      columns = node_A.profile.getConfig_A(r'$columns');
    }
    if (columns is List) {
      return TableColumn.parseColumns(columns);
    }
    return null;
  }
  final RemoteNode node;
  final Requester requester;
  StreamController<RequesterInvokeUpdate> _controller_A;
  Stream<RequesterInvokeUpdate> _stream_A;
  Request_A _request;
  List<TableColumn> _cachedColumns;
  String mode = 'stream';
  String lastStatus = StreamStatus.initialize;
  InvokeController(this.node, this.requester, Map params, [int maxPermission = Permission.CONFIG, RequestConsumer fetchRawReq]) {
    _controller_A = new StreamController<RequesterInvokeUpdate>();
    _controller_A.done.then(_onUnsubscribe);
    _stream_A = _controller_A.stream;
    var reqMap = <String, dynamic>{'method': 'invoke', 'path': node.remotePath, 'params': params};
    if (maxPermission != Permission.CONFIG) {
      reqMap['permit'] = Permission.names[maxPermission];
    }
    _request = requester._sendRequest_A(reqMap, this);
    if (fetchRawReq != null) {
      fetchRawReq(_request);
    }
  }
  void _onUnsubscribe(obj) {
    if (_request != null && _request.streamStatus != StreamStatus.closed_A) {
      _request.close();
    }
  }
  void onUpdate(String streamStatus, List updates, List columns, Map meta_A, DSError error_A) {
    if (meta_A != null && meta_A['mode'] is String) {
      mode = meta_A['mode'];
    }
    if (columns != null) {
      if (_cachedColumns == null || mode == 'refresh') {
        _cachedColumns = TableColumn.parseColumns(columns);
      } else {
        _cachedColumns.addAll(TableColumn.parseColumns(columns));
      }
    } else if (_cachedColumns == null) {
      _cachedColumns = getNodeColumns(node);
    }
    if (error_A != null) {
      streamStatus = StreamStatus.closed_A;
      _controller_A.add(new RequesterInvokeUpdate(null, null, null, streamStatus, error: error_A, meta: meta_A));
    } else if (updates != null || meta_A != null || streamStatus != lastStatus) {
      _controller_A.add(new RequesterInvokeUpdate(updates, columns, _cachedColumns, streamStatus, meta: meta_A));
    }
    lastStatus = streamStatus;
    if (streamStatus == StreamStatus.closed_A) {
      _controller_A.close();
    }
  }
  void onDisconnect() {}
  void onReconnect() {}
}
class RequesterListUpdate extends RequesterUpdate {
  List<String> changes;
  RemoteNode node;
  RequesterListUpdate(this.node, this.changes, String streamStatus) : super(streamStatus);
}
class ListDefListener {
  final RemoteNode node;
  final Requester requester;
  StreamSubscription listener;
  bool ready = false;
  ListDefListener(this.node, this.requester, void callback_A(RequesterListUpdate)) {
    listener = requester.list(node.remotePath).listen((RequesterListUpdate update_B) {
      ready = update_B.streamStatus != StreamStatus.initialize;
      callback_A(update_B);
    });
  }
  void cancel() {
    listener.cancel();
  }
}
class ListController implements RequestUpdater, ConnectionProcessor {
  final RemoteNode node;
  final Requester requester;
  BroadcastStreamController<RequesterListUpdate> _controller_A;
  Stream<RequesterListUpdate> get stream => _controller_A.stream;
  Request_A request;
  ListController(this.node, this.requester) {
    _controller_A = new BroadcastStreamController<RequesterListUpdate>(onStartListen, _onAllCancel, _onListen_A);
  }
  String disconnectTs;
  void onDisconnect() {
    disconnectTs = ValueUpdate.getTs();
    node.configs[r'$disconnectedTs'] = disconnectTs;
    _controller_A.add(new RequesterListUpdate(node, [r'$disconnectedTs'], request.streamStatus));
  }
  void onReconnect() {
    if (disconnectTs != null) {
      node.configs.remove(r'$disconnectedTs');
      disconnectTs = null;
      changes.add(r'$disconnectedTs');
    }
  }
  LinkedHashSet<String> changes = new LinkedHashSet<String>();
  void onUpdate(String streamStatus, List updates, List columns, Map meta_A, DSError error_A) {
    bool reseted = false;
    if (updates != null) {
      for (Object update_B in updates) {
        String name_A;
        Object value_A;
        bool removed = false;
        if (update_B is Map) {
          if (update_B['name'] is String) {
            name_A = update_B['name'];
          } else {
            continue;
          }
          if (update_B['change'] == 'remove') {
            removed = true;
          } else {
            value_A = update_B['value'];
          }
        } else if (update_B is List) {
          if (update_B.length > 0 && update_B[0] is String) {
            name_A = update_B[0];
            if (update_B.length > 1) {
              value_A = update_B[1];
            }
          } else {
            continue;
          }
        } else {
          continue;
        }
        if (name_A.startsWith(r'$')) {
          if (!reseted && (name_A == r'$is' || name_A == r'$base' || (name_A == r'$disconnectedTs' && value_A is String))) {
            reseted = true;
            node.resetNodeCache();
          }
          if (name_A == r'$is') {
            loadProfile(value_A);
          }
          changes.add(name_A);
          if (removed) {
            node.configs.remove(name_A);
          } else {
            node.configs[name_A] = value_A;
          }
        } else if (name_A.startsWith('@')) {
          changes.add(name_A);
          if (removed) {
            node.attributes.remove(name_A);
          } else {
            node.attributes[name_A] = value_A;
          }
        } else {
          changes.add(name_A);
          if (removed) {
            node.children.remove(name_A);
          } else if (value_A is Map) {
            node.children[name_A] = requester.nodeCache.updateRemoteChildNode(node, name_A, value_A);
          }
        }
      }
      if (request.streamStatus != StreamStatus.initialize) {
        node.listed = true;
      }
      if (_pendingRemoveDef) {
        _checkRemoveDef();
      }
      onProfileUpdated();
    }
  }
  ListDefListener _profileLoader;
  void loadProfile(String defName) {
    _ready_A = true;
    String defPath = defName;
    if (!defPath.startsWith('/')) {
      Object base_A = node.configs[r'$base'];
      if (base_A is String) {
        defPath = '${base_A}/defs/profile/${defPath}';
      } else {
        defPath = '/defs/profile/${defPath}';
      }
    }
    if (node.profile is RemoteNode && (node.profile as RemoteNode).remotePath == defPath) {
      return;
    }
    node.profile = requester.nodeCache.getDefNode(defPath, defName);
    if (defName == 'node') {
      return;
    }
    if ((node.profile is RemoteNode) && !(node.profile as RemoteNode).listed) {
      _ready_A = false;
      _profileLoader = new ListDefListener(node.profile, requester, _onProfileUpdate);
    }
  }
  static const List<String> _ignoreProfileProps = const[r'$is', r'$permission', r'$settings'];
  void _onProfileUpdate(RequesterListUpdate update_B) {
    if (_profileLoader == null) {
      logger.finest('warning, unexpected state of profile loading');
      return;
    }
    _profileLoader.cancel();
    _profileLoader = null;
    changes.addAll(update_B.changes.where((str) => !_ignoreProfileProps.contains(str)));
    _ready_A = true;
    onProfileUpdated();
  }
  bool _ready_A = true;
  void onProfileUpdated() {
    if (_ready_A) {
      if (request.streamStatus != StreamStatus.initialize) {
        _controller_A.add(new RequesterListUpdate(node, changes.toList(), request.streamStatus));
        changes.clear();
      }
      if (request.streamStatus == StreamStatus.closed_A) {
        _controller_A.close();
      }
    }
  }
  bool _pendingRemoveDef = false;
  void _checkRemoveDef() {
    _pendingRemoveDef = false;
  }
  void onStartListen() {
    if (request == null && !waitToSend) {
      waitToSend = true;
      requester.addProcessor(this);
    }
  }
  bool waitToSend = false;
  void startSendingData(int currentTime, int waitingAckId) {
    if (!waitToSend) {
      return;
    }
    request = requester._sendRequest_A({'method': 'list', 'path': node.remotePath}, this);
    waitToSend = false;
  }
  void ackReceived(int receiveAckId, int startTime, int currentTime) {}
  void _onListen_A(callback_A(RequesterListUpdate update)) {
    if (_ready_A && request != null) {
      DsTimer.callLater(() {
        var changes_A = <String>[];
        changes_A
            ..addAll(node.configs.keys)
            ..addAll(node.attributes.keys)
            ..addAll(node.children.keys);
        RequesterListUpdate update_B = new RequesterListUpdate(node, changes_A, request.streamStatus);
        callback_A(update_B);
      });
    }
  }
  void _onAllCancel() {
    _destroy();
  }
  void _destroy() {
    waitToSend = false;
    if (_profileLoader != null) {
      _profileLoader.cancel();
      _profileLoader = null;
    }
    if (request != null) {
      requester.closeRequest(request);
      request = null;
    }
    _controller_A.close();
    node._listController = null;
  }
}
class RemoveController implements RequestUpdater {
  final Completer<RequesterUpdate> completer = new Completer<RequesterUpdate>();
  Future<RequesterUpdate> get future => completer.future;
  final Requester requester;
  final String path;
  Request_A _request;
  RemoveController(this.requester, this.path) {
    var reqMap = <String, dynamic>{'method': 'remove', 'path': path};
    _request = requester._sendRequest_A(reqMap, this);
  }
  void onUpdate(String status_A, List updates, List columns, Map meta_A, DSError error_A) {
    completer.complete(new RequesterUpdate(status_A));
  }
  void onDisconnect() {}
  void onReconnect() {}
}
class SetController implements RequestUpdater {
  final Completer<RequesterUpdate> completer = new Completer<RequesterUpdate>();
  Future<RequesterUpdate> get future => completer.future;
  final Requester requester;
  final String path;
  final Object value;
  Request_A _request;
  SetController(this.requester, this.path, this.value, [int maxPermission = Permission.CONFIG]) {
    var reqMap = <String, dynamic>{'method': 'set', 'path': path, 'value': value};
    if (maxPermission != Permission.CONFIG) {
      reqMap['permit'] = Permission.names[maxPermission];
    }
    _request = requester._sendRequest_A(reqMap, this);
  }
  void onUpdate(String status_A, List updates, List columns, Map meta_A, DSError error_A) {
    completer.complete(new RequesterUpdate(status_A));
  }
  void onDisconnect() {}
  void onReconnect() {}
}
class ReqSubscribeListener implements StreamSubscription {
  ValueUpdateCallback callback;
  Requester requester;
  String path;
  ReqSubscribeListener(this.requester, this.path, this.callback);
  Future cancel() {
    if (callback != null) {
      requester.unsubscribe(path, callback);
      callback = null;
    }
    return null;
  }
  Future asFuture([futureValue]) {
    return null;
  }
  bool get isPaused => false;
  void onData(void handleData(data)) {}
  void onDone(void handleDone()) {}
  void onError(Function handleError_A) {}
  void pause([Future resumeSignal]) {}
  void resume() {}
}
class SubscribeController implements RequestUpdater {
  SubscribeRequest request;
  SubscribeController();
  void onDisconnect() {}
  void onReconnect() {}
  void onUpdate(String status_A, List updates, List columns, Map meta_A, DSError error_A) {}
}
class SubscribeRequest extends Request_A implements ConnectionProcessor {
  int lastSid = 0;
  int getNextSid() {
    do {
      if (lastSid < 0x7FFFFFFF) {
        ++lastSid;
      } else {
        lastSid = 1;
      }
    } while (subscriptionIds.containsKey(lastSid));
    return lastSid;
  }
  final Map<String, ReqSubscribeController> subscriptions = new Map<String, ReqSubscribeController>();
  final Map<int, ReqSubscribeController> subscriptionIds = new Map<int, ReqSubscribeController>();
  SubscribeRequest(Requester requester, int rid) : super(requester, rid, new SubscribeController(), null) {
    (updater as SubscribeController).request = this;
  }
  void resend() {
    prepareSending();
  }
  void _close_A([DSError error_A]) {
    if (subscriptions.isNotEmpty) {
      _changedPaths.addAll(subscriptions.keys);
    }
    _waitingAckCount = 0;
    _lastWatingAckId = -1;
    _sendingAfterAck = false;
  }
  void _update(Map m) {
    List updates = m['updates'];
    if (updates is List) {
      for (Object update_B in updates) {
        String path_A;
        int sid = -1;
        Object value_A;
        String ts_A;
        Map meta_A;
        if (update_B is Map) {
          if (update_B['ts'] is String) {
            path_A = update_B['path'];
            ts_A = update_B['ts'];
            if (update_B['path'] is String) {
              path_A = update_B['path'];
            } else if (update_B['sid'] is int) {
              sid = update_B['sid'];
            } else {
              continue;
            }
          }
          value_A = update_B['value'];
          meta_A = update_B;
        } else if (update_B is List && update_B.length > 2) {
          if (update_B[0] is String) {
            path_A = update_B[0];
          } else if (update_B[0] is int) {
            sid = update_B[0];
          } else {
            continue;
          }
          value_A = update_B[1];
          ts_A = update_B[2];
        } else {
          continue;
        }
        ReqSubscribeController controller_A;
        if (path_A != null) {
          controller_A = subscriptions[path_A];
        } else if (sid > -1) {
          controller_A = subscriptionIds[sid];
        }
        if (controller_A != null) {
          var valueUpdate = new ValueUpdate(value_A, ts: ts_A, meta: meta_A);
          controller_A.addValue(valueUpdate);
        }
      }
    }
  }
  HashSet<String> _changedPaths = new HashSet<String>();
  void addSubscription(ReqSubscribeController controller_A, int level_A) {
    String path_A = controller_A.node.remotePath;
    subscriptions[path_A] = controller_A;
    subscriptionIds[controller_A.sid] = controller_A;
    prepareSending();
    _changedPaths.add(path_A);
  }
  void removeSubscription(ReqSubscribeController controller_A) {
    String path_A = controller_A.node.remotePath;
    if (subscriptions.containsKey(path_A)) {
      toRemove[subscriptions[path_A].sid] = subscriptions[path_A];
      prepareSending();
    } else if (subscriptionIds.containsKey(controller_A.sid)) {
      logger.severe('unexpected remoteSubscription in the requester, sid: ${controller_A.sid}');
    }
  }
  Map<int, ReqSubscribeController> toRemove = new Map<int, ReqSubscribeController>();
  void startSendingData(int currentTime, int waitingAckId) {
    _pendingSending = false;
    if (waitingAckId != -1) {
      _waitingAckCount++;
      _lastWatingAckId = waitingAckId;
    }
    if (requester.connection == null) {
      return;
    }
    List toAdd = [];
    HashSet<String> processingPaths = _changedPaths;
    _changedPaths = new HashSet<String>();
    for (String path_A in processingPaths) {
      if (subscriptions.containsKey(path_A)) {
        ReqSubscribeController sub = subscriptions[path_A];
        Map m = {'path': path_A, 'sid': sub.sid};
        if (sub.currentQos > 0) {
          m['qos'] = sub.currentQos;
        }
        toAdd.add(m);
      }
    }
    if (!toAdd.isEmpty) {
      requester._sendRequest_A({'method': 'subscribe', 'paths': toAdd}, null);
    }
    if (!toRemove.isEmpty) {
      List removeSids = [];
      toRemove.forEach((int sid, ReqSubscribeController sub) {
        if (sub.callbacks.isEmpty) {
          removeSids.add(sid);
          subscriptions.remove(sub.node.remotePath);
          subscriptionIds.remove(sub.sid);
          sub._destroy();
        }
      });
      requester._sendRequest_A({'method': 'unsubscribe', 'sids': removeSids}, null);
      toRemove.clear();
    }
  }
  bool _pendingSending = false;
  int _waitingAckCount = 0;
  int _lastWatingAckId = -1;
  void ackReceived(int receiveAckId, int startTime, int currentTime) {
    if (receiveAckId == _lastWatingAckId) {
      _waitingAckCount = 0;
    } else {
      _waitingAckCount--;
    }
    if (_sendingAfterAck) {
      _sendingAfterAck = false;
      prepareSending();
    }
  }
  bool _sendingAfterAck = false;
  void prepareSending() {
    if (_sendingAfterAck) {
      return;
    }
    if (_waitingAckCount > ConnectionProcessor.ACK_WAIT_COUNT) {
      _sendingAfterAck = true;
      return;
    }
    if (!_pendingSending) {
      _pendingSending = true;
      requester.addProcessor(this);
    }
  }
}
class ReqSubscribeController {
  final RemoteNode node;
  final Requester requester;
  Map<Function, int> callbacks = new Map<Function, int>();
  int currentQos = -1;
  int sid;
  ReqSubscribeController(this.node, this.requester) {
    sid = requester._subscription_A.getNextSid();
  }
  void listen(callback_A(ValueUpdate update), int qos) {
    if (qos < 0 || qos > 3) {
      qos = 0;
    }
    bool qosChanged = false;
    if (callbacks.containsKey(callback_A)) {
      if (callbacks[callback_A] != 0) {
        callbacks[callback_A] = qos;
        qosChanged = updateQos();
      } else {
        callbacks[callback_A] = qos;
      }
    } else {
      callbacks[callback_A] = qos;
      int neededQos = qos;
      if (currentQos > -1) {
        neededQos |= currentQos;
      }
      qosChanged = neededQos > currentQos;
      currentQos = neededQos;
      if (_lastUpdate != null) {
        callback_A(_lastUpdate);
      }
    }
    if (qosChanged) {
      requester._subscription_A.addSubscription(this, currentQos);
    }
  }
  void unlisten(callback_A(ValueUpdate update)) {
    if (callbacks.containsKey(callback_A)) {
      int cacheLevel = callbacks.remove(callback_A);
      if (callbacks.isEmpty) {
        requester._subscription_A.removeSubscription(this);
      } else if (cacheLevel == currentQos && currentQos > 1) {
        updateQos();
      }
    }
  }
  bool updateQos() {
    int qosCache = 0;
    for (var qos in callbacks.values) {
      qosCache |= qos;
    }
    if (qosCache != currentQos) {
      currentQos = qosCache;
      return true;
    }
    return false;
  }
  ValueUpdate _lastUpdate;
  void addValue(ValueUpdate update_B) {
    _lastUpdate = update_B;
    for (Function callback_A in callbacks.keys.toList()) {
      callback_A(_lastUpdate);
    }
  }
  void _destroy() {
    callbacks.clear();
    node._subscribeController = null;
  }
}
typedef T_A RequestConsumer<T_A>(Request_A _0);
abstract class RequestUpdater {}
class RequesterUpdate {
  final String streamStatus;
  RequesterUpdate(this.streamStatus);
}
class Requester extends ConnectionHandler {
  Map<int, Request_A> _requests_A = new Map<int, Request_A>();
  final RemoteNodeCache nodeCache;
  SubscribeRequest _subscription_A;
  Requester([RemoteNodeCache cache]) : nodeCache = cache != null ? cache : new RemoteNodeCache() {
    _subscription_A = new SubscribeRequest(this, 0);
    _requests_A[0] = _subscription_A;
  }
  void onData(List list_A) {
    for (Object resp in list_A) {
      if (resp is Map) {
        _onReceiveUpdate(resp);
      }
    }
  }
  void _onReceiveUpdate(Map m) {
    if (m['rid'] is int && _requests_A.containsKey(m['rid'])) {
      _requests_A[m['rid']]._update(m);
    }
  }
  StreamController<DSError> _errorController = new StreamController<DSError>.broadcast();
  Stream<DSError> get onError => _errorController.stream;
  int lastRid = 0;
  int getNextRid() {
    do {
      if (lastRid < 0x7FFFFFFF) {
        ++lastRid;
      } else {
        lastRid = 1;
      }
    } while (_requests_A.containsKey(lastRid));
    return lastRid;
  }
  ProcessorResult getSendingData(int currentTime, int waitingAckId) {
    ProcessorResult rslt = super.getSendingData(currentTime, waitingAckId);
    return rslt;
  }
  Request_A _sendRequest_A(Map<String, dynamic> m, RequestUpdater updater) {
    m['rid'] = getNextRid();
    Request_A req;
    if (updater != null) {
      req = new Request_A(this, lastRid, updater, m);
      _requests_A[lastRid] = req;
    }
    addToSendList(m);
    return req;
  }
  ReqSubscribeListener subscribe(String path_A, callback_A(ValueUpdate update), [int qos = 0]) {
    RemoteNode node = nodeCache.getRemoteNode(path_A);
    node._subscribe_A(this, callback_A, qos);
    return new ReqSubscribeListener(this, path_A, callback_A);
  }
  Future<RemoteNode> getRemoteNode(String path_A) {
    var c = new Completer<RemoteNode>();
    StreamSubscription sub;
    sub = list(path_A).listen((update_B) {
      if (!c.isCompleted) {
        c.complete(update_B.node);
      }
      if (sub != null) {
        sub.cancel();
      }
    }, onError: (e, stack) {
      if (!c.isCompleted) {
        c.completeError(e, stack);
      }
    }, cancelOnError: true);
    return c.future;
  }
  void unsubscribe(String path_A, callback_A(ValueUpdate update)) {
    RemoteNode node = nodeCache.getRemoteNode(path_A);
    node._unsubscribe(this, callback_A);
  }
  Stream<RequesterListUpdate> list(String path_A) {
    RemoteNode node = nodeCache.getRemoteNode(path_A);
    return node._list_A(this);
  }
  Stream<RequesterInvokeUpdate> invoke(String path_A, [Map params = const{}, int maxPermission = Permission.CONFIG, RequestConsumer fetchRawReq]) {
    RemoteNode node = nodeCache.getRemoteNode(path_A);
    return node._invoke(params, this, maxPermission, fetchRawReq);
  }
  Future<RequesterUpdate> set(String path_A, Object value_A, [int maxPermission = Permission.CONFIG]) {
    return new SetController(this, path_A, value_A, maxPermission).future;
  }
  Future<RequesterUpdate> remove(String path_A) {
    return new RemoveController(this, path_A).future;
  }
  void closeRequest(Request_A request_B) {
    if (_requests_A.containsKey(request_B.rid)) {
      if (request_B.streamStatus != StreamStatus.closed_A) {
        addToSendList({'method': 'close', 'rid': request_B.rid});
      }
      _requests_A.remove(request_B.rid);
      request_B._close_A();
    }
  }
  bool _connected = false;
  void onDisconnected() {
    if (!_connected) return;
    _connected = false;
    var newRequests = new Map<int, Request_A>();
    newRequests[0] = _subscription_A;
    _requests_A.forEach((n, req) {
      if (req.rid <= lastRid && req.updater is! ListController) {
        req._close_A(DSError.DISCONNECTED);
      } else {
        newRequests[req.rid] = req;
        req.updater.onDisconnect();
      }
    });
    _requests_A = newRequests;
  }
  void onReconnected() {
    if (_connected) return;
    _connected = true;
    super.onReconnected();
    _requests_A.forEach((n, req) {
      req.updater.onReconnect();
      req.resend();
    });
  }
}
class ConfigSetting {
  final String name;
  final String type;
  final Object defaultValue;
  ConfigSetting.fromMap_A(this.name, Map m) : type = m.containsKey('type') ? m['type'] : 'string', defaultValue = m.containsKey('default') ? m['default'] : null {}
  DSError setConfig(Object value_A, LocalNodeImpl node, Responder responder) {
    if (node.configs[name] != value_A) {
      node.configs[name] = value_A;
      node.updateList(name);
    }
    return null;
  }
  DSError removeConfig(LocalNodeImpl node, Responder responder) {
    if (node.configs.containsKey(name)) {
      node.configs.remove(name);
      node.updateList(name);
    }
    return null;
  }
}
class Configs {
  static const Map _globalConfigs = const{r'$is': const{'type': 'profile'}, r'$interface': const{'type': 'interface'}, r'$permissions': const{'type': 'list', 'require': Permission.CONFIG, 'writable': Permission.CONFIG}, r'$name': const{'type': 'string'}, r'$type': const{'type': 'type'}, r'$invokable': const{'type': 'permission', 'default': 'read'}, r'$writable': const{'type': 'permission', 'default': 'never'}, r'$settings': const{'type': 'map'}, r'$params': const{'type': 'list'}, r'$columns': const{'type': 'list'}, r'$streamMeta': const{'type': 'list'}};
  static final Configs global = new Configs()
      ..load(_globalConfigs);
  static final ConfigSetting defaultConfig = new ConfigSetting.fromMap_A('', const{});
  static ConfigSetting getConfig(String name_A, Node profile) {
    if (global.configs.containsKey(name_A)) {
      return global.configs[name_A];
    }
    if (profile is DefinitionNode && profile.configs.containsKey(name_A)) {
      return profile.configs[name_A];
    }
    return defaultConfig;
  }
  Map<String, ConfigSetting> configs = {};
  void load(Map inputs) {
    inputs.forEach((name_A, m) {
      if (m is Map) {
        configs[name_A] = new ConfigSetting.fromMap_A(name_A, m);
      }
    });
  }
}
class DefinitionNode extends LocalNodeImpl {}
abstract class NodeProviderImpl extends NodeProvider {
  Map<String, LocalNode> get nodes;
}
abstract class LocalNodeImpl extends LocalNode {
  LocalNodeImpl(String path_A) : super(path_A);
  bool _loaded = false;
  void load(Map m) {
    if (_loaded) {
      configs.clear();
      attributes.clear();
      children.clear();
    }
    String childPathPre;
    if (path == '/') {
      childPathPre = '/';
    } else {
      childPathPre = '${path}/';
    }
    m.forEach((String key_A, value_A) {
      if (key_A.startsWith(r'$')) {
        configs[key_A] = value_A;
      } else if (key_A.startsWith('@')) {
        attributes[key_A] = value_A;
      } else if (value_A is Map) {
        Node node = provider.getOrCreateNode('${childPathPre}${key_A}', false);
        if (node is LocalNodeImpl) {
          node.load(value_A);
        }
        children[key_A] = node;
      }
    });
    _loaded = true;
  }
  void updateList(String name_A) {
    listChangeController.add(name_A);
  }
  Response_A setAttribute(String name_A, Object value_A, Responder responder, Response_A response_B) {
    if (!attributes.containsKey(name_A) || attributes[name_A] != value_A) {
      attributes[name_A] = value_A;
      updateList(name_A);
      if (provider is SerializableNodeProvider) {
        (provider as SerializableNodeProvider).persist();
      }
    }
    return response_B
        ..close();
  }
  Response_A removeAttribute(String name_A, Responder responder, Response_A response_B) {
    if (attributes.containsKey(name_A)) {
      attributes.remove(name_A);
      updateList(name_A);
      if (provider is SerializableNodeProvider) {
        (provider as SerializableNodeProvider).persist();
      }
    }
    return response_B
        ..close();
  }
  Response_A setConfig(String name_A, Object value_A, Responder responder, Response_A response_B) {
    var config = Configs.getConfig(name_A, profile);
    response_B.close(config.setConfig(value_A, this, responder));
    return response_B;
  }
  Response_A removeConfig(String name_A, Responder responder, Response_A response_B) {
    var config = Configs.getConfig(name_A, profile);
    return response_B
        ..close(config.removeConfig(this, responder));
  }
  Response_A setValue(Object value_A, Responder responder, Response_A response_B, [int maxPermission = Permission.CONFIG]) {
    updateValue(value_A);
    return response_B
        ..close();
  }
}
abstract class IPermissionManager {}
class DummyPermissionManager implements IPermissionManager {
  int getPermission(String path_A, Responder resp) {
    return Permission.CONFIG;
  }
}
abstract class ISubscriptionResponderStorage {}
abstract class ISubscriptionNodeStorage {}
typedef dynamic ResponseTraceCallback(ResponseTrace _0);
class ResponseTrace {
  String path;
  String type;
  String change_A;
  String action;
  int rid;
  ResponseTrace(this.path, this.type, this.rid, [this.change_A = '', this.action]);
}
abstract class LocalNode extends Node {
  BroadcastStreamController<String> _listChangeController;
  BroadcastStreamController<String> get listChangeController {
    if (_listChangeController == null) {
      _listChangeController = new BroadcastStreamController<String>(() {
        _hasListListener = true;
        onStartListListen();
      }, () {
        _hasListListener = false;
        onAllListCancel();
      }, null, true);
    }
    return _listChangeController;
  }
  Stream<String> get listStream => listChangeController.stream;
  void onStartListListen() {}
  void onAllListCancel() {}
  bool _hasListListener = false;
  NodeProvider get provider;
  final String path;
  LocalNode(this.path);
  Map<ValueUpdateCallback, int> callbacks = new Map<ValueUpdateCallback, int>();
  RespSubscribeListener subscribe(callback_A(ValueUpdate update), [int qos = 0]) {
    callbacks[callback_A] = qos;
    return new RespSubscribeListener(this, callback_A);
  }
  void unsubscribe(ValueUpdateCallback callback_A) {
    if (callbacks.containsKey(callback_A)) {
      callbacks.remove(callback_A);
    }
  }
  ValueUpdate _lastValueUpdate;
  ValueUpdate get lastValueUpdate {
    if (_lastValueUpdate == null) {
      _lastValueUpdate = new ValueUpdate(null);
    }
    return _lastValueUpdate;
  }
  dynamic get value {
    if (_lastValueUpdate != null) {
      return _lastValueUpdate.value;
    }
    return null;
  }
  bool _valueReady = false;
  bool get valueReady => _valueReady;
  void updateValue(Object update_B, {bool force: false}) {
    _valueReady = true;
    if (update_B is ValueUpdate) {
      _lastValueUpdate = update_B;
      callbacks.forEach((callback_A, qos) {
        callback_A(_lastValueUpdate);
      });
    } else if (_lastValueUpdate == null || _lastValueUpdate.value != update_B || force) {
      _lastValueUpdate = new ValueUpdate(update_B);
      callbacks.forEach((callback_A, qos) {
        callback_A(_lastValueUpdate);
      });
    }
  }
  bool get exists => true;
  bool get listReady => true;
  String get disconnected => null;
  bool get hasSubscriber => callbacks.isNotEmpty;
  int getInvokePermission() {
    return Permission.parse_A(getConfig_A(r'$invokable'));
  }
  int getSetPermission() {
    return Permission.parse_A(getConfig_A(r'$writable'));
  }
  InvokeResponse invoke(Map<String, dynamic> params, Responder responder, InvokeResponse response_B, Node parentNode, [int maxPermission = Permission.CONFIG]) {
    return response_B
        ..close();
  }
  Response_A setAttribute(String name_A, Object value_A, Responder responder, Response_A response_B) {
    if (response_B != null) {
      return response_B
          ..close();
    } else {
      if (!name_A.startsWith("@")) {
        name_A = "@${name_A}";
      }
      attributes[name_A] = value_A;
      if (provider is SerializableNodeProvider) {
        (provider as SerializableNodeProvider).persist();
      }
      return null;
    }
  }
  Response_A removeAttribute(String name_A, Responder responder, Response_A response_B) {
    if (response_B != null) {
      return response_B
          ..close();
    } else {
      if (!name_A.startsWith("@")) {
        name_A = "@${name_A}";
      }
      attributes.remove(name_A);
      if (provider is SerializableNodeProvider) {
        (provider as SerializableNodeProvider).persist();
      }
      return null;
    }
  }
  Response_A setConfig(String name_A, Object value_A, Responder responder, Response_A response_B) {
    if (response_B != null) {
      return response_B
          ..close();
    } else {
      if (!name_A.startsWith(r"$")) {
        name_A = "\$${name_A}";
      }
      configs[name_A] = value_A;
      return null;
    }
  }
  Response_A removeConfig(String name_A, Responder responder, Response_A response_B) {
    if (response_B != null) {
      return response_B
          ..close();
    } else {
      if (!name_A.startsWith(r"$")) {
        name_A = "\$${name_A}";
      }
      configs.remove(name_A);
      return null;
    }
  }
  Response_A setValue(Object value_A, Responder responder, Response_A response_B, [int maxPermission = Permission.CONFIG]) {
    return response_B
        ..close();
  }
  operator[](String name_A) {
    return get(name_A);
  }
  operator[]=(String name_A, Object value_A) {
    if (name_A.startsWith(r"$")) {
      configs[name_A] = value_A;
    } else if (name_A.startsWith(r"@")) {
      attributes[name_A] = value_A;
    } else if (value_A is Node) {
      addChild(name_A, value_A);
    }
  }
  void load(Map<String, dynamic> map_A) {}
}
abstract class NodeProvider {
  LocalNode getNode(String path_A);
  LocalNode getOrCreateNode(String path_A, [bool addToTree = true]);
  LocalNode operator[](String path_A) {
    return getNode(path_A);
  }
  LocalNode operator~() => getOrCreateNode("/", false);
  IPermissionManager get permissions;
}
class Responder extends ConnectionHandler {
  String reqId;
  int maxCacheLength = ConnectionProcessor.DEFAULT_CACHE_SIZE;
  ISubscriptionResponderStorage storage;
  List<String> groups = [];
  final Map<int, Response_A> _responses = new Map<int, Response_A>();
  SubscribeResponse _subscription_B;
  final NodeProvider nodeProvider;
  Responder(this.nodeProvider, [this.reqId]) {
    _subscription_B = new SubscribeResponse(this, 0);
    _responses[0] = _subscription_B;
    if (reqId != null) {
      groups = [reqId];
    }
  }
  Response_A addResponse(Response_A response_B) {
    if (response_B._sentStreamStatus != StreamStatus.closed_A) {
      _responses[response_B.rid] = response_B;
      if (_traceCallbacks != null) {
        ResponseTrace update_B = response_B.getTraceData();
        for (ResponseTraceCallback callback_A in _traceCallbacks) {
          callback_A(update_B);
        }
      }
    } else {
      if (_traceCallbacks != null) {
        ResponseTrace update_B = response_B.getTraceData('');
        for (ResponseTraceCallback callback_A in _traceCallbacks) {
          callback_A(update_B);
        }
      }
    }
    return response_B;
  }
  void traceResponseRemoved(Response_A response_B) {
    ResponseTrace update_B = response_B.getTraceData('-');
    for (ResponseTraceCallback callback_A in _traceCallbacks) {
      callback_A(update_B);
    }
  }
  bool disabled = false;
  void onData(List list_A) {
    if (disabled) {
      return;
    }
    for (Object resp in list_A) {
      if (resp is Map) {
        _onReceiveRequest(resp);
      }
    }
  }
  void _onReceiveRequest(Map m) {
    Object method_A = m['method'];
    if (m['rid'] is int) {
      if (method_A == null) {
        updateInvoke(m);
        return;
      } else {
        if (_responses.containsKey(m['rid'])) {
          if (method_A == 'close') {
            close(m);
          }
          return;
        }
        switch (method_A) {
          case 'list':
            list(m);
            return;

          case 'subscribe':
            subscribe(m);
            return;

          case 'unsubscribe':
            unsubscribe(m);
            return;

          case 'invoke':
            invoke(m);
            return;

          case 'set':
            set(m);
            return;

          case 'remove':
            remove(m);
            return;
        }
      }
    }
    closeResponse(m['rid'], error: DSError.INVALID_METHOD);
  }
  void closeResponse(int rid, {Response_A response, DSError error}) {
    if (response != null) {
      if (_responses[response.rid] != response) {
        return;
      }
      response._sentStreamStatus = StreamStatus.closed_A;
      rid = response.rid;
    }
    Map m = {'rid': rid, 'stream': StreamStatus.closed_A};
    if (error != null) {
      m['error'] = error.serialize();
    }
    _responses.remove(rid);
    addToSendList(m);
  }
  void updateResponse(Response_A response_B, List updates, {String streamStatus, List<dynamic> columns, Map meta, void handleMap(Map m)}) {
    if (_responses[response_B.rid] == response_B) {
      Map m = {'rid': response_B.rid};
      if (streamStatus != null && streamStatus != response_B._sentStreamStatus) {
        response_B._sentStreamStatus = streamStatus;
        m['stream'] = streamStatus;
      }
      if (columns != null) {
        m['columns'] = columns;
      }
      if (updates != null) {
        m['updates'] = updates;
      }
      if (meta != null) {
        m['meta'] = meta;
      }
      if (handleMap != null) {
        handleMap(m);
      }
      addToSendList(m);
      if (response_B._sentStreamStatus == StreamStatus.closed_A) {
        _responses.remove(response_B.rid);
        if (_traceCallbacks != null) {
          traceResponseRemoved(response_B);
        }
      }
    }
  }
  void list(Map m) {
    Path path_A = Path.getValidNodePath(m['path']);
    if (path_A != null && path_A.isAbsolute) {
      int rid = m['rid'];
      _getNode(path_A, (LocalNode node) {
        addResponse(new ListResponse(this, rid, node));
      }, (e, stack) {
        var error_A = new DSError("nodeError", msg: e.toString(), detail: stack.toString());
        closeResponse(m['rid'], error: error_A);
      });
    } else {
      closeResponse(m['rid'], error: DSError.INVALID_PATH);
    }
  }
  void subscribe(Map m) {
    if (m['paths'] is List) {
      for (Object p in m['paths']) {
        String pathstr;
        int qos = 0;
        int sid = -1;
        if (p is Map) {
          if (p['path'] is String) {
            pathstr = p['path'];
          } else {
            continue;
          }
          if (p['sid'] is int) {
            sid = p['sid'];
          } else {
            continue;
          }
          if (p['qos'] is int) {
            qos = p['qos'];
          }
        }
        Path path_A = Path.getValidNodePath(pathstr);
        if (path_A != null && path_A.isAbsolute) {
          _getNode(path_A, (LocalNode node) {
            _subscription_B.add(path_A.path, node, sid, qos);
            closeResponse(m['rid']);
          }, (e, stack) {
            var error_A = new DSError("nodeError", msg: e.toString(), detail: stack.toString());
            closeResponse(m['rid'], error: error_A);
          });
        } else {
          closeResponse(m['rid']);
        }
      }
    } else {
      closeResponse(m['rid'], error: DSError.INVALID_PATHS);
    }
  }
  void _getNode(Path p, Taker<LocalNode> func, [TwoTaker<dynamic, dynamic> onError_A]) {
    try {
      LocalNode node = nodeProvider.getOrCreateNode(p.path, false);
      if (node is WaitForMe) {
        (node as WaitForMe).onLoaded.then((n) {
          if (n is LocalNode) {
            node = n;
          }
          func(node);
        }).catchError((e, stack) {
          if (onError_A != null) {
            onError_A(e, stack);
          }
        });
      } else {
        func(node);
      }
    } catch (e, stack) {
      if (onError_A != null) {
        onError_A(e, stack);
      } else {
        rethrow;
      }
    }
  }
  void unsubscribe(Map m) {
    if (m['sids'] is List) {
      for (Object sid in m['sids']) {
        if (sid is int) {
          _subscription_B.remove(sid);
        }
      }
      closeResponse(m['rid']);
    } else {
      closeResponse(m['rid'], error: DSError.INVALID_PATHS);
    }
  }
  void invoke(Map m) {
    Path path_A = Path.getValidNodePath(m['path']);
    if (path_A != null && path_A.isAbsolute) {
      int rid = m['rid'];
      LocalNode parentNode;
      parentNode = nodeProvider.getOrCreateNode(path_A.parentPath, false);
      doInvoke([LocalNode overriden]) {
        LocalNode node = overriden == null ? nodeProvider.getNode(path_A.path) : overriden;
        if (node == null) {
          if (overriden == null) {
            node = parentNode.getChild(path_A.name);
            if (node == null) {
              closeResponse(m['rid'], error: DSError.PERMISSION_DENIED);
              return;
            }
            if (node is WaitForMe) {
              (node as WaitForMe).onLoaded.then((__I) => doInvoke(node));
              return;
            } else {
              doInvoke(node);
              return;
            }
          } else {
            closeResponse(m['rid'], error: DSError.PERMISSION_DENIED);
            return;
          }
        }
        int permission = nodeProvider.permissions.getPermission(path_A.path, this);
        int maxPermit = Permission.parse_A(m['permit']);
        if (maxPermit < permission) {
          permission = maxPermit;
        }
        Map<String, dynamic> params;
        if (m["params"] is Map<String, dynamic>) {
          params = m["params"] as Map<String, dynamic>;
        }
        if (params == null) {
          params = {};
        }
        if (node.getInvokePermission() <= permission) {
          node.invoke(params, this, addResponse(new InvokeResponse(this, rid, parentNode, node, path_A.name)), parentNode, permission);
        } else {
          closeResponse(m['rid'], error: DSError.PERMISSION_DENIED);
        }
      }
      if (parentNode is WaitForMe) {
        (parentNode as WaitForMe).onLoaded.then((__I) {
          doInvoke();
        }).catchError((e, stack) {
          var err = new DSError("nodeError", msg: e.toString(), detail: stack.toString());
          closeResponse(m['rid'], error: err);
        });
      } else {
        doInvoke();
      }
    } else {
      closeResponse(m['rid'], error: DSError.INVALID_PATH);
    }
  }
  void updateInvoke(Map m) {
    int rid = m['rid'];
    if (_responses[rid] is InvokeResponse) {
      if (m['params'] is Map) {
        (_responses[rid] as InvokeResponse).updateReqParams(m['params']);
      }
    } else {
      closeResponse(m['rid'], error: DSError.INVALID_METHOD);
    }
  }
  void set(Map m) {
    Path path_A = Path.getValidPath(m['path']);
    if (path_A == null || !path_A.isAbsolute) {
      closeResponse(m['rid'], error: DSError.INVALID_PATH);
      return;
    }
    if (!m.containsKey('value')) {
      closeResponse(m['rid'], error: DSError.INVALID_VALUE);
      return;
    }
    Object value_A = m['value'];
    int rid = m['rid'];
    if (path_A.isNode) {
      _getNode(path_A, (LocalNode node) {
        int permission = nodeProvider.permissions.getPermission(node.path, this);
        int maxPermit = Permission.parse_A(m['permit']);
        if (maxPermit < permission) {
          permission = maxPermit;
        }
        if (node.getSetPermission() <= permission) {
          node.setValue(value_A, this, addResponse(new Response_A(this, rid)));
        } else {
          closeResponse(m['rid'], error: DSError.PERMISSION_DENIED);
        }
        closeResponse(m['rid']);
      }, (e, stack) {
        var error_A = new DSError("nodeError", msg: e.toString(), detail: stack.toString());
        closeResponse(m['rid'], error: error_A);
      });
    } else if (path_A.isConfig) {
      LocalNode node;
      node = nodeProvider.getOrCreateNode(path_A.parentPath, false);
      int permission = nodeProvider.permissions.getPermission(node.path, this);
      if (permission < Permission.CONFIG) {
        closeResponse(m['rid'], error: DSError.PERMISSION_DENIED);
      } else {
        node.setConfig(path_A.name, value_A, this, addResponse(new Response_A(this, rid)));
      }
    } else if (path_A.isAttribute) {
      LocalNode node;
      node = nodeProvider.getOrCreateNode(path_A.parentPath, false);
      int permission = nodeProvider.permissions.getPermission(node.path, this);
      if (permission < Permission.WRITE_A) {
        closeResponse(m['rid'], error: DSError.PERMISSION_DENIED);
      } else {
        node.setAttribute(path_A.name, value_A, this, addResponse(new Response_A(this, rid)));
      }
    } else {
      throw 'unexpected case';
    }
  }
  void remove(Map m) {
    Path path_A = Path.getValidPath(m['path']);
    if (path_A == null || !path_A.isAbsolute) {
      closeResponse(m['rid'], error: DSError.INVALID_PATH);
      return;
    }
    int rid = m['rid'];
    if (path_A.isNode) {
      closeResponse(m['rid'], error: DSError.INVALID_METHOD);
    } else if (path_A.isConfig) {
      LocalNode node;
      node = nodeProvider.getOrCreateNode(path_A.parentPath, false);
      int permission = nodeProvider.permissions.getPermission(node.path, this);
      if (permission < Permission.CONFIG) {
        closeResponse(m['rid'], error: DSError.PERMISSION_DENIED);
      } else {
        node.removeConfig(path_A.name, this, addResponse(new Response_A(this, rid)));
      }
    } else if (path_A.isAttribute) {
      LocalNode node;
      node = nodeProvider.getOrCreateNode(path_A.parentPath, false);
      int permission = nodeProvider.permissions.getPermission(node.path, this);
      if (permission < Permission.WRITE_A) {
        closeResponse(m['rid'], error: DSError.PERMISSION_DENIED);
      } else {
        node.removeAttribute(path_A.name, this, addResponse(new Response_A(this, rid)));
      }
    } else {
      throw 'unexpected case';
    }
  }
  void close(Map m) {
    if (m['rid'] is int) {
      int rid = m['rid'];
      if (_responses.containsKey(rid)) {
        _responses[rid]._close_B();
        Response_A resp = _responses.remove(rid);
        if (_traceCallbacks != null) {
          traceResponseRemoved(resp);
        }
      }
    }
  }
  void onDisconnected() {
    clearProcessors();
    _responses.forEach((id_A, resp) {
      resp._close_B();
    });
    _responses.clear();
    _responses[0] = _subscription_B;
  }
  void onReconnected() {
    super.onReconnected();
  }
  List<ResponseTraceCallback> _traceCallbacks;
}
class Response_A implements ConnectionProcessor {
  final Responder responder;
  final int rid;
  String _sentStreamStatus = StreamStatus.initialize;
  Response_A(this.responder, this.rid);
  void close([DSError err = null]) {
    _sentStreamStatus = StreamStatus.closed_A;
    responder.closeResponse(rid, error: err, response: this);
  }
  void _close_B() {}
  void prepareSending() {
    if (!_pendingSending_A) {
      _pendingSending_A = true;
      responder.addProcessor(this);
    }
  }
  bool _pendingSending_A = false;
  void startSendingData(int currentTime, int waitingAckId) {
    _pendingSending_A = false;
  }
  void ackReceived(int receiveAckId, int startTime, int currentTime) {}
  ResponseTrace getTraceData([String change_A = '+']) {
    return null;
  }
}
typedef void OnInvokeClosed(InvokeResponse _0);
typedef void OnInvokeSend(InvokeResponse _0, Map _1);
typedef bool OnReqParams(InvokeResponse _0, Map _1);
class _InvokeResponseUpdate {
  String status;
  List columns;
  List updates;
  Map meta;
  _InvokeResponseUpdate(this.status, this.updates, this.columns, this.meta);
}
class InvokeResponse extends Response_A {
  final LocalNode parentNode;
  final LocalNode node;
  final String name;
  InvokeResponse(Responder responder, int rid, this.parentNode, this.node, this.name) : super(responder, rid);
  List<_InvokeResponseUpdate> pendingData = new List<_InvokeResponseUpdate>();
  bool _hasSentColumns = false;
  void updateStream(List updates, {List columns, String streamStatus: StreamStatus.open_A, Map meta, bool autoSendColumns: true}) {
    if (meta != null && meta['mode'] == 'refresh') {
      pendingData.length = 0;
    }
    if (!_hasSentColumns) {
      if (columns == null && autoSendColumns && node != null && node.configs[r"$columns"] is List) {
        columns = node.configs[r"$columns"];
      }
    }
    if (columns != null) {
      _hasSentColumns = true;
    }
    pendingData.add(new _InvokeResponseUpdate(streamStatus, updates, columns, meta));
    prepareSending();
  }
  OnReqParams onReqParams;
  void updateReqParams(Map m) {
    if (onReqParams != null) {
      onReqParams(this, m);
    }
  }
  void startSendingData(int currentTime, int waitingAckId) {
    _pendingSending_A = false;
    if (_err != null) {
      responder.closeResponse(rid, response: this, error: _err);
      if (_sentStreamStatus == StreamStatus.closed_A) {
        _close_B();
      }
      return;
    }
    for (_InvokeResponseUpdate update_B in pendingData) {
      List<Map<String, dynamic>> outColumns;
      if (update_B.columns != null) {
        outColumns = TableColumn.serializeColumns(update_B.columns);
      }
      responder.updateResponse(this, update_B.updates, streamStatus: update_B.status, columns: outColumns, meta: update_B.meta, handleMap: (m) {
        if (onSendUpdate != null) {
          onSendUpdate(this, m);
        }
      });
      if (_sentStreamStatus == StreamStatus.closed_A) {
        _close_B();
        break;
      }
    }
    pendingData.length = 0;
  }
  void close([DSError err = null]) {
    if (err != null) {
      _err = err;
    }
    if (!pendingData.isEmpty) {
      pendingData.last.status = StreamStatus.closed_A;
    } else {
      pendingData.add(new _InvokeResponseUpdate(StreamStatus.closed_A, null, null, null));
      prepareSending();
    }
  }
  DSError _err;
  OnInvokeClosed onClose;
  OnInvokeSend onSendUpdate;
  void _close_B() {
    if (onClose != null) {
      onClose(this);
    }
  }
  ResponseTrace getTraceData([String change_A = '+']) {
    return new ResponseTrace(parentNode.path, 'invoke', rid, change_A, name);
  }
}
class ListResponse extends Response_A {
  final LocalNode node;
  StreamSubscription _nodeChangeListener;
  int _permission;
  ListResponse(Responder responder, int rid, this.node) : super(responder, rid) {
    _permission = responder.nodeProvider.permissions.getPermission(node.path, responder);
    _nodeChangeListener = node.listStream.listen(changed);
    if (node.listReady) {
      prepareSending();
    } else if (node.disconnected != null) {
      prepareSending();
    }
  }
  LinkedHashSet<String> changes = new LinkedHashSet<String>();
  bool initialResponse = true;
  void changed(String key_A) {
    if (_permission == Permission.NONE_B) {
      return;
    }
    if (key_A.startsWith(r'$$')) {
      if (_permission < Permission.CONFIG) {
        return;
      }
      if (key_A.startsWith(r'$$$')) {
        return;
      }
    }
    if (changes.isEmpty) {
      changes.add(key_A);
      prepareSending();
    } else {
      changes.add(key_A);
    }
  }
  bool _disconnectSent = false;
  void startSendingData(int currentTime, int waitingAckId) {
    _pendingSending_A = false;
    if (waitingAckId != -1) {
      _waitingAckCount_A++;
      _lastWatingAckId_A = waitingAckId;
    }
    Object updateIs;
    Object updateBase;
    List updateConfigs = [];
    List updateAttributes = [];
    List updateChildren = [];
    if (node.disconnected != null) {
      responder.updateResponse(this, [[r'$disconnectedTs', node.disconnected]], streamStatus: StreamStatus.open_A);
      _disconnectSent = true;
      changes.clear();
      return;
    } else if (_disconnectSent && !changes.contains(r'$disconnectedTs')) {
      _disconnectSent = false;
      updateConfigs.add({'name': r'$disconnectedTs', 'change': 'remove'});
      if (node.configs.containsKey(r'$disconnectedTs')) {
        node.configs.remove(r'$disconnectedTs');
      }
    }
    if (initialResponse || changes.contains(r'$is')) {
      initialResponse = false;
      if (_permission == Permission.NONE_B) {
        return;
      } else {
        node.configs.forEach((name_A, value_A) {
          Object update_B = [name_A, value_A];
          if (name_A == r'$is') {
            updateIs = update_B;
          } else if (name_A == r'$base') {
            updateBase = update_B;
          } else if (name_A.startsWith(r'$$')) {
            if (_permission == Permission.CONFIG && !name_A.startsWith(r'$$$')) {
              updateConfigs.add(update_B);
            }
          } else {
            if (_permission != Permission.CONFIG) {
              if (name_A == r'$writable') {
                if (_permission < Permission.WRITE_A) {
                  return;
                }
              }
              if (name_A == r'$invokable') {
                int invokePermission = Permission.parse_A(node.getConfig_A(r'$invokable'));
                if (invokePermission > _permission) {
                  updateConfigs.add([r'$invokable', 'never']);
                  return;
                }
              }
            }
            updateConfigs.add(update_B);
          }
        });
        node.attributes.forEach((name_A, value_A) {
          updateAttributes.add([name_A, value_A]);
        });
        node.children.forEach((name_A, Node value_A) {
          Map simpleMap = value_A.getSimpleMap();
          if (_permission != Permission.CONFIG) {
            int invokePermission = Permission.parse_A(simpleMap[r'$invokable']);
            if (invokePermission != Permission.NEVER && invokePermission > _permission) {
              simpleMap[r'$invokable'] = 'never';
            }
          }
          updateChildren.add([name_A, simpleMap]);
        });
      }
      if (updateIs == null) {
        updateIs = [r'$is', 'node'];
      }
    } else {
      for (String change_A in changes) {
        Object update_B;
        if (change_A.startsWith(r'$')) {
          if (_permission != Permission.CONFIG) {
            if (change_A == r'$writable') {
              if (_permission < Permission.WRITE_A) {
                continue;
              }
            }
            if (change_A == r'$invokable') {
              int invokePermission = Permission.parse_A(node.getConfig_A(r'$invokable'));
              if (invokePermission > _permission) {
                updateConfigs.add([r'$invokable', 'never']);
                continue;
              }
            }
          }
          if (node.configs.containsKey(change_A)) {
            update_B = [change_A, node.configs[change_A]];
          } else {
            update_B = {'name': change_A, 'change': 'remove'};
          }
          if (_permission == Permission.CONFIG || !change_A.startsWith(r'$$')) {
            updateConfigs.add(update_B);
          }
        } else if (change_A.startsWith(r'@')) {
          if (node.attributes.containsKey(change_A)) {
            update_B = [change_A, node.attributes[change_A]];
          } else {
            update_B = {'name': change_A, 'change': 'remove'};
          }
          updateAttributes.add(update_B);
        } else {
          if (node.children.containsKey(change_A)) {
            Map simpleMap = node.children[change_A].getSimpleMap();
            if (_permission != Permission.CONFIG) {
              int invokePermission = Permission.parse_A(simpleMap[r'$invokable']);
              if (invokePermission != Permission.NEVER && invokePermission > _permission) {
                simpleMap[r'$invokable'] = 'never';
              }
            }
            update_B = [change_A, simpleMap];
          } else {
            update_B = {'name': change_A, 'change': 'remove'};
          }
          updateChildren.add(update_B);
        }
      }
    }
    changes.clear();
    List updates = [];
    if (updateBase != null) {
      updates.add(updateBase);
    }
    if (updateIs != null) {
      updates.add(updateIs);
    }
    updates
        ..addAll(updateConfigs)
        ..addAll(updateAttributes)
        ..addAll(updateChildren);
    responder.updateResponse(this, updates, streamStatus: StreamStatus.open_A);
  }
  int _waitingAckCount_A = 0;
  int _lastWatingAckId_A = -1;
  void ackReceived(int receiveAckId, int startTime, int currentTime) {
    if (receiveAckId == _lastWatingAckId_A) {
      _waitingAckCount_A = 0;
    } else {
      _waitingAckCount_A--;
    }
    if (_sendingAfterAck_A) {
      _sendingAfterAck_A = false;
      prepareSending();
    }
  }
  bool _sendingAfterAck_A = false;
  void prepareSending() {
    if (_sendingAfterAck_A) {
      return;
    }
    if (_waitingAckCount_A > ConnectionProcessor.ACK_WAIT_COUNT) {
      _sendingAfterAck_A = true;
      return;
    }
    if (!_pendingSending_A) {
      _pendingSending_A = true;
      responder.addProcessor(this);
    }
  }
  void _close_B() {
    _nodeChangeListener.cancel();
  }
  ResponseTrace getTraceData([String change_A = '+']) {
    return new ResponseTrace(node.path, 'list', rid, change_A, null);
  }
}
class RespSubscribeListener {
  ValueUpdateCallback callback;
  LocalNode node;
  RespSubscribeListener(this.node, this.callback);
  void cancel() {
    if (callback != null) {
      node.unsubscribe(callback);
      callback = null;
    }
  }
}
class SubscribeResponse extends Response_A {
  SubscribeResponse(Responder responder, int rid) : super(responder, rid);
  final Map<String, RespSubscribeController> subscriptions = new Map<String, RespSubscribeController>();
  final Map<int, RespSubscribeController> subsriptionids = new Map<int, RespSubscribeController>();
  final LinkedHashSet<RespSubscribeController> changed = new LinkedHashSet<RespSubscribeController>();
  RespSubscribeController add(String path_A, LocalNode node, int sid, int qos) {
    RespSubscribeController controller_A;
    if (subscriptions[path_A] != null) {
      controller_A = subscriptions[path_A];
      if (controller_A.sid != sid) {
        if (controller_A.sid >= 0) {
          subsriptionids.remove(controller_A.sid);
        }
        controller_A.sid = sid;
        if (sid >= 0) {
          subsriptionids[sid] = controller_A;
        }
      }
      controller_A.qosLevel = qos;
      if (sid > -1 && controller_A.lastValue != null) {
        subscriptionChanged(controller_A);
      }
    } else {
      int permission = responder.nodeProvider.permissions.getPermission(node.path, responder);
      controller_A = new RespSubscribeController(this, node, sid, permission >= Permission.READ_A, qos);
      subscriptions[path_A] = controller_A;
      if (sid >= 0) {
        subsriptionids[sid] = controller_A;
      }
      if (responder._traceCallbacks != null) {
        ResponseTrace update_B = new ResponseTrace(path_A, 'subscribe', 0, '+');
        for (ResponseTraceCallback callback_A in responder._traceCallbacks) {
          callback_A(update_B);
        }
      }
    }
    return controller_A;
  }
  void remove(int sid) {
    if (subsriptionids[sid] != null) {
      RespSubscribeController controller_A = subsriptionids[sid];
      subsriptionids[sid].destroy();
      subsriptionids.remove(sid);
      subscriptions.remove(controller_A.node.path);
      if (responder._traceCallbacks != null) {
        ResponseTrace update_B = new ResponseTrace(controller_A.node.path, 'subscribe', 0, '-');
        for (ResponseTraceCallback callback_A in responder._traceCallbacks) {
          callback_A(update_B);
        }
      }
    }
  }
  void subscriptionChanged(RespSubscribeController controller_A) {
    changed.add(controller_A);
    prepareSending();
  }
  void startSendingData(int currentTime, int waitingAckId) {
    _pendingSending_A = false;
    if (waitingAckId != -1) {
      _waitingAckCount_A++;
      _lastWaitingAckId = waitingAckId;
    }
    List updates = new List();
    for (RespSubscribeController controller_A in changed) {
      updates.addAll(controller_A.process(waitingAckId));
    }
    responder.updateResponse(this, updates);
    changed.clear();
  }
  int _waitingAckCount_A = 0;
  int _lastWaitingAckId = -1;
  void ackReceived(int receiveAckId, int startTime, int currentTime) {
    if (receiveAckId == _lastWaitingAckId) {
      _waitingAckCount_A = 0;
    } else {
      _waitingAckCount_A--;
    }
    subscriptions.forEach((String path_A, RespSubscribeController controller_A) {
      if (controller_A._qosLevel > 0) {
        controller_A.onAck(receiveAckId);
      }
    });
    if (_sendingAfterAck_A) {
      _sendingAfterAck_A = false;
      prepareSending();
    }
  }
  bool _sendingAfterAck_A = false;
  void prepareSending() {
    if (_sendingAfterAck_A) {
      return;
    }
    if (_waitingAckCount_A > ConnectionProcessor.ACK_WAIT_COUNT) {
      _sendingAfterAck_A = true;
      return;
    }
    if (responder.connection == null) {
      return;
    }
    if (!_pendingSending_A) {
      _pendingSending_A = true;
      responder.addProcessor(this);
    }
  }
  void _close_B() {
    List pendingControllers;
    subscriptions.forEach((path_A, RespSubscribeController controller_A) {
      if (controller_A._qosLevel == 0) {
        controller_A.destroy();
      } else {
        controller_A.sid = -1;
        if (pendingControllers == null) {
          pendingControllers = new List();
        }
        pendingControllers.add(controller_A);
      }
    });
    subscriptions.clear();
    if (pendingControllers != null) {
      for (RespSubscribeController controller_A in pendingControllers) {
        subscriptions[controller_A.node.path] = controller_A;
      }
    }
    subsriptionids.clear();
    _waitingAckCount_A = 0;
    _lastWaitingAckId = -1;
    _sendingAfterAck_A = false;
  }
}
class RespSubscribeController {
  final LocalNode node;
  final SubscribeResponse response;
  RespSubscribeListener _listener;
  int sid;
  bool _permitted = true;
  List<ValueUpdate> lastValues = new List<ValueUpdate>();
  ListQueue<ValueUpdate> waitingValues;
  ValueUpdate lastValue;
  int _qosLevel = -1;
  ISubscriptionNodeStorage _storage;
  void set qosLevel(int v) {
    if (v < 0 || v > 3) v = 0;
    if (_qosLevel == v) return;
    _qosLevel = v;
    if (waitingValues == null && _qosLevel > 0) {
      waitingValues = new ListQueue<ValueUpdate>();
    }
    caching = (v & 1) == 1;
    persist = (v & 2) == 2;
  }
  bool _caching = false;
  void set caching(bool val) {
    if (val == _caching) return;
    _caching = val;
    if (!_caching) {
      lastValues.length = 0;
    }
  }
  bool _persist = false;
  void set persist(bool val) {
    if (val == _persist) return;
    _persist = val;
    ISubscriptionResponderStorage storageM = response.responder.storage;
    if (storageM != null) {
      if (_persist) {
        _storage = storageM.getOrCreateValue(node.path);
      } else if (_storage != null) {
        storageM.destroyValue(node.path);
        _storage = null;
      }
    }
  }
  RespSubscribeController(this.response, this.node, this.sid, this._permitted, int qos) {
    this.qosLevel = qos;
    _listener = node.subscribe(addValue, _qosLevel);
    if (node.valueReady && node.lastValueUpdate != null) {
      addValue(node.lastValueUpdate);
    }
  }
  bool _isCacheValid = true;
  void addValue(ValueUpdate val) {
    if (_caching && _isCacheValid) {
      lastValues.add(val);
      if (lastValues.length > response.responder.maxCacheLength) {
        _isCacheValid = false;
        lastValue = new ValueUpdate(null, ts: '');
        for (ValueUpdate update_B in lastValues) {
          lastValue.mergeAdd(update_B);
        }
        lastValues.length = 0;
        if (_qosLevel > 0) {
          if (_storage != null) {
            _storage.setValue(waitingValues, lastValue);
          }
          waitingValues
              ..clear()
              ..add(lastValue);
        }
      } else {
        lastValue = val;
        if (_qosLevel > 0) {
          waitingValues.add(lastValue);
          if (_storage != null) {
            _storage.addValue(lastValue);
          }
        }
      }
    } else {
      if (lastValue != null) {
        lastValue = new ValueUpdate.merge(lastValue, val);
      } else {
        lastValue = val;
      }
      if (_qosLevel > 0) {
        if (_storage != null) {
          _storage.setValue(waitingValues, lastValue);
        }
        waitingValues
            ..clear()
            ..add(lastValue);
      }
    }
    if (_permitted && sid > -1) {
      response.subscriptionChanged(this);
    }
  }
  List process(int waitingAckId) {
    List rslts = new List();
    if (_caching && _isCacheValid) {
      for (ValueUpdate lastValue_A in lastValues) {
        rslts.add([sid, lastValue_A.value, lastValue_A.ts]);
      }
      if (_qosLevel > 0) {
        for (ValueUpdate update_B in lastValues) {
          update_B.waitingAck = waitingAckId;
        }
      }
      lastValues.length = 0;
    } else {
      if (lastValue.count > 1 || lastValue.status != null) {
        Map m = lastValue.toMap();
        m['sid'] = sid;
        rslts.add(m);
      } else {
        rslts.add([sid, lastValue.value, lastValue.ts]);
      }
      if (_qosLevel > 0) {
        lastValue.waitingAck = waitingAckId;
      }
      _isCacheValid = true;
    }
    lastValue = null;
    return rslts;
  }
  void onAck(int ackId) {
    if (waitingValues.isEmpty) {
      return;
    }
    bool valueRemoved = false;
    if (!waitingValues.isEmpty && waitingValues.first.waitingAck != ackId) {
      ValueUpdate matchUpdate;
      for (ValueUpdate update_B in waitingValues) {
        if (update_B.waitingAck == ackId) {
          matchUpdate = update_B;
          break;
        }
      }
      if (matchUpdate != null) {
        while (!waitingValues.isEmpty && waitingValues.first != matchUpdate) {
          ValueUpdate removed = waitingValues.removeFirst();
          if (_storage != null) {
            _storage.removeValue(removed);
            valueRemoved = true;
          }
        }
      }
    }
    while (!waitingValues.isEmpty && waitingValues.first.waitingAck == ackId) {
      ValueUpdate removed = waitingValues.removeFirst();
      if (_storage != null) {
        _storage.removeValue(removed);
        valueRemoved = true;
      }
    }
    if (valueRemoved && _storage != null) {
      _storage.valueRemoved(waitingValues);
    }
  }
  void destroy() {
    if (_storage != null) {
      ISubscriptionResponderStorage storageM = response.responder.storage;
      storageM.destroyValue(node.path);
      _storage = null;
    }
    _listener.cancel();
  }
}
typedef LocalNode NodeFactory(String _0);
typedef SimpleNode SimpleNodeFactory(String _0);
class SimpleTableResult {}
abstract class WaitForMe {}
class AsyncTableResult {
  InvokeResponse response;
  List columns;
  List rows;
  String status = StreamStatus.open_A;
  Map meta;
  OnInvokeClosed onClose;
  AsyncTableResult([this.columns]);
  void update(List rows_A, [String stat_A, Map meta_A]) {
    if (this.rows == null) {
      this.rows = rows_A;
    } else {
      this.rows.addAll(rows_A);
    }
    this.meta = meta_A;
    if (stat_A != null) {
      status = stat_A;
    }
    if (response == null) {
      new Future(write);
    } else {
      write();
    }
  }
  void write([InvokeResponse resp]) {
    if (resp != null) {
      if (response == null) {
        response = resp;
      } else {
        logger.warning("can not use same AsyncTableResult twice");
      }
    }
    if (response != null && (rows != null || meta != null || status == StreamStatus.closed_A)) {
      response.updateStream(rows, columns: columns, streamStatus: status, meta: meta);
      rows = null;
      columns = null;
    }
  }
  void close() {
    if (response != null) {
      response.close();
    } else {
      status = StreamStatus.closed_A;
    }
  }
}
class LiveTable {}
abstract class SerializableNodeProvider {}
abstract class MutableNodeProvider {}
class SimpleNodeProvider extends NodeProviderImpl implements SerializableNodeProvider, MutableNodeProvider {
  static SimpleNodeProvider instance_A;
  ExecutableFunction _persist;
  final Map<String, LocalNode> nodes = new Map<String, LocalNode>();
  List<SimpleNodeFactory> _resolverFactories = [];
  LocalNode getNode(String path_A) {
    return _getNode(path_A);
  }
  LocalNode _getNode(String path_A, {bool allowStubs: false}) {
    if (nodes.containsKey(path_A)) {
      SimpleNode node = nodes[path_A];
      if (allowStubs || node._stub == false) {
        return node;
      }
    }
    if (_resolverFactories.isNotEmpty) {
      for (var f in _resolverFactories) {
        var node = f(path_A);
        if (node != null) {
          return node;
        }
      }
    }
    return null;
  }
  LocalNode getOrCreateNode(String path_A, [bool addToTree = true, bool init_A = true]) {
    LocalNode node = _getNode(path_A, allowStubs: true);
    if (node != null) {
      if (addToTree) {
        Path po = new Path(path_A);
        if (!po.isRoot) {
          LocalNode parent_A = getNode(po.parentPath);
          if (parent_A != null && !parent_A.children.containsKey(po.name)) {
            parent_A.addChild(po.name, node);
            parent_A.listChangeController.add(po.name);
            node.listChangeController.add(r"$is");
          }
        }
        if (node is SimpleNode) {
          node._stub = false;
        }
      }
      return node;
    }
    if (addToTree) {
      return createNode(path_A, init_A);
    } else {
      node = new SimpleNode(path_A, this)
          .._stub = true;
      nodes[path_A] = node;
      return node;
    }
  }
  void setPersistFunction(ExecutableFunction doPersist) {
    _persist = doPersist;
  }
  void persist([bool now_A = false]) {
    if (now_A) {
      if (_persist == null) {
        return;
      }
      _persist();
    } else {
      new Future.delayed(const Duration(seconds: 5), () {
        if (_persist == null) {
          return;
        }
        _persist();
      });
    }
  }
  SimpleNode createNode(String path_A, [bool init_A = true]) {
    Path p = new Path(path_A);
    LocalNode existing = nodes[path_A];
    if (existing != null) {
      if (existing is SimpleNode) {
        if (existing._stub != true) {
          throw new Exception("Node at ${path_A} already exists.");
        } else {
          existing._stub = false;
        }
      } else {
        throw new Exception("Node at ${path_A} already exists.");
      }
    }
    SimpleNode node = existing == null ? new SimpleNode(path_A, this) : existing;
    nodes[path_A] = node;
    if (init_A) {
      node.onCreated();
    }
    SimpleNode pnode;
    if (p.parentPath != "") {
      pnode = getNode(p.parentPath);
    }
    if (pnode != null) {
      pnode.children[p.name] = node;
      pnode.onChildAdded(p.name, node);
      pnode.updateList(p.name);
    }
    return node;
  }
  SimpleNodeProvider([Map<String, dynamic> m, Map<String, NodeFactory> profiles_A]) {
    if (instance_A == null) {
      instance_A = this;
    }
    root_A = new SimpleNode("/", this);
    nodes["/"] = root_A;
    defs = new SimpleHiddenNode('/defs', this);
    nodes[defs.path] = defs;
    sys = new SimpleHiddenNode('/sys', this);
    nodes[sys.path] = sys;
    init(m, profiles_A);
  }
  SimpleNode root_A;
  SimpleHiddenNode defs;
  SimpleHiddenNode sys;
  void init([Map<String, dynamic> m, Map<String, NodeFactory> profiles_A]) {
    if (profiles_A != null) {
      if (profiles_A.isNotEmpty) {
        _profiles.addAll(profiles_A);
      } else {
        _profiles = profiles_A;
      }
    }
    if (m != null) {
      root_A.load(m);
    }
  }
  Map save() {
    return root_A.save();
  }
  void updateValue(String path_A, Object value_A) {
    SimpleNode node = getNode(path_A);
    node.updateValue(value_A);
  }
  SimpleNode addNode(String path_A, Map m) {
    if (path_A == '/' || !path_A.startsWith('/')) return null;
    Path p = new Path(path_A);
    SimpleNode oldNode = _getNode(path_A, allowStubs: true);
    SimpleNode pnode = getNode(p.parentPath);
    SimpleNode node;
    if (pnode != null) {
      node = pnode.onLoadChild(p.name, m, this);
    }
    if (node == null) {
      String profile = m[r'$is'];
      if (_profiles.containsKey(profile)) {
        node = _profiles[profile](path_A);
      } else {
        node = getOrCreateNode(path_A, true, false);
      }
    }
    if (oldNode != null) {
      logger.fine("Found old node for ${path_A}: Copying subscriptions.");
      for (ValueUpdateCallback func in oldNode.callbacks.keys) {
        node.subscribe(func, oldNode.callbacks[func]);
      }
      if (node is SimpleNode) {
        try {
          node._listChangeController = oldNode._listChangeController;
        } catch (e) {}
        if (node._hasListListener) {
          node.onStartListListen();
        }
      }
    }
    nodes[path_A] = node;
    node.load(m);
    node.onCreated();
    if (pnode != null) {
      pnode.addChild(p.name, node);
      pnode.onChildAdded(p.name, node);
      pnode.updateList(p.name);
    }
    node.updateList(r"$is");
    if (oldNode != null) {
      oldNode.updateList(r"$is");
    }
    return node;
  }
  void removeNode(String path_A, {bool recurse: true}) {
    if (path_A == '/' || !path_A.startsWith('/')) return;
    SimpleNode node = getNode(path_A);
    if (node == null) {
      return;
    }
    if (recurse) {
      String base_A = path_A;
      if (!base_A.endsWith("/")) {
        base_A += "/";
      }
      int baseSlashFreq = countCharacterFrequency(base_A, "/");
      List<String> targets_A = nodes.keys.where((String x_A) {
        return x_A.startsWith(base_A) && baseSlashFreq == countCharacterFrequency(x_A, "/");
      }).toList();
      for (String target_A in targets_A) {
        removeNode(target_A);
      }
    }
    Path p = new Path(path_A);
    SimpleNode pnode = getNode(p.parentPath);
    node.onRemoving();
    node.removed = true;
    if (pnode != null) {
      pnode.children.remove(p.name);
      pnode.onChildRemoved(p.name, node);
      pnode.updateList(p.name);
    }
    if (node.callbacks.isEmpty) {
      nodes.remove(path_A);
    } else {
      node._stub = true;
    }
  }
  Map<String, NodeFactory> _profiles = new Map<String, NodeFactory>();
  IPermissionManager permissions = new DummyPermissionManager();
  String toString({bool showInstances: false}) {
    var buff = new StringBuffer();
    void doNode(LocalNode node, [int depth = 0]) {
      Path p = new Path(node.path);
      buff.write("${'  ' * depth}- ${p.name}");
      if (showInstances) {
        buff.write(": ${node}");
      }
      buff.writeln();
      for (var child in node.children.values) {
        doNode(child, depth + 1);
      }
    }
    doNode(root_A);
    return buff.toString().trim();
  }
}
class SimpleNode extends LocalNodeImpl {
  final SimpleNodeProvider provider;
  bool _stub = false;
  SimpleNode(String path_A, [SimpleNodeProvider nodeprovider]) : provider = nodeprovider == null ? SimpleNodeProvider.instance_A : nodeprovider, super(path_A);
  bool removed = false;
  bool serializable = true;
  void load(Map m) {
    if (_loaded) {
      configs.clear();
      attributes.clear();
      children.clear();
    }
    String childPathPre;
    if (path == '/') {
      childPathPre = '/';
    } else {
      childPathPre = '${path}/';
    }
    m.forEach((String key_A, value_A) {
      if (key_A.startsWith('?')) {
        if (key_A == '?value') {
          updateValue(value_A);
        }
      } else if (key_A.startsWith(r'$')) {
        configs[key_A] = value_A;
      } else if (key_A.startsWith('@')) {
        attributes[key_A] = value_A;
      } else if (value_A is Map) {
        String childPath = '${childPathPre}${key_A}';
        provider.addNode(childPath, value_A);
      }
    });
    _loaded = true;
  }
  Map save() {
    Map rslt = {};
    configs.forEach((str, val) {
      rslt[str] = val;
    });
    attributes.forEach((str, val) {
      rslt[str] = val;
    });
    if (_lastValueUpdate != null && _lastValueUpdate.value != null) {
      rslt['?value'] = _lastValueUpdate.value;
    }
    children.forEach((str, Node node) {
      if (node is SimpleNode && node.serializable == true) {
        rslt[str] = node.save();
      }
    });
    return rslt;
  }
  InvokeResponse invoke(Map<String, dynamic> params, Responder responder, InvokeResponse response_B, Node parentNode, [int maxPermission = Permission.CONFIG]) {
    Object rslt;
    try {
      rslt = onInvoke(params);
    } catch (e, stack) {
      var error_A = new DSError("invokeException", msg: e.toString());
      try {
        error_A.detail = stack.toString();
      } catch (e) {}
      response_B.close(error_A);
      return response_B;
    }
    var rtype = "values";
    if (configs.containsKey(r"$result")) {
      rtype = configs[r"$result"];
    }
    if (rslt == null) {
      if (rtype == "values") {
        rslt = {};
      } else if (rtype == "table") {
        rslt = [];
      } else if (rtype == "stream") {
        rslt = [];
      }
    }
    if (rslt is Iterable) {
      response_B.updateStream(rslt.toList(), streamStatus: StreamStatus.closed_A);
    } else if (rslt is Map) {
      var columns = [];
      var out = [];
      for (var x_A in rslt.keys) {
        columns.add({"name": x_A, "type": "dynamic"});
        out.add(rslt[x_A]);
      }
      response_B.updateStream([out], columns: columns, streamStatus: StreamStatus.closed_A);
    } else if (rslt is SimpleTableResult) {
      response_B.updateStream(rslt.rows, columns: rslt.columns, streamStatus: StreamStatus.closed_A);
    } else if (rslt is AsyncTableResult) {
      (rslt as AsyncTableResult).write(response_B);
      response_B.onClose = (var response_B) {
        if ((rslt as AsyncTableResult).onClose != null) {
          (rslt as AsyncTableResult).onClose(response_B);
        }
      };
      return response_B;
    } else if (rslt is Table) {
      response_B.updateStream(rslt.rows, columns: rslt.columns, streamStatus: StreamStatus.closed_A);
    } else if (rslt is Stream) {
      var r = new AsyncTableResult();
      response_B.onClose = (var response_B) {
        if (r.onClose != null) {
          r.onClose(response_B);
        }
      };
      Stream stream_A = rslt;
      if (rtype == "stream") {
        StreamSubscription sub;
        r.onClose = (__I) {
          if (sub != null) {
            sub.cancel();
          }
        };
        sub = stream_A.listen((v) {
          if (v is TableMetadata) {
            r.meta = v.meta;
            return;
          } else if (v is TableColumns) {
            r.columns = v.columns.map((x_A) => x_A.getData()).toList();
            return;
          }
          if (v is Iterable) {
            r.update(v.toList(), StreamStatus.open_A);
          } else if (v is Map) {
            var meta_A;
            if (v.containsKey("__META__")) {
              meta_A = v["__META__"];
            }
            r.update([v], StreamStatus.open_A, meta_A);
          } else {
            throw new Exception("Unknown Value from Stream");
          }
        }, onDone: () {
          r.close();
        }, onError: (e, stack) {
          var error_A = new DSError("invokeException", msg: e.toString());
          try {
            error_A.detail = stack.toString();
          } catch (e) {}
          response_B.close(error_A);
        }, cancelOnError: true);
        r.write(response_B);
        return response_B;
      } else {
        var list_A = [];
        StreamSubscription sub;
        r.onClose = (__I) {
          if (sub != null) {
            sub.cancel();
          }
        };
        sub = stream_A.listen((v) {
          if (v is TableMetadata) {
            r.meta = v.meta;
            return;
          } else if (v is TableColumns) {
            r.columns = v.columns.map((x_A) => x_A.getData()).toList();
            return;
          }
          if (v is Iterable) {
            list_A.addAll(v);
          } else if (v is Map) {
            list_A.add(v);
          } else {
            throw new Exception("Unknown Value from Stream");
          }
        }, onDone: () {
          r.update(list_A);
          r.close();
        }, onError: (e, stack) {
          var error_A = new DSError("invokeException", msg: e.toString());
          try {
            error_A.detail = stack.toString();
          } catch (e) {}
          response_B.close(error_A);
        }, cancelOnError: true);
      }
      r.write(response_B);
      return response_B;
    } else if (rslt is Future) {
      var r = new AsyncTableResult();
      response_B.onClose = (var response_B) {
        if (r.onClose != null) {
          r.onClose(response_B);
        }
      };
      rslt.then((value_A) {
        if (value_A is LiveTable) {
          r = null;
          value_A.sendTo(response_B);
        } else if (value_A is Stream) {
          Stream stream_A = value_A;
          StreamSubscription sub;
          r.onClose = (__I) {
            if (sub != null) {
              sub.cancel();
            }
          };
          sub = stream_A.listen((v) {
            if (v is TableMetadata) {
              r.meta = v.meta;
              return;
            } else if (v is TableColumns) {
              r.columns = v.columns.map((x_A) => x_A.getData()).toList();
              return;
            }
            if (v is Iterable) {
              r.update(v.toList());
            } else if (v is Map) {
              var meta_A;
              if (v.containsKey("__META__")) {
                meta_A = v["__META__"];
              }
              r.update([v], StreamStatus.open_A, meta_A);
            } else {
              throw new Exception("Unknown Value from Stream");
            }
          }, onDone: () {
            r.close();
          }, onError: (e, stack) {
            var error_A = new DSError("invokeException", msg: e.toString());
            try {
              error_A.detail = stack.toString();
            } catch (e) {}
            response_B.close(error_A);
          }, cancelOnError: true);
        } else if (value_A is Table) {
          Table table = value_A;
          r.columns = table.columns.map((x_A) => x_A.getData()).toList();
          r.update(table.rows, StreamStatus.closed_A, table.meta);
          r.close();
        } else {
          r.update(value_A is Iterable ? value_A.toList() : [value_A]);
          r.close();
        }
      }).catchError((e, stack) {
        var error_A = new DSError("invokeException", msg: e.toString());
        try {
          error_A.detail = stack.toString();
        } catch (e) {}
        response_B.close(error_A);
      });
      r.write(response_B);
      return response_B;
    } else if (rslt is LiveTable) {
      rslt.sendTo(response_B);
    } else {
      response_B.close();
    }
    return response_B;
  }
  dynamic onInvoke(Map<String, dynamic> params) {
    return null;
  }
  SimpleNode get parent => provider.getNode(new Path(path).parentPath);
  bool onSetValue(Object val) => false;
  bool onSetConfig(String name_A, String value_A) => false;
  bool onSetAttribute(String name_A, String value_A) => false;
  void onSubscribe() {}
  void onUnsubscribe() {}
  void onCreated() {}
  void onRemoving() {}
  void onChildRemoved(String name_A, Node node) {}
  void onChildAdded(String name_A, Node node) {}
  RespSubscribeListener subscribe(ValueUpdateCallback callback_A, [int qos = 0]) {
    onSubscribe();
    return super.subscribe(callback_A, qos);
  }
  void unsubscribe(ValueUpdateCallback callback_A) {
    onUnsubscribe();
    super.unsubscribe(callback_A);
  }
  SimpleNode onLoadChild(String name_A, Map data_A, SimpleNodeProvider provider_A) {
    return null;
  }
  SimpleNode createChild(String name_A, [Map m]) {
    var tp = new Path(path).child(name_A).path;
    return provider.addNode(tp, m == null ? {} : m);
  }
  String get name => new Path(path).name;
  String get type => configs[r"$type"];
  set type(String value_A) {
    if (value_A == null) {
      configs.remove(r"$type");
    } else {
      configs[r"$type"] = value_A;
    }
    updateList(r"$type");
  }
  void addChild(String name_A, Node node) {
    super.addChild(name_A, node);
    updateList(name_A);
  }
  String removeChild(dynamic input_A) {
    String name_A = super.removeChild(input_A);
    if (name_A != null) {
      updateList(name_A);
    }
    return name_A;
  }
  Response_A setAttribute(String name_A, Object value_A, Responder responder, Response_A response_B) {
    if (onSetAttribute(name_A, value_A) != true) {
      super.setAttribute(name_A, value_A, responder, response_B);
    }
    return response_B;
  }
  Response_A setConfig(String name_A, Object value_A, Responder responder, Response_A response_B) {
    if (onSetConfig(name_A, value_A) != true) {
      super.setConfig(name_A, value_A, responder, response_B);
    }
    return response_B;
  }
  Response_A setValue(Object value_A, Responder responder, Response_A response_B, [int maxPermission = Permission.CONFIG]) {
    if (onSetValue(value_A) != true) super.setValue(value_A, responder, response_B, maxPermission);
    return response_B;
  }
  operator[](String name_A) => get(name_A);
  operator[]=(String name_A, value_A) {
    if (name_A.startsWith(r"$") || name_A.startsWith(r"@")) {
      if (name_A.startsWith(r"$")) {
        configs[name_A] = value_A;
      } else {
        attributes[name_A] = value_A;
      }
    } else {
      if (value_A == null) {
        return removeChild(name_A);
      } else if (value_A is Map) {
        return createChild(name_A, value_A);
      } else {
        addChild(name_A, value_A);
        return value_A;
      }
    }
  }
}
class SimpleHiddenNode extends SimpleNode {
  SimpleHiddenNode(String path_A, SimpleNodeProvider provider_A) : super(path_A, provider_A) {
    configs[r'$hidden'] = true;
  }
  Map<String, dynamic> getSimpleMap() {
    var rslt = <String, dynamic>{r'$hidden': true};
    if (configs.containsKey(r'$is')) {
      rslt[r'$is'] = configs[r'$is'];
    }
    if (configs.containsKey(r'$type')) {
      rslt[r'$type'] = configs[r'$type'];
    }
    if (configs.containsKey(r'$name')) {
      rslt[r'$name'] = configs[r'$name'];
    }
    if (configs.containsKey(r'$invokable')) {
      rslt[r'$invokable'] = configs[r'$invokable'];
    }
    if (configs.containsKey(r'$writable')) {
      rslt[r'$writable'] = configs[r'$writable'];
    }
    return rslt;
  }
}
class Base64 {
  static const int PAD_A = 61;
  static const int CR_A = 13;
  static const int LF_A = 10;
  static const int SP_A = 32;
  static const int PLUS = 43;
  static const int SLASH_A = 47;
  static const String _encodeTable_B = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_";
  static final List<int> _decodeTable_B = (() {
    List<int> table = new List<int>(256);
    table.fillRange(0, 256, -2);
    List<int> charCodes = _encodeTable_B.codeUnits;
    int len = charCodes.length;
    for (int i = 0; i < len; ++i) {
      table[charCodes[i]] = i;
    }
    table[PLUS] = 62;
    table[SLASH_A] = 63;
    table[CR_A] = -1;
    table[LF_A] = -1;
    table[SP_A] = -1;
    table[LF_A] = -1;
    table[PAD_A] = 0;
    return table;
  })();
  static String encode_B(List<int> bytes_A, [int lineSize = 0, int paddingSpace = 0]) {
    int len = bytes_A.length;
    if (len == 0) {
      return "";
    }
    final int remainderLength = len.remainder(3);
    final int chunkLength = len - remainderLength;
    int outputLen = ((len ~/ 3) * 4) + ((remainderLength > 0) ? 4 : 0) + paddingSpace;
    int lineSizeGroup = lineSize >> 2;
    if (lineSizeGroup > 0) {
      outputLen += ((outputLen - 1) ~/ (lineSizeGroup << 2)) * (1 + paddingSpace);
    }
    List<int> out = new List<int>(outputLen);
    int j = 0, i = 0, c = 0;
    for (int i = 0; i < paddingSpace; ++i) {
      out[j++] = SP_A;
    }
    while (i < chunkLength) {
      int x_A = (((bytes_A[i++] % 256) << 16) & 0xFFFFFF) | (((bytes_A[i++] % 256) << 8) & 0xFFFFFF) | (bytes_A[i++] % 256);
      out[j++] = _encodeTable_B.codeUnitAt(x_A >> 18);
      out[j++] = _encodeTable_B.codeUnitAt((x_A >> 12) & 0x3F);
      out[j++] = _encodeTable_B.codeUnitAt((x_A >> 6) & 0x3F);
      out[j++] = _encodeTable_B.codeUnitAt(x_A & 0x3f);
      if (lineSizeGroup > 0 && ++c == lineSizeGroup && j < outputLen - 2) {
        out[j++] = LF_A;
        for (int i = 0; i < paddingSpace; ++i) {
          out[j++] = SP_A;
        }
        c = 0;
      }
    }
    if (remainderLength == 1) {
      int x_A = bytes_A[i] % 256;
      out[j++] = _encodeTable_B.codeUnitAt(x_A >> 2);
      out[j++] = _encodeTable_B.codeUnitAt((x_A << 4) & 0x3F);
      return new String.fromCharCodes(out.sublist(0, outputLen - 2));
    } else if (remainderLength == 2) {
      int x_A = bytes_A[i] % 256;
      int y_A = bytes_A[i + 1] % 256;
      out[j++] = _encodeTable_B.codeUnitAt(x_A >> 2);
      out[j++] = _encodeTable_B.codeUnitAt(((x_A << 4) | (y_A >> 4)) & 0x3F);
      out[j++] = _encodeTable_B.codeUnitAt((y_A << 2) & 0x3F);
      return new String.fromCharCodes(out.sublist(0, outputLen - 1));
    }
    return new String.fromCharCodes(out);
  }
  static Uint8List decode_B(String input_A) {
    if (input_A == null) {
      return null;
    }
    int len = input_A.length;
    if (len == 0) {
      return new Uint8List(0);
    }
    int extrasLen = 0;
    for (int i = 0; i < len; i++) {
      int c = _decodeTable_B[input_A.codeUnitAt(i)];
      if (c < 0) {
        extrasLen++;
        if (c == -2) {
          return null;
        }
      }
    }
    int lenmis = (len - extrasLen) % 4;
    if (lenmis == 2) {
      input_A = '${input_A}==';
      len += 2;
    } else if (lenmis == 3) {
      input_A = '${input_A}=';
      len += 1;
    } else if (lenmis == 1) {
      return null;
    }
    int padLength = 0;
    for (int i = len - 1; i >= 0; i--) {
      int currentCodeUnit = input_A.codeUnitAt(i);
      if (_decodeTable_B[currentCodeUnit] > 0) break;
      if (currentCodeUnit == PAD_A) padLength++;
    }
    int outputLen = (((len - extrasLen) * 6) >> 3) - padLength;
    Uint8List out = new Uint8List(outputLen);
    for (int i = 0, o = 0; o < outputLen;) {
      int x_A = 0;
      for (int j = 4; j > 0;) {
        int c = _decodeTable_B[input_A.codeUnitAt(i++)];
        if (c >= 0) {
          x_A = ((x_A << 6) & 0xFFFFFF) | c;
          j--;
        }
      }
      out[o++] = x_A >> 16;
      if (o < outputLen) {
        out[o++] = (x_A >> 8) & 0xFF;
        if (o < outputLen) out[o++] = x_A & 0xFF;
      }
    }
    return out;
  }
}
typedef Object _Encoder(Object _0);
typedef Object _Reviver_A(String _0, Object _1);
abstract class DsCodec {
  static final Map<String, DsCodec> _codecs = {"json": DsJson.instance_B, "msgpack": DsMsgPackCodecImpl.instance_C};
  static final DsCodec defaultCodec = DsJson.instance_B;
  static DsCodec getCodec(String name_A) {
    DsCodec rslt = _codecs[name_A];
    if (rslt == null) {
      return defaultCodec;
    }
    return rslt;
  }
  Object _blankData;
  Object get blankData {
    if (_blankData == null) {
      _blankData = encodeFrame({});
    }
    return _blankData;
  }
  Object encodeFrame(Map val);
  Map decodeStringFrame(String input_A);
  Map decodeBinaryFrame(List<int> input_A);
}
abstract class DsJson {
  static DsJsonCodecImpl instance_B = new DsJsonCodecImpl();
  static String encode_A(Object val, {bool pretty: false}) {
    return instance_B.encodeJson(val, pretty: pretty);
  }
  static dynamic decode_A(String str) {
    return instance_B.decodeJson(str);
  }
}
class DsJsonCodecImpl extends DsCodec implements DsJson {
  static dynamic _safeEncoder(value_A) {
    return null;
  }
  JsonEncoder encoder = new JsonEncoder(_safeEncoder);
  JsonDecoder decoder = new JsonDecoder();
  JsonEncoder _prettyEncoder;
  dynamic decodeJson(String str) {
    return decoder.convert(str);
  }
  String encodeJson(val, {bool pretty: false}) {
    JsonEncoder e = encoder;
    if (pretty) {
      if (_prettyEncoder == null) {
        _prettyEncoder = encoder = new JsonEncoder.withIndent("  ", _safeEncoder);
      }
      e = _prettyEncoder;
    }
    return e.convert(val);
  }
  JsonDecoder _unsafeDecoder;
  Map decodeBinaryFrame(List<int> bytes_A) {
    return decodeStringFrame(const Utf8Decoder().convert(bytes_A));
  }
  Map decodeStringFrame(String str) {
    if (_reviver_A == null) {
      _reviver_A = (key_A, value_A) {
        if (value_A is String && value_A.startsWith("\u001Bbytes:")) {
          try {
            return ByteDataUtil.fromUint8List(Base64.decode_B(value_A.substring(7)));
          } catch (err) {
            return null;
          }
        }
        return value_A;
      };
    }
    if (_unsafeDecoder == null) {
      _unsafeDecoder = new JsonDecoder(_reviver_A);
    }
    var result_A = _unsafeDecoder.convert(str);
    return result_A;
  }
  _Reviver_A _reviver_A;
  _Encoder _encoder_B;
  Object encodeFrame(Object val) {
    if (_encoder_B == null) {
      _encoder_B = (value_A) {
        if (value_A is ByteData) {
          return "\u001Bbytes:${Base64.encode_B(ByteDataUtil.toUint8List(value_A))}";
        }
        return null;
      };
    }
    JsonEncoder c;
    if (_unsafeEncoder == null) {
      _unsafeEncoder = new JsonEncoder(_encoder_B);
    }
    c = _unsafeEncoder;
    var result_A = c.convert(val);
    return result_A;
  }
  JsonEncoder _unsafeEncoder;
}
class DsMsgPackCodecImpl extends DsCodec {
  static DsMsgPackCodecImpl instance_C = new DsMsgPackCodecImpl();
  Map decodeBinaryFrame(List<int> input_A) {
    Uint8List data_A = ByteDataUtil.list2Uint8List(input_A);
    if (_unpacker == null) {
      _unpacker = new Unpacker(data_A.buffer, data_A.offsetInBytes);
    } else {
      _unpacker.reset(data_A.buffer, 0);
      _unpacker.offset = data_A.offsetInBytes;
    }
    Object rslt = _unpacker.unpack();
    if (rslt is Map) {
      return rslt;
    }
    _unpacker.data = null;
    return {};
  }
  Unpacker _unpacker;
  Map decodeStringFrame(String input_A) {
    return {};
  }
  Object encodeFrame(Map val) {
    return pack(val);
  }
}
class ByteDataUtil {
  static Uint8List list2Uint8List(List<int> input_A) {
    if (input_A is Uint8List) {
      return input_A;
    }
    return new Uint8List.fromList(input_A);
  }
  static ByteData fromUint8List(Uint8List uintsList) {
    return uintsList.buffer.asByteData(uintsList.offsetInBytes, uintsList.lengthInBytes);
  }
  static Uint8List toUint8List(ByteData bytes_A) {
    return bytes_A.buffer.asUint8List(bytes_A.offsetInBytes, bytes_A.lengthInBytes);
  }
}
class BroadcastStreamController<T_A> implements StreamController<T_A> {
  StreamController<T_A> _controller_B;
  CachedStreamWrapper<T_A> _stream_B;
  Stream<T_A> get stream => _stream_B;
  Function _onStartListen;
  Function _onAllCancel_A;
  BroadcastStreamController([void onStartListen(), void onAllCancel(), void onListen_A(callback(T_A value)), bool sync_A = false]) {
    _controller_B = new StreamController<T_A>(sync: sync_A);
    _stream_B = new CachedStreamWrapper(_controller_B.stream.asBroadcastStream(onListen: _onListen_B, onCancel: _onCancel_A), onListen_A);
    _onStartListen = onStartListen;
    _onAllCancel_A = onAllCancel;
  }
  bool _listening = false;
  bool _listenState = false;
  void _onListen_B(StreamSubscription<T_A> subscription_A) {
    if (!_listenState) {
      if (_onStartListen != null) {
        _onStartListen();
      }
      _listenState = true;
    }
    _listening = true;
  }
  void _onCancel_A(StreamSubscription<T_A> subscription_A) {
    _listening = false;
    if (_onAllCancel_A != null) {
      if (!_delayedCheckCanceling) {
        _delayedCheckCanceling = true;
        DsTimer.callLater(delayedCheckCancel);
      }
    } else {
      _listenState = false;
    }
  }
  bool _delayedCheckCanceling = false;
  void delayedCheckCancel() {
    _delayedCheckCanceling = false;
    if (!_listening && _listenState) {
      _onAllCancel_A();
      _listenState = false;
    }
  }
  void add(T_A t) {
    _controller_B.add(t);
    _stream_B.lastValue = t;
  }
  void addError(Object error_A, [StackTrace stackTrace_A]) {
    _controller_B.addError(error_A, stackTrace_A);
  }
  Future addStream(Stream<T_A> source_A, {bool cancelOnError: true}) {
    return _controller_B.addStream(source_A, cancelOnError: cancelOnError);
  }
  Future close() {
    return _controller_B.close();
  }
  Future get done => _controller_B.done;
  bool get hasListener => _controller_B.hasListener;
  bool get isClosed => _controller_B.isClosed;
  bool get isPaused => _controller_B.isPaused;
  StreamSink<T_A> get sink => _controller_B.sink;
  void set onCancel(onCancelHandler()) {
    throw ('BroadcastStreamController.onCancel not implemented');
  }
  void set onListen(void onListenHandler()) {
    throw ('BroadcastStreamController.onListen not implemented');
  }
  void set onPause(void onPauseHandler()) {
    throw ('BroadcastStreamController.onPause not implemented');
  }
  void set onResume(void onResumeHandler()) {
    throw ('BroadcastStreamController.onResume not implemented');
  }
  ControllerCancelCallback get onCancel => null;
  ControllerCallback get onListen => null;
  ControllerCallback get onPause => null;
  ControllerCallback get onResume => null;
}
class CachedStreamWrapper<T_A> extends Stream<T_A> {
  T_A lastValue;
  final Stream<T_A> _stream_B;
  final Function _onListen_B;
  CachedStreamWrapper(this._stream_B, this._onListen_B);
  Stream<T_A> asBroadcastStream({void onListen(StreamSubscription<T_A> subscription), void onCancel(StreamSubscription<T_A> subscription)}) {
    return this;
  }
  bool get isBroadcast => true;
  StreamSubscription<T_A> listen(void onData_A(T_A event), {Function onError, void onDone(), bool cancelOnError}) {
    if (_onListen_B != null) {
      _onListen_B(onData_A);
    }
    return _stream_B.listen(onData_A, onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }
}
class TimerFunctions extends LinkedListEntry<TimerFunctions> {
  final int ts50;
  List<Function> _functions = new List<Function>();
  TimerFunctions(this.ts50);
  void add(Function foo) {
    if (!_functions.contains(foo)) {
      _functions.add(foo);
    }
  }
  void remove(Function foo) {
    _functions.remove(foo);
  }
}
class DsTimer {
  static List<Function> _callbacks = [];
  static void _startTimer_A() {
    Timer.run(_dsLoop);
    _pending_A = true;
  }
  static void callLater(Function callback_A) {
    if (!_pending_A) {
      _startTimer_A();
    }
    _callbacks.add(callback_A);
  }
  static LinkedList<TimerFunctions> _pendingTimer = new LinkedList<TimerFunctions>();
  static Map<int, TimerFunctions> _pendingTimerMap = new Map<int, TimerFunctions>();
  static Map<Function, TimerFunctions> _functionsMap = new Map<Function, TimerFunctions>();
  static TimerFunctions _getTimerFunctions(int time50) {
    TimerFunctions tf = _pendingTimerMap[time50];
    if (tf != null) {
      return tf;
    }
    tf = new TimerFunctions(time50);
    _pendingTimerMap[time50] = tf;
    TimerFunctions it;
    if (_pendingTimer.isNotEmpty) {
      it = _pendingTimer.first;
    }
    while (it != null) {
      if (it.ts50 > time50) {
        it.insertBefore(tf);
        break;
      } else if (it.next != _pendingTimer && it.next != it) {
        it = it.next;
      } else {
        it = null;
      }
    }
    if (it == null) {
      _pendingTimer.add(tf);
    }
    if (!_pending_A) {
      _startTimer_A();
    }
    return tf;
  }
  static TimerFunctions _removeTimerFunctions(int time50) {
    if (_pendingTimer.isNotEmpty && _pendingTimer.first.ts50 <= time50) {
      TimerFunctions rslt = _pendingTimer.first;
      _pendingTimerMap.remove(rslt.ts50);
      rslt.unlink();
      for (Function fun in rslt._functions) {
        _functionsMap.remove(fun);
        fun();
      }
      return rslt;
    }
    return null;
  }
  static int _lastTimeRun = -1;
  static void timerOnceAfter(Function callback_A, int ms) {
    int desiredTime50 = (((new DateTime.now()).millisecondsSinceEpoch + ms) / 50).ceil();
    if (_functionsMap.containsKey(callback_A)) {
      TimerFunctions existTf = _functionsMap[callback_A];
      if (existTf.ts50 >= desiredTime50) {
        return;
      } else {
        existTf.remove(callback_A);
      }
    }
    if (desiredTime50 <= _lastTimeRun) {
      callLater(callback_A);
      return;
    }
    TimerFunctions tf = _getTimerFunctions(desiredTime50);
    tf.add(callback_A);
    _functionsMap[callback_A] = tf;
  }
  static void timerCancel(Function callback_A) {
    TimerFunctions existTf = _functionsMap[callback_A];
    if (existTf != null) {
      existTf.remove(callback_A);
    }
  }
  static bool _pending_A = false;
  static bool _looping = false;
  static bool _mergeCycle = false;
  static void _dsLoop() {
    _pending_A = false;
    _looping = true;
    List<Function> runnings = _callbacks;
    _callbacks = new List();
    for (var f in runnings) {
      f();
    }
    int currentTime = (new DateTime.now()).millisecondsSinceEpoch;
    _lastTimeRun = (currentTime / 50).floor();
    while (_removeTimerFunctions(_lastTimeRun) != null) {}
    _looping = false;
    if (_mergeCycle) {
      _mergeCycle = false;
      _dsLoop();
    }
    if (_pendingTimer.isNotEmpty) {
      if (!_pending_A) {
        if (timerTs50 != _pendingTimer.first.ts50) {
          timerTs50 = _pendingTimer.first.ts50;
          if (timerTimer != null && timerTimer.isActive) {
            timerTimer.cancel();
          }
          var duration_A = new Duration(milliseconds: timerTs50 * 50 + 1 - currentTime);
          timerTimer = new Timer(duration_A, _startTimer_A);
        }
      }
    } else if (timerTimer != null) {
      if (timerTimer.isActive) {
        timerTimer.cancel();
      }
      timerTimer = null;
    }
  }
  static int timerTs50 = -1;
  static Timer timerTimer;
}
typedef dynamic ExecutableFunction();
typedef dynamic Taker<T_A>(T_A _0);
typedef dynamic TwoTaker<A, B>(A _0, B _1);
const String DSA_VERSION = "1.1.2";
Logger _logger;
bool _DEBUG_MODE;
List<int> foldList(List<int> a, List<int> b) {
  return a
      ..addAll(b);
}
int countCharacterFrequency(String input_A, String char) {
  var c = char.codeUnitAt(0);
  return input_A.codeUnits.where((u) => c == u).length;
}
bool get DEBUG_MODE {
  if (_DEBUG_MODE != null) {
    return _DEBUG_MODE;
  }
  try {
    assert(false);
    _DEBUG_MODE = false;
  } catch (e) {
    _DEBUG_MODE = true;
  }
  return _DEBUG_MODE;
}
const bool _isJavaScript = identical(1, 1.0);
bool _getLogSetting(LogRecord record, String name_A, [bool defaultValue_A = false]) {
  if (!_isJavaScript) {
    bool env = new bool.fromEnvironment(name_A, defaultValue: null);
    if (env != null) {
      return env;
    }
  }
  if (record.zone[name_A] is bool) {
    return record.zone[name_A];
  }
  return defaultValue_A;
}
Logger get logger {
  if (_logger != null) {
    return _logger;
  }
  hierarchicalLoggingEnabled = true;
  _logger = new Logger("DSA");
  _logger.onRecord.listen((record) {
    List<String> lines = record.message.split("\n");
    bool inlineErrors = _getLogSetting(record, "dsa.logger.inline_errors", true);
    bool enableSequenceNumbers = _getLogSetting(record, "dsa.logger.sequence", false);
    if (inlineErrors) {
      if (record.error != null) {
        lines.addAll(record.error.toString().split("\n"));
      }
      if (record.stackTrace != null) {
        lines.addAll(record.stackTrace.toString().split("\n").where((x_A) => x_A.isNotEmpty).toList());
      }
    }
    String rname = record.loggerName;
    if (record.zone["dsa.logger.name"] is String) {
      rname = record.zone["dsa.logger.name"];
    }
    bool showTimestamps = _getLogSetting(record, "dsa.logger.show_timestamps", false);
    if (!_getLogSetting(record, "dsa.logger.show_name", true)) {
      rname = null;
    }
    for (String line_A in lines) {
      String msg_A = "";
      if (enableSequenceNumbers) {
        msg_A += "[${record.sequenceNumber}]";
      }
      if (showTimestamps) {
        msg_A += "[${record.time}]";
      }
      msg_A += "[${record.level.name}]";
      if (rname != null) {
        msg_A += "[${rname}]";
      }
      msg_A += " ";
      msg_A += line_A;
      if (_getLogSetting(record, "dsa.logger.print", true)) {
        print(msg_A);
      }
    }
    if (!inlineErrors) {
      if (record.error != null) {
        print(record.error);
      }
      if (record.stackTrace != null) {
        print(record.stackTrace);
      }
    }
  });
  updateLogLevel(const String.fromEnvironment("dsa.logger.default_level", defaultValue: "INFO"));
  return _logger;
}
void updateLogLevel(String name_A) {
  name_A = name_A.trim().toUpperCase();
  if (name_A == "DEBUG") {
    name_A = "ALL";
  }
  Map<String, Level> levels = {};
  for (var l in Level.LEVELS) {
    levels[l.name] = l;
  }
  var l = levels[name_A];
  if (l != null) {
    logger.level = l;
  }
}
String buildEnumType(Iterable<String> values_A) => "enum[${values_A.join(",")}]";
Uint8List toUTF8(String str) {
  int length_A = str.length;
  Uint8List bytes_A = new Uint8List(length_A);
  for (int i = 0; i < length_A; i++) {
    int unit = str.codeUnitAt(i);
    if (unit >= 128) {
      return new Uint8List.fromList(const Utf8Encoder().convert(str));
    }
    bytes_A[i] = unit;
  }
  return bytes_A;
}
class ClientException implements Exception {
  final String message;
  final Uri uri;
  ClientException(this.message, [this.uri]);
  String toString() => message;
}
class StringScannerException extends SourceSpanFormatException {
  String get source => super.source;
  Uri get sourceUrl => span.sourceUrl;
  StringScannerException(String message_A, SourceSpan span, String source_A) : super(message_A, span, source_A);
}
const int _LF_B = 10;
const int _CR_B = 13;
class SourceFile {
  final Uri url;
  final _lineStarts = <int>[0];
  final Uint32List _decodedChars;
  int get length => _decodedChars.length;
  int get lines => _lineStarts.length;
  int _cachedLine;
  SourceFile(String text_A, {url}) : this.decoded(text_A.runes, url: url);
  SourceFile.decoded(Iterable<int> decodedChars, {url}) : url = url is String ? Uri.parse(url) : url, _decodedChars = new Uint32List.fromList(decodedChars.toList()) {
    for (var i = 0; i < _decodedChars.length; i++) {
      var c = _decodedChars[i];
      if (c == _CR_B) {
        var j = i + 1;
        if (j >= _decodedChars.length || _decodedChars[j] != _LF_B) c = _LF_B;
      }
      if (c == _LF_B) _lineStarts.add(i + 1);
    }
  }
  FileSpan span(int start_A, [int end_A]) {
    if (end_A == null) end_A = length - 1;
    return new _FileSpan(this, start_A, end_A);
  }
  FileLocation location(int offset_A) => new FileLocation.__C(this, offset_A);
  int getLine(int offset_A) {
    if (offset_A < 0) {
      throw new RangeError("Offset may not be negative, was ${offset_A}.");
    } else if (offset_A > length) {
      throw new RangeError("Offset ${offset_A} must not be greater than the number " "of characters in the file, ${length}.");
    }
    if (offset_A < _lineStarts.first) return -1;
    if (offset_A >= _lineStarts.last) return _lineStarts.length - 1;
    if (_isNearCachedLine(offset_A)) return _cachedLine;
    _cachedLine = _binarySearch(offset_A) - 1;
    return _cachedLine;
  }
  bool _isNearCachedLine(int offset_A) {
    if (_cachedLine == null) return false;
    if (offset_A < _lineStarts[_cachedLine]) return false;
    if (_cachedLine >= _lineStarts.length - 1 || offset_A < _lineStarts[_cachedLine + 1]) {
      return true;
    }
    if (_cachedLine >= _lineStarts.length - 2 || offset_A < _lineStarts[_cachedLine + 2]) {
      _cachedLine++;
      return true;
    }
    return false;
  }
  int _binarySearch(int offset_A) {
    int min_B = 0;
    int max_B = _lineStarts.length - 1;
    while (min_B < max_B) {
      var half = min_B + ((max_B - min_B) ~/ 2);
      if (_lineStarts[half] > offset_A) {
        max_B = half;
      } else {
        min_B = half + 1;
      }
    }
    return max_B;
  }
  int getColumn(int offset_A, {int line}) {
    if (offset_A < 0) {
      throw new RangeError("Offset may not be negative, was ${offset_A}.");
    } else if (offset_A > length) {
      throw new RangeError("Offset ${offset_A} must be not be greater than the " "number of characters in the file, ${length}.");
    }
    if (line == null) {
      line = getLine(offset_A);
    } else if (line < 0) {
      throw new RangeError("Line may not be negative, was ${line}.");
    } else if (line >= lines) {
      throw new RangeError("Line ${line} must be less than the number of " "lines in the file, ${lines}.");
    }
    var lineStart = _lineStarts[line];
    if (lineStart > offset_A) {
      throw new RangeError("Line ${line} comes after offset ${offset_A}.");
    }
    return offset_A - lineStart;
  }
  int getOffset(int line_A, [int column_A]) {
    if (column_A == null) column_A = 0;
    if (line_A < 0) {
      throw new RangeError("Line may not be negative, was ${line_A}.");
    } else if (line_A >= lines) {
      throw new RangeError("Line ${line_A} must be less than the number of " "lines in the file, ${lines}.");
    } else if (column_A < 0) {
      throw new RangeError("Column may not be negative, was ${column_A}.");
    }
    var result_A = _lineStarts[line_A] + column_A;
    if (result_A > length || (line_A + 1 < lines && result_A >= _lineStarts[line_A + 1])) {
      throw new RangeError("Line ${line_A} doesn't have ${column_A} columns.");
    }
    return result_A;
  }
  String getText(int start_A, [int end_A]) => new String.fromCharCodes(_decodedChars.sublist(start_A, end_A));
}
class FileLocation extends SourceLocationMixin implements SourceLocation_A {
  final SourceFile file;
  final int offset;
  Uri get sourceUrl => file.url;
  int get line => file.getLine(offset);
  int get column => file.getColumn(offset);
  FileLocation.__C(this.file, this.offset) {
    if (offset < 0) {
      throw new RangeError("Offset may not be negative, was ${offset}.");
    } else if (offset > file.length) {
      throw new RangeError("Offset ${offset} must not be greater than the number " "of characters in the file, ${file.length}.");
    }
  }
}
abstract class FileSpan implements SourceSpanWithContext {}
class _FileSpan extends SourceSpanMixin implements FileSpan {
  final SourceFile file;
  final int _start_A;
  final int _end_A;
  Uri get sourceUrl => file.url;
  int get length => _end_A - _start_A;
  FileLocation get start => new FileLocation.__C(file, _start_A);
  FileLocation get end => new FileLocation.__C(file, _end_A);
  String get text => file.getText(_start_A, _end_A);
  String get context => file.getText(file.getOffset(start.line), end.line == file.lines - 1 ? null : file.getOffset(end.line + 1));
  _FileSpan(this.file, this._start_A, this._end_A) {
    if (_end_A < _start_A) {
      throw new ArgumentError('End ${_end_A} must come after start ${_start_A}.');
    } else if (_end_A > file.length) {
      throw new RangeError("End ${_end_A} must not be greater than the number " "of characters in the file, ${file.length}.");
    } else if (_start_A < 0) {
      throw new RangeError("Start may not be negative, was ${_start_A}.");
    }
  }
  int compareTo(SourceSpan other) {
    if (other is! _FileSpan) return super.compareTo(other);
    _FileSpan otherFile = other;
    var result_A = _start_A.compareTo(otherFile._start_A);
    return result_A == 0 ? _end_A.compareTo(otherFile._end_A) : result_A;
  }
  SourceSpan union(SourceSpan other) {
    if (other is! FileSpan) return super.union(other);
    _FileSpan span = expand(other);
    if (other is _FileSpan) {
      if (this._start_A > other._end_A || other._start_A > this._end_A) {
        throw new ArgumentError("Spans ${this} and ${other} are disjoint.");
      }
    } else {
      if (this._start_A > other.end.offset || other.start.offset > this._end_A) {
        throw new ArgumentError("Spans ${this} and ${other} are disjoint.");
      }
    }
    return span;
  }
  bool operator==(other) {
    if (other is! FileSpan) return super == other;
    if (other is! _FileSpan) {
      return super == other && sourceUrl == other.sourceUrl;
    }
    return _start_A == other._start_A && _end_A == other._end_A && sourceUrl == other.sourceUrl;
  }
  int get hashCode => super.hashCode;
  FileSpan expand(FileSpan other) {
    if (sourceUrl != other.sourceUrl) {
      throw new ArgumentError("Source URLs \"${sourceUrl}\" and " " \"${other.sourceUrl}\" don't match.");
    }
    if (other is _FileSpan) {
      var start_A = _A.min(this._start_A, other._start_A);
      var end_A = _A.max(this._end_A, other._end_A);
      return new _FileSpan(file, start_A, end_A);
    } else {
      var start_A = _A.min(this._start_A, other.start.offset);
      var end_A = _A.max(this._end_A, other.end.offset);
      return new _FileSpan(file, start_A, end_A);
    }
  }
}
Future<Response> get_A(url, {Map<String, String> headers}) => _withClient((client) => client.get(url, headers: headers));
Future _withClient(Future fn(Client client)) async {
  var client = new Client();
  try {
    return await fn(client);
  } finally {
    client.close();
  }
}
bool get supported => _library != null;
final _library = _getLibrary();
final ClassMirror _httpClient_A = _library.declarations[const Symbol('HttpClient')];
final ClassMirror _httpException = _library.declarations[const Symbol('HttpException')];
void assertSupported(String name_A) {
  if (supported) return;
  throw new UnsupportedError("${name_A} isn't supported on this platform.");
}
newHttpClient() => _httpClient_A.newInstance(const Symbol(''), []).reflectee;
bool isHttpException(error_A) => reflect(error_A).type.isSubtypeOf(_httpException);
bool isHttpClient(client) => reflect(client).type.isSubtypeOf(_httpClient_A);
LibraryMirror _getLibrary() {
  try {
    return currentMirrorSystem().findLibrary(const Symbol('dart.io'));
  } catch (__I) {
    return null;
  }
}
class IOClient extends BaseClient {
  var _inner;
  IOClient([innerClient]) {
    assertSupported("IOClient");
    if (innerClient != null) {
      assert(isHttpClient(innerClient));
      _inner = innerClient;
    } else {
      _inner = newHttpClient();
    }
  }
  Future<StreamedResponse> send(BaseRequest request_B) async {
    var stream_A = request_B.finalize();
    try {
      var ioRequest = await _inner.openUrl(request_B.method, request_B.url);
      ioRequest
          ..followRedirects = request_B.followRedirects
          ..maxRedirects = request_B.maxRedirects
          ..contentLength = request_B.contentLength == null ? -1 : request_B.contentLength
          ..persistentConnection = request_B.persistentConnection;
      request_B.headers.forEach((name_A, value_A) {
        ioRequest.headers.set(name_A, value_A);
      });
      var response_B = await stream_A.pipe(DelegatingStreamConsumer.typed_B(ioRequest));
      var headers_A = <String, String>{};
      response_B.headers.forEach((key_A, values_A) {
        headers_A[key_A] = values_A.join(',');
      });
      return new StreamedResponse(DelegatingStream.typed_C(response_B).handleError((error_A) => throw new ClientException(error_A.message, error_A.uri), test: (error_A) => isHttpException(error_A)), response_B.statusCode, contentLength: response_B.contentLength == -1 ? null : response_B.contentLength, request: request_B, headers: headers_A, isRedirect: response_B.isRedirect, persistentConnection: response_B.persistentConnection, reasonPhrase: response_B.reasonPhrase);
    } catch (error_A) {
      if (!isHttpException(error_A)) rethrow;
      throw new ClientException(error_A.message, error_A.uri);
    }
  }
  void close() {
    if (_inner != null) _inner.close(force: true);
    _inner = null;
  }
}
class SourceLocation_A implements Comparable<SourceLocation_A> {}
abstract class SourceLocationMixin implements SourceLocation_A {
  String get toolString {
    var source_A = sourceUrl == null ? 'unknown source' : sourceUrl;
    return '${source_A}:${line + 1}:${column + 1}';
  }
  int distance(SourceLocation_A other) {
    if (sourceUrl != other.sourceUrl) {
      throw new ArgumentError("Source URLs \"${sourceUrl}\" and " "\"${other.sourceUrl}\" don't match.");
    }
    return (offset - other.offset).abs();
  }
  int compareTo(SourceLocation_A other) {
    if (sourceUrl != other.sourceUrl) {
      throw new ArgumentError("Source URLs \"${sourceUrl}\" and " "\"${other.sourceUrl}\" don't match.");
    }
    return offset - other.offset;
  }
  bool operator==(other) => other is SourceLocation_A && sourceUrl == other.sourceUrl && offset == other.offset;
  int get hashCode => sourceUrl.hashCode + offset;
  String toString() => '<${runtimeType}: ${offset} ${toolString}>';
}
bool hierarchicalLoggingEnabled = false;
Level recordStackTraceAtLevel = Level.OFF_A;
Level _rootLevel = Level.INFO;
class Logger {
  final String name;
  String get fullName => (parent == null || parent.name == '') ? name : '${parent.fullName}.${name}';
  final Logger parent;
  Level _level;
  final Map<String, Logger> _children;
  final Map<String, Logger> children;
  StreamController<LogRecord> _controller_C;
  factory Logger(String name_A) {
    return _loggers.putIfAbsent(name_A, () => new Logger._named(name_A));
  }
  factory Logger._named(String name_A) {
    if (name_A.startsWith('.')) {
      throw new ArgumentError("name shouldn't start with a '.'");
    }
    int dot = name_A.lastIndexOf('.');
    Logger parent_A = null;
    String thisName;
    if (dot == -1) {
      if (name_A != '') parent_A = new Logger('');
      thisName = name_A;
    } else {
      parent_A = new Logger(name_A.substring(0, dot));
      thisName = name_A.substring(dot + 1);
    }
    return new Logger._internal_A(thisName, parent_A, new Map<String, Logger>());
  }
  Logger._internal_A(this.name, this.parent, Map<String, Logger> children_A) : this._children = children_A, this.children = new UnmodifiableMapView(children_A) {
    if (parent != null) parent._children[name] = this;
  }
  Level get level {
    if (hierarchicalLoggingEnabled) {
      if (_level != null) return _level;
      if (parent != null) return parent.level;
    }
    return _rootLevel;
  }
  void set level(Level value_A) {
    if (hierarchicalLoggingEnabled && parent != null) {
      _level = value_A;
    } else {
      if (parent != null) {
        throw new UnsupportedError('Please set "hierarchicalLoggingEnabled" to true if you want to ' 'change the level on a non-root logger.');
      }
      _rootLevel = value_A;
    }
  }
  Stream<LogRecord> get onRecord => _getStream();
  void clearListeners() {
    if (hierarchicalLoggingEnabled || parent == null) {
      if (_controller_C != null) {
        _controller_C.close();
        _controller_C = null;
      }
    } else {
      root.clearListeners();
    }
  }
  bool isLoggable(Level value_A) => (value_A >= level);
  void log_A(Level logLevel, message_A, [Object error_A, StackTrace stackTrace_A, Zone zone_A]) {
    Object object;
    if (isLoggable(logLevel)) {
      if (message_A is Function) message_A = message_A();
      if (message_A is! String) {
        object = message_A;
        message_A = message_A.toString();
      }
      if (stackTrace_A == null && logLevel >= recordStackTraceAtLevel) {
        try {
          throw "autogenerated stack trace for ${logLevel} ${message_A}";
        } catch (e, t) {
          stackTrace_A = t;
          if (error_A == null) error_A = e;
        }
      }
      if (zone_A == null) zone_A = Zone.current;
      var record = new LogRecord(logLevel, message_A, fullName, error_A, stackTrace_A, zone_A, object);
      if (hierarchicalLoggingEnabled) {
        var target_A = this;
        while (target_A != null) {
          target_A._publish(record);
          target_A = target_A.parent;
        }
      } else {
        root._publish(record);
      }
    }
  }
  void finest(message_A, [Object error_A, StackTrace stackTrace_A]) => log_A(Level.FINEST, message_A, error_A, stackTrace_A);
  void fine(message_A, [Object error_A, StackTrace stackTrace_A]) => log_A(Level.FINE, message_A, error_A, stackTrace_A);
  void info(message_A, [Object error_A, StackTrace stackTrace_A]) => log_A(Level.INFO, message_A, error_A, stackTrace_A);
  void warning(message_A, [Object error_A, StackTrace stackTrace_A]) => log_A(Level.WARNING_A, message_A, error_A, stackTrace_A);
  void severe(message_A, [Object error_A, StackTrace stackTrace_A]) => log_A(Level.SEVERE, message_A, error_A, stackTrace_A);
  Stream<LogRecord> _getStream() {
    if (hierarchicalLoggingEnabled || parent == null) {
      if (_controller_C == null) {
        _controller_C = new StreamController<LogRecord>.broadcast(sync: true);
      }
      return _controller_C.stream;
    } else {
      return root._getStream();
    }
  }
  void _publish(LogRecord record) {
    if (_controller_C != null) {
      _controller_C.add(record);
    }
  }
  static final Logger root = new Logger('');
  static final Map<String, Logger> _loggers = <String, Logger>{};
}
class Level implements Comparable<Level> {
  final String name;
  final int value;
  const Level(this.name, this.value);
  static const Level ALL_A = const Level('ALL', 0);
  static const Level OFF_A = const Level('OFF', 2000);
  static const Level FINEST = const Level('FINEST', 300);
  static const Level FINER = const Level('FINER', 400);
  static const Level FINE = const Level('FINE', 500);
  static const Level CONFIG_A = const Level('CONFIG', 700);
  static const Level INFO = const Level('INFO', 800);
  static const Level WARNING_A = const Level('WARNING', 900);
  static const Level SEVERE = const Level('SEVERE', 1000);
  static const Level SHOUT = const Level('SHOUT', 1200);
  static const List<Level> LEVELS = const[ALL_A, FINEST, FINER, FINE, CONFIG_A, INFO, WARNING_A, SEVERE, SHOUT, OFF_A];
  bool operator==(other) => other is Level && value == other.value;
  bool operator<(Level other) => value < other.value;
  bool operator<=(Level other) => value <= other.value;
  bool operator>(Level other) => value > other.value;
  bool operator>=(Level other) => value >= other.value;
  int compareTo(Level other) => value - other.value;
  int get hashCode => value;
  String toString() => name;
}
class LogRecord {
  final Level level;
  final String message;
  final Object object;
  final String loggerName;
  final DateTime time;
  final int sequenceNumber;
  static int _nextNumber = 0;
  final Object error;
  final StackTrace stackTrace;
  final Zone zone;
  LogRecord(this.level, this.message, this.loggerName, [this.error, this.stackTrace, this.zone, this.object]) : time = new DateTime.now(), sequenceNumber = LogRecord._nextNumber++;
  String toString() => '[${level.name}] ${loggerName}: ${message}';
}
final _escapedChar = new RegExp(r'["\x00-\x1F\x7F]');
class MediaType {
  final String type;
  final String subtype;
  final Map<String, String> parameters;
  String get mimeType => "${type}/${subtype}";
  factory MediaType.parse_B(String mediaType) {
    return wrapFormatException("media type", mediaType, () {
      var scanner = new StringScanner(mediaType);
      scanner.scan(whitespace);
      scanner.expect(token_A);
      var type_A = scanner.lastMatch[0];
      scanner.expect('/');
      scanner.expect(token_A);
      var subtype_A = scanner.lastMatch[0];
      scanner.scan(whitespace);
      var parameters_A = <String, String>{};
      while (scanner.scan(';')) {
        scanner.scan(whitespace);
        scanner.expect(token_A);
        var attribute = scanner.lastMatch[0];
        scanner.expect('=');
        var value_A;
        if (scanner.scan(token_A)) {
          value_A = scanner.lastMatch[0];
        } else {
          value_A = expectQuotedString(scanner);
        }
        scanner.scan(whitespace);
        parameters_A[attribute] = value_A;
      }
      scanner.expectDone();
      return new MediaType(type_A, subtype_A, parameters_A);
    });
  }
  MediaType(String type_A, String subtype_A, [Map<String, String> parameters_A]) : type = type_A.toLowerCase(), subtype = subtype_A.toLowerCase(), parameters = new UnmodifiableMapView(parameters_A == null ? {} : new CaseInsensitiveMap.from_B(parameters_A));
  MediaType change_A({String type, String subtype, String mimeType, Map<String, String> parameters, bool clearParameters: false}) {
    if (mimeType != null) {
      if (type != null) {
        throw new ArgumentError("You may not pass both [type] and [mimeType].");
      } else if (subtype != null) {
        throw new ArgumentError("You may not pass both [subtype] and " "[mimeType].");
      }
      var segments = mimeType.split('/');
      if (segments.length != 2) {
        throw new FormatException('Invalid mime type "${mimeType}".');
      }
      type = segments[0];
      subtype = segments[1];
    }
    if (type == null) type = this.type;
    if (subtype == null) subtype = this.subtype;
    if (parameters == null) parameters = {};
    if (!clearParameters) {
      var newParameters = parameters;
      parameters = new Map.from(this.parameters);
      parameters.addAll(newParameters);
    }
    return new MediaType(type, subtype, parameters);
  }
  String toString() {
    var buffer_A = new StringBuffer()
        ..write(type)
        ..write("/")
        ..write(subtype);
    parameters.forEach((attribute, value_A) {
      buffer_A.write("; ${attribute}=");
      if (nonToken.hasMatch(value_A)) {
        buffer_A
            ..write('"')
            ..write(value_A.replaceAllMapped(_escapedChar, (match) => "\\" + match[0]))
            ..write('"');
      } else {
        buffer_A.write(value_A);
      }
    });
    return buffer_A.toString();
  }
}
class StringCache {
  static Map<String, List<int>> _cache = {};
  static bool has(String str) {
    return _cache.containsKey(str);
  }
  static List<int> get_B(String string_A) {
    return _cache[string_A];
  }
}
Uint8List _toUTF8(String str) {
  int length_A = str.length;
  Uint8List bytes_A = new Uint8List(length_A);
  for (int i = 0; i < length_A; i++) {
    int unit = str.codeUnitAt(i);
    if (unit >= 128) {
      return new Uint8List.fromList(const Utf8Encoder().convert(str));
    }
    bytes_A[i] = unit;
  }
  return bytes_A;
}
Uint8List pack(value_A) {
  if (_statefulPacker == null) {
    _statefulPacker = new StatefulPacker();
  }
  _statefulPacker.pack_A(value_A);
  return _statefulPacker.done();
}
StatefulPacker _statefulPacker;
class PackedReference {}
class Float {}
abstract class PackBuffer {}
class MsgPackBuffer implements PackBuffer {
  static const int defaultBufferSize = const int.fromEnvironment("msgpack.packer.defaultBufferSize", defaultValue: 512);
  List<Uint8List> _buffers = <Uint8List>[];
  Uint8List _buffer_B;
  int _len_A = 0;
  int _offset = 0;
  int _totalLength = 0;
  final int bufferSize;
  MsgPackBuffer({this.bufferSize: defaultBufferSize});
  void _checkBuffer() {
    if (_buffer_B == null) {
      _buffer_B = new Uint8List(bufferSize);
    }
  }
  void writeUint8(int byte) {
    if (_buffer_B == null) {
      _buffer_B = new Uint8List(bufferSize);
    }
    if (_buffer_B.lengthInBytes == _len_A) {
      _buffers.add(_buffer_B);
      _buffer_B = new Uint8List(bufferSize);
      _len_A = 0;
      _offset = 0;
    }
    _buffer_B[_offset] = byte;
    _offset++;
    _len_A++;
    _totalLength++;
  }
  void writeUint16(int value_A) {
    _checkBuffer();
    if ((_buffer_B.lengthInBytes - _len_A) < 2) {
      writeUint8((value_A >> 8) & 0xff);
      writeUint8(value_A & 0xff);
    } else {
      _buffer_B[_offset++] = (value_A >> 8) & 0xff;
      _buffer_B[_offset++] = value_A & 0xff;
      _len_A += 2;
      _totalLength += 2;
    }
  }
  void writeUint32(int value_A) {
    _checkBuffer();
    if ((_buffer_B.lengthInBytes - _len_A) < 4) {
      writeUint8((value_A >> 24) & 0xff);
      writeUint8((value_A >> 16) & 0xff);
      writeUint8((value_A >> 8) & 0xff);
      writeUint8(value_A & 0xff);
    } else {
      _buffer_B[_offset++] = (value_A >> 24) & 0xff;
      _buffer_B[_offset++] = (value_A >> 16) & 0xff;
      _buffer_B[_offset++] = (value_A >> 8) & 0xff;
      _buffer_B[_offset++] = value_A & 0xff;
      _len_A += 4;
      _totalLength += 4;
    }
  }
  Uint8List read() {
    var out = new Uint8List(_totalLength);
    var off = 0;
    var bufferCount = _buffers.length;
    for (var i = 0; i < bufferCount; i++) {
      Uint8List buff = _buffers[i];
      for (var x_A = buff.offsetInBytes; x_A < buff.lengthInBytes; x_A++) {
        out[off] = buff[x_A];
        off++;
      }
    }
    if (_buffer_B != null) {
      for (var i = 0; i < _len_A; i++) {
        out[off] = _buffer_B[i];
        off++;
      }
    }
    return out;
  }
  Uint8List done() {
    Uint8List out = read();
    _buffers = new List<Uint8List>();
    _len_A = 0;
    _totalLength = 0;
    _offset = 0;
    _buffer_B = null;
    return out;
  }
  void writeUint8List(Uint8List data_A) {
    _checkBuffer();
    var dataSize = data_A.lengthInBytes;
    var bufferSpace = _buffer_B.lengthInBytes - _len_A;
    if (bufferSpace < dataSize) {
      int i;
      for (i = 0; i < bufferSpace; i++) {
        _buffer_B[_offset++] = data_A[i];
      }
      _len_A += bufferSpace;
      _totalLength += bufferSpace;
      while (i < dataSize) {
        writeUint8(data_A[i++]);
      }
    } else {
      for (var i = 0; i < dataSize; i++) {
        _buffer_B[_offset++] = data_A[i];
      }
      _len_A += dataSize;
      _totalLength += dataSize;
    }
  }
}
class StatefulPacker {
  PackBuffer buffer;
  StatefulPacker([this.buffer]) {
    if (buffer == null) {
      buffer = new MsgPackBuffer();
    }
  }
  void pack_A(value_A) {
    if (value_A is Iterable && value_A is! List) {
      value_A = value_A.toList();
    }
    if (value_A == null) {
      buffer.writeUint8(0xc0);
    } else if (value_A == false) {
      buffer.writeUint8(0xc2);
    } else if (value_A == true) {
      buffer.writeUint8(0xc3);
    } else if (value_A is int) {
      packInt(value_A);
    } else if (value_A is String) {
      packString(value_A);
    } else if (value_A is List) {
      packList(value_A);
    } else if (value_A is Map) {
      packMap(value_A);
    } else if (value_A is double) {
      packDouble(value_A);
    } else if (value_A is Float) {
      packFloat(value_A);
    } else if (value_A is ByteData) {
      packBinary(value_A);
    } else if (value_A is PackedReference) {
      writeAllBytes(value_A.data);
    } else {
      throw new Exception("Failed to pack value: ${value_A}");
    }
  }
  void packBinary(ByteData data_A) {
    var list_A = data_A.buffer.asUint8List(data_A.offsetInBytes, data_A.lengthInBytes);
    var count_A = list_A.lengthInBytes;
    if (count_A <= 255) {
      buffer.writeUint8(0xc4);
      buffer.writeUint8(count_A);
      writeAllBytes(list_A);
    } else if (count_A <= 65535) {
      buffer.writeUint8(0xc5);
      buffer.writeUint16(count_A);
      writeAllBytes(list_A);
    } else {
      buffer.writeUint8(0xc6);
      buffer.writeUint32(count_A);
      writeAllBytes(list_A);
    }
  }
  void packInt(int value_A) {
    if (value_A >= 0 && value_A < 128) {
      buffer.writeUint8(value_A);
      return;
    }
    if (value_A < 0) {
      if (value_A >= -32) {
        buffer.writeUint8(0xe0 + value_A + 32);
      } else if (value_A > -0x80) {
        buffer.writeUint8(0xd0);
        buffer.writeUint8(value_A + 0x100);
      } else if (value_A > -0x8000) {
        buffer.writeUint8(0xd1);
        buffer.writeUint16(value_A + 0x10000);
      } else if (value_A > -0x80000000) {
        buffer.writeUint8(0xd2);
        buffer.writeUint32(value_A + 0x100000000);
      } else {
        buffer.writeUint8(0xd3);
        _encodeUint64(value_A);
      }
    } else {
      if (value_A < 0x100) {
        buffer.writeUint8(0xcc);
        buffer.writeUint8(value_A);
      } else if (value_A < 0x10000) {
        buffer.writeUint8(0xcd);
        buffer.writeUint16(value_A);
      } else if (value_A < 0x100000000) {
        buffer.writeUint8(0xce);
        buffer.writeUint32(value_A);
      } else {
        buffer.writeUint8(0xcf);
        _encodeUint64(value_A);
      }
    }
  }
  void _encodeUint64(int value_A) {
    var high = (value_A / 0x100000000).floor();
    var low = value_A & 0xffffffff;
    buffer.writeUint8((high >> 24) & 0xff);
    buffer.writeUint8((high >> 16) & 0xff);
    buffer.writeUint8((high >> 8) & 0xff);
    buffer.writeUint8(high & 0xff);
    buffer.writeUint8((low >> 24) & 0xff);
    buffer.writeUint8((low >> 16) & 0xff);
    buffer.writeUint8((low >> 8) & 0xff);
    buffer.writeUint8(low & 0xff);
  }
  void packString(String value_A) {
    List<int> utf8;
    if (StringCache.has(value_A)) {
      utf8 = StringCache.get_B(value_A);
    } else {
      utf8 = _toUTF8(value_A);
    }
    if (utf8.length < 0x20) {
      buffer.writeUint8(0xa0 + utf8.length);
    } else if (utf8.length < 0x100) {
      buffer.writeUint8(0xd9);
      buffer.writeUint8(utf8.length);
    } else if (utf8.length < 0x10000) {
      buffer.writeUint8(0xda);
      buffer.writeUint16(utf8.length);
    } else {
      buffer.writeUint8(0xdb);
      buffer.writeUint32(utf8.length);
    }
    writeAllBytes(utf8);
  }
  void packDouble(double value_A) {
    buffer.writeUint8(0xcb);
    var f = new ByteData(8);
    f.setFloat64(0, value_A);
    writeAllBytes(f);
  }
  void packFloat(Float float) {
    buffer.writeUint8(0xca);
    var f = new ByteData(4);
    f.setFloat32(0, float.value);
    writeAllBytes(f);
  }
  void packList(List value_A) {
    var len = value_A.length;
    if (len < 16) {
      buffer.writeUint8(0x90 + len);
    } else if (len < 0x100) {
      buffer.writeUint8(0xdc);
      buffer.writeUint16(len);
    } else {
      buffer.writeUint8(0xdd);
      buffer.writeUint32(len);
    }
    for (var i = 0; i < len; i++) {
      pack_A(value_A[i]);
    }
  }
  void packMap(Map value_A) {
    if (value_A.length < 16) {
      buffer.writeUint8(0x80 + value_A.length);
    } else if (value_A.length < 0x100) {
      buffer.writeUint8(0xde);
      buffer.writeUint16(value_A.length);
    } else {
      buffer.writeUint8(0xdf);
      buffer.writeUint32(value_A.length);
    }
    for (var element_A in value_A.keys) {
      pack_A(element_A);
      pack_A(value_A[element_A]);
    }
  }
  void writeAllBytes(list_A) {
    if (list_A is Uint8List) {
      buffer.writeUint8List(list_A);
    } else if (list_A is ByteData) {
      buffer.writeUint8List(list_A.buffer.asUint8List(list_A.offsetInBytes, list_A.lengthInBytes));
    } else if (list_A is List) {
      for (var b in list_A) {
        buffer.writeUint8(b);
      }
    } else {
      throw new Exception("I don't know how to write everything in ${list_A}");
    }
  }
  Uint8List done() {
    return buffer.done();
  }
}
const int _maxUint32 = 4294967295;
const bool _enableFastBinaryUnpacker = true;
class Unpacker {
  ByteData data;
  int offset;
  Unpacker(ByteBuffer buffer_A, [this.offset = 0]) {
    data = buffer_A.asByteData();
  }
  void reset(ByteBuffer buff, int off) {
    data = buff.asByteData();
    offset = off;
  }
  unpack() {
    int type_A = data.getUint8(offset++);
    if (type_A >= 0xe0) return type_A - 0x100;
    if (type_A < 0xc0) {
      if (type_A < 0x80) return type_A; else if (type_A < 0x90) return unpackMap(type_A - 0x80); else if (type_A < 0xa0) return unpackList(type_A - 0x90); else return unpackString(type_A - 0xa0);
    }
    switch (type_A) {
      case 0xc0:
        return null;

      case 0xc2:
        return false;

      case 0xc3:
        return true;

      case 0xc4:
        return unpackBinary(type_A);

      case 0xc5:
        return unpackBinary(type_A);

      case 0xc6:
        return unpackBinary(type_A);

      case 0xcf:
        return unpackU64();

      case 0xce:
        return unpackU32();

      case 0xcd:
        return unpackU16();

      case 0xcc:
        return unpackU8();

      case 0xd3:
        return unpackS64();

      case 0xd2:
        return unpackS32();

      case 0xd1:
        return unpackS16();

      case 0xd0:
        return unpackS8();

      case 0xd9:
        return unpackString(unpackU8());

      case 0xda:
        return unpackString(unpackU16());

      case 0xdb:
        return unpackString(unpackU32());

      case 0xdf:
        return unpackMap(unpackU32());

      case 0xde:
        return unpackMap(unpackU16());

      case 0x80:
        return unpackMap(unpackU8());

      case 0xdd:
        return unpackList(unpackU32());

      case 0xdc:
        return unpackList(unpackU16());

      case 0x90:
        return unpackList(unpackU8());

      case 0xca:
        return unpackFloat32();

      case 0xcb:
        return unpackDouble();
    }
  }
  ByteData unpackBinary(int type_A) {
    int count_A;
    var byteOffset = 0;
    if (type_A == 0xc4) {
      count_A = data.getUint8(offset);
      byteOffset = 1;
    } else if (type_A == 0xc5) {
      count_A = data.getUint16(offset);
      byteOffset = 2;
    } else if (type_A == 0xc6) {
      count_A = data.getUint32(offset);
      byteOffset = 4;
    } else {
      throw new Exception("Bad Binary Type");
    }
    offset += byteOffset;
    if (_enableFastBinaryUnpacker) {
      var result_A = data.buffer.asByteData(offset, count_A);
      offset += count_A;
      return result_A;
    } else {
      var result_A = new Uint8List(count_A);
      var c = 0;
      for (var i = offset; c < count_A; i++) {
        result_A[c] = data.getUint8(i);
        c++;
      }
      offset += count_A;
      return result_A.buffer.asByteData(result_A.offsetInBytes, result_A.lengthInBytes);
    }
  }
  double unpackFloat32() {
    var value_A = data.getFloat32(offset);
    offset += 4;
    return value_A;
  }
  double unpackDouble() {
    var buff = new Uint8List.fromList(data.buffer.asUint8List(offset, 8));
    offset += 8;
    return buff.buffer.asByteData().getFloat64(0);
  }
  int unpackU64() {
    var high = unpackU32();
    var low = unpackU32();
    return (high * (_maxUint32 + 1)) + low;
  }
  int unpackU32() {
    var num_A = 0;
    for (var i = 0; i < 4; i++) {
      num_A = (num_A << 8) | unpackU8();
    }
    return num_A;
  }
  int unpackU16() {
    var o = unpackU8();
    o = o << 8;
    o |= unpackU8();
    return o;
  }
  int unpackU8() {
    return data.getUint8(offset++);
  }
  int unpackS64() {
    var bytes_A = [unpackU8(), unpackU8(), unpackU8(), unpackU8(), unpackU8(), unpackU8(), unpackU8(), unpackU8()];
    var num_A = bytes_A[0];
    if ((num_A & 0x80) != 0) {
      var out = (num_A ^ 0xff) * 0x100000000000000;
      out += (bytes_A[1] ^ 0xff) * 0x1000000000000;
      out += (bytes_A[2] ^ 0xff) * 0x10000000000;
      out += (bytes_A[3] ^ 0xff) * 0x100000000;
      out += (bytes_A[4] ^ 0xff) * 0x1000000;
      out += (bytes_A[5] ^ 0xff) * 0x10000;
      out += (bytes_A[6] ^ 0xff) * 0x100;
      out += (bytes_A[7] ^ 0xff) + 1;
      return -out;
    } else {
      var out = num_A * 0x100000000000000;
      out += bytes_A[1] * 0x1000000000000;
      out += bytes_A[2] * 0x10000000000;
      out += bytes_A[3] * 0x100000000;
      out += bytes_A[4] * 0x1000000;
      out += bytes_A[5] * 0x10000;
      out += bytes_A[6] * 0x100;
      out += bytes_A[7];
      return out;
    }
  }
  int unpackS32() {
    var bytes_A = [unpackU8(), unpackU8(), unpackU8(), unpackU8()];
    var negate = (bytes_A[0] & 0x40) != 0;
    var x_A = 0;
    var o = 0;
    var carry = 1;
    for (var i = 3, m = 1; i >= 0; i--, m *= 256) {
      var v = bytes_A[o + i];
      if (negate) {
        v = (v ^ 0xff) + carry;
        carry = v >> 8;
        v &= 0xff;
      }
      x_A += v * m;
    }
    return negate ? -x_A : x_A;
  }
  int unpackS16() {
    var bytes_A = [unpackU8(), unpackU8()];
    var negate = (bytes_A[0] & 0x20) != 0;
    var x_A = 0;
    var o = 0;
    var carry = 1;
    for (var i = 1, m = 1; i >= 0; i--, m *= 256) {
      var v = bytes_A[o + i];
      if (negate) {
        v = (v ^ 0xff) + carry;
        carry = v >> 8;
        v &= 0xff;
      }
      x_A += v * m;
    }
    return negate ? -x_A : x_A;
  }
  int unpackS8() {
    var num_A = unpackU8();
    return num_A < 0x80 ? num_A : num_A - 0x100;
  }
  String unpackString(int count_A) {
    String value_A = const Utf8Decoder().convert(data.buffer.asUint8List(offset, count_A));
    offset += count_A;
    return value_A;
  }
  Map unpackMap(int count_A) {
    Map map_A = {};
    for (int i = 0; i < count_A; ++i) {
      map_A[unpack()] = unpack();
    }
    return map_A;
  }
  List unpackList(int count_A) {
    List list_A = [];
    list_A.length = count_A;
    for (int i = 0; i < count_A; ++i) {
      list_A[i] = unpack();
    }
    return list_A;
  }
}
Option newOption(String name_A, String abbreviation, String help, String valueHelp, List<String> allowed, Map<String, String> allowedHelp, defaultValue_A, Function callback_A, OptionType type_A, {bool negatable, bool splitCommas, bool hide: false}) {
  return new Option.__D(name_A, abbreviation, help, valueHelp, allowed, allowedHelp, defaultValue_A, callback_A, type_A, negatable: negatable, splitCommas: splitCommas, hide: hide);
}
class Option {
  final String name;
  final String abbreviation;
  final List<String> allowed;
  final defaultValue;
  final Function callback;
  final String help;
  final String valueHelp;
  final Map<String, String> allowedHelp;
  final OptionType type;
  final bool negatable;
  final bool splitCommas;
  final bool hide;
  bool get isFlag => type == OptionType.FLAG;
  bool get isMultiple => type == OptionType.MULTIPLE;
  Option.__D(this.name, this.abbreviation, this.help, this.valueHelp, List<String> allowed_A, Map<String, String> allowedHelp_A, this.defaultValue, this.callback, OptionType type_A, {this.negatable, bool splitCommas, this.hide: false}) : this.allowed = allowed_A == null ? null : new UnmodifiableListView(allowed_A), this.allowedHelp = allowedHelp_A == null ? null : new UnmodifiableMapView(allowedHelp_A), this.type = type_A, this.splitCommas = splitCommas == null ? type_A == OptionType.MULTIPLE : splitCommas {
    if (name.isEmpty) {
      throw new ArgumentError('Name cannot be empty.');
    } else if (name.startsWith('-')) {
      throw new ArgumentError('Name ${name} cannot start with "-".');
    }
    if (_invalidChars.hasMatch(name)) {
      throw new ArgumentError('Name "${name}" contains invalid characters.');
    }
    if (abbreviation != null) {
      if (abbreviation.length != 1) {
        throw new ArgumentError('Abbreviation must be null or have length 1.');
      } else if (abbreviation == '-') {
        throw new ArgumentError('Abbreviation cannot be "-".');
      }
      if (_invalidChars.hasMatch(abbreviation)) {
        throw new ArgumentError('Abbreviation is an invalid character.');
      }
    }
  }
  dynamic getOrDefault(value_A) {
    if (value_A != null) return value_A;
    if (!isMultiple) return defaultValue;
    if (defaultValue != null) return [defaultValue];
    return [];
  }
  static final _invalidChars = new RegExp(r'''[ \t\r\n"'\\/]''');
}
class OptionType {
  static const FLAG = const OptionType.__E("OptionType.FLAG");
  static const SINGLE = const OptionType.__E("OptionType.SINGLE");
  static const MULTIPLE = const OptionType.__E("OptionType.MULTIPLE");
  final String name;
  const OptionType.__E(this.name);
}
final _SOLO_OPT = new RegExp(r'^-([a-zA-Z0-9])$');
final _ABBR_OPT = new RegExp(r'^-([a-zA-Z0-9]+)(.*)$');
final _LONG_OPT = new RegExp(r'^--([a-zA-Z\-_0-9]+)(=(.*))?$');
class Parser {
  final String commandName;
  final Parser parent;
  final ArgParser grammar;
  final List<String> args;
  final rest = <String>[];
  final Map<String, dynamic> results = <String, dynamic>{};
  Parser(this.commandName, this.grammar, this.args, [this.parent, List<String> rest_A]) {
    if (rest_A != null) this.rest.addAll(rest_A);
  }
  String get current => args[0];
  ArgResults parse_D() {
    var arguments_A = args.toList();
    var commandResults = null;
    while (args.length > 0) {
      if (current == '--') {
        args.removeAt(0);
        break;
      }
      var command_A = grammar.commands[current];
      if (command_A != null) {
        validate(rest.isEmpty, 'Cannot specify arguments before a command.');
        var commandName_A = args.removeAt(0);
        var commandParser = new Parser(commandName_A, command_A, args, this, rest);
        commandResults = commandParser.parse_D();
        rest.clear();
        break;
      }
      if (parseSoloOption()) continue;
      if (parseAbbreviation(this)) continue;
      if (parseLongOption()) continue;
      if (!grammar.allowTrailingOptions) break;
      rest.add(args.removeAt(0));
    }
    grammar.options.forEach((name_A, option) {
      if (option.callback == null) return;
      option.callback(option.getOrDefault(results[name_A]));
    });
    rest.addAll(args);
    args.clear();
    return newArgResults(grammar, results, commandName, commandResults, rest, arguments_A);
  }
  void readNextArgAsValue(Option option) {
    validate(args.length > 0, 'Missing argument for "${option.name}".');
    setOption(results, option, current);
    args.removeAt(0);
  }
  bool parseSoloOption() {
    var soloOpt = _SOLO_OPT.firstMatch(current);
    if (soloOpt == null) return false;
    var option = grammar.findByAbbreviation(soloOpt[1]);
    if (option == null) {
      validate(parent != null, 'Could not find an option or flag "-${soloOpt[1]}".');
      return parent.parseSoloOption();
    }
    args.removeAt(0);
    if (option.isFlag) {
      setFlag(results, option, true);
    } else {
      readNextArgAsValue(option);
    }
    return true;
  }
  bool parseAbbreviation(Parser innermostCommand) {
    var abbrOpt = _ABBR_OPT.firstMatch(current);
    if (abbrOpt == null) return false;
    var c = abbrOpt[1].substring(0, 1);
    var first_A = grammar.findByAbbreviation(c);
    if (first_A == null) {
      validate(parent != null, 'Could not find an option with short name "-${c}".');
      return parent.parseAbbreviation(innermostCommand);
    } else if (!first_A.isFlag) {
      var value_A = '${abbrOpt[1].substring(1)}${abbrOpt[2]}';
      setOption(results, first_A, value_A);
    } else {
      validate(abbrOpt[2] == '', 'Option "-${c}" is a flag and cannot handle value ' '"${abbrOpt[1].substring(1)}${abbrOpt[2]}".');
      for (var i = 0; i < abbrOpt[1].length; i++) {
        var c = abbrOpt[1].substring(i, i + 1);
        innermostCommand.parseShortFlag(c);
      }
    }
    args.removeAt(0);
    return true;
  }
  void parseShortFlag(String c) {
    var option = grammar.findByAbbreviation(c);
    if (option == null) {
      validate(parent != null, 'Could not find an option with short name "-${c}".');
      parent.parseShortFlag(c);
      return;
    }
    validate(option.isFlag, 'Option "-${c}" must be a flag to be in a collapsed "-".');
    setFlag(results, option, true);
  }
  bool parseLongOption() {
    var longOpt = _LONG_OPT.firstMatch(current);
    if (longOpt == null) return false;
    var name_A = longOpt[1];
    var option = grammar.options[name_A];
    if (option != null) {
      args.removeAt(0);
      if (option.isFlag) {
        validate(longOpt[3] == null, 'Flag option "${name_A}" should not be given a value.');
        setFlag(results, option, true);
      } else if (longOpt[3] != null) {
        setOption(results, option, longOpt[3]);
      } else {
        readNextArgAsValue(option);
      }
    } else if (name_A.startsWith('no-')) {
      name_A = name_A.substring('no-'.length);
      option = grammar.options[name_A];
      if (option == null) {
        validate(parent != null, 'Could not find an option named "${name_A}".');
        return parent.parseLongOption();
      }
      args.removeAt(0);
      validate(option.isFlag, 'Cannot negate non-flag option "${name_A}".');
      validate(option.negatable, 'Cannot negate option "${name_A}".');
      setFlag(results, option, false);
    } else {
      validate(parent != null, 'Could not find an option named "${name_A}".');
      return parent.parseLongOption();
    }
    return true;
  }
  void validate(bool condition, String message_A) {
    if (!condition) throw new FormatException(message_A);
  }
  void setOption(Map results_A, Option option, String value_A) {
    assert(!option.isFlag);
    if (!option.isMultiple) {
      _validateAllowed(option, value_A);
      results_A[option.name] = value_A;
      return;
    }
    var list_A = results_A.putIfAbsent(option.name, () => <String>[]);
    if (option.splitCommas) {
      for (var element_A in value_A.split(",")) {
        _validateAllowed(option, element_A);
        list_A.add(element_A);
      }
    } else {
      _validateAllowed(option, value_A);
      list_A.add(value_A);
    }
  }
  void setFlag(Map results_A, Option option, bool value_A) {
    assert(option.isFlag);
    results_A[option.name] = value_A;
  }
  void _validateAllowed(Option option, String value_A) {
    if (option.allowed == null) return;
    validate(option.allowed.contains(value_A), '"${value_A}" is not an allowed value for option "${option.name}".');
  }
}
final Context context_A = createInternal();
String get current_A {
  var uri_A = Uri.base;
  if (uri_A == _currentUriBase) return _current_A;
  _currentUriBase = uri_A;
  if (Style.platform == Style.url_A) {
    _current_A = uri_A.resolve('.').toString();
    return _current_A;
  } else {
    var path_A = uri_A.toFilePath();
    var lastIndex = path_A.length - 1;
    assert(path_A[lastIndex] == '/' || path_A[lastIndex] == '\\');
    _current_A = path_A.substring(0, lastIndex);
    return _current_A;
  }
}
Uri _currentUriBase;
String _current_A;
String prettyUri(uri_A) => context_A.prettyUri_A(uri_A);
const PERIOD = 0x2e;
const SLASH_B = 0x2f;
const COLON_A = 0x3a;
const UPPER_A = 0x41;
const UPPER_Z = 0x5a;
const LOWER_A = 0x61;
const LOWER_Z = 0x7a;
const BACKSLASH_A = 0x5c;
Context createInternal() => new Context._internal_B();
class Context {
  factory Context({Style style, String current}) {
    if (current == null) {
      if (style == null) {
        current = current_A;
      } else {
        current = ".";
      }
    }
    if (style == null) {
      style = Style.platform;
    } else if (style is! InternalStyle) {
      throw new ArgumentError("Only styles defined by the path package are " "allowed.");
    }
    return new Context.__F(style as InternalStyle, current);
  }
  Context._internal_B() : style = Style.platform as InternalStyle, _current_B = null;
  Context.__F(this.style, this._current_B);
  final InternalStyle style;
  final String _current_B;
  String get current => _current_B != null ? _current_B : current_A;
  String get separator => style.separator;
  String absolute(String part1, [String part2, String part3, String part4, String part5, String part6, String part7]) {
    _validateArgList("absolute", [part1, part2, part3, part4, part5, part6, part7]);
    if (part2 == null && isAbsolute(part1) && !isRootRelative(part1)) {
      return part1;
    }
    return join(current, part1, part2, part3, part4, part5, part6, part7);
  }
  String rootPrefix(String path_A) => path_A.substring(0, style.rootLength(path_A));
  bool isAbsolute(String path_A) => style.rootLength(path_A) > 0;
  bool isRelative(String path_A) => !this.isAbsolute(path_A);
  bool isRootRelative(String path_A) => style.isRootRelative(path_A);
  String join(String part1, [String part2, String part3, String part4, String part5, String part6, String part7, String part8]) {
    var parts = <String>[part1, part2, part3, part4, part5, part6, part7, part8];
    _validateArgList("join", parts);
    return joinAll(parts.where((part_A) => part_A != null));
  }
  String joinAll(Iterable<String> parts) {
    var buffer_A = new StringBuffer();
    var needsSeparator = false;
    var isAbsoluteAndNotRootRelative = false;
    for (var part_A in parts.where((part_A) => part_A != '')) {
      if (this.isRootRelative(part_A) && isAbsoluteAndNotRootRelative) {
        var parsed = _parse_B(part_A);
        parsed.root_A = this.rootPrefix(buffer_A.toString());
        if (style.needsSeparator(parsed.root_A)) {
          parsed.separators[0] = style.separator;
        }
        buffer_A.clear();
        buffer_A.write(parsed.toString());
      } else if (this.isAbsolute(part_A)) {
        isAbsoluteAndNotRootRelative = !this.isRootRelative(part_A);
        buffer_A.clear();
        buffer_A.write(part_A);
      } else {
        if (part_A.length > 0 && style.containsSeparator(part_A[0])) {} else if (needsSeparator) {
          buffer_A.write(separator);
        }
        buffer_A.write(part_A);
      }
      needsSeparator = style.needsSeparator(part_A);
    }
    return buffer_A.toString();
  }
  List<String> split(String path_A) {
    var parsed = _parse_B(path_A);
    parsed.parts = parsed.parts.where((part_A) => !part_A.isEmpty).toList();
    if (parsed.root_A != null) parsed.parts.insert(0, parsed.root_A);
    return parsed.parts;
  }
  String normalize(String path_A) {
    if (!_needsNormalization(path_A)) return path_A;
    var parsed = _parse_B(path_A);
    parsed.normalize();
    return parsed.toString();
  }
  bool _needsNormalization(String path_A) {
    var start_A = 0;
    var codeUnits_A = path_A.codeUnits;
    var previousPrevious;
    var previous_A;
    var root_A = style.rootLength(path_A);
    if (root_A != 0) {
      start_A = root_A;
      previous_A = SLASH_B;
      if (style == Style.windows) {
        for (var i = 0; i < root_A; i++) {
          if (codeUnits_A[i] == SLASH_B) return true;
        }
      }
    }
    for (var i = start_A; i < codeUnits_A.length; i++) {
      var codeUnit = codeUnits_A[i];
      if (style.isSeparator(codeUnit)) {
        if (style == Style.windows && codeUnit == SLASH_B) return true;
        if (previous_A != null && style.isSeparator(previous_A)) return true;
        if (previous_A == PERIOD && (previousPrevious == null || previousPrevious == PERIOD || style.isSeparator(previousPrevious))) {
          return true;
        }
      }
      previousPrevious = previous_A;
      previous_A = codeUnit;
    }
    if (previous_A == null) return true;
    if (style.isSeparator(previous_A)) return true;
    if (previous_A == PERIOD && (previousPrevious == null || previousPrevious == SLASH_B || previousPrevious == PERIOD)) {
      return true;
    }
    return false;
  }
  String relative(String path_A, {String from}) {
    if (from == null && this.isRelative(path_A)) return this.normalize(path_A);
    from = from == null ? current : absolute(from);
    if (this.isRelative(from) && this.isAbsolute(path_A)) {
      return this.normalize(path_A);
    }
    if (this.isRelative(path_A) || this.isRootRelative(path_A)) {
      path_A = this.absolute(path_A);
    }
    if (this.isRelative(path_A) && this.isAbsolute(from)) {
      throw new PathException('Unable to find a path to "${path_A}" from "${from}".');
    }
    var fromParsed = _parse_B(from)
        ..normalize();
    var pathParsed = _parse_B(path_A)
        ..normalize();
    if (fromParsed.parts.length > 0 && fromParsed.parts[0] == '.') {
      return pathParsed.toString();
    }
    if (fromParsed.root_A != pathParsed.root_A && ((fromParsed.root_A == null || pathParsed.root_A == null) || fromParsed.root_A.toLowerCase().replaceAll('/', '\\') != pathParsed.root_A.toLowerCase().replaceAll('/', '\\'))) {
      return pathParsed.toString();
    }
    while (fromParsed.parts.length > 0 && pathParsed.parts.length > 0 && fromParsed.parts[0] == pathParsed.parts[0]) {
      fromParsed.parts.removeAt(0);
      fromParsed.separators.removeAt(1);
      pathParsed.parts.removeAt(0);
      pathParsed.separators.removeAt(1);
    }
    if (fromParsed.parts.length > 0 && fromParsed.parts[0] == '..') {
      throw new PathException('Unable to find a path to "${path_A}" from "${from}".');
    }
    pathParsed.parts.insertAll(0, new List.filled(fromParsed.parts.length, '..'));
    pathParsed.separators[0] = '';
    pathParsed.separators.insertAll(1, new List.filled(fromParsed.parts.length, style.separator));
    if (pathParsed.parts.length == 0) return '.';
    if (pathParsed.parts.length > 1 && pathParsed.parts.last == '.') {
      pathParsed.parts.removeLast();
      pathParsed.separators
          ..removeLast()
          ..removeLast()
          ..add('');
    }
    pathParsed.root_A = '';
    pathParsed.removeTrailingSeparators();
    return pathParsed.toString();
  }
  String fromUri_A(uri_A) {
    if (uri_A is String) uri_A = Uri.parse(uri_A);
    return style.pathFromUri(uri_A);
  }
  String prettyUri_A(uri_A) {
    if (uri_A is String) uri_A = Uri.parse(uri_A);
    if (uri_A.scheme == 'file' && style == Style.url_A) return uri_A.toString();
    if (uri_A.scheme != 'file' && uri_A.scheme != '' && style != Style.url_A) {
      return uri_A.toString();
    }
    var path_A = normalize(fromUri_A(uri_A));
    var rel = relative(path_A);
    return split(rel).length > split(path_A).length ? path_A : rel;
  }
  ParsedPath _parse_B(String path_A) => new ParsedPath.parse_C(path_A, style);
}
_validateArgList(String method_A, List<String> args) {
  for (var i = 1; i < args.length; i++) {
    if (args[i] == null || args[i - 1] != null) continue;
    var numArgs;
    for (numArgs = args.length; numArgs >= 1; numArgs--) {
      if (args[numArgs - 1] != null) break;
    }
    var message_A = new StringBuffer();
    message_A.write("${method_A}(");
    message_A.write(args.take(numArgs).map((arg) => arg == null ? "null" : '"${arg}"').join(", "));
    message_A.write("): part ${i - 1} was null, but part ${i} was not.");
    throw new ArgumentError(message_A.toString());
  }
}
abstract class InternalStyle extends Style {
  String get separator;
  bool containsSeparator(String path_A);
  bool isSeparator(int codeUnit);
  bool needsSeparator(String path_A);
  int rootLength(String path_A);
  String getRoot(String path_A) {
    var length_A = rootLength(path_A);
    if (length_A > 0) return path_A.substring(0, length_A);
    return isRootRelative(path_A) ? path_A[0] : null;
  }
  bool isRootRelative(String path_A);
  String pathFromUri(Uri uri_A);
}
class ParsedPath {
  InternalStyle style;
  String root_A;
  bool isRootRelative;
  List<String> parts;
  List<String> separators;
  bool get isAbsolute => root_A != null;
  factory ParsedPath.parse_C(String path_A, InternalStyle style_A) {
    var root_A = style_A.getRoot(path_A);
    var isRootRelative_A = style_A.isRootRelative(path_A);
    if (root_A != null) path_A = path_A.substring(root_A.length);
    var parts_A = <String>[];
    var separators_A = <String>[];
    var start_A = 0;
    if (path_A.isNotEmpty && style_A.isSeparator(path_A.codeUnitAt(0))) {
      separators_A.add(path_A[0]);
      start_A = 1;
    } else {
      separators_A.add('');
    }
    for (var i = start_A; i < path_A.length; i++) {
      if (style_A.isSeparator(path_A.codeUnitAt(i))) {
        parts_A.add(path_A.substring(start_A, i));
        separators_A.add(path_A[i]);
        start_A = i + 1;
      }
    }
    if (start_A < path_A.length) {
      parts_A.add(path_A.substring(start_A));
      separators_A.add('');
    }
    return new ParsedPath.__G(style_A, root_A, isRootRelative_A, parts_A, separators_A);
  }
  ParsedPath.__G(this.style, this.root_A, this.isRootRelative, this.parts, this.separators);
  void removeTrailingSeparators() {
    while (!parts.isEmpty && parts.last == '') {
      parts.removeLast();
      separators.removeLast();
    }
    if (separators.length > 0) separators[separators.length - 1] = '';
  }
  void normalize() {
    var leadingDoubles = 0;
    var newParts = <String>[];
    for (var part_A in parts) {
      if (part_A == '.' || part_A == '') {} else if (part_A == '..') {
        if (newParts.length > 0) {
          newParts.removeLast();
        } else {
          leadingDoubles++;
        }
      } else {
        newParts.add(part_A);
      }
    }
    if (!isAbsolute) {
      newParts.insertAll(0, new List.filled(leadingDoubles, '..'));
    }
    if (newParts.length == 0 && !isAbsolute) {
      newParts.add('.');
    }
    var newSeparators = new List<String>.generate(newParts.length, (__I) => style.separator, growable: true);
    newSeparators.insert(0, isAbsolute && newParts.length > 0 && style.needsSeparator(root_A) ? style.separator : '');
    parts = newParts;
    separators = newSeparators;
    if (root_A != null && style == Style.windows) {
      root_A = root_A.replaceAll('/', '\\');
    }
    removeTrailingSeparators();
  }
  String toString() {
    var builder_A = new StringBuffer();
    if (root_A != null) builder_A.write(root_A);
    for (var i = 0; i < parts.length; i++) {
      builder_A.write(separators[i]);
      builder_A.write(parts[i]);
    }
    builder_A.write(separators.last);
    return builder_A.toString();
  }
  ParsedPath clone() => new ParsedPath.__G(style, root_A, isRootRelative, new List.from(parts), new List.from(separators));
}
class PathException implements Exception {
  String message;
  PathException(this.message);
  String toString() => "PathException: ${message}";
}
abstract class Style {
  static final Style posix = new PosixStyle();
  static final Style windows = new WindowsStyle();
  static final Style url_A = new UrlStyle();
  static final Style platform = _getPlatformStyle();
  static Style _getPlatformStyle() {
    if (Uri.base.scheme != 'file') return Style.url_A;
    if (!Uri.base.path.endsWith('/')) return Style.url_A;
    if (new Uri(path: 'a/b').toFilePath() == 'a\\b') return Style.windows;
    return Style.posix;
  }
  String get name;
  Context get context => new Context(style: this);
  String get separator;
  String getRoot(String path_A);
  String pathFromUri(Uri uri_A);
  String toString() => name;
}
class PosixStyle extends InternalStyle {
  PosixStyle();
  final name = 'posix';
  final separator = '/';
  final separators = const['/'];
  final separatorPattern = new RegExp(r'/');
  final needsSeparatorPattern = new RegExp(r'[^/]$');
  final rootPattern = new RegExp(r'^/');
  final relativeRootPattern = null;
  bool containsSeparator(String path_A) => path_A.contains('/');
  bool isSeparator(int codeUnit) => codeUnit == SLASH_B;
  bool needsSeparator(String path_A) => path_A.isNotEmpty && !isSeparator(path_A.codeUnitAt(path_A.length - 1));
  int rootLength(String path_A) {
    if (path_A.isNotEmpty && isSeparator(path_A.codeUnitAt(0))) return 1;
    return 0;
  }
  bool isRootRelative(String path_A) => false;
  String pathFromUri(Uri uri_A) {
    if (uri_A.scheme == '' || uri_A.scheme == 'file') {
      return Uri.decodeComponent(uri_A.path);
    }
    throw new ArgumentError("Uri ${uri_A} must have scheme 'file:'.");
  }
}
class UrlStyle extends InternalStyle {
  UrlStyle();
  final name = 'url';
  final separator = '/';
  final separators = const['/'];
  final separatorPattern = new RegExp(r'/');
  final needsSeparatorPattern = new RegExp(r"(^[a-zA-Z][-+.a-zA-Z\d]*://|[^/])$");
  final rootPattern = new RegExp(r"[a-zA-Z][-+.a-zA-Z\d]*://[^/]*");
  final relativeRootPattern = new RegExp(r"^/");
  bool containsSeparator(String path_A) => path_A.contains('/');
  bool isSeparator(int codeUnit) => codeUnit == SLASH_B;
  bool needsSeparator(String path_A) {
    if (path_A.isEmpty) return false;
    if (!isSeparator(path_A.codeUnitAt(path_A.length - 1))) return true;
    return path_A.endsWith("://") && rootLength(path_A) == path_A.length;
  }
  int rootLength(String path_A) {
    if (path_A.isEmpty) return 0;
    if (isSeparator(path_A.codeUnitAt(0))) return 1;
    var index_A = path_A.indexOf("/");
    if (index_A > 0 && path_A.startsWith('://', index_A - 1)) {
      index_A = path_A.indexOf('/', index_A + 2);
      if (index_A > 0) return index_A;
      return path_A.length;
    }
    return 0;
  }
  bool isRootRelative(String path_A) => path_A.isNotEmpty && isSeparator(path_A.codeUnitAt(0));
  String pathFromUri(Uri uri_A) => uri_A.toString();
}
class WindowsStyle extends InternalStyle {
  WindowsStyle();
  final name = 'windows';
  final separator = '\\';
  final separators = const['/', '\\'];
  final separatorPattern = new RegExp(r'[/\\]');
  final needsSeparatorPattern = new RegExp(r'[^/\\]$');
  final rootPattern = new RegExp(r'^(\\\\[^\\]+\\[^\\/]+|[a-zA-Z]:[/\\])');
  final relativeRootPattern = new RegExp(r"^[/\\](?![/\\])");
  bool containsSeparator(String path_A) => path_A.contains('/');
  bool isSeparator(int codeUnit) => codeUnit == SLASH_B || codeUnit == BACKSLASH_A;
  bool needsSeparator(String path_A) {
    if (path_A.isEmpty) return false;
    return !isSeparator(path_A.codeUnitAt(path_A.length - 1));
  }
  int rootLength(String path_A) {
    if (path_A.isEmpty) return 0;
    if (path_A.codeUnitAt(0) == SLASH_B) return 1;
    if (path_A.codeUnitAt(0) == BACKSLASH_A) {
      if (path_A.length < 2 || path_A.codeUnitAt(1) != BACKSLASH_A) return 1;
      var index_A = path_A.indexOf('\\', 2);
      if (index_A > 0) {
        index_A = path_A.indexOf('\\', index_A + 1);
        if (index_A > 0) return index_A;
      }
      return path_A.length;
    }
    if (path_A.length < 3) return 0;
    if (!isAlphabetic(path_A.codeUnitAt(0))) return 0;
    if (path_A.codeUnitAt(1) != COLON_A) return 0;
    if (!isSeparator(path_A.codeUnitAt(2))) return 0;
    return 3;
  }
  bool isRootRelative(String path_A) => rootLength(path_A) == 1;
  String pathFromUri(Uri uri_A) {
    if (uri_A.scheme != '' && uri_A.scheme != 'file') {
      throw new ArgumentError("Uri ${uri_A} must have scheme 'file:'.");
    }
    var path_A = uri_A.path;
    if (uri_A.host == '') {
      if (path_A.startsWith('/')) path_A = path_A.replaceFirst("/", "");
    } else {
      path_A = '\\\\${uri_A.host}${path_A}';
    }
    return Uri.decodeComponent(path_A.replaceAll("/", "\\"));
  }
}
bool isAlphabetic(int char) => (char >= UPPER_A && char <= UPPER_Z) || (char >= LOWER_A && char <= LOWER_Z);
class Request extends BaseRequest {
  int get contentLength => bodyBytes.length;
  set contentLength(int value_A) {
    throw new UnsupportedError("Cannot set the contentLength property of " "non-streaming Request objects.");
  }
  Encoding _defaultEncoding;
  Encoding get encoding {
    if (_contentType == null || !_contentType.parameters.containsKey('charset')) {
      return _defaultEncoding;
    }
    return requiredEncodingForCharset(_contentType.parameters['charset']);
  }
  set encoding(Encoding value_A) {
    _checkFinalized_A();
    _defaultEncoding = value_A;
    var contentType_A = _contentType;
    if (contentType_A == null) return;
    _contentType = contentType_A.change_A(parameters: {'charset': value_A.name});
  }
  Uint8List get bodyBytes => _bodyBytes;
  Uint8List _bodyBytes;
  set bodyBytes(List<int> value_A) {
    _checkFinalized_A();
    _bodyBytes = toUint8List_A(value_A);
  }
  String get body => encoding.decode(bodyBytes);
  set body(String value_A) {
    bodyBytes = encoding.encode(value_A);
    var contentType_A = _contentType;
    if (contentType_A == null) {
      _contentType = new MediaType("text", "plain", {'charset': encoding.name});
    } else if (!contentType_A.parameters.containsKey('charset')) {
      _contentType = contentType_A.change_A(parameters: {'charset': encoding.name});
    }
  }
  set bodyFields(Map<String, String> fields) {
    var contentType_A = _contentType;
    if (contentType_A == null) {
      _contentType = new MediaType("application", "x-www-form-urlencoded");
    } else if (contentType_A.mimeType != "application/x-www-form-urlencoded") {
      throw new StateError('Cannot set the body fields of a Request with ' 'content-type "${contentType_A.mimeType}".');
    }
    this.body = mapToQuery(fields, encoding: encoding);
  }
  Request(String method_A, Uri url) : _defaultEncoding = UTF8, _bodyBytes = new Uint8List(0), super(method_A, url);
  ByteStream finalize() {
    super.finalize();
    return new ByteStream.fromBytes_D(bodyBytes);
  }
  MediaType get _contentType {
    var contentType_A = headers['content-type'];
    if (contentType_A == null) return null;
    return new MediaType.parse_B(contentType_A);
  }
  set _contentType(MediaType value_A) {
    headers['content-type'] = value_A.toString();
  }
  void _checkFinalized_A() {
    if (!finalized) return;
    throw new StateError("Can't modify a finalized Request.");
  }
}
class Response extends BaseResponse {
  final Uint8List bodyBytes;
  String get body => _encodingForHeaders(headers).decode(bodyBytes);
  Response.bytes(List<int> bodyBytes_A, int statusCode_A, {BaseRequest request, Map<String, String> headers: const{}, bool isRedirect: false, bool persistentConnection: true, String reasonPhrase}) : bodyBytes = toUint8List_A(bodyBytes_A), super(statusCode_A, contentLength: bodyBytes_A.length, request: request, headers: headers, isRedirect: isRedirect, persistentConnection: persistentConnection, reasonPhrase: reasonPhrase);
  static Future<Response> fromStream(StreamedResponse response_B) {
    return response_B.stream.toBytes().then((body_A) {
      return new Response.bytes(body_A, response_B.statusCode, request: response_B.request, headers: response_B.headers, isRedirect: response_B.isRedirect, persistentConnection: response_B.persistentConnection, reasonPhrase: response_B.reasonPhrase);
    });
  }
}
Encoding _encodingForHeaders(Map<String, String> headers_A) => encodingForCharset(_contentTypeForHeaders(headers_A).parameters['charset']);
MediaType _contentTypeForHeaders(Map<String, String> headers_A) {
  var contentType_A = headers_A['content-type'];
  if (contentType_A != null) return new MediaType.parse_B(contentType_A);
  return new MediaType("application", "octet-stream");
}
const String DAY_URL = "http://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/all_day.geojson";
SimpleNode rootNode;
LinkProvider link;
Timer timer;
main(List<String> args) async {
  link = new LinkProvider(args, "Earthquakes-", defaultNodes: {"Get_All": {r"$name": "Get All", r"$is": "getAll", r"$invokable": "read", r"$result": "table", r"$columns": [{"name": "id", "type": "string"}, {"name": "title", "type": "string"}, {"name": "place", "type": "string"}, {"name": "alert", "type": "string"}, {"name": "magnitude", "type": "num"}, {"name": "latitude", "type": "num"}, {"name": "longitude", "type": "num"}, {"name": "depth", "type": "num"}]}}, profiles: {"getAll": (String path_A) => new GetAllActionNode(path_A)});
  link.connect();
  rootNode = link["/"];
  timer = new Timer.periodic(new Duration(seconds: 15), (__I) async {
    await update_A();
  });
  await update_A();
}
update_A() async {
  var json = await getEarthquakeInformation();
  if (json == null) {
    return;
  }
  var features = json["features"];
  ids = features.map((it) => it["id"]).toList();
  var toRemove = rootNode.children.keys.where((it) => !ids.contains(it) && it != "Get_All").toList();
  for (var x_A in toRemove) {
    link.removeNode(x_A);
  }
  for (Map<String, dynamic> feature in features) {
    Map<String, dynamic> props = feature["properties"];
    String id_A = feature["id"];
    SimpleNode n = link["/${id_A}"];
    if (n == null) {
      n = rootNode.createChild(id_A, createEarthquakeInitializer());
    }
    SimpleNode node = link["/${id_A}"];
    v(String name_A, dynamic value_A) {
      link.updateValue("${node.path}/${name_A}", value_A);
    }
    var coords = feature["geometry"]["coordinates"];
    v("Title", props["title"]);
    v("Place", props["place"]);
    v("Timestamp", new DateTime.fromMillisecondsSinceEpoch(props["time"]).toString());
    v("Updated", new DateTime.fromMillisecondsSinceEpoch(props["updated"]).toString());
    v("Type", props["type"]);
    v("Alert", props["alert"] == null ? "unknown" : props["alert"]);
    v("Magnitude", props["mag"]);
    v("Latitude", coords[1]);
    v("Longitude", coords[0]);
    v("Depth", coords[2]);
    v("Felt", props["felt"] == null ? 0 : props["felt"]);
    v("RMS", props["rms"]);
    v("Magnitude_Type", props["magType"]);
    v("Significance", props["sig"]);
    v("Tsunami", props["tsunami"] == 1);
    v("URL", props["url"]);
    v("Status", props["status"]);
    v("Timezone", props["tz"]);
  }
}
Map<String, dynamic> createEarthquakeInitializer() => {"Title": {r"$type": "string"}, "Place": {r"$type": "string"}, "Timestamp": {r"$type": "string"}, "Updated": {r"$type": "string"}, "Type": {r"$type": "string"}, "Alert": {r"$type": "enum[unknown,green,yellow,orange,red]"}, "Magnitude": {r"$type": "num"}, "Latitude": {r"$type": "num"}, "Longitude": {r"$type": "num"}, "Depth": {r"$type": "num"}, "Felt": {r"$type": "num"}, "RMS": {r"$type": "num"}, "Magnitude_Type": {r"$name": "Magnitude Type", r"$type": "string"}, "Maximum_Intensity": {r"$name": "Maximum Intensity", r"$type": "num"}, "Significance": {r"$type": "int"}, "Tsunami": {r"$name": "Is Tsunami", r"$type": "bool"}, "URL": {r"$type": "string"}, "Status": {r"$type": "string"}, "Timezone": {r"$type": "int"}};
List<String> ids = [];
class GetAllActionNode extends SimpleNode {
  GetAllActionNode(String path_A) : super(path_A);
  onInvoke(Map<String, dynamic> params) async {
    var rows = [];
    for (var id_A in ids) {
      SimpleNode node = link.provider.getNode("/${id_A}");
      var map_A = {};
      v(String name_A) {
        return (node.getChild(name_A) as SimpleNode).lastValueUpdate.value;
      }
      map_A["id"] = node.path.split("/").last;
      map_A["title"] = v("Title");
      map_A["place"] = v("Place");
      map_A["alert"] = v("Alert");
      map_A["magnitude"] = v("Magnitude");
      map_A["latitude"] = v("Latitude");
      map_A["longitude"] = v("Longitude");
      map_A["depth"] = v("Depth");
      rows.add(map_A);
    }
    return rows;
  }
}
getEarthquakeInformation() async {
  try {
    Response response_B = await get_A(DAY_URL);
    if (response_B.statusCode != 200) {
      return null;
    }
    return JSON.decode(response_B.body);
  } catch (e) {
    return null;
  }
}
final token_A = new RegExp(r'[^()<>@,;:"\\/[\]?={} \t\x00-\x1F\x7F]+');
final _lws = new RegExp(r"(?:\r\n)?[ \t]+");
final _quotedString = new RegExp(r'"(?:[^"\x00-\x1F\x7F]|\\.)*"');
final _quotedPair = new RegExp(r'\\(.)');
final nonToken = new RegExp(r'[()<>@,;:"\\/\[\]?={} \t\x00-\x1F\x7F]');
final whitespace = new RegExp("(?:${_lws.pattern})*");
String expectQuotedString(StringScanner scanner, {String name}) {
  if (name == null) name = "quoted string";
  scanner.expect(_quotedString, name: name);
  var string_A = scanner.lastMatch[0];
  return string_A.substring(1, string_A.length - 1).replaceAllMapped(_quotedPair, (match) => match[1]);
}
abstract class SourceSpan implements Comparable<SourceSpan> {
  factory SourceSpan(SourceLocation_A start_A, SourceLocation_A end_A, String text_A) => new SourceSpanBase(start_A, end_A, text_A);
}
class SourceSpanBase extends SourceSpanMixin {
  final SourceLocation_A start;
  final SourceLocation_A end;
  final String text;
  SourceSpanBase(this.start, this.end, this.text) {
    if (end.sourceUrl != start.sourceUrl) {
      throw new ArgumentError("Source URLs \"${start.sourceUrl}\" and " " \"${end.sourceUrl}\" don't match.");
    } else if (end.offset < start.offset) {
      throw new ArgumentError('End ${end} must come after start ${start}.');
    } else if (text.length != start.distance(end)) {
      throw new ArgumentError('Text "${text}" must be ${start.distance(end)} ' 'characters long.');
    }
  }
}
class SourceSpanException implements Exception {
  String get message => _message;
  final String _message;
  SourceSpan get span => _span;
  final SourceSpan _span;
  SourceSpanException(this._message, this._span);
  String toString({color}) {
    if (span == null) return message;
    return "Error on " + span.message(message, color: color);
  }
}
class SourceSpanFormatException extends SourceSpanException implements FormatException {
  dynamic get source => _source_A;
  final _source_A;
  int get offset => span == null ? null : span.start.offset;
  SourceSpanFormatException(String message_A, SourceSpan span, [this._source_A]) : super(message_A, span);
}
abstract class SourceSpanMixin implements SourceSpan {
  Uri get sourceUrl => start.sourceUrl;
  int get length => end.offset - start.offset;
  int compareTo(SourceSpan other) {
    var result_A = start.compareTo(other.start);
    return result_A == 0 ? end.compareTo(other.end) : result_A;
  }
  SourceSpan union(SourceSpan other) {
    if (sourceUrl != other.sourceUrl) {
      throw new ArgumentError("Source URLs \"${sourceUrl}\" and " " \"${other.sourceUrl}\" don't match.");
    }
    var start_A = min_A(this.start, other.start);
    var end_A = max_A(this.end, other.end);
    var beginSpan = start_A == this.start ? this : other;
    var endSpan = end_A == this.end ? this : other;
    if (beginSpan.end.compareTo(endSpan.start) < 0) {
      throw new ArgumentError("Spans ${this} and ${other} are disjoint.");
    }
    var text_A = beginSpan.text + endSpan.text.substring(beginSpan.end.distance(endSpan.start));
    return new SourceSpan(start_A, end_A, text_A);
  }
  String message(String message_A, {color}) {
    if (color == true) color = RED;
    if (color == false) color = null;
    var line_A = start.line;
    var column_A = start.column;
    var buffer_A = new StringBuffer();
    buffer_A.write('line ${line_A + 1}, column ${column_A + 1}');
    if (sourceUrl != null) buffer_A.write(' of ${prettyUri(sourceUrl)}');
    buffer_A.write(': ${message_A}');
    if (length == 0 && this is! SourceSpanWithContext) return buffer_A.toString();
    buffer_A.write("\n");
    var textLine;
    if (this is SourceSpanWithContext) {
      var context_B = (this as SourceSpanWithContext).context;
      var lineStart = findLineStart(context_B, text, column_A);
      if (lineStart != null && lineStart > 0) {
        buffer_A.write(context_B.substring(0, lineStart));
        context_B = context_B.substring(lineStart);
      }
      var endIndex = context_B.indexOf('\n');
      textLine = endIndex == -1 ? context_B : context_B.substring(0, endIndex + 1);
      column_A = _A.min(column_A, textLine.length);
    } else {
      textLine = text.split("\n").first;
      column_A = 0;
    }
    var toColumn = _A.min(column_A + end.offset - start.offset, textLine.length);
    if (color != null) {
      buffer_A.write(textLine.substring(0, column_A));
      buffer_A.write(color);
      buffer_A.write(textLine.substring(column_A, toColumn));
      buffer_A.write(NONE_A);
      buffer_A.write(textLine.substring(toColumn));
    } else {
      buffer_A.write(textLine);
    }
    if (!textLine.endsWith('\n')) buffer_A.write('\n');
    buffer_A.write(' ' * column_A);
    if (color != null) buffer_A.write(color);
    buffer_A.write('^' * _A.max(toColumn - column_A, 1));
    if (color != null) buffer_A.write(NONE_A);
    return buffer_A.toString();
  }
  bool operator==(other) => other is SourceSpan && start == other.start && end == other.end;
  int get hashCode => start.hashCode + (31 * end.hashCode);
  String toString() => '<${runtimeType}: from ${start} to ${end} "${text}">';
}
class SourceSpanWithContext extends SourceSpanBase {}
class DelegatingStream<T_A> extends StreamView<T_A> {
  static Stream typed_C(Stream stream_A) => stream_A is Stream ? stream_A : new TypeSafeStream(stream_A);
}
class TypeSafeStream<T_A> implements Stream<T_A> {
  final Stream _stream_C;
  Future<T_A> get first async => (await _stream_C.first) as T_A;
  Future<T_A> get last async => (await _stream_C.last) as T_A;
  Future<T_A> get single async => (await _stream_C.single) as T_A;
  bool get isBroadcast => _stream_C.isBroadcast;
  Future<bool> get isEmpty => _stream_C.isEmpty;
  Future<int> get length => _stream_C.length;
  TypeSafeStream(this._stream_C);
  Stream<T_A> asBroadcastStream({void onListen(StreamSubscription<T_A> subscription), void onCancel(StreamSubscription<T_A> subscription)}) {
    return new TypeSafeStream<T_A>(_stream_C.asBroadcastStream(onListen: onListen == null ? null : (subscription_A) => onListen(new TypeSafeStreamSubscription<T_A>(subscription_A)), onCancel: onCancel == null ? null : (subscription_A) => onCancel(new TypeSafeStreamSubscription<T_A>(subscription_A))));
  }
  Stream asyncExpand(Stream convert_A(T_A event)) => _stream_C.asyncExpand(_validateType(convert_A));
  Stream asyncMap(convert_A(T_A event)) => _stream_C.asyncMap(_validateType(convert_A));
  Stream<T_A> distinct([bool equals(T_A previous, T_A next)]) => new TypeSafeStream<T_A>(_stream_C.distinct(equals == null ? null : (previous_A, next_A) => equals(previous_A as T_A, next_A as T_A)));
  Future drain([futureValue]) => _stream_C.drain(futureValue);
  Stream expand(Iterable convert_A(T_A value)) => _stream_C.expand(_validateType(convert_A));
  Future firstWhere(bool test_A(T_A element), {Object defaultValue()}) => _stream_C.firstWhere(_validateType(test_A), defaultValue: defaultValue);
  Future lastWhere(bool test_A(T_A element), {Object defaultValue()}) => _stream_C.lastWhere(_validateType(test_A), defaultValue: defaultValue);
  Future<T_A> singleWhere(bool test_A(T_A element)) async => (await _stream_C.singleWhere(_validateType(test_A))) as T_A;
  Future fold(initialValue, combine_A(previous, T_A element)) => _stream_C.fold(initialValue, (previous_A, element_A) => combine_A(previous_A, element_A as T_A));
  Future forEach(void action(T_A element)) => _stream_C.forEach(_validateType(action));
  Stream<T_A> handleError(Function onError_A, {bool test(error)}) => new TypeSafeStream<T_A>(_stream_C.handleError(onError_A, test: test));
  StreamSubscription<T_A> listen(void onData_A(T_A value), {Function onError, void onDone(), bool cancelOnError}) => new TypeSafeStreamSubscription<T_A>(_stream_C.listen(_validateType(onData_A), onError: onError, onDone: onDone, cancelOnError: cancelOnError));
  Stream map(convert_A(T_A event)) => _stream_C.map(_validateType(convert_A));
  Future pipe(StreamConsumer<T_A> consumer) => consumer.addStream(this).then((__I) => consumer.close());
  Future<T_A> reduce(T_A combine_A(T_A previous, T_A element)) async {
    var result_A = await _stream_C.reduce((previous_A, element_A) => combine_A(previous_A as T_A, element_A as T_A));
    return result_A as T_A;
  }
  Stream<T_A> skipWhile(bool test_A(T_A element)) => new TypeSafeStream<T_A>(_stream_C.skipWhile(_validateType(test_A)));
  Stream<T_A> takeWhile(bool test_A(T_A element)) => new TypeSafeStream<T_A>(_stream_C.takeWhile(_validateType(test_A)));
  Stream timeout(Duration timeLimit, {void onTimeout(EventSink sink)}) => _stream_C.timeout(timeLimit, onTimeout: onTimeout);
  Future<List<T_A>> toList() async => DelegatingList.typed(await _stream_C.toList());
  Future<Set<T_A>> toSet() async => DelegatingSet.typed_D(await _stream_C.toSet());
  Stream transform(StreamTransformer<T_A, dynamic> transformer) => transformer.bind(this);
  Stream<T_A> where(bool test_A(T_A element)) => new TypeSafeStream<T_A>(_stream_C.where(_validateType(test_A)));
  Future<bool> every(bool test_A(T_A element)) => _stream_C.every(_validateType(test_A));
  Future<bool> any(bool test_A(T_A element)) => _stream_C.any(_validateType(test_A));
  Stream<T_A> skip(int count_A) => new TypeSafeStream<T_A>(_stream_C.skip(count_A));
  Stream<T_A> take(int count_A) => new TypeSafeStream<T_A>(_stream_C.take(count_A));
  Future<T_A> elementAt(int index_A) async => (await _stream_C.elementAt(index_A)) as T_A;
  Future<bool> contains(Object needle) => _stream_C.contains(needle);
  Future<String> join([String separator = ""]) => _stream_C.join(separator);
  String toString() => _stream_C.toString();
  UnaryFunction _validateType(function_A(T_A value)) => function_A == null ? null : (value_A) => function_A(value_A as T_A);
}
class DelegatingStreamConsumer<T_A> implements StreamConsumer<T_A> {
  final StreamConsumer _consumer_A;
  DelegatingStreamConsumer.__H(this._consumer_A);
  static StreamConsumer typed_B(StreamConsumer consumer) => consumer is StreamConsumer ? consumer : new DelegatingStreamConsumer.__H(consumer);
  Future addStream(Stream<T_A> stream_A) => _consumer_A.addStream(stream_A);
  Future close() => _consumer_A.close();
}
class TypeSafeStreamSubscription<T_A> implements StreamSubscription<T_A> {
  final StreamSubscription _subscription_C;
  bool get isPaused => _subscription_C.isPaused;
  TypeSafeStreamSubscription(this._subscription_C);
  void onData(void handleData(T_A data)) {
    _subscription_C.onData((data_A) => handleData(data_A as T_A));
  }
  void onError(Function handleError_A) {
    _subscription_C.onError(handleError_A);
  }
  void onDone(void handleDone()) {
    _subscription_C.onDone(handleDone);
  }
  void pause([Future resumeFuture]) {
    _subscription_C.pause(resumeFuture);
  }
  void resume() {
    _subscription_C.resume();
  }
  Future cancel() => _subscription_C.cancel();
  Future asFuture([futureValue]) => _subscription_C.asFuture(futureValue);
}
class StreamedResponse extends BaseResponse {
  final ByteStream stream;
  StreamedResponse(Stream<List<int>> stream_A, int statusCode_A, {int contentLength, BaseRequest request, Map<String, String> headers: const{}, bool isRedirect: false, bool persistentConnection: true, String reasonPhrase}) : this.stream = toByteStream(stream_A), super(statusCode_A, contentLength: contentLength, request: request, headers: headers, isRedirect: isRedirect, persistentConnection: persistentConnection, reasonPhrase: reasonPhrase);
}
final _slashAutoEscape = new RegExp("/").pattern == "\\/";
class StringScanner {
  final Uri sourceUrl;
  final String string;
  int get position => _position_A;
  set position(int position_A) {
    if (position_A < 0 || position_A > string.length) {
      throw new ArgumentError("Invalid position ${position_A}");
    }
    _position_A = position_A;
    _lastMatch = null;
  }
  int _position_A = 0;
  Match get lastMatch {
    if (_position_A != _lastMatchPosition) _lastMatch = null;
    return _lastMatch;
  }
  Match _lastMatch;
  int _lastMatchPosition;
  String get rest => string.substring(position);
  bool get isDone => position == string.length;
  StringScanner(this.string, {sourceUrl, int position}) : sourceUrl = sourceUrl is String ? Uri.parse(sourceUrl) : sourceUrl {
    if (position != null) this.position = position;
  }
  bool scan(Pattern pattern_A) {
    var success = matches(pattern_A);
    if (success) {
      _position_A = _lastMatch.end;
      _lastMatchPosition = _position_A;
    }
    return success;
  }
  void expect(Pattern pattern_A, {String name}) {
    if (scan(pattern_A)) return;
    if (name == null) {
      if (pattern_A is RegExp) {
        var source_A = pattern_A.pattern;
        if (!_slashAutoEscape) source_A = source_A.replaceAll("/", "\\/");
        name = "/${source_A}/";
      } else {
        name = pattern_A.toString().replaceAll("\\", "\\\\").replaceAll('"', '\\"');
        name = '"${name}"';
      }
    }
    _fail_A(name);
  }
  void expectDone() {
    if (isDone) return;
    _fail_A("no more input");
  }
  bool matches(Pattern pattern_A) {
    _lastMatch = pattern_A.matchAsPrefix(string, position);
    _lastMatchPosition = _position_A;
    return _lastMatch != null;
  }
  String substring(int start_A, [int end_A]) {
    if (end_A == null) end_A = position;
    return string.substring(start_A, end_A);
  }
  void error(String message_A, {Match match, int position, int length}) {
    validateErrorArgs(string, match, position, length);
    if (match == null && position == null && length == null) match = lastMatch;
    if (position == null) {
      position = match == null ? this.position : match.start;
    }
    if (length == null) length = match == null ? 0 : match.end - match.start;
    var sourceFile = new SourceFile(string, url: sourceUrl);
    var span = sourceFile.span(position, position + length);
    throw new StringScannerException(message_A, span, string);
  }
  void _fail_A(String name_A) {
    error("expected ${name_A}.", position: this.position, length: 0);
  }
}
typedef F_A _UnaryFunction<E_A, F_A>(E_A _0);
abstract class _TypeSafeIterableBase<E_A> implements Iterable<E_A> {
  Iterable get _base_A;
  _TypeSafeIterableBase();
  bool any(bool test_A(E_A element)) => _base_A.any(_validate_A(test_A));
  bool contains(Object element_A) => _base_A.contains(element_A);
  E_A elementAt(int index_A) => _base_A.elementAt(index_A) as E_A;
  bool every(bool test_A(E_A element)) => _base_A.every(_validate_A(test_A));
  Iterable expand(Iterable f(E_A element)) => _base_A.expand(_validate_A(f));
  E_A get first => _base_A.first as E_A;
  E_A firstWhere(bool test_A(E_A element), {E_A orElse()}) => _base_A.firstWhere(_validate_A(test_A), orElse: orElse) as E_A;
  fold(initialValue, combine_A(previousValue, E_A element)) => _base_A.fold(initialValue, (previousValue, element_A) => combine_A(previousValue, element_A as E_A));
  void forEach(void f(E_A element)) => _base_A.forEach(_validate_A(f));
  bool get isEmpty => _base_A.isEmpty;
  bool get isNotEmpty => _base_A.isNotEmpty;
  Iterator<E_A> get iterator => _base_A.map((element_A) => element_A as E_A).iterator;
  String join([String separator = ""]) => _base_A.join(separator);
  E_A get last => _base_A.last as E_A;
  E_A lastWhere(bool test_A(E_A element), {E_A orElse()}) => _base_A.lastWhere(_validate_A(test_A), orElse: orElse) as E_A;
  int get length => _base_A.length;
  Iterable map(f(E_A element)) => _base_A.map(_validate_A(f));
  E_A reduce(E_A combine_A(E_A value, E_A element)) => _base_A.reduce((value_A, element_A) => combine_A(value_A as E_A, element_A as E_A)) as E_A;
  E_A get single => _base_A.single as E_A;
  E_A singleWhere(bool test_A(E_A element)) => _base_A.singleWhere(_validate_A(test_A)) as E_A;
  Iterable<E_A> skip(int n) => new TypeSafeIterable<E_A>(_base_A.skip(n));
  Iterable<E_A> skipWhile(bool test_A(E_A value)) => new TypeSafeIterable<E_A>(_base_A.skipWhile(_validate_A(test_A)));
  Iterable<E_A> take(int n) => new TypeSafeIterable<E_A>(_base_A.take(n));
  Iterable<E_A> takeWhile(bool test_A(E_A value)) => new TypeSafeIterable<E_A>(_base_A.takeWhile(_validate_A(test_A)));
  List<E_A> toList({bool growable: true}) => new TypeSafeList<E_A>(_base_A.toList(growable: growable));
  Set<E_A> toSet() => new TypeSafeSet<E_A>(_base_A.toSet());
  Iterable<E_A> where(bool test_A(E_A element)) => new TypeSafeIterable<E_A>(_base_A.where(_validate_A(test_A)));
  String toString() => _base_A.toString();
  _UnaryFunction _validate_A(function_A(E_A value)) => (value_A) => function_A(value_A as E_A);
}
class TypeSafeIterable<E_A> extends _TypeSafeIterableBase<E_A> implements DelegatingIterable<E_A> {
  final Iterable _base_A;
  TypeSafeIterable(Iterable base_A) : _base_A = base_A;
}
class TypeSafeList<E_A> extends TypeSafeIterable<E_A> implements DelegatingList<E_A> {
  TypeSafeList(List base_A) : super(base_A);
  List get _listBase => _base_A;
  E_A operator[](int index_A) => _listBase[index_A] as E_A;
  void operator[]=(int index_A, E_A value_A) {
    _listBase[index_A] = value_A;
  }
  void add(E_A value_A) {
    _listBase.add(value_A);
  }
  void addAll(Iterable<E_A> iterable) {
    _listBase.addAll(iterable);
  }
  Map<int, E_A> asMap() => new TypeSafeMap<int, E_A>(_listBase.asMap());
  void clear() {
    _listBase.clear();
  }
  void fillRange(int start_A, int end_A, [E_A fillValue]) {
    _listBase.fillRange(start_A, end_A, fillValue);
  }
  Iterable<E_A> getRange(int start_A, int end_A) => new TypeSafeIterable<E_A>(_listBase.getRange(start_A, end_A));
  int indexOf(E_A element_A, [int start_A = 0]) => _listBase.indexOf(element_A, start_A);
  void insert(int index_A, E_A element_A) {
    _listBase.insert(index_A, element_A);
  }
  void insertAll(int index_A, Iterable<E_A> iterable) {
    _listBase.insertAll(index_A, iterable);
  }
  int lastIndexOf(E_A element_A, [int start_A]) => _listBase.lastIndexOf(element_A, start_A);
  void set length(int newLength) {
    _listBase.length = newLength;
  }
  bool remove(Object value_A) => _listBase.remove(value_A);
  E_A removeAt(int index_A) => _listBase.removeAt(index_A) as E_A;
  E_A removeLast() => _listBase.removeLast() as E_A;
  void removeRange(int start_A, int end_A) {
    _listBase.removeRange(start_A, end_A);
  }
  void removeWhere(bool test_A(E_A element)) {
    _listBase.removeWhere(_validate_A(test_A));
  }
  void replaceRange(int start_A, int end_A, Iterable<E_A> iterable) {
    _listBase.replaceRange(start_A, end_A, iterable);
  }
  void retainWhere(bool test_A(E_A element)) {
    _listBase.retainWhere(_validate_A(test_A));
  }
  Iterable<E_A> get reversed => new TypeSafeIterable<E_A>(_listBase.reversed);
  void setAll(int index_A, Iterable<E_A> iterable) {
    _listBase.setAll(index_A, iterable);
  }
  void setRange(int start_A, int end_A, Iterable<E_A> iterable, [int skipCount = 0]) {
    _listBase.setRange(start_A, end_A, iterable, skipCount);
  }
  void shuffle([Random random]) {
    _listBase.shuffle(random);
  }
  void sort([int compare_A(E_A a, E_A b)]) {
    if (compare_A == null) {
      _listBase.sort();
    } else {
      _listBase.sort((a, b) => compare_A(a as E_A, b as E_A));
    }
  }
  List<E_A> sublist(int start_A, [int end_A]) => new TypeSafeList<E_A>(_listBase.sublist(start_A, end_A));
}
class TypeSafeSet<E_A> extends TypeSafeIterable<E_A> implements DelegatingSet<E_A> {
  TypeSafeSet(Set base_A) : super(base_A);
  Set get _setBase => _base_A;
  bool add(E_A value_A) => _setBase.add(value_A);
  void addAll(Iterable<E_A> elements) {
    _setBase.addAll(elements);
  }
  void clear() {
    _setBase.clear();
  }
  bool containsAll(Iterable<Object> other) => _setBase.containsAll(other);
  Set<E_A> difference(Set<E_A> other) => new TypeSafeSet<E_A>(_setBase.difference(other));
  Set<E_A> intersection(Set<Object> other) => new TypeSafeSet<E_A>(_setBase.intersection(other));
  E_A lookup(Object element_A) => _setBase.lookup(element_A) as E_A;
  bool remove(Object value_A) => _setBase.remove(value_A);
  void removeAll(Iterable<Object> elements) {
    _setBase.removeAll(elements);
  }
  void removeWhere(bool test_A(E_A element)) {
    _setBase.removeWhere(_validate_A(test_A));
  }
  void retainAll(Iterable<Object> elements) {
    _setBase.retainAll(elements);
  }
  void retainWhere(bool test_A(E_A element)) {
    _setBase.retainWhere(_validate_A(test_A));
  }
  Set<E_A> union(Set<E_A> other) => new TypeSafeSet<E_A>(_setBase.union(other));
}
class TypeSafeMap<K, V> implements DelegatingMap<K, V> {
  final Map _base_A;
  TypeSafeMap(Map base_A) : _base_A = base_A;
  V operator[](Object key_A) => _base_A[key_A] as V;
  void operator[]=(K key_A, V value_A) {
    _base_A[key_A] = value_A;
  }
  void addAll(Map<K, V> other) {
    _base_A.addAll(other);
  }
  void clear() {
    _base_A.clear();
  }
  bool containsKey(Object key_A) => _base_A.containsKey(key_A);
  bool containsValue(Object value_A) => _base_A.containsValue(value_A);
  void forEach(void f(K key, V value)) {
    _base_A.forEach((key_A, value_A) => f(key_A as K, value_A as V));
  }
  bool get isEmpty => _base_A.isEmpty;
  bool get isNotEmpty => _base_A.isNotEmpty;
  Iterable<K> get keys => new TypeSafeIterable<K>(_base_A.keys);
  int get length => _base_A.length;
  V putIfAbsent(K key_A, V ifAbsent()) => _base_A.putIfAbsent(key_A, ifAbsent) as V;
  V remove(Object key_A) => _base_A.remove(key_A) as V;
  Iterable<V> get values => new TypeSafeIterable<V>(_base_A.values);
  String toString() => _base_A.toString();
}
class Usage {
  static const NUM_COLUMNS = 3;
  final List optionsAndSeparators;
  StringBuffer buffer;
  int currentColumn = 0;
  List<int> columnWidths;
  int numHelpLines = 0;
  int newlinesNeeded = 0;
  Usage(this.optionsAndSeparators);
  String generate_A() {
    buffer = new StringBuffer();
    calculateColumnWidths();
    for (var optionOrSeparator in optionsAndSeparators) {
      if (optionOrSeparator is String) {
        if (buffer.isNotEmpty) buffer.write("\n\n");
        buffer.write(optionOrSeparator);
        newlinesNeeded = 1;
        continue;
      }
      var option = optionOrSeparator as Option;
      if (option.hide) continue;
      write(0, getAbbreviation(option));
      write(1, getLongOption(option));
      if (option.help != null) write(2, option.help);
      if (option.allowedHelp != null) {
        var allowedNames = option.allowedHelp.keys.toList(growable: false);
        allowedNames.sort();
        newline();
        for (var name_A in allowedNames) {
          write(1, getAllowedTitle(name_A));
          write(2, option.allowedHelp[name_A]);
        }
        newline();
      } else if (option.allowed != null) {
        write(2, buildAllowedList(option));
      } else if (option.defaultValue != null) {
        if (option.isFlag && option.defaultValue == true) {
          write(2, '(defaults to on)');
        } else if (!option.isFlag) {
          write(2, '(defaults to "${option.defaultValue}")');
        }
      }
      if (numHelpLines > 1) newline();
    }
    return buffer.toString();
  }
  String getAbbreviation(Option option) {
    if (option.abbreviation != null) {
      return '-${option.abbreviation}, ';
    } else {
      return '';
    }
  }
  String getLongOption(Option option) {
    var result_A;
    if (option.negatable) {
      result_A = '--[no-]${option.name}';
    } else {
      result_A = '--${option.name}';
    }
    if (option.valueHelp != null) result_A += "=<${option.valueHelp}>";
    return result_A;
  }
  String getAllowedTitle(String allowed) {
    return '      [${allowed}]';
  }
  void calculateColumnWidths() {
    int abbr = 0;
    int title = 0;
    for (var option in optionsAndSeparators) {
      if (option is! Option) continue;
      if (option.hide) continue;
      abbr = _A.max(abbr, getAbbreviation(option).length);
      title = _A.max(title, getLongOption(option).length);
      if (option.allowedHelp != null) {
        for (var allowed in option.allowedHelp.keys) {
          title = _A.max(title, getAllowedTitle(allowed).length);
        }
      }
    }
    title += 4;
    columnWidths = [abbr, title];
  }
  void newline() {
    newlinesNeeded++;
    currentColumn = 0;
    numHelpLines = 0;
  }
  void write(int column_A, String text_A) {
    var lines = text_A.split('\n');
    while (lines.length > 0 && lines[0].trim() == '') {
      lines.removeRange(0, 1);
    }
    while (lines.length > 0 && lines[lines.length - 1].trim() == '') {
      lines.removeLast();
    }
    for (var line_A in lines) {
      writeLine(column_A, line_A);
    }
  }
  void writeLine(int column_A, String text_A) {
    while (newlinesNeeded > 0) {
      buffer.write('\n');
      newlinesNeeded--;
    }
    while (currentColumn != column_A) {
      if (currentColumn < NUM_COLUMNS - 1) {
        buffer.write(padRight_A('', columnWidths[currentColumn]));
      } else {
        buffer.write('\n');
      }
      currentColumn = (currentColumn + 1) % NUM_COLUMNS;
    }
    if (column_A < columnWidths.length) {
      buffer.write(padRight_A(text_A, columnWidths[column_A]));
    } else {
      buffer.write(text_A);
    }
    currentColumn = (currentColumn + 1) % NUM_COLUMNS;
    if (column_A == NUM_COLUMNS - 1) newlinesNeeded++;
    if (column_A == NUM_COLUMNS - 1) {
      numHelpLines++;
    } else {
      numHelpLines = 0;
    }
  }
  String buildAllowedList(Option option) {
    var allowedBuffer = new StringBuffer();
    allowedBuffer.write('[');
    bool first_A = true;
    for (var allowed in option.allowed) {
      if (!first_A) allowedBuffer.write(', ');
      allowedBuffer.write(allowed);
      if (allowed == option.defaultValue) {
        allowedBuffer.write(' (default)');
      }
      first_A = false;
    }
    allowedBuffer.write(']');
    return allowedBuffer.toString();
  }
}
String padRight_A(String source_A, int length_A) {
  final result_A = new StringBuffer();
  result_A.write(source_A);
  while (result_A.length < length_A) {
    result_A.write(' ');
  }
  return result_A.toString();
}
typedef F_A UnaryFunction<E_A, F_A>(E_A _0);
class Pair<E_A, F_A> {
  E_A first;
  F_A last;
  Pair(this.first, this.last);
}
String mapToQuery(Map<String, String> map_A, {Encoding encoding}) {
  var pairs = <List<String>>[];
  map_A.forEach((key_A, value_A) => pairs.add([Uri.encodeQueryComponent(key_A, encoding: encoding), Uri.encodeQueryComponent(value_A, encoding: encoding)]));
  return pairs.map((pair) => "${pair[0]}=${pair[1]}").join("&");
}
Encoding encodingForCharset(String charset_A, [Encoding fallback = LATIN1]) {
  if (charset_A == null) return fallback;
  var encoding_A = Encoding.getByName(charset_A);
  return encoding_A == null ? fallback : encoding_A;
}
Encoding requiredEncodingForCharset(String charset_A) {
  var encoding_A = Encoding.getByName(charset_A);
  if (encoding_A != null) return encoding_A;
  throw new FormatException('Unsupported encoding "${charset_A}".');
}
Uint8List toUint8List_A(List<int> input_A) {
  if (input_A is Uint8List) return input_A;
  if (input_A is TypedData) {
    return new Uint8List.view((input_A as TypedData).buffer);
  }
  return new Uint8List.fromList(input_A);
}
ByteStream toByteStream(Stream<List<int>> stream_A) {
  if (stream_A is ByteStream) return stream_A;
  return new ByteStream(stream_A);
}
wrapFormatException(String name_A, String value_A, body()) {
  try {
    return body();
  }on SourceSpanFormatException  catch (error_A) {
    throw new SourceSpanFormatException('Invalid ${name_A}: ${error_A.message}', error_A.span, error_A.source);
  } on FormatException  catch (error_A) {
    throw new FormatException('Invalid ${name_A} "${value_A}": ${error_A.message}', error_A.source, error_A.offset);
  }
}
Comparable min_A(Comparable obj1, Comparable obj2) => obj1.compareTo(obj2) > 0 ? obj2 : obj1;
Comparable max_A(Comparable obj1, Comparable obj2) => obj1.compareTo(obj2) > 0 ? obj1 : obj2;
int findLineStart(String context_B, String text_A, int column_A) {
  var isEmpty_A = text_A == '';
  var index_A = context_B.indexOf(text_A);
  while (index_A != -1) {
    var lineStart = context_B.lastIndexOf('\n', index_A) + 1;
    var textColumn = index_A - lineStart;
    if (column_A == textColumn || (isEmpty_A && column_A == textColumn + 1)) {
      return lineStart;
    }
    index_A = context_B.indexOf(text_A, index_A + 1);
  }
  return null;
}
void validateErrorArgs(String string_A, Match match, int position_A, int length_A) {
  if (match != null && (position_A != null || length_A != null)) {
    throw new ArgumentError("Can't pass both match and position/length.");
  }
  if (position_A != null) {
    if (position_A < 0) {
      throw new RangeError("position must be greater than or equal to 0.");
    } else if (position_A > string_A.length) {
      throw new RangeError("position must be less than or equal to the " "string length.");
    }
  }
  if (length_A != null && length_A < 0) {
    throw new RangeError("length must be greater than or equal to 0.");
  }
  if (position_A != null && length_A != null && position_A + length_A > string_A.length) {
    throw new RangeError("position plus length must not go beyond the end of " "the string.");
  }
}
abstract class _DelegatingIterableBase<E_A> implements Iterable<E_A> {}
class DelegatingIterable<E_A> extends _DelegatingIterableBase<E_A> {}
class DelegatingList<E_A> extends DelegatingIterable<E_A> implements List<E_A> {
  static List typed(List base_A) => base_A is List ? base_A : new TypeSafeList(base_A);
}
class DelegatingSet<E_A> extends DelegatingIterable<E_A> implements Set<E_A> {
  static Set typed_D(Set base_A) => base_A is Set ? base_A : new TypeSafeSet(base_A);
}
class DelegatingMap<K, V> implements Map<K, V> {
  static Map typed_A(Map base_A) => base_A is Map ? base_A : new TypeSafeMap(base_A);
}
