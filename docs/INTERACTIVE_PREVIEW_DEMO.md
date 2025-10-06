# Interactive Preview Mode - Visual Guide

**Status:** ✅ Implemented  
**Date:** October 6, 2025  
**Task:** 2.2

---

## 🎯 Overview

Interactive Preview Mode allows users to selectively choose which items to clean before running the cleanup operation. This provides maximum control and confidence.

---

## 🖥️ Interactive Display

### Main Selection Screen

```
╔══════════════════════════════════════════════════════════════╗
║          🔍 Interactive Cleanup Preview                      ║
╚══════════════════════════════════════════════════════════════╝

Select items to clean (↑↓ navigate, SPACE toggle, ENTER confirm):

┌────────────────────────────────────────────────────────────────┐
│ ☑ 🌐 Browser Caches                        5.2GB    892 files │ ← Category
│ ☑   └─ Google Chrome                       3.8GB    456 files │ ← Item
│ ☑   └─ Firefox                             892MB    234 files │
│ ☑   └─ Safari                              512MB     78 files │
│                                                                │
│ ☑ 💻 Developer Tools                       2.3GB    355 files │
│ ☑   └─ npm cache                           1.2GB    234 files │
│ ☑   └─ pip cache                           856MB     89 files │
│ ☑   └─ Docker                              234MB     32 files │
│                                                                │
│ ☐ 📦 App Caches                            1.2GB    234 files │ ← Deselected
│ ☐   └─ Slack                               567MB    123 files │
│ ☐   └─ Spotify                             645MB    111 files │
│                                                                │
│ ☑ 📝 Logs                                  456MB    123 files │
└────────────────────────────────────────────────────────────────┘

Selected: 3 categories │ 8.0GB │ 1370 files

Controls:
  ↑↓  Navigate    SPACE  Toggle    A  Select All    N  Deselect All
  ENTER  Continue    Q  Cancel    ?  Help
```

### Navigation States

#### Cursor on Category
```
│ ☑ 🌐 Browser Caches                        5.2GB    892 files │ ← Highlighted
│ ☑   └─ Google Chrome                       3.8GB    456 files │
│ ☑   └─ Firefox                             892MB    234 files │
```

#### Cursor on Item
```
│ ☑ 🌐 Browser Caches                        5.2GB    892 files │
│ ☑   └─ Google Chrome                       3.8GB    456 files │ ← Highlighted
│ ☑   └─ Firefox                             892MB    234 files │
```

---

## 🎮 User Interactions

### 1. **Basic Navigation**
- **↑ / ↓ Arrow Keys** - Move cursor up/down through list
- **Home** - Jump to top (planned)
- **End** - Jump to bottom (planned)

### 2. **Selection Actions**
- **SPACE** - Toggle selection of current item
  - On category: Selects/deselects all items under it
  - On item: Selects/deselects just that item
- **A** - Select All (all categories and items)
- **N** - Deselect All (clear all selections)

### 3. **Confirmation Actions**
- **ENTER** - Confirm selection and proceed to cleanup
- **Q / ESC** - Cancel and exit without changes

### 4. **Help**
- **?** - Show help screen with controls and tips

---

## 📊 Selection Behavior

### Category-Level Selection

When you select a category:
```
Before SPACE:
│ ☐ 📦 App Caches                            1.2GB    234 files │
│ ☐   └─ Slack                               567MB    123 files │
│ ☐   └─ Spotify                             645MB    111 files │

After SPACE:
│ ☑ 📦 App Caches                            1.2GB    234 files │
│ ☑   └─ Slack                               567MB    123 files │
│ ☑   └─ Spotify                             645MB    111 files │
```
**Result:** All items under the category are selected

### Item-Level Selection

Individual items can be toggled independently:
```
│ ☑ 📦 App Caches                            1.2GB    234 files │
│ ☑   └─ Slack                               567MB    123 files │ ← Toggle this
│ ☐   └─ Spotify                             645MB    111 files │ ← Different state
```

---

## 🎨 Visual Indicators

### Checkboxes
- `☑` - **Selected** (will be cleaned)
- `☐` - **Not selected** (will be kept)

### Category Icons
- 🌐 Browser Caches
- 💻 Developer Tools
- 📦 App Caches
- 📝 Logs
- 🗑️  Trash
- 💾 System Caches
- 🧹 Orphaned Data

### Color Coding
- **Cyan** - Current cursor position
- **Green** - Selection summary (size, count)
- **Gray** - Deselected items
- **Blue** - Control hints

### Hierarchy
- **Category** - No indentation, bold appearance
- **Item** - Indented with `└─` tree connector

---

## 🔄 Workflow Examples

### Example 1: Clean Everything Except App Caches

1. Launch: `mo clean --preview`
2. All items selected by default
3. Navigate to "App Caches" category
4. Press SPACE to deselect
5. Press ENTER to confirm
6. Result: Everything cleaned except App Caches

### Example 2: Clean Only Browser Caches

