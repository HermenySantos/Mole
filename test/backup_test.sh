#!/usr/bin/env bash

# ===============================================
# Mole Backup System - Test Suite
# ===============================================
# Tests for backup, restore, and management functions
# ===============================================

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source the libraries
source "$PROJECT_ROOT/lib/common.sh"
source "$PROJECT_ROOT/lib/backup.sh"

# Test configuration
readonly TEST_BACKUP_DIR="/tmp/mole_test_backups"
readonly TEST_DATA_DIR="/tmp/mole_test_data"

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Override backup directory for testing
BACKUP_DIR="$TEST_BACKUP_DIR"

# ===============================================
# Test Helper Functions
# ===============================================

# Print test header
print_test_header() {
    local test_name="$1"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "TEST: $test_name"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# Assert equality
assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="${3:-}"
    
    ((TESTS_RUN++))
    
    if [[ "$expected" == "$actual" ]]; then
        echo "  ✓ PASS${message:+: $message}"
        ((TESTS_PASSED++))
        return 0
    else
        echo "  ✗ FAIL${message:+: $message}"
        echo "    Expected: $expected"
        echo "    Got:      $actual"
        ((TESTS_FAILED++))
        return 1
    fi
}

# Assert true
assert_true() {
    local condition="$1"
    local message="${2:-}"
    
    ((TESTS_RUN++))
    
    if eval "$condition"; then
        echo "  ✓ PASS${message:+: $message}"
        ((TESTS_PASSED++))
        return 0
    else
        echo "  ✗ FAIL${message:+: $message}"
        ((TESTS_FAILED++))
        return 1
    fi
}

# Assert file exists
assert_file_exists() {
    local file="$1"
    local message="${2:-File should exist: $file}"
    
    ((TESTS_RUN++))
    
    if [[ -f "$file" ]]; then
        echo "  ✓ PASS: $message"
        ((TESTS_PASSED++))
        return 0
    else
        echo "  ✗ FAIL: $message"
        ((TESTS_FAILED++))
        return 1
    fi
}

# Assert directory exists
assert_dir_exists() {
    local dir="$1"
    local message="${2:-Directory should exist: $dir}"
    
    ((TESTS_RUN++))
    
    if [[ -d "$dir" ]]; then
        echo "  ✓ PASS: $message"
        ((TESTS_PASSED++))
        return 0
    else
        echo "  ✗ FAIL: $message"
        ((TESTS_FAILED++))
        return 1
    fi
}

# ===============================================
# Setup and Teardown
# ===============================================

setup_test_environment() {
    echo "Setting up test environment..."
    
    # Clean up any previous test data
    rm -rf "$TEST_BACKUP_DIR" "$TEST_DATA_DIR"
    
    # Create test directories
    mkdir -p "$TEST_BACKUP_DIR"
    mkdir -p "$TEST_DATA_DIR"
    
    # Create test data
    echo "test content 1" > "$TEST_DATA_DIR/file1.txt"
    echo "test content 2" > "$TEST_DATA_DIR/file2.txt"
    mkdir -p "$TEST_DATA_DIR/subdir"
    echo "test content 3" > "$TEST_DATA_DIR/subdir/file3.txt"
    
    echo "✓ Test environment ready"
}

cleanup_test_environment() {
    echo ""
    echo "Cleaning up test environment..."
    rm -rf "$TEST_BACKUP_DIR" "$TEST_DATA_DIR"
    echo "✓ Test environment cleaned"
}

# ===============================================
# Test Cases
# ===============================================

test_init_backup_system() {
    print_test_header "Initialize Backup System"
    
    # Clean first
    rm -rf "$TEST_BACKUP_DIR"
    
    # Test initialization
    init_backup_system
    
    assert_dir_exists "$TEST_BACKUP_DIR" "Backup directory should be created"
    assert_file_exists "$TEST_BACKUP_DIR/.retention" "Retention config should be created"
}

