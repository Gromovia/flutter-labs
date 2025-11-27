// Без изменений — логика создания/редактирования теперь в ViewModel
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'task_model.dart';

class AddTaskPage extends StatefulWidget {
  final Task? taskToEdit;

  const AddTaskPage({super.key, this.taskToEdit});

  @override
  State<AddTaskPage> createState() => _AddTaskPageState();
}

class _AddTaskPageState extends State<AddTaskPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _selectedDueDate;
  final Uuid _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
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
              primary: Colors.blue,
              onPrimary: Colors.white,
              surface: Colors.grey,
              onSurface: Colors.white,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue,
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
                  final newTask = Task(
                    id: _uuid.v4(),
                    title: _titleController.text,
                    description: _descriptionController.text,
                    dueDate: _selectedDueDate,
                    isCompleted: false,
                  );
                  Navigator.pop(context, newTask);
                } else {
                  final updatedTask = widget.taskToEdit!.copyWith(
                    title: _titleController.text,
                    description: _descriptionController.text,
                    dueDate: _selectedDueDate,
                  );
                  Navigator.pop(context, updatedTask);
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
        padding: const EdgeInsets.all(16.0),
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
