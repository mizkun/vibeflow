## Development Workflow

### Phase Structure

Discovery Phase (outside cycle: /discuss, /conclude)
  → Role: Discussion Partner
  → All files read-only, .vibe/discussions/ only for recording
  → /conclude to finalize → reflect to vision.md / spec.md / plan.md

Development Cycle (/next to progress)

### Execution Modes

Each step has a mode:
- **solo**: Main agent executes directly (default)
- **team**: Agent Team spawns multiple perspectives (requires CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1)
- **fork**: context: fork delegates to separate agent inheriting PM context (requires Claude Code 2.1.20+)

Agent Team / fork automatically falls back to solo if unavailable.

### Development Cycle Steps

#### Step 1: Plan Review
- Role: Product Manager | Mode: solo

#### Step 2: Issue Breakdown
- Role: Product Manager | Mode: team
- Team: Lead=PM, Teammates=[Technical Feasibility Analyst, UX Critic, Devil's Advocate]
- Checkpoint: 2a_human_validation (required)

#### Step 2.5: Hook Permission Setup
- Role: Infrastructure Manager | Mode: solo (auto-inserted after step 2a)

#### Step 3: Branch Creation
- Role: Engineer | Mode: solo

#### Step 4: Test Writing (TDD Red)
- Role: Engineer | Mode: fork

#### Step 5: Implementation (TDD Green)
- Role: Engineer | Mode: fork

#### Step 6: Refactoring (TDD Refactor)
- Role: Engineer | Mode: fork
- Checkpoint: 6a_code_sanity_check (automated)

#### Step 6.5: Hook Rollback
- Role: Infrastructure Manager | Mode: solo (auto-inserted after step 6a)

#### Step 7: Acceptance Test
- Role: QA Engineer | Mode: team
- Team: Lead=QA Lead, Teammates=[Spec Compliance Checker, Edge Case Hunter, UI Visual Verifier]
- Checkpoint: 7a_human_runnable_check (required)

#### Step 8: Pull Request
- Role: Engineer | Mode: solo

#### Step 9: Code Review
- Role: QA Engineer | Mode: team
- Team: Lead=QA Lead, Teammates=[Security Reviewer, Performance Reviewer, Test Coverage Reviewer]

#### Step 10: Merge
- Role: Engineer | Mode: solo

#### Step 11: Deployment
- Role: Engineer | Mode: solo
