import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mads_safebox/models/user.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserNotifier extends StateNotifier<UserSB?> {
  UserNotifier() : super(null) {
    _init();
  }

  void _init() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      final session = data.session;

      if (event == AuthChangeEvent.signedIn && session != null) {
        final sessionUser = session.user;
        state = UserSB(
          id: sessionUser.id,
          nome: sessionUser.userMetadata?['display_name'] ?? sessionUser.userMetadata?['name'] ?? '',
        );
      } else if (event == AuthChangeEvent.signedOut) {
        state = null;
      }
    });

    // Inicializar se já estiver logado
    final currentSession = Supabase.instance.client.auth.currentSession;
    if (currentSession != null) {
      final sessionUser = currentSession.user;
      state = UserSB(
        id: sessionUser.id,
        nome: sessionUser.userMetadata?['display_name'] ?? sessionUser.userMetadata?['name'] ?? '',
      );
    }
  }
}

final userProvider = StateNotifierProvider<UserNotifier, UserSB?>((ref) {
  return UserNotifier();
});


