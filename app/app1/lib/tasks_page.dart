import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'task_model.dart';
import 'add_task_page.dart';
import 'viewmodels/task_viewmodel.dart'; // Новый импорт

class TasksPage extends StatefulWidget {
  const TasksPage({super.key});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  @override
  void initState() {
    super.initState();
    // Загружаем задачи через ViewModel
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskViewModel>().loadTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Мои Задачи',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Consumer<TaskViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (viewModel.errorMessage != null) {
            return Center(
              child: Text(
                'Ошибка: ${viewModel.errorMessage}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          List<Task> activeTasks = viewModel.tasks.where((task) => !task.isCompleted).toList();
          List<Task> completedTasks = viewModel.tasks.where((task) => task.isCompleted).toList();

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildTaskList(
                    context,
                    'Активные задачи',
                    activeTasks,
                    Colors.blue,
                    showEdit: true,
                    showCheckbox: true,
                    viewModel: viewModel,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: _buildTaskList(
                    context,
                    'Завершенные задачи',
                    completedTasks,
                    Colors.green,
                    showEdit: false,
                    showCheckbox: false,
                    viewModel: viewModel,
                  ),
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
        label: const Text('Добавить новую задачу'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildTaskList(
    BuildContext context,
    String title,
    List<Task> tasks,
    Color titleColor, {
    required bool showEdit,
    required bool showCheckbox,
    required TaskViewModel viewModel,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: titleColor,
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: tasks.isEmpty
              ? Center(
                  child: Text(
                    'Здесь пока пусто.',
                    style: const TextStyle(color: Colors.white70),
                  ),
                )
              : ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return Card(
                      elevation: 2.0,
                      margin: const EdgeInsets.symmetric(vertical: 6.0),
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
                            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                            color: Colors.white,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (task.description.isNotEmpty)
                              Text(
                                task.description,
                                style: const TextStyle(color: Colors.white70),
                              ),
                            if (task.dueDate != null)
                              Text(
                                'Срок: ${task.dueDate!.day}.${task.dueDate!.month}.${task.dueDate!.year}',
                                style: const TextStyle(fontSize: 12, color: Colors.white54),
                              ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (showEdit)
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.amber),
                                onPressed: () async {
                                  final updatedTask = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AddTaskPage(taskToEdit: task),
                                    ),
                                  );
                                  if (updatedTask != null && updatedTask is Task) {
                                    viewModel.updateTask(updatedTask);
                                  }
                                },
                              ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                viewModel.deleteTask(task.id);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
