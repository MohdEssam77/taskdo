class AppConfig {
  // Update this URL to match your FastAPI backend URL
  static const String baseUrl = 'http://localhost:8000';
  
  // Add other configuration constants here
  static const int apiTimeout = 30000; // 30 seconds
  static const String appName = 'TaskDo';

  // API endpoints
  static const String loginEndpoint = '/api/token';
  static const String registerEndpoint = '/api/register';
  static const String forgotPasswordEndpoint = '/api/forgot-password';
  static const String todosEndpoint = '/api/todos';
  static const String userEndpoint = '/api/users/me';

  // Headers
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
  };

  // Timeouts
  static const Duration connectionTimeout = Duration(milliseconds: 30000);
  static const Duration receiveTimeout = Duration(milliseconds: 30000);
} 