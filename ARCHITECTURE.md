# QX Installation Framework - Technical Architecture

**Version:** 2.0.0  
**Status:** Production Ready  
**Last Updated:** October 17, 2025

---

## 📐 System Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    User / CI/CD Pipeline                         │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│              install-prereqs.sh (Entry Point)                    │
│  • Argument parsing & validation                                 │
│  • Profile selection (minimal/development/full)                  │
│  • Orchestration & error handling                                │
└────────┬────────────┬────────────┬───────────────┬──────────────┘
         │            │            │               │
         ▼            ▼            ▼               ▼
┌────────────┐ ┌───────────┐ ┌──────────┐ ┌───────────────┐
│   Config   │ │  Logger   │ │  Utils   │ │ Plugin Manager│
│  (YAML)    │ │           │ │          │ │               │
└────────────┘ └───────────┘ └──────────┘ └───────┬───────┘
                                                    │
                  ┌─────────────────────────────────┤
                  │                                 │
      ┌───────────▼──────────┐         ┌──────────▼──────────┐
      │   Platform Detection │         │   Download Manager  │
      │  • OS/Arch check     │         │  • HTTPS only       │
      │  • Version compare   │         │  • Checksums        │
      └──────────────────────┘         │  • Retry logic      │
                                       └─────────────────────┘
                                                    │
                  ┌─────────────────────────────────┤
                  │                 │               │
         ┌────────▼──────┐  ┌──────▼──────┐  ┌────▼─────┐
         │  Plugin: Bun  │  │Plugin: Kind │  │Plugin: X │
         │  • detect()   │  │• detect()   │  │• detect()│
         │  • install()  │  │• install()  │  │• install()│
         │  • verify()   │  │• verify()   │  │• verify() │
         │  • uninstall()│  │• uninstall()│  │• uninstall()│
         └───────┬───────┘  └──────┬──────┘  └────┬─────┘
                 │                 │               │
                 └─────────────────┴───────────────┘
                             │
                    ┌────────▼────────┐
                    │  Rollback       │
                    │  • Track changes│
                    │  • Restore state│
                    └─────────────────┘
```

---

## 🧩 Component Details

### 1. Core Components (`scripts/lib/`)

#### config.sh (316 lines)
**Purpose:** Configuration management and validation

**Key Functions:**
- `load_config()` - Parse YAML configuration files
- `validate_config()` - Validate tool configurations
- `get_config_value()` - Retrieve nested config values
- `merge_config()` - Merge multiple config sources

**Features:**
- YAML parsing (pure Bash, no dependencies)
- Nested key access (dot notation: `tools.bun.version`)
- Type validation (versions, paths, enums)
- Profile validation against plugin registry

**Configuration Schema:**
```yaml
global:
  log_level, cache_dir, temp_dir, parallel_downloads,
  download_timeout, retry_attempts, retry_delay

platform:
  min_ubuntu_version, architectures, required_system_packages

profiles:
  minimal: [tools...]
  development: [tools...]
  full: [tools...]

security:
  verify_checksums, require_https, allow_insecure_downloads,
  temp_file_permissions

tools:
  [tool_name]:
    version: "x.y.z"
    [tool-specific settings]

channels:
  stable: {tool: version}
  latest: {tool: version}
```

#### rollback.sh (343 lines)
**Purpose:** Automatic rollback and system restoration

**Key Functions:**
- `register_rollback()` - Register actions for rollback
- `perform_rollback()` - Execute rollback procedures
- `rollback_file_operation()` - Restore files
- `rollback_environment()` - Restore environment variables

**Rollback Types:**
1. **File Operations** - Backup/restore files
2. **Package Operations** - Uninstall packages
3. **Environment Variables** - Restore shell configs
4. **Binary Installations** - Remove installed binaries

**State Tracking:**
```bash
ROLLBACK_ACTIONS=()        # Stack of rollback actions
ROLLBACK_FILES=()          # Backup file locations
ROLLBACK_STATE_FILE=/tmp   # Persistent state file
```

#### plugin_manager.sh (291 lines)
**Purpose:** Plugin lifecycle and registry management

**Key Functions:**
- `load_plugins()` - Load plugins from registry
- `validate_plugin()` - Validate plugin interface
- `execute_plugin()` - Execute plugin functions
- `list_plugins()` - List available plugins

**Plugin Registry:**
```bash
PLUGIN_REGISTRY=(
    "bun"
    "podman"
    "kubectl"
    "kind"
)
```

**Required Plugin Interface:**
```bash
# Detection
detect_[tool]() -> 0 (found) | 1 (not found)

