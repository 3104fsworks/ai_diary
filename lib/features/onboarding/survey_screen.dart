import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_settings.dart';
import '../../app/router/app_router.dart';
import '../../app/service_locator.dart';
import '../../app/theme/app_theme.dart';
import '../../data/models/survey_response.dart';
import '../../l10n/generated/app_localizations.dart';

class SurveyScreen extends StatefulWidget {
  const SurveyScreen({super.key});

  @override
  State<SurveyScreen> createState() => _SurveyScreenState();
}

class _SurveyScreenState extends State<SurveyScreen> {
  int _index = 0;
  final _answers = <int, Set<String>>{};
  final _freeText = <int, TextEditingController>{};

  List<_Question> _questions(AppLocalizations l) => [
        _Question(
          title: l.surveyQ1,
          required: true,
          options: const [
            '日本',
            'United States',
            'United Kingdom',
            'France',
            'Germany',
            'Canada',
            'Australia',
            'Taiwan',
            'その他 / Other',
          ],
        ),
        _Question(
          title: l.surveyQ2,
          required: true,
          options: const ['iPhone', 'Android'],
        ),
        _Question(
          title: l.surveyQ3,
          required: true,
          options: const [
            '使っていない / None',
            'Apple Watch',
            'Pixel / Fitbit',
            'Amazfit',
            'Garmin',
            'その他 / Other',
          ],
        ),
        _Question(
          title: l.surveyQ4,
          required: true,
          multi: true,
          // New order per spec: phone default → none → news → yahoo → tenki
          options: const [
            'スマホ標準 / OS default',
            '特になし / None',
            'ウェザーニュース',
            'Yahoo!天気',
            'tenki.jp',
            'AccuWeather',
            'その他 / Other',
          ],
        ),
        _Question(
          title: l.surveyQ5,
          required: true,
          multi: true,
          options: const [
            '特になし / None',
            'Obsidian',
            'Notion',
            'Goodnotes',
            'Craft',
            'Apple メモ / Notes',
            'Evernote',
            'その他 / Other',
          ],
        ),
        _Question(
          title: l.surveyQ6,
          required: true,
          options: const [
            '紙の手帳 / Paper',
            'スマホのメモ / Notes app',
            '他の日記アプリ / Other diary app',
            '長続きしなかった / Never stuck',
            '日記をつけていなかった / Never tried',
          ],
        ),
        _Question(
          title: l.surveyQ7Gender,
          required: true,
          options: const [
            '男性 / Male',
            '女性 / Female',
            'その他 / Other',
            '回答しない / Prefer not to say',
          ],
        ),
        _Question(
          title: l.surveyQ7Age,
          required: true,
          options: const ['10代', '20代', '30代', '40代', '50代', '60代以上'],
        ),
        _Question(
          title: l.surveyQ8,
          required: true,
          options: const [
            'X (Twitter)',
            'YouTube',
            'ブログ / Blog',
            'Instagram',
            'TikTok',
            'ネット検索 / Web search',
            '友人の紹介 / Friend',
            'ストア検索 / Store',
          ],
        ),
        // Two optional free-text questions are merged into a single page
        // so users don't feel the survey drags on.
        _Question(
          title: l.surveyFinalTitle,
          required: false,
          finalPair: true,
          options: const [],
        ),
      ];

  bool _canAdvance(_Question q) {
    if (!q.required) return true;
    final selected = _answers[_index] ?? const {};
    return selected.isNotEmpty;
  }

  Future<void> _next(int total) async {
    if (_index < total - 1) {
      setState(() => _index++);
    } else {
      await _persistAnswers(total);
      if (!mounted) return;
      context.go(AppRoutes.tutorial);
    }
  }

  Future<void> _persistAnswers(int total) async {
    final services = Services.of(context);
    final settings = AppSettingsScope.of(context);
    // The final-pair page lives at index (total - 1); its two text fields
    // are stored at index * 10 and * 10 + 1.
    final finalIndex = total - 1;
    final pain = _freeText[finalIndex * 10]?.text.trim();
    final wish = _freeText[finalIndex * 10 + 1]?.text.trim();
    final response = SurveyResponse(
      capturedAt: DateTime.now().toUtc(),
      userId: settings.currentUserId,
      choices: {
        for (final e in _answers.entries) e.key: e.value.toList(),
      },
      painText: (pain != null && pain.isNotEmpty) ? pain : null,
      wishText: (wish != null && wish.isNotEmpty) ? wish : null,
    );
    try {
      await services.survey.save(response);
    } catch (_) {
      // Persistence failures shouldn't block onboarding.
    }
  }

