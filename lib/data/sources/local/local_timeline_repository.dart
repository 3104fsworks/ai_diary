import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../models/diary_entry.dart';
import '../../repositories/timeline_repository.dart';

/// `<docs>/timeline/yyyy-MM-dd.json`
class LocalTimelineRepository implements TimelineRepository {
  LocalTimelineRepository._(this._dir);
  final Directory _dir;

  static Future<LocalTimelineRepository> open() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}${Platform.pathSeparator}timeline');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return LocalTimelineRepository._(dir);
  }

  File _fileFor(DateTime date) {
    final ymd =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return File('${_dir.path}${Platform.pathSeparator}$ymd.json');
  }

  @override
  Future<List<TimelineStop>> getStays(DateTime date) async {
    final f = _fileFor(date);
    if (!await f.exists()) return const [];
    try {
      final list = jsonDecode(await f.readAsString()) as List;
      return list
          .map((e) => e as Map<String, dynamic>)
          .map((m) => TimelineStop(
                place: m['place'] as String,
                time: m['time'] as String,
              ))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<void> appendStay(DateTime date, TimelineStop stay) async {
    final current = await getStays(date);
    final next = [...current, stay];
    await replace(date, next);
  }

  @override
  Future<void> replace(DateTime date, List<TimelineStop> stays) async {
    final f = _fileFor(date);
    final encoded = jsonEncode(
      stays.map((s) => {'place': s.place, 'time': s.time}).toList(),
    );
    await f.writeAsString(encoded);
  }
}
