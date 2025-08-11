# QA Engineer Role - Detailed Execution Guide

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
   - Memory leaks in event listeners
