import 'tasks_service.dart';

class MockTasksService implements TasksService {
  @override
  bool get isSupported => true;

  @override
  Future<bool> hasPermissions() async => true;

  @override
  Future<bool> requestPermissions() async => true;

  @override
  Future<List<String>> getCompletedTasksFor(DateTime date) async {
    return const ['資料レビュー', '銀行へ振込'];
  }
}
