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
  DateTime? _selectedDeadline;

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

  Future<void> _selectDeadline(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDeadline ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDeadline) {
      setState(() {
        _selectedDeadline = picked;
      });
    }
  }

  void _clearDeadlineFilter() {
    setState(() {
      _selectedDeadline = null;
    });
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _selectDeadline(context),
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      _selectedDeadline != null
                          ? '${_selectedDeadline!.day}/${_selectedDeadline!.month}/${_selectedDeadline!.year}'
                          : 'Filter by Deadline',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                if (_selectedDeadline != null)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: _clearDeadlineFilter,
                    color: AppTheme.errorColor,
                  ),
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
                    // Filter by completion status
                    if (!_showCompleted && todo.completed) {
                      return false;
                    }
                    
                    // Filter by area
                    if (_selectedArea != null && todo.area != _selectedArea) {
                      return false;
                    }
                    
                    // Filter by deadline
                    if (_selectedDeadline != null) {
                      // If todo has no deadline, don't show it when filtering by date
                      if (todo.deadline == null) {
                        return false;
                      }
                      
                      final todoDate = DateTime(
                        todo.deadline!.year,
                        todo.deadline!.month,
                        todo.deadline!.day,
                      );
                      final selectedDate = DateTime(
                        _selectedDeadline!.year,
                        _selectedDeadline!.month,
                        _selectedDeadline!.day,
                      );
                      return todoDate.isAtSameMomentAs(selectedDate);
                    }
                    
                    return true;
                  }).toList()
                    ..sort((a, b) {
                      if (a.deadline == null && b.deadline == null) return 0;
                      if (a.deadline == null) return 1;
                      if (b.deadline == null) return -1;
                      return a.deadline!.compareTo(b.deadline!);
                    });

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
                          title: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                todo.title,
                                style: TextStyle(
                                  decoration: todo.completed
                                      ? TextDecoration.lineThrough
                                      : null,
                                  color: todo.completed
                                      ? AppTheme.secondaryTextColor
                                      : AppTheme.textColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (todo.description != null && todo.description!.isNotEmpty)
                                Text(
                                  todo.description!,
                                  style: TextStyle(
                                    color: AppTheme.secondaryTextColor,
                                    fontSize: 14,
                                    decoration: todo.completed
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 14,
                                    color: AppTheme.secondaryTextColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatDate(todo.deadline),
                                    style: const TextStyle(
                                      color: AppTheme.secondaryTextColor,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.category,
                                    size: 14,
                                    color: AppTheme.secondaryTextColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatArea(todo.area),
                                    style: const TextStyle(
                                      color: AppTheme.secondaryTextColor,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.priority_high,
                                    size: 14,
                                    color: _getPriorityColor(todo.priority),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatPriority(todo.priority),
                                    style: TextStyle(
                                      color: _getPriorityColor(todo.priority),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ],
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

  Color _getPriorityColor(TodoPriority? priority) {
    if (priority == null) return Colors.grey;
    switch (priority) {
      case TodoPriority.high:
        return Colors.red;
      case TodoPriority.medium:
        return Colors.orange;
      case TodoPriority.low:
        return Colors.green;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'No deadline';
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatArea(TodoArea? area) {
    if (area == null) return 'No category';
    return area.name.toUpperCase();
  }

  String _formatPriority(TodoPriority? priority) {
    if (priority == null) return 'No priority';
    return priority.name.toUpperCase();
  }
} 