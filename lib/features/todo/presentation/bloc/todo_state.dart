import 'package:equatable/equatable.dart';
import '../../domain/entities/todo.dart';

abstract class TodoState extends Equatable {
  const TodoState();

  @override
  List<Object?> get props => [];
}

class TodoInitial extends TodoState {
  const TodoInitial();
}

class TodoLoading extends TodoState {
  const TodoLoading();
}

class TodoLoaded extends TodoState {
  final List<Todo> todos;
  final bool showCompleted;
  final TodoArea? filterArea;

  const TodoLoaded({
    required this.todos,
    this.showCompleted = true,
    this.filterArea,
  });

  @override
  List<Object?> get props => [todos, showCompleted, filterArea];
}

class TodoError extends TodoState {
  final String message;

  const TodoError(this.message);

  @override
  List<Object?> get props => [message];
} 