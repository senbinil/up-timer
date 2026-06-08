# Agent Workflow (STRICT MODE)

This document defines the mandatory execution workflow for the agent.

---

## 🚨 CORE PRINCIPLE

- The agent MUST follow this workflow exactly.
- NO step may be skipped or reordered.
- NO implicit assumptions are allowed.
- The agent MAY ONLY deviate if the user explicitly overrides a rule in writing.

---

# 🧠 AGENT SKILLS (REQUIRED CAPABILITIES)

The agent MUST be capable of:

## 1. Requirement Analysis
- Interpreting user intent accurately
- Extracting functional + non-functional requirements
- Identifying missing or ambiguous requirements

## 2. System Design Thinking
- Breaking problems into modular components
- Designing scalable and maintainable solutions
- Identifying dependencies and integration points

## 3. Code Implementation
- Writing clean, production-grade code
- Following existing project conventions
- Minimizing side effects
- Keeping changes scoped strictly to plan

## 4. Debugging & Problem Solving
- Identifying root causes of issues
- Tracing errors logically
- Avoiding guess-based fixes

## 5. Git & Version Control
- Working with feature branches only after approval
- Writing structured commit messages
- Avoiding premature commits or pushes

## 6. Verification & Testing
- Validating logic correctness
- Running or reasoning about tests
- Detecting regressions before commit

---

# 🔁 WORKFLOW (MANDATORY SEQUENCE)

## 1. 🧠 PLANNING PHASE (READ ONLY)

### Rules:
- Understand full requirement
- Break task into explicit steps
- Identify files/modules impacted
- Identify risks and edge cases
- Propose implementation strategy

### Hard Constraints:
- ❌ NO code changes
- ❌ NO branch changes
- ❌ NO commits
- ❌ NO implementation work

### Output Requirement:
Must produce a structured plan for user approval.

---

## 2. ✋ USER APPROVAL (PLAN GATE)

### Rules:
- Agent MUST STOP and wait
- No further action allowed until approval is received

### Valid responses:
- `approve` → proceed
- `change plan` → revise plan and return to Planning Phase

### Hard Constraint:
- ❌ NO proceeding without explicit approval

---

## 3. 🌿 FEATURE BRANCH SWITCH (ONLY AFTER APPROVAL)

### Condition:
- ONLY after plan approval

### Rules:
- Switch to feature branch before implementation

### Branch naming:
feature/<short-description>


### Hard Constraints:
- ❌ NEVER switch before approval
- ❌ NEVER implement before branch switch

---

## 4. ⚙️ IMPLEMENTATION PHASE

### Rules:
- Implement ONLY approved plan
- Follow existing project structure and conventions
- Keep scope minimal and controlled

### Hard Constraints:
- ❌ NO scope creep
- ❌ NO unrelated refactors
- ❌ NO dependency changes unless approved
- ❌ NO architecture changes unless approved

---

## 5. 🔍 VERIFICATION PHASE

### Rules:
- Validate correctness of implementation
- Ensure alignment with approved plan
- Run lint/tests if available
- Check regressions

### Hard Constraints:
- ❌ NO skipping verification
- ❌ NO preparing commit without verification

---

## 6. ✋ FINAL USER APPROVAL (BEFORE COMMIT)

### Rules:
- Provide:
  - Summary of changes
  - List of modified files
  - Impact description
- Wait for explicit approval

### Hard Constraints:
- ❌ NO commit without approval
- ❌ NO push without approval

---

## 7. 🚀 COMMIT & PUSH (FINAL STEP ONLY)

### Rules:
- Commit ONLY after final approval
- Push ONLY after commit

### Commit format:

type(scope): description


Example:

feat(auth): implement JWT refresh flow
fix(api): handle null responses safely


---

# ⚠️ GLOBAL RULES (NON-NEGOTIABLE)

- Workflow steps MUST be followed in order
- Agent MUST stop at every approval gate
- Agent MUST NOT assume approval
- Agent MUST NOT auto-switch branches
- Agent MUST NOT auto-commit or push
- Agent MUST NOT exceed defined scope
- Agent MUST NOT modify unrelated code
- Agent MUST NOT bypass verification

---

# 🚫 OVERRIDE POLICY

Rules may ONLY be bypassed if:

- User explicitly writes: `override workflow rule`
OR
- User explicitly specifies the step to skip/modify

Otherwise:
➡️ FULL STRICT MODE ENFORCED

# 💎 RVM & Gemset Rules

The agent MUST use the project's configured Ruby version and gemset before executing any Ruby-related command.

## Startup Procedure

When entering a Ruby/Rails project:

1. Check for:
   - `.ruby-version`
   - `.ruby-gemset`
   - `.rvmrc`
   - Project documentation

2. Activate both the Ruby version and gemset.

Example:

```bash
rvm use ruby-4.0.5@up-timer

# .agentignore Compliance

The agent MUST respect `.agentignore`.

Rules:

- Do not read ignored files unless explicitly requested.
- Do not modify ignored files unless explicitly requested.
- Do not include ignored files in plans, diffs, commits, or summaries.
- Treat ignored files as out-of-scope.
- If a task requires an ignored file, request user approval before accessing it.