#!/usr/bin/env bash

# ===============================================
# Export Functionality - Demonstration
# ===============================================

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source libraries
source "$PROJECT_ROOT/lib/common.sh"
source "$PROJECT_ROOT/lib/dry_run_display.sh"
source "$PROJECT_ROOT/lib/export.sh"

echo "═══════════════════════════════════════════════════════════"
echo "  Export Functionality - Demonstration"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "Loading sample cleanup data..."
echo ""

# Simulate collecting cleanup data
add_category_item "Browser Caches" "Google Chrome" 4074848256 456
add_category_item "Browser Caches" "Firefox" 935718912 234
add_category_item "Browser Caches" "Safari" 536870912 78

add_category_item "Developer Tools" "npm cache" 1288490189 234
add_category_item "Developer Tools" "pip cache" 897581056 89
add_category_item "Developer Tools" "Docker" 245366784 32

add_category_item "App Caches" "Slack" 594542592 123
add_category_item "App Caches" "Spotify" 676331520 111

add_category_item "Logs" "Application Logs" 268435456 123
add_category_item "Logs" "System Logs" 134217728 67

add_category_item "Trash" "User Trash" 245366784 45

echo "✓ Data loaded (5 categories, 11 items, ~9GB)"
echo ""

# Create output directory
OUTPUT_DIR="/tmp/mole_export_demo"
mkdir -p "$OUTPUT_DIR"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Generating Export Files"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Export to JSON
echo "1. Exporting to JSON..."
export_cleanup_data json > "$OUTPUT_DIR/cleanup_report.json"
echo "   ✓ Saved: $OUTPUT_DIR/cleanup_report.json"
echo "   Size: $(du -h "$OUTPUT_DIR/cleanup_report.json" | cut -f1)"
echo ""

# Export to CSV
echo "2. Exporting to CSV..."
export_cleanup_data csv > "$OUTPUT_DIR/cleanup_report.csv"
echo "   ✓ Saved: $OUTPUT_DIR/cleanup_report.csv"
echo "   Size: $(du -h "$OUTPUT_DIR/cleanup_report.csv" | cut -f1)"
echo ""

# Export to Markdown
echo "3. Exporting to Markdown..."
export_cleanup_data markdown > "$OUTPUT_DIR/cleanup_report.md"
echo "   ✓ Saved: $OUTPUT_DIR/cleanup_report.md"
echo "   Size: $(du -h "$OUTPUT_DIR/cleanup_report.md" | cut -f1)"
echo ""

# Export to HTML
echo "4. Exporting to HTML..."
export_cleanup_data html > "$OUTPUT_DIR/cleanup_report.html"
echo "   ✓ Saved: $OUTPUT_DIR/cleanup_report.html"
echo "   Size: $(du -h "$OUTPUT_DIR/cleanup_report.html" | cut -f1)"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Sample Outputs"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Show JSON sample
echo "JSON Preview:"
echo "─────────────────────────────────────"
head -20 "$OUTPUT_DIR/cleanup_report.json"
echo "  ..."
echo "─────────────────────────────────────"
echo ""

# Show CSV sample
echo "CSV Preview:"
echo "─────────────────────────────────────"
head -10 "$OUTPUT_DIR/cleanup_report.csv"
echo "  ..."
echo "─────────────────────────────────────"
echo ""

# Show Markdown sample
echo "Markdown Preview:"
echo "─────────────────────────────────────"
head -25 "$OUTPUT_DIR/cleanup_report.md"
echo "  ..."
echo "─────────────────────────────────────"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Export Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Files available in: ${BLUE}$OUTPUT_DIR${NC}"
echo ""
echo "Usage examples:"
echo "  ${BLUE}cat $OUTPUT_DIR/cleanup_report.json${NC}"
echo "  ${BLUE}open $OUTPUT_DIR/cleanup_report.html${NC}"
echo "  ${BLUE}open -a Numbers $OUTPUT_DIR/cleanup_report.csv${NC}"
echo ""
echo "Command-line usage:"
echo "  ${BLUE}mo clean --dry-run --export json > report.json${NC}"
echo "  ${BLUE}mo clean --dry-run --export csv > report.csv${NC}"
echo "  ${BLUE}mo clean --dry-run --export md > report.md${NC}"
echo "  ${BLUE}mo clean --dry-run --export html > report.html${NC}"
echo ""

# Offer to open files
if [[ -t 0 ]]; then
    echo "Would you like to:"
    echo "  1) View JSON in terminal"
    echo "  2) Open HTML in browser"
    echo "  3) Open CSV in Numbers/Excel"
    echo "  4) View Markdown in terminal"
    echo "  5) Skip"
    echo ""
    read -p "Choice (1-5): " -n 1 -r choice
    echo ""
    echo ""
    
    case "$choice" in
        1)
            cat "$OUTPUT_DIR/cleanup_report.json" | head -100
            ;;
        2)
            if command -v open >/dev/null 2>&1; then
                open "$OUTPUT_DIR/cleanup_report.html"
                echo "✓ Opened HTML report in browser"
            else
                echo "✗ 'open' command not available"
            fi
            ;;
        3)
            if command -v open >/dev/null 2>&1; then
                open "$OUTPUT_DIR/cleanup_report.csv"
                echo "✓ Opened CSV report"
            else
                echo "✗ 'open' command not available"
            fi
            ;;
        4)
            cat "$OUTPUT_DIR/cleanup_report.md"
            ;;
        *)
            echo "Skipped"
            ;;
    esac
fi

echo ""
echo "Demo complete! Files remain in $OUTPUT_DIR for inspection."
