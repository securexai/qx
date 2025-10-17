# pnpm Implementation Guide for QX React Project

**Document Type:** Technical Implementation Guide  
**Target Phase:** Phase 1 (Project Foundation)  
**Status:** Ready for Implementation  
**Prerequisites:** Phase 0 complete, Bun installed

---

## 🎯 Overview

This guide provides step-by-step instructions for implementing pnpm (or Bun package manager) when creating the QX React application in Phase 1.

**Reference:** See `PNPM_FEASIBILITY_ANALYSIS.md` for decision rationale.

---

## 🔀 Two Implementation Paths

### Path A: Bun Package Manager (Recommended)
✅ Faster, already installed, simpler toolchain

### Path B: pnpm
✅ More mature, industry standard, clear separation

Choose based on team preference and risk tolerance.

---

## 🚀 Path A: Implementing with Bun Package Manager

### Step 1: Verify Bun Installation

```bash
# Check Bun is installed
bun --version
# Should show: 1.1.12 or higher

# If not installed:
sudo bash scripts/install-prereqs.sh --profile development
```

### Step 2: Create Monorepo Structure

```bash
# From project root
cd /path/to/qx

# Create directory structure
mkdir -p apps/frontend
mkdir -p apps/backend
mkdir -p packages/shared
mkdir -p packages/types
mkdir -p packages/config
```

### Step 3: Initialize Root Package.json

```bash
# Create root package.json
cat > package.json << 'EOF'
{
  "name": "qx",
  "version": "0.1.0",
  "private": true,
  "workspaces": [
    "apps/*",
    "packages/*"
  ],
  "scripts": {
    "dev": "bun run --filter './apps/*' dev",
    "build": "bun run --filter './apps/*' build",
    "test": "bun test",
    "lint": "eslint . --ext .ts,.tsx",
    "typecheck": "tsc --noEmit"
  },
  "devDependencies": {
    "@types/bun": "latest",
    "typescript": "^5.0.0"
  }
}
EOF
```

### Step 4: Create Frontend React App

```bash
cd apps/frontend

# Create Vite React app with TypeScript
bun create vite . --template react-ts

# Install dependencies
bun install

# Install planned dependencies from README.md
bun add @chakra-ui/react @emotion/react @emotion/styled framer-motion
bun add zustand
bun add @tanstack/react-query
bun add react-router-dom
bun add react-hook-form
bun add zod

# Install dev dependencies
bun add -d vitest @vitest/ui
bun add -d @testing-library/react @testing-library/jest-dom @testing-library/user-event
bun add -d @types/react @types/react-dom
bun add -d eslint @typescript-eslint/eslint-plugin @typescript-eslint/parser
```

### Step 5: Create Bun Configuration

```bash
# Create bunfig.toml in project root
cat > bunfig.toml << 'EOF'
[install]
# Peer dependencies
auto-install-peers = true
exact = false

# Production mode
production = false

# Lockfile
frozen-lockfile = false

[install.cache]
# Cache location
dir = "~/.bun/install/cache"

# Cache strategy
disable = false

[test]
# Test configuration
preload = ["./test/setup.ts"]
EOF
```

### Step 6: Configure TypeScript for Monorepo

```bash
# Root tsconfig.json
cat > tsconfig.json << 'EOF'
{
  "compilerOptions": {
    "target": "ESNext",
    "module": "ESNext",
    "lib": ["ESNext", "DOM"],
    "moduleResolution": "bundler",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true,
    "paths": {
      "@qx/shared/*": ["./packages/shared/src/*"],
      "@qx/types/*": ["./packages/types/src/*"],
      "@qx/config/*": ["./packages/config/src/*"]
    }
  },
  "exclude": ["node_modules", "dist"]
}
EOF
```

### Step 7: Verify Installation

```bash
# From project root
cd /path/to/qx

# Install all workspace dependencies
bun install

# Verify frontend runs
cd apps/frontend
bun run dev

# Should start development server on http://localhost:5173
# Ctrl+C to stop

# Run tests
bun test

# Build
bun run build
```

### Step 8: Update Documentation

```bash
# Update README.md with new structure
# Add to Getting Started section:

## Getting Started with Bun

### Install Dependencies
\`\`\`bash
bun install
\`\`\`

### Run Development Server
\`\`\`bash
cd apps/frontend
bun run dev
\`\`\`

### Run Tests
\`\`\`bash
bun test
\`\`\`

### Build for Production
\`\`\`bash
bun run build
\`\`\`
```

---

## 🔧 Path B: Implementing with pnpm

### Step 1: Create pnpm Plugin

