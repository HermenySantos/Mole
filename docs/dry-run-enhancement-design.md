# Enhanced Dry-Run Output - Design Document

**Version:** 1.0  
**Date:** October 6, 2025  
**Status:** Design  
**Task:** 2.1, 2.2, 2.3

---

## 🎯 Overview

Enhance the dry-run functionality to provide users with:
1. **Better visualization** of what will be cleaned
2. **Interactive preview** with selection capability
3. **Export options** for analysis and record-keeping

---

## 📋 Current State Analysis

### Existing Dry-Run Behavior

The current `mo clean --dry-run` implementation:
- ✅ Shows what would be cleaned
- ✅ Displays size information
- ✅ Prevents actual deletion
- ❌ Limited visualization (just lists items)
- ❌ No categorization summary
- ❌ No export capability
- ❌ No interactive selection

### Example Current Output
```bash
$ mo clean --dry-run

🧹 Clean Your Mac
🍎 Apple Silicon | 💾 Free space: 45.2GB

System essentials
  → User app cache (1.2GB dry)
  → User app logs (234MB dry)
  → Trash (567MB dry)
  ...
```

---

## 🎨 Enhanced Design

### Task 2.1: Enhanced Dry-Run Output

#### **Summary View**

Display a comprehensive summary at the end:

```
╔══════════════════════════════════════════════════════════╗
║          DRY-RUN SUMMARY - No files deleted              ║
╚══════════════════════════════════════════════════════════╝

📊 Category Breakdown:
┌──────────────────────────┬──────────┬────────┬──────────┐
│ Category                 │ Size     │ Files  │ Items    │
├──────────────────────────┼──────────┼────────┼──────────┤
│ 🌐 Browser Caches        │ 5.2GB    │  892   │    4     │
│ 👨‍💻 Developer Tools       │ 2.3GB    │  355   │    3     │
│ 📦 App Caches            │ 1.2GB    │  234   │    8     │
│ 📝 Logs                  │ 456MB    │  123   │    5     │
│ 🗑️  Trash                │ 234MB    │   45   │    1     │
│ 💾 System Caches         │ 189MB    │   67   │    4     │
│ 🧹 Orphaned Data         │ 89MB     │   23   │    2     │
├──────────────────────────┼──────────┼────────┼──────────┤
│ TOTAL                    │ 9.6GB    │ 1739   │   27     │
└──────────────────────────┴──────────┴────────┴──────────┘

💾 Estimated space to recover: 9.6GB
📈 Current free space: 45.2GB → 54.8GB
🎯 Improvement: +21.2%

⚙️  Options:
  • Run cleanup:     mo clean
  • With backup:     mo clean --backup
  • Select items:    mo clean --preview
  • Export data:     mo clean --dry-run --export json
```

#### **Tree View Mode**

```bash
$ mo clean --dry-run --tree

🌳 Cleanup Tree View:

📁 Browser Caches (5.2GB)
├── 🌐 Google Chrome (3.8GB)
│   ├── Cache (3.2GB, 456 files)
│   ├── Code Cache (512MB, 89 files)
│   └── Service Worker (89MB, 12 files)
├── 🦊 Firefox (892MB)
│   └── cache2 (892MB, 234 files)
└── 🧭 Safari (512MB)
    └── Caches (512MB, 78 files)

💻 Developer Tools (2.3GB)
├── 📦 npm cache (1.2GB, 234 files)
├── 🐍 pip cache (856MB, 89 files)
└── 🐳 Docker (234MB, 32 files)

🗑️  Trash (234MB, 45 files)
...
```

#### **Detailed View Mode**

```bash
$ mo clean --dry-run --detailed

📋 Detailed Cleanup Report

Category: Browser Caches
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
1. Google Chrome Cache
   Path: ~/Library/Caches/Google/Chrome/Default/Cache
   Size: 3.2GB (3,458,906,112 bytes)
   Files: 456 files, 23 directories
   Last Modified: 2 hours ago
   Safety: ✅ Safe to delete (browser will rebuild)
   
2. Firefox Cache
   Path: ~/Library/Caches/Firefox/Profiles/default/cache2
   Size: 892MB (935,718,912 bytes)
   Files: 234 files
   Last Modified: 1 hour ago
   Safety: ✅ Safe to delete
...
```

---

### Task 2.2: Interactive Preview Mode

Allow users to selectively choose what to clean:

