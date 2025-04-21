import 'package:uuid/uuid.dart';
import '../../domain/entities/todo.dart';
import '../../domain/repositories/todo_repository.dart';

class MockTodoRepository implements TodoRepository {
  final List<Todo> _todos = [];

  @override
  Future<List<Todo>> getTodos() async {
    return _todos;
  }

  @override
  Future<Todo> createTodo(
    String title,
    String description,
    TodoPriority priority,
    TodoArea area,
    DateTime deadline,
  ) async {
    final todo = Todo.create(
      title: title,
      description: description,
      priority: priority,
      area: area,
      deadline: deadline,
    );
    _todos.add(todo);
    return todo;
  }

  @override
  Future<Todo> updateTodo(Todo todo) async {
    final index = _todos.indexWhere((t) => t.id == todo.id);
    if (index != -1) {
      _todos[index] = todo;
      return todo;
    }
    throw Exception('Todo not found');
  }

  @override
  Future<void> deleteTodo(String id) async {
    _todos.removeWhere((todo) => todo.id == id);
  }

  @override
  Future<void> toggleTodo(String id) async {
    final index = _todos.indexWhere((t) => t.id == id);
    if (index != -1) {
      _todos[index] = _todos[index].copyWith(
        completed: !_todos[index].completed,
      );
    } else {
      throw Exception('Todo not found');
    }
  }
} 