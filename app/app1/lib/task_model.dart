class Task {
  final String id;
  String title;
  String description;
  DateTime? dueDate;
  bool isCompleted;

  Task({
    required this.id,
    required this.title,
    this.description = '',
    this.dueDate,
    this.isCompleted = false,
  });

  // Для Sqflite: fromMap (с конверсией int в bool)
  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String? ?? '',
      dueDate: map['dueDate'] != null ? DateTime.parse(map['dueDate'] as String) : null,
      isCompleted: (map['isCompleted'] as int) == 1,  // Конверсия int в bool
    );
  }

  // Для Sqflite: toMap (с конверсией bool в int)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dueDate': dueDate?.toIso8601String(),
      'isCompleted': isCompleted ? 1 : 0,  // bool в int
    };
  }

  // Сериализация для API (теперь с конверсией int в bool, если API возвращает int)
  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      description: json['description'] ?? '',
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      isCompleted: json['isCompleted'] is int ? (json['isCompleted'] as int) == 1 : json['isCompleted'] ?? false,  // Конверсия int в bool, если нужно
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dueDate': dueDate?.toIso8601String(),
      'isCompleted': isCompleted,  // bool для API
    };
  }

  // Метод для копии (оставлен)
  Task copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dueDate,
    bool? isCompleted,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
