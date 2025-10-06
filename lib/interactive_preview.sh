#!/usr/bin/env bash

# ===============================================
# Mole Interactive Preview Mode
# ===============================================
# Interactive selection of cleanup items
# ===============================================

# Ensure this is only loaded once
if [[ -n "${MOLE_INTERACTIVE_PREVIEW_LOADED:-}" ]]; then
    return 0
fi
readonly MOLE_INTERACTIVE_PREVIEW_LOADED=1

# Source dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh" 2>/dev/null || true

# Selection state
declare -A ITEM_SELECTED
declare -a DISPLAY_ITEMS
declare -a ITEM_KEYS

# ===============================================
# Terminal Control Functions
# ===============================================

enter_alt_screen() { tput smcup 2>/dev/null || true; }
leave_alt_screen() { tput rmcup 2>/dev/null || true; }
hide_cursor() { printf '\033[?25l'; }
show_cursor() { printf '\033[?25h'; }
clear_screen() { printf '\033[H\033[J'; }
move_cursor() { printf '\033[%d;%dH' "$1" "$2"; }

# ===============================================
# Data Preparation Functions
# ===============================================

# Build display list from category data
build_display_list() {
    DISPLAY_ITEMS=()
    ITEM_KEYS=()
    
    local idx=0
    for category in "${CATEGORY_ORDER[@]}"; do
        local stats="${CATEGORY_DATA[$category]}"
        local size=$(echo "$stats" | cut -d'|' -f1)
        
        if [[ $size -gt 0 ]]; then
            local files=$(echo "$stats" | cut -d'|' -f2)
            local items=$(echo "$stats" | cut -d'|' -f3)
            local size_human=$(bytes_to_human "$size")
            local emoji=$(get_category_emoji "$category")
            
            # Add category as selectable item
            DISPLAY_ITEMS+=("${emoji} ${category}|${size_human}|${files} files|category")
            ITEM_KEYS+=("cat_${category}")
            ITEM_SELECTED["cat_${category}"]=true
            ((idx++))
            
            # Add individual items under category
            for ((i=1; i<=items; i++)); do
                local item_key="${category}_${i}"
                local item_data="${CATEGORY_ITEMS[$item_key]}"
                
                if [[ -n "$item_data" ]]; then
                    local item_name=$(echo "$item_data" | cut -d'|' -f1)
                    local item_size=$(echo "$item_data" | cut -d'|' -f2)
                    local item_files=$(echo "$item_data" | cut -d'|' -f3)
                    local item_size_human=$(bytes_to_human "$item_size")
                    
                    DISPLAY_ITEMS+=("  └─ ${item_name}|${item_size_human}|${item_files} files|item")
                    ITEM_KEYS+=("item_${category}_${i}")
                    ITEM_SELECTED["item_${category}_${i}"]=true
                    ((idx++))
                fi
            done
        fi
    done
}

# Calculate selected totals
calculate_selected_totals() {
    local total_size=0
    local total_files=0
    local category_count=0
    local item_count=0
    
    for key in "${ITEM_KEYS[@]}"; do
        if [[ "${ITEM_SELECTED[$key]}" == "true" ]]; then
            if [[ "$key" == cat_* ]]; then
                # Category selected
                local category="${key#cat_}"
                local stats="${CATEGORY_DATA[$category]}"
                local size=$(echo "$stats" | cut -d'|' -f1)
                local files=$(echo "$stats" | cut -d'|' -f2)
                
                total_size=$((total_size + size))
                total_files=$((total_files + files))
                ((category_count++))
            fi
        fi
    done
    
    echo "${total_size}|${total_files}|${category_count}"
}

# ===============================================
# Display Functions
# ===============================================

# Draw header
draw_header() {
    local totals=$(calculate_selected_totals)
    local sel_size=$(echo "$totals" | cut -d'|' -f1)
    local sel_files=$(echo "$totals" | cut -d'|' -f2)
    local sel_categories=$(echo "$totals" | cut -d'|' -f3)
    
    local sel_size_human=$(bytes_to_human "$sel_size")
    
    echo ""
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║          🔍 Interactive Cleanup Preview                      ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
    echo "Select items to clean (↑↓ navigate, SPACE toggle, ENTER confirm):"
    echo ""
    echo "┌────────────────────────────────────────────────────────────────┐"
}