```bash
# Create scripts/plugins/pnpm.sh
cat > scripts/plugins/pnpm.sh << 'EOF'
#!/usr/bin/env bash

# Plugin: pnpm - Fast, disk space efficient package manager
# Version: 8.15.0
# Website: https://pnpm.io

set -euo pipefail

# Plugin metadata
PLUGIN_NAME="pnpm"
PLUGIN_VERSION="8.15.0"

# Detect if pnpm is installed
plugin_pnpm_detect() {
    if command -v pnpm >/dev/null 2>&1; then
        return 0
    fi
    return 1
}

# Get installed version
plugin_pnpm_get_version() {
    if ! plugin_pnpm_detect; then
        echo "not installed"
        return 1
    fi
    pnpm --version 2>/dev/null || echo "unknown"
}

# Install pnpm
plugin_pnpm_install() {
    local version="${1:-latest}"
    
    log_info "Installing pnpm version ${version}..."
    
    # Use official installation script
    if ! curl -fsSL https://get.pnpm.io/install.sh | sh -; then
        log_error "Failed to install pnpm"
        return 1
    fi
    
    # Add to PATH for current session
    export PNPM_HOME="$HOME/.local/share/pnpm"
    export PATH="$PNPM_HOME:$PATH"
    
    # Verify installation
    if ! plugin_pnpm_verify; then
        log_error "pnpm installation verification failed"
        return 1
    fi
    
    log_success "pnpm ${version} installed successfully"
    return 0
}

# Verify pnpm installation
plugin_pnpm_verify() {
    if ! plugin_pnpm_detect; then
        log_error "pnpm not found in PATH"
        return 1
    fi
    
    local installed_version
    installed_version=$(plugin_pnpm_get_version)
    log_info "Verified pnpm version: ${installed_version}"
    
    return 0
}

# Uninstall pnpm (for rollback)
plugin_pnpm_uninstall() {
    log_info "Uninstalling pnpm..."
    
    # Remove pnpm global installation
    rm -rf "$HOME/.local/share/pnpm"
    rm -f "$HOME/.local/bin/pnpm"
    
    log_success "pnpm uninstalled"
    return 0
}

# Get installation method
plugin_pnpm_get_install_method() {
    echo "script"
}
EOF

chmod +x scripts/plugins/pnpm.sh
```

### Step 2: Add pnpm to Configuration

```bash
# Edit scripts/config/default.yaml
# Add under tools section:

cat >> scripts/config/default.yaml << 'EOF'

  pnpm:
    version: "8.15.0"
    channel: "stable"
    description: "Fast, disk space efficient package manager"
    url_template: "https://get.pnpm.io/install.sh"
    platforms:
      - linux-x86_64
      - linux-arm64
      - darwin-x86_64
      - darwin-arm64
EOF
```

### Step 3: Install pnpm

```bash
# Using the install script
sudo bash scripts/install-prereqs.sh --tools pnpm

# OR manually:
curl -fsSL https://get.pnpm.io/install.sh | sh -

# Add to shell profile
echo 'export PNPM_HOME="$HOME/.local/share/pnpm"' >> ~/.bashrc
echo 'export PATH="$PNPM_HOME:$PATH"' >> ~/.bashrc
source ~/.bashrc

# Verify
pnpm --version
```

### Step 4: Create Monorepo Structure

```bash
# Same as Bun path
cd /path/to/qx

mkdir -p apps/frontend
mkdir -p apps/backend
mkdir -p packages/shared
mkdir -p packages/types
mkdir -p packages/config
```

### Step 5: Create pnpm Workspace Configuration

```bash
# Create pnpm-workspace.yaml at root
cat > pnpm-workspace.yaml << 'EOF'
packages:
  - 'apps/*'
  - 'packages/*'
EOF

# Create .npmrc at root
cat > .npmrc << 'EOF'
# Use pnpm for package management
package-manager=pnpm

# Strict peer dependencies
strict-peer-dependencies=false

# Auto install peer dependencies
auto-install-peers=true

# Node linker (isolated prevents hoisting)
node-linker=isolated

# Shamefully hoist (set to true if needed)
shamefully-hoist=false

# Store directory
store-dir=~/.pnpm-store
EOF
```

### Step 6: Initialize Root Package.json

```bash
cat > package.json << 'EOF'
{
  "name": "qx",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "dev": "pnpm --filter './apps/*' dev",
    "build": "pnpm --filter './apps/*' build",
    "test": "pnpm -r test",
    "lint": "pnpm -r lint",
    "typecheck": "pnpm -r typecheck"
  },
  "devDependencies": {
    "typescript": "^5.0.0"
  },
  "engines": {
    "node": ">=18.0.0",
    "pnpm": ">=8.0.0"
  }
}
EOF
```

