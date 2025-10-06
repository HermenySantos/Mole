#!/usr/bin/env bash

# ===============================================
# Mole Export Library
# ===============================================
# Export cleanup data to various formats
# ===============================================

# Ensure this is only loaded once
if [[ -n "${MOLE_EXPORT_LOADED:-}" ]]; then
    return 0
fi
readonly MOLE_EXPORT_LOADED=1

# ===============================================
# JSON Export Functions
# ===============================================

# Export cleanup data to JSON format
export_to_json() {
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local hostname=$(hostname)
    local os_version="$(sw_vers -productName) $(sw_vers -productVersion)"
    local arch=$(uname -m)
    local free_space=$(get_free_space)
    local free_space_bytes=$(get_free_space_bytes)
    
    # Calculate totals
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
    
    local total_size_human=$(bytes_to_human "$total_size")
    local estimated_free=$((free_space_bytes + total_size))
    local estimated_free_human=$(bytes_to_human "$estimated_free")
    
    # Start JSON output
    cat << EOF
{
  "metadata": {
    "timestamp": "$timestamp",
    "hostname": "$hostname",
    "user": "$USER",
    "generator": "Mole v1.6.3",
    "export_format": "json",
    "export_version": "1.0"
  },
  "system": {
    "os": "$os_version",
    "architecture": "$arch",
    "free_space_before": "$free_space",
    "free_space_before_bytes": $free_space_bytes,
    "free_space_after_estimate": "$estimated_free_human",
    "free_space_after_bytes": $estimated_free
  },
  "summary": {
    "total_size": $total_size,
    "total_size_human": "$total_size_human",
    "total_files": $total_files,
    "total_items": $total_items,
    "category_count": $category_count
  },
  "categories": [
EOF

    # Export categories
    local first_cat=true
    for category in "${CATEGORY_ORDER[@]}"; do
        local stats="${CATEGORY_DATA[$category]}"
        local size=$(echo "$stats" | cut -d'|' -f1)
        
        if [[ $size -gt 0 ]]; then
            local files=$(echo "$stats" | cut -d'|' -f2)
            local items=$(echo "$stats" | cut -d'|' -f3)
            local size_human=$(bytes_to_human "$size")
            local emoji=$(get_category_emoji "$category")
            
            # Add comma if not first category
            [[ "$first_cat" == "false" ]] && echo ","
            first_cat=false
            
            cat << EOF
    {
      "name": "$category",
      "emoji": "$emoji",
      "size_bytes": $size,
      "size_human": "$size_human",
      "file_count": $files,
      "item_count": $items,
      "items": [
EOF
            
            # Export items in category
            local first_item=true
            for ((i=1; i<=items; i++)); do
                local item_key="${category}_${i}"
                local item_data="${CATEGORY_ITEMS[$item_key]}"
                
                if [[ -n "$item_data" ]]; then
                    local item_name=$(echo "$item_data" | cut -d'|' -f1)
                    local item_size=$(echo "$item_data" | cut -d'|' -f2)
                    local item_files=$(echo "$item_data" | cut -d'|' -f3)
                    local item_size_human=$(bytes_to_human "$item_size")
                    
                    # Escape JSON special characters in item name
                    item_name=$(echo "$item_name" | sed 's/\\/\\\\/g; s/"/\\"/g')
                    
                    [[ "$first_item" == "false" ]] && echo ","
                    first_item=false
                    
                    cat << EOF
        {
          "name": "$item_name",
          "size_bytes": $item_size,
          "size_human": "$item_size_human",
          "file_count": $item_files,
          "safety_level": "safe"
        }
EOF
                fi
            done
            
            echo "      ]"
            echo -n "    }"
        fi
    done
    
    # Close JSON
    cat << EOF

  ],
  "recommendations": [
    "Consider running with --backup for safety",
    "Browser caches will be automatically rebuilt",
    "Developer tool caches can be cleared safely"
  ]
}
EOF
}

# ===============================================
# CSV Export Functions
# ===============================================

# Export cleanup data to CSV format
export_to_csv() {
    # CSV Header
    echo "Category,Item,Size (Bytes),Size (Human),Files,Safety"
    
    # Export each category and its items
    for category in "${CATEGORY_ORDER[@]}"; do
        local stats="${CATEGORY_DATA[$category]}"
        local size=$(echo "$stats" | cut -d'|' -f1)
        
        if [[ $size -gt 0 ]]; then
            local files=$(echo "$stats" | cut -d'|' -f2)
            local items=$(echo "$stats" | cut -d'|' -f3)
            
            # Export items
            for ((i=1; i<=items; i++)); do
                local item_key="${category}_${i}"
                local item_data="${CATEGORY_ITEMS[$item_key]}"
                
                if [[ -n "$item_data" ]]; then
                    local item_name=$(echo "$item_data" | cut -d'|' -f1)
                    local item_size=$(echo "$item_data" | cut -d'|' -f2)
                    local item_files=$(echo "$item_data" | cut -d'|' -f3)
                    local item_size_human=$(bytes_to_human "$item_size")
                    
                    # Escape CSV special characters
                    item_name=$(echo "$item_name" | sed 's/"/""/g')
                    category_escaped=$(echo "$category" | sed 's/"/""/g')
                    
                    # Check if fields need quoting
                    if [[ "$item_name" == *,* ]] || [[ "$item_name" == *\"* ]]; then
                        item_name="\"$item_name\""
                    fi
                    if [[ "$category_escaped" == *,* ]] || [[ "$category_escaped" == *\"* ]]; then
                        category_escaped="\"$category_escaped\""
                    fi
                    
                    echo "$category_escaped,$item_name,$item_size,$item_size_human,$item_files,safe"
                fi
            done
        fi
    done
}

# ===============================================
# Markdown Export Functions
# ===============================================

# Export cleanup data to Markdown format
export_to_markdown() {
    local timestamp=$(date "+%B %d, %Y %H:%M:%S")
    local hostname=$(hostname)
    local os_version="$(sw_vers -productName) $(sw_vers -productVersion)"
    local arch=$(uname -m)
    local free_space=$(get_free_space)
    
    # Calculate totals
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
    
    local total_size_human=$(bytes_to_human "$total_size")
    
    # Markdown header
    cat << EOF
# Mole Cleanup Report

**Generated:** $timestamp  
**System:** $hostname ($os_version, $arch)  
**User:** $USER

---

## Summary

- **Total Size:** $total_size_human ($total_size bytes)
- **Total Files:** $total_files files
- **Total Items:** $total_items items
- **Categories:** $category_count categories
- **Free Space:** $free_space
- **Estimated Recovery:** $total_size_human

---

## Category Breakdown

EOF

    # Export each category
    for category in "${CATEGORY_ORDER[@]}"; do
        local stats="${CATEGORY_DATA[$category]}"
        local size=$(echo "$stats" | cut -d'|' -f1)
        
        if [[ $size -gt 0 ]]; then
            local files=$(echo "$stats" | cut -d'|' -f2)
            local items=$(echo "$stats" | cut -d'|' -f3)
            local size_human=$(bytes_to_human "$size")
            local emoji=$(get_category_emoji "$category")
            
            echo "### $emoji $category ($size_human, $files files)"
            echo ""
            
            # List items
            for ((i=1; i<=items; i++)); do
                local item_key="${category}_${i}"
                local item_data="${CATEGORY_ITEMS[$item_key]}"
                
                if [[ -n "$item_data" ]]; then
                    local item_name=$(echo "$item_data" | cut -d'|' -f1)
                    local item_size=$(echo "$item_data" | cut -d'|' -f2)
                    local item_files=$(echo "$item_data" | cut -d'|' -f3)
                    local item_size_human=$(bytes_to_human "$item_size")
                    
                    echo "$i. **$item_name** - $item_size_human ($item_files files)"
                    echo "   - ✅ Safe to delete"
                fi
            done
            
            echo ""
        fi
    done
    
    # Footer
    cat << EOF
---

## Recommendations

- Consider running with \`--backup\` for safety
- Browser caches will be automatically rebuilt
- Developer tool caches can be cleared safely
- System will automatically recreate necessary files

---

*Generated by Mole v1.6.3*
EOF
}

# ===============================================
# HTML Export Functions (Bonus)
# ===============================================

# Export cleanup data to HTML format
export_to_html() {
    local timestamp=$(date "+%B %d, %Y %H:%M:%S")
    local hostname=$(hostname)
    local os_version="$(sw_vers -productName) $(sw_vers -productVersion)"
    
    # Calculate totals
    local total_size=0
    local total_files=0
    local category_count=0
    
    for category in "${CATEGORY_ORDER[@]}"; do
        local stats="${CATEGORY_DATA[$category]}"
        local size=$(echo "$stats" | cut -d'|' -f1)
        
        if [[ $size -gt 0 ]]; then
            local files=$(echo "$stats" | cut -d'|' -f2)
            total_size=$((total_size + size))
            total_files=$((total_files + files))
            category_count=$((category_count + 1))
        fi
    done
    
    local total_size_human=$(bytes_to_human "$total_size")
    
    # HTML output
    cat << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Mole Cleanup Report</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
            line-height: 1.6;
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
            background: #f5f5f5;
        }
        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 30px;
            border-radius: 10px;
            margin-bottom: 30px;
        }
        .summary {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }
        .summary-card {
            background: white;
            padding: 20px;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        .summary-card h3 {
            margin: 0 0 10px 0;
            color: #666;
            font-size: 14px;
        }
        .summary-card .value {
            font-size: 28px;
            font-weight: bold;
            color: #667eea;
        }
        .category {
            background: white;
            padding: 20px;
            border-radius: 8px;
            margin-bottom: 20px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        .category h2 {
            margin: 0 0 15px 0;
            color: #333;
        }
        .item {
            padding: 10px;
            border-left: 3px solid #667eea;
            margin: 10px 0;
            background: #f9f9f9;
        }
        .item-name {
            font-weight: bold;
            color: #333;
        }
        .item-details {
            color: #666;
            font-size: 14px;
        }
        .safe-badge {
            display: inline-block;
            background: #10b981;
            color: white;
            padding: 2px 8px;
            border-radius: 4px;
            font-size: 12px;
            margin-left: 10px;
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>🧹 Mole Cleanup Report</h1>
EOF

    echo "        <p><strong>Generated:</strong> $timestamp</p>"
    echo "        <p><strong>System:</strong> $hostname ($os_version)</p>"
    echo "    </div>"
    
    echo "    <div class=\"summary\">"
    echo "        <div class=\"summary-card\">"
    echo "            <h3>Total Size</h3>"
    echo "            <div class=\"value\">$total_size_human</div>"
    echo "        </div>"
    echo "        <div class=\"summary-card\">"
    echo "            <h3>Total Files</h3>"
    echo "            <div class=\"value\">$total_files</div>"
    echo "        </div>"
    echo "        <div class=\"summary-card\">"
    echo "            <h3>Categories</h3>"
    echo "            <div class=\"value\">$category_count</div>"
    echo "        </div>"
    echo "    </div>"
    
    # Categories
    for category in "${CATEGORY_ORDER[@]}"; do
        local stats="${CATEGORY_DATA[$category]}"
        local size=$(echo "$stats" | cut -d'|' -f1)
        
        if [[ $size -gt 0 ]]; then
            local files=$(echo "$stats" | cut -d'|' -f2)
            local items=$(echo "$stats" | cut -d'|' -f3)
            local size_human=$(bytes_to_human "$size")
            local emoji=$(get_category_emoji "$category")
            
            echo "    <div class=\"category\">"
            echo "        <h2>$emoji $category</h2>"
            echo "        <p><strong>$size_human</strong> ($files files)</p>"
            
            # Items
            for ((i=1; i<=items; i++)); do
                local item_key="${category}_${i}"
                local item_data="${CATEGORY_ITEMS[$item_key]}"
                
                if [[ -n "$item_data" ]]; then
                    local item_name=$(echo "$item_data" | cut -d'|' -f1)
                    local item_size=$(echo "$item_data" | cut -d'|' -f2)
                    local item_files=$(echo "$item_data" | cut -d'|' -f3)
                    local item_size_human=$(bytes_to_human "$item_size")
                    
                    # HTML escape
                    item_name=$(echo "$item_name" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g')
                    
                    echo "        <div class=\"item\">"
                    echo "            <div class=\"item-name\">$item_name <span class=\"safe-badge\">✓ Safe</span></div>"
                    echo "            <div class=\"item-details\">$item_size_human ($item_files files)</div>"
                    echo "        </div>"
                fi
            done
            
            echo "    </div>"
        fi
    done
    
    cat << 'EOF'
</body>
</html>
EOF
}

# ===============================================
# Main Export Function
# ===============================================

# Export to specified format
export_cleanup_data() {
    local format="${1:-json}"
    
    case "$format" in
        json)
            export_to_json
            ;;
        csv)
            export_to_csv
            ;;
        md|markdown)
            export_to_markdown
            ;;
        html)
            export_to_html
            ;;
        *)
            echo "Error: Unknown export format '$format'" >&2
            echo "Supported formats: json, csv, md, html" >&2
            return 1
            ;;
    esac
}

# Export functions
export -f export_to_json
export -f export_to_csv
export -f export_to_markdown
export -f export_to_html
export -f export_cleanup_data
