# QX Developer Workflow Guide

**Quick Reference for Daily Development**  
**Version:** 1.0  
**Last Updated:** October 17, 2025

---

## 🎯 Quick Start

```bash
# 1. Clone and setup
git clone <repo-url>
cd qx
git checkout develop

# 2. Run tests to verify setup
bash scripts/run-tests.sh --all

# 3. Create your feature branch
git checkout -b feature/QX-XXX-my-feature

# 4. Make changes, test, commit
# ... your work ...

# 5. Push and create PR
git push origin feature/QX-XXX-my-feature
```

---

## 📋 Daily Workflows

### Starting a New Feature

```bash
# 1. Update your local develop branch
git checkout develop
git pull origin develop

# 2. Create feature branch (use Jira ticket ID)
git checkout -b feature/QX-123-add-postgres-plugin

# 3. Verify you're on the right branch
git status
git branch --show-current

# 4. Start development with TDD approach
# - Write test first
# - Implement feature
# - Make test pass
# - Refactor
# - Commit

# Example: Adding a new plugin
touch scripts/plugins/postgres.sh
touch scripts/tests/unit/test_postgres_plugin.sh
```

### Running Tests During Development

```bash
# Quick unit test (fast, run frequently)
bash scripts/run-tests.sh --unit

# Run specific test file (when debugging)
bash scripts/tests/framework.sh scripts/tests/unit/test_config.sh

# Full test suite (before commits)
bash scripts/run-tests.sh --all

# Test your changes in isolation (Podman)
podman run --rm -it \
    -v "$(pwd):/workspace:ro" \
    ubuntu:24.04 \
    bash -c "
        apt-get update -qq && 
        apt-get install -y -qq curl unzip bc && 
        cd /workspace && 
        bash scripts/install-prereqs.sh --dry-run --profile development
    "
```

### Making Commits

```bash
# Stage specific files
git add scripts/plugins/postgres.sh
git add scripts/tests/unit/test_postgres_plugin.sh

# Commit with conventional commit message
git commit -m "feat(plugins): add PostgreSQL plugin with installation support

- Implement detect_postgres() function
- Add install_postgres() with version pinning
- Include verification and uninstallation
- Add comprehensive unit tests

Closes QX-123"

# Push to remote
git push origin feature/QX-123-add-postgres-plugin
```

### Commit Message Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation only
- `style`: Code style changes (formatting)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

**Examples:**
```bash
# Feature
git commit -m "feat(plugins): add PostgreSQL installation support"

# Bug fix
git commit -m "fix(rollback): correct file restoration in rollback_file_operation()"

# Documentation
git commit -m "docs(readme): update installation instructions"

# Test
git commit -m "test(integration): add rollback mechanism test"

# Refactor
git commit -m "refactor(config): simplify YAML parsing logic"
```

### Creating a Pull Request

```bash
# 1. Push your branch
git push origin feature/QX-123-my-feature

# 2. Create PR via GitHub UI or CLI
gh pr create \
    --base develop \
    --title "feat: Add PostgreSQL plugin support" \
    --body "$(cat <<EOF
## Description
Implements PostgreSQL plugin for automated installation.

## Changes
- New plugin: scripts/plugins/postgres.sh
- Unit tests for PostgreSQL plugin
- Configuration entries in default.yaml
- Documentation updates

## Type of Change
- [x] Feature
- [ ] Bugfix
- [ ] Documentation
- [ ] Refactoring

## Testing Completed
- [x] Unit tests pass (100%)
- [x] Integration tests pass
- [x] Dry-run validation successful
- [x] Manual testing on Ubuntu 24.04

## Checklist
- [x] Code follows project style
- [x] Documentation updated
- [x] Tests added/updated
- [x] No breaking changes
- [x] Commit messages follow convention

## Related Issues
Closes #123
EOF
)"
```

---

## 🔧 Common Tasks

### Updating Your Feature Branch

```bash
# Method 1: Merge (preserves history)
git checkout feature/QX-123-my-feature
git fetch origin develop
git merge origin/develop

# Method 2: Rebase (cleaner history, recommended)
git checkout feature/QX-123-my-feature
git fetch origin develop
git rebase origin/develop

# If conflicts occur during rebase:
# 1. Fix conflicts in files
# 2. Stage resolved files: git add <file>
# 3. Continue: git rebase --continue
# 4. Or abort: git rebase --abort
```

### Running Specific Tests

```bash
# Run single test function (for debugging)
bash -c '
source scripts/tests/framework.sh
source scripts/tests/unit/test_config.sh
test_load_config_success
'

# Run with verbose output
VERBOSE=true bash scripts/run-tests.sh --unit

# Run with debug logging
LOG_LEVEL=debug bash scripts/run-tests.sh --integration
```

### Testing Your Script Changes