### Step 7: Create Frontend React App

```bash
cd apps/frontend

# Create Vite React app with TypeScript
pnpm create vite . --template react-ts

# Install dependencies
pnpm install

# Install planned dependencies
pnpm add @chakra-ui/react @emotion/react @emotion/styled framer-motion
pnpm add zustand
pnpm add @tanstack/react-query
pnpm add react-router-dom
pnpm add react-hook-form
pnpm add zod

# Install dev dependencies
pnpm add -D vitest @vitest/ui
pnpm add -D @testing-library/react @testing-library/jest-dom @testing-library/user-event
pnpm add -D @types/react @types/react-dom
pnpm add -D eslint @typescript-eslint/eslint-plugin @typescript-eslint/parser
```

### Step 8: Configure TypeScript (Same as Bun)

```bash
# Use same tsconfig.json as Bun path
# See Step 6 in Path A
```

### Step 9: Verify Installation

```bash
# From project root
cd /path/to/qx

# Install all workspace dependencies
pnpm install

# Verify frontend runs
cd apps/frontend
pnpm dev

# Should start on http://localhost:5173
# Ctrl+C to stop

# Run tests
pnpm test

# Build
pnpm build
```

### Step 10: Update Documentation

```bash
# Add to README.md:

## Getting Started with pnpm

### Install pnpm
\`\`\`bash
curl -fsSL https://get.pnpm.io/install.sh | sh -
\`\`\`

### Install Dependencies
\`\`\`bash
pnpm install
\`\`\`

### Run Development Server
\`\`\`bash
cd apps/frontend
pnpm dev
\`\`\`

### Run Tests
\`\`\`bash
pnpm test
\`\`\`

### Build for Production
\`\`\`bash
pnpm build
\`\`\`
```

---

## 📦 Shared Configuration Files

### ESLint Configuration (Both Paths)

```bash
# Root .eslintrc.json
cat > .eslintrc.json << 'EOF'
{
  "root": true,
  "parser": "@typescript-eslint/parser",
  "parserOptions": {
    "ecmaVersion": 2022,
    "sourceType": "module",
    "ecmaFeatures": {
      "jsx": true
    }
  },
  "plugins": ["@typescript-eslint", "react", "react-hooks"],
  "extends": [
    "eslint:recommended",
    "plugin:@typescript-eslint/recommended",
    "plugin:react/recommended",
    "plugin:react-hooks/recommended"
  ],
  "rules": {
    "react/react-in-jsx-scope": "off"
  },
  "settings": {
    "react": {
      "version": "detect"
    }
  }
}
EOF
```

### Vitest Configuration (Both Paths)

```typescript
// apps/frontend/vitest.config.ts
import { defineConfig } from 'vitest/config'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  test: {
    globals: true,
    environment: 'jsdom',
    setupFiles: './src/test/setup.ts',
    css: true,
  },
})
```

```typescript
// apps/frontend/src/test/setup.ts
import { expect, afterEach } from 'vitest'
import { cleanup } from '@testing-library/react'
import * as matchers from '@testing-library/jest-dom/matchers'

expect.extend(matchers)

afterEach(() => {
  cleanup()
})
```

---

## 🧪 Testing the Setup

### Test Script (Both Paths)

```bash
#!/usr/bin/env bash
# test-setup.sh - Verify package manager setup

set -euo pipefail

echo "🧪 Testing package manager setup..."

# Check package manager
if command -v bun >/dev/null 2>&1; then
    echo "✅ Bun detected: $(bun --version)"
    PM="bun"
elif command -v pnpm >/dev/null 2>&1; then
    echo "✅ pnpm detected: $(pnpm --version)"
    PM="pnpm"
else
    echo "❌ No package manager found!"
    exit 1
fi

# Test installation
echo "📦 Installing dependencies..."
$PM install

# Test frontend
echo "🎨 Testing frontend..."
cd apps/frontend

# Run dev server in background
echo "🚀 Starting dev server..."
$PM dev > /dev/null 2>&1 &
DEV_PID=$!
sleep 5

# Check if running
if ps -p $DEV_PID > /dev/null; then
    echo "✅ Dev server started successfully"
    kill $DEV_PID
else
    echo "❌ Dev server failed to start"
    exit 1
fi

# Run build
echo "🏗️  Testing build..."
if $PM build; then
    echo "✅ Build successful"
else
    echo "❌ Build failed"
    exit 1
fi

echo "🎉 All tests passed!"
```

