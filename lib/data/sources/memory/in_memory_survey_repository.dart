import '../../models/survey_response.dart';
import '../../repositories/survey_repository.dart';

/// Web / preview fallback. Lives only for the current session.
class InMemorySurveyRepository implements SurveyRepository {
  SurveyResponse? _response;

  @override
  Future<void> save(SurveyResponse response) async {
    _response = response;
  }

  @override
  Future<SurveyResponse?> load() async => _response;
}