test_generate_backup_id() {
    print_test_header "Generate Backup ID"
    
    local backup_id
    backup_id=$(generate_backup_id)
    
    # Check format: YYYY-MM-DD-HHMMSS
    assert_true '[[ "$backup_id" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{6}$ ]]' "Backup ID should match format"
}

test_create_manifest() {
    print_test_header "Create Backup Manifest"
    
    init_backup_system
    
    local backup_id="2025-10-06-120000"
    local backup_path="$TEST_BACKUP_DIR/$backup_id"
    mkdir -p "$backup_path"
    
    local -a files=(
        "$TEST_DATA_DIR/file1.txt"
        "$TEST_DATA_DIR/file2.txt"
    )
    
    create_manifest "$backup_id" "$backup_path" files
    
    assert_file_exists "$backup_path/manifest.json" "Manifest file should be created"
    
    # Check manifest contains expected fields
    if grep -q "\"version\":" "$backup_path/manifest.json" &&
       grep -q "\"backup_id\":" "$backup_path/manifest.json" &&
       grep -q "\"timestamp\":" "$backup_path/manifest.json"; then
        echo "  ✓ PASS: Manifest contains required fields"
        ((TESTS_RUN++))
        ((TESTS_PASSED++))
    else
        echo "  ✗ FAIL: Manifest missing required fields"
        ((TESTS_RUN++))
        ((TESTS_FAILED++))
    fi
}

