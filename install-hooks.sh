#!/bin/bash
#
# QX Project - Git Hooks Installation Script
# 
# This script installs custom git hooks for code quality automation.
# Run from the project root directory.
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔═══════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  QX Project - Git Hooks Installation                 ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if we're in the project root
if [ ! -d ".git" ]; then
    echo -e "${RED}❌ Error: Not in git repository root${NC}"
    echo -e "${YELLOW}Please run this script from the project root directory${NC}"
    exit 1
fi

if [ ! -d ".githooks" ]; then
    echo -e "${RED}❌ Error: .githooks directory not found${NC}"
    echo -e "${YELLOW}This script requires .githooks directory to exist${NC}"
    exit 1
fi

echo -e "${YELLOW}Installing git hooks...${NC}"
echo ""

# Create hooks directory if it doesn't exist
mkdir -p .git/hooks

# Counter for installed hooks
INSTALLED=0
SKIPPED=0

# Install each hook
for hook_file in .githooks/*; do
    # Skip README and non-files
    if [ ! -f "$hook_file" ] || [ "$(basename "$hook_file")" = "README.md" ]; then
        continue
    fi
    
    hook_name=$(basename "$hook_file")
    target=".git/hooks/$hook_name"
    
    # Check if hook already exists
    if [ -e "$target" ] && [ ! -L "$target" ]; then
        echo -e "${YELLOW}⚠  $hook_name already exists (not a symlink)${NC}"
        echo -n "   Replace with new hook? [y/N] "
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            echo -e "${YELLOW}   Skipped $hook_name${NC}"
            SKIPPED=$((SKIPPED + 1))
            continue
        fi
        rm "$target"
    fi
    
    # Create symlink
    ln -sf "../../$hook_file" "$target"
    chmod +x "$target"
    echo -e "${GREEN}✓ Installed $hook_name${NC}"
    INSTALLED=$((INSTALLED + 1))
done

echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}Installation complete!${NC}"
echo ""
echo -e "Hooks installed: ${GREEN}$INSTALLED${NC}"
if [ $SKIPPED -gt 0 ]; then
    echo -e "Hooks skipped: ${YELLOW}$SKIPPED${NC}"
fi
echo ""

# List installed hooks
echo -e "${BLUE}Installed hooks:${NC}"
for hook in .git/hooks/*; do
    if [ -L "$hook" ] && [ -f "$hook" ]; then
        hook_name=$(basename "$hook")
        echo -e "  ${GREEN}✓${NC} $hook_name"
    fi
done
echo ""

# Show next steps
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}Next Steps:${NC}"
echo ""
echo -e "1. ${YELLOW}Test the hooks${NC}"
echo -e "   Create a test commit to verify hooks work:"
echo -e "   ${YELLOW}touch test.sh && git add test.sh && git commit -m 'test: verify hooks'${NC}"
echo ""
echo -e "2. ${YELLOW}Read the documentation${NC}"
echo -e "   Review hook behavior: ${YELLOW}cat .githooks/README.md${NC}"
echo ""
echo -e "3. ${YELLOW}Optional: Install additional tools${NC}"
echo -e "   - ShellCheck: ${YELLOW}sudo apt-get install shellcheck${NC}"
echo -e "   - For better linting and code quality"
echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${GREEN}✅ Git hooks are now active!${NC}"
echo -e "${YELLOW}Note: Hooks can be bypassed with 'git commit --no-verify' if needed${NC}"
echo ""
