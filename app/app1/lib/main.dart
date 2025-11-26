// main.dart
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart'; // Убедитесь, что зависимость добавлена в pubspec.yaml и выполнен flutter pub get

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Мои Задачи',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark, // Устанавливаем темную тему по умолчанию
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.black, // Фон всего приложения
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        cardTheme: CardThemeData( // ИСПРАВЛЕНО: CardThemeData вместо CardTheme
          color: Colors.grey[900], // Цвет карточек на черном фоне
          margin: const EdgeInsets.symmetric(vertical: 4.0),
        ),
        textTheme: Theme.of(context).textTheme.apply(
          bodyColor: Colors.white, // Цвет текста по умолчанию
          displayColor: Colors.white,
        ),
        buttonTheme: const ButtonThemeData(
          buttonColor: Colors.blue,
          textTheme: ButtonTextTheme.primary,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[800], // Фон для полей ввода
          labelStyle: const TextStyle(color: Colors.white70),
          hintStyle: const TextStyle(color: Colors.white54),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: const BorderSide(color: Colors.blue, width: 2.0),
          ),
        ),
      ),
      home: const TasksPage(),
    );
  }
}

// task_model.dart (интегрирован в main.dart)
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
    // Метод для создания копии задачи с измененными полями (удобно для редактирования)
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

// tasks_page.dart (интегрирован в main.dart)
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

// add_task_page.dart (интегрирован в main.dart)
class AddTaskPage extends StatefulWidget {
  final Task? taskToEdit; // Опциональный параметр для редактирования

  const AddTaskPage({super.key, this.taskToEdit});

  @override
  State<AddTaskPage> createState() => _AddTaskPageState();
}

class _AddTaskPageState extends State<AddTaskPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _selectedDueDate;

  // Создаем один экземпляр Uuid для этого класса
  final Uuid _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    // Если есть задача для редактирования, заполняем поля
    if (widget.taskToEdit != null) {
      _titleController.text = widget.taskToEdit!.title;
      _descriptionController.text = widget.taskToEdit!.description;
      _selectedDueDate = widget.taskToEdit!.dueDate;
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
      initialDate: _selectedDueDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.blue, // Цвет кнопки "OK" и выделения
              onPrimary: Colors.white, // Цвет текста на кнопке "OK"
              surface: Colors.grey, // Фон календаря
              onSurface: Colors.white, // Цвет текста в календаре
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue, // Цвет кнопок "CANCEL", "OK"
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDueDate) {
      setState(() {
        _selectedDueDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.taskToEdit == null ? 'Новая Задача' : 'Редактировать Задачу',
          style: const TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                if (widget.taskToEdit == null) {
                  // Создание новой задачи
                  final newTask = Task(
                    id: _uuid.v4(), // ИСПРАВЛЕНО: удален const
                    title: _titleController.text,
                    description: _descriptionController.text,
                    dueDate: _selectedDueDate,
                    isCompleted: false,
                  );
                  Navigator.pop(context, newTask); // Возвращаем новую задачу
                } else {
                  // Редактирование существующей задачи
                  final updatedTask = widget.taskToEdit!.copyWith(
                    title: _titleController.text,
                    description: _descriptionController.text,
                    dueDate: _selectedDueDate,
                  );
                  Navigator.pop(context, updatedTask); // Возвращаем обновленную задачу
                }
              }
            },
            child: const Text(
              'Сохранить',
              style: TextStyle(color: Colors.blue, fontSize: 16),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0), // ИСПРАВЛЕНО
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Название задачи',
                  hintText: 'Введите название',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Пожалуйста, введите название задачи';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Описание',
                  hintText: 'Подробное описание задачи (необязательно)',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => _selectDate(context),
                child: AbsorbPointer(
                  child: TextFormField(
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Срок выполнения',
                      hintText: _selectedDueDate == null
                          ? 'Выберите дату'
                          : '${_selectedDueDate!.day}.${_selectedDueDate!.month}.${_selectedDueDate!.year}',
                      suffixIcon: const Icon(Icons.calendar_today, color: Colors.white70),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}