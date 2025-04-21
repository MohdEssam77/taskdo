import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SharedPreferences _prefs;
  final AuthRepository _authRepository;
  static const _tokenKey = 'auth_token';
  static const _usernameKey = 'username';
  static const _emailKey = 'email';

  AuthBloc(this._prefs)
      : _authRepository = AuthRepository(),
        super(const AuthInitial()) {
    on<LoginEvent>(_onLogin);
    on<RegisterEvent>(_onRegister);
    on<ForgotPasswordEvent>(_onForgotPassword);
    on<LogoutEvent>(_onLogout);
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);
  }

  Future<void> _onLogin(LoginEvent event, Emitter<AuthState> emit) async {
    try {
      emit(const AuthLoading());
      final response = await _authRepository.login(
        event.username,
        event.password,
      );
      final token = response['access_token'] as String;
      await _prefs.setString(_tokenKey, token);
      await _prefs.setString(_usernameKey, event.username);
      emit(AuthAuthenticated(
        token: token,
        username: event.username,
        email: _prefs.getString(_emailKey) ?? '',
      ));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onRegister(RegisterEvent event, Emitter<AuthState> emit) async {
    try {
      emit(const AuthLoading());
      // First register the user
      await _authRepository.register(
        event.username,
        event.email,
        event.password,
      );
      // Store username and email
      await _prefs.setString(_usernameKey, event.username);
      await _prefs.setString(_emailKey, event.email);
      // Emit registration success state
      emit(const RegistrationSuccess());
      // Then attempt to log in
      final response = await _authRepository.login(
        event.username,
        event.password,
      );
      final token = response['access_token'] as String;
      await _prefs.setString(_tokenKey, token);
      emit(AuthAuthenticated(
        token: token,
        username: event.username,
        email: event.email,
      ));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onForgotPassword(
    ForgotPasswordEvent event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(const AuthLoading());
      await _authRepository.forgotPassword(event.email);
      emit(const PasswordResetSent());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onLogout(LogoutEvent event, Emitter<AuthState> emit) async {
    try {
      emit(const AuthLoading());
      await _prefs.remove(_tokenKey);
      await _prefs.remove(_usernameKey);
      await _prefs.remove(_emailKey);
      emit(const AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatusEvent event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(const AuthLoading());
      final token = _prefs.getString(_tokenKey);
      if (token != null) {
        final username = _prefs.getString(_usernameKey) ?? '';
        final email = _prefs.getString(_emailKey) ?? '';
        emit(AuthAuthenticated(
          token: token,
          username: username,
          email: email,
        ));
      } else {
        emit(const AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }
} 