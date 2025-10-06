#!/usr/bin/env bash

# ===============================================
# Mole Dry-Run Display Library
# ===============================================
# Enhanced visualization for dry-run output
# ===============================================

# Ensure this is only loaded once
if [[ -n "${MOLE_DRY_RUN_DISPLAY_LOADED:-}" ]]; then
    return 0
fi
readonly MOLE_DRY_RUN_DISPLAY_LOADED=1

# Data structures for dry-run collection
declare -A CATEGORY_DATA
declare -A CATEGORY_ITEMS
declare -a CATEGORY_ORDER

# ===============================================
# Data Collection Functions
# ===============================================

# Register a cleanup category
register_category() {
    local category="$1"
    
    if [[ ! " ${CATEGORY_ORDER[@]} " =~ " ${category} " ]]; then
        CATEGORY_ORDER+=("$category")
    fi
    
    # Initialize category stats if not exists
    if [[ -z "${CATEGORY_DATA[$category]:-}" ]]; then
        CATEGORY_DATA[$category]="0|0|0"  # size_bytes|files|items
    fi
}

# Add item to category
add_category_item() {
    local category="$1"
    local item_name="$2"
    local size_bytes="$3"
    local file_count="$4"
    
    register_category "$category"
    
    # Update category stats
    local current_stats="${CATEGORY_DATA[$category]}"
    local current_size=$(echo "$current_stats" | cut -d'|' -f1)
    local current_files=$(echo "$current_stats" | cut -d'|' -f2)
    local current_items=$(echo "$current_stats" | cut -d'|' -f3)
    
    local new_size=$((current_size + size_bytes))
    local new_files=$((current_files + file_count))
    local new_items=$((current_items + 1))
    
    CATEGORY_DATA[$category]="${new_size}|${new_files}|${new_items}"
    
    # Store item details
    local item_key="${category}_${new_items}"
    CATEGORY_ITEMS[$item_key]="${item_name}|${size_bytes}|${file_count}"
}

# ===============================================
# Summary Display Functions
# ===============================================

# Display enhanced summary table
show_summary_table() {
    echo ""
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║        DRY-RUN SUMMARY - No files deleted                ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo ""
    echo "📊 Category Breakdown:"
    
    # Table header
    printf "┌"
    printf "─%.0s" {1..26}
    printf "┬"
    printf "─%.0s" {1..10}
    printf "┬"
    printf "─%.0s" {1..8}
    printf "┬"
    printf "─%.0s" {1..10}
    printf "┐\n"
    
    printf "│ %-24s │ %-8s │ %-6s │ %-8s │\n" "Category" "Size" "Files" "Items"
    
    printf "├"
    printf "─%.0s" {1..26}
    printf "┼"
    printf "─%.0s" {1..10}
    printf "┼"
    printf "─%.0s" {1..8}
    printf "┼"
    printf "─%.0s" {1..10}
    printf "┤\n"
    
    # Category rows
    local total_size=0
    local total_files=0
    local total_items=0
    
    for category in "${CATEGORY_ORDER[@]}"; do
        local stats="${CATEGORY_DATA[$category]}"
        local size=$(echo "$stats" | cut -d'|' -f1)
        local files=$(echo "$stats" | cut -d'|' -f2)
        local items=$(echo "$stats" | cut -d'|' -f3)
        
        if [[ $size -gt 0 ]]; then
            local size_human=$(bytes_to_human "$size")
            local emoji=$(get_category_emoji "$category")
            local display_name="${emoji} ${category}"
            
            printf "│ %-24s │ %8s │ %6s │ %8s │\n" "$display_name" "$size_human" "$files" "$items"
            
            total_size=$((total_size + size))
            total_files=$((total_files + files))
            total_items=$((total_items + items))
        fi
    done
    
    # Total row
    printf "├"
    printf "─%.0s" {1..26}
    printf "┼"
    printf "─%.0s" {1..10}
    printf "┼"
    printf "─%.0s" {1..8}
    printf "┼"
    printf "─%.0s" {1..10}
    printf "┤\n"
    
    local total_size_human=$(bytes_to_human "$total_size")
    printf "│ ${GREEN}%-24s${NC} │ ${GREEN}%8s${NC} │ ${GREEN}%6s${NC} │ ${GREEN}%8s${NC} │\n" "TOTAL" "$total_size_human" "$total_files" "$total_items"
    
    printf "└"
    printf "─%.0s" {1..26}
    printf "┴"
    printf "─%.0s" {1..10}
    printf "┴"
    printf "─%.0s" {1..8}
    printf "┴"
    printf "─%.0s" {1..10}
    printf "┘\n"
    
    echo ""
    
    # Additional stats
    local current_free=$(get_free_space)
    local current_free_bytes=$(get_free_space_bytes)
    local estimated_free=$((current_free_bytes + total_size))
    local estimated_free_human=$(bytes_to_human "$estimated_free")
    
    local improvement=0
    if [[ $current_free_bytes -gt 0 ]]; then
        improvement=$(echo "scale=1; ($total_size * 100.0) / $current_free_bytes" | bc 2>/dev/null || echo "0")
    fi
    
    echo "💾 Estimated space to recover: ${GREEN}${total_size_human}${NC}"
    echo "📈 Current free space: ${current_free} → ${GREEN}${estimated_free_human}${NC}"
    echo "🎯 Improvement: ${GREEN}+${improvement}%${NC}"
    echo ""
    echo "⚙️  Options:"
    echo "  • Run cleanup:     ${BLUE}mo clean${NC}"
    echo "  • With backup:     ${BLUE}mo clean --backup${NC}"
    echo "  • Select items:    ${BLUE}mo clean --preview${NC}"
    echo ""
}

