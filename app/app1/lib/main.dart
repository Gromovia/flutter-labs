import 'dart:io' show Platform;  // Добавлено для проверки платформы
import 'package:flutter/foundation.dart' show kIsWeb;  // Добавлено для проверки на веб
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';  // Добавлено для FFI (только для desktop)
import 'tasks_page.dart';
import 'viewmodels/task_viewmodel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();  // Добавлено для асинхронной инициализации

  // Инициализация FFI для Sqflite только на desktop платформах (не в веб)
  if (!kIsWeb) {  // Проверка, что не веб
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  }
  // Для веб: Sqflite не поддерживается нативно, так что базу данных нужно заменить на веб-совместимую альтернативу (например, Hive или IndexedDB через плагин). Пока что приложение запустится без инициализации базы, но функционал с задачами может не работать в веб.

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TaskViewModel()),
      ],
      child: MaterialApp(
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
        ),
        home: const TasksPage(),
      ),
    );
  }
}