```bash
# Dry-run (safe, no actual installation)
sudo bash scripts/install-prereqs.sh --dry-run --profile development

# Verbose dry-run
sudo bash scripts/install-prereqs.sh --dry-run --verbose

# Test specific tool installation
sudo bash scripts/install-prereqs.sh --dry-run --tools bun,kubectl

# Test in clean container
podman run --rm -it \
    -v "$(pwd):/workspace:ro" \
    ubuntu:24.04 bash

# Inside container:
cd /workspace
apt-get update && apt-get install -y curl unzip bc
bash scripts/install-prereqs.sh --dry-run
```

### Debugging Failed Tests

```bash
# Run with maximum verbosity
DEBUG=1 VERBOSE=1 bash scripts/run-tests.sh --unit

# Run single test file
bash scripts/tests/framework.sh scripts/tests/unit/test_config.sh

# Check test logs
cat scripts/tests/*.log

# Run script with debugging
bash -x scripts/install-prereqs.sh --dry-run
```

### Adding a New Plugin

```bash
# 1. Create plugin file
cat > scripts/plugins/mynewool.sh << 'EOF'
#!/bin/bash
# Plugin: mynewtool

detect_mynewtool() {
    if command_exists mynewtool; then
        return 0
    fi
    return 1
}

install_mynewtool() {
    log_info "Installing mynewtool..."
    # Installation logic here
    return 0
}

verify_mynewtool() {
    detect_mynewtool || return 1
    log_success "mynewtool verified"
    return 0
}

uninstall_mynewtool() {
    log_info "Uninstalling mynewtool..."
    # Uninstallation logic here
    return 0
}
EOF

# 2. Register plugin in plugin_manager.sh
# Edit scripts/lib/plugin_manager.sh
# Add "mynewtool" to PLUGIN_REGISTRY array

# 3. Add configuration
# Edit scripts/config/default.yaml
# Add tool configuration under tools: section

# 4. Create tests
cat > scripts/tests/unit/test_mynewtool.sh << 'EOF'
#!/bin/bash
source "$(dirname "$0")/../framework.sh"

test_detect_mynewtool_not_installed() {
    # Test detection when not installed
    assert_command_fails detect_mynewtool
}

test_install_mynewtool_success() {
    # Test successful installation
    install_mynewtool
    assert_command_success verify_mynewtool
}

run_test_suite
EOF

# 5. Run tests
bash scripts/run-tests.sh --unit

# 6. Test integration
sudo bash scripts/install-prereqs.sh --dry-run --tools mynewtool

# 7. Commit changes
git add scripts/plugins/mynewtool.sh
git add scripts/lib/plugin_manager.sh
git add scripts/config/default.yaml
git add scripts/tests/unit/test_mynewtool.sh
git commit -m "feat(plugins): add mynewtool plugin"
```

---

## 🧪 Testing Best Practices

### Test-Driven Development (TDD)

```bash
# 1. Write failing test first
cat > scripts/tests/unit/test_new_feature.sh << 'EOF'
test_new_feature_works() {
    local result=$(my_new_function "input")
    assert_equals "expected" "$result"
}
EOF

# 2. Run test (should fail)
bash scripts/run-tests.sh --unit
# ❌ FAIL: my_new_function not found

# 3. Implement feature
cat >> scripts/lib/utils.sh << 'EOF'
my_new_function() {
    local input="$1"
    echo "expected"
}
EOF

# 4. Run test (should pass)
bash scripts/run-tests.sh --unit
# ✅ PASS: test_new_feature_works

# 5. Refactor and repeat
```

### Writing Good Tests

```bash
# ✅ Good test: Clear, specific, independent
test_config_value_retrieval_success() {
    CONFIG_CACHE["tools.bun.version"]="1.0.0"
    local result=$(get_config_value "tools.bun.version")
    assert_equals "1.0.0" "$result"
}

# ❌ Bad test: Unclear, vague, dependent on external state
test_config_works() {
    result=$(get_config_value "something")
    [[ -n "$result" ]] || exit 1
}

# ✅ Good test: Tests one thing
test_version_comparison_greater_than() {
    compare_versions "2.0.0" "1.0.0"
    assert_equals 1 $?
}

# ✅ Good test: Tests error cases
test_version_comparison_invalid_input() {
    assert_command_fails compare_versions "invalid" "1.0.0"
}
```

---

## 🔍 Code Review Checklist

### Before Requesting Review

- [ ] All tests pass locally
- [ ] Dry-run validation successful
- [ ] Code follows project style
- [ ] No commented-out code (unless documented)
- [ ] No debug logging left in code
- [ ] Documentation updated (if needed)
- [ ] Commit messages follow convention
- [ ] Branch is up-to-date with develop
- [ ] No merge conflicts
- [ ] Self-review completed

### Self-Review Questions

1. **Functionality**
   - Does the code do what it's supposed to do?
   - Are edge cases handled?
   - Is error handling appropriate?

2. **Quality**
   - Is the code readable and maintainable?
   - Are functions appropriately sized?
   - Are variables named clearly?
   - Is there unnecessary duplication?

3. **Testing**
   - Are there tests for new functionality?
   - Do tests cover edge cases?
   - Are tests clear and maintainable?

4. **Security**
   - Is input validated?
   - Are there any injection vulnerabilities?
   - Are file permissions set correctly?
   - Is sensitive data handled securely?

