import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/exceptions/auth_exception.dart';
import '../../domain/usecases/login_with_user_id.dart';
import '../../domain/usecases/logout.dart';
import '../../domain/usecases/restore_session.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required LoginWithUserId loginWithUserId,
    required RestoreSession restoreSession,
    required Logout logout,
  })  : _loginWithUserId = loginWithUserId,
        _restoreSession = restoreSession,
        _logout = logout,
        super(const AuthLoading()) {
    on<RestoreSessionRequested>(_onRestoreSessionRequested);
    on<LoginRequested>(_onLoginRequested);
    on<LogoutRequested>(_onLogoutRequested);
    add(const RestoreSessionRequested());
  }

  final LoginWithUserId _loginWithUserId;
  final RestoreSession _restoreSession;
  final Logout _logout;

  Future<void> _onRestoreSessionRequested(
    RestoreSessionRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final user = await _restoreSession();
      if (user == null) {
        emit(const AuthUnauthenticated());
      } else {
        emit(AuthAuthenticated(user));
      }
    } on AuthException catch (error) {
      emit(AuthFailure(error.message));
    }
  }

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    final userId = int.tryParse(event.userId.trim());
    if (userId == null || userId <= 0) {
      emit(const AuthFailure('Enter a valid positive user ID.'));
      return;
    }

    emit(const AuthLoading());
    try {
      emit(AuthAuthenticated(await _loginWithUserId(userId)));
    } on AuthException catch (error) {
      emit(AuthFailure(error.message));
    }
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await _logout();
      emit(const AuthUnauthenticated());
    } on AuthException catch (error) {
      emit(AuthFailure(error.message));
    }
  }
}
