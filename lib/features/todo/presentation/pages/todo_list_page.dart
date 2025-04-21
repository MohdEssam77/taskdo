import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../domain/entities/todo.dart';
import '../bloc/todo_bloc.dart';
import '../bloc/todo_event.dart';
import '../bloc/todo_state.dart';
import 'todo_form_page.dart';
import 'package:taskdo/features/auth/presentation/pages/profile_page.dart';

class TodoListPage extends StatefulWidget {
  const TodoListPage({Key? key}) : super(key: key);

  @override
  State<TodoListPage> createState() => _TodoListPageState();
}

class _TodoListPageState extends State<TodoListPage> {
  bool _showCompleted = true;
  TodoArea? _selectedArea;

  @override
  void initState() {
    super.initState();
    context.read<TodoBloc>().add(const LoadTodos());
  }

  void _toggleTodo(int id) {
    context.read<TodoBloc>().add(ToggleTodo(id));
  }

  void _deleteTodo(int id) {
    context.read<TodoBloc>().add(DeleteTodo(id));
  }

  void _editTodo(Todo todo) {
    showDialog(
      context: context,
      builder: (context) => TodoFormPage(todo: todo),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TaskDo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfilePage(),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(
              _showCompleted ? Icons.visibility : Icons.visibility_off,
              color: AppTheme.textColor,
            ),
            onPressed: () {
              setState(() {
                _showCompleted = !_showCompleted;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildCategoryTab(null, 'All'),
                ...TodoArea.values.map((area) => _buildCategoryTab(area, area.name.toUpperCase())).toList(),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: BlocBuilder<TodoBloc, TodoState>(
              builder: (context, state) {
                if (state is TodoLoading) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryColor,
                    ),
                  );
                }

                if (state is TodoError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: AppTheme.errorColor,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          state.message,
                          style: const TextStyle(
                            color: AppTheme.textColor,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 16),
                        CustomButton(
                          text: 'Retry',
                          onPressed: () {
                            context.read<TodoBloc>().add(const LoadTodos());
                          },
                        ),
                      ],
                    ),
                  );
                }

                if (state is TodoLoaded) {
                  final todos = state.todos.where((todo) {
                    if (!_showCompleted && todo.completed) {
                      return false;
                    }
                    if (_selectedArea != null && todo.area != _selectedArea) {
                      return false;
                    }
                    return true;
                  }).toList()
                    ..sort((a, b) => a.deadline.compareTo(b.deadline));

                  if (todos.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.task_alt,
                            color: AppTheme.secondaryTextColor,
                            size: 64,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No tasks',
                            style: TextStyle(
                              color: AppTheme.secondaryTextColor,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _selectedArea != null
                                ? 'Try changing the category'
                                : 'Add a new task to get started',
                            style: const TextStyle(
                              color: AppTheme.secondaryTextColor,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: todos.length,
                    itemBuilder: (context, index) {
                      final todo = todos[index];
                      return Dismissible(
                        key: Key(todo.id.toString()),
                        background: Container(
                          color: Colors.green,
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.only(left: 16.0),
                          child: const Icon(Icons.check, color: Colors.white),
                        ),
                        secondaryBackground: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 16.0),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        direction: DismissDirection.horizontal,
                        onDismissed: (direction) {
                          if (direction == DismissDirection.startToEnd) {
                            // Swipe from left to right to mark as complete
                            _toggleTodo(todo.id);
                          } else {
                            // Swipe from right to left to delete
                            _deleteTodo(todo.id);
                          }
                        },
                        child: ListTile(
                          leading: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: todo.completed ? Colors.green : Colors.grey,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            todo.title,
                            style: TextStyle(
                              decoration: todo.completed
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: todo.completed
                                  ? AppTheme.secondaryTextColor
                                  : AppTheme.textColor,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Text(
                            '${todo.deadline.day}/${todo.deadline.month}/${todo.deadline.year}',
                            style: const TextStyle(
                              color: AppTheme.secondaryTextColor,
                              fontSize: 14,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit),
                            color: AppTheme.primaryColor,
                            onPressed: () {
                              _editTodo(todo);
                            },
                          ),
                        ),
                      );
                    },
                  );
                }

                return const Center(child: Text('Unknown state'));
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primaryColor,
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const TodoFormPage(),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCategoryTab(TodoArea? area, String label) {
    final isSelected = _selectedArea == area;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedArea = isSelected ? null : area;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? AppTheme.primaryColor : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppTheme.primaryColor : AppTheme.textColor,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
} 