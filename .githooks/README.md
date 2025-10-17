# Git Hooks for QX Project

This directory contains custom Git hooks to maintain code quality.

## Installation

To install these hooks, run from the project root:

```bash
# Install pre-commit hook
ln -sf ../../.githooks/pre-commit .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit

# Or install all hooks at once
find .githooks -type f -not -name "README.md" -exec ln -sf ../../{} .git/hooks/ \;
find .git/hooks -type f -exec chmod +x {} \;
```

## Available Hooks

### pre-commit

Runs before each commit to ensure:
- ✅ Bash syntax is valid
- ✅ ShellCheck passes (if installed)
- ✅ Unit tests pass (if code changed)
- ✅ No common issues (debug statements, secrets, etc.)
- ⚠️  Commit message follows conventional format (warning only)

**To bypass:** `git commit --no-verify` (not recommended)

## Hook Configuration

### Disabling ShellCheck Warnings

If ShellCheck is too strict for certain files:

```bash
# Add to top of file
# shellcheck disable=SC2034,SC2155
```

### Skipping Tests

If tests are slow and you want to commit quickly:

```bash
# Temporarily bypass
git commit --no-verify

# Or set environment variable
SKIP_TESTS=1 git commit
```

## Troubleshooting

### Hook not executing

```bash
# Check if hook is executable
ls -la .git/hooks/pre-commit

# Make executable
chmod +x .git/hooks/pre-commit

# Verify symbolic link
ls -la .git/hooks/pre-commit
# Should show: .git/hooks/pre-commit -> ../../.githooks/pre-commit
```

### ShellCheck errors

```bash
# Install ShellCheck
sudo apt-get install shellcheck

# Test manually
shellcheck scripts/install-prereqs.sh
```

### Tests failing

```bash
# Run tests manually
bash scripts/run-tests.sh --unit

# Check test logs
cat scripts/tests/*.log

# Debug
VERBOSE=1 bash scripts/run-tests.sh --unit
```

## Best Practices

1. **Don't bypass hooks** unless absolutely necessary
2. **Fix issues** rather than disabling checks
3. **Keep hooks fast** - slow hooks discourage use
4. **Test hooks** before committing hook changes
5. **Document** any custom configurations

## Future Hooks

Planned additions:
- `pre-push` - Run full test suite before pushing
- `commit-msg` - Enforce commit message format
- `post-merge` - Notify about changes in dependencies

## Resources

- [Git Hooks Documentation](https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks)
- [ShellCheck](https://www.shellcheck.net/)
- [Conventional Commits](https://www.conventionalcommits.org/)
