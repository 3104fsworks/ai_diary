import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../models/survey_response.dart';
import '../../repositories/survey_repository.dart';

/// `<docs>/survey/response.json`
class LocalSurveyRepository implements SurveyRepository {
  LocalSurveyRepository._(this._file);
  final File _file;

  static Future<LocalSurveyRepository> open() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}${Platform.pathSeparator}survey');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return LocalSurveyRepository._(
      File('${dir.path}${Platform.pathSeparator}response.json'),
    );
  }

  @override
  Future<void> save(SurveyResponse response) async {
    await _file.writeAsString(jsonEncode(response.toJson()));
  }

  @override
  Future<SurveyResponse?> load() async {
    if (!await _file.exists()) return null;
    try {
      final json = jsonDecode(await _file.readAsString())
          as Map<String, dynamic>;
      return SurveyResponse.fromJson(json);
    } catch (_) {
      return null;
    }
  }
}
