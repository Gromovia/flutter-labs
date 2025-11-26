import 'package:flutter/material.dart';

void main() {
  runApp(const MainApp());
}

class Task {
  final String title;
  final String description;
  final String dueDate;
  final bool done;

  Task({
    required this.title,
    this.description = '',
    this.dueDate = '',
    this.done = false,
  });

  Task copyWith({String? title, String? description, String? dueDate, bool? done}) {
    return Task(
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      done: done ?? this.done,
    );
  }
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ToDo UI',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const TasksPage(),
    );
  }
}

class TasksPage extends StatefulWidget {
  const TasksPage({super.key});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  final List<Task> _active = [
    Task(title: 'Купить молоко', description: '2 литра', dueDate: '2025-11-27'),
    Task(title: 'Позвонить Ане', description: 'обсудить проект', dueDate: '2025-11-26'),
  ];
  final List<Task> _done = [
    Task(title: 'Сделать отчёт', done: true, dueDate: '2025-11-20'),
  ];

  // Навигация на экран добавления задачи и получение результата
  Future<void> _openAddTask() async {
    final Task? newTask = await Navigator.of(context).push<Task>(
      MaterialPageRoute(builder: (_) => const AddTaskPage()),
    );
    if (newTask != null) {
      setState(() {
        _active.add(newTask);
      });
    }
  }

  Widget _buildList(String title, Color headerColor, List<Task> items) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: headerColor.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              color: headerColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Text(
              title,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
          ),
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Text(
                      'Нет задач',
                      style: TextStyle(color: headerColor.withOpacity(0.7)),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(8),
                    itemBuilder: (context, index) {
                      final t = items[index];
                      return Card(
                        elevation: 0,
                        color: headerColor.withOpacity(0.06),
                        child: ListTile(
                          title: Text(t.title),
                          subtitle: t.dueDate.isNotEmpty ? Text('Срок: ${t.dueDate}') : null,
                        ),
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemCount: items.length,
                  ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Экран "Мои задачи"
    return Scaffold(
      appBar: AppBar(
        title: const Text('мои задачи'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Отступ под заголовком (если нужен) — уже есть AppBar
          Expanded(
            child: Row(
              children: [
                // Левая колонка — Активные задачи
                Expanded(
                  child: _buildList('Активные задачи', Colors.blue, _active),
                ),
                // Правая колонка — Завершенные
                Expanded(
                  child: _buildList('Завершенные', Colors.green, _done),
                ),
              ],
            ),
          ),
        ],
      ),
      // Кнопка "Добавить новую задачу" слева внизу
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddTask,
        label: const Text('Добавить новую задачу'),
        icon: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }
}

class AddTaskPage extends StatefulWidget {
  const AddTaskPage({super.key});

  @override
  State<AddTaskPage> createState() => _AddTaskPageState();
}

class _AddTaskPageState extends State<AddTaskPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _dueController = TextEditingController();

  void _saveAndReturn() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      // Для чистоты UI-версии можно просто закрывать без добавления. Здесь вы можете показать snackbar.
      Navigator.of(context).pop();
      return;
    }
    final newTask = Task(
      title: title,
      description: _descController.text.trim(),
      dueDate: _dueController.text.trim(),
      done: false,
    );
    Navigator.of(context).pop(newTask);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _dueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Экран добавления новой задачи
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(), // возвращаем
        ),
        title: TextField(
          controller: _titleController,
          decoration: const InputDecoration(
            hintText: 'Название задачи',
            border: InputBorder.none,
            isCollapsed: true,
          ),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
          ),
        actions: [
          TextButton(
            onPressed: _saveAndReturn,
            child: const Text(
              'Сохранить',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Описание
            TextField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: 'Описание',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 12),
            // Срок выполнения — для простоты обычный текстовый ввод
            TextField(
              controller: _dueController,
              decoration: const InputDecoration(
                labelText: 'Срок выполнения (например 2025-11-30)',
                border: OutlineInputBorder(),
              ),
            ),
            // Дополнительные элементы можно расположить ниже
            const SizedBox(height: 12),
            // Пустое пространство — чтобы визуально отделить
            const Expanded(child: SizedBox()),
            // (Опционально) Кнопка сохранить внизу (дублирует AppBar)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveAndReturn,
                child: const Text('Сохранить задачу'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}