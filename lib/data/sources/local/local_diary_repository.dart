import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../../core/export/diary_markdown_exporter.dart';
import '../../models/diary_entry.dart';
import '../../repositories/diary_repository.dart';

/// Stores each diary entry as a JSON file in the app's documents directory.
/// Each save ALSO writes a sibling `.md` file using the same date-based
/// filename — Obsidian Vaults pointed at this folder pick up the changes
/// automatically, and edits overwrite (never duplicate) the existing file.
///
/// File layout:
///   `<docs>/diary/yyyy-MM-dd.json`   ← source of truth
///   `<docs>/diary/yyyy-MM-dd.md`     ← rendered, Obsidian/Notion-friendly
class LocalDiaryRepository implements DiaryRepository {
  LocalDiaryRepository._(this._dir);

  final Directory _dir;

  /// Public access for the settings screen to display the diary folder path.
  @override
  String get folderPath => _dir.path;

  static Future<LocalDiaryRepository> open() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}${Platform.pathSeparator}diary');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return LocalDiaryRepository._(dir);
  }

  String _ymd(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  File _jsonFileFor(DateTime date) =>
      File('${_dir.path}${Platform.pathSeparator}${_ymd(date)}.json');

  File _mdFileFor(DateTime date) =>
      File('${_dir.path}${Platform.pathSeparator}${_ymd(date)}.md');

  @override
  Future<List<DiaryEntry>> listEntries() async {
    final files = await _dir
        .list()
        .where((e) => e is File && e.path.endsWith('.json'))
        .cast<File>()
        .toList();
    final entries = <DiaryEntry>[];
    for (final f in files) {
      try {
        final json = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
        entries.add(DiaryEntry.fromJson(json));
      } catch (_) {
        // Skip corrupt files — never break the list view.
      }
    }
    entries.sort((a, b) => b.date.compareTo(a.date));
    return entries;
  }

  @override
  Future<DiaryEntry?> getByDate(DateTime date) async {
    final f = _jsonFileFor(date);
    if (!await f.exists()) return null;
    try {
      final json = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
      return DiaryEntry.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<DiaryEntry?> getById(String id) async {
    final all = await listEntries();
    for (final e in all) {
      if (e.id == id) return e;
    }
    return null;
  }

  @override
  Future<void> save(DiaryEntry entry) async {
    // Source of truth — full JSON.
    await _jsonFileFor(entry.date)
        .writeAsString(jsonEncode(entry.toJson()));
    // Obsidian-friendly mirror — same filename, gets overwritten on every
    // edit so the Vault never accumulates duplicate files.
    await _mdFileFor(entry.date)
        .writeAsString(DiaryMarkdownExporter.render(entry));
  }

  @override
  Future<void> delete(String id) async {
    final entry = await getById(id);
    if (entry == null) return;
    final json = _jsonFileFor(entry.date);
    final md = _mdFileFor(entry.date);
    if (await json.exists()) await json.delete();
    if (await md.exists()) await md.delete();
  }
}
