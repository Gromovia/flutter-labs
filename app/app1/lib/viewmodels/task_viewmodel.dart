import 'package:flutter/foundation.dart';
import '../task_model.dart';  // Предполагаю, что task_model.dart в lib/models/ — если нет, скорректируйте путь
import '../repositories/task_repository.dart';

class TaskViewModel extends ChangeNotifier {
  final TaskRepository _repository = TaskRepository();

  List<Task> _tasks = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Task> get tasks => _tasks;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Загрузка задач (из API или БД)
  Future<void> loadTasks() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _tasks = await _repository.getTasks();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Добавление задачи
  Future<void> addTask(Task task) async {
    try {
      await _repository.addTask(task);
      await loadTasks();  // Перезагрузка списка
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Обновление задачи
  Future<void> updateTask(Task task) async {
    try {
      await _repository.updateTask(task);
      await loadTasks();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Удаление задачи
  Future<void> deleteTask(String taskId) async {
    try {
      await _repository.deleteTask(taskId);
      await loadTasks();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Переключение статуса завершения
  Future<void> toggleTaskCompletion(String taskId) async {
    try {
      await _repository.toggleTaskCompletion(taskId);
      await loadTasks();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }
}
