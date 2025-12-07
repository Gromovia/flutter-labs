import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'task_model.dart'; // убедитесь, что путь правильный

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

  bool _isCompleted = false; // для редактирования статуса задачи

  @override
  void initState() {
    super.initState();
    if (widget.taskToEdit != null) {
      _titleController.text = widget.taskToEdit!.title;
      _descriptionController.text = widget.taskToEdit!.description;
      _selectedDueDate = widget.taskToEdit!.dueDate;
      _isCompleted = widget.taskToEdit!.isCompleted;
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
    final isEditing = widget.taskToEdit != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Редактировать задачу' : 'Новая задача'),
        centerTitle: true,
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
                decoration: const InputDecoration(
                  labelText: 'Название задачи',
                  hintText: 'Например, Купить продукты',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Пожалуйста, введите название задачи';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Описание (необязательно)',
                  hintText: 'Дополнительная информация о задаче',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16.0),
              // Дата выполнения
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  _selectedDueDate == null
                      ? 'Дата выполнения (необязательно)'
                      : 'Срок: ${_selectedDueDate!.day}.${_selectedDueDate!.month}.${_selectedDueDate!.year}',
                  style: TextStyle(
                    color: _selectedDueDate == null ? Colors.white70 : Colors.white,
                    fontSize: 16,
                  ),
                ),
                trailing: const Icon(Icons.calendar_today, color: Colors.blue),
                onTap: () => _selectDate(context),
              ),
              const SizedBox(height: 16),
              // Поле для статуса завершенности
              SwitchListTile(
                title: const Text('Задача выполнена'),
                value: _isCompleted,
                onChanged: (value) {
                  setState(() {
                    _isCompleted = value;
                  });
                },
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      final String id = widget.taskToEdit?.id ?? _uuid.v4();
                      final Task resultTask = Task(
                        id: id,
                        title: _titleController.text.trim(),
                        description: _descriptionController.text.trim(),
                        dueDate: _selectedDueDate,
                        isCompleted: _isCompleted,
                      );
                      Navigator.pop(context, resultTask); // Возвращаем задачу
                    }
                  },
                  child: Text(isEditing ? 'Сохранить изменения' : 'Добавить задачу'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}