---

## 📚 Common Commands Reference

### Bun Commands

```bash
# Dependencies
bun install                    # Install all dependencies
bun add <package>              # Add package
bun add -d <package>           # Add dev dependency
bun remove <package>           # Remove package
bun update                     # Update dependencies

# Running
bun run dev                    # Start dev server
bun run build                  # Build for production
bun test                       # Run tests

# Workspace
bun install --filter ./apps/*  # Install in specific workspace
bun run --filter ./apps/* dev  # Run script in workspaces
```

### pnpm Commands

```bash
# Dependencies
pnpm install                   # Install all dependencies
pnpm add <package>             # Add package
pnpm add -D <package>          # Add dev dependency
pnpm remove <package>          # Remove package
pnpm update                    # Update dependencies

# Running
pnpm dev                       # Start dev server
pnpm build                     # Build for production
pnpm test                      # Run tests

# Workspace
pnpm install -r                # Install all workspaces
pnpm -r run dev                # Run in all workspaces
pnpm --filter frontend dev     # Run in specific workspace
```

---

## 🔄 Migration Between Package Managers

### From npm to pnpm

```bash
# Remove npm artifacts
rm -rf node_modules package-lock.json

# Install with pnpm
pnpm install

# Commit new lockfile
git add pnpm-lock.yaml
git commit -m "chore: migrate from npm to pnpm"
```

### From pnpm to Bun

```bash
# Remove pnpm artifacts
rm -rf node_modules pnpm-lock.yaml

# Install with Bun
bun install

# Commit new lockfile
git add bun.lockb
git commit -m "chore: migrate from pnpm to bun"
```

### From npm to Bun

```bash
# Remove npm artifacts
rm -rf node_modules package-lock.json

# Install with Bun
bun install

# Commit
git add bun.lockb
git commit -m "chore: migrate from npm to bun"
```

---

## 🚨 Troubleshooting

### Bun Issues

**Problem:** `bun: command not found`
```bash
# Solution: Add to PATH
export PATH="$HOME/.bun/bin:$PATH"
echo 'export PATH="$HOME/.bun/bin:$PATH"' >> ~/.bashrc
```

**Problem:** Peer dependency warnings
```bash
# Solution: Update bunfig.toml
auto-install-peers = true
```

### pnpm Issues

**Problem:** `pnpm: command not found`
```bash
# Solution: Add to PATH
export PNPM_HOME="$HOME/.local/share/pnpm"
export PATH="$PNPM_HOME:$PATH"
```

**Problem:** Phantom dependencies
```bash
# Solution: Use isolated linker
echo "node-linker=isolated" >> .npmrc
```

**Problem:** Hoisting issues
```bash
# Solution: Enable shamefully-hoist
echo "shamefully-hoist=true" >> .npmrc
```

---

## ✅ Verification Checklist

Before considering setup complete:

- [ ] Package manager installed and in PATH
- [ ] Monorepo structure created
- [ ] Workspace configuration added
- [ ] Root package.json created
- [ ] Frontend app created with Vite + React + TypeScript
- [ ] All planned dependencies installed
- [ ] Dev server runs successfully
- [ ] Tests execute correctly
- [ ] Build completes without errors
- [ ] TypeScript configuration working
- [ ] ESLint configuration working
- [ ] Documentation updated
- [ ] Team trained on new setup

---

## 📝 Next Steps After Implementation

1. **Update CI/CD** - Add package manager to GitHub Actions
2. **Team Training** - Ensure everyone knows new commands
3. **Update Scripts** - Modify any npm scripts in automation
4. **Monitor Performance** - Track build times, install times
5. **Gather Feedback** - Get team input on experience
6. **Consider Optimization** - Cache strategies, etc.

---

## 🔗 Resources

### Bun
- [Official Docs](https://bun.sh/docs)
- [Package Manager](https://bun.sh/docs/cli/install)
- [Workspaces](https://bun.sh/docs/install/workspaces)

### pnpm
- [Official Docs](https://pnpm.io/)
- [Workspaces](https://pnpm.io/workspaces)
- [Configuration](https://pnpm.io/npmrc)
- [CLI](https://pnpm.io/cli/install)

### React + Vite
- [Vite Guide](https://vitejs.dev/guide/)
- [React Docs](https://react.dev/)
- [Vitest](https://vitest.dev/)

---

**Guide Version:** 1.0.0  
**Last Updated:** October 17, 2025  
**Status:** Ready for Phase 1 Implementation  
**Maintenance:** Update when package manager versions change
