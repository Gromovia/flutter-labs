import '../task_model.dart';
import '../services/api_service.dart';
import '../services/database_service.dart';

class TaskRepository {
  final ApiService _apiService = ApiService();
  final DatabaseService _dbService = DatabaseService();

  // Получение задач: сначала пытаемся из API, fallback на БД
  Future<List<Task>> getTasks() async {
    try {
      List<Task> tasks = await _apiService.fetchTasks();
      await _dbService.saveTasks(tasks);  // Синхронизация с БД
      return tasks;
    } catch (e) {
      // Оффлайн: загружаем из БД
      return await _dbService.getTasks();
    }
  }

  // Добавление задачи
  Future<void> addTask(Task task) async {
    try {
      await _apiService.createTask(task);
    } catch (e) {
      // Оффлайн: сохраняем локально
    }
    await _dbService.insertTask(task);
  }

  // Обновление задачи
  Future<void> updateTask(Task task) async {
    try {
      await _apiService.updateTask(task);
    } catch (e) {
      // Оффлайн: обновляем локально
    }
    await _dbService.updateTask(task);
  }

  // Удаление задачи
  Future<void> deleteTask(String taskId) async {
    try {
      await _apiService.deleteTask(taskId);
    } catch (e) {
      // Оффлайн: удаляем локально
    }
    await _dbService.deleteTask(taskId);
  }

  // Переключение завершения
  Future<void> toggleTaskCompletion(String taskId) async {
    Task? task = await _dbService.getTaskById(taskId);
    if (task != null) {
      Task updatedTask = task.copyWith(isCompleted: !task.isCompleted);
      await updateTask(updatedTask);
    }
  }
}
