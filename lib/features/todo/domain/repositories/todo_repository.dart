import '../entities/todo.dart';

abstract class TodoRepository {
  Future<List<Todo>> getTodos();
  Future<Todo> createTodo(
    String title,
    String description,
    TodoPriority priority,
    TodoArea area,
    DateTime deadline,
  );
  Future<Todo> updateTodo(Todo todo);
  Future<void> deleteTodo(int id);
  Future<void> toggleTodo(int id);
} 