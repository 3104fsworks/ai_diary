// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'AI Journal';

  @override
  String get loginWelcome => 'Welcome';

  @override
  String get loginSubtitle => 'A minimal AI diary for the quiet life.';

  @override
  String get loginPrivacyTitle => 'Your privacy, in your hands.';

  @override
  String get loginPrivacyBody =>
      'We do not look into your everyday life.\n• Your diary, photos and location data are never stored on our servers.\n• Your data is never used to train AI models.\n• Everything stays on your device (or your own cloud).\n* Because of local storage, recovery on device loss must be done from your own backup (iCloud / Google Drive auto-sync).';

  @override
  String get loginWithGoogle => 'Continue with Google';

  @override
  String get loginWithApple => 'Continue with Apple';

  @override
  String get loginWithEmail => 'Continue with Email';

  @override
  String get loginWithEmailSignIn => 'Sign in with Email';

  @override
  String get loginWithEmailSignUp => 'Create account with Email';

  @override
  String get loginSignInFailed => 'Sign-in failed. Please try again.';

  @override
  String get loginCancelled => 'Sign-in cancelled.';

  @override
  String get emailAuthSignInTitle => 'Sign in';

  @override
  String get emailAuthSignUpTitle => 'Create account';

  @override
  String get emailAuthEmailLabel => 'Email';

  @override
  String get emailAuthPasswordLabel => 'Password';

  @override
  String get emailAuthPasswordHint => '8 characters or more';

  @override
  String get emailAuthSignInButton => 'Sign in';

  @override
  String get emailAuthSignUpButton => 'Create account';

  @override
  String get emailAuthToggleToSignUp => 'Don\'t have an account? Create one';

  @override
  String get emailAuthToggleToSignIn => 'Already have an account? Sign in';

  @override
  String get emailAuthForgotPassword => 'Forgot your password?';

  @override
  String get emailAuthResetSent => 'Password reset email sent.';

  @override
  String get emailAuthResetEnterEmail => 'Enter your email first.';

  @override
  String get authErrorInvalidEmail => 'That email address looks invalid.';

  @override
  String get authErrorWrongPassword => 'Email or password is incorrect.';

  @override
  String get authErrorEmailInUse =>
      'That email is already registered. Try signing in.';

  @override
  String get authErrorWeakPassword => 'Use a longer / stronger password.';

  @override
  String get authErrorUserNotFound => 'No account found for that email.';

  @override
  String get authErrorNetwork => 'Network error. Check your connection.';

  @override
  String get authErrorGeneric => 'Something went wrong. Please try again.';

  @override
  String get inviteTitle => 'Got an invite code?';

  @override
  String get inviteSubtitle => 'Enter it now and unlock the gift.';

  @override
  String get inviteHint => 'AID-XXXX-XXXX-XXXX';

  @override
  String get inviteRedeem => 'Redeem';

  @override
  String get inviteSkip => 'I don\'t have one';

  @override
  String get inviteSuccessLifetime =>
      'Code accepted. You have lifetime free access.';

  @override
  String get inviteSuccessMonth =>
      'Code accepted. You have 1 month of free access.';

  @override
  String get inviteAlreadyUsed => 'You\'ve already redeemed this code.';

  @override
  String get inviteInvalid => 'This code isn\'t valid.';

  @override
  String get inviteContinue => 'Continue';

  @override
  String get surveyTitle => 'Just a few questions';

  @override
  String get surveySubtitle => '30 seconds. No typing needed.';

  @override
  String get surveyNext => 'Next';

  @override
  String get surveyBack => 'Back';

  @override
  String get surveyFinish => 'Done';

  @override
  String get surveySkip => 'Skip';

  @override
  String get surveyQ1 => 'Where do you live?';

  @override
  String get surveyQ2 => 'Which phone do you use?';

  @override
  String get surveyQ3 => 'Do you use a smartwatch?';

  @override
  String get surveyQ4 => 'Which weather app do you use?';

  @override
  String get surveyQ5 => 'Which note app do you use?';

  @override
  String get surveyQ6 => 'Where did you write diaries before?';

  @override
  String get surveyQ7Gender => 'Gender';

  @override
  String get surveyQ7Age => 'Age range';

  @override
  String get surveyQ8 => 'How did you find us?';

  @override
  String get surveyQ9Pain =>
      'What\'s missing in your current diary app? (optional)';

  @override
  String get surveyQ10Wish => 'What do you want from this app? (optional)';

  @override
  String get surveyOptional => 'optional';

  @override
  String get surveyFreeTextHint => 'Tap to write your thoughts...';

  @override
  String get surveyFinalTitle => 'Anything you\'d like to share?';

  @override
  String get surveyFinalHint => 'Both are optional.';

  @override
  String get surveyPainLabel => 'Things missing from past diary apps';

  @override
  String get surveyWishLabel => 'What you\'d like from this app';

  @override
  String get tutorialTitle1 => 'Your day, ready when you open the app.';

  @override
  String get tutorialBody1 =>
      'Steps, schedule, weather and tasks are gathered for you in the background. You only add the moments that mattered.';

  @override
  String get tutorialTitle2 => 'Speak. Snap. Tick.';

  @override
  String get tutorialBody2 =>
      'Just talk for a moment, add a photo, tick today\'s goals.';

  @override
  String get tutorialTitle3 => 'Press Done. That\'s it.';

  @override
  String get tutorialBody3 =>
      'An AI diary that won\'t disappear, safely on your device.';

  @override
  String get tutorialStart => 'Get started';

  @override
  String get tutorialSkip => 'Skip';

  @override
  String get homeWeeklyRadio => 'Weekly AI Radio';

  @override
  String get homeViewPast => 'Past diaries';

  @override
  String get homeWriteToday => 'Write diary';

  @override
  String get homeSettings => 'Settings';

  @override
  String get homeHelp => 'Help';

  @override
  String get appTitleLine => 'AI Journal';

  @override
  String get diaryTodaysDiary => 'Today';

  @override
  String get diaryTalkWithAI => 'Voice input';

  @override
  String get diaryVoiceShort => 'Voice';

  @override
  String get diaryVoiceTooltipTitle => 'Talk to your day';

  @override
  String get diaryVoiceTooltipBody =>
      'Tap to start speaking. We keep listening until you tap again — pause, look up, think.';

  @override
  String get diaryVoiceListening => 'Listening...';

  @override
  String get diaryAddPhoto => 'Add photo';

  @override
  String get diaryPlaceholder => 'Anything on your mind...';

  @override
  String get diaryDailyGoals => 'Daily Goals';

  @override
  String get diaryActivity => 'Activity';

  @override
  String get diaryActivitySteps => 'Steps';

  @override
  String get diaryActivitySleep => 'Sleep';

  @override
  String diaryActivityHours(String value) {
    return '$value h';
  }

  @override
  String get diaryActivityDash => '—';

  @override
  String get diarySchedule => 'Schedule';

  @override
  String get diaryDoneTasks => 'Done Tasks';

  @override
  String get diaryTimeline => 'Timeline';

  @override
  String get diaryJournal => 'Journal';

  @override
  String get diaryPhotos => 'Photos';

  @override
  String get diaryAIFeedback => 'AI Feedback';

  @override
  String get diaryDone => 'Done';

  @override
  String get diaryShareSNS => 'Save SNS image';

  @override
  String get diaryEmptySchedule => 'No events on your calendar.';

  @override
  String get diarySaving => 'Saving...';

  @override
  String get diarySaved => 'Saved';

  @override
  String get historyTitle => 'Past Diaries';

  @override
  String get historyEmpty => 'No diary yet.';

  @override
  String get historyEmptyHint => 'Your first diary will live here.';

  @override
  String get historyEmptyCta => 'Write today';

  @override
  String get historyDelete => 'Delete';

  @override
  String get historyDeleteConfirm => 'Delete this diary?';

  @override
  String get historyDeleteBody =>
      'This removes the entry and its .md file from your device. This cannot be undone.';

  @override
  String get historyDeleted => 'Deleted';

  @override
  String get historySearchHint => 'Search diaries...';

  @override
  String get commonError => 'Something went wrong.';

  @override
  String get commonRetry => 'Try again';

  @override
  String get settingsTitle => 'Settings & Help';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsAccent => 'Color';

  @override
  String get settingsFontScale => 'Text size';

  @override
  String get fontScaleSmall => 'Small';

  @override
  String get fontScaleMedium => 'Default';

  @override
  String get fontScaleLarge => 'Large';

  @override
  String get fontScaleExtraLarge => 'Extra large';

  @override
  String get settingsIntegrations => 'Integrations';

  @override
  String get settingsHealth => 'Health (Apple Health / Health Connect)';

  @override
  String get settingsHealthUnavailable =>
      'Health Connect is not available on this device.';

  @override
  String get settingsHealthDenied =>
      'Health permission was not granted. Enable it in Health Connect / Apple Health.';

  @override
  String get settingsLocationDenied =>
      'Location permission was not granted. Enable it in OS Settings.';

  @override
  String get settingsCalendarDenied =>
      'Calendar access was not granted. Sign in with Google and grant calendar permission.';

  @override
  String get settingsTasksDenied =>
      'Google Tasks access was not granted. Sign in with Google and grant tasks permission.';

  @override
  String get settingsCalendar => 'Google Calendar';

  @override
  String get settingsTodo => 'Google Tasks';

  @override
  String get settingsLocation => 'Location timeline';

  @override
  String get settingsPlan => 'Plan';

  @override
  String get settingsUpgrade => 'Upgrade';

  @override
  String get settingsAutoSync => 'Auto Sync (iCloud / Google Drive)';

  @override
  String get settingsDiaryFolder => 'Diary folder (for Obsidian)';

  @override
  String get settingsDiaryFolderHint =>
      'Point your Obsidian Vault here. Each diary is a .md file that\'s overwritten in place when you edit it — no duplicates.';

  @override
  String get settingsDiaryFolderCopy => 'Copy path';

  @override
  String get settingsDiaryFolderCopied => 'Path copied';

  @override
  String get settingsBulkMarkdown => 'Export all as Markdown (.zip)';

  @override
  String get settingsBulkMarkdownHint =>
      'One .md file per day. Drop into Obsidian or Notion.';

  @override
  String get settingsBulkMarkdownNone => 'No diaries to export yet.';

  @override
  String settingsBulkMarkdownDone(int count) {
    return '$count diaries packaged.';
  }

  @override
  String get settingsDataMigration => 'Export / Import (ZIP)';

  @override
  String get settingsReferral => 'Referral code';

  @override
  String get settingsReferralBody =>
      'Invite a friend — both of you get 1 month free.';

  @override
  String get settingsFaq => 'FAQ / Help';

  @override
  String get settingsHowTo => 'How to use';

  @override
  String get settingsGoals => 'Daily goals';

  @override
  String get goalsTitle => 'Edit daily goals';

  @override
  String get goalsHint => 'These appear on each day\'s diary as a checklist.';

  @override
  String get goalsAdd => 'Add goal';

  @override
  String get goalsLimitFree => 'Free plan: up to 3 goals';

  @override
  String get goalsLimitPremium => 'Premium: up to 6 goals';

  @override
  String get goalsNamePlaceholder => 'e.g. Walk 5,000 steps';

  @override
  String get goalsDelete => 'Delete';

  @override
  String get language => 'Language';

  @override
  String get settingsPrivacyFooter =>
      'We never see your data. Diaries and photos stay on your device or your own cloud only.';

  @override
  String get settingsPrivacyPolicy => 'Privacy policy';

  @override
  String get settingsTerms => 'Terms of service';

  @override
  String get settingsAccount => 'Account';

  @override
  String get settingsAccountSignedInAs => 'Signed in as';

  @override
  String get settingsAccountDemo => 'Demo account (no email)';

  @override
  String get settingsSignOut => 'Sign out';

  @override
  String get settingsSignOutConfirm => 'Sign out of this device?';

  @override
  String get settingsSignOutBody =>
      'Your diaries stay on the device. You\'ll need to sign in again to add new entries.';

  @override
  String get settingsAiPersonality => 'AI personality';

  @override
  String get personalityStandard => 'Standard';

  @override
  String get personalityStandardDesc => 'Polite, clear, intellectual.';

  @override
  String get personalityMirroring => 'Mirror my voice';

  @override
  String get personalityMirroringDesc =>
      'Matches your tone, endings and vocabulary.';

  @override
  String get personalityFriendly => 'Warm & kind';

  @override
  String get personalityFriendlyDesc =>
      'A close-friend tone that gently cheers you on.';

  @override
  String get exportMarkdown => 'Export as Markdown';

  @override
  String get exportShared => 'Shared';

  @override
  String get diaryRawVoice => 'Today\'s whisper';

  @override
  String get diaryRawVoiceHint => 'Your own words, kept as you spoke them.';

  @override
  String get diaryRawVoiceShow => 'Show what I actually said';

  @override
  String get diaryRawVoiceHide => 'Hide';

  @override
  String get diaryJournalEditHint => 'Tap to refine.';

  @override
  String get diaryJournalSavedEdit => 'Edited';

  @override
  String get diaryAiFallback =>
      'Saved. AI was unreachable — used the offline draft.';

  @override
  String get settingsAiApiTitle => 'AI API';

  @override
  String get settingsAiApiKey => 'Gemini API key';

  @override
  String get settingsAiApiKeyNotSet => 'Not set — offline drafts will be used';

  @override
  String get settingsAiApiKeyDialogTitle => 'Gemini API key';

  @override
  String get settingsAiApiKeyDialogHint => 'Paste your key here';

  @override
  String get settingsAiApiKeyClear => 'Remove';

  @override
  String get settingsAiApiKeyHelp =>
      'Get a free key from Google AI Studio. We store it only on this device.';

  @override
  String get quotaTitle => 'Today\'s diary is already written.';

  @override
  String get quotaBody =>
      'Free plan allows one AI diary per day. Upgrade to Premium for unlimited diaries and personality choice — or bring your own API key.';

  @override
  String get quotaLater => 'Later';

  @override
  String get quotaUpgrade => 'See plans';

  @override
  String get lockedPremium => 'Premium';

  @override
  String get lockedPersonality =>
      'Personality is fixed to Standard on the free plan.';

  @override
  String get lockedByok => 'Bring-your-own API key is available on Premium.';

  @override
  String get planTestEnable => '[Test] Enable Premium';

  @override
  String get planTestDisable => '[Test] Disable Premium';

  @override
  String get planSubscribe => 'Subscribe';

  @override
  String get planRestore => 'Restore purchases';

  @override
  String get planRestoreSuccess => 'Purchases restored successfully.';

  @override
  String get planRestoreNone => 'No active subscription found.';

  @override
  String planPurchaseSuccess(String plan) {
    return 'You\'re now on the $plan plan.';
  }

  @override
  String get planPurchaseCancelled => 'Purchase cancelled.';

  @override
  String get planPurchaseError => 'Purchase failed. Please try again.';

  @override
  String get planCurrent => 'Current plan';

  @override
  String get planFreeLabel => 'Free';

  @override
  String get planPremiumLabel => 'Premium';

  @override
  String get calendarView => 'Calendar';

  @override
  String get listView => 'List';

  @override
  String get tutorialFirstTime => 'Welcome to AI Journal.';

  @override
  String get planFree => 'Free';

  @override
  String get planVoice => 'Voice';

  @override
  String get planVoicePhoto => 'Voice + Photo';

  @override
  String get planFull => 'Full';

  @override
  String get planPerMonth => '/month';

  @override
  String get planPerYear => '/year';

  @override
  String get planFreeTrial => 'First 10 entries on Full plan, free.';

  @override
  String get commonOk => 'OK';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonSave => 'Save';

  @override
  String get goalSteps => 'Walk 5,000 steps';

  @override
  String get goalNoMoney => 'No spending today';

  @override
  String get goalThanks => 'Say \'Thank you\'';

  @override
  String get goalSmile => 'Smile at someone';

  @override
  String get goalRead => 'Read 10 pages';

  @override
  String get goalSleep => 'Sleep before midnight';

  @override
  String get weatherSunny => 'Sunny';

  @override
  String get weatherCloudy => 'Cloudy';

  @override
  String get weatherRainy => 'Rainy';

  @override
  String get weatherSnowy => 'Snowy';

  @override
  String get voiceRecording => 'REC';

  @override
  String get voiceInitialising => 'Getting ready…';

  @override
  String get voiceRecordingHint => 'Speak freely — up to 2 minutes.';

  @override
  String get voiceTranscribing => 'Transcribing…';

  @override
  String get voiceTranscribingHint =>
      'Whisper is turning your voice into text.\nJust a moment.';

  @override
  String get voiceNoApiKeyTitle => 'OpenAI API key required';

  @override
  String get voiceNoApiKeyBody =>
      'Voice input uses Whisper for transcription.\nGo to Settings → AI API → OpenAI API key.\n(Get a free key at platform.openai.com)';

  @override
  String get settingsOpenAiApiKey => 'OpenAI API key (Whisper voice input)';

  @override
  String get settingsOpenAiApiKeyNotSet => 'Not set — voice input unavailable';

  @override
  String get settingsOpenAiApiKeyHelp =>
      'Used for Whisper transcription (\$0.006/min). Key stored on this device only. Get one at platform.openai.com.';

  @override
  String get settingsOpenAiApiKeyDialogTitle => 'OpenAI API key';

  @override
  String get settingsOpenAiApiKeyDialogHint => 'Paste your sk-... key here';

  @override
  String get settingsOpenAiApiKeyClear => 'Remove';

  @override
  String get historyVoicePlay => 'Play recording';

  @override
  String get historyVoicePlaying => 'Playing…';

  @override
  String get historyVoicePause => 'Pause';

  @override
  String get historyVoiceFileGone => 'Audio file not found';

  @override
  String get timeCapsuleNotifTitle => 'Your time capsule has arrived 📬';

  @override
  String timeCapsuleNotifBody(String title) {
    return 'A message from past you: $title';
  }

  @override
  String get weeklyRadioTitle => 'Weekly AI Radio';

  @override
  String get weeklyRadioSubtitle =>
      'Your week\'s voice diary, turned into a personal documentary.';

  @override
  String get weeklyRadioNoEntries => 'No recordings this week yet.';

  @override
  String get weeklyRadioPremiumArchive =>
      'Premium plan keeps every episode forever.';
}
