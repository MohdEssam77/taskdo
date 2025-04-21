import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/todo.dart';
import '../../domain/repositories/todo_repository.dart';

class TodoRepositoryImpl implements TodoRepository {
  static const String _todosKey = 'todos';
  final SharedPreferences _prefs;

  TodoRepositoryImpl(this._prefs);

  @override
  Future<List<Todo>> getTodos() async {
    final todosJson = _prefs.getStringList(_todosKey) ?? [];
    return todosJson.map((json) => Todo.fromJson(jsonDecode(json))).toList();
  }

  @override
  Future<Todo> getTodo(String id) async {
    final todos = await getTodos();
    return todos.firstWhere((todo) => todo.id == id);
  }

  @override
  Future<void> addTodo(Todo todo) async {
    final todos = await getTodos();
    todos.add(todo);
    await _saveTodos(todos);
  }

  @override
  Future<void> updateTodo(Todo todo) async {
    final todos = await getTodos();
    final index = todos.indexWhere((t) => t.id == todo.id);
    if (index != -1) {
      todos[index] = todo;
      await _saveTodos(todos);
    }
  }

  @override
  Future<void> deleteTodo(String id) async {
    final todos = await getTodos();
    todos.removeWhere((todo) => todo.id == id);
    await _saveTodos(todos);
  }

  @override
  Future<void> toggleTodo(String id) async {
    final todos = await getTodos();
    final index = todos.indexWhere((todo) => todo.id == id);
    if (index != -1) {
      final todo = todos[index];
      todos[index] = todo.copyWith(
        isCompleted: !todo.isCompleted,
        completedAt: !todo.isCompleted ? DateTime.now() : null,
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
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      isCompleted: json['isCompleted'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
    );
  }
} 