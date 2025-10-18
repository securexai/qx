---
title: "QX Quick Start Guide"
last_updated: "2025-10-18"
status: "active"
audience: "developers"
category: "getting-started"
---

# QX Project - Quick Start Guide

**For Developers Joining After Review Integration**

---

## 🚀 Getting Started in 5 Minutes

### 1. Clone and Setup

```bash
# Clone repository
git clone <repo-url>
cd qx

# Checkout develop branch
git checkout develop
git pull origin develop
```

### 2. Install Git Hooks (Required)

```bash
# Easy installation
bash install-hooks.sh

# Or manual installation
ln -sf ../../.githooks/pre-commit .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

### 3. Verify Setup

```bash
# Run tests to ensure environment is working
bash scripts/run-tests.sh --unit

# Test the installation script (dry-run)
sudo bash scripts/install-prereqs.sh --dry-run --profile minimal
```

### 4. Read Essential Docs

**Start here** (5 minutes):
- `REVIEW_SUMMARY.md` - Project overview and status

**For daily work** (15 minutes):
- `DEVELOPER_WORKFLOW.md` - How to work on features

**For reference** (as needed):
- `BRANCHING_AND_TESTING_STRATEGY.md` - Workflows and testing
- `ARCHITECTURE.md` - Technical deep-dive
- `docs/plan.md` - Project roadmap and technology stack

---

## 📋 Daily Workflow

### Starting New Work

```bash
# 1. Update develop
git checkout develop
git pull origin develop

# 2. Create feature branch
git checkout -b feature/QX-123-my-feature

# 3. Make changes and test frequently
# ... edit files ...
bash scripts/run-tests.sh --unit

# 4. Commit with conventional format
git add .
git commit -m "feat(scope): description"
```

### Before Pushing

```bash
# 1. Run full test suite
bash scripts/run-tests.sh --all

# 2. Rebase on develop
git fetch origin develop
git rebase origin/develop

# 3. Push
git push origin feature/QX-123-my-feature

# 4. Create PR on GitHub
```

---

## 🧪 Testing Commands

```bash
# Quick unit tests (fast)
bash scripts/run-tests.sh --unit

# Full test suite (slower)
bash scripts/run-tests.sh --all

# Integration tests only
bash scripts/run-tests.sh --integration

# Test in clean container
podman run --rm -it -v "$(pwd):/workspace:ro" ubuntu:24.04 bash
```

---

## 📚 Documentation Map

```
Quick Reference:
├── QUICK_START.md (this file) .......... Getting started
├── REVIEW_SUMMARY.md ................... Project status overview
└── DEVELOPER_WORKFLOW.md ............... Daily development guide

Detailed Guides:
├── BRANCHING_AND_TESTING_STRATEGY.md ... Complete workflow
├── ARCHITECTURE.md ..................... Technical architecture
├── PROJECT_STATUS_REPORT.md ............ Comprehensive analysis
└── docs/plan.md ........................ Project roadmap & tech stack

Integration:
├── MERGE_INSTRUCTIONS.md ............... For maintainers
└── POST_REVIEW_ACTION_PLAN.md .......... Implementation plan

Scripts & Infrastructure:
├── .githooks/README.md ................. Git hooks guide
├── .github/workflows/tests.yml ......... CI/CD pipeline
├── install-hooks.sh .................... Hook installer
└── docs/TASKS.md ....................... Completed improvements
```

---

## 🛠️ Essential Tools

### Required (for development)

```bash
# Install system dependencies
sudo apt-get update
sudo apt-get install -y curl ca-certificates unzip bc jq

# Install Podman (for testing)
sudo apt-get install -y podman
```

### Recommended (for quality)

```bash
# ShellCheck (linting)
sudo apt-get install -y shellcheck

# GitHub CLI (for PRs)
sudo apt-get install -y gh
gh auth login
```

---

## ⚡ Common Commands

### Git Operations

```bash
# Create feature branch
git checkout -b feature/QX-XXX-description

# Update from develop
git fetch origin develop && git rebase origin/develop

# Squash last 3 commits
git rebase -i HEAD~3