# Draw footer
draw_footer() {
    local line_num="$1"
    local totals=$(calculate_selected_totals)
    local sel_size=$(echo "$totals" | cut -d'|' -f1)
    local sel_files=$(echo "$totals" | cut -d'|' -f2)
    local sel_categories=$(echo "$totals" | cut -d'|' -f3)
    
    local sel_size_human=$(bytes_to_human "$sel_size")
    
    move_cursor "$line_num" 1
    echo "└────────────────────────────────────────────────────────────────┘"
    echo ""
    echo "Selected: ${GREEN}${sel_categories} categories${NC} │ ${GREEN}${sel_size_human}${NC} │ ${GREEN}${sel_files} files${NC}"
    echo ""
    echo "Controls:"
    echo "  ${BLUE}↑↓${NC}  Navigate    ${BLUE}SPACE${NC}  Toggle    ${BLUE}A${NC}  Select All    ${BLUE}N${NC}  Deselect All"
    echo "  ${BLUE}ENTER${NC}  Continue    ${BLUE}Q${NC}  Cancel    ${BLUE}?${NC}  Help"
}

# Draw single item
draw_item() {
    local idx="$1"
    local is_current="$2"
    
    local item_info="${DISPLAY_ITEMS[$idx]}"
    local item_key="${ITEM_KEYS[$idx]}"
    
    local display_text=$(echo "$item_info" | cut -d'|' -f1)
    local size=$(echo "$item_info" | cut -d'|' -f2)
    local files=$(echo "$item_info" | cut -d'|' -f3)
    local item_type=$(echo "$item_info" | cut -d'|' -f4)
    
    local checkbox="☐"
    [[ "${ITEM_SELECTED[$item_key]}" == "true" ]] && checkbox="☑"
    
    # Format the line
    local line
    if [[ "$item_type" == "category" ]]; then
        line=$(printf "│ %s %-42s %8s %12s │" "$checkbox" "$display_text" "$size" "$files")
    else
        line=$(printf "│ %s %-42s %8s %12s │" "$checkbox" "$display_text" "$size" "$files")
    fi
    
    if [[ "$is_current" == "true" ]]; then
        echo -e "${CYAN}${line}${NC}"
    else
        echo "$line"
    fi
}

# Draw the complete menu
draw_menu() {
    local cursor_pos="$1"
    local scroll_offset="$2"
    
    clear_screen
    draw_header
    
    local items_per_page=12
    local start_idx=$scroll_offset
    local end_idx=$((start_idx + items_per_page))
    [[ $end_idx -gt ${#DISPLAY_ITEMS[@]} ]] && end_idx=${#DISPLAY_ITEMS[@]}
    
    for ((i=start_idx; i<end_idx; i++)); do
        local is_current=false
        [[ $i -eq $cursor_pos ]] && is_current=true
        draw_item "$i" "$is_current"
    done
    
    # Fill remaining lines if needed
    local lines_drawn=$((end_idx - start_idx))
    for ((i=lines_drawn; i<items_per_page; i++)); do
        echo "│                                                                │"
    done
    
    draw_footer $((9 + items_per_page))
}

# ===============================================
# Input Handling Functions
# ===============================================

# Read a single key
read_key() {
    local key
    IFS= read -rsn1 key 2>/dev/null
    
    # Handle escape sequences
    if [[ $key == $'\x1b' ]]; then
        read -rsn2 -t 0.001 key 2>/dev/null
        case "$key" in
            '[A') echo "UP" ;;
            '[B') echo "DOWN" ;;
            *) echo "ESC" ;;
        esac
    else
        case "$key" in
            ' ') echo "SPACE" ;;
            '') echo "ENTER" ;;
            'q'|'Q') echo "QUIT" ;;
            'a'|'A') echo "SELECT_ALL" ;;
            'n'|'N') echo "DESELECT_ALL" ;;
            '?') echo "HELP" ;;
            *) echo "OTHER" ;;
        esac
    fi
}

# Toggle item selection
toggle_item() {
    local idx="$1"
    local item_key="${ITEM_KEYS[$idx]}"
    
    if [[ "${ITEM_SELECTED[$item_key]}" == "true" ]]; then
        ITEM_SELECTED[$item_key]=false
        
        # If it's a category, deselect all items under it
        if [[ "$item_key" == cat_* ]]; then
            local category="${item_key#cat_}"
            for key in "${ITEM_KEYS[@]}"; do
                if [[ "$key" == item_${category}_* ]]; then
                    ITEM_SELECTED[$key]=false
                fi
            done
        fi
    else
        ITEM_SELECTED[$item_key]=true
        
        # If it's a category, select all items under it
        if [[ "$item_key" == cat_* ]]; then
            local category="${item_key#cat_}"
            for key in "${ITEM_KEYS[@]}"; do
                if [[ "$key" == item_${category}_* ]]; then
                    ITEM_SELECTED[$key]=true
                fi
            done
        fi
    fi
}