# Installation
install_[tool]() -> 0 (success) | 1 (failure)

# Verification
verify_[tool]() -> 0 (valid) | 1 (invalid)

# Removal
uninstall_[tool]() -> 0 (success) | 1 (failure)
```

#### downloader.sh (182 lines)
**Purpose:** Secure file downloads with verification

**Key Functions:**
- `download_file()` - Download with retry logic
- `verify_checksum()` - Verify SHA256 checksums
- `extract_archive()` - Extract tar/zip files
- `cleanup_downloads()` - Clean temporary files

**Security Features:**
- HTTPS enforcement (configurable)
- SHA256 checksum verification
- Retry logic with exponential backoff
- Secure temp file permissions (600)
- Automatic cleanup on error

**Download Flow:**
```
1. Validate URL (HTTPS check)
2. Create secure temp file
3. Download with curl (retry on failure)
4. Verify checksum (if provided)
5. Extract if archive
6. Move to destination
7. Cleanup temp files
```

#### platform.sh (174 lines)
**Purpose:** Platform detection and compatibility

**Key Functions:**
- `detect_platform()` - Detect OS and architecture
- `check_system_requirements()` - Verify prerequisites
- `compare_versions()` - Semantic version comparison
- `get_package_manager()` - Detect package manager

**Supported Platforms:**
- **OS:** Ubuntu 24.04+ (primary), expandable
- **Architecture:** x86_64, aarch64
- **Package Managers:** apt, dnf, yum (extensible)

#### utils.sh (218 lines)
**Purpose:** Common utility functions

**Key Functions:**
- `command_exists()` - Check if command is available
- `is_root()` - Check root privileges
- `create_temp_dir()` - Create secure temp directories
- `cleanup_temp_files()` - Remove temporary files
- `join_array()` - Join array elements
- `trim_string()` - Trim whitespace

#### logger.sh (86 lines)
**Purpose:** Structured logging

**Key Functions:**
- `log_debug()`, `log_info()`, `log_warn()`, `log_error()`
- `log_success()` - Success messages with color
- `log_step()` - Step progress indicators

**Log Levels:**
- DEBUG (verbose output)
- INFO (standard output)
- WARN (warnings)
- ERROR (errors)

**Features:**
- Color-coded output (optional)
- File logging (optional)
- Timestamp prefixes
- Structured format

---

### 2. Plugin System (`scripts/plugins/`)

#### Plugin Architecture

Each plugin is a self-contained Bash script implementing the standard interface:

```bash
#!/bin/bash
# Plugin: [tool_name]

# Detection - Check if tool is installed
detect_[tool]() {
    if command_exists [tool]; then
        return 0
    fi
    return 1
}

# Installation - Install the tool
install_[tool]() {
    log_info "Installing [tool]..."
    
    # Get version from config
    VERSION=$(get_config_value "tools.[tool].version")
    
    # Download and install
    # ... installation logic ...
    
    return 0
}

# Verification - Verify installation
verify_[tool]() {
    if ! detect_[tool]; then
        return 1
    fi
    
    # Version check
    INSTALLED_VERSION=$([tool] --version)
    # ... verification logic ...
    
    return 0
}

# Uninstallation - Remove the tool
uninstall_[tool]() {
    log_info "Uninstalling [tool]..."
    
    # Remove binaries/packages
    # ... uninstallation logic ...
    
    return 0
}
```

#### Current Plugins

| Plugin | Lines | Install Method | Key Features |
|--------|-------|----------------|--------------|
| **bun.sh** | 155 | Binary download | Multi-arch, env setup |
| **podman.sh** | 115 | APT package | Repository setup |
| **kubectl.sh** | 119 | Binary download | Version pinning |
| **kind.sh** | 119 | Binary download | Kubernetes clusters |

---

### 3. Testing Framework (`scripts/tests/`)

#### Test Infrastructure

```
tests/
├── framework.sh           # Test framework (246 lines)
│   ├── assert_equals()
│   ├── assert_contains()
│   ├── assert_command_success()
│   ├── assert_command_fails()
│   └── run_test_suite()
├── unit/
│   ├── test_config.sh     # Config tests (161 lines)
│   └── test_utils.sh      # Utility tests (156 lines)
└── integration/
    ├── test_dry_run.sh    # Dry-run tests (95 lines)
    ├── test_rollback.sh   # Rollback tests
    └── test_error_handling.sh # Error tests
