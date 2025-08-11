# Engineer Role - Detailed Execution Guide

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
   - Don't over-engineer at this stage

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
   - Don't move on until current test passes

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
   - Ensure refactoring doesn't break functionality
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
   - Follow OWASP guidelines