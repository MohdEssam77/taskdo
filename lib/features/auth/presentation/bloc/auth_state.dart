import 'package:equatable/equatable.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final String token;
  final String username;
  final String email;
  final Map<String, dynamic>? userData;

  const AuthAuthenticated({
    required this.token,
    required this.username,
    required this.email,
    this.userData,
  });

  @override
  List<Object?> get props => [token, username, email, userData];
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class RegistrationSuccess extends AuthState {
  const RegistrationSuccess();
}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

class PasswordResetSent extends AuthState {
  const PasswordResetSent();
} 