```

#### Test Execution Flow

```
1. run-tests.sh invoked
2. Spin up Podman container (Ubuntu 24.04)
3. Mount project directory (read-only)
4. Install test dependencies (curl, unzip, bc)
5. Source test framework
6. Run test suites
   - Unit tests (isolated function tests)
   - Integration tests (full script workflows)
7. Collect results
8. Destroy container
9. Report pass/fail
```

---

## 🔄 Installation Workflow

### High-Level Flow

```
┌─────────────────────┐
│  User runs script   │
│  with arguments     │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ Parse & validate    │
│ arguments           │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ Load & validate     │
│ configuration       │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ Check root/sudo     │
│ privileges          │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ Detect platform &   │
│ verify requirements │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ Load plugins from   │
│ explicit registry   │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ For each tool:      │
│  1. Detect          │
│  2. Install         │◄────┐
│  3. Verify          │     │
│  4. Register        │     │
│     rollback        │     │
└──────────┬──────────┘     │
           │                │
           ├─ SUCCESS ──────┤
           │                │
           ├─ FAILURE       │
           │                │
           ▼                │
┌─────────────────────┐     │
│ Perform automatic   │     │
│ rollback            │─────┘
└─────────────────────┘
           │
           ▼
┌─────────────────────┐
│ Show summary &      │
│ cleanup             │
└─────────────────────┘
```

### Detailed Installation Steps

1. **Initialization**
   - Set shell options (`set -euo pipefail`)
   - Determine script directory
   - Source core libraries

2. **Configuration Loading**
   - Load default.yaml
   - Merge with custom config (if provided)
   - Validate configuration schema

3. **Argument Parsing**
   - Parse command-line arguments
   - Validate profile/tool names
   - Set flags (dry-run, force, etc.)

4. **Prerequisites Check**
   - Check OS and architecture
   - Verify system packages (curl, ca-certificates, etc.)
   - Check root/sudo privileges

5. **Plugin Loading**
   - Iterate through plugin registry
   - Source each plugin file
   - Validate plugin interface

6. **Tool Installation Loop**
   ```bash
   for tool in $TOOLS; do
       # Set ERR trap for automatic rollback
       trap 'handle_error $tool' ERR
       
       # Detect existing installation
       if detect_$tool && ! $FORCE; then
           log_info "$tool already installed"
           continue
       fi
       
       # Register rollback action
       register_rollback "uninstall_$tool"
       
       # Install tool
       install_$tool || return 1
       
       # Verify installation
       verify_$tool || return 1
       
       # Remove trap (successful)
       trap - ERR
   done
   ```

7. **Verification & Summary**
   - Run verification for all tools
   - Display installation summary
   - Show next steps

8. **Cleanup**
   - Remove temporary files
   - Clear sensitive data
   - Exit with status code

---

## 🔒 Security Architecture

### Defense in Depth Layers

#### Layer 1: Input Validation
```bash
# Profile validation
case "$PROFILE" in
    minimal|development|full) ;;
    *) error "Invalid profile: $PROFILE" ;;
esac

# Tool name validation (alphanumeric + hyphens/underscores)
if ! [[ "$TOOL" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    error "Invalid tool name: $TOOL"
fi

# Channel validation
case "$CHANNEL" in
    stable|latest|beta|nightly) ;;
    *) error "Invalid channel: $CHANNEL" ;;
esac
```

#### Layer 2: Download Security
- HTTPS enforcement (configurable)
- SHA256 checksum verification
- Secure temporary files (permissions: 600)
- Retry with exponential backoff
- Timeout enforcement

#### Layer 3: Execution Security
- Explicit plugin registry (no file discovery)
- Function validation before execution
- Shell option hardening (`set -euo pipefail`)
- Privilege escalation checks

#### Layer 4: File System Security
- Secure temp directories with random names
- Atomic file operations
- Automatic cleanup on error
- Backup before modification

---

## 📊 Error Handling & Recovery

### Error Handling Strategy

```bash
# Global error handler
set -E  # Inherit ERR trap in functions
trap 'handle_error ${LINENO} ${FUNCNAME:-main}' ERR

