import 'dart:io' show Platform;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  static final EnvConfig _instance = EnvConfig._internal();
  factory EnvConfig() => _instance;
  EnvConfig._internal();

  bool _initialized = false;

  late final String supabaseUrl;
  late final String supabaseAnonKey;
  late final String googleClientId;
  late final String iosClientId;
  late final String publicKey;
  late final String privateKey;
  late final String ivKey;

  final Map<String, String> _runtimeEnv = {};

  Future<void> initialize() async {
    if (_initialized) return;

    _captureRuntimeEnvVars();

    bool envFileLoaded = false;
    try {
      await dotenv.load(fileName: ".env");
      envFileLoaded = true;
      print('Arquivo .env carregado com sucesso.');
    } catch (e) {
      print('Arquivo .env não encontrado. Usando variáveis de ambiente do sistema.');
    }

    supabaseUrl = _getEnvVariable('SUPABASE_URL', envFileLoaded);
    supabaseAnonKey = _getEnvVariable('SUPABASE_ANON_KEY', envFileLoaded);
    googleClientId = _getEnvVariable('GOOGLE_CLIENT_ID', envFileLoaded);
    iosClientId = _getEnvVariable('IOS_CLIENT_ID', envFileLoaded);
    publicKey = _getEnvVariable('PUBLIC_KEY', envFileLoaded);
    privateKey = _getEnvVariable('PRIVATE_KEY', envFileLoaded);
    ivKey = _getEnvVariable('IV_KEY', envFileLoaded);

    _initialized = true;
  }

  void _captureRuntimeEnvVars() {
    _runtimeEnv['SUPABASE_URL'] = Platform.environment['SUPABASE_URL'] ?? '';
    _runtimeEnv['SUPABASE_ANON_KEY'] = Platform.environment['SUPABASE_ANON_KEY'] ?? '';
    _runtimeEnv['GOOGLE_CLIENT_ID'] = Platform.environment['GOOGLE_CLIENT_ID'] ?? '';
    _runtimeEnv['IOS_CLIENT_ID'] = Platform.environment['IOS_CLIENT_ID'] ?? '';
    _runtimeEnv['PUBLIC_KEY'] = Platform.environment['PUBLIC_KEY'] ?? '';
    _runtimeEnv['PRIVATE_KEY'] = Platform.environment['PRIVATE_KEY'] ?? '';
    _runtimeEnv['IV_KEY'] = Platform.environment['IV_KEY'] ?? '';
    
    const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
    const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
    const googleClientId = String.fromEnvironment('GOOGLE_CLIENT_ID');
    const iosClientId = String.fromEnvironment('IOS_CLIENT_ID');
    const publicKey = String.fromEnvironment('PUBLIC_KEY');
    const privateKey = String.fromEnvironment('PRIVATE_KEY');
    const ivKey = String.fromEnvironment('IV_KEY');
    
    if (_runtimeEnv['SUPABASE_URL']!.isEmpty && supabaseUrl.isNotEmpty) _runtimeEnv['SUPABASE_URL'] = supabaseUrl;
    if (_runtimeEnv['SUPABASE_ANON_KEY']!.isEmpty && supabaseAnonKey.isNotEmpty) _runtimeEnv['SUPABASE_ANON_KEY'] = supabaseAnonKey;
    if (_runtimeEnv['GOOGLE_CLIENT_ID']!.isEmpty && googleClientId.isNotEmpty) _runtimeEnv['GOOGLE_CLIENT_ID'] = googleClientId;
    if (_runtimeEnv['IOS_CLIENT_ID']!.isEmpty && iosClientId.isNotEmpty) _runtimeEnv['IOS_CLIENT_ID'] = iosClientId;
    if (_runtimeEnv['PUBLIC_KEY']!.isEmpty && publicKey.isNotEmpty) _runtimeEnv['PUBLIC_KEY'] = publicKey;
    if (_runtimeEnv['PRIVATE_KEY']!.isEmpty && privateKey.isNotEmpty) _runtimeEnv['PRIVATE_KEY'] = privateKey;
    if (_runtimeEnv['IV_KEY']!.isEmpty && ivKey.isNotEmpty) _runtimeEnv['IV_KEY'] = ivKey;
  }

  String _getEnvVariable(String key, bool envFileLoaded) {
    String value = '';
    
    if (_runtimeEnv.containsKey(key) && _runtimeEnv[key]!.isNotEmpty) {
      value = _runtimeEnv[key]!;
    }
    
    if (value.isEmpty && envFileLoaded) {
      value = dotenv.env[key] ?? '';
    }
    
    if (value.isEmpty) {
      throw Exception('Variável de ambiente $key não encontrada. '
          'Defina-a no arquivo .env ou use --dart-define=$key=valor ao compilar.');
    }
    
    return value;
  }

  void checkInitialized() {
    if (!_initialized) {
      throw Exception('EnvConfig não foi inicializado. Chame EnvConfig().initialize() antes de usar.');
    }
  }
}
