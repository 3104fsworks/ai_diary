/// Read-only bridge to the user's task list (Google Tasks today).
abstract class TasksService {
  bool get isSupported;
  Future<bool> hasPermissions();
  Future<bool> requestPermissions();

  /// Tasks the user marked completed on [date].
  Future<List<String>> getCompletedTasksFor(DateTime date);
}