handle_error() {
    local line=$1
    local func=$2
    
    log_error "Error in $func at line $line"
    
    # Perform rollback if installation in progress
    if [[ $INSTALL_IN_PROGRESS == true ]]; then
        perform_rollback
    fi
    
    # Cleanup
    cleanup_temp_files
    
    exit 1
}
```

### Rollback Mechanism

**State Tracking:**
```bash
ROLLBACK_ACTIONS=(
    "uninstall_bun:/usr/local/bin/bun"
    "restore_file:/etc/apt/sources.list.d/podman.list.backup"
    "remove_env:BUN_INSTALL"
)
```

**Rollback Execution:**
```bash
perform_rollback() {
    log_warn "Installation failed. Performing rollback..."
    
    # Iterate rollback actions in reverse order
    for ((i=${#ROLLBACK_ACTIONS[@]}-1; i>=0; i--)); do
        local action="${ROLLBACK_ACTIONS[$i]}"
        local type="${action%%:*}"
        local data="${action#*:}"
        
        case "$type" in
            uninstall_*)
                ${type} || log_error "Rollback failed: $type"
                ;;
            restore_file)
                mv "${data}.backup" "$data" 2>/dev/null || true
                ;;
            remove_env)
                # Remove from shell configs
                ;;
        esac
    done
    
    log_info "Rollback complete"
}
```

---

## 🧪 Testing Strategy

### Test Types

#### 1. Unit Tests
- **Target:** Individual functions in isolation
- **Environment:** Mocked dependencies
- **Coverage:** Config parsing, utilities, validation

#### 2. Integration Tests
- **Target:** Full script workflows
- **Environment:** Real Podman containers
- **Coverage:** Dry-run, error handling, rollback

#### 3. Manual Testing
- **Target:** Real installations
- **Environment:** Development machines
- **Coverage:** End-to-end workflows

### Test Execution

```bash
# Run all tests
bash scripts/run-tests.sh --all

# Run specific test type
bash scripts/run-tests.sh --unit
bash scripts/run-tests.sh --integration

# Test in isolated container
podman run --rm -it \
    -v "$(pwd):/workspace:ro" \
    ubuntu:24.04 \
    bash -c "cd /workspace && bash scripts/install-prereqs.sh --dry-run"
```

---

## 📈 Performance Considerations

### Optimization Strategies

1. **Parallel Downloads**
   - Configurable parallel download limit
   - Download multiple tools simultaneously
   - Throttling to prevent network overload

2. **Caching**
   - Cache directory for downloaded files
   - Reuse cached downloads on retry
   - Version-specific cache keys

3. **Lazy Loading**
   - Load plugins on-demand
   - Defer configuration parsing
   - Minimize startup time

4. **Efficient Detection**
   - Quick command existence checks
   - Cache detection results
   - Skip unnecessary operations

---

## 🔮 Future Enhancements

### Planned Features

1. **Multi-Distribution Support**
   - Fedora, Debian, Arch, Alpine
   - Automatic package manager detection
   - Distribution-specific plugins

2. **Plugin Marketplace**
   - Remote plugin repository
   - Plugin versioning
   - Community contributions

3. **Web Interface**
   - Web-based installation UI
   - Progress visualization
   - Remote management

4. **Telemetry (Optional)**
   - Installation success metrics
   - Error tracking
   - Usage statistics

---

## 📚 References

### Standards & Conventions

- **Shell Style Guide:** Google Shell Style Guide
- **Error Codes:** LSB Exit Codes (0-255)
- **Config Format:** YAML 1.2
- **Version Format:** Semantic Versioning 2.0.0

### Dependencies

**Required System Packages:**
- `curl` - HTTP client for downloads
- `ca-certificates` - SSL/TLS certificates
- `unzip` - Archive extraction
- `bc` - Floating-point calculations
- `jq` - JSON processing (future)

**Runtime Requirements:**
- Bash 4.3+
- Linux kernel 4.x+
- 100MB free disk space (temp files)

---

## 📞 Troubleshooting

### Common Issues

**Issue:** Permission denied  
**Solution:** Run with sudo: `sudo bash scripts/install-prereqs.sh`

**Issue:** Download timeout  
**Solution:** Increase timeout in config: `download_timeout: 600`

**Issue:** Checksum verification failed  
**Solution:** Clear cache: `rm -rf /var/cache/qx-install`

**Issue:** Rollback failed  
**Solution:** Check logs and manually remove files

---

**Architecture Version:** 2.0.0  
**Last Updated:** October 17, 2025  
**Maintainer:** QX Development Team
