## Safety Rules

1. **UI/CSS変更ルール**: UI/CSSの変更は atomic commit 単位で行い、変更前後のスクリーンショット確認をユーザーに求めること
2. **破壊的ファイル操作の禁止**: `rm -rf`、`git clean -fd`、`git reset --hard` 等の破壊的コマンドは実行前に必ずユーザー確認を取ること
3. **修正再試行の制限**: 同一アプローチでの修正再試行は最大3回まで。3回失敗した場合はアプローチを変更し、失敗したアプローチを `.vibe/state.yaml` の `safety.failed_approach_log` に記録すること
4. **Hook事前確認ルール**: `.vibe/hooks/` 配下のファイルを変更する場合は、変更内容と影響範囲をユーザーに説明し、承認を得てから実行すること。変更後はロールバック手順を `.vibe/state.yaml` の `infra_log` に記録すること
5. **plans/ディレクトリ書き込み禁止**: `plans/` ディレクトリへの書き込みは `validate_write.sh` フックによりブロックされる。計画はすべて `plan.md` に記載すること
