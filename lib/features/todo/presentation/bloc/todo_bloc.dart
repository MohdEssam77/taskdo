import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/todo_repository.dart';
import '../../domain/entities/todo.dart';
import 'todo_event.dart';
import 'todo_state.dart';

class TodoBloc extends Bloc<TodoEvent, TodoState> {
  final TodoRepository _repository;
  List<Todo> _todos = [];

  TodoBloc(this._repository) : super(const TodoInitial()) {
    on<LoadTodos>(_onLoadTodos);
    on<AddTodo>(_onAddTodo);
    on<UpdateTodo>(_onUpdateTodo);
    on<DeleteTodo>(_onDeleteTodo);
    on<ToggleTodo>(_onToggleTodo);
    on<SearchTodos>(_onSearchTodos);
  }

  Future<void> _onLoadTodos(LoadTodos event, Emitter<TodoState> emit) async {
    try {
      emit(const TodoLoading());
      _todos = await _repository.getTodos();
      emit(TodoLoaded(todos: _todos));
    } catch (e) {
      emit(TodoError(e.toString()));
    }
  }

  Future<void> _onAddTodo(AddTodo event, Emitter<TodoState> emit) async {
    try {
      final todo = await _repository.createTodo(event.todo);
      _todos = [..._todos, todo];
      emit(TodoLoaded(todos: _todos));
    } catch (e) {
      emit(TodoError(e.toString()));
    }
  }

  Future<void> _onUpdateTodo(UpdateTodo event, Emitter<TodoState> emit) async {
    try {
      final updatedTodo = await _repository.updateTodo(event.todo);
      final index = _todos.indexWhere((t) => t.id == updatedTodo.id);
      if (index != -1) {
        _todos = List<Todo>.from(_todos);
        _todos[index] = updatedTodo;
        emit(TodoLoaded(todos: _todos));
      }
    } catch (e) {
      emit(TodoError(e.toString()));
    }
  }

  Future<void> _onDeleteTodo(DeleteTodo event, Emitter<TodoState> emit) async {
    try {
      emit(const TodoLoading());
      await _repository.deleteTodo(event.id);
      _todos = await _repository.getTodos();
      emit(TodoLoaded(todos: _todos));
    } catch (e) {
      emit(TodoError('Failed to delete todo: $e'));
    }
  }

  Future<void> _onToggleTodo(ToggleTodo event, Emitter<TodoState> emit) async {
    try {
      emit(const TodoLoading());
      await _repository.toggleTodo(event.id);
      _todos = await _repository.getTodos();
      emit(TodoLoaded(todos: _todos));
    } catch (e) {
      emit(TodoError(e.toString()));
    }
  }

  Future<void> _onSearchTodos(SearchTodos event, Emitter<TodoState> emit) async {
    try {
      emit(const TodoLoading());
      _todos = await _repository.searchTodos(event.query);
      emit(TodoLoaded(todos: _todos));
    } catch (e) {
      emit(TodoError(e.toString()));
    }
  }
} 