import '../entities/todo.dart';

abstract class TodoRepository {
  Future<List<Todo>> getTodos();
  Future<Todo> createTodo(Todo todo);
  Future<Todo> updateTodo(Todo todo);
  Future<void> deleteTodo(int id);
  Future<void> toggleTodo(int id);
  Future<List<Todo>> searchTodos(String query);
} 