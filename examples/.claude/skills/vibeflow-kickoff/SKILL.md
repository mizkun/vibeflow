---
name: vibeflow-kickoff
description: プロジェクトの Vision/Spec/Plan をキックオフ生成するスキル
---

# vibeflow-kickoff

## When to Use

- 新規プロジェクトの初回セットアップ時
- Iris 起動時にプロジェクト状態を判定して自動実行
- ユーザーが「プロジェクトを始めたい」「計画を立てたい」と言った時

## プロジェクト状態判定

1. **新規プロジェクト (scratch)**: `vision.md`, `spec.md`, `plan.md` のいずれかが存在しない、または空
2. **既存プロジェクト (existing)**: 3ファイルとも存在し内容がある → 読み込みモード

## Instructions

### 新規プロジェクトの場合

対話的に Vision → Spec → Plan の順で生成する。

#### Step 1: Vision 生成
1. ユーザーにプロダクトのゴール・ターゲットユーザー・価値提案をヒアリング
2. `vision.md` を生成:
   - プロダクトビジョン
   - ターゲットユーザー
   - 解決する課題
   - 成功指標
3. ユーザーに確認・修正を促す

#### Step 2: Spec 生成
1. Vision を参照し、技術的な仕様を対話的に策定
2. `spec.md` を生成:
   - システムアーキテクチャ
   - 技術スタック
   - API 設計（概要）
   - データモデル（概要）
   - 非機能要件
3. ユーザーに確認・修正を促す

#### Step 3: Plan 生成
1. Vision + Spec を参照し、ロードマップを策定
2. `plan.md` を生成:
   - マイルストーン一覧
   - 各マイルストーンの Issue 候補
   - 優先順位
   - 依存関係
3. ユーザーに確認・修正を促す

### 既存プロジェクトの場合

1. `vision.md`, `spec.md`, `plan.md` を読み込み
2. `.vibe/context/STATUS.md` を読み込み（存在すれば）
3. GitHub open Issues を確認 (`gh issue list`)
4. 現状のサマリをユーザーに報告:
   - 直近のアクティビティ
   - 未完了の Issue 数
   - 次のアクション候補

### 生成後の振る舞い

- 生成した Vision/Spec/Plan は常に参照しながら行動する
- Issue 作成時は Plan のマイルストーンと紐付ける
- 技術的判断は Spec を根拠にする
- ゴール設定は Vision に立ち返る
