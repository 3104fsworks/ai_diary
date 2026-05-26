import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Journal'**
  String get appTitle;

  /// No description provided for @loginWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get loginWelcome;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A minimal AI diary for the quiet life.'**
  String get loginSubtitle;

  /// No description provided for @loginPrivacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your privacy, in your hands.'**
  String get loginPrivacyTitle;

  /// No description provided for @loginPrivacyBody.
  ///
  /// In en, this message translates to:
  /// **'We do not look into your everyday life.\n• Your diary, photos and location data are never stored on our servers.\n• Your data is never used to train AI models.\n• Everything stays on your device (or your own cloud).\n* Because of local storage, recovery on device loss must be done from your own backup (iCloud / Google Drive auto-sync).'**
  String get loginPrivacyBody;

  /// No description provided for @loginWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get loginWithGoogle;

  /// No description provided for @loginWithApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get loginWithApple;

  /// No description provided for @loginWithEmail.
  ///
  /// In en, this message translates to:
  /// **'Continue with Email'**
  String get loginWithEmail;

  /// No description provided for @loginWithEmailSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Email'**
  String get loginWithEmailSignIn;

  /// No description provided for @loginWithEmailSignUp.
  ///
  /// In en, this message translates to:
  /// **'Create account with Email'**
  String get loginWithEmailSignUp;

  /// No description provided for @loginSignInFailed.
  ///
  /// In en, this message translates to:
  /// **'Sign-in failed. Please try again.'**
  String get loginSignInFailed;

  /// No description provided for @loginCancelled.
  ///
  /// In en, this message translates to:
  /// **'Sign-in cancelled.'**
  String get loginCancelled;

  /// No description provided for @emailAuthSignInTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get emailAuthSignInTitle;

  /// No description provided for @emailAuthSignUpTitle.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get emailAuthSignUpTitle;

  /// No description provided for @emailAuthEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailAuthEmailLabel;

  /// No description provided for @emailAuthPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get emailAuthPasswordLabel;

  /// No description provided for @emailAuthPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'8 characters or more'**
  String get emailAuthPasswordHint;

  /// No description provided for @emailAuthSignInButton.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get emailAuthSignInButton;

  /// No description provided for @emailAuthSignUpButton.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get emailAuthSignUpButton;

  /// No description provided for @emailAuthToggleToSignUp.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Create one'**
  String get emailAuthToggleToSignUp;

  /// No description provided for @emailAuthToggleToSignIn.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get emailAuthToggleToSignIn;

  /// No description provided for @emailAuthForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot your password?'**
  String get emailAuthForgotPassword;

  /// No description provided for @emailAuthResetSent.
  ///
  /// In en, this message translates to:
  /// **'Password reset email sent.'**
  String get emailAuthResetSent;

  /// No description provided for @emailAuthResetEnterEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter your email first.'**
  String get emailAuthResetEnterEmail;

  /// No description provided for @authErrorInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'That email address looks invalid.'**
  String get authErrorInvalidEmail;

  /// No description provided for @authErrorWrongPassword.
  ///
  /// In en, this message translates to:
  /// **'Email or password is incorrect.'**
  String get authErrorWrongPassword;

  /// No description provided for @authErrorEmailInUse.
  ///
  /// In en, this message translates to:
  /// **'That email is already registered. Try signing in.'**
  String get authErrorEmailInUse;

  /// No description provided for @authErrorWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'Use a longer / stronger password.'**
  String get authErrorWeakPassword;

  /// No description provided for @authErrorUserNotFound.
  ///
  /// In en, this message translates to:
  /// **'No account found for that email.'**
  String get authErrorUserNotFound;

  /// No description provided for @authErrorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network error. Check your connection.'**
  String get authErrorNetwork;

  /// No description provided for @authErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get authErrorGeneric;

  /// No description provided for @inviteTitle.
  ///
  /// In en, this message translates to:
  /// **'Got an invite code?'**
  String get inviteTitle;

  /// No description provided for @inviteSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter it now and unlock the gift.'**
  String get inviteSubtitle;

  /// No description provided for @inviteHint.
  ///
  /// In en, this message translates to:
  /// **'AID-XXXX-XXXX-XXXX'**
  String get inviteHint;

  /// No description provided for @inviteRedeem.
  ///
  /// In en, this message translates to:
  /// **'Redeem'**
  String get inviteRedeem;

  /// No description provided for @inviteSkip.
  ///
  /// In en, this message translates to:
  /// **'I don\'t have one'**
  String get inviteSkip;

  /// No description provided for @inviteSuccessLifetime.
  ///
  /// In en, this message translates to:
  /// **'Code accepted. You have lifetime free access.'**
  String get inviteSuccessLifetime;

  /// No description provided for @inviteSuccessMonth.
  ///
  /// In en, this message translates to:
  /// **'Code accepted. You have 1 month of free access.'**
  String get inviteSuccessMonth;

  /// No description provided for @inviteAlreadyUsed.
  ///
  /// In en, this message translates to:
  /// **'You\'ve already redeemed this code.'**
  String get inviteAlreadyUsed;

  /// No description provided for @inviteInvalid.
  ///
  /// In en, this message translates to:
  /// **'This code isn\'t valid.'**
  String get inviteInvalid;

  /// No description provided for @inviteContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get inviteContinue;

  /// No description provided for @surveyTitle.
  ///
  /// In en, this message translates to:
  /// **'Just a few questions'**
  String get surveyTitle;

  /// No description provided for @surveySubtitle.
  ///
  /// In en, this message translates to:
  /// **'30 seconds. No typing needed.'**
  String get surveySubtitle;

  /// No description provided for @surveyNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get surveyNext;

  /// No description provided for @surveyBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get surveyBack;

  /// No description provided for @surveyFinish.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get surveyFinish;

  /// No description provided for @surveySkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get surveySkip;

  /// No description provided for @surveyQ1.
  ///
  /// In en, this message translates to:
  /// **'Where do you live?'**
  String get surveyQ1;

  /// No description provided for @surveyQ2.
  ///
  /// In en, this message translates to:
  /// **'Which phone do you use?'**
  String get surveyQ2;

  /// No description provided for @surveyQ3.
  ///
  /// In en, this message translates to:
  /// **'Do you use a smartwatch?'**
  String get surveyQ3;

  /// No description provided for @surveyQ4.
  ///
  /// In en, this message translates to:
  /// **'Which weather app do you use?'**
  String get surveyQ4;

  /// No description provided for @surveyQ5.
  ///
  /// In en, this message translates to:
  /// **'Which note app do you use?'**
  String get surveyQ5;

  /// No description provided for @surveyQ6.
  ///
  /// In en, this message translates to:
  /// **'Where did you write diaries before?'**
  String get surveyQ6;

  /// No description provided for @surveyQ7Gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get surveyQ7Gender;

  /// No description provided for @surveyQ7Age.
  ///
  /// In en, this message translates to:
  /// **'Age range'**
  String get surveyQ7Age;

  /// No description provided for @surveyQ8.
  ///
  /// In en, this message translates to:
  /// **'How did you find us?'**
  String get surveyQ8;

  /// No description provided for @surveyQ9Pain.
  ///
  /// In en, this message translates to:
  /// **'What\'s missing in your current diary app? (optional)'**
  String get surveyQ9Pain;

  /// No description provided for @surveyQ10Wish.
  ///
  /// In en, this message translates to:
  /// **'What do you want from this app? (optional)'**
  String get surveyQ10Wish;

  /// No description provided for @surveyOptional.
  ///
  /// In en, this message translates to:
  /// **'optional'**
  String get surveyOptional;

  /// No description provided for @surveyFreeTextHint.
  ///
  /// In en, this message translates to:
  /// **'Tap to write your thoughts...'**
  String get surveyFreeTextHint;

  /// No description provided for @surveyFinalTitle.
  ///
  /// In en, this message translates to:
  /// **'Anything you\'d like to share?'**
  String get surveyFinalTitle;

  /// No description provided for @surveyFinalHint.
  ///
  /// In en, this message translates to:
  /// **'Both are optional.'**
  String get surveyFinalHint;

  /// No description provided for @surveyPainLabel.
  ///
  /// In en, this message translates to:
  /// **'Things missing from past diary apps'**
  String get surveyPainLabel;

  /// No description provided for @surveyWishLabel.
  ///
  /// In en, this message translates to:
  /// **'What you\'d like from this app'**
  String get surveyWishLabel;

  /// No description provided for @tutorialTitle1.
  ///
  /// In en, this message translates to:
  /// **'Your day, ready when you open the app.'**
  String get tutorialTitle1;

  /// No description provided for @tutorialBody1.
  ///
  /// In en, this message translates to:
  /// **'Steps, schedule, weather and tasks are gathered for you in the background. You only add the moments that mattered.'**
  String get tutorialBody1;

  /// No description provided for @tutorialTitle2.
  ///
  /// In en, this message translates to:
  /// **'Speak. Snap. Tick.'**
  String get tutorialTitle2;

  /// No description provided for @tutorialBody2.
  ///
  /// In en, this message translates to:
  /// **'Just talk for a moment, add a photo, tick today\'s goals.'**
  String get tutorialBody2;

  /// No description provided for @tutorialTitle3.
  ///
  /// In en, this message translates to:
  /// **'Press Done. That\'s it.'**
  String get tutorialTitle3;

  /// No description provided for @tutorialBody3.
  ///
  /// In en, this message translates to:
  /// **'An AI diary that won\'t disappear, safely on your device.'**
  String get tutorialBody3;

  /// No description provided for @tutorialStart.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get tutorialStart;

  /// No description provided for @tutorialSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get tutorialSkip;

  /// No description provided for @homeViewPast.
  ///
  /// In en, this message translates to:
  /// **'Past diaries'**
  String get homeViewPast;

  /// No description provided for @homeWriteToday.
  ///
  /// In en, this message translates to:
  /// **'Write diary'**
  String get homeWriteToday;

  /// No description provided for @homeSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get homeSettings;

  /// No description provided for @homeHelp.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get homeHelp;

  /// No description provided for @appTitleLine.
  ///
  /// In en, this message translates to:
  /// **'AI Journal'**
  String get appTitleLine;

  /// No description provided for @diaryTodaysDiary.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get diaryTodaysDiary;

  /// No description provided for @diaryTalkWithAI.
  ///
  /// In en, this message translates to:
  /// **'Voice input'**
  String get diaryTalkWithAI;

  /// No description provided for @diaryVoiceShort.
  ///
  /// In en, this message translates to:
  /// **'Voice'**
  String get diaryVoiceShort;

  /// No description provided for @diaryVoiceTooltipTitle.
  ///
  /// In en, this message translates to:
  /// **'Talk to your day'**
  String get diaryVoiceTooltipTitle;

  /// No description provided for @diaryVoiceTooltipBody.
  ///
  /// In en, this message translates to:
  /// **'Tap to start speaking. We keep listening until you tap again — pause, look up, think.'**
  String get diaryVoiceTooltipBody;

  /// No description provided for @diaryVoiceListening.
  ///
  /// In en, this message translates to:
  /// **'Listening...'**
  String get diaryVoiceListening;

  /// No description provided for @diaryAddPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get diaryAddPhoto;

  /// No description provided for @diaryPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Anything on your mind...'**
  String get diaryPlaceholder;

  /// No description provided for @diaryDailyGoals.
  ///
  /// In en, this message translates to:
  /// **'Daily Goals'**
  String get diaryDailyGoals;

  /// No description provided for @diaryActivity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get diaryActivity;

  /// No description provided for @diaryActivitySteps.
  ///
  /// In en, this message translates to:
  /// **'Steps'**
  String get diaryActivitySteps;

  /// No description provided for @diaryActivitySleep.
  ///
  /// In en, this message translates to:
  /// **'Sleep'**
  String get diaryActivitySleep;

  /// No description provided for @diaryActivityHours.
  ///
  /// In en, this message translates to:
  /// **'{value} h'**
  String diaryActivityHours(String value);

  /// No description provided for @diaryActivityDash.
  ///
  /// In en, this message translates to:
  /// **'—'**
  String get diaryActivityDash;

  /// No description provided for @diarySchedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get diarySchedule;

  /// No description provided for @diaryDoneTasks.
  ///
  /// In en, this message translates to:
  /// **'Done Tasks'**
  String get diaryDoneTasks;

  /// No description provided for @diaryTimeline.
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get diaryTimeline;

  /// No description provided for @diaryJournal.
  ///
  /// In en, this message translates to:
  /// **'Journal'**
  String get diaryJournal;

  /// No description provided for @diaryPhotos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get diaryPhotos;

  /// No description provided for @diaryAIFeedback.
  ///
  /// In en, this message translates to:
  /// **'AI Feedback'**
  String get diaryAIFeedback;

  /// No description provided for @diaryDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get diaryDone;

  /// No description provided for @diaryShareSNS.
  ///
  /// In en, this message translates to:
  /// **'Save SNS image'**
  String get diaryShareSNS;

  /// No description provided for @diaryEmptySchedule.
  ///
  /// In en, this message translates to:
  /// **'No events on your calendar.'**
  String get diaryEmptySchedule;

  /// No description provided for @diarySaving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get diarySaving;

  /// No description provided for @diarySaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get diarySaved;

  /// No description provided for @historyTitle.
  ///
  /// In en, this message translates to:
  /// **'Past Diaries'**
  String get historyTitle;

  /// No description provided for @historyEmpty.
  ///
  /// In en, this message translates to:
  /// **'No diary yet.'**
  String get historyEmpty;

  /// No description provided for @historyEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Your first diary will live here.'**
  String get historyEmptyHint;

  /// No description provided for @historyEmptyCta.
  ///
  /// In en, this message translates to:
  /// **'Write today'**
  String get historyEmptyCta;

  /// No description provided for @historyDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get historyDelete;

  /// No description provided for @historyDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this diary?'**
  String get historyDeleteConfirm;

  /// No description provided for @historyDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'This removes the entry and its .md file from your device. This cannot be undone.'**
  String get historyDeleteBody;

  /// No description provided for @historyDeleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get historyDeleted;

  /// No description provided for @historySearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search diaries...'**
  String get historySearchHint;

  /// No description provided for @commonError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong.'**
  String get commonError;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get commonRetry;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings & Help'**
  String get settingsTitle;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @settingsThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsThemeSystem;

  /// No description provided for @settingsAccent.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get settingsAccent;

  /// No description provided for @settingsFontScale.
  ///
  /// In en, this message translates to:
  /// **'Text size'**
  String get settingsFontScale;

  /// No description provided for @fontScaleSmall.
  ///
  /// In en, this message translates to:
  /// **'Small'**
  String get fontScaleSmall;

  /// No description provided for @fontScaleMedium.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get fontScaleMedium;

  /// No description provided for @fontScaleLarge.
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get fontScaleLarge;

  /// No description provided for @fontScaleExtraLarge.
  ///
  /// In en, this message translates to:
  /// **'Extra large'**
  String get fontScaleExtraLarge;

  /// No description provided for @settingsIntegrations.
  ///
  /// In en, this message translates to:
  /// **'Integrations'**
  String get settingsIntegrations;

  /// No description provided for @settingsHealth.
  ///
  /// In en, this message translates to:
  /// **'Health (Apple Health / Health Connect)'**
  String get settingsHealth;

  /// No description provided for @settingsHealthUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Health Connect is not available on this device.'**
  String get settingsHealthUnavailable;

  /// No description provided for @settingsHealthDenied.
  ///
  /// In en, this message translates to:
  /// **'Health permission was not granted. Enable it in Health Connect / Apple Health.'**
  String get settingsHealthDenied;

  /// No description provided for @settingsLocationDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission was not granted. Enable it in OS Settings.'**
  String get settingsLocationDenied;

  /// No description provided for @settingsCalendarDenied.
  ///
  /// In en, this message translates to:
  /// **'Calendar access was not granted. Sign in with Google and grant calendar permission.'**
  String get settingsCalendarDenied;

  /// No description provided for @settingsTasksDenied.
  ///
  /// In en, this message translates to:
  /// **'Google Tasks access was not granted. Sign in with Google and grant tasks permission.'**
  String get settingsTasksDenied;

  /// No description provided for @settingsCalendar.
  ///
  /// In en, this message translates to:
  /// **'Google Calendar'**
  String get settingsCalendar;

  /// No description provided for @settingsTodo.
  ///
  /// In en, this message translates to:
  /// **'Google Tasks'**
  String get settingsTodo;

  /// No description provided for @settingsLocation.
  ///
  /// In en, this message translates to:
  /// **'Location timeline'**
  String get settingsLocation;

  /// No description provided for @settingsPlan.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get settingsPlan;

  /// No description provided for @settingsUpgrade.
  ///
  /// In en, this message translates to:
  /// **'Upgrade'**
  String get settingsUpgrade;

  /// No description provided for @settingsAutoSync.
  ///
  /// In en, this message translates to:
  /// **'Auto Sync (iCloud / Google Drive)'**
  String get settingsAutoSync;

  /// No description provided for @settingsDiaryFolder.
  ///
  /// In en, this message translates to:
  /// **'Diary folder (for Obsidian)'**
  String get settingsDiaryFolder;

  /// No description provided for @settingsDiaryFolderHint.
  ///
  /// In en, this message translates to:
  /// **'Point your Obsidian Vault here. Each diary is a .md file that\'s overwritten in place when you edit it — no duplicates.'**
  String get settingsDiaryFolderHint;

  /// No description provided for @settingsDiaryFolderCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy path'**
  String get settingsDiaryFolderCopy;

  /// No description provided for @settingsDiaryFolderCopied.
  ///
  /// In en, this message translates to:
  /// **'Path copied'**
  String get settingsDiaryFolderCopied;

  /// No description provided for @settingsBulkMarkdown.
  ///
  /// In en, this message translates to:
  /// **'Export all as Markdown (.zip)'**
  String get settingsBulkMarkdown;

  /// No description provided for @settingsBulkMarkdownHint.
  ///
  /// In en, this message translates to:
  /// **'One .md file per day. Drop into Obsidian or Notion.'**
  String get settingsBulkMarkdownHint;

  /// No description provided for @settingsBulkMarkdownNone.
  ///
  /// In en, this message translates to:
  /// **'No diaries to export yet.'**
  String get settingsBulkMarkdownNone;

  /// No description provided for @settingsBulkMarkdownDone.
  ///
  /// In en, this message translates to:
  /// **'{count} diaries packaged.'**
  String settingsBulkMarkdownDone(int count);

  /// No description provided for @settingsDataMigration.
  ///
  /// In en, this message translates to:
  /// **'Export / Import (ZIP)'**
  String get settingsDataMigration;

  /// No description provided for @settingsReferral.
  ///
  /// In en, this message translates to:
  /// **'Referral code'**
  String get settingsReferral;

  /// No description provided for @settingsReferralBody.
  ///
  /// In en, this message translates to:
  /// **'Invite a friend — both of you get 1 month free.'**
  String get settingsReferralBody;

  /// No description provided for @settingsFaq.
  ///
  /// In en, this message translates to:
  /// **'FAQ / Help'**
  String get settingsFaq;

  /// No description provided for @settingsHowTo.
  ///
  /// In en, this message translates to:
  /// **'How to use'**
  String get settingsHowTo;

  /// No description provided for @settingsGoals.
  ///
  /// In en, this message translates to:
  /// **'Daily goals'**
  String get settingsGoals;

  /// No description provided for @goalsTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit daily goals'**
  String get goalsTitle;

  /// No description provided for @goalsHint.
  ///
  /// In en, this message translates to:
  /// **'These appear on each day\'s diary as a checklist.'**
  String get goalsHint;

  /// No description provided for @goalsAdd.
  ///
  /// In en, this message translates to:
  /// **'Add goal'**
  String get goalsAdd;

  /// No description provided for @goalsLimitFree.
  ///
  /// In en, this message translates to:
  /// **'Free plan: up to 3 goals'**
  String get goalsLimitFree;

  /// No description provided for @goalsLimitPremium.
  ///
  /// In en, this message translates to:
  /// **'Premium: up to 6 goals'**
  String get goalsLimitPremium;

  /// No description provided for @goalsNamePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'e.g. Walk 5,000 steps'**
  String get goalsNamePlaceholder;

  /// No description provided for @goalsDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get goalsDelete;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @settingsPrivacyFooter.
  ///
  /// In en, this message translates to:
  /// **'We never see your data. Diaries and photos stay on your device or your own cloud only.'**
  String get settingsPrivacyFooter;

  /// No description provided for @settingsPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get settingsPrivacyPolicy;

  /// No description provided for @settingsTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms of service'**
  String get settingsTerms;

  /// No description provided for @settingsAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsAccount;

  /// No description provided for @settingsAccountSignedInAs.
  ///
  /// In en, this message translates to:
  /// **'Signed in as'**
  String get settingsAccountSignedInAs;

  /// No description provided for @settingsAccountDemo.
  ///
  /// In en, this message translates to:
  /// **'Demo account (no email)'**
  String get settingsAccountDemo;

  /// No description provided for @settingsSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get settingsSignOut;

  /// No description provided for @settingsSignOutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Sign out of this device?'**
  String get settingsSignOutConfirm;

  /// No description provided for @settingsSignOutBody.
  ///
  /// In en, this message translates to:
  /// **'Your diaries stay on the device. You\'ll need to sign in again to add new entries.'**
  String get settingsSignOutBody;

  /// No description provided for @settingsAiPersonality.
  ///
  /// In en, this message translates to:
  /// **'AI personality'**
  String get settingsAiPersonality;

  /// No description provided for @personalityStandard.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get personalityStandard;

  /// No description provided for @personalityStandardDesc.
  ///
  /// In en, this message translates to:
  /// **'Polite, clear, intellectual.'**
  String get personalityStandardDesc;

  /// No description provided for @personalityMirroring.
  ///
  /// In en, this message translates to:
  /// **'Mirror my voice'**
  String get personalityMirroring;

  /// No description provided for @personalityMirroringDesc.
  ///
  /// In en, this message translates to:
  /// **'Matches your tone, endings and vocabulary.'**
  String get personalityMirroringDesc;

  /// No description provided for @personalityFriendly.
  ///
  /// In en, this message translates to:
  /// **'Warm & kind'**
  String get personalityFriendly;

  /// No description provided for @personalityFriendlyDesc.
  ///
  /// In en, this message translates to:
  /// **'A close-friend tone that gently cheers you on.'**
  String get personalityFriendlyDesc;

  /// No description provided for @exportMarkdown.
  ///
  /// In en, this message translates to:
  /// **'Export as Markdown'**
  String get exportMarkdown;

  /// No description provided for @exportShared.
  ///
  /// In en, this message translates to:
  /// **'Shared'**
  String get exportShared;

  /// No description provided for @diaryRawVoice.
  ///
  /// In en, this message translates to:
  /// **'Today\'s whisper'**
  String get diaryRawVoice;

  /// No description provided for @diaryRawVoiceHint.
  ///
  /// In en, this message translates to:
  /// **'Your own words, kept as you spoke them.'**
  String get diaryRawVoiceHint;

  /// No description provided for @diaryRawVoiceShow.
  ///
  /// In en, this message translates to:
  /// **'Show what I actually said'**
  String get diaryRawVoiceShow;

  /// No description provided for @diaryRawVoiceHide.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get diaryRawVoiceHide;

  /// No description provided for @diaryJournalEditHint.
  ///
  /// In en, this message translates to:
  /// **'Tap to refine.'**
  String get diaryJournalEditHint;

  /// No description provided for @diaryJournalSavedEdit.
  ///
  /// In en, this message translates to:
  /// **'Edited'**
  String get diaryJournalSavedEdit;

  /// No description provided for @diaryAiFallback.
  ///
  /// In en, this message translates to:
  /// **'Saved. AI was unreachable — used the offline draft.'**
  String get diaryAiFallback;

  /// No description provided for @settingsAiApiTitle.
  ///
  /// In en, this message translates to:
  /// **'AI API'**
  String get settingsAiApiTitle;

  /// No description provided for @settingsAiApiKey.
  ///
  /// In en, this message translates to:
  /// **'Gemini API key'**
  String get settingsAiApiKey;

  /// No description provided for @settingsAiApiKeyNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set — offline drafts will be used'**
  String get settingsAiApiKeyNotSet;

  /// No description provided for @settingsAiApiKeyDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Gemini API key'**
  String get settingsAiApiKeyDialogTitle;

  /// No description provided for @settingsAiApiKeyDialogHint.
  ///
  /// In en, this message translates to:
  /// **'Paste your key here'**
  String get settingsAiApiKeyDialogHint;

  /// No description provided for @settingsAiApiKeyClear.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get settingsAiApiKeyClear;

  /// No description provided for @settingsAiApiKeyHelp.
  ///
  /// In en, this message translates to:
  /// **'Get a free key from Google AI Studio. We store it only on this device.'**
  String get settingsAiApiKeyHelp;

  /// No description provided for @quotaTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s diary is already written.'**
  String get quotaTitle;

  /// No description provided for @quotaBody.
  ///
  /// In en, this message translates to:
  /// **'Free plan allows one AI diary per day. Upgrade to Premium for unlimited diaries and personality choice — or bring your own API key.'**
  String get quotaBody;

  /// No description provided for @quotaLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get quotaLater;

  /// No description provided for @quotaUpgrade.
  ///
  /// In en, this message translates to:
  /// **'See plans'**
  String get quotaUpgrade;

  /// No description provided for @lockedPremium.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get lockedPremium;

  /// No description provided for @lockedPersonality.
  ///
  /// In en, this message translates to:
  /// **'Personality is fixed to Standard on the free plan.'**
  String get lockedPersonality;

  /// No description provided for @lockedByok.
  ///
  /// In en, this message translates to:
  /// **'Bring-your-own API key is available on Premium.'**
  String get lockedByok;

  /// No description provided for @planTestEnable.
  ///
  /// In en, this message translates to:
  /// **'[Test] Enable Premium'**
  String get planTestEnable;

  /// No description provided for @planTestDisable.
  ///
  /// In en, this message translates to:
  /// **'[Test] Disable Premium'**
  String get planTestDisable;

  /// No description provided for @planSubscribe.
  ///
  /// In en, this message translates to:
  /// **'Subscribe'**
  String get planSubscribe;

  /// No description provided for @planRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore purchases'**
  String get planRestore;

  /// No description provided for @planPurchaseSuccess.
  ///
  /// In en, this message translates to:
  /// **'You\'re now on the {plan} plan.'**
  String planPurchaseSuccess(String plan);

  /// No description provided for @planPurchaseCancelled.
  ///
  /// In en, this message translates to:
  /// **'Purchase cancelled.'**
  String get planPurchaseCancelled;

  /// No description provided for @planPurchaseError.
  ///
  /// In en, this message translates to:
  /// **'Purchase failed. Please try again.'**
  String get planPurchaseError;

  /// No description provided for @planCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current plan'**
  String get planCurrent;

  /// No description provided for @planFreeLabel.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get planFreeLabel;

  /// No description provided for @planPremiumLabel.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get planPremiumLabel;

  /// No description provided for @calendarView.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendarView;

  /// No description provided for @listView.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get listView;

  /// No description provided for @tutorialFirstTime.
  ///
  /// In en, this message translates to:
  /// **'Welcome to AI Journal.'**
  String get tutorialFirstTime;

  /// No description provided for @planFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get planFree;

  /// No description provided for @planVoice.
  ///
  /// In en, this message translates to:
  /// **'Voice'**
  String get planVoice;

  /// No description provided for @planVoicePhoto.
  ///
  /// In en, this message translates to:
  /// **'Voice + Photo'**
  String get planVoicePhoto;

  /// No description provided for @planFull.
  ///
  /// In en, this message translates to:
  /// **'Full'**
  String get planFull;

  /// No description provided for @planPerMonth.
  ///
  /// In en, this message translates to:
  /// **'/month'**
  String get planPerMonth;

  /// No description provided for @planPerYear.
  ///
  /// In en, this message translates to:
  /// **'/year'**
  String get planPerYear;

  /// No description provided for @planFreeTrial.
  ///
  /// In en, this message translates to:
  /// **'First 10 entries on Full plan, free.'**
  String get planFreeTrial;

  /// No description provided for @commonOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @goalSteps.
  ///
  /// In en, this message translates to:
  /// **'Walk 5,000 steps'**
  String get goalSteps;

  /// No description provided for @goalNoMoney.
  ///
  /// In en, this message translates to:
  /// **'No spending today'**
  String get goalNoMoney;

  /// No description provided for @goalThanks.
  ///
  /// In en, this message translates to:
  /// **'Say \'Thank you\''**
  String get goalThanks;

  /// No description provided for @goalSmile.
  ///
  /// In en, this message translates to:
  /// **'Smile at someone'**
  String get goalSmile;

  /// No description provided for @goalRead.
  ///
  /// In en, this message translates to:
  /// **'Read 10 pages'**
  String get goalRead;

  /// No description provided for @goalSleep.
  ///
  /// In en, this message translates to:
  /// **'Sleep before midnight'**
  String get goalSleep;

  /// No description provided for @weatherSunny.
  ///
  /// In en, this message translates to:
  /// **'Sunny'**
  String get weatherSunny;

  /// No description provided for @weatherCloudy.
  ///
  /// In en, this message translates to:
  /// **'Cloudy'**
  String get weatherCloudy;

  /// No description provided for @weatherRainy.
  ///
  /// In en, this message translates to:
  /// **'Rainy'**
  String get weatherRainy;

  /// No description provided for @weatherSnowy.
  ///
  /// In en, this message translates to:
  /// **'Snowy'**
  String get weatherSnowy;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
