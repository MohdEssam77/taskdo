import 'package:equatable/equatable.dart';

enum TodoPriority { high, medium, low }

enum TodoArea { work, university, life, sports }

class Todo extends Equatable {
  final int id;
  final String title;
  final String description;
  final bool completed;
  final TodoPriority priority;
  final TodoArea area;
  final DateTime deadline;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Todo({
    required this.id,
    required this.title,
    required this.description,
    required this.completed,
    required this.priority,
    required this.area,
    required this.deadline,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Todo.create({
    required String title,
    required String description,
    required TodoPriority priority,
    required TodoArea area,
    required DateTime deadline,
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
      priority: TodoPriority.values.firstWhere(
        (e) => e.toString().split('.').last == (json['priority']?.toString().toLowerCase() ?? 'medium'),
        orElse: () => TodoPriority.medium,
      ),
      area: TodoArea.values.firstWhere(
        (e) => e.toString().split('.').last == (json['area']?.toString().toLowerCase() ?? 'life'),
        orElse: () => TodoArea.life,
      ),
      deadline: json['deadline'] != null ? DateTime.parse(json['deadline']) : DateTime.now(),
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'completed': completed,
      'priority': priority.toString().split('.').last.toLowerCase(),
      'area': area.toString().split('.').last.toLowerCase(),
      'deadline': deadline.toIso8601String(),
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