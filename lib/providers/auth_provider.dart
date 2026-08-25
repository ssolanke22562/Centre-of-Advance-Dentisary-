import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

enum AuthStatus { initial, authenticating, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final UserSession? session;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.session,
    this.errorMessage,
  });

  bool get isAuthenticated => status == AuthStatus.authenticated && session != null;
  bool get isAdmin => session?.isAdmin ?? false;
  bool get isReceptionist => session?.isReceptionist ?? false;

  AuthState copyWith({
    AuthStatus? status,
    UserSession? session,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      session: session ?? this.session,
      errorMessage: errorMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    checkActiveSession();
  }

  final AuthService _authService = AuthService.instance;

  Future<void> checkActiveSession() async {
    try {
      final session = await _authService.getActiveSession();
      if (session != null) {
        state = state.copyWith(
          status: AuthStatus.authenticated,
          session: session,
          errorMessage: null,
        );
      } else {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          session: null,
        );
      }
    } catch (_) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        session: null,
      );
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.authenticating, errorMessage: null);
    try {
      final session = await _authService.login(email, password);
      if (session != null) {
        state = state.copyWith(
          status: AuthStatus.authenticated,
          session: session,
          errorMessage: null,
        );
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
