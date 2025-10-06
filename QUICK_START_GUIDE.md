# Mole v2.0 Development - Quick Start Guide

**Last Updated:** October 6, 2025  
**For Developers joining the project**

---

## 🚀 Getting Started in 5 Minutes

### Prerequisites
```bash
# macOS development environment
- macOS 12.0+ (Monterey or later)
- Bash 3.2+ (default on macOS)
- Git
- Text editor (VS Code recommended)

# Optional but recommended
- Python 3.8+ (for web dashboard)
- SQLite3 (for analytics)
```

### Clone & Setup
```bash
# Clone your fork
git clone https://github.com/hermenegildosantos/Mole.git
cd Mole

# Create development branch
git checkout -b feature/your-feature-name

# Install for development
./install.sh

# Verify installation
mo --version
```

---

## 📁 Project Structure

```
Mole/
├── mole                    # Main entry point
├── mo                      # Shortcut alias
├── install.sh              # Installation script
├── bin/                    # Command implementations
│   ├── clean.sh           # Cleanup logic
│   ├── uninstall.sh       # App uninstaller
│   └── analyze.sh         # Disk analyzer
├── lib/                    # Shared libraries
│   ├── common.sh          # Common functions
│   ├── app_selector.sh    # App selection UI
│   ├── paginated_menu.sh  # Menu system
│   ├── whitelist_manager.sh
│   └── batch_uninstall.sh
├── test/                   # Test suite (to be created)
├── docs/                   # Documentation (to be created)
├── web/                    # Web dashboard (to be created)
│   ├── templates/
│   ├── static/
│   └── api/
└── profiles/               # User profiles (to be created)

Configuration:
~/.config/mole/             # User configuration
├── config.yaml
├── whitelist
├── analytics.db
└── profiles/

Cache:
~/.cache/mole/              # Temporary data
├── backups/
└── app_scan_cache
```

---

## 🔧 Development Workflow

### 1. Pick a Task

Check the roadmap and choose a task:
```bash
# View tasks in project tracker
cat project-tracker.json | jq '.phases[0].tasks'

# Or view the roadmap
open IMPLEMENTATION_ROADMAP.md
```

### 2. Create a Branch

```bash
# Feature branch
git checkout -b feature/backup-system

# Bug fix branch
git checkout -b fix/whitelist-issue

# Documentation branch
git checkout -b docs/api-reference
```

### 3. Development

**Coding Standards:**
```bash
# Always use set -euo pipefail
set -euo pipefail

# Source common functions
source "$SCRIPT_DIR/../lib/common.sh"

# Use existing logging functions
log_info "Starting backup..."
log_success "Backup complete"
log_warning "Disk space low"
log_error "Failed to create backup"

# Follow naming conventions
function_name()          # lowercase with underscores
GLOBAL_VARIABLE="value"  # uppercase
local local_var="value"  # lowercase

# Add comments for complex logic
# Calculate growth rate over 7-day window
calculate_growth_rate() {
    # ... implementation
}
```

**File Organization:**
```bash
# New features go in lib/
lib/backup.sh           # New backup module
lib/scheduler.sh        # New scheduler module

# Command entry points go in bin/
bin/insights.sh         # New insights command

# Always make files executable
chmod +x lib/backup.sh
```

### 4. Testing

**Manual Testing:**
```bash
# Test your changes
mo clean --backup
mo restore --list

# Test dry-run mode (safe)
mo clean --dry-run

# Test edge cases
# - Empty directories
# - Large files
# - Permission errors
# - Disk full
```

**Automated Testing (to be set up):**
```bash
# Run test suite
./test/run_tests.sh

# Run specific test
./test/backup_test.sh
```

### 5. Commit & Push

```bash
# Stage changes
git add lib/backup.sh bin/clean.sh

# Commit with clear message
git commit -m "feat: add backup system with compression

- Implement backup creation with tar.gz
- Add restore functionality
- Support selective restore
- Add auto-cleanup of old backups
- Add tests for backup/restore flow

Closes #12"

# Push to your fork
git push origin feature/backup-system
```

