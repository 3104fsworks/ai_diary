import '../models/diary_entry.dart';

/// Abstract repository so the UI never sees storage details.
/// Swap the implementation later (local file / Firebase / iCloud / Drive).
abstract class DiaryRepository {
  Future<List<DiaryEntry>> listEntries();
  Future<DiaryEntry?> getByDate(DateTime date);
  Future<DiaryEntry?> getById(String id);
  Future<void> save(DiaryEntry entry);
  Future<void> delete(String id);

  /// On-disk folder where individual `.md` files live (when applicable).
  /// Cloud / in-memory implementations may return null.
  String? get folderPath => null;
}
