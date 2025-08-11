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
    
    # Create role documentation
    create_role_documents
    
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
current_role: "Product Manager"
last_role_transition: null
last_completed_step: null
next_step: 2_issue_breakdown

# Human checkpoint status
checkpoint_status:
  2a_issue_validation: pending
  7a_runnable_check: pending

# Issues tracking
issues_created: []
issues_completed: []

'
    
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

# Create role documentation
create_role_documents() {
    info "ロール別ドキュメントを作成中..."
    
    create_product_manager_doc
    create_engineer_doc
    create_qa_engineer_doc
    
    success "ロール別ドキュメントの作成が完了しました"
}

# Create Product Manager role documentation
create_product_manager_doc() {
    local content='# Product Manager Role - Detailed Execution Guide

## Role Overview
As a Product Manager, you are responsible for maintaining alignment between the product vision, specifications, and development plan. You ensure that all development work contributes to the product goals and that issues are clearly defined for implementation.

## Step 1: Plan Review

### Objective
Review current progress against the vision and specifications, then update the development plan accordingly.

### Execution Process

1. **Load Current Context**
   - Read `.vibe/state.yaml` to understand current cycle and progress
   - Note any previously completed issues

2. **MANDATORY Context Reading** (in this order):
   - **vision.md**: Understand the product goals and value proposition
   - **spec.md**: Review all functional and technical requirements
   - **plan.md**: Check current progress and TODO items
   - **qa-reports/** (if exists): Review any QA findings that might impact planning

3. **Progress Analysis**
   - Compare completed items in plan.md against actual delivered features
   - Identify any gaps between plan and implementation
   - Note any technical debt or quality issues from QA reports

4. **Plan Update**
   - Move completed items to "## Completed" section with dates
   - Update TODO list based on:
     - Remaining features from spec.md
     - New discoveries from completed work
     - QA feedback and quality improvements needed
   - Prioritize items based on:
     - User value (from vision.md)
     - Technical dependencies
     - Risk and complexity

5. **Save Updated Plan**
   ```markdown
   ## Completed
   - [x] Feature A (2024-01-15) - Successfully implemented user auth
   - [x] Feature B (2024-01-16) - Database schema created
   
   ## TODO
   ### High Priority
   - [ ] Feature C - Critical for MVP
   - [ ] Bug fix from QA report #001
   
   ### Medium Priority
   - [ ] Feature D - Nice to have for v1
   ```

6. **State Update**
   - Update `.vibe/state.yaml` with current step completion
   - Record any important decisions or changes

## Step 2: Issue Breakdown

### Objective
Transform high-level plan items into detailed, implementable issues that engineers can execute without ambiguity.

### Execution Process

1. **Select Items from Plan**
   - Choose 3-5 items from TODO list (manageable sprint size)
   - Consider engineer capacity and complexity

2. **For Each Selected Item**:

   a. **Verify Alignment**
      - Does it contribute to vision.md goals?
      - Is it covered in spec.md requirements?
      - Are there technical dependencies?

   b. **Create Detailed Issue File**
      - File naming: `issues/issue-{number:03d}-{description}.md`
      - Example: `issues/issue-001-user-authentication.md`

   c. **Issue Content Structure**:
      ```markdown
      # Issue #001: User Authentication Implementation
      
      ## Overview
      Implement secure user authentication using Firebase Auth as specified in spec.md section 3.2
      
      ## Requirements
      - Users can register with email/password
      - Users can login with existing credentials
      - Session management with JWT tokens
      - Password reset functionality
      
      ## Technical Details
      - Framework: Firebase Auth SDK
      - Token storage: Secure HTTP-only cookies
      - Password requirements: Min 8 chars, 1 uppercase, 1 number
      
      ## Acceptance Criteria
      - [ ] Registration endpoint creates new user in Firebase
      - [ ] Login endpoint returns valid JWT token
      - [ ] Protected routes require valid authentication
      - [ ] Password reset sends email with reset link
      - [ ] All auth endpoints have rate limiting
      
      ## Implementation Hints
      - Use Firebase Admin SDK for backend
      - Implement middleware for route protection
      - Store user profile in Firestore after registration
      
      ## File Locations
      - Backend auth logic: `src/auth/`
      - Middleware: `src/middleware/authMiddleware.js`
      - Frontend forms: `src/components/auth/`
      
      ## Testing Requirements
      - Unit tests for all auth functions
      - Integration tests for auth flow
      - E2E test for complete user journey
      
      ## Estimated Effort
      3-4 hours
      
      ## Dependencies
      - Firebase project setup (already complete)
      - Environment variables configured
      ```

3. **Cross-Reference Issues**
   - Ensure no duplicate work
   - Check dependencies between issues
   - Verify completeness against spec.md

4. **Priority Assignment**
   - P0: Blockers for other work
   - P1: Core functionality
   - P2: Enhancements
   - P3: Nice-to-have

5. **Final Checklist**
   - [ ] Each issue is self-contained and completable
   - [ ] All acceptance criteria are testable
   - [ ] Technical approach is clear
   - [ ] File locations are specified
   - [ ] No critical information is missing

## Step 2a: Issue Validation (Human Checkpoint)

### Preparation for Human Review

1. **Update State**
   ```yaml
   current_step: 2a_issue_validation
   checkpoint_status:
     2a_issue_validation: pending
   issues_created: 
     - issue-001-user-authentication.md
     - issue-002-dashboard-layout.md
     - issue-003-api-integration.md
   ```

2. **Display Summary**
   ```
   ✅ 今回のスプリント用に 3 個のIssueを作成しました：
   
   1. issue-001: User Authentication (P0) - 3-4 hours
   2. issue-002: Dashboard Layout (P1) - 2-3 hours  
   3. issue-003: API Integration (P1) - 4-5 hours
   
   合計見積もり時間: 9-12 hours
   
   確認して問題なければ「続けて」と言ってください。
   修正が必要な場合は具体的な指示をお願いします。
   ```

## Common Pitfalls to Avoid

1. **Creating Vague Issues**
   ❌ "Implement user feature"
   ✅ "Implement user registration with email validation using Firebase Auth"

2. **Missing Technical Details**
   ❌ "Add authentication"
   ✅ "Add JWT-based authentication with refresh token rotation"

3. **Untestable Acceptance Criteria**
   ❌ "System should work properly"
   ✅ "Login endpoint returns 200 status with valid JWT token"

4. **Ignoring Specifications**
   ❌ Creating issues based on assumptions
   ✅ Creating issues that reference specific sections of spec.md

5. **Poor Time Estimates**
   ❌ Not providing estimates or unrealistic ones
   ✅ Breaking down work to 1-4 hour chunks

## Quality Checklist

Before completing PM tasks:
- [ ] All issues align with product vision
- [ ] Technical approach matches spec.md
- [ ] Issues are detailed enough for engineers
- [ ] Dependencies are identified
- [ ] Time estimates are realistic
- [ ] Plan.md is up to date
- [ ] State.yaml reflects current status'
    
    create_file_with_backup ".vibe/roles/product-manager.md" "$content"
}

# Create Engineer role documentation
create_engineer_doc() {
    local content='# Engineer Role - Detailed Execution Guide

## Role Overview
As an Engineer, you are responsible for implementing features, writing tests, and maintaining code quality. You follow Test-Driven Development (TDD) practices and ensure all implementations meet the specified requirements.

## Step 3: Branch Creation

### Objective
Create a feature branch for implementing the current issue.

### Execution Process

1. **Read Current Issue**
   - Load issue from `.vibe/state.yaml` current_issue field
   - Read the complete issue file from `issues/` directory

2. **Create Feature Branch**
   ```bash
   # Branch naming convention
   git checkout -b feature/issue-{number}-{short-description}
   
   # Example
   git checkout -b feature/issue-001-user-auth
   ```

3. **Verify Branch**
   - Confirm you are on the correct branch
   - Ensure main/master is up to date before branching

## Step 4: Test Writing (TDD Red Phase)

### Objective
Write comprehensive tests that fail initially, defining the expected behavior before implementation.

### Execution Process

1. **Analyze Requirements**
   - Read acceptance criteria from the issue
   - Identify all test scenarios needed
   - Plan test structure

2. **Test Categories to Cover**
   
   a. **Unit Tests**
      - Individual function behavior
      - Edge cases and error handling
      - Input validation
   
   b. **Integration Tests**
      - Component interactions
      - API endpoint testing
      - Database operations
   
   c. **E2E Tests** (if applicable)
      - User workflows
      - Critical paths

3. **Write Test Files**
   
   Example for authentication:
   ```javascript
   // src/auth/__tests__/auth.test.js
   
   describe("User Authentication", () => {
     describe("Registration", () => {
       test("should create new user with valid email/password", async () => {
         const userData = {
           email: "test@example.com",
           password: "SecurePass123"
         };
         
         const result = await registerUser(userData);
         
         expect(result.success).toBe(true);
         expect(result.user.email).toBe(userData.email);
         expect(result.token).toBeDefined();
       });
       
       test("should reject weak passwords", async () => {
         const userData = {
           email: "test@example.com",
           password: "weak"
         };
         
         await expect(registerUser(userData))
           .rejects.toThrow("Password does not meet requirements");
       });
       
       test("should prevent duplicate email registration", async () => {
         // First registration
         await registerUser({
           email: "existing@example.com",
           password: "SecurePass123"
         });
         
         // Attempt duplicate
         await expect(registerUser({
           email: "existing@example.com",
           password: "AnotherPass123"
         })).rejects.toThrow("Email already registered");
       });
     });
     
     describe("Login", () => {
       test("should authenticate valid credentials", async () => {
         // Test implementation
       });
       
       test("should reject invalid credentials", async () => {
         // Test implementation
       });
     });
   });
   ```

4. **Run Tests to Confirm Failure**
   ```bash
   npm test
   # or
   jest src/auth/__tests__/auth.test.js
   ```
   
   Expected output: All tests should fail with errors like:
   - "registerUser is not defined"
   - "Cannot find module"

5. **Commit Test Files**
   ```bash
   git add .
   git commit -m "test: Add failing tests for user authentication (TDD Red)"
   ```

## Step 5: Implementation (TDD Green Phase)

### Objective
Write the minimal code necessary to make all tests pass.

### Execution Process

1. **Start with Simplest Test**
   - Implement just enough to pass one test
   - Run tests frequently
   - Don'"'"'t over-engineer at this stage

2. **Progressive Implementation**
   
   Example progression:
   ```javascript
   // Step 1: Make function exist
   function registerUser(userData) {
     return Promise.resolve({ success: false });
   }
   
   // Step 2: Make basic case work
   function registerUser(userData) {
     return Promise.resolve({
       success: true,
       user: { email: userData.email },
       token: "dummy-token"
     });
   }
   
   // Step 3: Add validation
   function registerUser(userData) {
     if (userData.password.length < 8) {
       return Promise.reject(new Error("Password does not meet requirements"));
     }
     // ... rest of implementation
   }
   ```

3. **Run Tests Continuously**
   - After each small change
   - Fix one test at a time
   - Don'"'"'t move on until current test passes

4. **Handle Edge Cases**
   - Implement error scenarios
   - Add input validation
   - Handle async operations properly

5. **Verify All Tests Pass**
   ```bash
   npm test
   # All tests should show green/passing
   ```

6. **Commit Implementation**
   ```bash
   git add .
   git commit -m "feat: Implement user authentication (TDD Green)"
   ```

## Step 6: Refactoring (TDD Refactor Phase)

### Objective
Improve code quality, structure, and maintainability while keeping all tests green.

### Execution Process

1. **Code Improvements**
   
   a. **Extract Functions**
      ```javascript
      // Before
      function registerUser(userData) {
        // 50 lines of mixed validation and logic
      }
      
      // After
      function registerUser(userData) {
        validateUserData(userData);
        const hashedPassword = await hashPassword(userData.password);
        const user = await createUserInDatabase(userData.email, hashedPassword);
        const token = generateAuthToken(user.id);
        return { success: true, user, token };
      }
      ```
   
   b. **Improve Naming**
      - Use descriptive variable names
      - Follow project conventions
      - Make intent clear
   
   c. **Remove Duplication**
      - Extract common patterns
      - Create utility functions
      - Use configuration objects

2. **Performance Optimization**
   - Add caching where appropriate
   - Optimize database queries
   - Reduce unnecessary operations

3. **Error Handling**
   ```javascript
   try {
     // operation
   } catch (error) {
     logger.error("Registration failed:", error);
     throw new CustomError("REGISTRATION_FAILED", error.message);
   }
   ```

4. **Add Comments (only where necessary)**
   ```javascript
   // Firebase Admin SDK requires service account credentials
   // These are loaded from environment variables for security
   const firebaseAdmin = initializeAdmin({
     credential: getServiceAccountFromEnv()
   });
   ```

5. **Run Tests After Each Change**
   - Ensure refactoring doesn'"'"'t break functionality
   - All tests must remain green

6. **Final Code Review**
   - Check against coding standards
   - Verify all acceptance criteria met
   - Ensure good test coverage

7. **Commit Refactored Code**
   ```bash
   git add .
   git commit -m "refactor: Improve auth code structure and error handling"
   ```

## Step 8: Pull Request Creation

### Objective
Create a comprehensive PR with all changes, documentation, and context for review.

### Execution Process

1. **Ensure All Changes Committed**
   ```bash
   git status
   git add .
   git commit -m "final: Complete issue-001 implementation"
   ```

2. **Push Branch**
   ```bash
   git push -u origin feature/issue-001-user-auth
   ```

3. **Create PR via GitHub CLI**
   ```bash
   gh pr create \
     --title "feat: Implement user authentication (Issue #001)" \
     --body "## Summary
     
     Implements complete user authentication system using Firebase Auth.
     
     ## Changes
     - User registration with email/password
     - Login functionality with JWT tokens
     - Password reset via email
     - Session management
     - Rate limiting on auth endpoints
     
     ## Testing
     - ✅ All unit tests passing (15/15)
     - ✅ Integration tests passing (8/8)
     - ✅ Manual testing completed
     
     ## Checklist
     - [x] Tests written and passing
     - [x] Code follows project style
     - [x] Documentation updated
     - [x] No console.logs in production code
     - [x] Security review completed
     
     Closes #001"
   ```

## Step 10: Merge

### Objective
Merge approved PR into main branch after all checks pass.

### Execution Process

1. **Pre-merge Checks**
   - All CI/CD pipelines passing
   - Required approvals received
   - No merge conflicts

2. **Merge Strategy**
   ```bash
   # Squash and merge for clean history
   gh pr merge --squash
   
   # Or regular merge if preserving commit history
   gh pr merge --merge
   ```

3. **Post-merge Cleanup**
   ```bash
   # Delete local feature branch
   git checkout main
   git pull origin main
   git branch -d feature/issue-001-user-auth
   
   # Delete remote branch (if not auto-deleted)
   git push origin --delete feature/issue-001-user-auth
   ```

## Step 11: Deployment

### Objective
Deploy merged changes to production environment.

### Execution Process

1. **Deployment Preparation**
   - Verify all tests pass on main
   - Check deployment prerequisites
   - Review deployment checklist

2. **Execute Deployment**
   ```bash
   # Example deployment commands
   npm run build
   npm run deploy:production
   
   # Or using CI/CD
   git tag -a v1.2.0 -m "Release: User authentication"
   git push origin v1.2.0
   ```

3. **Verify Deployment**
   - Check application health
   - Verify new features working
   - Monitor for errors

## Best Practices

1. **Commit Message Format**
   - `feat:` New feature
   - `fix:` Bug fix
   - `refactor:` Code improvement
   - `test:` Test additions/changes
   - `docs:` Documentation updates

2. **Code Quality Standards**
   - No commented-out code
   - No console.logs in production
   - Consistent formatting
   - Meaningful variable names

3. **Testing Philosophy**
   - Test behavior, not implementation
   - Cover edge cases
   - Keep tests simple and readable
   - One assertion per test when possible

4. **Security Considerations**
   - Never commit secrets
   - Validate all inputs
   - Use parameterized queries
   - Follow OWASP guidelines'
    
    create_file_with_backup ".vibe/roles/engineer.md" "$content"
}

# Create QA Engineer role documentation
create_qa_engineer_doc() {
    local content='# QA Engineer Role - Detailed Execution Guide

## Role Overview
As a QA Engineer, you are responsible for ensuring code quality, verifying requirements are met, and maintaining high standards throughout the development process. You act as the quality gatekeeper before code reaches production.

## Step 6a: Code Sanity Check

### Objective
Perform automated quality checks on the implemented code to catch obvious issues before deeper testing.

### Execution Process

1. **Load Current Context**
   - Read `.vibe/state.yaml` for current issue
   - Identify which files were modified

2. **Automated Checks**
   
   a. **Linting**
   ```bash
   # JavaScript/TypeScript
   npm run lint
   eslint src/ --ext .js,.jsx,.ts,.tsx
   
   # Python
   pylint src/
   flake8 src/
   
   # Record results
   echo "Lint check: PASS/FAIL" >> .vibe/test-results.log
   ```
   
   b. **Type Checking** (if applicable)
   ```bash
   # TypeScript
   npm run typecheck
   tsc --noEmit
   
   # Python
   mypy src/
   ```
   
   c. **Security Scan**
   ```bash
   # npm audit for dependencies
   npm audit
   
   # Check for common vulnerabilities
   # - Hardcoded secrets
   # - SQL injection risks
   # - XSS vulnerabilities
   ```

3. **Code Review Checklist**
   - [ ] No console.log/print statements in production code
   - [ ] No commented-out code blocks
   - [ ] No TODO comments without issue references
   - [ ] No hardcoded credentials or API keys
   - [ ] Error handling is present
   - [ ] Input validation exists

4. **Test Coverage Check**
   ```bash
   # Generate coverage report
   npm test -- --coverage
   
   # Check coverage thresholds
   # Minimum acceptable: 80% overall
   # Critical paths: 95%+
   ```

5. **Decision Point**
   
   If major issues found:
   ```yaml
   # Update state.yaml
   current_step: 6_refactoring
   qa_findings:
     - "Multiple lint errors in auth module"
     - "Type errors in user interface"
     - "Missing error handling in API calls"
   ```
   
   If minor/no issues:
   ```yaml
   # Proceed to acceptance testing
   current_step: 7_acceptance_test
   sanity_check: passed
   ```

## Step 7: Acceptance Test

### Objective
Verify that the implementation meets all requirements specified in the issue and aligns with product specifications.

### Execution Process

1. **Requirement Mapping**
   
   Read the issue file and create a verification checklist:
   ```markdown
   ## Issue #001 Acceptance Verification
   
   ### Functional Requirements
   - [ ] User can register with email/password
   - [ ] User can login with valid credentials
   - [ ] User receives error for invalid credentials
   - [ ] Password reset sends email
   - [ ] Session persists after page refresh
   
   ### Non-Functional Requirements
   - [ ] Response time < 2 seconds
   - [ ] Supports 100 concurrent users
   - [ ] Works on Chrome, Firefox, Safari
   - [ ] Mobile responsive
   ```

2. **Test Execution**
   
   a. **Run Unit Tests**
   ```bash
   npm test src/auth/
   # Record: 15/15 tests passing ✅
   ```
   
   b. **Run Integration Tests**
   ```bash
   npm test:integration
   # Record: 8/8 tests passing ✅
   ```
   
   c. **Run E2E Tests** (if available)
   ```bash
   npm run test:e2e
   # Or with Playwright
   npx playwright test
   ```

3. **Manual Testing Scenarios**
   
   Document each scenario tested:
   ```markdown
   ## Manual Test Results
   
   ### Scenario 1: New User Registration
   Steps:
   1. Navigate to /register
   2. Enter email: test@example.com
   3. Enter password: SecurePass123
   4. Click "Register"
   
   Expected: User created, redirected to dashboard
   Actual: ✅ As expected
   
   ### Scenario 2: Duplicate Email
   Steps:
   1. Try registering with same email
   
   Expected: Error message "Email already exists"
   Actual: ✅ As expected
   
   ### Scenario 3: Weak Password
   Steps:
   1. Enter password: "123"
   
   Expected: Error "Password must be 8+ characters"
   Actual: ❌ No error shown
   ```

4. **Cross-Browser Testing**
   ```markdown
   ## Browser Compatibility
   - Chrome 120: ✅ All features working
   - Firefox 121: ✅ All features working
   - Safari 17: ⚠️ CSS alignment issue on form
   - Edge: ✅ All features working
   ```

5. **Performance Testing**
   ```bash
   # Load testing
   npm run test:load
   
   # Results:
   # - Average response time: 250ms ✅
   # - 99th percentile: 800ms ✅
   # - Error rate: 0% ✅
   ```

6. **Create QA Report**
   
   File: `.vibe/qa-reports/issue-001-qa-report.md`
   ```markdown
   # QA Report: Issue #001 - User Authentication
   
   ## Test Summary
   - **Date**: 2024-01-20
   - **Tester**: QA Engineer
   - **Issue**: #001 User Authentication
   - **Result**: PASS with minor issues
   
   ## Test Coverage
   - Unit Tests: 15/15 ✅
   - Integration Tests: 8/8 ✅
   - E2E Tests: 5/5 ✅
   - Manual Tests: 10/12 ⚠️
   
   ## Findings
   
   ### Critical Issues
   None
   
   ### Major Issues
   None
   
   ### Minor Issues
   1. CSS alignment issue on Safari
   2. Password error message not showing on first attempt
   
   ## Performance Metrics
   - Login Time: 250ms average ✅
   - Registration Time: 400ms average ✅
   - Token Refresh: 100ms average ✅
   
   ## Security Review
   - [x] No hardcoded credentials
   - [x] Passwords hashed with bcrypt
   - [x] JWT tokens expire appropriately
   - [x] Rate limiting implemented
   - [x] Input sanitization present
   
   ## Recommendations
   1. Fix Safari CSS issue before production
   2. Improve password validation UX
   
   ## Approval Status
   ✅ APPROVED for merge with noted minor fixes
   ```

## Step 7a: Runnable Check (Human Checkpoint)

### Preparation for Human Testing

1. **Setup Test Environment**
   ```bash
   # Ensure application is running
   npm run dev
   # Application running at http://localhost:3000
   ```

2. **Prepare Test Guide**
   ```markdown
   🧪 Manual Testing Required
   
   Application is running at: http://localhost:3000
   
   Please test the following features:
   
   1. User Registration
      - Go to /register
      - Create a new account
      - Verify email confirmation
   
   2. User Login
      - Go to /login
      - Use the account you created
      - Verify dashboard access
   
   3. Password Reset
      - Click "Forgot Password"
      - Enter your email
      - Check email for reset link
   
   4. Session Management
      - Refresh the page
      - Verify you stay logged in
      - Try accessing protected route
   
   Test Credentials (if needed):
   - Email: test@example.com
   - Password: TestPass123
   
   ✅ If everything works, respond with "OK" or "動作確認OK"
   ❌ If issues found, describe them in detail
   ```

3. **Update State for Checkpoint**
   ```yaml
   current_step: 7a_runnable_check
   checkpoint_status:
     7a_runnable_check: pending
   qa_status: automated_tests_passed
   manual_testing: required
   ```

## Step 9: Code Review

### Objective
Perform thorough code review of the pull request to ensure quality, maintainability, and adherence to standards.

### Execution Process

1. **Review Checklist**
   
   a. **Code Quality**
   - [ ] Code is readable and self-documenting
   - [ ] Functions are small and focused
   - [ ] No code duplication
   - [ ] Consistent naming conventions
   - [ ] Appropriate abstractions
   
   b. **Architecture**
   - [ ] Follows project structure
   - [ ] Proper separation of concerns
   - [ ] No tight coupling
   - [ ] Scalable approach
   
   c. **Security**
   - [ ] Input validation present
   - [ ] No SQL injection vulnerabilities
   - [ ] No XSS vulnerabilities
   - [ ] Proper authentication/authorization
   - [ ] Secrets properly managed
   
   d. **Performance**
   - [ ] No N+1 queries
   - [ ] Appropriate caching
   - [ ] Efficient algorithms
   - [ ] No memory leaks
   
   e. **Testing**
   - [ ] Adequate test coverage
   - [ ] Tests are meaningful
   - [ ] Edge cases covered
   - [ ] Tests are maintainable

2. **Review Comments**
   
   Provide constructive feedback:
   ```markdown
   ## Code Review Comments
   
   ### Positive Feedback
   - Excellent test coverage ✅
   - Clean separation of concerns ✅
   - Good error handling ✅
   
   ### Suggestions for Improvement
   
   **File: src/auth/register.js:45**
   ```javascript
   // Current
   if (password.length < 8) throw new Error("Bad password");
   
   // Suggested
   if (password.length < 8) {
     throw new ValidationError("Password must be at least 8 characters", "PASSWORD_TOO_SHORT");
   }
   ```
   *Reason: More specific error types help with debugging and user feedback*
   
   **File: src/auth/token.js:23**
   Consider extracting TOKEN_EXPIRY to configuration file for easier management.
   
   ### Required Changes
   1. Remove console.log on line 67 of auth.js
   2. Add rate limiting to password reset endpoint
   ```

3. **Approval Decision**
   
   **Approve**: All critical requirements met, only minor suggestions
   ```bash
   gh pr review --approve --body "LGTM! Great implementation. Minor suggestions above can be addressed in follow-up."
   ```
   
   **Request Changes**: Critical issues found
   ```bash
   gh pr review --request-changes --body "Found security issue with password storage. Please address before merging."
   ```
   
   **Comment**: Need clarification
   ```bash
   gh pr review --comment --body "Can you explain the reasoning behind the token refresh strategy?"
   ```

## Quality Standards

### Test Quality Indicators
- Tests should be independent
- Test names clearly describe what is being tested
- Assertions are specific and meaningful
- No flaky tests (random failures)
- Fast execution (< 10 seconds for unit tests)

### Code Quality Indicators
- Functions < 50 lines
- Files < 300 lines
- Cyclomatic complexity < 10
- No nested callbacks > 3 levels
- Clear variable/function names

### Documentation Requirements
- API endpoints documented
- Complex logic has comments
- README updated if needed
- Configuration changes documented
- Breaking changes noted

## Common QA Findings

1. **Missing Error Handling**
   ```javascript
   // Bad
   async function getData() {
     const result = await fetch(url);
     return result.json();
   }
   
   // Good
   async function getData() {
     try {
       const result = await fetch(url);
       if (!result.ok) throw new Error(`HTTP ${result.status}`);
       return result.json();
     } catch (error) {
       logger.error("Failed to fetch data:", error);
       throw new DataFetchError(error.message);
     }
   }
   ```

2. **Inadequate Input Validation**
   ```javascript
   // Bad
   function createUser(email, password) {
     return db.create({ email, password });
   }
   
   // Good
   function createUser(email, password) {
     if (!isValidEmail(email)) throw new ValidationError("Invalid email");
     if (!isStrongPassword(password)) throw new ValidationError("Weak password");
     const sanitizedEmail = sanitize(email.toLowerCase());
     const hashedPassword = await hash(password);
     return db.create({ email: sanitizedEmail, password: hashedPassword });
   }
   ```

3. **Poor Test Coverage**
   - Missing edge cases
   - No error scenario tests
   - Untested async operations
   - No integration tests

4. **Performance Issues**
   - Unnecessary database calls
   - Missing indexes
   - Inefficient loops
   - Memory leaks in event listeners'
    
    create_file_with_backup ".vibe/roles/qa-engineer.md" "$content"
}

# Main function (called if script is run directly)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    create_templates
fi