# Google Calendar / Tasks API セットアップ手順

`RealGoogleCalendarService` / `RealGoogleTasksService` を実機で動かすには、Firebase が裏で作った Google Cloud プロジェクトで **Calendar API** と **Tasks API** を有効化する必要があります。コード側は実装済みで、API を有効化すれば自動的に動きます。

## 1. Google Cloud Console で対象プロジェクトを開く

1. https://console.cloud.google.com を開く（Firebase と同じ Google アカウント）
2. 画面上部のプロジェクトプルダウンで、Firebase が作った **`aijournal-d4f0b`** を選択

## 2. Calendar API を有効化

1. 左メニュー → **「API とサービス」→「ライブラリ」**
2. 検索バーに **`Google Calendar API`** と入力
3. ヒットしたカードをクリック → **「有効にする」** ボタン

## 3. Tasks API を有効化

1. 同じく「ライブラリ」に戻る
2. 検索バーに **`Tasks API`** と入力
3. ヒットしたカードをクリック → **「有効にする」**

## 4. OAuth 同意画面でスコープを宣言

外部ユーザーがログインする本番リリース前には、OAuth 同意画面で使用スコープを宣言する必要があります。テスト中は同意画面の **「テストユーザー」** に自分のメアドを追加すれば動きます。

1. 左メニュー → **「API とサービス」→「OAuth 同意画面」**
2. **User Type** が「外部」になっていることを確認（変更不可なら OK）
3. **「テストユーザー」** タブ → **「+ ADD USERS」** → `gran.keiri@granhouse.co.jp` を追加
4. **「スコープ」** タブ → **「スコープを追加または削除」** → 以下にチェック:
   - `.../auth/calendar.readonly` （カレンダー読み取り）
   - `.../auth/tasks.readonly` （タスク読み取り）
5. **「更新」** → **「保存して次へ」**

> テストモードのままだと 100 ユーザーまで使えます。本番公開は別途審査必要ですが、個人開発では当面テストモードで OK。

## 5. アプリ側でのフロー

1. アプリ起動 → ログイン画面で **Google サインイン**
2. ホーム → **設定 → 「Google カレンダー」トグルを ON**
3. **追加スコープの OAuth ダイアログ** が出る → 「許可」
4. **設定 → 「Google ToDo」トグルを ON** → 同様にスコープダイアログ → 許可
5. 日記画面に戻る → その日の予定と完了タスクが **「Schedule」「Done Tasks」** に表示される

## トラブルシューティング

| 症状 | 対処 |
| --- | --- |
| 「許可」を押したのに予定が空 | その日の Google Calendar に予定が無い（別の日に予定がある日に開いて確認） |
| 「Calendar access was not granted」と SnackBar | テストユーザーに追加していない / スコープ宣言が未保存 / Google サインイン未完了 |
| 「403 Insufficient Permission」 | スコープ宣言を保存し直し、いったんサインアウトして再サインイン |
| 完了タスクが出ない | Google Tasks 側で **当日に完了** したタスクが無い（前日完了は対象外） |

## 取れる情報

- **Calendar**: その日 00:00–24:00 のイベント（タイトル + 開始時刻）。primary カレンダーのみ
- **Tasks**: 当日 00:00–24:00 に完了マークしたタスクのタイトル。全タスクリストを横断

書き込みは一切行いません（read-only スコープ）。
