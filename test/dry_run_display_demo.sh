#!/usr/bin/env bash

# ===============================================
# Dry-Run Display Demo
# ===============================================
# Demonstrates the enhanced dry-run visualization
# ===============================================

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source libraries
source "$PROJECT_ROOT/lib/common.sh"
source "$PROJECT_ROOT/lib/dry_run_display.sh"

echo "═══════════════════════════════════════════════════════════"
echo "  Enhanced Dry-Run Display - Demonstration"
echo "═══════════════════════════════════════════════════════════"
echo ""

# Simulate collecting cleanup data
echo "Simulating cleanup scan..."
echo ""

# Browser Caches
add_category_item "Browser Caches" "Google Chrome" 4074848256 456
add_category_item "Browser Caches" "Firefox" 935718912 234
add_category_item "Browser Caches" "Safari" 536870912 78
add_category_item "Browser Caches" "Brave" 268435456 45

# Developer Tools
add_category_item "Developer Tools" "npm cache" 1288490189 234
add_category_item "Developer Tools" "pip cache" 897581056 89
add_category_item "Developer Tools" "Docker" 245366784 32

# App Caches
add_category_item "App Caches" "Slack" 594542592 123
add_category_item "App Caches" "Spotify" 676331520 111
add_category_item "App Caches" "VS Code" 428937216 67
add_category_item "App Caches" "Zoom" 321945600 45
add_category_item "App Caches" "Discord" 235929600 34
add_category_item "App Caches" "Notion" 198180864 28
add_category_item "App Caches" "Figma" 157286400 23
add_category_item "App Caches" "Postman" 134217728 19

# Logs
add_category_item "Logs" "Application Logs" 268435456 123
add_category_item "Logs" "System Logs" 134217728 67
add_category_item "Logs" "Install Logs" 89478485 45
add_category_item "Logs" "Crash Reports" 67108864 32
add_category_item "Logs" "Diagnostic Reports" 45875712 23

# Trash
add_category_item "Trash" "User Trash" 245366784 45

# System Caches
add_category_item "System Caches" "QuickLook Thumbnails" 134217728 67
add_category_item "System Caches" "Icon Services" 89478485 45
add_category_item "System Caches" "Launch Services" 67108864 34
add_category_item "System Caches" "CloudKit" 45875712 23

# Orphaned Data
add_category_item "Orphaned Data" "Old Xcode" 56623104 12
add_category_item "Orphaned Data" "Uninstalled Apps" 34603008 11

echo "✓ Data collection complete"
echo ""
sleep 1

# Demonstration 1: Default Enhanced Summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  DEMO 1: Enhanced Summary Table (Default)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

show_summary_table

echo "Press Enter to continue to Tree View..."
read -r

# Demonstration 2: Tree View
clear
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  DEMO 2: Tree View"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

show_tree_view

echo "Press Enter to continue to Detailed View..."
read -r

# Demonstration 3: Detailed View
clear
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  DEMO 3: Detailed View"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

show_detailed_view | head -50

echo ""
echo "... (more items below)"
echo ""
echo "Press Enter to continue to Compact Summary..."
read -r

# Demonstration 4: Compact Summary
clear
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  DEMO 4: Compact Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

show_compact_summary

# Summary
echo ""
echo "═══════════════════════════════════════════════════════════"
echo "  ✨ Enhanced Dry-Run Display Features"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "  ✅ Summary Table     - Category breakdown with totals"
echo "  ✅ Tree View         - Hierarchical visualization"
echo "  ✅ Detailed View     - In-depth item information"
echo "  ✅ Compact Summary   - Quick overview"
echo ""
echo "  Coming next:"
echo "  ⏳ Interactive Preview  - Select what to clean"
echo "  ⏳ JSON/CSV Export     - Data export capabilities"
echo ""
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "Demo complete!"
