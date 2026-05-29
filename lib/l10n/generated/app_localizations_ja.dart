// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'AIジャーナル';

  @override
  String get loginWelcome => 'ようこそ';

  @override
  String get loginSubtitle => '静かな毎日のための、ミニマルAIジャーナル。';

  @override
  String get loginPrivacyTitle => 'あなたのデータは、あなたのものです。';

  @override
  String get loginPrivacyBody =>
      '私たちは、あなたの大切な日常を覗き見しません。\n・日記や写真、位置情報のデータは運営サーバーに一切保存されません。\n・AIモデルの学習にあなたのデータが利用されることはありません。\n・データは完全にあなた個人のデバイス内（またはご自身のクラウド）にのみ安全に保管されます。\n※ローカル保存の特性上、端末紛失時のデータ復旧はご自身のバックアップ（iCloud / Google Drive自動同期）から行う必要があります。';

  @override
  String get loginWithGoogle => 'Googleで続ける';

  @override
  String get loginWithApple => 'Appleで続ける';

  @override
  String get loginWithEmail => 'メールアドレスで続ける';

  @override
  String get loginWithEmailSignIn => 'メールアドレスでログイン';

  @override
  String get loginWithEmailSignUp => 'メールアドレスで新規登録';

  @override
  String get loginSignInFailed => 'サインインに失敗しました。もう一度お試しください。';

  @override
  String get loginCancelled => 'サインインをキャンセルしました。';

  @override
  String get emailAuthSignInTitle => 'ログイン';

  @override
  String get emailAuthSignUpTitle => 'アカウントを作成';

  @override
  String get emailAuthEmailLabel => 'メールアドレス';

  @override
  String get emailAuthPasswordLabel => 'パスワード';

  @override
  String get emailAuthPasswordHint => '8文字以上';

  @override
  String get emailAuthSignInButton => 'ログイン';

  @override
  String get emailAuthSignUpButton => '登録する';

  @override
  String get emailAuthToggleToSignUp => 'アカウントをお持ちでない方はこちら';

  @override
  String get emailAuthToggleToSignIn => 'すでにアカウントをお持ちの方はこちら';

  @override
  String get emailAuthForgotPassword => 'パスワードを忘れた方はこちら';

  @override
  String get emailAuthResetSent => 'パスワード再設定メールを送信しました。';

  @override
  String get emailAuthResetEnterEmail => '先にメールアドレスを入力してください。';

  @override
  String get authErrorInvalidEmail => 'メールアドレスの形式が正しくないようです。';

  @override
  String get authErrorWrongPassword => 'メールアドレスかパスワードが正しくありません。';

  @override
  String get authErrorEmailInUse => 'このメールアドレスは既に登録されています。ログインをお試しください。';

  @override
  String get authErrorWeakPassword => 'パスワードが弱すぎます。もう少し長くしてください。';

  @override
  String get authErrorUserNotFound => 'このメールアドレスのアカウントが見つかりません。';

  @override
  String get authErrorNetwork => 'ネットワークエラーです。通信状況をご確認ください。';

  @override
  String get authErrorGeneric => '問題が発生しました。もう一度お試しください。';

  @override
  String get inviteTitle => '招待コードはお持ちですか？';

  @override
  String get inviteSubtitle => 'ご入力で特典が解放されます。';

  @override
  String get inviteHint => 'AID-XXXX-XXXX-XXXX';

  @override
  String get inviteRedeem => 'コードを使う';

  @override
  String get inviteSkip => '持っていません';

  @override
  String get inviteSuccessLifetime => 'コードが認証されました。永久無料でご利用いただけます。';

  @override
  String get inviteSuccessMonth => 'コードが認証されました。1ヶ月間無料でご利用いただけます。';

  @override
  String get inviteAlreadyUsed => 'このコードはすでにお使いいただいています。';

  @override
  String get inviteInvalid => 'このコードは無効です。';

  @override
  String get inviteContinue => '次へ';

  @override
  String get surveyTitle => 'いくつか教えてください';

  @override
  String get surveySubtitle => '30秒で終わります。タイピング不要。';

  @override
  String get surveyNext => '次へ';

  @override
  String get surveyBack => '戻る';

  @override
  String get surveyFinish => '完了';

  @override
  String get surveySkip => 'スキップ';

  @override
  String get surveyQ1 => 'お住まいの地域';

  @override
  String get surveyQ2 => 'お使いのスマホ';

  @override
  String get surveyQ3 => 'スマートウォッチの使用';

  @override
  String get surveyQ4 => '普段使っている天気アプリ';

  @override
  String get surveyQ5 => '普段お使いのノートアプリ';

  @override
  String get surveyQ6 => '今まで日記は何に書いていましたか？';

  @override
  String get surveyQ7Gender => 'ご性別';

  @override
  String get surveyQ7Age => 'ご年代';

  @override
  String get surveyQ8 => 'このアプリをどこで知りましたか？';

  @override
  String get surveyQ9Pain => '今まで使っていた日記アプリで不満に感じていたこと（任意）';

  @override
  String get surveyQ10Wish => 'このアプリに求めること（任意）';

  @override
  String get surveyOptional => '任意';

  @override
  String get surveyFreeTextHint => 'ご自由にお書きください…';

  @override
  String get surveyFinalTitle => '最後に、もしよければ教えてください';

  @override
  String get surveyFinalHint => 'どちらも任意です。';

  @override
  String get surveyPainLabel => '今までの日記アプリで足りなかったこと';

  @override
  String get surveyWishLabel => 'このアプリに期待すること';

  @override
  String get tutorialTitle1 => '今日のあなたが、自然に整います。';

  @override
  String get tutorialBody1 =>
      '歩数・予定・天気・タスクは、裏側で静かに集まります。あなたは、その日心に残った瞬間だけを足してください。';

  @override
  String get tutorialTitle2 => '話す、撮る、チェックするだけ。';

  @override
  String get tutorialBody2 => '声で一言、写真を一枚、今日の目標をチェック。';

  @override
  String get tutorialTitle3 => '完了ボタンを押すだけ。';

  @override
  String get tutorialBody3 => '消えない安心な日記が、あなたの端末に静かに保存されます。';

  @override
  String get tutorialStart => 'はじめる';

  @override
  String get tutorialSkip => 'スキップ';

  @override
  String get homeWeeklyRadio => '今週のAIラジオ';

  @override
  String get homeViewPast => '過去の日記';

  @override
  String get homeWriteToday => '日記を書く';

  @override
  String get homeSettings => '設定';

  @override
  String get homeHelp => 'ヘルプ';

  @override
  String get appTitleLine => 'AI Journal';

  @override
  String get diaryTodaysDiary => '今日';

  @override
  String get diaryTalkWithAI => '音声入力';

  @override
  String get diaryVoiceShort => '音声';

  @override
  String get diaryVoiceTooltipTitle => '今日のことを話してみる';

  @override
  String get diaryVoiceTooltipBody =>
      'タップで開始。もう一度押すまで聞き続けるので、思い出しながら、ゆっくり話してください。';

  @override
  String get diaryVoiceListening => '聞いています…';

  @override
  String get diaryAddPhoto => '写真を追加';

  @override
  String get diaryPlaceholder => '今日、なにかありましたか…';

  @override
  String get diaryDailyGoals => '今日の目標';

  @override
  String get diaryActivity => 'アクティビティ';

  @override
  String get diaryActivitySteps => '歩数';

  @override
  String get diaryActivitySleep => '睡眠';

  @override
  String diaryActivityHours(String value) {
    return '$value 時間';
  }

  @override
  String get diaryActivityDash => '—';

  @override
  String get diarySchedule => '予定';

  @override
  String get diaryDoneTasks => '完了したタスク';

  @override
  String get diaryTimeline => 'タイムライン';

  @override
  String get diaryJournal => '日記';

  @override
  String get diaryPhotos => '写真';

  @override
  String get diaryAIFeedback => 'AIからひと言';

  @override
  String get diaryDone => '完了';

  @override
  String get diaryShareSNS => 'SNS用の画像を保存';

  @override
  String get diaryEmptySchedule => 'カレンダー未記入';

  @override
  String get diarySaving => '保存中…';

  @override
  String get diarySaved => '保存しました';

  @override
  String get historyTitle => '過去の日記';

  @override
  String get historyEmpty => 'まだ日記はありません。';

  @override
  String get historyEmptyHint => 'あなたの最初の日記が、ここに静かに残ります。';

  @override
  String get historyEmptyCta => '今日の日記を書く';

  @override
  String get historyDelete => '削除';

  @override
  String get historyDeleteConfirm => 'この日記を削除しますか？';

  @override
  String get historyDeleteBody => '日記本文と .md ファイルが端末から完全に削除されます。この操作は取り消せません。';

  @override
  String get historyDeleted => '削除しました';

  @override
  String get historySearchHint => '日記を検索…';

  @override
  String get commonError => 'うまく読み込めませんでした。';

  @override
  String get commonRetry => 'もう一度';

  @override
  String get settingsTitle => '設定 ＆ ヘルプ';

  @override
  String get settingsAppearance => '見た目';

  @override
  String get settingsTheme => 'テーマ';

  @override
  String get settingsThemeLight => 'ライト';

  @override
  String get settingsThemeDark => 'ダーク';

  @override
  String get settingsThemeSystem => '端末に合わせる';

  @override
  String get settingsAccent => 'カラー';

  @override
  String get settingsFontScale => '文字サイズ';

  @override
  String get fontScaleSmall => '小';

  @override
  String get fontScaleMedium => '標準';

  @override
  String get fontScaleLarge => '大';

  @override
  String get fontScaleExtraLarge => '特大';

  @override
  String get settingsIntegrations => '外部連携';

  @override
  String get settingsHealth => 'ヘルスケア (Apple Health / Health Connect)';

  @override
  String get settingsHealthUnavailable => 'この端末ではヘルスケア連携を利用できません。';

  @override
  String get settingsHealthDenied =>
      'ヘルスケアの権限が付与されませんでした。Health Connect / ヘルスケア App で有効にしてください。';

  @override
  String get settingsLocationDenied => '位置情報の権限が付与されませんでした。OSの設定から有効にしてください。';

  @override
  String get settingsCalendarDenied =>
      'カレンダーへのアクセスが許可されませんでした。Googleでサインインしてカレンダーの権限を付与してください。';

  @override
  String get settingsTasksDenied =>
      'Google Tasks へのアクセスが許可されませんでした。Googleでサインインしてタスクの権限を付与してください。';

  @override
  String get settingsCalendar => 'Google カレンダー';

  @override
  String get settingsTodo => 'Google ToDo';

  @override
  String get settingsLocation => '位置情報タイムライン';

  @override
  String get settingsPlan => 'プラン';

  @override
  String get settingsUpgrade => 'アップグレード';

  @override
  String get settingsAutoSync => '自動クラウド同期 (iCloud / Google Drive)';

  @override
  String get settingsDiaryFolder => '日記フォルダ（Obsidian連携）';

  @override
  String get settingsDiaryFolderHint =>
      'ObsidianのVaultをこのフォルダに設定すると、日記が .md として自動同期されます。編集時は同じファイルが上書きされ、重複は発生しません。';

  @override
  String get settingsDiaryFolderCopy => 'パスをコピー';

  @override
  String get settingsDiaryFolderCopied => 'パスをコピーしました';

  @override
  String get settingsBulkMarkdown => 'Markdown一括書き出し (.zip)';

  @override
  String get settingsBulkMarkdownHint =>
      '1日1ファイルの .md にしてまとめます。Obsidian や Notion にそのまま取り込めます。';

  @override
  String get settingsBulkMarkdownNone => '書き出せる日記がまだありません。';

  @override
  String settingsBulkMarkdownDone(int count) {
    return '$count件の日記を書き出しました。';
  }

  @override
  String get settingsDataMigration => 'データ引越し (ZIP書き出し / 復元)';

  @override
  String get settingsReferral => '紹介コード';

  @override
  String get settingsReferralBody => '友人を招待すると、紹介した側・された側の両方が1ヶ月無料。';

  @override
  String get settingsFaq => 'よくある質問 / ヘルプ';

  @override
  String get settingsHowTo => '使い方';

  @override
  String get settingsGoals => '毎日の目標';

  @override
  String get goalsTitle => '毎日の目標を編集';

  @override
  String get goalsHint => 'ここで作った目標は、毎日の日記にチェックリストとして表示されます。';

  @override
  String get goalsAdd => '目標を追加';

  @override
  String get goalsLimitFree => '無料プラン: 最大3個まで';

  @override
  String get goalsLimitPremium => 'Premium: 最大6個まで';

  @override
  String get goalsNamePlaceholder => '例: 5,000歩あるく';

  @override
  String get goalsDelete => '削除';

  @override
  String get language => '言語';

  @override
  String get settingsPrivacyFooter =>
      'あなたのデータは私たちには見えません。日記と写真はあなたのデバイス、またはあなた自身のクラウドにのみ保管されます。';

  @override
  String get settingsPrivacyPolicy => 'プライバシーポリシー';

  @override
  String get settingsTerms => '利用規約';

  @override
  String get settingsAccount => 'アカウント';

  @override
  String get settingsAccountSignedInAs => 'サインイン中';

  @override
  String get settingsAccountDemo => 'デモアカウント（メールなし）';

  @override
  String get settingsSignOut => 'サインアウト';

  @override
  String get settingsSignOutConfirm => 'この端末からサインアウトしますか？';

  @override
  String get settingsSignOutBody =>
      '日記データは端末に残ります。新しい日記を書くには、もう一度サインインが必要になります。';

  @override
  String get settingsAiPersonality => 'AIの口調';

  @override
  String get personalityStandard => 'デフォルト';

  @override
  String get personalityStandardDesc => '丁寧で知的な、すっきりとした口調。';

  @override
  String get personalityMirroring => '自分と同じ口調';

  @override
  String get personalityMirroringDesc => 'あなたの語尾や言葉遣いをAIがそのまま反映します。';

  @override
  String get personalityFriendly => '優しく・かわいく';

  @override
  String get personalityFriendlyDesc => '親友のように、その日のあなたを全肯定して労います。';

  @override
  String get exportMarkdown => 'Markdownでエクスポート';

  @override
  String get exportShared => '共有しました';

  @override
  String get diaryRawVoice => '今日のつぶやき';

  @override
  String get diaryRawVoiceHint => 'あなたが話した、そのままの言葉。';

  @override
  String get diaryRawVoiceShow => 'あなたが話したそのままの言葉を表示';

  @override
  String get diaryRawVoiceHide => '閉じる';

  @override
  String get diaryJournalEditHint => 'タップして手直しできます。';

  @override
  String get diaryJournalSavedEdit => '編集しました';

  @override
  String get diaryAiFallback => '保存しました。AIに接続できなかったため、下書きを使用しました。';

  @override
  String get settingsAiApiTitle => 'AI APIの設定';

  @override
  String get settingsAiApiKey => 'Gemini APIキー';

  @override
  String get settingsAiApiKeyNotSet => '未設定 — オフライン下書きで動作します';

  @override
  String get settingsAiApiKeyDialogTitle => 'Gemini APIキー';

  @override
  String get settingsAiApiKeyDialogHint => 'ここにキーを貼り付け';

  @override
  String get settingsAiApiKeyClear => '削除';

  @override
  String get settingsAiApiKeyHelp =>
      'Google AI Studio で無料発行できます。キーはこの端末にのみ保存されます。';

  @override
  String get quotaTitle => '今日の日記は、もう書き終わりました。';

  @override
  String get quotaBody =>
      '無料プランは1日に1回までAIに頼めます。プレミアムにアップグレードすると、回数無制限・口調の選択ができます。または、独自のAPIキーをお持ち込みください。';

  @override
  String get quotaLater => 'また明日';

  @override
  String get quotaUpgrade => 'プランを見る';

  @override
  String get lockedPremium => 'Premium限定';

  @override
  String get lockedPersonality => '無料プランではAIの口調は「デフォルト」固定です。';

  @override
  String get lockedByok => '独自APIキーの利用はPremiumプランで解放されます。';

  @override
  String get planTestEnable => '[テスト] Premiumを有効化';

  @override
  String get planTestDisable => '[テスト] Premiumを解除';

  @override
  String get planSubscribe => 'このプランで登録';

  @override
  String get planRestore => '購入を復元';

  @override
  String get planRestoreSuccess => '購入を復元しました。';

  @override
  String get planRestoreNone => '有効なサブスクリプションが見つかりませんでした。';

  @override
  String planPurchaseSuccess(String plan) {
    return '$planに登録しました。';
  }

  @override
  String get planPurchaseCancelled => '購入をキャンセルしました。';

  @override
  String get planPurchaseError => '購入に失敗しました。もう一度お試しください。';

  @override
  String get planCurrent => '現在のプラン';

  @override
  String get planFreeLabel => '無料プラン';

  @override
  String get planPremiumLabel => 'Premiumプラン';

  @override
  String get calendarView => 'カレンダー';

  @override
  String get listView => 'リスト';

  @override
  String get tutorialFirstTime => 'AIジャーナルへようこそ。';

  @override
  String get planFree => '無料プラン';

  @override
  String get planVoice => '音声入力プラン';

  @override
  String get planVoicePhoto => '音声＋写真プラン';

  @override
  String get planFull => 'フル機能プラン';

  @override
  String get planPerMonth => '／月';

  @override
  String get planPerYear => '／年';

  @override
  String get planFreeTrial => '最初の10回はフル機能を無料体験。';

  @override
  String get commonOk => 'OK';

  @override
  String get commonCancel => 'キャンセル';

  @override
  String get commonSave => '保存';

  @override
  String get goalSteps => '5,000歩あるく';

  @override
  String get goalNoMoney => '今日はお金を使わない';

  @override
  String get goalThanks => '「ありがとう」を言う';

  @override
  String get goalSmile => '誰かに微笑む';

  @override
  String get goalRead => '本を10ページ読む';

  @override
  String get goalSleep => '0時前に眠る';

  @override
  String get weatherSunny => '晴れ';

  @override
  String get weatherCloudy => 'くもり';

  @override
  String get weatherRainy => '雨';

  @override
  String get weatherSnowy => '雪';

  @override
  String get voiceRecording => '録音中';

  @override
  String get voiceInitialising => '準備中…';

  @override
  String get voiceRecordingHint => '思いのまま、話してください。\n最大2分間録音できます。';

  @override
  String get voiceTranscribing => '文字起こし中…';

  @override
  String get voiceTranscribingHint => 'Whisperがあなたの声を文字に変換しています。\nそのままお待ちください。';

  @override
  String get voiceNoApiKeyTitle => 'OpenAI APIキーが必要です';

  @override
  String get voiceNoApiKeyBody =>
      '音声入力にはWhisperを使用します。\n設定 → AI API → OpenAI APIキー から入力してください。\n（OpenAI Platformでキーを無料で発行できます）';

  @override
  String get settingsOpenAiApiKey => 'OpenAI APIキー（Whisper音声認識）';

  @override
  String get settingsOpenAiApiKeyNotSet => '未設定 — 音声入力は利用できません';

  @override
  String get settingsOpenAiApiKeyHelp =>
      'Whisper音声認識に使用します（\$0.006/分）。キーはこの端末にのみ保存されます。platform.openai.com で発行できます。';

  @override
  String get settingsOpenAiApiKeyDialogTitle => 'OpenAI APIキー';

  @override
  String get settingsOpenAiApiKeyDialogHint => 'sk-... を貼り付け';

  @override
  String get settingsOpenAiApiKeyClear => '削除';

  @override
  String get historyVoicePlay => '録音を再生';

  @override
  String get historyVoicePlaying => '再生中…';

  @override
  String get historyVoicePause => '一時停止';

  @override
  String get historyVoiceFileGone => '音声ファイルが見つかりません';

  @override
  String get timeCapsuleNotifTitle => 'タイムカプセルが届きました 📬';

  @override
  String timeCapsuleNotifBody(String title) {
    return 'あの日のあなたからメッセージ：$title';
  }

  @override
  String get weeklyRadioTitle => '今週のAIラジオ';

  @override
  String get weeklyRadioSubtitle => '1週間の声の記録から、あなたの物語をお届けします。';

  @override
  String get weeklyRadioNoEntries => '今週の録音がまだありません。';

  @override
  String get weeklyRadioPremiumArchive => 'プレミアムプランで過去の全エピソードを保存。';
}
