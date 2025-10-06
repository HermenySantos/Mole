#!/usr/bin/env bash

# ===============================================
# Interactive Preview Mode - Demonstration
# ===============================================

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source libraries
source "$PROJECT_ROOT/lib/common.sh"
source "$PROJECT_ROOT/lib/dry_run_display.sh"
source "$PROJECT_ROOT/lib/interactive_preview.sh"

echo "═══════════════════════════════════════════════════════════"
echo "  Interactive Preview Mode - Demonstration"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "Preparing sample cleanup data..."
echo ""

# Simulate collecting cleanup data (same as dry-run demo)
add_category_item "Browser Caches" "Google Chrome" 4074848256 456
add_category_item "Browser Caches" "Firefox" 935718912 234
add_category_item "Browser Caches" "Safari" 536870912 78

add_category_item "Developer Tools" "npm cache" 1288490189 234
add_category_item "Developer Tools" "pip cache" 897581056 89
add_category_item "Developer Tools" "Docker" 245366784 32

add_category_item "App Caches" "Slack" 594542592 123
add_category_item "App Caches" "Spotify" 676331520 111
add_category_item "App Caches" "VS Code" 428937216 67

add_category_item "Logs" "Application Logs" 268435456 123
add_category_item "Logs" "System Logs" 134217728 67

add_category_item "Trash" "User Trash" 245366784 45

echo "✓ Sample data loaded (6 categories, 11 items, ~9GB)"
echo ""
echo "Launching interactive preview..."
sleep 2

# Run interactive preview
if interactive_preview; then
    echo ""
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                  Selection Confirmed!                        ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
    echo "Selected categories for cleanup:"
    echo ""
    
    # Show selected categories
    local -a selected_cats
    mapfile -t selected_cats < <(get_selected_categories)
    
    if [[ ${#selected_cats[@]} -eq 0 ]]; then
        echo "  ${YELLOW}⚠️  No categories selected${NC}"
        echo "  ${GRAY}Cleanup cancelled${NC}"
    else
        local total_size=0
        local total_files=0
        
        for category in "${selected_cats[@]}"; do
            local stats="${CATEGORY_DATA[$category]}"
            local size=$(echo "$stats" | cut -d'|' -f1)
            local files=$(echo "$stats" | cut -d'|' -f2)
            local size_human=$(bytes_to_human "$size")
            local emoji=$(get_category_emoji "$category")
            
            echo "  ${GREEN}✓${NC} ${emoji} ${category} ${GRAY}(${size_human}, ${files} files)${NC}"
            
            total_size=$((total_size + size))
            total_files=$((total_files + files))
        done
        
        echo ""
        echo "Total to clean: ${GREEN}$(bytes_to_human $total_size)${NC} (${total_files} files)"
        echo ""
        echo "Next steps:"
        echo "  • Review selection above"
        echo "  • Run: ${BLUE}mo clean${NC} to execute cleanup"
        echo "  • Or:  ${BLUE}mo clean --backup${NC} for safe cleanup with backup"
    fi
else
    echo ""
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                  Selection Cancelled                         ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
    echo "No changes made. You can:"
    echo "  • Run ${BLUE}mo clean --preview${NC} again to select items"
    echo "  • Run ${BLUE}mo clean --dry-run${NC} to see what would be cleaned"
    echo "  • Run ${BLUE}mo clean${NC} to clean everything"
fi

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "  Demo Complete!"
echo "═══════════════════════════════════════════════════════════"