5. **Documentation**
   - Are complex sections documented?
   - Is the README updated (if needed)?
   - Are function purposes clear?

---

## 🚨 Troubleshooting

### Tests Failing Locally

```bash
# 1. Check if you have dependencies
curl --version
unzip -v
bc --version

# 2. Install missing dependencies
sudo apt-get update
sudo apt-get install -y curl ca-certificates unzip bc jq

# 3. Check Podman (for integration tests)
podman --version
# If not installed:
sudo apt-get install -y podman

# 4. Run tests with verbose output
VERBOSE=1 bash scripts/run-tests.sh --all

# 5. Check test logs
cat scripts/tests/*.log
```

### Git Issues

```bash
# Undo last commit (keep changes)
git reset --soft HEAD~1

# Undo last commit (discard changes) ⚠️ DANGEROUS
git reset --hard HEAD~1

# Discard local changes to file
git checkout -- scripts/file.sh

# Stash changes temporarily
git stash
git stash pop

# Amend last commit message
git commit --amend -m "New commit message"

# Force push after amend (⚠️ only on feature branches!)
git push --force-with-lease origin feature/QX-123-my-feature
```

### Clean Up Merged Branches

```bash
# List merged branches
git branch --merged develop

# Delete local merged branches (except develop and main)
git branch --merged develop | grep -v "develop" | grep -v "main" | xargs git branch -d

# Delete remote branch
git push origin --delete feature/QX-123-old-feature

# Prune remote branches
git fetch --prune
```

---

## 📚 Resources

### Internal Documentation
- [BRANCHING_AND_TESTING_STRATEGY.md](./BRANCHING_AND_TESTING_STRATEGY.md) - Comprehensive strategy
- [ARCHITECTURE.md](./ARCHITECTURE.md) - Technical architecture
- [PROJECT_STATUS_REPORT.md](./PROJECT_STATUS_REPORT.md) - Current status

### External Resources
- [Git Documentation](https://git-scm.com/doc)
- [Bash Best Practices](https://bertvv.github.io/cheat-sheets/Bash.html)
- [ShellCheck](https://www.shellcheck.net/) - Shell script linter
- [Conventional Commits](https://www.conventionalcommits.org/)

### Team Resources
- GitHub Issues: [Link to issues]
- Team Chat: [Link to Slack/Discord]
- Wiki: [Link to wiki]

---

## 🎓 Learning Path

### New to the Project?

1. **Week 1: Setup & Familiarization**
   - Clone repository
   - Read README.md and ARCHITECTURE.md
   - Run test suite successfully
   - Review existing plugins

2. **Week 2: Small Contributions**
   - Fix a minor bug or update documentation
   - Write tests for existing untested code
   - Review PRs from other developers

3. **Week 3: Feature Development**
   - Implement a small feature
   - Write comprehensive tests
   - Go through full PR process

4. **Week 4: Complex Work**
   - Add a new plugin
   - Refactor existing code
   - Help review others' PRs

---

## 💡 Pro Tips

### Speed Up Your Workflow

```bash
# Create shell aliases
alias qx-test='bash scripts/run-tests.sh --unit'
alias qx-test-all='bash scripts/run-tests.sh --all'
alias qx-dry='sudo bash scripts/install-prereqs.sh --dry-run'

# Add to ~/.bashrc or ~/.zshrc
echo "alias qx-test='bash scripts/run-tests.sh --unit'" >> ~/.bashrc
```

### Git Shortcuts

```bash
# Pretty git log
git log --oneline --graph --all --decorate -20

# Create alias
git config --global alias.lg "log --oneline --graph --all --decorate"
git lg -20

# Quick status
git config --global alias.st "status --short"
git st
```

### Faster Testing

```bash
# Run only changed tests
git diff --name-only develop | grep "test_" | while read test; do
    bash scripts/tests/framework.sh "$test"
done

# Watch mode (requires entr)
ls scripts/**/*.sh | entr -c bash scripts/run-tests.sh --unit
```

---

## ❓ FAQ

**Q: How often should I run tests?**  
A: Run unit tests frequently (every few commits). Run full suite before pushing.

**Q: Should I squash commits before merging?**  
A: Generally yes, unless commit history is meaningful. Use "Squash and merge" on GitHub.

**Q: Can I commit directly to develop?**  
A: No. Always use feature branches and PRs, except for urgent hotfixes.

**Q: What if my tests pass locally but fail in CI?**  
A: Usually environment differences. Check CI logs carefully. Common causes:
- Missing dependencies
- File paths
- Permissions
- Environment variables

**Q: How do I handle long-running feature branches?**  
A: Regularly rebase on develop to avoid large merge conflicts:
```bash
git fetch origin develop
git rebase origin/develop
```

**Q: Should I delete my feature branch after merge?**  
A: Yes, always clean up merged branches to keep repository tidy.

---

**Remember:** When in doubt, ask! Better to ask questions than to introduce bugs.

---

**Document Version:** 1.0  
**Last Updated:** October 17, 2025  
**Maintained By:** QX Development Team
