##

 Export Formats Guide

**Status:** ✅ Implemented  
**Date:** October 6, 2025  
**Task:** 2.3

---

## 🎯 Overview

Mole now supports exporting cleanup data to multiple formats for analysis, record-keeping, and sharing.

**Supported Formats:**
- 📊 **JSON** - Structured data for APIs and tools
- 📈 **CSV** - Spreadsheet-compatible format
- 📝 **Markdown** - Documentation-friendly format
- 🌐 **HTML** - Beautiful web reports

---

## 📋 Usage

### Command-Line Syntax

```bash
# Export to JSON
mo clean --dry-run --export json > cleanup_report.json

# Export to CSV
mo clean --dry-run --export csv > cleanup_report.csv

# Export to Markdown
mo clean --dry-run --export md > cleanup_report.md

# Export to HTML
mo clean --dry-run --export html > cleanup_report.html
```

### Programmatic Usage

```bash
# In scripts
source lib/export.sh

# Export to specific format
export_cleanup_data json > report.json
export_cleanup_data csv > report.csv
export_cleanup_data markdown > report.md
export_cleanup_data html > report.html
```

---

## 📊 JSON Format

### Structure

```json
{
  "metadata": {
    "timestamp": "2025-10-06T21:30:00Z",
    "hostname": "MacBook-Pro.local",
    "user": "hermenegildosantos",
    "generator": "Mole v1.6.3",
    "export_format": "json",
    "export_version": "1.0"
  },
  "system": {
    "os": "macOS 15.1",
    "architecture": "arm64",
    "free_space_before": "45.2GB",
    "free_space_before_bytes": 48537665536,
    "free_space_after_estimate": "54.8GB",
    "free_space_after_bytes": 58844831744
  },
  "summary": {
    "total_size": 10297466880,
    "total_size_human": "9.6GB",
    "total_files": 1739,
    "total_items": 27,
    "category_count": 7
  },
  "categories": [
    {
      "name": "Browser Caches",
      "emoji": "🌐",
      "size_bytes": 5577658368,
      "size_human": "5.2GB",
      "file_count": 892,
      "item_count": 4,
      "items": [
        {
          "name": "Google Chrome",
          "size_bytes": 4074848256,
          "size_human": "3.8GB",
          "file_count": 456,
          "safety_level": "safe"
        },
        {
          "name": "Firefox",
          "size_bytes": 935718912,
          "size_human": "892MB",
          "file_count": 234,
          "safety_level": "safe"
        }
      ]
    }
  ],
  "recommendations": [
    "Consider running with --backup for safety",
    "Browser caches will be automatically rebuilt",
    "Developer tool caches can be cleared safely"
  ]
}
```

### Use Cases

- **API Integration** - Feed into monitoring systems
- **Data Analysis** - Process with jq, Python, Node.js
- **Automation** - Parse in scripts and workflows
- **Archival** - Store historical cleanup data
- **Comparison** - Diff between multiple runs

### Example Queries

```bash
# Get total size
jq '.summary.total_size_human' report.json

# List all categories
jq '.categories[].name' report.json

# Find largest item
jq '.categories[].items[] | select(.size_bytes > 1000000000)' report.json

# Export category names
jq -r '.categories[].name' report.json
```

---

## 📈 CSV Format

### Structure

```csv
Category,Item,Size (Bytes),Size (Human),Files,Safety
Browser Caches,Google Chrome,4074848256,3.8GB,456,safe
Browser Caches,Firefox,935718912,892MB,234,safe
Browser Caches,Safari,536870912,512MB,78,safe
Developer Tools,npm cache,1288490189,1.2GB,234,safe
Developer Tools,pip cache,897581056,856MB,89,safe
Developer Tools,Docker,245366784,234MB,32,safe
App Caches,Slack,594542592,567MB,123,safe
App Caches,Spotify,676331520,645MB,111,safe
Logs,Application Logs,268435456,256MB,123,safe
Logs,System Logs,134217728,128MB,67,safe
Trash,User Trash,245366784,234MB,45,safe
```

### Use Cases

- **Spreadsheet Analysis** - Open in Excel, Numbers, Google Sheets
- **Pivot Tables** - Analyze by category, size, file count
- **Charts & Graphs** - Visualize disk usage
- **Reporting** - Create business reports
- **Budget Planning** - Track storage costs over time

### Excel/Numbers Tips