```bash
$ mo clean --preview

🔍 Interactive Cleanup Preview

Select items to clean (↑↓ to navigate, SPACE to select, ENTER to confirm):

┌────────────────────────────────────────────────────────────┐
│ [✓] Browser Caches                           5.2GB   892   │
│     ├─ [✓] Google Chrome                     3.8GB   456   │
│     ├─ [✓] Firefox                           892MB   234   │
│     └─ [✓] Safari                            512MB    78   │
│                                                            │
│ [✓] Developer Tools                          2.3GB   355   │
│     ├─ [✓] npm cache                         1.2GB   234   │
│     ├─ [✓] pip cache                         856MB    89   │
│     └─ [✓] Docker                            234MB    32   │
│                                                            │
│ [ ] App Caches                               1.2GB   234   │
│     ├─ [ ] Slack                             567MB   123   │
│     └─ [ ] Spotify                           645MB   111   │
│                                                            │
│ [✓] Logs                                     456MB   123   │
│ [✓] Trash                                    234MB    45   │
│                                                            │
│ Selected: 6 categories, 8.1GB                             │
└────────────────────────────────────────────────────────────┘

Options:
  ↑↓  Navigate    SPACE  Toggle    A  Select All    N  Deselect All
  ENTER  Continue    Q  Cancel    ?  Help

After selection:
  ✓ 8.1GB will be cleaned (5 categories)
  • Slack and Spotify caches will be kept
  
Continue? [y/N]: 
```

#### **Expandable Categories**

```bash
[✓] Browser Caches (5.2GB) ─┐
                            │
                            ├─ [✓] Chrome (3.8GB)
                            │   ├─ [✓] Cache (3.2GB)
                            │   ├─ [✓] Code Cache (512MB)
                            │   └─ [ ] Cookies (2MB)  ← Excluded
                            │
                            ├─ [✓] Firefox (892MB)
                            └─ [✓] Safari (512MB)
```

---

### Task 2.3: Export Capabilities

#### **JSON Export**

```bash
$ mo clean --dry-run --export json > cleanup_report.json
```

```json
{
  "timestamp": "2025-10-06T21:30:00Z",
  "hostname": "MacBook-Pro.local",
  "user": "hermenegildosantos",
  "system": {
    "os": "macOS 15.1",
    "architecture": "arm64",
    "free_space_before": "45.2GB",
    "free_space_after_estimate": "54.8GB"
  },
  "summary": {
    "total_size": 10297466880,
    "total_size_human": "9.6GB",
    "total_files": 1739,
    "total_items": 27,
    "categories": 7
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
          "path": "~/Library/Caches/Google/Chrome/Default/Cache",
          "size_bytes": 4074848256,
          "size_human": "3.8GB",
          "file_count": 456,
          "last_modified": "2025-10-06T19:30:00Z",
          "safety_level": "safe"
        }
      ]
    }
  ],
  "warnings": [],
  "recommendations": [
    "Consider running with --backup for safety",
    "Browser caches will be automatically rebuilt",
    "npm cache can be cleared safely"
  ]
}
```

#### **CSV Export**

```bash
$ mo clean --dry-run --export csv > cleanup_report.csv
```

```csv
Category,Item,Path,Size (Bytes),Size (Human),Files,Last Modified,Safety
Browser Caches,Google Chrome,~/Library/Caches/Google/Chrome,4074848256,3.8GB,456,2025-10-06T19:30:00Z,safe
Browser Caches,Firefox,~/Library/Caches/Firefox,935718912,892MB,234,2025-10-06T20:15:00Z,safe
Developer Tools,npm cache,~/.npm,1288490189,1.2GB,234,2025-10-05T14:20:00Z,safe
...
```

#### **Markdown Export**

```bash
$ mo clean --dry-run --export md > cleanup_report.md
```

```markdown
# Mole Cleanup Report

**Generated:** October 6, 2025 21:30:00  
**System:** MacBook-Pro.local (macOS 15.1, Apple Silicon)  
**User:** hermenegildosantos

## Summary

- **Total Size:** 9.6GB (10,297,466,880 bytes)
- **Total Files:** 1,739 files
- **Total Items:** 27 items
- **Categories:** 7 categories
- **Estimated Recovery:** 9.6GB
- **Free Space:** 45.2GB → 54.8GB (+21.2%)

## Category Breakdown

### 🌐 Browser Caches (5.2GB, 892 files)

1. **Google Chrome** - 3.8GB (456 files)
   - Path: `~/Library/Caches/Google/Chrome/Default/Cache`
   - Last Modified: 2 hours ago
   - ✅ Safe to delete

2. **Firefox** - 892MB (234 files)
   - Path: `~/Library/Caches/Firefox/Profiles/default/cache2`
   - Last Modified: 1 hour ago
   - ✅ Safe to delete
...
```

---

## 🛠️ Implementation Plan

### Phase 1: Data Collection Enhancement

**File:** `bin/clean.sh` modifications

1. **Add data collection structure:**
```bash
declare -A CLEANUP_DATA
declare -A CATEGORY_STATS

# Structure:
# CLEANUP_DATA[category_item]="path|size|files|mtime"
# CATEGORY_STATS[category]="total_size|total_files|item_count"
```

