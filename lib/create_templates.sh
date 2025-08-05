#!/bin/bash

# Vibe Coding Framework - Templates Creation
# This script creates template files and issue templates

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

# Function to create all templates
create_templates() {
    section "テンプレートファイルを作成中"
    
    # Create initial state.yaml
    create_initial_state
    
    # Create template files
    create_vision_template
    create_spec_template
    create_plan_template
    
    # Create issue templates
    create_issue_templates
    
    success "テンプレートファイルの作成が完了しました"
    return 0
}

# Create initial state.yaml
create_initial_state() {
    info "初期state.yamlを作成中..."
    
    local state_content='# Vibe Coding Framework - Current State
current_cycle: 1
current_step: 1_plan_review
current_issue: null
next_step: 2_issue_breakdown

# Human checkpoint status
checkpoint_status:
  2a_issue_validation: pending
  7a_runnable_check: pending'
    
    create_file_with_backup ".vibe/state.yaml" "$state_content"
}

# Create vision.md template
create_vision_template() {
    info "vision.md テンプレートを作成中..."
    
    local vision_content='# Product Vision

## 解決したい課題
[ここに解決したい課題を記載]

## ターゲットユーザー
[誰のためのプロダクトか記載]

## 提供する価値
[どんな価値を提供するか記載]

## プロダクトの概要
[プロダクトの簡単な説明]

## 成功の定義
[このプロダクトが成功したと言える状態]'
    
    create_file_with_backup "vision.md" "$vision_content"
}

# Create spec.md template
create_spec_template() {
    info "spec.md テンプレートを作成中..."
    
    local spec_content='# Specification Document

## 機能要件

### 必須機能
1. [機能1]
2. [機能2]
3. [機能3]

### あったら良い機能
1. [機能A]
2. [機能B]

## 非機能要件

### パフォーマンス
- [レスポンスタイムなど]

### セキュリティ
- [認証・認可など]

### 可用性
- [稼働率など]

## 技術スタック

### フロントエンド
- [例: React, Next.js]

### バックエンド
- [例: Node.js, Python]

### データベース
- [例: PostgreSQL, MongoDB]

### インフラ
- [例: AWS, Vercel]

## アーキテクチャ
[システム構成の説明]

## 制約事項
- [技術的制約]
- [ビジネス的制約]'
    
    create_file_with_backup "spec.md" "$spec_content"
}

# Create plan.md template
create_plan_template() {
    info "plan.md テンプレートを作成中..."
    
    local plan_content='# Development Plan

## マイルストーン

### Phase 1: MVP (2週間)
- [ ] 基本機能の実装
- [ ] 最小限のUI

### Phase 2: 機能拡張 (2週間)
- [ ] 追加機能の実装
- [ ] UIの改善

### Phase 3: 本番準備 (1週間)
- [ ] パフォーマンス最適化
- [ ] セキュリティ対策

## TODO リスト

### 高優先度
- [ ] [タスク1]
- [ ] [タスク2]
- [ ] [タスク3]

### 中優先度
- [ ] [タスクA]
- [ ] [タスクB]

### 低優先度
- [ ] [タスクX]
- [ ] [タスクY]

## 完了項目
- [x] プロジェクトセットアップ
- [x] Vibe Coding環境構築

## 次のスプリント予定
[次に取り組む予定の項目]'
    
    create_file_with_backup "plan.md" "$plan_content"
}