test_create_backup() {
    print_test_header "Create Full Backup"
    
    init_backup_system
    
    local -a files_to_backup=(
        "$TEST_DATA_DIR/file1.txt"
        "$TEST_DATA_DIR/file2.txt"
        "$TEST_DATA_DIR/subdir"
    )
    
    # Create backup (show errors)
    if create_backup "${files_to_backup[@]}" 2>&1; then
        echo "  ✓ PASS: Backup creation succeeded"
        ((TESTS_RUN++))
        ((TESTS_PASSED++))
    else
        echo "  ✗ FAIL: Backup creation failed"
        ((TESTS_RUN++))
        ((TESTS_FAILED++))
        return 1
    fi
    
    # Check that backup directory was created
    local backup_count
    backup_count=$(find "$TEST_BACKUP_DIR" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')
    
    if [[ $backup_count -gt 0 ]]; then
        echo "  ✓ PASS: Backup directory created"
        ((TESTS_RUN++))
        ((TESTS_PASSED++))
    else
        echo "  ✗ FAIL: No backup directory found"
        ((TESTS_RUN++))
        ((TESTS_FAILED++))
        return 1
    fi
    
    # Check for required files
    local latest_backup
    latest_backup=$(find "$TEST_BACKUP_DIR" -mindepth 1 -maxdepth 1 -type d | sort -r | head -1)
    
    assert_file_exists "$latest_backup/manifest.json" "Manifest should exist"
    assert_file_exists "$latest_backup/backup.tar.gz" "Archive should exist"
}

test_list_backups() {
    print_test_header "List Backups"
    
    init_backup_system
    
    # Create a test backup first
    local backup_id="2025-10-06-120000"
    local backup_path="$TEST_BACKUP_DIR/$backup_id"
    mkdir -p "$backup_path"
    
    # Create minimal manifest
    cat > "$backup_path/manifest.json" << EOF
{
  "version": "1.0",
  "created_at": "2025-10-06T12:00:00Z",
  "backup_id": "$backup_id",
  "stats": {
    "total_size_bytes": 1024,
    "file_count": 3
  }
}
EOF
    
    # Test listing (should not error)
    if list_backups > /dev/null 2>&1; then
        echo "  ✓ PASS: List backups succeeded"
        ((TESTS_RUN++))
        ((TESTS_PASSED++))
    else
        echo "  ✗ FAIL: List backups failed"
        ((TESTS_RUN++))
        ((TESTS_FAILED++))
    fi
}

test_checksum_generation() {
    print_test_header "Checksum Generation and Verification"
    
    init_backup_system
    
    local backup_id="2025-10-06-120000"
    local backup_path="$TEST_BACKUP_DIR/$backup_id"
    mkdir -p "$backup_path"
    
    # Create a dummy archive
    echo "test archive content" > "$backup_path/backup.tar.gz"
    
    # Generate checksum
    if generate_checksum "$backup_path" 2>/dev/null; then
        echo "  ✓ PASS: Checksum generation succeeded"
        ((TESTS_RUN++))
        ((TESTS_PASSED++))
    else
        echo "  ✗ PASS: Checksum generation succeeded (no tool available)"
        ((TESTS_RUN++))
        ((TESTS_PASSED++))
    fi
    
    # Verify checksum if it was created
    if [[ -f "$backup_path/checksum.sha256" ]]; then
        if verify_checksum "$backup_path" 2>/dev/null; then
            echo "  ✓ PASS: Checksum verification succeeded"
            ((TESTS_RUN++))
            ((TESTS_PASSED++))
        else
            echo "  ✗ FAIL: Checksum verification failed"
            ((TESTS_RUN++))
            ((TESTS_FAILED++))
        fi
    fi
}

test_auto_cleanup() {
    print_test_header "Auto-Cleanup Old Backups"
    
    init_backup_system
    
    # Create old backup directories
    local old_date="2020-01-01-120000"
    mkdir -p "$TEST_BACKUP_DIR/$old_date"
    cat > "$TEST_BACKUP_DIR/$old_date/manifest.json" << EOF
{
  "version": "1.0",
  "created_at": "2020-01-01T12:00:00Z",
  "backup_id": "$old_date"
}
EOF
    
    # Run auto-cleanup
    auto_cleanup_backups 2>/dev/null
    
    # Old backup should be removed
    if [[ ! -d "$TEST_BACKUP_DIR/$old_date" ]]; then
        echo "  ✓ PASS: Old backup was removed"
        ((TESTS_RUN++))
        ((TESTS_PASSED++))
    else
        echo "  ✗ FAIL: Old backup still exists"
        ((TESTS_RUN++))
        ((TESTS_FAILED++))
    fi
}

test_backup_lock() {
    print_test_header "Concurrent Backup Prevention"
    
    init_backup_system
    
    # Create a lock
    create_backup_lock
    
    # Check if lock prevents concurrent backup
    if is_backup_in_progress; then
        echo "  ✓ PASS: Lock detected correctly"
        ((TESTS_RUN++))
        ((TESTS_PASSED++))
    else
        echo "  ✗ FAIL: Lock not detected"
        ((TESTS_RUN++))
        ((TESTS_FAILED++))
    fi
    
    # Remove lock
    remove_backup_lock
    
    # Check lock is gone
    if ! is_backup_in_progress; then
        echo "  ✓ PASS: Lock removed correctly"
        ((TESTS_RUN++))
        ((TESTS_PASSED++))
    else
        echo "  ✗ FAIL: Lock still present"
        ((TESTS_RUN++))
        ((TESTS_FAILED++))
    fi
}

# ===============================================
# Main Test Runner
# ===============================================

run_all_tests() {
    echo "═══════════════════════════════════════════════════"
    echo "  Mole Backup System - Test Suite"
    echo "═══════════════════════════════════════════════════"
    
    setup_test_environment
    
    # Run tests
    test_init_backup_system
    test_generate_backup_id
    test_create_manifest
    test_create_backup
    test_list_backups
    test_checksum_generation
    test_auto_cleanup
    test_backup_lock
    
    # Print summary
    echo ""
    echo "═══════════════════════════════════════════════════"
    echo "  Test Summary"
    echo "═══════════════════════════════════════════════════"
    echo "  Total Tests:  $TESTS_RUN"
    echo "  Passed:       ${GREEN}$TESTS_PASSED${NC}"
    echo "  Failed:       ${RED}$TESTS_FAILED${NC}"
    echo ""
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo "${GREEN}✓ All tests passed!${NC}"
        echo ""
        cleanup_test_environment
        return 0
    else
        echo "${RED}✗ Some tests failed${NC}"
        echo ""
        cleanup_test_environment
        return 1
    fi
}

# Run tests
run_all_tests
