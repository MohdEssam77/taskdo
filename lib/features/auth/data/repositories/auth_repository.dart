import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:taskdo/core/config.dart';

class AuthRepository {
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}${AppConfig.loginEndpoint}'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'username': username,
          'password': password,
        },
      ).timeout(AppConfig.connectionTimeout);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['detail'] ?? 'Failed to login');
      }
    } catch (e) {
      throw Exception('Failed to login: $e');
    }
  }

  Future<Map<String, dynamic>> register(
    String username,
    String email,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}${AppConfig.registerEndpoint}'),
        headers: AppConfig.defaultHeaders,
        body: json.encode({
          'username': username,
          'email': email,
          'password': password,
        }),
      ).timeout(AppConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        // After successful registration, automatically log in
        return await login(username, password);
      } else {
        final errorBody = json.decode(response.body);
        final errorMessage = errorBody['detail'] ?? 'Failed to register';
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e is http.ClientException) {
        throw Exception('Network error: ${e.message}');
      } else if (e is FormatException) {
        throw Exception('Invalid response format from server');
      } else {
        throw Exception('Failed to register: $e');
      }
    }
  }

  Future<void> forgotPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}${AppConfig.forgotPasswordEndpoint}'),
        headers: AppConfig.defaultHeaders,
        body: json.encode({'email': email}),
      ).timeout(AppConfig.connectionTimeout);

      if (response.statusCode != 200) {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['detail'] ?? 'Failed to send password reset email');
      }
    } catch (e) {
      throw Exception('Failed to send password reset email: $e');
    }
  }

  Future<Map<String, dynamic>> getUserData(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}${AppConfig.userEndpoint}'),
        headers: {
          ...AppConfig.defaultHeaders,
          'Authorization': 'Bearer $token',
        },
      ).timeout(AppConfig.connectionTimeout);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['detail'] ?? 'Failed to fetch user data');
      }
    } catch (e) {
      throw Exception('Failed to fetch user data: $e');
    }
  }
} 