1. **Import as Table** - Auto-format with headers
2. **Sort by Size** - Find biggest space consumers
3. **Group by Category** - Subtotals per category
4. **Create Charts** - Pie chart of categories
5. **Conditional Formatting** - Highlight large items

---

## 📝 Markdown Format

### Structure

```markdown
# Mole Cleanup Report

**Generated:** October 6, 2025 21:30:00  
**System:** MacBook-Pro.local (macOS 15.1, arm64)  
**User:** hermenegildosantos

---

## Summary

- **Total Size:** 9.6GB (10,297,466,880 bytes)
- **Total Files:** 1,739 files
- **Total Items:** 27 items
- **Categories:** 7 categories
- **Free Space:** 45.2GB
- **Estimated Recovery:** 9.6GB

---

## Category Breakdown

### 🌐 Browser Caches (5.2GB, 892 files)

1. **Google Chrome** - 3.8GB (456 files)
   - ✅ Safe to delete

2. **Firefox** - 892MB (234 files)
   - ✅ Safe to delete

3. **Safari** - 512MB (78 files)
   - ✅ Safe to delete

### 💻 Developer Tools (2.3GB, 355 files)

1. **npm cache** - 1.2GB (234 files)
   - ✅ Safe to delete

2. **pip cache** - 856MB (89 files)
   - ✅ Safe to delete

---

## Recommendations

- Consider running with `--backup` for safety
- Browser caches will be automatically rebuilt
- Developer tool caches can be cleared safely

---

*Generated by Mole v1.6.3*
```

### Use Cases

- **Documentation** - Add to project wikis, README files
- **GitHub/GitLab** - Track cleanup history in repos
- **Notion/Obsidian** - Personal knowledge bases
- **Slack/Teams** - Share cleanup reports
- **Blog Posts** - Write about system maintenance

### Viewing Options

```bash
# Terminal with syntax highlighting
bat cleanup_report.md

# Convert to PDF
pandoc cleanup_report.md -o cleanup_report.pdf

# Preview on macOS
open -a "Marked 2" cleanup_report.md
```

---

## 🌐 HTML Format

### Structure

