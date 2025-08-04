# Vibe Coding Issue Templates

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
    field1: '',
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
```
