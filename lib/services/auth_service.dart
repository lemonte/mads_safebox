import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mads_safebox/config/env_config.dart';
import '../models/user.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient supabaseClient = Supabase.instance.client;

  Future<UserSB> signInWithEmail(String email, String password) async {
    AuthResponse authResponse = await supabaseClient.auth.signInWithPassword(email: email, password: password);

    if (authResponse.user != null) {
      UserSB user = UserSB(id: authResponse.user!.id, nome: authResponse.user!.userMetadata?['display_name'] ?? '');
      return user;
    } else {
      throw Exception('Failed to sign in');
    }
  }

  Future<AuthResponse> signUp(String email, String password, String name) async {
    AuthResponse authResponse = await supabaseClient.auth.signUp(
      email: email,
      password: password,
      data: {'display_name': name},
    );
    await signOut();

    try {
      await supabaseClient.from('users').insert({'id': authResponse.user!.id, 'name': name});
    } on Exception catch (e) {
      debugPrint("Error inserting user: $e");
    }
    return authResponse;
  }

  Future<void> signOut() async {
    await supabaseClient.auth.signOut();
  }

  UserSB getCurrentUser() {
    final user = supabaseClient.auth.currentUser;
    if (user != null) {
      return UserSB(id: user.id, nome: user.userMetadata?['display_name'] ?? user.userMetadata?['name'] ?? '');
    } else {
      throw Exception('No user is currently signed in');
    }
  }

  Future<void> resetPassword(String email) async {
    await supabaseClient.auth.resetPasswordForEmail(email);
  }

  Future<void> nativeGoogleSignIn() async {
    try {
      debugPrint("Iniciando Google Sign-In...");

      final EnvConfig config = EnvConfig();

      try {
        config.checkInitialized();
        debugPrint("EnvConfig inicializado com sucesso");
      } catch (e) {
        debugPrint("ERRO: EnvConfig não inicializado: $e");
        throw Exception("Configuração de ambiente não encontrada: $e");
      }

      final GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId: config.googleClientId, // Web Client ID para Supabase
        clientId: config.iosClientId, // iOS Client ID para o redirect
      );
      debugPrint("GoogleSignIn criado com serverClientId: ${config.googleClientId}");
      debugPrint("GoogleSignIn criado com clientId: ${config.iosClientId}");

      // Sign out from any previous session
      await googleSignIn.signOut();
      debugPrint("Sign out anterior realizado");

      debugPrint("Iniciando processo de sign in...");
      final googleUser;
      try {
        googleUser = await googleSignIn.signIn().timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            debugPrint("TIMEOUT: Google Sign-In demorou mais de 30 segundos");
            return null;
          },
        );
        debugPrint("Resultado do signIn: $googleUser");
      } catch (signInError) {
        debugPrint("ERRO específico no signIn: $signInError");
        debugPrint("Tipo do erro: ${signInError.runtimeType}");
        rethrow;
      }

      if (googleUser == null) {
        debugPrint("Google sign-in foi cancelado pelo usuário");
        throw Exception('Google sign-in was canceled');
      }

      debugPrint("Obtendo credenciais de autenticação...");
      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      debugPrint("AccessToken: ${accessToken != null ? 'Presente' : 'Ausente'}");
      debugPrint("IdToken: ${idToken != null ? 'Presente' : 'Ausente'}");

      if (accessToken == null) {
        throw 'No Access Token found.';
      }
      if (idToken == null) {
        throw 'No ID Token found.';
      }

      debugPrint("Realizando sign in com Supabase...");
      await supabaseClient.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      debugPrint("Sign in com Supabase realizado com sucesso");
      UserSB user = getCurrentUser();
      debugPrint("Usuário atual obtido: ${user.nome}");

      try {
        await supabaseClient.from('users').upsert({'id': user.id, 'name': user.nome}, onConflict: 'id');
        debugPrint("Usuário inserido/atualizado no banco de dados");
      } on Exception catch (e) {
        debugPrint("Error inserting user: $e");
      }
    } catch (e) {
      debugPrint("Google Sign-In Error: $e");
      debugPrint("Stack trace: ${e.toString()}");
      rethrow;
    }
  }

  Future<void> signInWithFacebook() async {
    await supabaseClient.auth.signInWithOAuth(
      OAuthProvider.facebook,
      redirectTo: 'io.supabase.madsafebox://login-callback',
      authScreenLaunchMode: LaunchMode.platformDefault,
    );

    Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      final event = data.event;
      final session = data.session;

      if (event == AuthChangeEvent.signedIn && session != null) {
        final user = session.user;

        try {
          await supabaseClient.from('users').upsert({
            'id': user.id,
            'name': user.userMetadata?['name'],
          }, onConflict: 'id');
        } catch (e) {
          debugPrint("Error inserting user: $e");
        }
      }
    });
  }
}
