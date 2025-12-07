import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'task_model.dart';
import 'add_task_page.dart';
import 'viewmodels/task_viewmodel.dart';

class TasksPage extends StatefulWidget {
  const TasksPage({super.key});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskViewModel>().loadTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Полностью черный фон
      appBar: AppBar(
        title: const Text(
          'Мои Задачи',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.black, // Черный AppBar
      ),
      body: Consumer<TaskViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            );
          }
          if (viewModel.errorMessage != null) {
            return Center(
              child: Text(
                'Ошибка: ${viewModel.errorMessage}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          List<Task> activeTasks =
              viewModel.tasks.where((task) => !task.isCompleted).toList();
          List<Task> completedTasks =
              viewModel.tasks.where((task) => task.isCompleted).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Активные задачи
                _buildTaskSection(
                  context,
                  'Активные задачи',
                  activeTasks,
                  Colors.blue[400]!, // Синий цвет для заголовка активных задач
                  showEdit: true,
                  showCheckbox: true,
                  viewModel: viewModel,
                ),
                const SizedBox(height: 20),
                // Завершенные задачи
                _buildTaskSection(
                  context,
                  'Завершенные задачи',
                  completedTasks,
                  Colors.green[400]!, // Более яркий зеленый для завершенных
                  showEdit: false,
                  showCheckbox: false,
                  viewModel: viewModel,
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final newTask = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddTaskPage()),
          );
          if (newTask != null && newTask is Task) {
            context.read<TaskViewModel>().addTask(newTask);
          }
        },
        label: const Text(
          'Добавить новую задачу',
          style: TextStyle(fontSize: 14),
        ),
        icon: const Icon(Icons.add, size: 20),
        backgroundColor: Colors.blue[700], // Синяя кнопка
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildTaskSection(
    BuildContext context,
    String title,
    List<Task> tasks,
    Color titleColor, {
    required bool showEdit,
    required bool showCheckbox,
    required TaskViewModel viewModel,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: titleColor,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[900], // Темно-серый фон для контейнера (немного ярче черного)
            borderRadius: BorderRadius.circular(8),
          ),
          child: tasks.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: Text(
                      'Здесь пока пусто.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: tasks.map((task) {
                    return Card(
                      elevation: 2.0,
                      margin: const EdgeInsets.symmetric(
                          vertical: 6.0, horizontal: 8.0),
                      color: Colors.grey[800], // Серые плашки (ярче черного)
                      child: ListTile(
                        leading: showCheckbox
                            ? Checkbox(
                                value: task.isCompleted,
                                onChanged: (bool? value) {
                                  viewModel.toggleTaskCompletion(task.id);
                                },
                                activeColor: Colors.blue,
                                checkColor: Colors.white,
                              )
                            : null,
                        title: Text(
                          task.title,
                          style: TextStyle(
                            decoration: task.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (task.description.isNotEmpty)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4.0),
                                child: Text(
                                  task.description,
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            if (task.dueDate != null)
                              Text(
                                'Срок: ${task.dueDate!.day}.${task.dueDate!.month}.${task.dueDate!.year}',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.white54),
                              ),
                          ],
                        ),
                        trailing: SizedBox(
                          width: 80,
                          child: Row(
                            children: [
                              if (showEdit)
                                IconButton(
                                  icon: const Icon(Icons.edit,
                                      color: Colors.amber, size: 18),
                                  onPressed: () async {
                                    final updatedTask = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            AddTaskPage(taskToEdit: task),
                                      ),
                                    );
                                    if (updatedTask != null &&
                                        updatedTask is Task) {
                                      viewModel.updateTask(updatedTask);
                                    }
                                  },
                                ),
                              IconButton(
                                icon: const Icon(Icons.delete,
                                    color: Colors.red, size: 18),
                                onPressed: () {
                                  viewModel.deleteTask(task.id);
                                },
                              ),
                            ],
                          ),
                        ),
                        minVerticalPadding: 10,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        isThreeLine:
                            task.description.isNotEmpty || task.dueDate != null,
                      ),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }
}