2. **Enhance `safe_clean` function:**
```bash
safe_clean() {
    # ... existing code ...
    
    # If dry-run, collect data instead of just printing
    if [[ "$DRY_RUN" == "true" ]]; then
        collect_cleanup_data "$description" "$path" "$size" "$count"
    fi
}
```

### Phase 2: Visualization Functions

**New File:** `lib/dry_run_display.sh`

Functions to implement:
- `show_summary_table()` - Category breakdown table
- `show_tree_view()` - Hierarchical tree display
- `show_detailed_view()` - Detailed item information
- `format_table()` - Table formatting helper
- `draw_progress_bar()` - Visual progress indicators

### Phase 3: Interactive Preview

**New File:** `lib/interactive_preview.sh`

Functions to implement:
- `interactive_cleanup_selector()` - Main interactive UI
- `build_selection_tree()` - Create selectable tree
- `handle_selection_input()` - Keyboard input handling
- `apply_selections()` - Execute selected items only

### Phase 4: Export Functions

**New File:** `lib/export.sh`

Functions to implement:
- `export_to_json()` - JSON format
- `export_to_csv()` - CSV format
- `export_to_markdown()` - Markdown format
- `export_to_html()` - HTML report (bonus)

---

## 📊 New Command-Line Options

```bash
# Enhanced dry-run
mo clean --dry-run              # Current behavior + summary
mo clean --dry-run --tree       # Tree view
mo clean --dry-run --detailed   # Detailed view
mo clean --dry-run --summary    # Summary only (no items)

# Interactive preview
mo clean --preview              # Interactive selection
mo clean --preview --backup     # With backup protection

# Export
mo clean --dry-run --export json
mo clean --dry-run --export csv
mo clean --dry-run --export md
mo clean --dry-run --export html

# Combined
mo clean --dry-run --tree --export json > report.json
```

---

## 🎨 UI/UX Improvements

### Color Coding

- 🟢 **Green** - Safe to delete, frequently cached
- 🟡 **Yellow** - Moderate risk, seldom needed
- 🔴 **Red** - Caution, may affect app performance
- 🔵 **Blue** - Information, headers
- ⚪ **Gray** - Disabled, not selected

### Icons & Symbols

- ✅ Safe
- ⚠️  Warning
- 🔒 Protected (whitelist)
- 📁 Directory
- 📄 File
- 🌐 Browser
- 💻 Developer
- 📦 Package
- 🗑️  Trash

---

## 🔧 Technical Considerations

### Performance

- **Dry-run should be fast** (<5 seconds for full scan)
- Cache scan results for preview mode
- Use parallel processing where appropriate
- Lazy-load detailed information

### Compatibility

- **Bash 3.2+** - macOS default
- **Terminal support** - Graceful degradation for non-interactive
- **Wide terminal** - Detect width, adapt layout
- **No external dependencies** - Built-in tools only

### Data Structure

```bash
# Efficient data storage
declare -A CLEANUP_REGISTRY
CLEANUP_REGISTRY[browsers_chrome_cache]="path=~/Library/Caches/Chrome|size=4074848256|files=456|category=browsers|subcategory=chrome|item=cache|mtime=1696604652"

# Fast lookups
get_item_size() {
    local key="$1"
    echo "${CLEANUP_REGISTRY[$key]}" | grep -o 'size=[0-9]*' | cut -d= -f2
}
```

---

## 🧪 Testing Strategy

### Unit Tests

- Data collection accuracy
- Table formatting
- Tree structure building
- Export format validation

### Integration Tests

- Full dry-run workflow
- Interactive preview flow
- Export to all formats
- Large dataset handling (10GB+)

### User Acceptance

- Readability tests
- Navigation tests
- Export usefulness
- Performance benchmarks

---

## 📋 Success Criteria

- ✅ Summary displays in <1 second
- ✅ Tree view renders correctly for 100+ items
- ✅ Interactive preview responds instantly
- ✅ JSON export validates against schema
- ✅ CSV opens correctly in Excel/Numbers
- ✅ All formats preserve data accuracy
- ✅ Works in 80-column terminal
- ✅ Graceful degradation in non-interactive mode

---

## 🎯 Deliverables

### Task 2.1: Enhanced Dry-Run Output
- Enhanced summary display
- Category breakdown table
- Tree view option
- Detailed view option
- Size/file statistics

### Task 2.2: Interactive Preview Mode
- Selectable item list
- Category expansion
- Keyboard navigation
- Visual feedback
- Selection confirmation

### Task 2.3: JSON/CSV Export
- JSON export with full metadata
- CSV export for spreadsheets
- Markdown export for documentation
- Export validation

---

**Status:** Ready for Implementation 🚀

Next Steps:
1. Create `lib/dry_run_display.sh`
2. Enhance data collection in `bin/clean.sh`
3. Implement summary display
4. Add tree view
5. Test and iterate