# Create issue templates
create_issue_templates() {
    info "Issueテンプレートを作成中..."
    
    local issue_templates='# Vibe Coding Issue Templates

## Frontend UI Issue Template

```markdown
# Issue #XXX: [具体的なコンポーネント/機能名]

## Overview
[1-2文で何を作るか明確に記述]

## Detailed Specifications

### Visual Design
- **レイアウト**: [具体的な配置。可能ならASCII図やwireframe]
- **カラー**: [具体的な色指定 例: primary=#1976d2]
- **スペーシング**: [margin/padding 例: 16px grid system]
- **タイポグラフィ**: [フォントサイズ、weight]

### Component Structure
```
ComponentName/
├── index.tsx          # メインコンポーネント
├── styles.ts          # スタイル定義
├── types.ts           # TypeScript型定義
└── hooks/             # カスタムフック
```

### State Management
```typescript
// 必要な状態の型定義
interface ComponentState {
  field1: string;
  field2: number;
  // ...
}
```

### Props Interface
```typescript
interface ComponentProps {
  prop1: string;
  prop2?: boolean;
  onEvent: (data: any) => void;
}
```

## Acceptance Criteria
- [ ] 機能要件1（具体的に測定可能な条件）
- [ ] 機能要件2
- [ ] アクセシビリティ: [具体的な要件 例: ARIA labels, keyboard navigation]
- [ ] パフォーマンス: [具体的な指標 例: First paint < 1s]

## Implementation Guide

### 使用するMUIコンポーネント
- `Box` - レイアウト用
- `TextField` - 入力用
- `Button` - アクション用
- [その他具体的なコンポーネント]

### サンプルコード
```tsx
// 基本的な実装例
const ComponentName: FC<ComponentProps> = ({ prop1, onEvent }) => {
  const [state, setState] = useState<ComponentState>({
    field1: '\'''\'',
    field2: 0
  });

  return (
    <Box sx={{ /* styles */ }}>
      {/* 実装 */}
    </Box>
  );
};
```

### エラーハンドリング
- [具体的なエラーケースと対処法]

### テストケース
1. [テストすべきシナリオ1]
2. [テストすべきシナリオ2]

## File Locations
- Component: `/src/components/ComponentName/`
- Tests: `/src/components/ComponentName/__tests__/`
- Stories: `/src/components/ComponentName/ComponentName.stories.tsx`

## Dependencies
- MUI v6
- React 18+
- TypeScript
- [その他必要なライブラリ]

## Notes
- [実装時の注意点]
- [参考リンク]
```

---

## Backend API Issue Template

```markdown
# Issue #XXX: [具体的なAPI/機能名]

## Overview
[何のためのAPIか明確に記述]

## API Specification

### Endpoint
```
METHOD /api/v1/resource
```

### Request
```typescript
interface RequestBody {
  field1: string;
  field2: number;
  field3?: boolean;
}

// サンプルリクエスト
{
  "field1": "example",
  "field2": 123,
  "field3": true
}
```

### Response
```typescript
interface SuccessResponse {
  id: string;
  data: {
    // 具体的なレスポンス構造
  };
  timestamp: string;
}

interface ErrorResponse {
  error: {
    code: string;
    message: string;
  };
}
```

### Status Codes
- `200 OK`: 成功時
- `400 Bad Request`: [具体的な条件]
- `401 Unauthorized`: [具体的な条件]
- `500 Internal Server Error`: サーバーエラー

## Acceptance Criteria
- [ ] 正常系: [具体的な条件]
- [ ] エラー処理: [各エラーケースの処理]
- [ ] バリデーション: [具体的なルール]
- [ ] パフォーマンス: [レスポンスタイム要件]

## Implementation Guide

### Database Schema
```sql
-- 必要なテーブル/コレクション定義
CREATE TABLE table_name (
  id UUID PRIMARY KEY,
  field1 VARCHAR(255) NOT NULL,
  -- ...
);
```

### Business Logic
1. [処理ステップ1]
2. [処理ステップ2]
3. [処理ステップ3]

### Validation Rules
- field1: [具体的なバリデーションルール]
- field2: [具体的なバリデーションルール]

### Security Considerations
- [ ] 認証が必要
- [ ] 認可チェック: [具体的な権限]
- [ ] Rate limiting: [具体的な制限]

## File Locations
- Route Handler: `/src/api/routes/resource.ts`
- Controller: `/src/api/controllers/resourceController.ts`
- Model: `/src/api/models/Resource.ts`
- Tests: `/src/api/__tests__/resource.test.ts`

## Dependencies
- [フレームワーク/ライブラリ]
- [データベースドライバ]

## Testing Checklist
- [ ] ユニットテスト（各関数）
- [ ] 統合テスト（API全体）
- [ ] エラーケーステスト
- [ ] パフォーマンステスト

## Notes
- [実装時の注意点]
- [関連するIssue番号]
```

---

## Feature Issue Template (Simple)

```markdown
# Issue #XXX: [機能名]

## Overview
[機能の概要]

## User Story
As a [ユーザータイプ],
I want to [やりたいこと],
So that [達成したい目的].

## Detailed Requirements

### Functional Requirements
1. [具体的な要件1]
2. [具体的な要件2]
3. [具体的な要件3]

### Non-Functional Requirements
- Performance: [具体的な指標]
- Security: [具体的な要件]
- Usability: [具体的な要件]

## Technical Specification

### Architecture
[どのレイヤーに何を実装するか]

### Data Flow
```
User Action → Component → API → Database → Response
```

### Error Handling
- [エラーケース1]: [対処法]
- [エラーケース2]: [対処法]

## Acceptance Criteria
- [ ] Given [前提条件], When [アクション], Then [期待結果]
- [ ] Given [前提条件], When [アクション], Then [期待結果]

## Implementation Checklist
- [ ] Frontend実装
  - [ ] UI component
  - [ ] State management
  - [ ] API integration
- [ ] Backend実装
  - [ ] API endpoint
  - [ ] Business logic
  - [ ] Database操作
- [ ] テスト
  - [ ] Unit tests
  - [ ] Integration tests
  - [ ] E2E tests

## Definition of Done
- [ ] コードレビュー完了
- [ ] テストがすべてパス
- [ ] ドキュメント更新
- [ ] デプロイ可能な状態

## Notes
- [参考資料]
- [注意事項]
```

---

## Bug Fix Issue Template

```markdown
# Issue #XXX: [バグの簡潔な説明]

## Bug Description
[バグの詳細な説明]

## Steps to Reproduce
1. [再現手順1]
2. [再現手順2]
3. [再現手順3]

## Expected Behavior
[期待される動作]

## Actual Behavior
[実際の動作]

## Environment
- OS: [e.g., macOS 13.0]
- Browser: [e.g., Chrome 120]
- Version: [アプリケーションのバージョン]

## Root Cause Analysis
[推定される原因]

## Proposed Solution
[修正方法の提案]

## Acceptance Criteria
- [ ] バグが再現しない
- [ ] 既存の機能に影響がない
- [ ] 適切なエラーハンドリング

## Testing
- [ ] 修正箇所のユニットテスト
- [ ] 回帰テスト
- [ ] 再現手順での動作確認

## Notes
- [関連Issue]
- [参考情報]
```'
    
    create_file_with_backup ".vibe/templates/issue-templates.md" "$issue_templates"
}

# Main function (called if script is run directly)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    create_templates
fi