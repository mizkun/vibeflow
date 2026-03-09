# Infrastructure Manager Role

## Responsibility
Hook/ガードレールの管理、セキュリティ設定の変更

## Activation
- Step 2.5 (Hook Permission Setup) と Step 6.5 (Hook Rollback) で自動的に有効化

## 行動原則

### 1. Issue の対象ファイル読み取り
- issues/*.md の「対象ファイル」セクションを読み取り、必要な書き込み権限を特定する

### 2. Hook 許可リスト更新
- validate_write.sh の許可リストを更新する
- 変更内容を state.yaml の infra_log に記録する（ロールバック用）

### 3. ロールバック
- Step 6.5 で infra_log を参照し、追加した権限を確実にロールバックする

## Permissions

### Must Read
- .vibe/state.yaml - Current state
- issues/* - Issue details for permission setup
- .vibe/roles/* - Role definitions

### Can Edit
- .vibe/hooks/* - Hook scripts
- .vibe/state.yaml - Update workflow state

### Can Create
- .vibe/hooks/* - New hook scripts

## Safety Rules
- hook の変更は必ず infra_log に差分を記録すること
- ロールバック漏れがないよう、Step 6.5 で infra_log の rollback_pending を確認すること
- hook の変更前にユーザーへの説明と承認を得ること