# Display compact summary (just totals)
show_compact_summary() {
    local total_size=0
    local total_files=0
    local total_items=0
    local category_count=0
    
    for category in "${CATEGORY_ORDER[@]}"; do
        local stats="${CATEGORY_DATA[$category]}"
        local size=$(echo "$stats" | cut -d'|' -f1)
        
        if [[ $size -gt 0 ]]; then
            local files=$(echo "$stats" | cut -d'|' -f2)
            local items=$(echo "$stats" | cut -d'|' -f3)
            
            total_size=$((total_size + size))
            total_files=$((total_files + files))
            total_items=$((total_items + items))
            category_count=$((category_count + 1))
        fi
    done
    
    echo ""
    echo "═══════════════════════════════════════════"
    echo "  📊 Dry-Run Summary"
    echo "═══════════════════════════════════════════"
    echo "  Total Size:     $(bytes_to_human $total_size)"
    echo "  Total Files:    $total_files"
    echo "  Categories:     $category_count"
    echo "  Items:          $total_items"
    echo "═══════════════════════════════════════════"
    echo ""
}

# ===============================================
# Tree View Functions
# ===============================================

# Display tree view of cleanup items
show_tree_view() {
    echo ""
    echo "🌳 ${BLUE}Cleanup Tree View:${NC}"
    echo ""
    
    for category in "${CATEGORY_ORDER[@]}"; do
        local stats="${CATEGORY_DATA[$category]}"
        local size=$(echo "$stats" | cut -d'|' -f1)
        
        if [[ $size -gt 0 ]]; then
            local files=$(echo "$stats" | cut -d'|' -f2)
            local items=$(echo "$stats" | cut -d'|' -f3)
            local size_human=$(bytes_to_human "$size")
            local emoji=$(get_category_emoji "$category")
            
            echo "📁 ${GREEN}${category}${NC} ${GRAY}(${size_human}, ${files} files)${NC}"
            
            # Show items in category
            for ((i=1; i<=items; i++)); do
                local item_key="${category}_${i}"
                local item_data="${CATEGORY_ITEMS[$item_key]}"
                
                if [[ -n "$item_data" ]]; then
                    local item_name=$(echo "$item_data" | cut -d'|' -f1)
                    local item_size=$(echo "$item_data" | cut -d'|' -f2)
                    local item_files=$(echo "$item_data" | cut -d'|' -f3)
                    local item_size_human=$(bytes_to_human "$item_size")
                    
                    if [[ $i -eq $items ]]; then
                        echo "└── ${emoji} ${item_name} ${GRAY}(${item_size_human}, ${item_files} files)${NC}"
                    else
                        echo "├── ${emoji} ${item_name} ${GRAY}(${item_size_human}, ${item_files} files)${NC}"
                    fi
                fi
            done
            echo ""
        fi
    done
}

# ===============================================
# Detailed View Functions
# ===============================================

# Display detailed information about cleanup items
show_detailed_view() {
    echo ""
    echo "📋 ${BLUE}Detailed Cleanup Report${NC}"
    echo ""
    
    for category in "${CATEGORY_ORDER[@]}"; do
        local stats="${CATEGORY_DATA[$category]}"
        local size=$(echo "$stats" | cut -d'|' -f1)
        
        if [[ $size -gt 0 ]]; then
            local items=$(echo "$stats" | cut -d'|' -f3)
            
            echo "Category: ${GREEN}${category}${NC}"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            
            # Show items in category
            for ((i=1; i<=items; i++)); do
                local item_key="${category}_${i}"
                local item_data="${CATEGORY_ITEMS[$item_key]}"
                
                if [[ -n "$item_data" ]]; then
                    local item_name=$(echo "$item_data" | cut -d'|' -f1)
                    local item_size=$(echo "$item_data" | cut -d'|' -f2)
                    local item_files=$(echo "$item_data" | cut -d'|' -f3)
                    local item_size_human=$(bytes_to_human "$item_size")
                    
                    echo "${i}. ${CYAN}${item_name}${NC}"
                    echo "   Size: ${item_size_human} (${item_size} bytes)"
                    echo "   Files: ${item_files} files"
                    echo "   Safety: ${GREEN}✅ Safe to delete${NC}"
                    echo ""
                fi
            done
        fi
    done
}

# ===============================================
# Helper Functions
# ===============================================

# Get emoji for category
get_category_emoji() {
    local category="$1"
    
    case "$category" in
        *"Browser"*|*"browser"*) echo "🌐" ;;
        *"Developer"*|*"developer"*) echo "💻" ;;
        *"App"*|*"app"*) echo "📦" ;;
        *"Log"*|*"log"*) echo "📝" ;;
        *"Trash"*|*"trash"*) echo "🗑️" ;;
        *"System"*|*"system"*) echo "💾" ;;
        *"Orphan"*|*"orphan"*) echo "🧹" ;;
        *"Cache"*|*"cache"*) echo "💿" ;;
        *) echo "📁" ;;
    esac
}

# Export functions
export -f register_category
export -f add_category_item
export -f show_summary_table
export -f show_compact_summary
export -f show_tree_view
export -f show_detailed_view
export -f get_category_emoji
