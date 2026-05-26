import '../../models/diary_entry.dart';
import '../../models/goal_item.dart';
import '../../repositories/diary_repository.dart';

/// In-memory mock — replaced later with a real local source.
class MockDiaryRepository implements DiaryRepository {
  MockDiaryRepository() : _entries = _seed();

  final List<DiaryEntry> _entries;

  static List<DiaryEntry> _seed() {
    final today = DateTime.now();
    return List.generate(6, (i) {
      final d = today.subtract(Duration(days: i + 1));
      return DiaryEntry(
        id: 'seed-$i',
        date: DateTime(d.year, d.month, d.day),
        aiTitle: _titles[i % _titles.length],
        userMemo: '',
        aiJournal:
            '今日は穏やかな1日でした。午後は少し歩いて、夕方には自分の時間を持つことができました。',
        aiFeedback: 'よく歩いた1日でしたね。',
        weather: const WeatherInfo(
          kind: WeatherKind.sunny,
          tempC: 22,
          place: 'Tokyo',
        ),
        activity: const ActivityInfo(steps: 7432, sleepHours: 7.5),
        goals: const [
          GoalItem(id: 'g1', labelKey: 'goalSteps', checked: true),
          GoalItem(id: 'g2', labelKey: 'goalNoMoney'),
          GoalItem(id: 'g3', labelKey: 'goalThanks', checked: true),
        ],
      );
    });
  }

  static const _titles = [
    '渋谷で打ち合わせ、夜は自炊',
    'のんびりとした休日',
    '読書とコーヒー',
    '新しい本を買った日',
    '雨、家で過ごす',
    '友人とランチ',
  ];

  @override
  String? get folderPath => null;

  @override
  Future<List<DiaryEntry>> listEntries() async {
    await Future<void>.delayed(const Duration(milliseconds: 60));
    return List.unmodifiable(_entries);
  }

  @override
  Future<DiaryEntry?> getById(String id) async {
    for (final e in _entries) {
      if (e.id == id) return e;
    }
    return null;
  }

  @override
  Future<DiaryEntry?> getByDate(DateTime date) async {
    for (final e in _entries) {
      if (e.date.year == date.year &&
          e.date.month == date.month &&
          e.date.day == date.day) {
        return e;
      }
    }
    return null;
  }

  @override
  Future<void> save(DiaryEntry entry) async {
    final i = _entries.indexWhere((e) => e.id == entry.id);
    if (i >= 0) {
      _entries[i] = entry;
    } else {
      _entries.insert(0, entry);
    }
  }

  @override
  Future<void> delete(String id) async {
    _entries.removeWhere((e) => e.id == id);
  }
}
