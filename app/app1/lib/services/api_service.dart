import 'package:dio/dio.dart';
import '../task_model.dart';

class ApiService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://your-api-url.com',  // Замените на ваш реальный API URL
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 5),
  ));

  Future<List<Task>> fetchTasks() async {
    final response = await _dio.get('/tasks');
    return (response.data as List).map((json) => Task.fromJson(json)).toList();
  }

  Future<Task> createTask(Task task) async {
    final response = await _dio.post('/tasks', data: task.toJson());
    return Task.fromJson(response.data);
  }

  Future<Task> updateTask(Task task) async {
    final response = await _dio.put('/tasks/${task.id}', data: task.toJson());
    return Task.fromJson(response.data);
  }

  Future<void> deleteTask(String taskId) async {
    await _dio.delete('/tasks/$taskId');
  }
}
