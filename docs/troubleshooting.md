# トラブルシューティングガイド

## よくある問題と解決方法

### セットアップ関連

#### エラー: "lib directory not found"
```bash
❌ Error: lib directory not found at /path/to/lib
```

**原因**: スクリプトがlibディレクトリを見つけられません。

**解決方法**:
1. リポジトリが正しくクローンされているか確認
2. setup_vibeflow.shとlibディレクトリが同じ場所にあるか確認
3. スクリプトを直接実行する代わりに、フルパスで実行してみる

#### エラー: "command not found"
```bash
bash: git: command not found
```

**原因**: 必要なツールがインストールされていません。

**解決方法**:
- macOS: `brew install git`
- Linux: `sudo apt-get install git` または `sudo yum install git`

### 実行時の問題

#### 既存ファイルの上書き警告
```
⚠️  既存のVibe Coding設定が見つかりました。
```

**解決方法**:
1. バックアップを作成してから続行: そのまま「y」を入力
2. 別のディレクトリで実行: 新しいディレクトリを作成して実行
3. 強制インストール: `--force`オプションを使用

#### スラッシュコマンドが動作しない

**原因**: コマンドファイルが正しく生成されていない可能性があります。

**解決方法**:
1. `.claude/commands/`ディレクトリを確認
2. コマンドファイル（.md）が存在するか確認
3. 必要に応じてセットアップを再実行

### Claude Code関連

#### "Subagent not found"エラー

**原因**: Subagentファイルが見つかりません。

**解決方法**:
1. `.claude/agents/`ディレクトリを確認
2. 4つのSubagentファイルが存在するか確認：
   - pm-auto.md
   - engineer-auto.md
   - qa-auto.md
   - deploy-auto.md

#### 開発サイクルが進まない

**原因**: state.yamlが正しく更新されていない可能性があります。

**解決方法**:
1. `.vibe/state.yaml`の内容を確認
2. 必要に応じて手動で修正：
   ```yaml
   current_cycle: 1
   current_step: 1_plan_review
   current_issue: null
   next_step: 2_issue_breakdown
   ```

### ファイルアクセス権限

#### Permission deniedエラー

**原因**: ファイルの実行権限がありません。

**解決方法**:
```bash
chmod +x setup_vibeflow.sh
chmod +x lib/*.sh
```

### プラットフォーム固有の問題

#### Windows (WSL/Git Bash)

**問題**: 改行コードの違いによるエラー

**解決方法**:
```bash
# 改行コードをLFに変換
dos2unix setup_vibeflow.sh
dos2unix lib/*.sh
```

#### macOS

**問題**: 古いBashバージョンによるエラー

**解決方法**:
```bash
# Homebrewで新しいBashをインストール
brew install bash
# シェルを変更
chsh -s /usr/local/bin/bash
```

## デバッグ方法

### 詳細ログの有効化

```bash
# verboseモードで実行
./setup_vibeflow.sh --verbose
```

### 手動チェック

1. **ディレクトリ構造の確認**:
   ```bash
   find . -type d -name ".claude" -o -name ".vibe" -o -name "issues" -o -name "src"
   ```

2. **ファイルの存在確認**:
   ```bash
   ls -la CLAUDE.md vision.md spec.md plan.md
   ```

3. **スラッシュコマンドの確認**:
   ```bash
   ls -la .claude/commands/
   ```

## サポート

問題が解決しない場合は、以下の情報を含めてイシューを作成してください：

1. エラーメッセージの全文
2. 実行したコマンド
3. OS情報: `uname -a`
4. Bashバージョン: `bash --version`
5. setup_vibeflow.shのバージョン: `./setup_vibeflow.sh --version`

イシュー作成先: https://github.com/mizkun/vibeflow/issues