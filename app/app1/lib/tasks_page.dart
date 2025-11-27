import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart'; // Убедитесь, что зависимость добавлена в pubspec.yaml и выполнен flutter pub get
import 'task_model.dart'; // Импорт модели Task
import 'add_task_page.dart'; // Импорт страницы добавления/редактирования

class TasksPage extends StatefulWidget {
  const TasksPage({super.key});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  // Создаем один экземпляр Uuid для этого класса
  final Uuid _uuid = const Uuid();

  late List<Task> _tasks; // Объявляем late, инициализируем в initState

  @override
  void initState() {
    super.initState();
    // Инициализация тестовыми задачами с использованием _uuid
    _tasks = [
      Task(id: _uuid.v4(), title: 'Купить продукты', description: 'Молоко, хлеб, яйца', dueDate: DateTime.now().add(const Duration(days: 1))),
      Task(id: _uuid.v4(), title: 'Сделать домашнее задание', description: 'По Flutter и Lisp', dueDate: DateTime.now().add(const Duration(hours: 3))),
      Task(id: _uuid.v4(), title: 'Позвонить маме', description: '', dueDate: DateTime.now().add(const Duration(days: 5)), isCompleted: true),
      Task(id: _uuid.v4(), title: 'Прочитать книгу', description: 'Глава 3', isCompleted: true),
    ];
  }

  @override
  Widget build(BuildContext context) {
    List<Task> activeTasks = _tasks.where((task) => !task.isCompleted).toList();
    List<Task> completedTasks = _tasks.where((task) => task.isCompleted).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Мои Задачи',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row( // Изменено на Row
          crossAxisAlignment: CrossAxisAlignment.start, // Выравниваем списки по верху
          children: [
            Expanded(
              child: _buildTaskList(
                context,
                'Активные задачи',
                activeTasks,
                Colors.blue,
                showEdit: true,
                showCheckbox: true,
              ),
            ),
            const SizedBox(width: 20), // Горизонтальный отступ между списками
            Expanded(
              child: _buildTaskList(
                context,
                'Завершенные задачи',
                completedTasks,
                Colors.green,
                showEdit: false,
                showCheckbox: false,
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final newTask = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddTaskPage()),
          );
          if (newTask != null && newTask is Task) {
            setState(() {
              _tasks.add(newTask);
            });
          }
        },
        label: const Text('Добавить новую задачу'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildTaskList(
    BuildContext context,
    String title,
    List<Task> tasks,
    Color titleColor, {
    required bool showEdit,
    required bool showCheckbox,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: titleColor,
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: tasks.isEmpty
              ? Center(
                  child: Text(
                    'Здесь пока пусто.',
                    style: TextStyle(color: Colors.white70),
                  ),
                )
              : ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return Card(
                      elevation: 2.0,
                      margin: const EdgeInsets.symmetric(vertical: 6.0),
                      child: ListTile(
                        leading: showCheckbox
                            ? Checkbox(
                                value: task.isCompleted,
                                onChanged: (bool? value) {
                                  setState(() {
                                    task.isCompleted = value ?? false;
                                  });
                                },
                                activeColor: Colors.blue,
                                checkColor: Colors.white,
                              )
                            : null,
                        title: Text(
                          task.title,
                          style: TextStyle(
                            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                            color: Colors.white,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (task.description.isNotEmpty)
                              Text(
                                task.description,
                                style: const TextStyle(color: Colors.white70),
                              ),
                            if (task.dueDate != null)
                              Text(
                                'Срок: ${task.dueDate!.day}.${task.dueDate!.month}.${task.dueDate!.year}',
                                style: const TextStyle(fontSize: 12, color: Colors.white54),
                              ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (showEdit)
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.amber),
                                onPressed: () async {
                                  final updatedTask = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AddTaskPage(taskToEdit: task),
                                    ),
                                  );
                                  if (updatedTask != null && updatedTask is Task) {
                                    setState(() {
                                      final taskIndex = _tasks.indexWhere((t) => t.id == updatedTask.id);
                                      if (taskIndex != -1) {
                                        _tasks[taskIndex] = updatedTask;
                                      }
                                    });
                                  }
                                },
                              ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  _tasks.removeWhere((t) => t.id == task.id);
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
