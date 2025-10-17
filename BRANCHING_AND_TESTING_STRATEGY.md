# QX Project - Branching Strategy & Testing Workflow

**Document Version:** 1.0  
**Created:** October 17, 2025  
**Status:** Active  
**Applies To:** All QX development

---

## 📋 Table of Contents

1. [Current Branch State](#current-branch-state)
2. [Branching Strategy](#branching-strategy)
3. [Testing Workflow](#testing-workflow)
4. [Integration Process](#integration-process)
5. [Quality Gates](#quality-gates)
6. [Post-Task Completion Process](#post-task-completion-process)
7. [Future Recommendations](#future-recommendations)

---

## 🌳 Current Branch State

### Branch Overview

```
main (origin/main)
  │
  └── 6be6614 - Initial commit
       │
       └── develop (origin/develop)
            │
            ├── c799e5e - Add plugins and test framework
            ├── dd40b2f - Enhance installation with rollback
            └── f651ade - Update test framework (HEAD of develop)
                 │
                 └── review-qx-develop-status (current)
                      │
                      └── c34ed4b - Add review docs and .gitignore
```

### Current State Analysis

| Branch | Commits Ahead | Status | Purpose |
|--------|---------------|--------|---------|
| `main` | 0 (baseline) | ✅ Stable | Production/baseline |
| `develop` | 3 ahead of main | ✅ Stable | Active development |
| `review-qx-develop-status` | 1 ahead of develop | 🔍 Review | Documentation review branch |

---

## 🔀 Branching Strategy

### Strategy: GitFlow-Inspired Workflow

We follow a **modified GitFlow** approach suitable for the project's current phase:

```
┌─────────────────────────────────────────────────────────────┐
│                         main                                 │
│  • Production-ready code                                     │
│  • Tagged releases (v1.0.0, v2.0.0, etc.)                   │
│  • Protected branch                                          │
└────────────────────┬────────────────────────────────────────┘
                     │ merge (via PR)
                     │
┌────────────────────▼────────────────────────────────────────┐
│                       develop                                │
│  • Integration branch for features                           │
│  • Always in deployable state                                │
│  • Protected branch (require reviews)                        │
└─────┬──────────────┬──────────────┬────────────────────────┘
      │              │              │
      │              │              └─────────────┐
      │              │                            │
┌─────▼──────┐  ┌───▼────────┐  ┌──────────┐  ┌─▼─────────┐
│  feature/  │  │  bugfix/   │  │  docs/   │  │  review/  │
│  [name]    │  │  [name]    │  │  [name]  │  │  [name]   │
└────────────┘  └────────────┘  └──────────┘  └───────────┘
```

### Branch Types

#### 1. **main** (Long-lived)
- **Purpose:** Production-ready code
- **Naming:** `main`
- **Protection:** 
  - Require pull request reviews (minimum 1 approver)
  - Require status checks to pass
  - No direct commits
- **Merge From:** `develop` (via release PRs)
- **Tagged:** Every merge is a release (semantic versioning)

#### 2. **develop** (Long-lived)
- **Purpose:** Integration branch for ongoing development
- **Naming:** `develop`
- **Protection:**
  - Require pull request reviews
  - Require passing tests
  - No direct commits (except hotfixes)
- **Merge From:** Feature branches, bugfix branches
- **State:** Always deployable to staging

#### 3. **feature/** (Short-lived)
- **Purpose:** New features and enhancements
- **Naming:** `feature/[ticket-id]-[short-description]`
  - Examples:
    - `feature/QX-123-kind-cluster-setup`
    - `feature/QX-124-user-authentication`
- **Branch From:** `develop`
- **Merge To:** `develop`
- **Lifetime:** Days to weeks
- **Deletion:** After successful merge

#### 4. **bugfix/** (Short-lived)
- **Purpose:** Bug fixes for develop branch
- **Naming:** `bugfix/[ticket-id]-[short-description]`
  - Examples:
    - `bugfix/QX-200-fix-rollback-error`
    - `bugfix/QX-201-config-parsing-crash`
- **Branch From:** `develop`
- **Merge To:** `develop`
- **Lifetime:** Hours to days
- **Deletion:** After successful merge

#### 5. **docs/** (Short-lived)
- **Purpose:** Documentation updates
- **Naming:** `docs/[description]`
  - Examples:
    - `docs/update-installation-guide`
    - `docs/api-documentation`
- **Branch From:** `develop`
- **Merge To:** `develop`
- **Lifetime:** Hours to days
- **Deletion:** After successful merge

#### 6. **review/** (Short-lived)
- **Purpose:** Code reviews, audits, status reports
- **Naming:** `review/[description]`
  - Examples:
    - `review-qx-develop-status` (current)
    - `review/security-audit-q4`
- **Branch From:** `develop` or specific feature branch
- **Merge To:** `develop` (if contains improvements)
- **Lifetime:** Hours to days
- **Deletion:** After review completion

#### 7. **hotfix/** (Short-lived)
- **Purpose:** Critical production fixes
- **Naming:** `hotfix/[ticket-id]-[short-description]`
  - Examples:
    - `hotfix/QX-999-critical-security-patch`
- **Branch From:** `main`
- **Merge To:** `main` AND `develop`
- **Lifetime:** Minutes to hours
- **Tagged:** Immediately after merge

#### 8. **release/** (Short-lived)
- **Purpose:** Prepare releases (version bump, final testing)
- **Naming:** `release/v[major].[minor].[patch]`
  - Examples:
    - `release/v1.0.0`
    - `release/v2.1.0`
- **Branch From:** `develop`
- **Merge To:** `main` AND back to `develop`
- **Lifetime:** Hours to days
- **Tagged:** After merge to main

---

## 🧪 Testing Workflow

### Testing Philosophy

> **"Test early, test often, fail fast"**

All code changes must pass through multiple testing layers before merging.

### Testing Pyramid

```
                  ┌─────────────┐
                  │   Manual    │  10% - Exploratory testing
                  │   Testing   │
                  └─────────────┘
                ┌─────────────────┐
                │  Integration    │  20% - Script workflows
                │     Tests       │
                └─────────────────┘
              ┌───────────────────────┐
              │     Unit Tests        │  70% - Function-level
              │                       │
              └───────────────────────┘
```

### Testing Types

#### 1. **Unit Tests** (Required)
- **Location:** `scripts/tests/unit/`
- **Scope:** Individual functions in isolation
- **When:** During development (TDD approach)
- **Tools:** Custom shell test framework
- **Command:** `bash scripts/run-tests.sh --unit`
- **Threshold:** 100% pass rate

**Example Test Structure:**
```bash
# File: scripts/tests/unit/test_module.sh

test_function_success_case() {
    local result=$(my_function "valid_input")
    assert_equals "expected_output" "$result"
}

test_function_error_case() {
    assert_command_fails my_function "invalid_input"
}
```

#### 2. **Integration Tests** (Required)
- **Location:** `scripts/tests/integration/`
- **Scope:** Complete workflows and script execution
- **When:** Before merging to develop
- **Tools:** Podman containers (Ubuntu 24.04)
- **Command:** `bash scripts/run-tests.sh --integration`
- **Threshold:** 100% pass rate

**Test Categories:**
- Dry-run tests (all profiles)
- Error handling tests
- Rollback mechanism tests
- End-to-end installation tests

#### 3. **Manual Testing** (Recommended)
- **Scope:** User experience, edge cases
- **When:** Before major releases
- **Environment:** Real development machines
- **Checklist:** See [Manual Testing Checklist](#manual-testing-checklist)

#### 4. **Security Testing** (Future)
- **Tools:** ShellCheck, Bandit, custom security scanners
- **Scope:** Input validation, injection attacks, privilege escalation
- **When:** Automatically on every commit (CI/CD)

#### 5. **Performance Testing** (Future)
- **Scope:** Installation time, download speeds, resource usage
- **When:** Before major releases
- **Baseline:** Track metrics over time

### Test Execution Environments

#### Local Development
```bash
# Quick unit tests (no Podman required)
bash scripts/run-tests.sh --unit

# Full test suite (requires Podman)
bash scripts/run-tests.sh --all

# Dry-run test of actual script
sudo bash scripts/install-prereqs.sh --dry-run --profile development
```

#### Podman Container (Isolated)
```bash
# Run tests in clean container
podman run --rm -it \
    -v "$(pwd):/workspace:ro" \
    ubuntu:24.04 \
    bash -c "
        apt-get update -qq && 
        apt-get install -y -qq curl unzip bc && 
        cd /workspace && 
        bash scripts/run-tests.sh --all
    "
```

#### CI/CD Pipeline (Automated)
```yaml
# Future GitHub Actions workflow
name: Test Suite
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-24.04
    steps:
      - uses: actions/checkout@v3
      - name: Run Unit Tests
        run: bash scripts/run-tests.sh --unit
      - name: Run Integration Tests
        run: bash scripts/run-tests.sh --integration
```

---

## 🔄 Integration Process

### Standard Feature Integration Flow

```
1. Create Feature Branch
   └─> git checkout -b feature/QX-123-my-feature develop

2. Develop & Test Locally
   ├─> Write code
   ├─> Write tests (TDD)
   ├─> Run unit tests
   └─> Commit frequently

3. Pre-Merge Validation
   ├─> Run full test suite
   ├─> Run dry-run tests
   ├─> Update documentation
   └─> Self-review changes

4. Push & Create PR
   ├─> Push to remote
   ├─> Create pull request to develop
   ├─> Fill PR template
   └─> Request reviews

5. Code Review Process
   ├─> Automated tests run
   ├─> Reviewers provide feedback
   ├─> Address comments
   └─> Get approvals

6. Merge to Develop
   ├─> Squash and merge (or rebase)
   ├─> Delete feature branch
   └─> Verify develop is stable

7. Post-Merge Validation
   └─> Run full test suite on develop
```

### Integration Process for Current Review Branch

For the **current review branch** (`review-qx-develop-status`), here's the specific integration plan:

#### Option A: Merge Review Artifacts to Develop (Recommended)

```bash
# 1. Ensure we're on review branch
git checkout review-qx-develop-status

# 2. Run validation (documentation check)
ls -la .gitignore *.md docs/

# 3. Create PR to develop
# - Title: "docs: Add project status review and comprehensive documentation"
# - Description: Include summary of review findings
# - Reviewers: Project maintainers

# 4. After approval, merge to develop
git checkout develop
git merge --no-ff review-qx-develop-status -m "docs: Merge review documentation and .gitignore"

# 5. Push to remote
git push origin develop

# 6. Delete review branch
git branch -d review-qx-develop-status
git push origin --delete review-qx-develop-status
```

#### Option B: Keep Review as Separate Documentation Branch

```bash
# Keep review branch for historical reference
git checkout review-qx-develop-status
git tag review-2025-10-17
git push origin review-2025-10-17

# Cherry-pick only .gitignore to develop
git checkout develop
git cherry-pick c34ed4b -- .gitignore
git commit -m "chore: Add .gitignore file"
git push origin develop

# Keep review branch for future reference (don't delete)
```

#### Recommended Approach: **Option A**

**Rationale:**
- `.gitignore` is essential for all branches
- Documentation adds value to the repository
- Architecture documentation helps onboarding
- Review findings inform future development

---

## ✅ Quality Gates

### Pre-Commit Checks (Local)

**Developer Responsibilities:**
```bash
# 1. Run unit tests
bash scripts/run-tests.sh --unit

# 2. Check for syntax errors
bash -n scripts/install-prereqs.sh

# 3. Dry-run validation
sudo bash scripts/install-prereqs.sh --dry-run

# 4. Self-review changes
git diff --staged
```

### Pre-Push Checks (Local)

```bash
# 1. Run full test suite
bash scripts/run-tests.sh --all

# 2. Ensure branch is up-to-date
git fetch origin develop
git rebase origin/develop

# 3. Verify commit messages
git log --oneline origin/develop..HEAD
```

### Pre-Merge Checks (CI/CD - Future)

**Automated Checks:**
- ✅ Unit tests pass (100%)
- ✅ Integration tests pass (100%)
- ✅ ShellCheck linting passes
- ✅ No security vulnerabilities detected
- ✅ Code review approved (minimum 1)
- ✅ Documentation updated
- ✅ No merge conflicts

**Manual Checks:**
- 👤 Code review by maintainer
- 👤 Architecture review (for major changes)
- 👤 Documentation review

---

## 📋 Post-Task Completion Process

### For Feature/Bugfix Branches

#### 1. **Final Testing** (Before PR)
```bash
# Switch to feature branch
git checkout feature/QX-123-my-feature

# Rebase on latest develop
git fetch origin develop
git rebase origin/develop

# Run full test suite
bash scripts/run-tests.sh --all

# Manual smoke test
sudo bash scripts/install-prereqs.sh --dry-run --profile development

# Check for uncommitted changes
git status
```

#### 2. **Documentation Updates**
```bash
# Update relevant documentation
# - README.md (if user-facing changes)
# - docs/TASKS.md (mark task complete)
# - docs/IMPROVEMENT_PLAN.md (if applicable)
# - Code comments (ensure up-to-date)

# Stage documentation changes
git add docs/
git commit -m "docs: Update documentation for feature XYZ"
```

#### 3. **Create Pull Request**

**PR Template:**
```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Feature
- [ ] Bugfix
- [ ] Documentation
- [ ] Refactoring

## Testing Completed
- [ ] Unit tests pass
- [ ] Integration tests pass
- [ ] Manual testing completed
- [ ] Dry-run validation passed

## Checklist
- [ ] Code follows project style
- [ ] Documentation updated
- [ ] Tests added/updated
- [ ] No breaking changes (or documented)
- [ ] Commit messages follow convention

## Related Issues
Closes #123
```

#### 4. **Code Review Process**
- Address reviewer comments
- Push updates to same branch
- Re-request review after changes
- Ensure all discussions resolved

#### 5. **Post-Merge Actions**
```bash
# After merge to develop
git checkout develop
git pull origin develop

# Delete local feature branch
git branch -d feature/QX-123-my-feature

# Delete remote feature branch (if not auto-deleted)
git push origin --delete feature/QX-123-my-feature

# Run post-merge validation
bash scripts/run-tests.sh --all

# Update task tracking (Jira, GitHub Issues, etc.)
```

### For Review Branches (Current Case)

#### 1. **Review Completion Checklist**
- ✅ All review objectives met
- ✅ Documentation created (.gitignore, reports, architecture)
- ✅ Findings documented
- ✅ Recommendations provided
- ✅ No test failures introduced

#### 2. **Merge Strategy**
```bash
# Current state: review-qx-develop-status has documentation commits
# Goal: Integrate valuable artifacts into develop

# Step 1: Verify current state
git status
git log --oneline -5

# Step 2: Create PR to develop
# Via GitHub UI or:
gh pr create \
    --base develop \
    --head review-qx-develop-status \
    --title "docs: Add comprehensive project review and documentation" \
    --body "$(cat <<EOF
## Review Summary
Completed comprehensive review of develop branch.

## Deliverables Added
- .gitignore (152 lines)
- PROJECT_STATUS_REPORT.md (500 lines)
- REVIEW_SUMMARY.md (183 lines)
- ARCHITECTURE.md (560 lines)
- REVIEW_DELIVERABLES.md (140 lines)
- BRANCHING_AND_TESTING_STRATEGY.md (this document)

## Findings
- Branch health: EXCELLENT
- Code quality: 9/10
- Security: Strong
- Test coverage: Comprehensive

## Recommendations
- Merge these artifacts to develop
- Proceed with Phase 0.1 (Kind cluster setup)
- Consider adding CI/CD workflows

## Testing
- No code changes, documentation only
- Existing test suite not affected
- Manual review recommended
EOF
)"

# Step 3: After approval, merge (maintainer action)
git checkout develop
git merge --no-ff review-qx-develop-status

# Step 4: Cleanup
git branch -d review-qx-develop-status
git push origin --delete review-qx-develop-status

# Step 5: Tag review for reference
git tag -a review-2025-10-17 -m "Project status review - October 2025"
git push origin review-2025-10-17
```

#### 3. **Post-Review Actions**
```bash
# Ensure develop is stable after merge
bash scripts/run-tests.sh --all

# Update team on findings (Slack, email, etc.)

# Create follow-up tasks based on recommendations
# - Add CI/CD workflows
# - Sync TASKS.md with IMPROVEMENT_PLAN.md
# - Configure ShellCheck linting

# Plan next sprint/phase based on review findings
```

---

## 📊 Testing Coverage Requirements

### Minimum Requirements by Change Type

| Change Type | Unit Tests | Integration Tests | Manual Tests | Code Review |
|-------------|-----------|-------------------|--------------|-------------|
| **New Feature** | ✅ Required | ✅ Required | ✅ Recommended | ✅ Required |
| **Bug Fix** | ✅ Required | ✅ Required | ✅ Recommended | ✅ Required |
| **Refactoring** | ✅ Required | ✅ Required | ⚠️ Optional | ✅ Required |
| **Documentation** | ⚠️ N/A | ⚠️ N/A | 👁️ Review only | ✅ Required |
| **Config Change** | ⚠️ Optional | ✅ Required | ✅ Recommended | ✅ Required |
| **Hotfix** | ✅ Required | ✅ Required | ✅ Required | ✅ Required (2+) |

### Test Execution Frequency

```
┌─────────────────────┬──────────────────┬─────────────────┐
│ Test Type           │ Frequency        │ Trigger         │
├─────────────────────┼──────────────────┼─────────────────┤
│ Unit Tests          │ Every commit     │ Developer (TDD) │
│ Integration Tests   │ Before push      │ Developer       │
│ Full Suite          │ Before PR        │ Developer       │
│ Automated CI Tests  │ Every push       │ CI/CD (future)  │
│ Manual Tests        │ Before release   │ QA Team         │
│ Security Scan       │ Weekly/release   │ Automated       │
└─────────────────────┴──────────────────┴─────────────────┘
```

---

## 🔍 Manual Testing Checklist

### Installation Script Testing

**Prerequisites:**
- [ ] Clean Ubuntu 24.04 system or VM
- [ ] Root/sudo access
- [ ] Internet connection
- [ ] No existing installations of Bun, Podman, kubectl, kind

**Test Cases:**

#### 1. Dry-Run Tests
```bash
# Test all profiles
- [ ] sudo bash scripts/install-prereqs.sh --dry-run --profile minimal
- [ ] sudo bash scripts/install-prereqs.sh --dry-run --profile development  
- [ ] sudo bash scripts/install-prereqs.sh --dry-run --profile full

# Verify no actual changes made
- [ ] No binaries installed
- [ ] No packages added
- [ ] No files modified
```

#### 2. Actual Installation Tests
```bash
# Test minimal profile
- [ ] sudo bash scripts/install-prereqs.sh --profile minimal
- [ ] Verify Bun installed: bun --version
- [ ] Verify Bun works: bun --help

# Clean system and test development profile
- [ ] sudo bash scripts/install-prereqs.sh --profile development
- [ ] Verify kubectl installed: kubectl version --client
- [ ] Verify kind installed: kind version

# Clean system and test full profile
- [ ] sudo bash scripts/install-prereqs.sh --profile full
- [ ] Verify all tools installed
- [ ] Run basic commands for each tool
```

#### 3. Error Handling Tests
```bash
# Test with invalid arguments
- [ ] Invalid profile: --profile invalid
- [ ] Invalid tool: --tools nonexistent
- [ ] Invalid channel: --channel fake

# Test rollback
- [ ] Simulate installation failure
- [ ] Verify rollback executed
- [ ] Verify system restored to previous state
```

#### 4. Edge Cases
```bash
# Test force reinstall
- [ ] Install tools
- [ ] Run with --force flag
- [ ] Verify reinstallation works

# Test specific tools
- [ ] sudo bash scripts/install-prereqs.sh --tools bun
- [ ] sudo bash scripts/install-prereqs.sh --tools kubectl,kind
```

---

## 🚀 Future Recommendations

### Short-Term (Next 2 Weeks)

#### 1. **Implement CI/CD Pipeline**
- Create `.github/workflows/tests.yml`
- Run tests on every push and PR
- Enforce quality gates

**Example Workflow:**
```yaml
name: Test Suite
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-24.04
    steps:
      - uses: actions/checkout@v3
      - name: Install Dependencies
        run: sudo apt-get update && sudo apt-get install -y curl unzip bc
      - name: Run Unit Tests
        run: bash scripts/run-tests.sh --unit
      - name: Run Integration Tests
        run: bash scripts/run-tests.sh --integration
      - name: Upload Test Results
        uses: actions/upload-artifact@v3
        with:
          name: test-results
          path: scripts/tests/test-results/
```

#### 2. **Add ShellCheck Linting**
```bash
# Install ShellCheck
sudo apt-get install shellcheck

# Run on all scripts
find scripts -name "*.sh" -exec shellcheck {} \;

# Add to pre-commit hook
cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash
find scripts -name "*.sh" -exec shellcheck {} \;
EOF
chmod +x .git/hooks/pre-commit
```

#### 3. **Create Pre-Commit Hooks**
```bash
# .git/hooks/pre-commit
#!/bin/bash
set -e

echo "Running pre-commit checks..."

# Run unit tests
echo "→ Running unit tests..."
bash scripts/run-tests.sh --unit

# Run ShellCheck
echo "→ Running ShellCheck..."
find scripts -name "*.sh" -exec shellcheck {} \;

echo "✅ All pre-commit checks passed!"
```

### Medium-Term (Next Month)

#### 1. **Test Coverage Metrics**
- Track test coverage over time
- Set minimum coverage thresholds
- Generate coverage reports

#### 2. **Performance Benchmarks**
- Measure installation times
- Track download speeds
- Monitor resource usage

#### 3. **Security Scanning**
- Automated vulnerability scanning
- Dependency checking
- SAST (Static Application Security Testing)

### Long-Term (Next Quarter)

#### 1. **Automated Release Process**
- Semantic versioning automation
- Changelog generation
- Release notes automation

#### 2. **Multi-Environment Testing**
- Test on multiple Ubuntu versions
- Test on other distributions
- Test on different architectures

#### 3. **Documentation CI**
- Automated documentation builds
- Link checking
- Documentation versioning

---

## 📚 References

### Internal Documentation
- [PROJECT_STATUS_REPORT.md](./PROJECT_STATUS_REPORT.md) - Comprehensive status review
- [ARCHITECTURE.md](./ARCHITECTURE.md) - Technical architecture
- [REVIEW_SUMMARY.md](./REVIEW_SUMMARY.md) - Quick reference
- [docs/IMPROVEMENT_PLAN.md](./docs/IMPROVEMENT_PLAN.md) - Completed improvements
- [docs/TASKS.md](./docs/TASKS.md) - Task tracking

### External Resources
- [GitFlow Workflow](https://nvie.com/posts/a-successful-git-branching-model/)
- [Semantic Versioning](https://semver.org/)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html)

---

## 📞 Support & Questions

### Getting Help
- **Documentation:** See docs/ directory
- **Issues:** GitHub Issues
- **Team Chat:** [Your team chat platform]
- **Email:** [Your team email]

### Contributing
1. Read this branching strategy
2. Follow testing requirements
3. Submit PR with proper documentation
4. Respond to review feedback

---

**Document Version:** 1.0  
**Last Updated:** October 17, 2025  
**Next Review:** December 2025  
**Owner:** QX Development Team

---

## ✅ Immediate Next Steps

### For This Review Branch (`review-qx-develop-status`)

**Priority: HIGH - Immediate Action Required**

```bash
# 1. Verify all documentation is complete
git status
git log --oneline -5

# 2. Run validation (no code changes, so tests not required)
ls -la .gitignore *.md

# 3. Create pull request to develop
# Use GitHub UI or CLI

# 4. Request review from project maintainers

# 5. After approval, merge to develop

# 6. Delete review branch after merge

# 7. Proceed with next phase (Kind cluster setup)
```

**Expected Timeline:** 1-2 days for review and merge

---

**Status:** 🟢 Ready for Integration  
**Blockers:** None  
**Dependencies:** Maintainer review and approval
