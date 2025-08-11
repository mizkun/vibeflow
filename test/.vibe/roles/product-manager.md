# Product Manager Role - Detailed Execution Guide

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
- [ ] State.yaml reflects current status
