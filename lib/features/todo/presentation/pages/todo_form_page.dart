import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../domain/entities/todo.dart';
import '../bloc/todo_bloc.dart';
import '../bloc/todo_event.dart';

class TodoFormPage extends StatefulWidget {
  final Todo? todo;

  const TodoFormPage({Key? key, this.todo}) : super(key: key);

  @override
  State<TodoFormPage> createState() => _TodoFormPageState();
}

class _TodoFormPageState extends State<TodoFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _selectedDate;
  TodoPriority? _selectedPriority;
  TodoArea? _selectedArea;

  @override
  void initState() {
    super.initState();
    if (widget.todo != null) {
      _titleController.text = widget.todo!.title;
      _descriptionController.text = widget.todo!.description;
      _selectedDate = widget.todo!.deadline;
      _selectedPriority = widget.todo!.priority;
      _selectedArea = widget.todo!.area;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppTheme.primaryColor,
              onPrimary: AppTheme.backgroundColor,
              surface: AppTheme.surfaceColor,
              onSurface: AppTheme.textColor,
            ),
            dialogBackgroundColor: AppTheme.surfaceColor,
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _clearDate() {
    setState(() {
      _selectedDate = null;
    });
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      final todo = Todo.create(
        title: _titleController.text,
        description: _descriptionController.text,
        priority: _selectedPriority,
        area: _selectedArea,
        deadline: _selectedDate,
      );
      context.read<TodoBloc>().add(AddTodo(todo));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.9,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Material(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      widget.todo != null ? 'Edit Task' : 'New Task',
                      style: const TextStyle(
                        color: AppTheme.textColor,
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 24),
                    CustomTextField(
                      controller: _titleController,
                      label: 'Title',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _descriptionController,
                      label: 'Description',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Due Date',
                                style: TextStyle(
                                  color: AppTheme.textColor,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextButton(
                                      onPressed: () => _selectDate(context),
                                      style: TextButton.styleFrom(
                                        backgroundColor: AppTheme.backgroundColor,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.calendar_today,
                                            color: AppTheme.primaryColor,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            _selectedDate != null
                                                ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                                                : 'Select Date',
                                            style: const TextStyle(
                                              color: AppTheme.textColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  if (_selectedDate != null)
                                    IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: _clearDate,
                                      color: AppTheme.errorColor,
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Priority',
                                style: TextStyle(
                                  color: AppTheme.textColor,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                decoration: BoxDecoration(
                                  color: AppTheme.backgroundColor,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: DropdownButtonFormField<TodoPriority?>(
                                  value: _selectedPriority,
                                  dropdownColor: AppTheme.backgroundColor,
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                  ),
                                  items: [
                                    const DropdownMenuItem(
                                      value: null,
                                      child: Text(
                                        'None',
                                        style: TextStyle(
                                          color: AppTheme.textColor,
                                        ),
                                      ),
                                    ),
                                    ...TodoPriority.values.map((priority) {
                                      return DropdownMenuItem(
                                        value: priority,
                                        child: Text(
                                          priority.name.toUpperCase(),
                                          style: const TextStyle(
                                            color: AppTheme.textColor,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedPriority = value;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Category',
                          style: TextStyle(
                            color: AppTheme.textColor,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: AppTheme.backgroundColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButtonFormField<TodoArea?>(
                            value: _selectedArea,
                            dropdownColor: AppTheme.backgroundColor,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            items: [
                              const DropdownMenuItem(
                                value: null,
                                child: Text(
                                  'None',
                                  style: TextStyle(
                                    color: AppTheme.textColor,
                                  ),
                                ),
                              ),
                              ...TodoArea.values.map((area) {
                                return DropdownMenuItem(
                                  value: area,
                                  child: Text(
                                    area.name.toUpperCase(),
                                    style: const TextStyle(
                                      color: AppTheme.textColor,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedArea = value;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              color: AppTheme.textColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        CustomButton(
                          text: widget.todo != null ? 'Save' : 'Add',
                          onPressed: _handleSubmit,
                          fullWidth: false,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
} 