1. Launch: `mo clean --preview`
2. Press `N` to deselect all
3. Navigate to "Browser Caches"
4. Press SPACE to select
5. Press ENTER to confirm
6. Result: Only browser caches cleaned

### Example 3: Selective App Cache Cleaning

1. Launch: `mo clean --preview`
2. Navigate to "Slack" under App Caches
3. Press SPACE to toggle off
4. Navigate to "Spotify"
5. Press SPACE to toggle off
6. Press ENTER
7. Result: All app caches cleaned except Slack and Spotify

---

## 📋 Confirmation Screen

After pressing ENTER, you see:

```
╔══════════════════════════════════════════════════════════════╗
║                  Selection Confirmed!                        ║
╚══════════════════════════════════════════════════════════════╝

Selected categories for cleanup:

  ✓ 🌐 Browser Caches (5.2GB, 892 files)
  ✓ 💻 Developer Tools (2.3GB, 355 files)
  ✓ 📝 Logs (456MB, 123 files)

Total to clean: 8.0GB (1370 files)

Proceed with cleanup? (y/N):
```

---

## ❓ Help Screen

Pressing `?` shows:

```
╔══════════════════════════════════════════════════════════════╗
║                    Interactive Preview Help                  ║
╚══════════════════════════════════════════════════════════════╝

Navigation:
  ↑ / ↓         - Move cursor up/down
  SPACE         - Toggle item selection
  ENTER         - Confirm selection and continue
  Q / ESC       - Cancel and exit

Bulk Actions:
  A             - Select all items
  N             - Deselect all items

Display:
  Categories are shown in bold with folder icons
  Items under categories are indented with └─
  ☑ indicates selected, ☐ indicates not selected

Selection Behavior:
  - Selecting a category selects all items under it
  - Deselecting a category deselects all items under it
  - Individual items can be toggled independently

Safety:
  - Only selected items will be cleaned
  - You can review the selection summary before confirming
  - No files are deleted until you confirm

Press any key to return to selection...
```

---

## 🎯 Command Usage

```bash
# Launch interactive preview
mo clean --preview

# Interactive preview with backup (recommended)
mo clean --preview --backup

# Skip preview and clean everything
mo clean

# Preview without actual cleaning (dry-run)
mo clean --dry-run
```

---

## ✨ Key Features

### ✅ Implemented
- **Checkbox Selection** - Visual toggle states
- **Keyboard Navigation** - Arrow keys, space, enter
- **Category Management** - Hierarchical selection
- **Real-time Totals** - Live size/file calculations
- **Bulk Actions** - Select all / Deselect all
- **Help System** - Built-in help screen
- **Cancel Support** - Q/ESC to abort

### 🎨 User Experience
- **Clear Visual Hierarchy** - Categories and items clearly distinguished
- **Immediate Feedback** - Selection changes update totals instantly
- **Safe Defaults** - All items selected by default (can deselect)
- **Reversible Actions** - Toggle back and forth freely
- **Confirmation Required** - Must press ENTER to proceed

---

## 🔧 Technical Implementation

### Data Structures
```bash
# Selection state
ITEM_SELECTED[key]=true/false

# Display items
DISPLAY_ITEMS[index]="display|size|files|type"

# Item keys for lookup
ITEM_KEYS[index]="cat_category" or "item_category_N"
```

### Key Functions
- `build_display_list()` - Prepare items for display
- `interactive_preview()` - Main interaction loop
- `toggle_item()` - Handle selection changes
- `calculate_selected_totals()` - Real-time statistics
- `get_selected_categories()` - Export selections for cleanup

---

## 🚀 Integration

### With Clean Command
```bash
# In bin/clean.sh
if [[ "$PREVIEW_MODE" == "true" ]]; then
    # Collect cleanup data
    collect_cleanup_data
    
    # Run interactive preview
    if interactive_preview; then
        # Get selected categories
        SELECTED_CATEGORIES=$(get_selected_categories)
        
        # Perform cleanup only for selected
        cleanup_selected_categories
    else
        # User cancelled
        echo "Cleanup cancelled"
        exit 0
    fi
fi
```

---

## 📊 Benefits

### For Users
- **Control** - Choose exactly what to clean
- **Confidence** - See what's selected before cleaning
- **Flexibility** - Toggle individual items or whole categories
- **Safety** - Review before committing

### For Cleanup Operations
- **Selective** - Clean only what's needed
- **Efficient** - Skip unnecessary categories
- **Targeted** - Focus on space-consuming items
- **Customizable** - Different needs, different selections

---

## 🎓 Usage Tips

1. **Start with everything selected** - Easier to deselect a few items
2. **Use category toggles** - Faster than individual items
3. **Review the summary** - Check totals before confirming
4. **Combine with backup** - Maximum safety: `mo clean --preview --backup`
5. **Press ? for help** - Anytime you forget controls

---

**Status:** ✅ Task 2.2 Complete - Ready for Integration

Next: Task 2.3 - JSON/CSV Export
