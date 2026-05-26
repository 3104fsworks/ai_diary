import '../models/survey_response.dart';

/// Persists onboarding survey answers.
///
/// Local implementations write to a single file in the app's documents
/// directory (so the user can move / delete it). A future
/// FirestoreSurveyRepository will additionally push to a server.
abstract class SurveyRepository {
  Future<void> save(SurveyResponse response);
  Future<SurveyResponse?> load();
}
