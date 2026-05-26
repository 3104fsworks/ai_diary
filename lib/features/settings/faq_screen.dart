import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final items = const [
      _Faq(
        q: 'データはどこに保存されますか？',
        a: '日記の本文、写真、位置情報はすべてあなたのスマホ内に保存されます。'
            'iCloud / Google Drive を有効にすると、ご自身のクラウドフォルダにも自動バックアップされます。',
      ),
      _Faq(
        q: '端末を変えたらデータはどうなりますか？',
        a: '自動クラウド同期を有効にしていれば、新しい端末でログインするだけで'
            'ご自身のクラウドから日記を復元できます。',
      ),
      _Faq(
        q: 'AIに何を渡しているの？',
        a: '完了ボタンを押した瞬間に、その日のメモ・音声つぶやき・連携データを一度だけAIに送り、'
            '日記を生成します。データは学習には利用されません。'
            '※「今日のつぶやき」（生の音声）はAIには参考情報として渡されますが、'
            '日記本文として書き換えられることなく、あなたの言葉のままデバイスに残ります。',
      ),
      _Faq(
        q: 'Gemini APIキーの取得方法は？',
        a: '①ブラウザで「Google AI Studio」と検索し、Googleアカウントでログイン\n'
            '②画面左上の「Get API key」をタップ\n'
            '③「Create API key」を押すと、AIza… で始まる文字列が表示されます\n'
            '④それをコピーして、本アプリの 設定 → AI APIの設定 → Gemini APIキー に貼り付けてください。\n\n'
            'キーはこの端末にのみ保存され、運営サーバーには送られません。',
      ),
      _Faq(
        q: 'AIの料金はかかりますか？',
        a: 'Gemini APIには無料枠があり、日記1日1〜2件程度のご利用であれば'
            '実質ほぼ無料で運用できます。'
            '正確な料金は Google AI Studio の料金ページをご確認ください。',
      ),
      _Faq(
        q: 'APIキーを入れない場合はどうなりますか？',
        a: 'AI生成は「オフライン下書きモード」で動作し、簡易的な日記が自動生成されます。'
            'いつでも設定からキーを追加すれば、本格的なAI日記に切り替わります。',
      ),
      _Faq(
        q: '無料プランで何ができますか？',
        a: 'テキストでの手入力と、ObsidianやNotionなど他ノートアプリへのエクスポートが無料でご利用いただけます。',
      ),
      _Faq(
        q: 'Obsidian と連携するには？',
        a: '①設定 → 「日記フォルダ（Obsidian連携）」を開き、表示されているパスをコピー\n'
            '②Obsidian の「Vault を開く」→「既存フォルダを Vault として開く」を選び、貼り付けたパスをペースト\n'
            '③以降は、日記を書く / 編集するたびに同じ .md ファイルが更新されます（新しいファイルは増えません）\n\n'
            'クラウド同期（iCloud Drive / Google Drive）にこのフォルダが含まれていれば、複数端末でも同じVaultとして開けます。',
      ),
      _Faq(
        q: '過去の日記を編集したら、新しい .md ファイルが作られますか？',
        a: 'いいえ、その日付の既存ファイル（例: 2026-05-25.md）が上書きされます。'
            'ファイル名は日付固定なので、Obsidian側でも履歴が散らからずに済みます。',
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l.settingsFaq)),
      body: ListView.separated(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          32 + MediaQuery.viewPaddingOf(context).bottom,
        ),
        itemCount: items.length,
        separatorBuilder: (_, _) =>
            Divider(color: theme.dividerColor, height: 1, thickness: 0.5),
        itemBuilder: (_, i) {
          final f = items[i];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(f.q, style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                  f.a,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.6,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Faq {
  final String q;
  final String a;
  const _Faq({required this.q, required this.a});
}
