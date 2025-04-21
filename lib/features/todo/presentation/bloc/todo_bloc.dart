import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/todo_repository.dart';
import 'todo_event.dart';
import 'todo_state.dart';

class TodoBloc extends Bloc<TodoEvent, TodoState> {
  final TodoRepository _repository;

  TodoBloc(this._repository) : super(const TodoInitial()) {
    on<LoadTodos>(_onLoadTodos);
    on<AddTodo>(_onAddTodo);
    on<UpdateTodo>(_onUpdateTodo);
    on<DeleteTodo>(_onDeleteTodo);
    on<ToggleTodo>(_onToggleTodo);
  }

  Future<void> _onLoadTodos(LoadTodos event, Emitter<TodoState> emit) async {
    try {
      emit(const TodoLoading());
      final todos = await _repository.getTodos();
      emit(TodoLoaded(todos: todos));
    } catch (e) {
      emit(TodoError(e.toString()));
    }
  }

  Future<void> _onAddTodo(AddTodo event, Emitter<TodoState> emit) async {
    try {
      emit(const TodoLoading());
      final todo = await _repository.createTodo(
        event.todo.title,
        event.todo.description,
        event.todo.priority,
        event.todo.area,
        event.todo.deadline,
      );
      // After adding a todo, reload the entire list
      final todos = await _repository.getTodos();
      emit(TodoLoaded(todos: todos));
    } catch (e) {
      emit(TodoError(e.toString()));
    }
  }

  Future<void> _onUpdateTodo(UpdateTodo event, Emitter<TodoState> emit) async {
    try {
      emit(const TodoLoading());
      await _repository.updateTodo(event.todo);
      // After updating a todo, reload the entire list
      final todos = await _repository.getTodos();
      emit(TodoLoaded(todos: todos));
    } catch (e) {
      emit(TodoError(e.toString()));
    }
  }

  Future<void> _onDeleteTodo(DeleteTodo event, Emitter<TodoState> emit) async {
    try {
      emit(const TodoLoading());
      await _repository.deleteTodo(event.id);
      // After deleting a todo, reload the entire list
      final todos = await _repository.getTodos();
      emit(TodoLoaded(todos: todos));
    } catch (e) {
      emit(TodoError('Failed to delete todo: $e'));
    }
  }

  Future<void> _onToggleTodo(ToggleTodo event, Emitter<TodoState> emit) async {
    try {
      emit(const TodoLoading());
      await _repository.toggleTodo(event.id);
      // After toggling a todo, reload the entire list
      final todos = await _repository.getTodos();
      emit(TodoLoaded(todos: todos));
    } catch (e) {
      emit(TodoError(e.toString()));
    }
  }
} 