# Amend last commit
git commit --amend

# Stash changes
git stash && git stash pop
```

### Testing

```bash
# Run unit tests
bash scripts/run-tests.sh --unit

# Run with verbose output
VERBOSE=1 bash scripts/run-tests.sh --unit

# Test specific tool installation
sudo bash scripts/install-prereqs.sh --dry-run --tools bun
```

### Git Hooks

```bash
# Bypass hooks (not recommended)
git commit --no-verify

# Test hook manually
bash .githooks/pre-commit

# Reinstall hooks
bash install-hooks.sh
```

---

## 🎯 Commit Message Format

### Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types

- `feat` - New feature
- `fix` - Bug fix
- `docs` - Documentation
- `test` - Testing
- `refactor` - Refactoring
- `chore` - Maintenance

### Examples

```bash
# Feature
git commit -m "feat(plugins): add PostgreSQL plugin"

# Bug fix
git commit -m "fix(rollback): correct file restoration logic"

# Documentation
git commit -m "docs(readme): update installation steps"

# With body and footer
git commit -m "feat(config): add support for custom profiles

- Implement profile loading from external files
- Add validation for custom profiles
- Update documentation

Closes #123"
```

---

## 🆘 Troubleshooting

### Tests Failing

```bash
# Check dependencies
curl --version && unzip -v && bc --version

# Install missing packages
sudo apt-get install -y curl ca-certificates unzip bc jq

# Run with debug
DEBUG=1 bash scripts/run-tests.sh --unit
```

### Git Hooks Issues

```bash
# Verify hook is installed
ls -la .git/hooks/pre-commit

# Check if executable
chmod +x .git/hooks/pre-commit

# Test manually
bash .githooks/pre-commit
```

### Merge Conflicts

```bash
# During rebase
git status                    # See conflicts
# ... fix conflicts ...
git add <file>
git rebase --continue

# Abort if needed
git rebase --abort
```

---

## 📞 Getting Help

### Documentation

1. Check `DEVELOPER_WORKFLOW.md` for daily tasks
2. Review `BRANCHING_AND_TESTING_STRATEGY.md` for processes
3. Consult `ARCHITECTURE.md` for technical details

### Team Resources

- **GitHub Issues** - For bugs and features
- **Team Chat** - For quick questions  
- **Documentation** - In `docs/` directory
- **Code Review** - Learn from PR feedback

---

## 🎓 Learning Path

### Week 1: Setup & Familiarization

- [ ] Clone repository and install hooks
- [ ] Run test suite successfully
- [ ] Read REVIEW_SUMMARY.md
- [ ] Review existing code structure

### Week 2: First Contribution

- [ ] Fix a documentation issue or typo
- [ ] Create a branch following naming convention
- [ ] Make a commit with proper format
- [ ] Create a PR and get it reviewed

### Week 3: Regular Development

- [ ] Implement a small feature or bug fix
- [ ] Write tests for your changes
- [ ] Follow full development workflow
- [ ] Help review another PR

---

## ✅ Setup Checklist

After completing setup, verify:

- [ ] Git hooks installed and working
- [ ] Can run unit tests successfully
- [ ] Can run dry-run installation
- [ ] Read DEVELOPER_WORKFLOW.md
- [ ] Understand branching strategy
- [ ] Know commit message format
- [ ] Can create feature branch
- [ ] Can create and push commits
- [ ] Ready to create first PR

---

## 🎉 You're Ready!

You now have everything needed to contribute to the QX project:

✅ Development environment set up  
✅ Git hooks installed for quality  
✅ Tests running successfully  
✅ Documentation reviewed  
✅ Workflow understood  

**Next Step:** Create your first feature branch and start contributing!

```bash
git checkout -b feature/QX-XXX-your-first-task
```

Good luck and happy coding! 🚀

---

**Quick Links:**
- [Developer Workflow](./DEVELOPER_WORKFLOW.md)
- [Testing Strategy](./BRANCHING_AND_TESTING_STRATEGY.md)
- [Architecture](./ARCHITECTURE.md)
- [Git Hooks](./githooks/README.md)
