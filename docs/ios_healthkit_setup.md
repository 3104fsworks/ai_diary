# iOS HealthKit セットアップ手順

`RealHealthService` を iOS 実機で動かすには、Apple Developer Program に登録した Bundle ID で **HealthKit Capability** を有効化し、Provisioning Profile を再生成する必要があります。Flutter のコードからは設定できないため、必ず Xcode から行ってください。

## 1. Xcode で Runner プロジェクトを開く

```bash
cd ios
open Runner.xcworkspace
```

（`Runner.xcodeproj` ではなく必ず `xcworkspace` を開くこと）

## 2. Signing & Capabilities で HealthKit を追加

1. 左ペインで `Runner` プロジェクト → TARGETS の `Runner` を選択
2. 上部タブから **Signing & Capabilities** を開く
3. 左上の **+ Capability** をクリック
4. リストから **HealthKit** をダブルクリック

これで `Runner/Runner.entitlements` が自動生成され、以下が追加されます:

```xml
<key>com.apple.developer.healthkit</key>
<true/>
<key>com.apple.developer.healthkit.access</key>
<array/>
```

> 本アプリは **読み取り専用** で歩数と睡眠時間のみ参照します。Clinical Health Records が必要になった場合のみ `<array>` に種別を追加してください。

## 3. Apple Developer Console でも有効化

App ID の Capabilities に HealthKit のチェックを入れて、**Provisioning Profile を再生成 → ダウンロード** します。

- App IDs: https://developer.apple.com/account/resources/identifiers/list
- 該当の App ID (`jp.co.granhouse.aiDiary` など) を選んで **HealthKit** を ON
- 編集後、自動署名なら Xcode が次回ビルドで再取得します

## 4. Info.plist のチェック（既に設定済み）

以下のキーが `ios/Runner/Info.plist` にあることを確認:

- `NSHealthShareUsageDescription` — 読み取り用（必須）
- `NSHealthUpdateUsageDescription` — 書き込み用（読み取り専用アプリでも審査で要求されることがある）

## 5. ビルドして実機テスト

```bash
flutter run -d <iphone-device-id>
```

設定画面の「ヘルスケア」トグルを ON にすると、iOS の HealthKit 権限ダイアログが表示されます。

## トラブルシューティング

| 症状 | 対処 |
| --- | --- |
| `Missing entitlement` で起動失敗 | Provisioning Profile が古い。Xcode で signing を一度 None → Automatic に戻す |
| 権限ダイアログが出ない | アプリを一度削除して再インストール。HealthKit の認可は端末側にキャッシュされる |
| 歩数が常に 0 | iPhone 単体で計測している場合、ヘルスケアアプリで歩数データが入っているか確認。Apple Watch がペアリングされていれば優先される |

## App Store 提出時のメモ

審査では「なぜヘルスケアデータが必要か」を Review Notes に明記する必要があります。本アプリの場合は:

> "AI Diary auto-fills the daily journal entry with the user's step count and sleep hours. All health data stays on-device and is never uploaded."

と書けば通ります（読み取り専用 + ローカル保存のため）。
