import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/todo.dart';
import '../../domain/repositories/todo_repository.dart';

class TodoRepositoryImpl implements TodoRepository {
  static const String _todosKey = 'todos';
  static const String _lastIdKey = 'last_todo_id';
  final SharedPreferences _prefs;

  TodoRepositoryImpl(this._prefs);

  Future<int> _getNextId() async {
    final lastId = _prefs.getInt(_lastIdKey) ?? 0;
    await _prefs.setInt(_lastIdKey, lastId + 1);
    return lastId + 1;
  }

  @override
  Future<List<Todo>> getTodos() async {
    final todosJson = _prefs.getStringList(_todosKey) ?? [];
    return todosJson.map((json) => Todo.fromJson(jsonDecode(json))).toList();
  }

  @override
  Future<Todo> getTodo(int id) async {
    final todos = await getTodos();
    return todos.firstWhere((todo) => todo.id == id);
  }

  @override
  Future<Todo> createTodo(Todo todo) async {
    final todos = await getTodos();
    final newId = await _getNextId();
    final newTodo = todo.copyWith(id: newId);
    todos.add(newTodo);
    await _saveTodos(todos);
    return newTodo;
  }

  @override
  Future<Todo> updateTodo(Todo todo) async {
    final todos = await getTodos();
    final index = todos.indexWhere((t) => t.id == todo.id);
    if (index != -1) {
      todos[index] = todo;
      await _saveTodos(todos);
      return todo;
    }
    throw Exception('Todo not found');
  }

  @override
  Future<void> deleteTodo(int id) async {
    final todos = await getTodos();
    todos.removeWhere((todo) => todo.id == id);
    await _saveTodos(todos);
  }

  @override
  Future<void> toggleTodo(int id) async {
    final todos = await getTodos();
    final index = todos.indexWhere((todo) => todo.id == id);
    if (index != -1) {
      final todo = todos[index];
      todos[index] = todo.copyWith(
        completed: !todo.completed,
      );
      await _saveTodos(todos);
    }
  }

  Future<void> _saveTodos(List<Todo> todos) async {
    final todosJson = todos.map((todo) => jsonEncode(todo.toJson())).toList();
    await _prefs.setStringList(_todosKey, todosJson);
  }
}

extension TodoJson on Todo {
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'completed': completed,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'priority': priority?.name,
      'area': area?.name,
      'deadline': deadline?.toIso8601String(),
    };
  }

  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      id: json['id'] is String ? int.parse(json['id']) : json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      completed: json['completed'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      priority: json['priority'] != null
          ? TodoPriority.values.firstWhere(
              (e) => e.name == json['priority'],
              orElse: () => TodoPriority.medium,
            )
          : null,
      area: json['area'] != null
          ? TodoArea.values.firstWhere(
              (e) => e.name == json['area'],
              orElse: () => TodoArea.personal,
            )
          : null,
      deadline: json['deadline'] != null
          ? DateTime.parse(json['deadline'] as String)
          : null,
    );
  }
} 