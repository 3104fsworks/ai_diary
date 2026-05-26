import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final body = locale == 'ja' ? _bodyJa : _bodyEn;
    final lastUpdated = locale == 'ja' ? '最終更新: 2026年5月26日' : 'Last updated: May 26, 2026';

    return Scaffold(
      appBar: AppBar(title: Text(l.settingsPrivacyPolicy)),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          32 + MediaQuery.viewPaddingOf(context).bottom,
        ),
        children: [
          Text(lastUpdated, style: theme.textTheme.bodySmall),
          const SizedBox(height: 16),
          Text(
            body,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.7),
          ),
        ],
      ),
    );
  }
}

const _bodyJa = '''
AIジャーナル（以下「本アプリ」）は、ユーザーのプライバシーを最優先に設計されています。本ポリシーでは、本アプリがどのようなデータをどう扱うかをご説明します。

## 1. データの保管場所

日記の本文・写真・音声入力テキスト・位置情報・ヘルスケアデータなど、すべての個人データは原則としてユーザーの端末内（または、ユーザー自身が選択したiCloud / Google Driveフォルダ）にのみ保管されます。本アプリの運営者がこれらのデータを閲覧することはできません。

## 2. AI日記生成について

ユーザーが「完了」ボタンを押した瞬間に、その日のメモ・音声つぶやき・連携データを Google Gemini API に送信し、日記本文を生成します。Google Gemini API のプライバシー方針については Google のプライバシーポリシー（https://policies.google.com/privacy）をご確認ください。本アプリの運営者がGeminiに送信されたデータを保持・閲覧することはありません。

ユーザーが独自のAPIキーをご入力された場合、通信はそのキーを介して直接行われ、本アプリの運営者はキーや通信内容に一切関与しません。

## 3. アカウント情報（Firebase Authentication）

ログインに使用したメールアドレス・Google ID・電話番号は Google Firebase Authentication が安全に管理します。本アプリの運営者は、これらの認証情報の中身（メール本文、アカウントの詳細等）を直接閲覧することはありません。

## 4. 招待コード機能

招待コードを使用した場合、本アプリの運営者は「どの招待コードが使われたか」と「使った匿名ユーザーID」のみを記録します。個人を特定する情報は記録しません。

## 5. 外部連携サービス（任意）

ユーザーが任意で有効化した場合に限り、以下のサービスと連携します。連携を有効化しなければ通信は発生しません。
- Apple Health / Health Connect（歩数・睡眠の読み取りのみ）
- Google カレンダー / Google Tasks（読み取りのみ）
- 位置情報サービス（端末内のタイムライン作成のみ。位置データは外部送信されません）

## 6. 未成年者の利用

13歳未満のお子様による本アプリのご利用は推奨しておりません。

## 7. データの削除

アプリの「データを削除」操作、または OS の標準的なアプリ削除操作で、端末内のすべてのデータが完全に削除されます。

## 8. お問い合わせ

本ポリシーや本アプリのプライバシー実装についてご質問がある場合は、運営までお問い合わせください。
''';

const _bodyEn = '''
AI Journal ("the App") is designed with your privacy as the highest priority. This policy explains what data the App handles and how.

## 1. Where your data is stored

All personal data — diary entries, photos, voice transcripts, location data, health data — is stored only on your device (or, optionally, in the iCloud / Google Drive folder you choose). The App's operators cannot view this data.

## 2. AI diary generation

When you press "Done", the app sends that day's notes, voice transcript, and integrated data to Google Gemini API to generate the diary text. Please review Google's Privacy Policy for how Gemini handles data: https://policies.google.com/privacy. The App's operators do not retain or view data sent to Gemini.

If you enter your own API key, the request goes directly with your key. The App's operators have no access to the key or the request.

## 3. Account information (Firebase Authentication)

The email address, Google ID, or phone number you use to sign in is managed by Google Firebase Authentication. The App's operators cannot read the contents of email, account details, etc.

## 4. Invite codes

When you redeem an invite code, the App's operators record only the redeemed code value and an anonymous user identifier — no personally identifying information.

## 5. Optional integrations

The App connects to the following services only when you explicitly enable them. No communication occurs otherwise.
- Apple Health / Health Connect (read-only: steps, sleep)
- Google Calendar / Google Tasks (read-only)
- Location services (used only to build a local timeline; coordinates never leave your device)

## 6. Children

The App is not recommended for use by children under 13.

## 7. Deleting your data

Selecting "Delete data" in the app, or uninstalling via standard OS controls, completely removes all data from your device.

## 8. Contact

For questions about this policy or our privacy implementation, please contact us.
''';
