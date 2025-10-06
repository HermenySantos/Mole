#!/usr/bin/env bash

# ===============================================
# Integration Test Suite
# ===============================================
# Tests all new features integrated into clean.sh
# ===============================================

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "═══════════════════════════════════════════════════════════"
echo "  Mole Integration Test Suite"
echo "═══════════════════════════════════════════════════════════"
echo ""

# Test counter
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test function
run_test() {
    local test_name="$1"
    local test_cmd="$2"
    
    ((TESTS_RUN++))
    echo "Test $TESTS_RUN: $test_name"
    echo "Command: $test_cmd"
    
    if eval "$test_cmd" > /tmp/mole_test_output_$TESTS_RUN.txt 2>&1; then
        echo "  ✅ PASSED"
        ((TESTS_PASSED++))
    else
        echo "  ❌ FAILED"
        echo "  Output:"
        cat /tmp/mole_test_output_$TESTS_RUN.txt | head -20
        ((TESTS_FAILED++))
    fi
    echo ""
}

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  1. Command-Line Flag Tests"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

run_test "Help flag" "bash '$PROJECT_ROOT/bin/clean.sh' --help"
run_test "Dry-run flag" "bash '$PROJECT_ROOT/bin/clean.sh' --dry-run --summary"
run_test "Tree view flag" "bash '$PROJECT_ROOT/bin/clean.sh' --dry-run --tree"
run_test "Detailed view flag" "bash '$PROJECT_ROOT/bin/clean.sh' --dry-run --detailed"
run_test "Export JSON flag" "bash '$PROJECT_ROOT/bin/clean.sh' --dry-run --export json | head -5"
run_test "Export CSV flag" "bash '$PROJECT_ROOT/bin/clean.sh' --dry-run --export csv | head -5"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  2. Library Integration Tests"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

run_test "Backup library loads" "bash -c 'source \"$PROJECT_ROOT/lib/common.sh\" && source \"$PROJECT_ROOT/lib/backup.sh\" && echo ok'"
run_test "Display library loads" "bash -c 'source \"$PROJECT_ROOT/lib/common.sh\" && source \"$PROJECT_ROOT/lib/dry_run_display.sh\" && echo ok'"
run_test "Preview library loads" "bash -c 'source \"$PROJECT_ROOT/lib/common.sh\" && source \"$PROJECT_ROOT/lib/interactive_preview.sh\" && echo ok'"
run_test "Export library loads" "bash -c 'source \"$PROJECT_ROOT/lib/common.sh\" && source \"$PROJECT_ROOT/lib/export.sh\" && echo ok'"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  3. Function Availability Tests"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

run_test "Display function available" "bash -c 'source \"$PROJECT_ROOT/lib/common.sh\" && source \"$PROJECT_ROOT/lib/dry_run_display.sh\" && declare -f display_summary_table'"
run_test "Export function available" "bash -c 'source \"$PROJECT_ROOT/lib/common.sh\" && source \"$PROJECT_ROOT/lib/export.sh\" && declare -f export_cleanup_data'"
run_test "Preview function available" "bash -c 'source \"$PROJECT_ROOT/lib/common.sh\" && source \"$PROJECT_ROOT/lib/paginated_menu.sh\" && source \"$PROJECT_ROOT/lib/interactive_preview.sh\" && declare -f interactive_cleanup_preview'"
run_test "Backup function available" "bash -c 'source \"$PROJECT_ROOT/lib/common.sh\" && source \"$PROJECT_ROOT/lib/backup.sh\" && declare -f create_backup'"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  4. Data Collection Tests"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

run_test "Category tracking works" "bash -c 'source \"$PROJECT_ROOT/lib/common.sh\" && source \"$PROJECT_ROOT/lib/dry_run_display.sh\" && add_category_item \"Test\" \"Item1\" 1024000 100 && echo \${#CATEGORY_DATA[@]}'"
run_test "Item collection works" "bash -c 'source \"$PROJECT_ROOT/lib/common.sh\" && source \"$PROJECT_ROOT/lib/dry_run_display.sh\" && add_category_item \"Test\" \"Item1\" 1024000 100 && echo \${#CATEGORY_ITEMS[@]}'"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  5. Export Format Tests"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Create test data
TEST_SCRIPT='
source "$PROJECT_ROOT/lib/common.sh"
source "$PROJECT_ROOT/lib/dry_run_display.sh"
source "$PROJECT_ROOT/lib/export.sh"
add_category_item "Browser Caches" "Chrome" 4074848256 456
add_category_item "Developer Tools" "npm cache" 1288490189 234
export_cleanup_data json | head -10
'

run_test "JSON export works" "bash -c '$TEST_SCRIPT'"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Test Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Total Tests:  $TESTS_RUN"
echo "Passed:       $TESTS_PASSED ✅"
echo "Failed:       $TESTS_FAILED ❌"
echo ""

if [[ $TESTS_FAILED -eq 0 ]]; then
    echo "🎉 All tests passed!"
    exit 0
else
    echo "⚠️  Some tests failed. Check output above for details."
    exit 1
fi
