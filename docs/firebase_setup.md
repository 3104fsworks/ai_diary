# Firebase / Auth セットアップ手順

`RealFirebaseAuthService` を実機で動かすための手順です。コード側は実装済みで、設定ファイルを配置すれば自動的に Mock → Real に切り替わります（`main.dart` の `_initFirebase()` が成功すれば Real、失敗すれば Mock）。

## 1. Firebase プロジェクトを作る

1. https://console.firebase.google.com にアクセスして「プロジェクトを追加」
2. プロジェクト名: `AI Journal` など任意（後で変えられる）
3. Google Analytics は **無効** でも OK（個人開発なら）
4. 完成したら「ロケーション」を `asia-northeast1` などに設定

## 2. Android アプリを登録

1. Firebase コンソール → プロジェクト概要 → Android アイコン
2. **Android パッケージ名**: `jp.co.granhouse.ai_diary`
3. **デバッグ用 SHA-1 フィンガープリント** を登録（Google Sign-In に必須）:

   ```powershell
   # Windows / PowerShell
   cd "C:\Users\GRAN HOUSE\ai_diary\android"
   ./gradlew signingReport
   ```

   出力された `SHA1` のうち、`Variant: debug` のものをコピーして Firebase に貼り付け。

4. **`google-services.json` をダウンロード** → `android/app/google-services.json` に配置
5. このファイルは `.gitignore` に追加すること（鍵情報を含むため）

## 3. iOS アプリを登録（後で）

1. Firebase コンソール → iOS アイコン
2. **iOS バンドル ID**: `jp.co.granhouse.aiDiary`（または Runner.xcworkspace で確認した値）
3. **`GoogleService-Info.plist` をダウンロード** → `ios/Runner/GoogleService-Info.plist` に配置
4. Xcode で Runner プロジェクトに **Add Files...** で追加（Copy items if needed をチェック）

## 4. Authentication プロバイダーを有効化

Firebase コンソール → **Authentication** → Sign-in method タブで以下を有効化:

| プロバイダー | 追加設定 |
| --- | --- |
| **メール / パスワード** | チェックを入れて保存するだけ |
| **Google** | プロジェクトのサポートメールを設定するだけ |
| **Apple** | iOS のみ。Service ID と Key ID が必要（下記） |

### Apple Sign In の追加設定（iOS のみ）

1. [Apple Developer Console](https://developer.apple.com/account) → Certificates, Identifiers & Profiles
2. App ID の Capabilities に **Sign In with Apple** を ON
3. **Services ID** を作成（例: `jp.co.granhouse.aiDiary.signin`）
4. **Key** を作成（Sign In with Apple を選択）→ `.p8` ファイルをダウンロード
5. Firebase コンソールの Apple プロバイダーに以下を入力:
   - Services ID
   - Apple Team ID
   - Key ID（`.p8` の発行時に表示される）
   - Private Key の内容（`.p8` の中身）

### Xcode 側の Capability 追加

Runner target → Signing & Capabilities → + Capability → **Sign In with Apple**

`Runner/Runner.entitlements` に以下が追加されます:

```xml
<key>com.apple.developer.applesignin</key>
<array>
    <string>Default</string>
</array>
```

## 5. ビルドして確認

```bash
flutter clean
flutter run -d <device-id>
```

`google-services.json` を置くと Android Gradle の `google-services` プラグインが自動 apply され、`main.dart` で `Firebase.initializeApp()` が成功します。ログイン画面でメール / Google / (iOSで)Apple のいずれかでサインインすると、Firebase Auth コンソールに該当ユーザーが現れます。

## .gitignore に追加すべきファイル

```gitignore
# Firebase config files (contain client secrets)
android/app/google-services.json
ios/Runner/GoogleService-Info.plist
```

## トラブルシューティング

| 症状 | 対処 |
| --- | --- |
| `DEVELOPER_ERROR` (Google Sign-In) | SHA-1 が登録されていない / 違う Variant のものを登録している。リリースビルド用の SHA-1 もリリース時に登録する |
| `ApiException: 10` | 同上 |
| Firebase init failed が起動ログに出る | google-services.json が `android/app/` 直下に無い、もしくは Bundle ID 不一致 |
| Apple Sign-In がボタンを押しても無反応 | Xcode で Capability 未追加、または Service ID 設定漏れ |
| Web 版で MockAuthService のまま | これは想定動作（Web 用 Firebase 設定は同梱していない） |

## Firebase 未設定でも開発を続けるには

`_initFirebase()` が失敗すると自動で MockAuthService にフォールバックします。Web プレビューや、Firebase コンソール側の作業が終わるまでは Mock で十分動作確認できます。Mock では:

- Google / Apple / メール、どれを押しても固定の `mock-xxx` UID が払い出される
- 認証フローは存在するが Firebase コンソールには出ない

これで UI と画面遷移のテストが完結します。