# Select all items
select_all() {
    for key in "${ITEM_KEYS[@]}"; do
        ITEM_SELECTED[$key]=true
    done
}

# Deselect all items
deselect_all() {
    for key in "${ITEM_KEYS[@]}"; do
        ITEM_SELECTED[$key]=false
    done
}

# Show help screen
show_help() {
    clear_screen
    echo ""
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                    Interactive Preview Help                  ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
    echo "Navigation:"
    echo "  ↑ / ↓         - Move cursor up/down"
    echo "  SPACE         - Toggle item selection"
    echo "  ENTER         - Confirm selection and continue"
    echo "  Q / ESC       - Cancel and exit"
    echo ""
    echo "Bulk Actions:"
    echo "  A             - Select all items"
    echo "  N             - Deselect all items"
    echo ""
    echo "Display:"
    echo "  Categories are shown in bold with folder icons"
    echo "  Items under categories are indented with └─"
    echo "  ☑ indicates selected, ☐ indicates not selected"
    echo ""
    echo "Selection Behavior:"
    echo "  - Selecting a category selects all items under it"
    echo "  - Deselecting a category deselects all items under it"
    echo "  - Individual items can be toggled independently"
    echo ""
    echo "Safety:"
    echo "  - Only selected items will be cleaned"
    echo "  - You can review the selection summary before confirming"
    echo "  - No files are deleted until you confirm"
    echo ""
    echo "Press any key to return to selection..."
    read -rsn1
}

# ===============================================
# Main Interactive Function
# ===============================================

# Run interactive preview mode
interactive_preview() {
    # Build display list from category data
    build_display_list
    
    if [[ ${#DISPLAY_ITEMS[@]} -eq 0 ]]; then
        echo "No items to display"
        return 1
    fi
    
    # Setup terminal
    local cleanup_done=false
    cleanup() {
        if [[ "$cleanup_done" == "false" ]]; then
            cleanup_done=true
            show_cursor
            stty echo icanon 2>/dev/null || true
            leave_alt_screen
        fi
    }
    
    handle_interrupt() {
        cleanup
        exit 130
    }
    
    trap cleanup EXIT
    trap handle_interrupt INT TERM
    
    stty -echo -icanon intr ^C 2>/dev/null || true
    enter_alt_screen
    hide_cursor
    
    # Main loop
    local cursor_pos=0
    local scroll_offset=0
    local items_per_page=12
    local total_items=${#DISPLAY_ITEMS[@]}
    
    while true; do
        # Adjust scroll if needed
        if [[ $cursor_pos -lt $scroll_offset ]]; then
            scroll_offset=$cursor_pos
        elif [[ $cursor_pos -ge $((scroll_offset + items_per_page)) ]]; then
            scroll_offset=$((cursor_pos - items_per_page + 1))
        fi
        
        draw_menu "$cursor_pos" "$scroll_offset"
        
        local key=$(read_key)
        
        case "$key" in
            UP)
                ((cursor_pos > 0)) && ((cursor_pos--))
                ;;
            DOWN)
                ((cursor_pos < total_items - 1)) && ((cursor_pos++))
                ;;
            SPACE)
                toggle_item "$cursor_pos"
                ;;
            SELECT_ALL)
                select_all
                ;;
            DESELECT_ALL)
                deselect_all
                ;;
            HELP)
                show_help
                ;;
            ENTER)
                # Confirm and exit
                cleanup
                return 0
                ;;
            QUIT|ESC)
                # Cancel
                cleanup
                return 1
                ;;
        esac
    done
}

# Get list of selected category names (for cleanup execution)
get_selected_categories() {
    local -a selected_cats=()
    
    for key in "${ITEM_KEYS[@]}"; do
        if [[ "$key" == cat_* && "${ITEM_SELECTED[$key]}" == "true" ]]; then
            local category="${key#cat_}"
            selected_cats+=("$category")
        fi
    done
    
    printf "%s\n" "${selected_cats[@]}"
}

# Export functions
export -f interactive_preview
export -f build_display_list
export -f get_selected_categories