**Commit Message Format:**
```
<type>: <short summary>

<detailed description>

<footer>
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation
- `test`: Tests
- `refactor`: Code refactoring
- `perf`: Performance improvement
- `chore`: Maintenance

### 6. Create Pull Request

1. Go to GitHub
2. Create Pull Request from your branch
3. Fill in template:

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [x] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
- [x] Tested manually
- [x] Added automated tests
- [x] Tested edge cases

## Checklist
- [x] Code follows style guidelines
- [x] Self-review completed
- [x] Comments added for complex logic
- [x] Documentation updated
- [x] No new warnings
```

---

## 🧪 Testing Guide

### Manual Test Checklist

**Before submitting PR:**
- [ ] Feature works as expected
- [ ] Dry-run mode works
- [ ] Error messages are clear
- [ ] No data loss possible
- [ ] Performance acceptable
- [ ] Works on both Intel and Apple Silicon
- [ ] Documentation updated

**Test Scenarios:**
```bash
# Happy path
mo clean --backup
mo restore

# Edge cases
mo clean --backup  # When disk is almost full
mo restore         # When no backups exist
mo clean --backup  # With very large files (10GB+)
mo restore         # When backup is corrupted

# Error handling
mo clean --backup  # Without write permissions
mo restore         # With invalid backup
```

### Writing Tests (Future)

**Test Structure:**
```bash
#!/bin/bash
# test/backup_test.sh

source "test/test_helper.sh"

test_backup_creation() {
    # Setup
    setup_test_environment
    
    # Execute
    mo clean --backup
    
    # Assert
    assert_file_exists "$HOME/.cache/mole/backups/$(date +%Y-%m-%d)*"
    assert_backup_valid
    
    # Cleanup
    cleanup_test_environment
}

test_restore_functionality() {
    # ... test implementation
}

# Run tests
run_tests
```

---

## 📚 Common Tasks

### Adding a New Command

**1. Create command file:**
```bash
# bin/mycommand.sh
#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

my_command_function() {
    log_info "Starting my command..."
    # Implementation
    log_success "Command complete"
}

# Main
my_command_function "$@"
```

**2. Add to main entry point:**
```bash
# In mole file
main() {
    case "${1:-""}" in
        # ... existing commands
        "mycommand")
            exec "$SCRIPT_DIR/bin/mycommand.sh" "${@:2}"
            ;;
        # ...
    esac
}
```

**3. Update help:**
```bash
# In mole show_help()
printf "  %s%-28s%s %s\n" "$GREEN" "mo mycommand" "$NC" "Description"
```

### Adding a Library Function

**lib/mylib.sh:**
```bash
#!/bin/bash
# My Library - Description
set -euo pipefail

# Prevent multiple sourcing
if [[ -n "${MOLE_MYLIB_LOADED:-}" ]]; then
    return 0
fi
readonly MOLE_MYLIB_LOADED=1

# Source dependencies
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

my_function() {
    local param="$1"
    # Implementation
}

export -f my_function
```

**Usage:**
```bash
source "$SCRIPT_DIR/../lib/mylib.sh"
my_function "value"
```

### Adding Configuration

**~/.config/mole/feature.conf:**
```yaml
feature:
  enabled: true
  option1: value1
  option2: value2
```

**Reading config:**
```bash
read_feature_config() {
    local config_file="$HOME/.config/mole/feature.conf"
    
    if [[ -f "$config_file" ]]; then
        # Parse YAML (simple bash approach)
        enabled=$(grep "enabled:" "$config_file" | awk '{print $2}')
    fi
}
```

### Adding Database Tables

**For analytics features:**
```sql
-- schema/my_feature.sql
CREATE TABLE my_table (
    id INTEGER PRIMARY KEY,
    timestamp INTEGER NOT NULL,
    data TEXT
);

CREATE INDEX idx_my_table_timestamp ON my_table(timestamp);
```

**In code:**
```bash
init_my_database() {
    local db_path="$HOME/.config/mole/analytics.db"
    
    sqlite3 "$db_path" < "$SCRIPT_DIR/../schema/my_feature.sql"
}
```

---

## 🐛 Debugging Tips

### Enable Verbose Mode
```bash
# Add debug output
set -x  # Print commands as they execute

# Or use logging
log_info "DEBUG: Variable value = $my_var"
```

