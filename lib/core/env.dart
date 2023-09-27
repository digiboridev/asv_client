import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(path: '.env')
abstract class Env {
  @EnviedField(varName: 'APIKEY', obfuscate: true)
  static final apiKey = _Env.apiKey;
  @EnviedField(varName: 'APIURL', obfuscate: true)
  static final apiUrl = _Env.apiUrl;
  @EnviedField(varName: 'APIURLDEV', obfuscate: true)
  static final apiUrlDev = _Env.apiUrlDev;
  @EnviedField(varName: 'TURNU', obfuscate: true)
  static final turnU = _Env.turnU;
  @EnviedField(varName: 'TURNC', obfuscate: true)
  static final turnC = _Env.turnC;
}