  void _back() {
    if (_index > 0) setState(() => _index--);
  }

  @override
  void dispose() {
    for (final c in _freeText.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final qs = _questions(l);
    final q = qs[_index];
    final selected = _answers[_index] ?? <String>{};

    return Scaffold(
      appBar: AppBar(
        leading: _index > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                onPressed: _back,
              )
            : const SizedBox.shrink(),
        title: Text(
          '${_index + 1} / ${qs.length}',
          style: theme.textTheme.bodySmall,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(l.surveyTitle, style: theme.textTheme.bodySmall),
                  const SizedBox(width: 6),
                  if (!q.required)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: theme.dividerColor.withValues(alpha: 0.5),
                      ),
                      child: Text(
                        l.surveyOptional,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(q.title, style: theme.textTheme.headlineMedium),
              const SizedBox(height: 24),
              Expanded(
                child: q.finalPair
                    ? SingleChildScrollView(
                        child: _FinalPair(
                          painController: _freeText.putIfAbsent(
                            _index * 10,
                            () => TextEditingController(),
                          ),
                          wishController: _freeText.putIfAbsent(
                            _index * 10 + 1,
                            () => TextEditingController(),
                          ),
                          painLabel: l.surveyPainLabel,
                          wishLabel: l.surveyWishLabel,
                          hint: l.surveyFreeTextHint,
                          subtitle: l.surveyFinalHint,
                        ),
                      )
                    : ListView.separated(
                        itemCount: q.options.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          final option = q.options[i];
                          final isSelected = selected.contains(option);
                          return _OptionTile(
                            label: option,
                            selected: isSelected,
                            onTap: () => setState(() {
                              if (q.multi) {
                                if (isSelected) {
                                  selected.remove(option);
                                } else {
                                  selected.add(option);
                                }
                              } else {
                                selected
                                  ..clear()
                                  ..add(option);
                              }
                              _answers[_index] = selected;
                            }),
                          );
                        },
                      ),
              ),
              ElevatedButton(
                onPressed: _canAdvance(q) ? () => _next(qs.length) : null,
                child: Text(
                  _index == qs.length - 1 ? l.surveyFinish : l.surveyNext,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Question {
  final String title;
  final List<String> options;
  final bool multi;
  final bool required;
  final bool finalPair;
  const _Question({
    required this.title,
    required this.options,
    this.multi = false,
    this.required = true,
    this.finalPair = false,
  });
}

class _OptionTile extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _OptionTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radius),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radius),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary
                : theme.dividerColor,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(child: Text(label, style: theme.textTheme.bodyLarge)),
            if (selected)
              Icon(
                Icons.check,
                size: 18,
                color: theme.colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }
}

/// Two free-text fields stacked into the final survey page so the survey
/// ends on one screen instead of two.
class _FinalPair extends StatelessWidget {
  final TextEditingController painController;
  final TextEditingController wishController;
  final String painLabel;
  final String wishLabel;
  final String hint;
  final String subtitle;

  const _FinalPair({
    required this.painController,
    required this.wishController,
    required this.painLabel,
    required this.wishLabel,
    required this.hint,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(subtitle, style: theme.textTheme.bodySmall),
        const SizedBox(height: 16),
        Text(painLabel, style: theme.textTheme.titleMedium),
        const SizedBox(height: 6),
        _FreeText(controller: painController, hint: hint),
        const SizedBox(height: 20),
        Text(wishLabel, style: theme.textTheme.titleMedium),
        const SizedBox(height: 6),
        _FreeText(controller: wishController, hint: hint),
      ],
    );
  }
}

class _FreeText extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  const _FreeText({required this.controller, required this.hint});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radius),
          border: Border.all(color: theme.dividerColor),
        ),
        // minLines starts compact; field grows as the user types.
        child: TextField(
          controller: controller,
          minLines: 2,
          maxLines: null,
          textAlignVertical: TextAlignVertical.top,
          style: theme.textTheme.bodyLarge,
          decoration: InputDecoration(hintText: hint),
        ),
      ),
    );
  }
}
