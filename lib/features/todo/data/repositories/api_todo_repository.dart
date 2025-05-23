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
  Future<Todo> createTodo(Todo todo) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}${AppConfig.todosEndpoint}'),
        headers: _headers,
        body: json.encode({
          'title': todo.title,
          'description': todo.description,
          'completed': todo.completed,
          if (todo.priority != null) 'priority': _priorityToNumber(todo.priority!),
          if (todo.area != null) 'area': todo.area!.name.toLowerCase(),
          if (todo.deadline != null) 'deadline': todo.deadline!.toIso8601String().split('T')[0],
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
          if (todo.priority != null) 'priority': _priorityToNumber(todo.priority!),
          if (todo.area != null) 'area': todo.area!.name.toLowerCase(),
          if (todo.deadline != null) 'deadline': todo.deadline!.toIso8601String().split('T')[0],
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

  @override
  Future<List<Todo>> searchTodos(String query) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}${AppConfig.todosEndpoint}/search?query=$query'),
        headers: _headers,
      ).timeout(AppConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Todo.fromJson(json)).toList();
      } else {
        throw Exception('Failed to search todos: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to search todos: $e');
    }
  }

  int _priorityToNumber(TodoPriority priority) {
    switch (priority) {
      case TodoPriority.high:
        return 1;
      case TodoPriority.medium:
        return 2;
      case TodoPriority.low:
        return 3;
    }
  }
} 