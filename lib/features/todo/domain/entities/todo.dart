import 'package:equatable/equatable.dart';

enum TodoPriority { high, medium, low }

enum TodoArea { sports, university, life, work }

class Todo extends Equatable {
  final int id;
  final String title;
  final String description;
  final bool completed;
  final TodoPriority? priority;
  final TodoArea? area;
  final DateTime? deadline;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Todo({
    required this.id,
    required this.title,
    required this.description,
    required this.completed,
    this.priority,
    this.area,
    this.deadline,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Todo.create({
    required String title,
    String description = '',
    TodoPriority? priority,
    TodoArea? area,
    DateTime? deadline,
  }) {
    return Todo(
      id: 0, // This will be set by the backend
      title: title,
      description: description,
      completed: false,
      priority: priority,
      area: area,
      deadline: deadline,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      completed: json['completed'] ?? false,
      priority: json['priority'] != null
          ? _numberToPriority(json['priority'])
          : null,
      area: json['area'] != null
          ? TodoArea.values.firstWhere(
              (e) => e.name.toLowerCase() == json['area'].toString().toLowerCase(),
              orElse: () => TodoArea.life,
            )
          : null,
      deadline: json['deadline'] != null ? DateTime.parse(json['deadline']) : null,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : DateTime.now(),
    );
  }

  static TodoPriority _numberToPriority(dynamic value) {
    final intValue = value is String ? int.parse(value) : value as int;
    switch (intValue) {
      case 1:
        return TodoPriority.high;
      case 2:
        return TodoPriority.medium;
      case 3:
        return TodoPriority.low;
      default:
        return TodoPriority.medium;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'completed': completed,
      if (priority != null) 'priority': priority!.name.toLowerCase(),
      if (area != null) 'area': area!.name.toLowerCase(),
      if (deadline != null) 'deadline': deadline!.toIso8601String().split('T')[0],
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Todo copyWith({
    int? id,
    String? title,
    String? description,
    bool? completed,
    TodoPriority? priority,
    TodoArea? area,
    DateTime? deadline,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Todo(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      completed: completed ?? this.completed,
      priority: priority ?? this.priority,
      area: area ?? this.area,
      deadline: deadline ?? this.deadline,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        completed,
        priority,
        area,
        deadline,
        createdAt,
        updatedAt,
      ];
} 