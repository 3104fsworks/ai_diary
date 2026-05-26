import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/models/diary_entry.dart';
import 'diary_markdown_exporter.dart';

/// Bundles every diary entry as one `.md` file per day inside a single ZIP,
/// then opens the OS share sheet. Obsidian / Notion can ingest the unzipped
/// folder directly.
///
/// Filename convention:
///   archive: ai-journal-export-yyyy-MM-dd.zip
///   inside : yyyy-MM-dd.md  (one per entry, date-sortable)
class BulkMarkdownExporter {
  BulkMarkdownExporter._();

  static String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static Future<File> bundle(List<DiaryEntry> entries) async {
    final archive = Archive();
    for (final e in entries) {
      final md = DiaryMarkdownExporter.render(e);
      final bytes = utf8.encode(md);
      archive.addFile(
        ArchiveFile('${_ymd(e.date)}.md', bytes.length, bytes),
      );
    }
    final encoded = ZipEncoder().encode(archive);
    if (encoded == null) {
      throw StateError('Failed to encode the export archive.');
    }
    final tmp = await getTemporaryDirectory();
    final exportDate = _ymd(DateTime.now());
    final file = File(
      '${tmp.path}${Platform.pathSeparator}'
      'ai-journal-export-$exportDate.zip',
    );
    await file.writeAsBytes(encoded);
    return file;
  }

  /// Builds the ZIP and opens the OS share sheet.
  /// Returns the number of entries exported (0 means nothing was shared).
  static Future<int> share(List<DiaryEntry> entries) async {
    if (entries.isEmpty) return 0;
    final file = await bundle(entries);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/zip')],
      text: 'AI Journal export',
    );
    return entries.length;
  }
}
