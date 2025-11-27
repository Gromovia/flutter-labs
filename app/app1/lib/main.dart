import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// --- 1. Главное приложение ---
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
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: Colors.grey[900],
          margin: const EdgeInsets.symmetric(vertical: 4.0),
        ),
        textTheme: Theme.of(context).textTheme.apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[800],
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
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            backgroundColor: Colors.blue, // Дефолтный цвет для Elevated Button
            foregroundColor: Colors.white, // Дефолтный цвет текста для Elevated Button
          ),
        ),
      ),
      home: const TasksPage(),
    );
  }
}

// --- 2. Модель данных для Задачи (Task) ---
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

  // Метод для создания копии задачи с измененными полями
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

  // Преобразование объекта Task в Map для сохранения в базу данных
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dueDate': dueDate?.toIso8601String(), // Сохраняем дату как строку ISO 8601
      'isCompleted': isCompleted ? 1 : 0,    // SQLite не поддерживает булевы, используем 0/1
    };
  }

  // Создание объекта Task из Map, полученного из базы данных
  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      dueDate: map['dueDate'] != null ? DateTime.parse(map['dueDate']) : null,
      isCompleted: map['isCompleted'] == 1,
    );
  }
}

// --- 3. Database Helper (для sqflite) ---
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Получаем путь для хранения базы данных
    String path = join(await getApplicationDocumentsDirectory().then((dir) => dir.path), 'tasks_db.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tasks(
        id TEXT PRIMARY KEY,
        title TEXT,
        description TEXT,
        dueDate TEXT,
        isCompleted INTEGER
      )
    ''');
  }

  Future<void> insertTask(Task task) async {
    final db = await database;
    await db.insert(
      'tasks',
      task.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Task>> getTasks() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('tasks');
    return List.generate(maps.length, (i) {
      return Task.fromMap(maps[i]);
    });
  }

  Future<void> updateTask(Task task) async {
    final db = await database;
    await db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<void> deleteTask(String id) async {
    final db = await database;
    await db.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

// --- 4. Модель погоды (Weather Model) ---
class Weather {
  final String cityName;
  final double temperature;
  final String description;
  final String iconCode;

  Weather({
    required this.cityName,
    required this.temperature,
    required this.description,
    required this.iconCode,
  });

  factory Weather.fromJson(Map<String, dynamic> json) {
    return Weather(
      cityName: json['name'] as String,
      temperature: (json['main']['temp'] as num).toDouble(),
      description: json['weather'][0]['description'] as String,
      iconCode: json['weather'][0]['icon'] as String,
    );
  }
}

// --- 5. Сервис погоды (Weather Service) ---

class WeatherService {
  // ВАЖНО: Замените 'YOUR_API_KEY' на ваш реальный ключ API от OpenWeatherMap
  // Получить ключ можно здесь: https://openweathermap.org/api
  // Пример: 'd5d371a80e7c67c4b3a3e8f2b1f6a4a2'
  static const String _apiKey = 'YOUR_API_KEY'; // <<< ЗАМЕНИТЕ ЭТО!
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5/weather';

  Future<Weather> fetchWeather(String city) async {
    if (_apiKey == 'YOUR_API_KEY' || _apiKey.isEmpty) {
      throw Exception('OpenWeatherMap API Key not set. Please replace YOUR_API_KEY in main.dart.');
    }

    final response = await http.get(
      Uri.parse('$_baseUrl?q=$city&appid=$_apiKey&units=metric&lang=ru'),
    );

    if (response.statusCode == 200) {
      return Weather.fromJson(jsonDecode(response.body));
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'Failed to load weather data');
    }
  }
}

// --- 6. Страница задач (TasksPage) ---
class TasksPage extends StatefulWidget {
  const TasksPage({super.key});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  final Uuid _uuid = const Uuid();
  late List<Task> _tasks;
  late DatabaseHelper _dbHelper;

  // Переменные для погоды
  final WeatherService _weatherService = WeatherService();
  Weather? _weatherData;
  bool _isLoadingWeather = false;
  String? _weatherError;
  final TextEditingController _cityController = TextEditingController();
  static const String _lastCityKey = 'last_city'; // Ключ для Shared Preferences

  @override
  void initState() {
    super.initState();
    _tasks = [];
    _dbHelper = DatabaseHelper();
    _loadTasks(); // Загружаем задачи из БД
    _loadLastCityAndFetchWeather(); // Загружаем последний город и погоду
  }

  // Загрузка задач из базы данных
  Future<void> _loadTasks() async {
    try {
      final tasks = await _dbHelper.getTasks();
      setState(() {
        _tasks = tasks;
        // Сортировка: незавершенные выше завершенных, затем по дате
        _tasks.sort((a, b) {
          if (a.isCompleted && !b.isCompleted) return 1;
          if (!a.isCompleted && b.isCompleted) return -1;
          return (a.dueDate ?? DateTime(2100)).compareTo(b.dueDate ?? DateTime(2100));
        });
      });
    } catch (e) {
      _showSnackBar('Ошибка загрузки задач: $e', Colors.red);
    }
  }

  // Загрузка последнего выбранного города из Shared Preferences
  Future<void> _loadLastCityAndFetchWeather() async {
    final prefs = await SharedPreferences.getInstance();
    final lastCity = prefs.getString(_lastCityKey) ?? 'Moscow'; // Город по умолчанию
    _cityController.text = lastCity;
    _fetchWeather(lastCity);
  }

  // Сохранение последнего выбранного города в Shared Preferences
  Future<void> _saveLastCity(String city) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastCityKey, city);
  }

  // Получение погоды
  Future<void> _fetchWeather(String city) async {
    if (city.isEmpty) {
      setState(() {
        _weatherError = 'Пожалуйста, введите название города.';
        _weatherData = null;
      });
      return;
    }

    setState(() {
      _isLoadingWeather = true;
      _weatherError = null;
    });

    try {
      final weather = await _weatherService.fetchWeather(city);
      setState(() {
        _weatherData = weather;
      });
      await _saveLastCity(city); // Сохраняем город при успешном получении погоды
    } catch (e) {
      setState(() {
        _weatherError = e.toString().replaceFirst('Exception: ', '');
        _weatherData = null;
      });
    } finally {
      setState(() {
        _isLoadingWeather = false;
        });
    }
  }

  // Helper для вывода SnackBar
  void _showSnackBar(String message, [Color color = Colors.green]) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Добавление новой задачи
  void _addTask(Task newTask) async {
    await _dbHelper.insertTask(newTask);
    _loadTasks(); // Перезагружаем список
    _showSnackBar('Задача "${newTask.title}" добавлена.');
  }

  // Обновление задачи
  void _updateTask(Task updatedTask) async {
    await _dbHelper.updateTask(updatedTask);
    _loadTasks();
    _showSnackBar('Задача "${updatedTask.title}" обновлена.');
  }

  // Удаление задачи
  void _deleteTask(String id, String title) async {
    await _dbHelper.deleteTask(id);
    _loadTasks();
    _showSnackBar('Задача "${title}" удалена.', Colors.orange);
  }

  // Переключение статуса задачи
  void _toggleTaskCompletion(Task task) {
    final updatedTask = task.copyWith(isCompleted: !task.isCompleted);
    _updateTask(updatedTask);
    _showSnackBar(updatedTask.isCompleted ? 'Задача завершена!' : 'Задача возобновлена.', Colors.blue);
  }

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  // Показывает форму для добавления/редактирования задачи
  void _showTaskForm({Task? task}) {
    final TextEditingController titleController = TextEditingController(text: task?.title ?? '');
    final TextEditingController descriptionController = TextEditingController(text: task?.description ?? '');
    DateTime? selectedDate = task?.dueDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext bc) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(bc).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                task == null ? 'Новая Задача' : 'Редактировать Задачу',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Название задачи',
                  hintText: 'Например, Купить продукты',
                ),
                autofocus: true,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Описание (необязательно)',
                  hintText: 'Дополнительная информация о задаче',
                ),
                maxLines: 3,
                minLines: 1,
              ),
              const SizedBox(height: 10),
              StatefulBuilder(
                builder: (BuildContext context, StateSetter setModalState) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      selectedDate == null
                          ? 'Дата выполнения (необязательно)'
                          : 'Срок: ${selectedDate!.day}.${selectedDate!.month}.${selectedDate!.year}',
                      style: TextStyle(color: selectedDate == null ? Colors.white70 : Colors.white),
                    ),
                    trailing: const Icon(Icons.calendar_today, color: Colors.blue),
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate ?? DateTime.now(),
                        firstDate: DateTime.now(), // Начинаем с сегодняшнего дня
                        lastDate: DateTime(2101),
                      );
                      if (picked != null && picked != selectedDate) {
                        setModalState(() {
                          selectedDate = picked;
                        });
                      }
                    },
                  );
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (titleController.text.trim().isEmpty) {
                      _showSnackBar('Название задачи не может быть пустым.', Colors.red);
                      return;
                    }

                    if (task == null) {
                      // Добавление новой задачи
                      final newTask = Task(
                        id: _uuid.v4(),
                        title: titleController.text.trim(),
                        description: descriptionController.text.trim(),
                        dueDate: selectedDate,
                      );
                      _addTask(newTask);
                    } else {
                      // Редактирование существующей задачи
                      final updatedTask = task.copyWith(
                        title: titleController.text.trim(),
                        description: descriptionController.text.trim(),
                        dueDate: selectedDate,
                      );
                      _updateTask(updatedTask);
                    }
                    Navigator.pop(bc); // Закрываем BottomSheet
                  },
                  child: Text(task == null ? 'Добавить Задачу' : 'Сохранить Изменения'),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  // Сборка виджета списка задач
  // ВАЖНО: Этот метод _buildTaskList предназначен для использования внутри другого ListView
  // или Column, который уже имеет ограничение по высоте.
  // Поэтому ListView.builder внутри него использует shrinkWrap: true и NeverScrollableScrollPhysics.
  Widget _buildTaskList(
    BuildContext context,
    String title,
    List<Task> tasks,
    Color headerColor, {
    required bool showEdit,
    required bool showCheckbox,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: headerColor,
            ),
          ),
        ),
        if (tasks.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 10.0), // Добавлен отступ
              child: Text(
                'Нет задач',
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return TaskCard(
                task: task,
                onToggleComplete: _toggleTaskCompletion,
                onEdit: () => _showTaskForm(task: task),
                onDelete: _deleteTask,
              );
            },
          ),
      ],
    );
  }

  // Основной метод построения UI
  @override
  Widget build(BuildContext context) {
    final List<Task> incompleteTasks = _tasks.where((task) => !task.isCompleted).toList();
    final List<, // Запрос при нажатии Enter, убираем пробелы
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _fetchWeather(_cityController.text.trim()),
                  child: const Text('Найти'),
                ),
              ],
            ),
            const SizedBox(height: 15),
            if (_isLoadingWeather)
              const Center(child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ))
            else if (_weatherError != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'Ошибка: $_weatherError',
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else if (_weatherData != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _weatherData!.cityName,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${_weatherData!.temperature.toStringAsFixed(1)}°C',
                        style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w300),
                      ),
                      Text(
                        _weatherData!.description,
                        style: const TextStyle(fontSize: 18, color: Colors.white70),
                      ),
                    ],
                  ),
                  // Иконка погоды
                  Image.network(
                    'http://openweathermap.org/img/wn/${_weatherData!.iconCode}@2x.png',
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.cloud_off, size: 80, color: Colors.white38),
                  ),
                ],
              )
            else
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'Введите город, чтобы получить информацию о погоде.',
                    style: TextStyle(fontSize: 16, color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// --- 7. Виджет Карточки Задачи (TaskCard) ---
class TaskCard extends StatelessWidget {
  final Task task;
  final Function(Task) onToggleComplete;
  final VoidCallback onEdit;
  final Function(String, String) onDelete;

  const TaskCard({
    Key? key,
    required this.task,
    required this.onToggleComplete,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  void _confirmDelete(BuildContext context, String id, String title) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardTheme.color,
          title: const Text('Удалить задачу?', style: TextStyle(color: Colors.white)),
          content: Text('Вы уверены, что хотите удалить задачу "${title}"?', style: TextStyle(color: Colors.white70)),
          actions: <Widget>[
            TextButton(
              child: const Text('Отмена', style: TextStyle(color: Colors.white70)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Удалить'),
              onPressed: () {
                onDelete(id, title);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Checkbox(
              value: task.isCompleted,
              onChanged: (bool? value) {
                if (value != null) {
                  onToggleComplete(task);
                }
              },
              activeColor: Colors.blue,
              checkColor: Colors.white,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                      color: task.isCompleted ? Colors.white54 : Colors.white,
                    ),
                  ),
                  if (task.description.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        task.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: task.isCompleted ? Colors.white38 : Colors.white70,
                          decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                  if (task.dueDate != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        'Срок: ${task.dueDate!.day}.${task.dueDate!.month}.${task.dueDate!.year}',
                        style: TextStyle(
                          fontSize: 12,
                          color: task.isCompleted ? Colors.white38 : Colors.white60,
                          decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blueGrey),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              onPressed: () => _confirmDelete(context, task.id, task.title),
            ),
          ],
        ),
      ),
    );
  }
}
                        