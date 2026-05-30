---
title: Tsumug — 完全技術仕様書
app: Tsumug
package: com.aidiary.app
platform: Android
version: 1.0-beta
updated: 2026-05-29
tags:
  - project/ai-diary
  - flutter
  - android
  - spec
  - "#AI"
  - "#diary"
status: in-progress
repo: https://github.com/3104fsworks/ai_diary
---

# Tsumug — 完全技術仕様書

> [!info] アプリ概要
> 「**話すだけで今日が日記になる**」——声で日記を記録し、AIが整形。週末には蓄積された日記から **AIラジオ番組**を自動生成するパーソナルな日記アプリ。
> - パッケージ名: `com.aidiary.app`
> - リポジトリ: https://github.com/3104fsworks/ai_diary
> - プライバシーポリシー: https://3104fsworks.github.io/ai_diary/privacy_policy.html

---

## 目次

- [[#1. プロジェクト概要]]
- [[#2. 技術スタック]]
- [[#3. アーキテクチャ]]
- [[#4. ファイル構造]]
- [[#5. データモデル]]
- [[#6. 画面仕様・ナビゲーション]]
- [[#7. 機能仕様]]
- [[#8. AIプロンプト仕様]]
- [[#9. 通知仕様]]
- [[#10. 課金仕様（RevenueCat）]]
- [[#11. Cloudflare Workers プロキシ仕様]]
- [[#12. ローカルストレージ仕様]]
- [[#13. Markdownエクスポート仕様]]
- [[#14. 設定値一覧（SharedPreferences）]]
- [[#15. Androidビルド設定]]
- [[#16. プレミアム機能ゲート]]
- [[#17. ローカライゼーション]]

---

## 1. プロジェクト概要

| 項目 | 値 |
|---|---|
| アプリ名（日本） | Tsumug（ツムグ） |
| アプリ名（海外） | AI Voice Journal, Radio |
| パッケージ名 | `com.aidiary.app` |
| プラットフォーム | Android（主）、iOS（予定） |
| 最小SDK | Android 21（Android 5.0） |
| 対象SDK | Android 35 |
| 言語 | 日本語（デフォルト）、英語 |

---

## 2. 技術スタック

### Flutter / Dart

| 項目 | バージョン |
|---|---|
| Flutter | 3.44.0 |
| Dart | 3.12 |
| Min SDK Android | API 21 |

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
| `archive` | ^3.6.1 | ZIP圧縮（MDエクスポート） |

### 外部API

| API | エンドポイント | 用途 |
|---|---|---|
| OpenAI Whisper | `POST /v1/audio/transcriptions` | 音声→テキスト変換 |
| Google Gemini 2.5 Flash | `POST .../gemini-2.5-flash:generateContent` | 日記生成AI |
| RevenueCat | SDK経由 | サブスクリプション管理 |
| Google Calendar API | SDK経由 | カレンダー連携（読み取り専用） |
| Health Connect | Android SDK | 歩数・睡眠取得 |
| Cloudflare Workers | カスタムURL | APIキープロキシ（本番） |

---

## 3. アーキテクチャ

### 設計原則

> [!tip] 設計原則
> - **ローカルファースト**: 全データを端末内JSONファイルに保存。クラウド同期なし。
> - **ServiceLocator**: `ServiceLocator`クラスで依存関係を1箇所管理（DIフレームワーク不使用）。
> - **InheritedWidget**: サービスと設定をWidget Treeに注入。
> - **Mock/Real切り替え**: 各サービスにMock実装。Firebase未設定/Web環境ではMock使用。

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
2. AppSettings.load()              → SharedPreferences 読み込み
3. _initFirebase()                 → 失敗時はMockにフォールバック
4. ServiceLocator.bootstrap()      → 全サービス初期化
5. TimeCapsuleService.init()       → タイムゾーンデータ初期化
6. RadioNotificationService.init() + scheduleAll()
7. DiaryReminderService.init()     + scheduleDaily()
8. RevenueCat entitlement sync     → checkEntitlement() + listener登録
9. runApp(AiDiaryApp)
```

### ServiceLocatorが管理するサービス

| フィールド | 型 | 実装 |
|---|---|---|
| `diary` | DiaryRepository | LocalDiaryRepository |
| `timeline` | TimelineRepository | LocalTimelineRepository |
| `location` | LocationTimelineService | GPS取得→Timeline記録 |
| `ai` | RoutingAiDiaryService | BYOK/Premium/Freeルーティング |
| `health` | HealthService | RealHealthService（Health Connect） |
| `calendar` | CalendarService | RealGoogleCalendarService |
| `tasks` | TasksService | RealGoogleTasksService |
| `auth` | AuthService | RealFirebaseAuthService |
| `purchase` | PurchaseService | RealRevenueCatPurchaseService |

---

## 4. ファイル構造

```
ai_diary/
├── lib/
│   ├── main.dart
│   ├── app/
│   │   ├── app.dart                        # AiDiaryApp（root widget）
│   │   ├── app_settings.dart               # SharedPrefs全設定（ChangeNotifier）
│   │   ├── service_locator.dart            # DI container
│   │   ├── router/app_router.dart          # GoRouter設定・全ルート定義
│   │   └── theme/                          # カラー・TextTheme・ThemeData
│   ├── core/
│   │   ├── ai/
│   │   │   ├── gemini_ai_diary_service.dart
│   │   │   ├── routing_ai_diary_service.dart
│   │   │   ├── whisper_transcription_service.dart
│   │   │   ├── prompt_builder.dart
│   │   │   └── radio_script_service.dart
│   │   ├── audio/          # TTS・音声クリーンアップ
│   │   ├── auth/           # Firebase Auth
│   │   ├── calendar/       # Google Calendar
│   │   ├── export/         # Markdown・SNS画像エクスポート
│   │   ├── health/         # Health Connect
│   │   ├── notifications/  # 日記リマインダー・ラジオ・タイムカプセル
│   │   ├── purchase/       # RevenueCat
│   │   └── tasks/          # Google Tasks
│   ├── data/
│   │   ├── models/         # DiaryEntry, VoiceMetadata, RadioEpisode...
│   │   ├── repositories/   # 抽象インターフェース
│   │   └── sources/
│   │       ├── local/      # JSONファイルベース実装
│   │       └── memory/     # インメモリ実装（Web/テスト）
│   ├── features/
│   │   ├── diary/          # 日記作成・音声録音
│   │   ├── history/        # 日記一覧・詳細
│   │   ├── home/           # カレンダー・ラジオ一覧・プレイヤー
│   │   ├── onboarding/     # スプラッシュ・言語選択・チュートリアル
│   │   └── settings/       # 設定・プラン・目標
│   └── l10n/               # app_ja.arb / app_en.arb
├── android/
│   └── app/src/main/AndroidManifest.xml
├── cloudflare/
│   ├── worker.js           # Cloudflare Workers プロキシ
│   └── wrangler.toml
├── docs/
│   ├── privacy_policy.html
│   └── play_console_listing.md
└── assets/icon/
    ├── app_icon.png                    # 1024×1024 マスター
    ├── play_store_icon_512.png         # 512×512
    └── play_store_feature_graphic.png  # 1024×500
```

---

## 5. データモデル

### DiaryEntry（日記エントリ）

```dart
class DiaryEntry {
  final String id;                    // UUID (date-based)
  final DateTime date;
  final String? aiTitle;              // AIタイトル（10〜20字）
  final String userMemo;              // ユーザー手入力テキスト
  final String rawVoiceMemo;          // 音声文字起こし原文（AI編集禁止）
  final String? aiJournal;            // AI生成日記本文（日本語・一人称）
  final String? aiJournalEn;          // 英語要約（3〜4文・ラジオ用）
  final String? aiFeedback;           // AI一言コメント（日本語）
  final String? aiFeedbackEn;         // 英語コメント
  final String? aiRadioIndex;         // ラジオインデックス（英語・2行）
  final List<String> photoPaths;
  final List<GoalItem> goals;
  final WeatherInfo? weather;
  final ActivityInfo? activity;       // 歩数・睡眠時間
  final List<ScheduleItem> schedule;
  final List<String> doneTasks;
  final List<TimelineStop> timeline;
  final String? audioFilePath;        // .m4a（最大120秒）
  final DateTime? capsuleDeliveryDate;
  final VoiceMetadata? voiceMetadata;
}
```

### VoiceMetadata（音声特性）

```dart
class VoiceMetadata {
  final double averageAmplitude;    // 平均振幅 0.0〜1.0
  final double silenceRatio;        // 無音率 0.0〜1.0（無音閾値: 0.15）
  final int totalDurationSeconds;
  final double emotionTemperature;
}

// 感情温度 = (avgAmplitude × 0.7) + ((1.0 - silenceRatio) × 0.3)
```

### RadioEpisode

```dart
class RadioEpisode {
  final String id;              // "weekly_2026-05-25" / "monthly_2026-05-31"
  final DateTime generatedAt;
  final RadioEpisodeType type;  // weekly(目標180秒) / monthly(目標300秒)
  final String script;
  final String audioFilePath;
}
```

### AiGenerationResult

```dart
class AiGenerationResult {
  final String journal;           // 日本語日記本文（必須）
  final String feedback;          // 日本語コメント（必須）
  final String? titleSuggestion;
  final String? journalEn;        // 英語要約
  final String? feedbackEn;
  final String? radioIndex;
}
```

---

## 6. 画面仕様・ナビゲーション

### ルート一覧（GoRouter）

| ルート | 画面 | 備考 |
|---|---|---|
| `/splash` | SplashScreen | 初回起動判定 |
| `/language` | LanguageSelectScreen | 初回のみ |
| `/survey` | SurveyScreen | 初回アンケート |
| `/tutorial` | TutorialScreen | 4ページ（最後: 通知許可） |
| `/login` | LoginScreen | Google/Appleサインイン |
| `/home` | HomeScreen | メイン（カレンダー） |
| `/diary` | DiaryEditScreen | 日記作成・編集 |
| `/history` | HistoryListScreen | 日記一覧 |
| `/history/:date` | HistoryDetailScreen | 日記詳細 |
| `/weekly-radio` | WeeklyRadioScreen | AIラジオ一覧 |
| `/weekly-radio/player` | RadioPlayerScreen | ラジオプレイヤー |
| `/settings` | SettingsScreen | 設定メイン |
| `/settings/custom` | CustomSettingsScreen | APIキー・プロキシ |
| `/settings/goals` | GoalsScreen | 目標設定 |
| `/plan` | PlanScreen | プラン・課金 |
| `/legal/privacy` | PrivacyPolicyScreen | プライバシーポリシー |

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

| ページ | 内容 | アクション |
|---|---|---|
| 1 | tutorialTitle1 | 次へ |
| 2 | tutorialTitle2 | 次へ |
| 3 | tutorialTitle3 | 次へ |
| 4 | 毎日の日記リマインダー | 「通知をオンにする」/ 「あとで設定する」 |

---

## 7. 機能仕様

### 7-1. 音声録音・文字起こし

> [!note] VoiceRecordingScreen
> - 最大録音時間: **120秒（2分）**、フォーマット: `.m4a`（AAC-LC）
> - サンプリング間隔: 500ms
> - 言語コード: BCP-47 → ISO-639-1（`ja-JP` → `ja`）

```
直接モード（デフォルト）:
  POST https://api.openai.com/v1/audio/transcriptions
  Authorization: Bearer {apiKey}
  Body: file={audioFile}, model=whisper-1, language=ja, response_format=text

プロキシモード（proxyUrl設定時）:
  POST {proxyUrl}/whisper
  X-App-Token: {appToken}
  （同じBody）
```

### 7-1.5. 初回限定フル機能体験期間（オンボーディング施策）

> [!tip] 14日間トライアル
> **仕様**: 初回のオンボーディング完了（チュートリアル完了）から**14日間**は、RevenueCatの契約状態に関わらず全ユーザーに「プレミアム（Fullプラン）」の全機能を解放する。
>
> **目的**: AIラジオ・ライフログ連携など、アプリの最大価値を体験してもらい、納得して課金へ移行してもらう。**目標CVR: 3〜5%**

#### 実装

| 項目 | 詳細 |
|---|---|
| 開始トリガー | `TutorialScreen._completeOnboarding()` → `settings.recordFirstLaunchDate()` |
| 期間 | `firstLaunchDate` から14日間 |
| 判定 | `AppSettings.isInTrialPeriod` → `isPremium` に含まれる |
| 体験期間終了後 | 無課金なら `isPremium = false` → `PremiumUpsellSheet` を表示 |

```dart
// AppSettings.isPremium の判定ロジック
bool get isPremium {
  if (isInTrialPeriod) return true; // 14-day trial
  if (_manualPremium) return true;  // RevenueCat同期
  if (lifetimeFree) return true;    // 招待コード（永久）
  final until = premiumUntil;
  if (until != null && until.isAfter(DateTime.now())) return true;
  return false;
}

bool get isInTrialPeriod {
  final launched = firstLaunchDate;
  if (launched == null) return false;
  return DateTime.now().difference(launched).inDays < 14;
}
```

---

### 7-2. AI日記生成（APIキー優先度）

```
優先度 1: BYOK（ユーザー入力 Gemini APIキー）→ 無制限・選択パーソナリティ
優先度 2: Premium（トライアル含む） → 共有キー・選択パーソナリティ
優先度 3: Free → 共有キー、週3回制限、パーソナリティ強制Standard
          ↓ 失敗時 → MockAiDiaryService（フォールバック）
```

#### 無料プランのAI生成回数制限（週3回ルール）

> [!warning] 制限変更（旧: 1日1回 → 新: 週3回まで）

- **制限ロジック**: 過去7日間（ローリングウィンドウ）のAI生成回数が3回に達したらブロック。
- **`FreeQuotaExceeded`** 例外が投げられると UI が `PremiumUpsellSheet` を表示。
- **手入力の日記作成は無制限**（AI生成のみカウント）。

```dart
// RoutingAiDiaryService（自動フォールバック）
if (settings.freeGenerationExceededThisWeek) {
  throw const FreeQuotaExceeded();
}
```

| SharedPreferences キー | 旧 | 新 |
|---|---|---|
| `last_free_generation_date` | 最終生成日（1日1回用） | 廃止（後方互換のため残存） |
| `free_generation_dates_list` | — | 過去7日間の生成日時JSON配列 |

### 7-3. Gemini パラメータ

| パラメータ | 値 |
|---|---|
| モデル | `gemini-2.5-flash` |
| temperature | 0.6 |
| topP | 0.95 |
| maxOutputTokens | 2000 |
| timeout | 30秒 |
| 安全設定 | BLOCK_ONLY_HIGH（全カテゴリ） |

### 7-4. AIパーソナリティ

| 種類 | storageKey | 内容 |
|---|---|---|
| Standard（標準） | `standard` | 中立的なトーン |
| Mirror（鏡） | `mirror` | ユーザーの感情をそのまま反映 |
| Friendly（フレンドリー） | `friendly` | 温かく励ますトーン |

### 7-5. ライフログ自動連携

| データ種別 | 取得元 | 権限 |
|---|---|---|
| 天気 | OpenWeatherMap / 端末位置 | ACCESS_COARSE_LOCATION |
| 歩数 | Health Connect | health.READ_STEPS |
| 睡眠 | Health Connect | health.READ_SLEEP |
| カレンダー | Google Calendar API | Calendar.readonly |
| タスク | Google Tasks API | Tasks.readonly |
| 位置タイムライン | Geolocator | ACCESS_FINE_LOCATION |

### 7-6. AIラジオ生成フロー

```
1. WeeklySummaryRepository から対象期間の日記を取得
2. 各日記の aiRadioIndex（英語・軽量）を優先使用
   └ なければ aiJournalEn（英語要約）を使用
3. Gemini にラジオスクリプト生成を依頼
4. TTS で音声化 → RadioEpisode として保存

週間: 毎週日曜 21:00（目標180秒）
月間: 毎月末日 21:00（目標300秒）
```

### 7-6.5. PremiumUpsellSheet（体験期間終了モーダル）

`lib/widgets/premium_upsell_sheet.dart` — `PremiumUpsellSheet.show(context)` で表示。

**表示トリガー:**
- ラジオ画面でユーザーが生成を試みたとき（`settings.isPremium == false`）
- 日記編集画面で週3回の無料AI生成枠を超えたとき（`FreeQuotaExceeded`）

**UI構成:**

| 要素 | 内容 |
|---|---|
| ビジュアル | ラジオプレイヤー風グラフィック（電波アーク + 鍵マーク + Premiumバッジ） |
| メインコピー | 「今週も、あなただけの『AIラジオ』の準備ができています。」 |
| 本文 | 14日間体験終了の説明 + プレミアム移行の訴求 |
| プライマリCTA | 「プランを選んで、今週のラジオを聴く」→ `/settings/plan` へ遷移 |
| セカンダリリンク | 「無料プラン（AIラジオなし・AI生成週3回）で続ける」→ シートを閉じる |

---

### 7-7. タイムカプセル機能

> [!note] タイムカプセル
> AIが日記中に「○ヶ月後の自分へ」フレーズを検出した場合に自動設定。
> `capsuleDeliveryDate` に配信日時を記録し、`TimeCapsuleService` が起動時にスキャン。
> `flutter_local_notifications` でスケジュール（ハッシュベースID）。

---

## 8. AIプロンプト仕様

### システムプロンプト構成（3部構成）

| パート | 内容 |
|---|---|
| Part 1: `_basePrompt` | ロール定義・6セクション出力規則・フォーマット指定 |
| Part 2: `_emotionSyncClause` | 感情状態に応じた対応（優先度最高） |
| Part 3: `_personalityClause` | Standard / Mirror / Friendly のトーン定義 |

### 出力セクション（6セクション固定）

| セクション | 言語 | 内容 | 文字数目安 |
|---|---|---|---|
| `## Title` | 日本語 | 体言止め1行 | 10〜20字 |
| `## Journal` | 日本語 | 一人称日記本文 | 300〜500字 |
| `## Journal EN` | 英語 | 日記要約 | 3〜4文 |
| `## AI Feedback JP` | 日本語 | 労いコメント | 1〜2文 |
| `## AI Feedback EN` | 英語 | 同上翻訳 | 1〜2文 |
| `## Radio Index` | 英語 | ラジオ用超軽量インデックス | 2行固定 |

> [!warning] Radio Index フォーマット（厳守）
> ```
> - **Core Action:** [今日の出来事を英語2文以内で要約]
> - **AI Sentiment:** [心理状態を英語キーワード2つ e.g. Focused calm, quiet satisfaction]
> ```

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

| チャンネルID | 通知ID | 用途 | タイミング |
|---|---|---|---|
| `diary_reminder` | 1000 | 日記リマインダー | 毎日21:00（設定変更可） |
| `ai_radio` | 2000 / 2001 | ラジオ番組通知 | 週: 日曜21:00 / 月: 末日21:00 |
| `time_capsule` | ハッシュ | タイムカプセル | capsuleDeliveryDate 指定日時 |

### 必要権限

- Android 13+: `POST_NOTIFICATIONS`（実行時許可）
- `SCHEDULE_EXACT_ALARM` + `USE_EXACT_ALARM`
- `RECEIVE_BOOT_COMPLETED`（ブート後再スケジュール）

---

## 10. 課金仕様（RevenueCat）

### プラン構成

| 商品ID | 名前 | 価格 | 機能 |
|---|---|---|---|
| `ai_journal_voice_monthly` | 音声入力プラン | ¥300/月 | 音声日記・広告非表示 |
| `ai_journal_voice_photo_monthly` | 音声+写真プラン | ¥500/月 | 上記+写真機能 |
| `ai_journal_full_monthly` | フル機能プラン | ¥1,000/月 | 全機能・パーソナリティ選択 |

> [!warning] RevenueCat設定値
> - Android API Key: `goog_SdOhXOfTWeGKAUGNiJxHqFYnKKu`
> - エンタイトルメントID: `premium`

### 起動時エンタイトルメント同期

```dart
// main.dart
final active = await purchaseSvc.checkEntitlement();
await settings.setPremium(active);
await purchaseSvc.listenToEntitlementChanges((isActive) async {
  await settings.setPremium(isActive);
});
```

### isPremium判定ロジック

```dart
bool get isPremium {
  if (_manualPremium) return true;     // RevenueCat同期値
  if (lifetimeFree) return true;       // 招待コード（永久）
  final until = premiumUntil;
  if (until != null && until.isAfter(DateTime.now())) return true;
  return false;
}
```

---

## 11. Cloudflare Workers プロキシ仕様

### エンドポイント

| メソッド | パス | 機能 |
|---|---|---|
| POST | `/whisper` | OpenAI Whisper APIへ転送（multipart） |
| POST | `/gemini` | Google Gemini APIへ転送（JSON） |
| OPTIONS | `/*` | CORS preflight |

### 認証

リクエストヘッダー: `X-App-Token: {APP_TOKEN}`
Worker側でシークレット `APP_TOKEN` と照合（未設定時は検証スキップ）

### Workerシークレット

| シークレット名 | 内容 |
|---|---|
| `OPENAI_API_KEY` | OpenAI APIキー（sk-proj-...） |
| `GEMINI_API_KEY` | Gemini APIキー（AIzaSy...） |
| `APP_TOKEN` | アプリ認証トークン（32文字以上ランダム） |

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

```
{documentsDir}/
├── diary/
│   └── {YYYY-MM-DD}.json      # 1日記 = 1ファイル
├── timeline/
│   └── timeline.json
├── radio/
│   └── episodes.json
└── recordings/
    └── {timestamp}.m4a
```

> [!note] 音声ファイル自動削除（AudioCleanupService）
> - **無料ユーザー**: 7日以上前の `.m4a` を削除
> - **プレミアムユーザー**: 削除しない
> - 実行タイミング: 毎回アプリ起動時

---

## 13. Markdownエクスポート仕様

### BulkMarkdownExporter

全日記エントリをZIP圧縮してOS共有シートで出力。
出力ファイル名: `ai_diary_{YYYYMMDD}.zip`

### YAML Frontmatterフィールド

| フィールド | 型 | 算出方法 |
|---|---|---|
| `date` | String | `YYYY-MM-DD` |
| `day_of_week` | String | `MON`〜`SUN` |
| `weather` | String | `{emoji} {tempC}°C {place}` |
| `steps` | int | activity.steps |
| `sleep_duration` | String | `"HH:MM"`形式 |
| `sleep_quality` | String | Good(>7h) / Fair(5-7h) / Poor(<5h) |
| `energy_level` | int | `emotionTemperature × 100` |
| `stress_level` | int | `(100 - energy) × 0.7` |
| `tags` | List | 空配列（将来拡張用） |

### Markdownテンプレート

```markdown
---
date: 2026-05-29
day_of_week: THU
weather: ☀️ 22°C 渋谷
steps: 8000
sleep_duration: "07:30"
sleep_quality: Good
stress_level: 21
energy_level: 70
tags: []
---

# 2026-05-29 — [AIタイトル]

## 🎯 Daily Goals
- [x] 目標1

## 📓 AI Journal
[日本語日記本文]

*[English summary]*

## 💬 AI Feedback
> [日本語コメント]

## 🎤 User Records
### Voice Memo (Raw)
[音声文字起こし原文]

## 📻 AI Radio Index
<details>
<summary>Radio Index (EN)</summary>

[ラジオインデックス]

</details>
```

---

## 14. 設定値一覧（SharedPreferences）

| キー | 型 | デフォルト | 内容 |
|---|---|---|---|
| `theme_mode` | String | `system` | `light`/`dark`/`system` |
| `accent_color` | int | black | アクセントカラー（ARGB int） |
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
| `premium_until_iso` | String | null | 期限付きプレミアム期限 |
| `first_launch_date` | String | null | 初回オンボーディング完了日時（ISO 8601）。14日間トライアル起算点。 |
| `free_generation_dates_list` | String | `"[]"` | 無料AI生成日時のJSON配列（7日超は自動削除）。週3回制限の管理用。 |
| `last_free_generation_date` | String | null | **廃止済み**（旧1日1回管理キー。後方互換のため残存） |
| `diary_reminder_enabled` | bool | `false` | 日記リマインダー有効 |
| `diary_reminder_hour` | int | `21` | リマインダー時刻（0-23） |
| `radio_notifications_enabled` | bool | `true` | ラジオ通知有効 |
| `font_scale` | double | `1.0` | 文字スケール（0.9/1.0/1.15/1.3） |
| `locale_override` | String | null | 言語上書き（`ja`/`en`） |
| `custom_goals` | String | `"[]"` | 目標リスト（JSON配列） |
| `voice_tooltip_seen` | bool | `false` | 音声ツールチップ表示済み |
| `current_user_id` | String | `""` | Firebase UID |

---

## 15. Androidビルド設定

### build.gradle.kts

| 設定 | 値 |
|---|---|
| namespace / applicationId | `com.aidiary.app` |
| minSdk | 21 |
| targetSdk / compileSdk | 35 |
| Gradle | 9.4.1 |
| AGP | 9.2.1 |
| Kotlin | 2.3.20 |

### リリースビルドコマンド（Windows）

```powershell
$env:JAVA_TOOL_OPTIONS = "-Djava.nio.channels.spi.SelectorProvider=sun.nio.ch.WindowsSelectorProvider"
flutter build apk --release
# 出力: build/app/outputs/flutter-apk/app-release.apk
```

### AndroidManifest.xml 主要権限

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="com.android.vending.BILLING"/>
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.health.READ_STEPS"/>
<uses-permission android:name="android.permission.health.READ_SLEEP"/>
```

> [!danger] コミット禁止ファイル（gitignore済み）
> - `android/app/google-services.json`
> - `android/signing/release.keystore`
> - `android/key.properties`

---

## 16. プレミアム機能ゲート

| 機能 | 無料 | プレミアム |
|---|---|---|
| テキスト日記 | ✅ | ✅ |
| AI日記生成 | **週3回まで** | 無制限 |
| 音声入力 | ✅ | ✅ |
| AIラジオ生成 | ❌（体験期間中のみ） | ✅ 週・月 |
| 写真添付 | ❌ | ✅（Voice+Photo以上） |
| カレンダー・タスク連携 | ❌ | ✅（Fullプラン） |
| ヘルスデータ連携 | ❌ | ✅（Fullプラン） |
| 位置情報タイムライン | ❌ | ✅（Fullプラン） |
| AIパーソナリティ選択 | ❌ | ✅（Fullプラン） |
| 目標チップ | 3個まで | 6個まで |
| 音声ファイル保持 | 7日間 | 無期限 |
| 広告 | あり | なし |
| BYOK（独自APIキー） | ❌ | ✅ |

> [!note] 初回14日間トライアル
> トライアル中は全機能が無制限で利用可能（AIラジオ含む）。体験期間終了後は上記テーブルに従う。

---

## 17. ローカライゼーション

| 言語 | コード | ARBファイル |
|---|---|---|
| 日本語 | `ja` | `lib/l10n/app_ja.arb` |
| 英語 | `en` | `lib/l10n/app_en.arb` |

```bash
flutter gen-l10n
# 出力: lib/l10n/generated/app_localizations*.dart
```

- `AppSettings.localeOverride` に `Locale('ja')` または `Locale('en')` を設定
- `null` の場合はOS言語に追従

---

## 付録: Play Store情報

| 項目 | 値 |
|---|---|
| アプリ名（JP） | Tsumug |
| アプリ名（EN） | AI Voice Journal, Radio |
| カテゴリ | ライフスタイル |
| プライバシーポリシーURL | https://3104fsworks.github.io/ai_diary/privacy_policy.html |
| コンテンツレーティング | 全年齢対象 |
| 最小Androidバージョン | Android 5.0（API 21） |
| アイコン（512×512） | `assets/icon/play_store_icon_512.png` |
| フィーチャーグラフィック | `assets/icon/play_store_feature_graphic.png` |

---

## 残タスク

- [ ] Play Console 登録・支払い（$25 一回払い）
- [ ] ストア掲載文入力 → `docs/play_console_listing.md` 参照
- [ ] 署名済みAPKアップロード（内部テストトラック）
- [ ] RevenueCat サービスアカウント紐付け
- [ ] RevenueCat ダッシュボード: `premium` エンタイトルメント + 3商品設定
- [ ] iOS TestFlight（Apple Developer Program $99/年 + Mac環境が必要）

---

*この仕様書はリポジトリ `docs/spec.md`（オリジナル）および `docs/spec_obsidian.md`（Obsidian用）に含まれています。*
