import 'package:flutter/material.dart';
import 'tasks_page.dart'; // Импорт страницы со списком задач

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
