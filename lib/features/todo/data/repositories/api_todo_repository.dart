import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/entities/todo.dart';
import '../../domain/repositories/todo_repository.dart';
import 'package:taskdo/core/config.dart';

class ApiTodoRepository implements TodoRepository {
  final String? token;

  ApiTodoRepository({this.token});

  Map<String, String> get _headers {
    final headers = Map<String, String>.from(AppConfig.defaultHeaders);
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  @override
  Future<List<Todo>> getTodos() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}${AppConfig.todosEndpoint}'),
        headers: _headers,
      ).timeout(AppConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Todo.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load todos: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to load todos: $e');
    }
  }

  @override
  Future<Todo> createTodo(
    String title,
    String description,
    TodoPriority priority,
    TodoArea area,
    DateTime deadline,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}${AppConfig.todosEndpoint}'),
        headers: _headers,
        body: json.encode({
          'title': title,
          'description': description,
          'priority': priority.index + 1,
          'area': area.toString().split('.').last.toLowerCase(),
          'deadline': deadline.toIso8601String().split('T')[0],
        }),
      ).timeout(AppConfig.connectionTimeout);

      if (response.statusCode == 200) {
        return Todo.fromJson(json.decode(response.body));
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['detail'] ?? 'Failed to create todo');
      }
    } catch (e) {
      throw Exception('Failed to create todo: $e');
    }
  }

  @override
  Future<Todo> updateTodo(Todo todo) async {
    try {
      final response = await http.put(
        Uri.parse('${AppConfig.baseUrl}${AppConfig.todosEndpoint}/${todo.id}'),
        headers: _headers,
        body: json.encode({
          'title': todo.title,
          'description': todo.description,
          'completed': todo.completed,
          'priority': todo.priority.index + 1,
          'area': todo.area.toString().split('.').last.toLowerCase(),
          'deadline': todo.deadline.toIso8601String().split('T')[0],
          'updated_at': DateTime.now().toIso8601String(),
        }),
      ).timeout(AppConfig.connectionTimeout);

      if (response.statusCode == 200) {
        return Todo.fromJson(json.decode(response.body));
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['detail'] ?? 'Failed to update todo');
      }
    } catch (e) {
      throw Exception('Failed to update todo: $e');
    }
  }

  @override
  Future<void> deleteTodo(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('${AppConfig.baseUrl}${AppConfig.todosEndpoint}/$id'),
        headers: _headers,
      ).timeout(AppConfig.connectionTimeout);

      if (response.statusCode != 200) {
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['detail'] ?? 'Failed to delete todo');
      }
    } catch (e) {
      throw Exception('Failed to delete todo: $e');
    }
  }

  @override
  Future<void> toggleTodo(int id) async {
    try {
      // First get the current todo to check its completion status
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}${AppConfig.todosEndpoint}/$id'),
        headers: _headers,
      ).timeout(AppConfig.connectionTimeout);

      if (response.statusCode != 200) {
        throw Exception('Failed to get todo status');
      }

      final todo = json.decode(response.body);
      final currentStatus = todo['completed'] ?? false;

      // Update the todo with the opposite status
      final updateResponse = await http.put(
        Uri.parse('${AppConfig.baseUrl}${AppConfig.todosEndpoint}/$id'),
        headers: _headers,
        body: json.encode({
          'completed': !currentStatus,
          'updated_at': DateTime.now().toIso8601String(),
        }),
      ).timeout(AppConfig.connectionTimeout);

      if (updateResponse.statusCode != 200) {
        final errorBody = json.decode(updateResponse.body);
        throw Exception(errorBody['detail'] ?? 'Failed to toggle todo');
      }
    } catch (e) {
      throw Exception('Failed to toggle todo: $e');
    }
  }
} 