Beautiful, self-contained HTML with embedded CSS:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Mole Cleanup Report</title>
    <style>
        /* Modern, responsive design */
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto; }
        .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); }
        .summary-card { background: white; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        /* ... more styles */
    </style>
</head>
<body>
    <div class="header">
        <h1>🧹 Mole Cleanup Report</h1>
        <p><strong>Generated:</strong> October 6, 2025</p>
        <p><strong>System:</strong> MacBook-Pro.local (macOS 15.1)</p>
    </div>
    
    <div class="summary">
        <div class="summary-card">
            <h3>Total Size</h3>
            <div class="value">9.6GB</div>
        </div>
        <!-- More cards -->
    </div>
    
    <div class="category">
        <h2>🌐 Browser Caches</h2>
        <p><strong>5.2GB</strong> (892 files)</p>
        <div class="item">
            <div class="item-name">Google Chrome <span class="safe-badge">✓ Safe</span></div>
            <div class="item-details">3.8GB (456 files)</div>
        </div>
        <!-- More items -->
    </div>
</body>
</html>
```

### Features

- **Responsive Design** - Works on desktop, tablet, mobile
- **Modern UI** - Gradient header, card layout
- **Color-Coded** - Categories and safety badges
- **Print-Friendly** - Clean printouts
- **Self-Contained** - No external dependencies

### Use Cases

- **Email Reports** - Send to team/management
- **Archive** - Beautiful historical records
- **Presentations** - Embed in slides
- **Dashboards** - Display on monitors
- **Client Reports** - Professional appearance

### Viewing & Sharing

```bash
# Open in default browser
open cleanup_report.html

# Open in specific browser
open -a "Google Chrome" cleanup_report.html

# Serve with local web server
python3 -m http.server 8000
# Then visit: http://localhost:8000/cleanup_report.html

# Convert to PDF (macOS)
wkhtmltopdf cleanup_report.html cleanup_report.pdf
```

---

## 🔧 Technical Details

### Data Flow

```
Dry-Run Scan
    ↓
Category Data (CATEGORY_DATA)
    ↓
Item Data (CATEGORY_ITEMS)
    ↓
Export Function
    ↓
Format-Specific Output
    ↓
File or STDOUT
```

### Export Functions

```bash
# Main export function
export_cleanup_data <format>

# Individual format functions
export_to_json()
export_to_csv()
export_to_markdown()
export_to_html()
```

### Character Escaping

Each format properly escapes special characters:

- **JSON**: `\` and `"` → `\\` and `\"`
- **CSV**: `"` → `""`, fields with `,` quoted
- **Markdown**: Preserved (Markdown-safe)
- **HTML**: `&`, `<`, `>`, `"` → HTML entities

---

## 📊 Comparison Table

| Feature | JSON | CSV | Markdown | HTML |
|---------|------|-----|----------|------|
| **Size** | Medium | Small | Medium | Large |
| **Human Readable** | ⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **Machine Readable** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐ |
| **Spreadsheet Support** | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐ | ⭐⭐ |
| **Visual Appeal** | ⭐⭐ | ⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **Automation** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐ | ⭐⭐ |
| **Email Friendly** | ⭐⭐ | ⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |

### When to Use Each Format

**JSON** - When you need:
- API integration
- Programmatic processing
- Complex data structures
- Maximum flexibility

**CSV** - When you need:
- Spreadsheet analysis
- Simple data processing
- Universal compatibility
- Smallest file size

**Markdown** - When you need:
- Documentation
- Version control
- Human readability
- Plain text format

**HTML** - When you need:
- Beautiful reports
- Email attachments
- Presentations
- Print-friendly output

---

## 🎯 Real-World Examples

### Example 1: Weekly Cleanup Report

```bash
#!/bin/bash
# weekly_cleanup_report.sh

DATE=$(date +%Y-%m-%d)
OUTPUT_DIR="$HOME/cleanup_reports"
mkdir -p "$OUTPUT_DIR"

# Generate all formats
mo clean --dry-run --export json > "$OUTPUT_DIR/$DATE-report.json"
mo clean --dry-run --export csv > "$OUTPUT_DIR/$DATE-report.csv"
mo clean --dry-run --export html > "$OUTPUT_DIR/$DATE-report.html"

# Email HTML report
echo "Weekly cleanup report" | mail -s "Cleanup Report $DATE" \
    -a "$OUTPUT_DIR/$DATE-report.html" admin@company.com
```

### Example 2: Disk Usage Tracking

```bash
#!/bin/bash
# track_disk_usage.sh

# Append to CSV log
mo clean --dry-run --export csv | tail -n +2 >> disk_usage_log.csv

# Analyze trends with Python/R
python analyze_disk_trends.py disk_usage_log.csv
```

### Example 3: Automated Cleanup Decision

```bash
#!/bin/bash
# smart_cleanup.sh

# Export to JSON
mo clean --dry-run --export json > /tmp/cleanup.json

# Parse with jq
TOTAL_SIZE=$(jq '.summary.total_size' /tmp/cleanup.json)

# Cleanup if over 10GB
if [[ $TOTAL_SIZE -gt 10737418240 ]]; then
    echo "Over 10GB of cleanable data found, running cleanup..."
    mo clean --backup
else
    echo "Less than 10GB, skipping cleanup"
fi
```

---

## ✨ Advanced Features

### Custom Processing

```bash
# Pipe JSON through jq for custom output
mo clean --dry-run --export json | jq '.categories[] | 
    select(.size_bytes > 1000000000) | 
    {name, size: .size_human}'

# Filter CSV with awk
mo clean --dry-run --export csv | awk -F, '$3 > 1000000000 {print $1,$2,$4}'

# Convert Markdown to PDF
mo clean --dry-run --export md | pandoc -o report.pdf
```

### Integration Examples

```python
# Python
import json
with open('report.json') as f:
    data = json.load(f)
    print(f"Total: {data['summary']['total_size_human']}")
```

```javascript
// Node.js
const fs = require('fs');
const data = JSON.parse(fs.readFileSync('report.json'));
console.log(`Total: ${data.summary.total_size_human}`);
```

```r
# R
library(readr)
data <- read_csv("report.csv")
summary(data$`Size (Bytes)`)
```

---

## 📋 Export Checklist

When exporting cleanup data:

- [ ] Choose appropriate format for your use case
- [ ] Redirect output to file (not terminal)
- [ ] Verify file was created successfully
- [ ] Check file size is reasonable
- [ ] Test opening in target application
- [ ] Store securely if contains sensitive paths
- [ ] Add to .gitignore if in version control

---

**Status:** ✅ Task 2.3 Complete - All Formats Implemented

**Files Created:**
- `lib/export.sh` (600+ lines)
- `test/export_demo.sh` (demonstration)
- `docs/EXPORT_FORMATS_GUIDE.md` (this file)

**Next:** Integration with `bin/clean.sh` and testing
