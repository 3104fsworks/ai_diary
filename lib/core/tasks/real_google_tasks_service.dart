import 'package:googleapis/tasks/v1.dart' as gtasks;

import '../auth/auth_service.dart';
import 'tasks_service.dart';

/// Live implementation backed by Google Tasks v1. Walks every task list
/// the user owns and returns the titles of tasks completed on [date].
class RealGoogleTasksService implements TasksService {
  RealGoogleTasksService({required this.auth});

  final AuthService auth;

  @override
  bool get isSupported => true;

  @override
  Future<bool> hasPermissions() async => auth.isGoogleUser;

  @override
  Future<bool> requestPermissions() {
    return auth.requestGoogleScopes(const [GoogleApiScopes.tasksReadonly]);
  }

  @override
  Future<List<String>> getCompletedTasksFor(DateTime date) async {
    final client = await auth.authenticatedGoogleClient();
    if (client == null) return const [];
    try {
      final api = gtasks.TasksApi(client);
      final lists = await api.tasklists.list();
      final start = DateTime(date.year, date.month, date.day).toUtc();
      final end = start.add(const Duration(days: 1));

      final out = <String>[];
      for (final list in lists.items ?? const <gtasks.TaskList>[]) {
        final listId = list.id;
        if (listId == null) continue;
        // showCompleted + showHidden together is necessary; Google hides
        // completed tasks by default after the user clears them.
        final tasks = await api.tasks.list(
          listId,
          showCompleted: true,
          showHidden: true,
          // Tasks API wants RFC 3339 strings, not DateTime objects.
          completedMin: start.toIso8601String(),
          completedMax: end.toIso8601String(),
        );
        for (final t in tasks.items ?? const <gtasks.Task>[]) {
          if (t.status == 'completed' && (t.title ?? '').isNotEmpty) {
            out.add(t.title!);
          }
        }
      }
      return out;
    } catch (_) {
      return const [];
    } finally {
      client.close();
    }
  }
}
