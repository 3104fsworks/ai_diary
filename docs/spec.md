# Tsumug — 完全技術仕様書
**AI Voice Journal, Radio**  
バージョン: 1.0-beta  
最終更新: 2026-05-29  
リポジトリ: https://github.com/3104fsworks/ai_diary

---

## 目次

1. [プロジェクト概要](#1-プロジェクト概要)
2. [技術スタック](#2-技術スタック)
3. [アーキテクチャ](#3-アーキテクチャ)
4. [ファイル構造](#4-ファイル構造)
5. [データモデル](#5-データモデル)
6. [画面仕様・ナビゲーション](#6-画面仕様ナビゲーション)
7. [機能仕様](#7-機能仕様)
8. [AI プロンプト仕様](#8-ai-プロンプト仕様)
9. [通知仕様](#9-通知仕様)
10. [課金仕様（RevenueCat）](#10-課金仕様revenuecat)
11. [Cloudflare Workers プロキシ仕様](#11-cloudflare-workers-プロキシ仕様)
12. [ローカルストレージ仕様](#12-ローカルストレージ仕様)
13. [Markdownエクスポート仕様](#13-markdownエクスポート仕様)
14. [設定値一覧（SharedPreferences）](#14-設定値一覧sharedpreferences)
15. [Androidビルド設定](#15-androidビルド設定)
16. [プレミアム機能ゲート](#16-プレミアム機能ゲート)
17. [ローカライゼーション](#17-ローカライゼーション)

---

## 1. プロジェクト概要

### アプリ概要

| 項目 | 値 |
|---|---|
| アプリ名（日本） | Tsumug（ツムグ） |
| アプリ名（海外） | AI Voice Journal, Radio |
| パッケージ名 | `com.aidiary.app` |
| プラットフォーム | Android（主）、iOS（予定） |
| 最小SDK | Android 21（Android 5.0） |
| 対象SDK | Android 35 |
| 言語 | 日本語（デフォルト）、英語 |

### コンセプト

「話すだけで今日が日記になる」——声で日記を記録し、AIが整形。週末には蓄積された日記からAIラジオ番組を自動生成するパーソナルな日記アプリ。

---

## 2. 技術スタック

### Flutter / Dart

| 項目 | バージョン |
|---|---|
| Flutter | 3.44.0 |
| Dart | 3.12 |
| Min SDK Android | 21 |

### 主要パッケージ

| パッケージ | バージョン | 用途 |
|---|---|---|
| `go_router` | ^14.6.1 | 画面ルーティング |
| `shared_preferences` | ^2.3.3 | 設定値永続化 |
| `path_provider` | ^2.1.5 | ファイルパス取得 |
| `share_plus` | ^10.1.2 | OS共有シート |
| `image_picker` | ^1.1.2 | 写真ピッカー |
| `record` | ^7.0.0 | 音声録音（.m4a） |
| `audioplayers` | ^6.0.0 | 音声再生（ラジオ） |
| `purchases_flutter` | ^8.0.0 | RevenueCat課金 |
| `flutter_local_notifications` | ^18.0.0 | ローカル通知 |
| `timezone` | ^0.9.4 | タイムゾーン処理 |
| `permission_handler` | ^11.3.1 | 権限管理 |
| `http` | ^1.2.2 | HTTP通信 |
| `geolocator` | ^13.0.2 | GPS位置情報 |
| `health` | ^13.0.1 | Health Connect |
| `firebase_core` | ^3.6.0 | Firebase（オプション） |
| `firebase_auth` | ^5.3.1 | Firebase Auth |
| `google_sign_in` | ^6.2.1 | Googleサインイン |
| `googleapis` | ^14.0.0 | Calendar/Tasks API |
| `crypto` | ^3.0.6 | タイムカプセルID生成 |
| `archive` | ^3.6.1 | ZIP圧縮（Markdownエクスポート） |
| `flutter_svg` | ^2.0.10 | SVGレンダリング |

### 外部API

| API | エンドポイント | 用途 |
|---|---|---|
| OpenAI Whisper | `POST https://api.openai.com/v1/audio/transcriptions` | 音声→テキスト変換 |
| Google Gemini 2.5 Flash | `POST https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent` | 日記生成AI |
| RevenueCat | SDK経由 | サブスクリプション管理 |

### バックエンド

| サービス | 用途 |
|---|---|
| Cloudflare Workers | APIキープロキシ（本番環境） |
| Firebase Auth | Google/Appleサインイン（オプション） |
| Google Calendar API | カレンダー連携（読み取り専用） |
| Google Tasks API | タスク連携（読み取り専用） |
| Health Connect | 歩数・睡眠取得（Android） |

---

## 3. アーキテクチャ

### 設計原則

- **ローカルファースト**: 全データを端末内のJSONファイルに保存。クラウド同期なし。
- **サービスロケーター**: `ServiceLocator`クラスで依存関係を1箇所管理（DIフレームワーク不使用）。
- `InheritedWidget`でサービスと設定をWidget Treeに注入。
- **Mock/Real切り替え**: 各サービスにMock実装を用意。Firebase未設定 / Web環境ではMockを使用。

### レイヤー構成

```
┌─────────────────────────────────────────────┐
│  features/  (UI Screens + Widgets)          │
├─────────────────────────────────────────────┤
│  app/       (Router, ServiceLocator,        │
│             AppSettings, Theme)             │
├─────────────────────────────────────────────┤
│  core/      (Services: AI, Audio,           │
│             Notifications, Purchase,        │
│             Auth, Calendar, Health,         │
│             Location, Export)               │
├─────────────────────────────────────────────┤
│  data/      (Models, Repositories)          │
└─────────────────────────────────────────────┘
```

### 起動フロー（main.dart）

```
1. WidgetsFlutterBinding.ensureInitialized()
2. AppSettings.load()           → SharedPreferences読み込み
3. _initFirebase()               → Firebase初期化（失敗時はMockにフォールバック）
4. ServiceLocator.bootstrap()    → 全サービス初期化
5. TimeCapsuleService.init()     → タイムゾーンデータ初期化
6. RadioNotificationService.init() + scheduleAll()
7. DiaryReminderService.init() + scheduleDaily()
8. RevenueCat entitlement sync   → checkEntitlement() + listener登録
9. runApp(AiDiaryApp)
```

### ServiceLocatorが管理するサービス

| フィールド | 型 | 実装 |
|---|---|---|
| `diary` | `DiaryRepository` | `LocalDiaryRepository`（SQLite-like JSON） |
| `timeline` | `TimelineRepository` | `LocalTimelineRepository` |
| `location` | `LocationTimelineService` | GPS取得→Timelineに書き込み |
| `ai` | `RoutingAiDiaryService` | BYOK/Premium/Free を自動ルーティング |
| `health` | `HealthService` | `RealHealthService`（Health Connect） |
| `calendar` | `CalendarService` | `RealGoogleCalendarService` |
| `tasks` | `TasksService` | `RealGoogleTasksService` |
| `auth` | `AuthService` | `RealFirebaseAuthService` |
| `purchase` | `PurchaseService` | `RealRevenueCatPurchaseService` |
| `survey` | `SurveyRepository` | `LocalSurveyRepository` |
| `weeklySummary` | `WeeklySummaryRepository` | `LocalWeeklySummaryRepository` |

---

## 4. ファイル構造

```
ai_diary/
├── lib/
│   ├── main.dart
│   ├── app/
│   │   ├── app.dart                    # AiDiaryApp（root widget）
│   │   ├── app_settings.dart           # SharedPrefs全設定（ChangeNotifier）
│   │   ├── service_locator.dart        # DI container
│   │   ├── router/
│   │   │   └── app_router.dart         # GoRouter設定・全ルート定義
│   │   └── theme/
│   │       ├── app_colors.dart         # カラーパレット
│   │       ├── app_theme.dart          # ThemeData（Light/Dark）
│   │       └── app_typography.dart     # TextTheme
│   ├── core/
│   │   ├── ai/
│   │   │   ├── ai_diary_service.dart           # 抽象インターフェース
│   │   │   ├── gemini_ai_diary_service.dart    # Gemini REST実装
│   │   │   ├── mock_ai_diary_service.dart      # Mock実装
│   │   │   ├── prompt_builder.dart             # プロンプト構築・レスポンス解析
│   │   │   ├── radio_script_service.dart       # ラジオスクリプト生成
│   │   │   ├── routing_ai_diary_service.dart   # BYOK/Premium/Freeルーティング
│   │   │   └── whisper_transcription_service.dart  # OpenAI Whisper
│   │   ├── audio/
│   │   │   ├── audio_cleanup_service.dart      # 古い音声ファイル自動削除
│   │   │   └── tts_service.dart                # TTS（ラジオ音声生成）
│   │   ├── auth/
│   │   │   ├── auth_service.dart               # 抽象インターフェース
│   │   │   ├── app_user.dart                   # Userモデル
│   │   │   ├── mock_auth_service.dart
│   │   │   └── real_firebase_auth_service.dart
│   │   ├── calendar/
│   │   │   ├── calendar_service.dart
│   │   │   ├── mock_calendar_service.dart
│   │   │   └── real_google_calendar_service.dart
│   │   ├── export/
│   │   │   ├── diary_markdown_exporter.dart    # 1エントリ→Markdown変換
│   │   │   ├── bulk_markdown_exporter.dart     # 全エントリZIP出力
│   │   │   └── sns_image_exporter.dart         # SNS用画像生成
│   │   ├── health/
│   │   │   ├── health_service.dart
│   │   │   ├── mock_health_service.dart
│   │   │   └── real_health_service.dart        # Health Connect
│   │   ├── invites/
│   │   │   └── invite_code_service.dart        # 招待コード検証
│   │   ├── location/
│   │   │   └── location_timeline_service.dart  # GPS→Timeline記録
│   │   ├── notifications/
│   │   │   ├── diary_reminder_service.dart     # 日記リマインダー（毎日）
│   │   │   ├── radio_notification_service.dart # AIラジオ通知（週・月）
│   │   │   └── time_capsule_service.dart       # タイムカプセル通知
│   │   ├── purchase/
│   │   │   ├── purchase_service.dart           # 抽象インターフェース
│   │   │   ├── product_info.dart               # 商品モデル
│   │   │   ├── mock_purchase_service.dart
│   │   │   └── real_revenue_cat_purchase_service.dart
│   │   └── tasks/
│   │       ├── tasks_service.dart
│   │       ├── mock_tasks_service.dart
│   │       └── real_google_tasks_service.dart
│   ├── data/
│   │   ├── models/
│   │   │   ├── diary_entry.dart        # 日記エントリ（メインモデル）
│   │   │   ├── ai_personality.dart     # AIパーソナリティ enum
│   │   │   ├── goal_item.dart          # 目標チップ
│   │   │   ├── radio_episode.dart      # ラジオエピソード
│   │   │   ├── radio_voice_personality.dart  # ラジオ声質設定
│   │   │   ├── survey_response.dart    # アンケート回答
│   │   │   └── voice_metadata.dart     # 音声特性メタデータ
│   │   ├── repositories/              # 抽象インターフェース
│   │   └── sources/
│   │       ├── local/                 # JSONファイルベース実装
│   │       └── memory/                # インメモリ実装（Web/テスト）
│   ├── features/
│   │   ├── diary/
│   │   │   ├── diary_edit_screen.dart      # 日記作成・編集メイン画面
│   │   │   ├── voice_recording_screen.dart # 音声録音→文字起こし
│   │   │   └── widgets/                    # 日記画面ウィジェット群
│   │   ├── history/
│   │   │   ├── history_list_screen.dart    # 日記一覧（リスト）
│   │   │   └── history_detail_screen.dart  # 日記詳細閲覧
│   │   ├── home/
│   │   │   ├── home_screen.dart            # ホーム（カレンダー）
│   │   │   ├── weekly_radio_screen.dart    # AIラジオ一覧
│   │   │   └── radio_player_screen.dart    # ラジオプレイヤー
│   │   ├── legal/
│   │   ├── onboarding/
│   │   │   ├── splash_screen.dart
│   │   │   ├── language_select_screen.dart
│   │   │   ├── survey_screen.dart
│   │   │   ├── tutorial_screen.dart        # 4ページ（最後: 通知許可）
│   │   │   └── login_screen.dart
│   │   └── settings/
│   │       ├── settings_screen.dart        # メイン設定
│   │       ├── custom_settings_screen.dart # カスタム設定（APIキー・プロキシ）
│   │       ├── plan_screen.dart            # プラン・課金
│   │       └── goals_screen.dart           # 目標設定
│   ├── l10n/
│   │   ├── app_ja.arb
│   │   ├── app_en.arb
│   │   └── generated/
│   └── widgets/                            # 共通ウィジェット
├── android/
│   ├── app/
│   │   ├── build.gradle.kts
│   │   ├── proguard-rules.pro
│   │   └── src/main/
│   │       ├── AndroidManifest.xml
│   │       └── kotlin/com/aidiary/app/MainActivity.kt
│   ├── gradle.properties
│   └── settings.gradle.kts
├── cloudflare/
│   ├── worker.js                       # Cloudflare Workers プロキシ
│   └── wrangler.toml                   # デプロイ設定
├── docs/
│   ├── privacy_policy.html             # プライバシーポリシー（GitHub Pages）
│   └── play_console_listing.md         # Play Storeコピペ用掲載文
└── assets/
    ├── icon/
    │   ├── app_icon.png                # 1024×1024 マスターアイコン
    │   ├── app_icon_foreground.png     # Adaptive icon前景
    │   ├── play_store_icon_512.png     # Play Store用 512×512
    │   └── play_store_feature_graphic.png  # Play Store 1024×500
    └── (fonts, images, etc.)
```

---

## 5. データモデル

### DiaryEntry（日記エントリ）

```dart
class DiaryEntry {
  final String id;                    // UUID (date-based)
  final DateTime date;                // 日付
  final String? aiTitle;              // AIが生成したタイトル（10〜20字）
  final String userMemo;              // ユーザーが手入力したテキスト
  final String rawVoiceMemo;          // 音声文字起こし原文（AI編集禁止）
  final String? aiJournal;            // AI生成日記本文（日本語・一人称）
  final String? aiJournalEn;          // 英語要約（3〜4文・ラジオ用）
  final String? aiFeedback;           // AI一言コメント（日本語）
  final String? aiFeedbackEn;         // 英語コメント
  final String? aiRadioIndex;         // ラジオインデックス（英語）
  final List<String> photoPaths;      // 写真ローカルパス一覧
  final List<GoalItem> goals;         // 目標チェックリスト
  final WeatherInfo? weather;         // 天気情報
  final ActivityInfo? activity;       // 歩数・睡眠時間
  final List<ScheduleItem> schedule;  // カレンダー予定
  final List<String> doneTasks;       // 完了タスク
  final List<TimelineStop> timeline;  // 位置情報タイムライン
  final String? audioFilePath;        // 録音ファイルパス（.m4a）
  final int? audioDurationSeconds;    // 録音時間（最大120秒）
  final DateTime? capsuleDeliveryDate;// タイムカプセル配信日時
  final VoiceMetadata? voiceMetadata; // 音声特性（感情温度等）
}
```

**サブモデル:**

```dart
class WeatherInfo {
  final WeatherKind kind;   // sunny/cloudy/rainy/snowy
  final double tempC;       // 気温（摂氏）
  final String place;       // 地名
}

class ActivityInfo {
  final int steps;          // 歩数
  final double sleepHours;  // 睡眠時間（時間単位）
}

class VoiceMetadata {
  final double averageAmplitude;    // 平均振幅（0.0〜1.0）
  final double silenceRatio;        // 無音率（0.0〜1.0）
  final int totalDurationSeconds;   // 録音秒数
  final double emotionTemperature;  // 感情温度（振幅70%+発話率30%で算出）
}
// 感情温度計算式: (avgAmplitude * 0.7) + ((1.0 - silenceRatio) * 0.3)
// 無音閾値: 0.15
```

### RadioEpisode（ラジオエピソード）

```dart
class RadioEpisode {
  final String id;              // "weekly_2026-05-25" / "monthly_2026-05-31"
  final DateTime generatedAt;
  final RadioEpisodeType type;  // weekly / monthly
  final String script;          // AIが生成したナレーションスクリプト
  final String audioFilePath;   // TTS生成音声ファイルパス
}
// 週間: 目標180秒（3分）
// 月間: 目標300秒（5分）
```

### AiGenerationResult（AI生成結果）

```dart
class AiGenerationResult {
  final String journal;         // 日本語日記本文（必須）
  final String feedback;        // 日本語コメント（必須）
  final String? titleSuggestion;// タイトル案
  final String? journalEn;      // 英語要約
  final String? feedbackEn;     // 英語コメント
  final String? radioIndex;     // ラジオインデックス
}
```

---

## 6. 画面仕様・ナビゲーション

### ルート一覧（GoRouter）

| ルート | 画面 | 備考 |
|---|---|---|
| `/` → redirect | SplashScreen | オンボーディング完了確認 |
| `/splash` | SplashScreen | 初回起動判定 |
| `/language` | LanguageSelectScreen | 言語選択（初回） |
| `/survey` | SurveyScreen | 初回アンケート |
| `/tutorial` | TutorialScreen | チュートリアル（4ページ） |
| `/login` | LoginScreen | Google/Appleサインイン |
| `/home` | HomeScreen | メイン（カレンダー表示） |
| `/diary` | DiaryEditScreen | 日記作成・編集 |
| `/history` | HistoryListScreen | 日記一覧 |
| `/history/:date` | HistoryDetailScreen | 日記詳細 |
| `/weekly-radio` | WeeklyRadioScreen | AIラジオ一覧 |
| `/weekly-radio/player` | RadioPlayerScreen | ラジオプレイヤー |
| `/settings` | SettingsScreen | 設定メイン |
| `/settings/custom` | CustomSettingsScreen | カスタム設定 |
| `/settings/goals` | GoalsScreen | 目標設定 |
| `/plan` | PlanScreen | プラン・課金 |
| `/legal/privacy` | PrivacyPolicyScreen | プライバシーポリシー |
| `/legal/terms` | TermsScreen | 利用規約 |
| `/settings/faq` | FaqScreen | FAQ |

### ナビゲーションフロー

```
起動
  ↓
onboardingDone = false → /language → /survey → /tutorial(4p) → /home
onboardingDone = true  → /home
                               ↓
                         ┌─ BottomNav ─┐
                         ホーム  履歴  設定
```

### TutorialScreen（4ページ構成）

| ページ | タイトル | アクション |
|---|---|---|
| 1 | tutorialTitle1 | 次へ |
| 2 | tutorialTitle2 | 次へ |
| 3 | tutorialTitle3 | 次へ |
| 4 | 毎日の日記リマインダー | 「通知をオンにする」（許可取得+設定） / 「あとで設定する」（スキップ） |

---

## 7. 機能仕様

### 7-1. 音声録音・文字起こし

**VoiceRecordingScreen**
- 最大録音時間: **120秒（2分）**
- フォーマット: .m4a（AAC-LC）
- サンプリング間隔: 500ms（振幅サンプリング用）
- 録音完了後の処理:
  1. `VoiceMetadata.compute()` で感情温度を算出
  2. OpenAI Whisper API（または プロキシ）に音声ファイルを送信
  3. `response_format=text` でプレーンテキスト取得
  4. 文字起こし結果と `VoiceMetadata` を `VoiceRecordingResult` として返す

**WhisperTranscriptionService**
```
直接モード（デフォルト）:
  POST https://api.openai.com/v1/audio/transcriptions
  Authorization: Bearer {apiKey}
  Content-Type: multipart/form-data
  Body: file={audioFile}, model=whisper-1, language={iso639}, response_format=text

プロキシモード（proxyUrl設定時）:
  POST {proxyUrl}/whisper
  X-App-Token: {appToken}
  Content-Type: multipart/form-data
  Body: file={audioFile}, model=whisper-1, language={iso639}, response_format=text
```

**言語コード**: BCP-47 → ISO-639-1変換（`ja-JP` → `ja`）

### 7-2. AI日記生成

**RoutingAiDiaryService（APIキー優先度）**

```
優先度 1: BYOK（ユーザーが入力したGemini APIキー）→ 無制限・選択パーソナリティ
優先度 2: Premium → 共有キー（GEMINI_API_KEY環境変数 or インラインキー）
優先度 3: Free → 共有キー、1日1回制限、パーソナリティ強制Standard
          ↓ 失敗時 → MockAiDiaryService（フォールバック）
```

**GeminiAiDiaryService**
- モデル: `gemini-2.5-flash`
- temperature: 0.6
- topP: 0.95
- maxOutputTokens: 2000
- timeout: 30秒
- 安全設定: BLOCK_ONLY_HIGH（全カテゴリ）

```
直接モード:
  POST https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key={apiKey}

プロキシモード:
  POST {proxyUrl}/gemini
  X-App-Token: {appToken}
  Body: { "model": "gemini-2.5-flash", "body": {geminiRequest} }
```

**AIパーソナリティ（AiPersonality）**

| 種類 | storageKey | 内容 |
|---|---|---|
| Standard（標準） | `standard` | デフォルト。中立的なトーン |
| Mirror（鏡） | `mirror` | ユーザーの感情をそのまま反映 |
| Friendly（フレンドリー） | `friendly` | 温かく励ますトーン |

### 7-3. 日記編集画面（DiaryEditScreen）

**主要コンポーネント:**
- `TextEditingController` × 2: メインテキスト用 + 音声メモ用
- `_rawVoiceController`: 音声文字起こし原文（常時表示・編集可能）
- `ValueListenableBuilder<TextEditingValue>`: 「AI再生成」ボタンの表示制御
- 音声ファイルパスが存在する場合、再生ボタンを表示

**状態管理:**
- `_isSummarising`: AI生成中フラグ（ボタン無効化）
- 音声メモ編集後に「AI再生成」ボタンをタップ → `_summariseIntoTextField()` 呼び出し

**保存時（`_onDone()`）のデータ:**
```
DiaryEntry.userMemo = メインテキストフィールド値
DiaryEntry.rawVoiceMemo = _rawVoiceController.text
DiaryEntry.voiceTranscript = _rawVoiceController.text（Whisperからの原文）
```

### 7-4. AIラジオ（WeeklyRadioScreen / RadioPlayerScreen）

**生成タイミング:**
- 週間: 毎週日曜 21:00 に通知 → タップで生成または自動生成
- 月間: 毎月末日 21:00 に通知

**スクリプト生成ロジック（RadioScriptService）:**
1. `WeeklySummaryRepository` から対象期間の日記を取得
2. 各日記の `aiRadioIndex`（英語・軽量）を優先使用
3. `aiRadioIndex` がない場合は `aiJournalEn`（英語要約）を使用
4. Gemini にラジオスクリプト生成を依頼
5. TTS で音声化 → `RadioEpisode` として保存

**RadioPlayerScreen:**
- `audioplayers` パッケージで音声再生
- スクリプトテキスト表示
- 前後エピソード切り替え

### 7-5. ライフログ自動連携

| データ種別 | 取得元 | 権限 |
|---|---|---|
| 天気 | OpenWeatherMap / 端末位置 | ACCESS_COARSE_LOCATION |
| 歩数 | Health Connect | health.READ_STEPS |
| 睡眠 | Health Connect | health.READ_SLEEP |
| カレンダー | Google Calendar API | Calendar.readonly |
| タスク | Google Tasks API | Tasks.readonly |
| 位置タイムライン | Geolocator | ACCESS_FINE_LOCATION |

### 7-6. タイムカプセル機能

- AIが日記中に「○ヶ月後の自分へ」フレーズを検出した場合に自動設定
- `capsuleDeliveryDate` にデリバリー日時を記録
- `TimeCapsuleService` が起動時に未配信カプセルをスキャン
- `flutter_local_notifications` でスケジュール（ハッシュベースID）

### 7-7. Markdownエクスポート（DiaryMarkdownExporter）

出力形式:

```markdown
---
date: 2026-05-29
day_of_week: THU
weather: ☀️ 22°C 渋谷
location: 渋谷
steps: 8000
sleep_duration: "07:30"
sleep_quality: Good     # Good(>7h) / Fair(5-7h) / Poor(<5h)
stress_level: 21        # (100 - energy) * 0.7
energy_level: 70        # emotionTemperature * 100
tags: []
---

# 2026-05-29 — [AIタイトル]

## 🎯 Daily Goals
- [x] 目標1
- [ ] 目標2

## 📓 AI Journal
[日本語日記本文]

*[English summary (3-4 sentences)]*

## 💬 AI Feedback
> [日本語コメント]
> *[English comment]*

## 🎤 User Records
### Voice Memo (Raw)
[音声文字起こし原文]

### Notes
[手入力テキスト]

## 📅 Life Log
[カレンダー・タスク]

## 📻 AI Radio Index
<details>
<summary>Radio Index (EN)</summary>

[ラジオインデックスブロック]

</details>
```

**ストレスレベル計算式:**
- `energyLevel = (emotionTemperature * 100).round()`
- `stressLevel = ((100 - energyLevel) * 0.7).round()`
- `sleepQuality: Good(>7h) / Fair(5〜7h) / Poor(<5h)`

---

## 8. AI プロンプト仕様

### システムプロンプト構成（3部構成）

```
Part 1: ベースプロンプト（_basePrompt）
  ロール定義・6セクション出力規則・フォーマット指定

Part 2: 感情同期条項（_emotionSyncClause）
  ユーザーの感情状態に応じた対応（優先度最高）

Part 3: パーソナリティ条項（_personalityClause）
  Standard / Mirror / Friendly のトーン定義
```

### 出力セクション（6セクション固定）

| セクション | 言語 | 内容 | 文字数目安 |
|---|---|---|---|
| `## Title` | 日本語 | 体言止め1行 | 10〜20字 |
| `## Journal` | 日本語 | 一人称日記本文 | 300〜500字 |
| `## Journal EN` | 英語 | 日記要約 | 3〜4文 |
| `## AI Feedback JP` | 日本語 | 労いコメント | 1〜2文 |
| `## AI Feedback EN` | 英語 | 同上翻訳 | 1〜2文 |
| `## Radio Index` | 英語 | ラジオ用超軽量インデックス | 2行固定 |

**Radio Indexフォーマット（厳守）:**
```
- **Core Action:** [今日の出来事を英語2文以内で要約]
- **AI Sentiment:** [心理状態を英語キーワード2つ e.g. Focused calm, quiet satisfaction]
```

### ユーザープロンプト（送信データ）

```markdown
## Today
- Date: YYYY-MM-DD
- Weather: sunny, 22°C @ 渋谷
- Activity: 8000 steps, 7.5h sleep
- Schedule:
  - 14:00 会議
- Done tasks:
  - タスクA

## User memo (typed)
[手入力テキスト]

## User voice transcript (verbatim — DO NOT rewrite)
[音声文字起こし原文]
```

---

## 9. 通知仕様

### 通知チャンネル一覧

| チャンネルID | 名前 | 通知ID | 用途 | タイミング |
|---|---|---|---|---|
| `diary_reminder` | 日記リマインダー | `1000` | 毎日日記を書くよう促す | 設定時刻（デフォルト21:00）毎日繰り返し |
| `ai_radio` | AIラジオ | `2000`（週）/ `2001`（月） | ラジオ番組生成を通知 | 毎週日曜21:00 / 毎月末日21:00 |
| `time_capsule` | タイムカプセル | ハッシュベース | 過去日記を配信 | `capsuleDeliveryDate` 指定日時 |

### 権限

- Android 13+: `POST_NOTIFICATIONS`（実行時許可）
- アラーム: `SCHEDULE_EXACT_ALARM` + `USE_EXACT_ALARM`
- ブート後再スケジュール: `RECEIVE_BOOT_COMPLETED`

### 日記リマインダー設定フロー

```
チュートリアルp.4: 「通知をオンにする」
  → requestPermission()
  → setDiaryReminderEnabled(true)
  → scheduleDaily(hour: 21)

設定画面: トグル + 時刻ピッカー
  → showTimePicker（24h表示）
  → setDiaryReminderHour(hour)
  → scheduleDaily(hour: hour, enabled: true)
```

---

## 10. 課金仕様（RevenueCat）

### プラン構成

| 商品ID | 名前 | 価格 | 機能 |
|---|---|---|---|
| `ai_journal_voice_monthly` | 音声入力プラン | ¥300/月 | 音声日記・広告非表示 |
| `ai_journal_voice_photo_monthly` | 音声+写真プラン | ¥500/月 | 上記+写真機能 |
| `ai_journal_full_monthly` | フル機能プラン | ¥1,000/月 | 全機能・パーソナリティ選択 |

### RevenueCat設定

| 項目 | 値 |
|---|---|
| Android API Key | `goog_SdOhXOfTWeGKAUGNiJxHqFYnKKu` |
| エンタイトルメントID | `premium` |

### 起動時エンタイトルメント同期

```dart
// main.dart
final active = await purchaseSvc.checkEntitlement();
await settings.setPremium(active);  // 双方向同期
await purchaseSvc.listenToEntitlementChanges((isActive) async {
  await settings.setPremium(isActive);  // リアルタイム更新
});
```

### isPremiumの判定ロジック

```dart
bool get isPremium {
  if (_manualPremium) return true;     // RevenueCat同期値
  if (lifetimeFree) return true;       // 招待コード（永久）
  final until = premiumUntil;
  if (until != null && until.isAfter(DateTime.now())) return true;  // 期限付き
  return false;
}
```

---

## 11. Cloudflare Workers プロキシ仕様

### エンドポイント

| メソッド | パス | 機能 |
|---|---|---|
| `POST` | `/whisper` | OpenAI Whisper APIへ転送（multipart） |
| `POST` | `/gemini` | Google Gemini APIへ転送（JSON） |
| `OPTIONS` | `/*` | CORS preflight |

### 認証

リクエストヘッダー: `X-App-Token: {APP_TOKEN}`  
Worker側でシークレット `APP_TOKEN` と照合（未設定時は検証スキップ）

### `/whisper` リクエスト仕様

```
Client → Worker:
  POST /whisper
  X-App-Token: {token}
  Content-Type: multipart/form-data; boundary=...
  Body: file={audioBytes}, model=whisper-1, language=ja, response_format=text

Worker → OpenAI:
  POST https://api.openai.com/v1/audio/transcriptions
  Authorization: Bearer {OPENAI_API_KEY}  ← Workerが注入
  同じmultipartボディを転送

レスポンス: プレーンテキスト（文字起こし結果）
```

### `/gemini` リクエスト仕様

```
Client → Worker:
  POST /gemini
  X-App-Token: {token}
  Content-Type: application/json
  Body: {
    "model": "gemini-2.5-flash",
    "body": { ...Gemini generateContent request... }
  }

Worker → Gemini:
  POST https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key={GEMINI_API_KEY}
  Content-Type: application/json
  Body: body フィールドの内容をそのまま転送

レスポンス: Gemini generateContent レスポンスJSON
```

### Workerシークレット（`wrangler secret put`で設定）

| シークレット名 | 内容 |
|---|---|
| `OPENAI_API_KEY` | OpenAI APIキー（sk-proj-...） |
| `GEMINI_API_KEY` | Gemini APIキー（AIzaSy...） |
| `APP_TOKEN` | アプリ認証トークン（任意の32文字以上ランダム文字列） |

### デプロイコマンド

```bash
npm install -g wrangler
wrangler login
cd cloudflare
wrangler secret put OPENAI_API_KEY
wrangler secret put GEMINI_API_KEY
wrangler secret put APP_TOKEN
wrangler deploy
# → https://ai-diary-proxy.{subdomain}.workers.dev
```

---

## 12. ローカルストレージ仕様

### ストレージ方式

全データをJSONファイルとして端末の `Documents` ディレクトリ（`path_provider`で取得）に保存。

### ファイル構成

```
{documentsDir}/
├── diary/
│   └── {YYYY-MM-DD}.json          # 1日記 = 1ファイル（DiaryEntry）
├── timeline/
│   └── timeline.json              # 位置タイムライン配列
├── survey/
│   └── responses.json             # アンケート回答配列
├── weekly_summary/
│   └── summary_cache.json         # 週間サマリーキャッシュ
├── radio/
│   └── episodes.json              # RadioEpisode配列
└── recordings/
    └── {timestamp}.m4a            # 音声録音ファイル
```

### 音声ファイル自動削除（AudioCleanupService）

```
無料ユーザー: 7日以上前の .m4a ファイルを削除
プレミアムユーザー: 削除しない
実行タイミング: 毎回アプリ起動時
```

---

## 13. Markdownエクスポート仕様（再掲・詳細版）

### BulkMarkdownExporter

全日記エントリをZIP圧縮してOS共有シートで出力。

```
出力ファイル名: ai_diary_{YYYYMMDD}.zip
ZIP内構造:
  {YYYY-MM-DD}.md  × エントリ数
```

### YAML Frontmatterフィールド

| フィールド | 型 | 算出方法 |
|---|---|---|
| `date` | String | `YYYY-MM-DD` |
| `day_of_week` | String | `MON`〜`SUN` |
| `weather` | String | `{emoji} {tempC}°C {place}` |
| `location` | String | timeline最初のstop.place |
| `steps` | int | activity.steps |
| `sleep_duration` | String | `"HH:MM"`形式 |
| `sleep_quality` | String | `Good`(>7h) / `Fair`(5-7h) / `Poor`(<5h) |
| `stress_level` | int | `((100-energy)*0.7).round()` |
| `energy_level` | int | `(emotionTemperature*100).round()` |
| `tags` | List | 空配列（将来拡張用） |

---

## 14. 設定値一覧（SharedPreferences）

| キー | 型 | デフォルト | 内容 |
|---|---|---|---|
| `theme_mode` | String | `system` | `light`/`dark`/`system` |
| `accent_color` | int | `black` | アクセントカラー（ARGB int） |
| `ai_personality` | String | `standard` | `standard`/`mirror`/`friendly` |
| `onboarding_done` | bool | `false` | オンボーディング完了フラグ |
| `gemini_api_key` | String | `""` | ユーザーBYOK Gemini APIキー |
| `openai_api_key` | String | `""` | ユーザーBYOK OpenAI APIキー |
| `proxy_base_url` | String | `""` | Cloudflare Workers URL |
| `app_proxy_token` | String | `""` | プロキシ認証トークン |
| `location_enabled` | bool | `false` | 位置情報ライフログ |
| `health_enabled` | bool | `false` | ヘルスデータ連携 |
| `calendar_enabled` | bool | `false` | カレンダー連携 |
| `tasks_enabled` | bool | `false` | タスク連携 |
| `is_premium` | bool | `false` | RevenueCat同期プレミアムフラグ |
| `lifetime_free` | bool | `false` | 招待コード永久フラグ |
| `premium_until_iso` | String | `null` | 期限付きプレミアム期限 |
| `redeemed_code` | String | `null` | 使用済み招待コード |
| `last_free_generation_date` | String | `null` | 無料生成最終利用日 |
| `diary_reminder_enabled` | bool | `false` | 日記リマインダー有効 |
| `diary_reminder_hour` | int | `21` | リマインダー時刻（0-23） |
| `radio_notifications_enabled` | bool | `true` | ラジオ通知有効 |
| `radio_voice_type` | String | `narrator` | ラジオ音声タイプ |
| `radio_voice_gender` | String | `neutral` | ラジオ音声性別 |
| `font_scale` | double | `1.0` | 文字スケール（0.9/1.0/1.15/1.3） |
| `locale_override` | String | `null` | 言語上書き（`ja`/`en`） |
| `custom_goals` | String | `"[]"` | 目標リスト（JSON配列） |
| `voice_tooltip_seen` | bool | `false` | 音声ツールチップ表示済み |
| `current_user_id` | String | `""` | Firebase UID |

---

## 15. Androidビルド設定

### build.gradle.kts

```kotlin
namespace = "com.aidiary.app"
applicationId = "com.aidiary.app"
minSdk = 21
targetSdk = 35
compileSdk = 35
```

### 署名設定

```
android/key.properties（gitignore済み）:
  storeFile=app/release.keystore
  storePassword=...
  keyAlias=...
  keyPassword=...
```

### Gradleバージョン

| ツール | バージョン |
|---|---|
| Gradle | 9.4.1 |
| AGP（Android Gradle Plugin） | 9.2.1 |
| Kotlin | 2.3.20 |

### AndroidManifest.xml 権限一覧

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="com.android.vending.BILLING"/>  <!-- Play Billing -->
<uses-permission android:name="android.permission.BLUETOOTH"/>
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT"/>
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.USE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.health.READ_STEPS"/>
<uses-permission android:name="android.permission.health.READ_SLEEP"/>
<uses-permission android:name="android.permission.ACTIVITY_RECOGNITION"/>
```

### リリースビルドコマンド（Windows）

```powershell
$env:JAVA_TOOL_OPTIONS = "-Djava.nio.channels.spi.SelectorProvider=sun.nio.ch.WindowsSelectorProvider"
flutter build apk --release
# 出力: build/app/outputs/flutter-apk/app-release.apk
```

---

## 16. プレミアム機能ゲート

| 機能 | 無料 | プレミアム |
|---|---|---|
| テキスト日記 | ✅ | ✅ |
| AI日記生成 | 1回/日 | 無制限 |
| 音声入力 | ✅ | ✅ |
| 写真添付 | ❌（Voice+Photoプラン以上） | ✅ |
| カレンダー・タスク連携 | ❌（Fullプラン） | ✅ |
| ヘルスデータ連携 | ❌（Fullプラン） | ✅ |
| 位置情報タイムライン | ❌（Fullプラン） | ✅ |
| AIパーソナリティ選択 | ❌ | ✅（Fullプラン） |
| 目標チップ | 3個まで | 6個まで |
| 音声ファイル保持 | 7日間 | 無期限 |
| 広告 | あり | なし |
| BYOK（独自APIキー） | ❌ | ✅ |

---

## 17. ローカライゼーション

### 対応言語

| 言語 | コード | ARBファイル |
|---|---|---|
| 日本語 | `ja` | `lib/l10n/app_ja.arb` |
| 英語 | `en` | `lib/l10n/app_en.arb` |

### 生成コマンド

```bash
flutter gen-l10n
# l10n.yaml設定ファイルを参照して自動生成
# 出力: lib/l10n/generated/app_localizations*.dart
```

### 言語切り替え

- `AppSettings.localeOverride` に `Locale('ja')` または `Locale('en')` を設定
- `null` の場合はOS言語に追従

---

## 付録：Play Store情報

| 項目 | 値 |
|---|---|
| アプリ名（JP） | Tsumug |
| アプリ名（EN） | AI Voice Journal, Radio |
| カテゴリ | ライフスタイル |
| プライバシーポリシーURL | https://3104fsworks.github.io/ai_diary/privacy_policy.html |
| Androidアイコン（512×512） | `assets/icon/play_store_icon_512.png` |
| フィーチャーグラフィック（1024×500） | `assets/icon/play_store_feature_graphic.png` |
| 最小Androidバージョン | Android 5.0（API 21） |
| コンテンツレーティング | 全年齢対象 |

---

*この仕様書はリポジトリ `docs/spec.md` に含まれています。*