### Check Logs
```bash
# View mole logs
tail -f ~/.config/mole/mole.log

# View scheduler logs
tail -f /tmp/mole-scheduler.log
```

### Common Issues

**Issue: Permission denied**
```bash
# Check file permissions
ls -la ~/.config/mole/

# Fix permissions
chmod 755 bin/clean.sh
```

**Issue: Command not found**
```bash
# Check PATH
echo $PATH

# Re-install
./install.sh --prefix /usr/local/bin
```

**Issue: Syntax error**
```bash
# Check bash version
bash --version

# Test script syntax
bash -n bin/clean.sh
```

---

## 📖 Resources

### Documentation
- **PRD**: `IMPROVEMENTS_PRD.md` - Product requirements
- **Roadmap**: `IMPLEMENTATION_ROADMAP.md` - Implementation plan
- **Tracker**: `project-tracker.json` - Task tracking

### Code Style
- Use shellcheck for linting: `shellcheck bin/clean.sh`
- Follow existing code patterns
- Add comments for complex logic
- Keep functions focused (single responsibility)

### Helpful Commands
```bash
# Find function usage
grep -r "function_name" lib/ bin/

# Find TODO items
grep -r "TODO\|FIXME" .

# Count lines of code
find . -name "*.sh" | xargs wc -l

# Check for common issues
shellcheck bin/*.sh lib/*.sh
```

---

## 🤝 Getting Help

### Ask Questions
- GitHub Issues: For bugs and features
- Discussions: For questions and ideas
- Comments in code: For implementation details

### Code Review
- Request review from lead developer
- Address all feedback
- Be open to suggestions

### Pair Programming
- Schedule pairing sessions for complex features
- Share knowledge with team
- Learn from others

---

## 📊 Progress Tracking

### Check Your Progress
```bash
# View current sprint
cat project-tracker.json | jq '.phases[0].tasks[] | select(.status=="in_progress")'

# View completed tasks
cat project-tracker.json | jq '.phases[0].tasks[] | select(.status=="done")'
```

### Update Task Status
```bash
# Edit project-tracker.json
{
  "id": "1.2",
  "status": "in_progress",  # or "done"
  "assignee": "Your Name"
}
```

---

## ✅ Pre-Commit Checklist

Before every commit:
- [ ] Code works as expected
- [ ] No syntax errors (`bash -n script.sh`)
- [ ] Follows style guidelines
- [ ] Comments added for complex logic
- [ ] No hardcoded paths (use `$HOME`)
- [ ] Error handling in place
- [ ] Tested manually
- [ ] Documentation updated if needed

---

## 🚢 Release Process

### Version Numbers
- **v2.0.x**: Patch (bug fixes)
- **v2.x.0**: Minor (new features)
- **v3.0.0**: Major (breaking changes)

### Release Checklist
- [ ] All tests pass
- [ ] Documentation updated
- [ ] CHANGELOG.md updated
- [ ] Version bumped in `mole` file
- [ ] Git tag created
- [ ] Release notes written

---

## 🎓 Learning Resources

### Bash Scripting
- [Advanced Bash-Scripting Guide](https://tldp.org/LDP/abs/html/)
- [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html)
- [Bash Pitfalls](https://mywiki.wooledge.org/BashPitfalls)

### macOS Development
- [macOS Command Line Tools](https://developer.apple.com/library/archive/technotes/tn2339/)
- [Launch Agents/Daemons](https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPSystemStartup/)

### SQLite
- [SQLite Documentation](https://www.sqlite.org/docs.html)
- [SQL Tutorial](https://www.sqlitetutorial.net/)

---

## 💡 Pro Tips

1. **Use dry-run extensively** - Always test with `--dry-run` first
2. **Backup before testing** - Use your own tool! `mo clean --backup`
3. **Test on multiple Macs** - Intel vs Apple Silicon
4. **Profile performance** - Use `time` command
5. **Read existing code** - Learn patterns from current codebase
6. **Ask for help early** - Don't struggle alone
7. **Document as you go** - Future you will thank you
8. **Have fun!** - We're building something cool 🚀

---

**Ready to contribute? Pick a task from the roadmap and dive in!**

**Questions?** Open an issue or start a discussion on GitHub.

**Happy Coding! 🐹**
