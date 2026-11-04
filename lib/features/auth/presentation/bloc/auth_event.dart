import 'package:equatable/equatable.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

final class RestoreSessionRequested extends AuthEvent {
  const RestoreSessionRequested();
}

final class LoginRequested extends AuthEvent {
  const LoginRequested(this.userId);

  final String userId;

  @override
  List<Object?> get props => [userId];
}

final class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}
