# Backup System Architecture

**Version:** 1.0  
**Date:** October 6, 2025  
**Status:** Design  
**Author:** Lead Dev

---

## 🎯 Overview

The backup system provides a safety net for users by creating compressed archives of files before deletion, enabling full or selective restoration if needed.

### Goals
1. **Safety**: Enable restoration of accidentally deleted files
2. **Efficiency**: Minimize storage overhead through compression
3. **Simplicity**: Easy to use and understand
4. **Performance**: <10% overhead on cleanup operations

---

## 🏗️ Architecture Design

### Directory Structure

```
~/.cache/mole/backups/
├── 2025-10-06-143052/              # Timestamp-based backup
│   ├── manifest.json               # Backup metadata
│   ├── backup.tar.gz               # Compressed archive
│   └── checksum.sha256             # Integrity verification
├── 2025-10-05-091234/
│   ├── manifest.json
│   ├── backup.tar.gz
│   └── checksum.sha256
└── .retention                      # Retention policy config
```

### Why This Structure?

1. **Timestamp directories**: Easy to identify and sort by date
2. **Separate manifest**: Fast listing without decompressing
3. **Checksum file**: Verify integrity before restore
4. **Hidden retention file**: Store policy configuration

---

## 📄 Manifest Format (JSON)

```json
{
  "version": "1.0",
  "timestamp": "2025-10-06T14:30:52Z",
  "backup_id": "2025-10-06-143052",
  "trigger": "manual",
  "command": "mo clean --backup",
  "system": {
    "os": "macOS 14.1",
    "hostname": "MacBook-Pro.local",
    "user": "hermenegildosantos"
  },
  "stats": {
    "total_size_bytes": 8804683776,
    "compressed_size_bytes": 2641405132,
    "compression_ratio": 0.70,
    "file_count": 1247,
    "duration_seconds": 23
  },
  "categories": [
    {
      "name": "Browser Caches",
      "size_bytes": 5473960346,
      "file_count": 892,
      "items": [
        {
          "original_path": "~/Library/Caches/Google/Chrome",
          "archived_path": "browser_caches/Google_Chrome",
          "size_bytes": 5473960346,
          "type": "directory",
          "mtime": 1696604652
        }
      ]
    },
    {
      "name": "Developer Tools",
      "size_bytes": 2330723430,
      "file_count": 355,
      "items": [
        {
          "original_path": "~/.npm/_cacache",
          "archived_path": "developer_tools/npm_cacache",
          "size_bytes": 2330723430,
          "type": "directory",
          "mtime": 1696601234
        }
      ]
    }
  ],
  "metadata": {
    "created_at": "2025-10-06T14:30:52Z",
    "expires_at": "2025-10-13T14:30:52Z",
    "retention_days": 7,
    "auto_cleanup": true
  }
}
```

### Manifest Fields Explained

| Field | Purpose |
|-------|---------|
| `version` | Schema version for future compatibility |
| `backup_id` | Unique identifier (timestamp-based) |
| `trigger` | How backup was initiated (manual/scheduled) |
| `stats` | Quick overview without parsing archive |
| `categories` | Grouped by cleanup category |
| `items.original_path` | Where file came from |
| `items.archived_path` | Where in archive to find it |
| `metadata.expires_at` | When to auto-delete |

---

## 🗜️ Compression Strategy

### Technology: tar + gzip

**Rationale:**
- ✅ Built-in on macOS (no dependencies)
- ✅ Universal format (portable)
- ✅ Good compression ratio (70-80%)
- ✅ Supports preserving permissions/timestamps
- ✅ Can extract selectively

**Command:**
```bash
tar -czf backup.tar.gz -C / \
  --exclude='.DS_Store' \
  --exclude='._*' \
  --files-from=file_list.txt
```

**Compression Levels:**
- Default (gzip -6): Balance of speed/size
- Fast (gzip -1): For large backups >10GB
- Best (gzip -9): For small backups <1GB

### Archive Structure

```
backup.tar.gz
├── browser_caches/
│   ├── Google_Chrome/
│   │   └── [files...]
│   └── Safari/
│       └── [files...]
├── developer_tools/
│   ├── npm_cacache/
│   └── xcode_derived_data/
└── app_logs/
    └── [files...]
```

**Path Sanitization:**
- Replace `/` with `_` in directory names
- Remove `~` prefix
- Preserve directory structure within categories

---

## 🔄 Backup Flow

```
┌─────────────────────────────────────────────────────────┐
│ User: mo clean --backup                                 │
└──────────────────┬──────────────────────────────────────┘
                   ▼
┌─────────────────────────────────────────────────────────┐
│ 1. Check Prerequisites                                  │
│    • Sufficient disk space (2x data size)               │
│    • Backup directory writable                          │
│    • No concurrent backups                              │
└──────────────────┬──────────────────────────────────────┘
                   ▼
┌─────────────────────────────────────────────────────────┐
│ 2. Create Backup Directory                             │
│    • Generate timestamp ID                              │
│    • Create ~/.cache/mole/backups/YYYY-MM-DD-HHMMSS/   │
└──────────────────┬──────────────────────────────────────┘
                   ▼
┌─────────────────────────────────────────────────────────┐
│ 3. Scan Files to Clean                                 │
│    • Run cleanup detection (dry-run internally)         │
│    • Build file list with metadata                      │
│    • Calculate total size                               │
└──────────────────┬──────────────────────────────────────┘
                   ▼
┌─────────────────────────────────────────────────────────┐
│ 4. Create Archive                                       │
│    • Show progress (percentage/size)                    │
│    • Compress with tar + gzip                           │
│    • Handle errors gracefully                           │
└──────────────────┬──────────────────────────────────────┘
                   ▼
┌─────────────────────────────────────────────────────────┐
│ 5. Generate Manifest                                    │
│    • Write manifest.json                                │
│    • Calculate checksum                                 │
│    • Write checksum.sha256                              │
└──────────────────┬──────────────────────────────────────┘
                   ▼
┌─────────────────────────────────────────────────────────┐
│ 6. Verify Backup                                        │
│    • Check archive integrity                            │
│    • Verify checksum                                    │
│    • Confirm file count                                 │
└──────────────────┬──────────────────────────────────────┘
                   ▼
┌─────────────────────────────────────────────────────────┐
│ 7. Proceed with Cleanup                                │
│    • Now safe to delete files                           │
│    • Track cleanup success                              │
└──────────────────┬──────────────────────────────────────┘
                   ▼
┌─────────────────────────────────────────────────────────┐
│ 8. Post-Backup Tasks                                   │
│    • Update manifest with cleanup status                │
│    • Check total backup size vs limit                   │
│    • Trigger auto-cleanup if needed                     │
└─────────────────────────────────────────────────────────┘
```

---

## 🔙 Restore Flow

### Full Restore

```
┌─────────────────────────────────────────────────────────┐
│ User: mo restore                                        │
└──────────────────┬──────────────────────────────────────┘
                   ▼
┌─────────────────────────────────────────────────────────┐
│ 1. List Available Backups                              │
│    • Scan ~/.cache/mole/backups/                        │
│    • Parse manifest.json for each                       │
│    • Sort by date (newest first)                        │
└──────────────────┬──────────────────────────────────────┘
                   ▼
┌─────────────────────────────────────────────────────────┐
│ 2. Interactive Selection                                │
│    • Show: Date, Size, Categories                       │
│    • User selects backup                                │
│    • Display backup details                             │
└──────────────────┬──────────────────────────────────────┘
                   ▼
┌─────────────────────────────────────────────────────────┐
│ 3. Verify Backup Integrity                             │
│    • Check checksum                                     │
│    • Verify archive not corrupted                       │
│    • Warn if checksum mismatch                          │
└──────────────────┬──────────────────────────────────────┘
                   ▼
┌─────────────────────────────────────────────────────────┐
│ 4. Confirm Restore                                      │
│    • Show what will be restored                         │
│    • Warn about overwriting existing files              │
│    • User confirms (y/N)                                │
└──────────────────┬──────────────────────────────────────┘
                   ▼
┌─────────────────────────────────────────────────────────┐
│ 5. Extract Archive                                      │
│    • Show progress                                      │
│    • Extract to original paths                          │
│    • Preserve permissions/timestamps                    │
└──────────────────┬──────────────────────────────────────┘
                   ▼
┌─────────────────────────────────────────────────────────┐
│ 6. Verify Restoration                                   │
│    • Count restored files                               │
│    • Check critical paths exist                         │
│    • Report success/failures                            │
└──────────────────┬──────────────────────────────────────┘
                   ▼
┌─────────────────────────────────────────────────────────┐
│ 7. Cleanup (Optional)                                   │
│    • Ask: Delete this backup? (y/N)                     │
│    • Remove backup directory if confirmed               │
└─────────────────────────────────────────────────────────┘
```

### Selective Restore

```
User: mo restore --list-files 2025-10-06-143052
→ Show tree of files in backup

User: mo restore --files "browser_caches/*"
→ Restore only matching paths
```

---

## 🗑️ Retention & Auto-Cleanup

### Retention Policy

**Default Configuration** (`~/.cache/mole/backups/.retention`):
```ini
# Retention policy for Mole backups
[retention]
max_age_days=7
max_size_gb=10
max_count=10
auto_cleanup=true

[cleanup_strategy]
# Keep newest when over limit
keep_strategy=newest
# Or keep: oldest, largest, smallest
```

### Auto-Cleanup Logic

```python
# Pseudo-code
def auto_cleanup_backups():
    backups = list_all_backups()
    
    # Strategy 1: Age-based
    for backup in backups:
        if backup.age_days > retention.max_age_days:
            delete_backup(backup)
    
    # Strategy 2: Size-based
    total_size = sum(b.size for b in backups)
    if total_size > retention.max_size_gb:
        # Keep newest, delete oldest until under limit
        backups.sort(by='date', reverse=True)
        while total_size > retention.max_size_gb:
            oldest = backups.pop()
            delete_backup(oldest)
            total_size -= oldest.size
    
    # Strategy 3: Count-based
    if len(backups) > retention.max_count:
        # Keep newest N backups
        excess = backups[retention.max_count:]
        for backup in excess:
            delete_backup(backup)
```

### When Auto-Cleanup Runs

1. **After each backup** - Keep storage under control
2. **Before backup** - Make space if needed
3. **On schedule** - Daily cleanup check (via cron)
4. **Manual** - `mo backup-clean`

---

## 🔒 Security & Safety

### File Permissions

```bash
# Backup directory permissions
~/.cache/mole/backups/          # 700 (owner only)
├── 2025-10-06-143052/          # 700
│   ├── manifest.json           # 600
│   ├── backup.tar.gz           # 600
│   └── checksum.sha256         # 600
```

### Integrity Verification

**Checksum Generation:**
```bash
# Create checksum
sha256sum backup.tar.gz > checksum.sha256

# Verify checksum
sha256sum -c checksum.sha256
```

**Verification Points:**
1. After backup creation
2. Before restore operation
3. During auto-cleanup (verify before delete)

### Path Safety

**Prevent Directory Traversal:**
```bash
# Validate paths before restore
validate_restore_path() {
    local path="$1"
    
    # Reject dangerous patterns
    [[ "$path" =~ \.\. ]] && return 1  # No ../
    [[ "$path" =~ ^/ ]] && return 1    # No absolute paths
    [[ "$path" =~ ~/ ]] && return 1    # No home expansion
    
    return 0
}
```

**Sandbox Extraction:**
```bash
# Extract to temp dir first, then move
temp_dir=$(mktemp -d)
tar -xzf backup.tar.gz -C "$temp_dir"
# Validate extracted paths
# Then move to final destination
```

---

## 📊 Performance Considerations

### Target Performance

| Operation | Target | Max Acceptable |
|-----------|--------|----------------|
| Backup creation | 5s per GB | 10s per GB |
| Restore | 5s per GB | 10s per GB |
| List backups | <1s | 2s |
| Verify integrity | 2s per GB | 5s per GB |

### Optimization Strategies

1. **Parallel Compression**
   ```bash
   # Use pigz (parallel gzip) if available
   if command -v pigz &>/dev/null; then
       tar -I pigz -cf backup.tar.gz files/
   else
       tar -czf backup.tar.gz files/
   fi
   ```

2. **Incremental Backup** (Future)
   - Only backup changed files
   - Store deltas instead of full copies
   - Link unchanged files

3. **Smart Compression**
   - Already compressed files (jpg, mp4, zip): Store only
   - Text files: Maximum compression
   - Detect file types automatically

4. **Progress Tracking**
   ```bash
   # Show progress with pv if available
   tar -cf - files/ | pv -s $(du -sb files/ | awk '{print $1}') | gzip > backup.tar.gz
   ```

---

## 🧪 Testing Strategy

### Unit Tests

```bash
# test/backup_unit_test.sh
test_manifest_generation()
test_compression_ratio()
test_checksum_verification()
test_path_sanitization()
test_size_calculation()
```

### Integration Tests

```bash
# test/backup_integration_test.sh
test_backup_and_restore_full()
test_backup_and_restore_selective()
test_backup_with_large_files()
test_backup_with_symlinks()
test_concurrent_backup_prevention()
test_restore_with_corrupted_archive()
```

### Test Data Sets

1. **Small** (10MB, 100 files) - Fast iteration
2. **Medium** (1GB, 1000 files) - Typical case
3. **Large** (10GB, 10000 files) - Stress test
4. **Edge cases**:
   - Files with special characters
   - Very deep directory trees
   - Symlinks
   - Files being modified during backup

---

## 🚨 Error Handling

### Error Categories

1. **Insufficient Disk Space**
   ```
   ❌ Error: Not enough disk space for backup
   Required: 8.2GB (2x cleanup size)
   Available: 5.1GB
   
   Solutions:
   - Free up space with: mo clean (without backup)
   - Increase backup compression
   - Clean old backups: mo backup-clean
   ```

2. **Corrupted Backup**
   ```
   ⚠️  Warning: Backup checksum mismatch
   Expected: abc123...
   Got:      def456...
   
   This backup may be corrupted. Continue restore? (y/N)
   ```

3. **Permission Denied**
   ```
   ❌ Error: Cannot create backup directory
   Path: ~/.cache/mole/backups/
   
   Try: chmod 755 ~/.cache/mole/
   ```

4. **Concurrent Backup**
   ```
   ⚠️  Another backup is in progress
   Started: 2 minutes ago
   
   [Wait] [Cancel Other] [Abort]
   ```

### Recovery Strategies

| Error | Recovery Action |
|-------|----------------|
| Disk full during backup | Clean partial backup, abort |
| Checksum mismatch | Offer to continue or abort |
| Corrupted archive | List other backups available |
| Missing manifest | Attempt to reconstruct from archive |

---

## 📈 Future Enhancements

### Phase 2 (Nice to Have)

1. **Incremental Backups**
   - Only backup changed files since last backup
   - Link to previous backup for unchanged files
   - Save 80%+ space for repeated backups

2. **Compression Algorithm Choice**
   ```bash
   mo clean --backup --compress zstd  # Faster, better ratio
   mo clean --backup --compress lz4   # Fastest
   mo clean --backup --compress gzip  # Default, universal
   ```

3. **Cloud Sync**
   ```bash
   mo backup-sync icloud    # Sync to iCloud Drive
   mo backup-sync dropbox   # Sync to Dropbox
   ```

4. **Backup Encryption**
   ```bash
   mo clean --backup --encrypt  # AES-256 encryption
   # Requires password
   ```

5. **Differential Backups**
   - Full backup weekly
   - Differential daily
   - Minimal storage overhead

### Phase 3 (Advanced)

1. **Deduplication**
   - Detect identical files across backups
   - Store only once, link elsewhere
   - 50%+ space savings

2. **Smart Restore**
   ```bash
   mo restore --smart
   # Only restore files that don't exist
   # Skip if current version is newer
   ```

3. **Backup Profiles**
   ```bash
   mo backup-profile create aggressive
   # Max compression, no size limit
   
   mo backup-profile create quick
   # Fast compression, 2GB limit
   ```

---

## 📝 Implementation Checklist

### Phase 1 - Core Functionality

- [ ] Design document (this file) ✅
- [ ] Directory structure creation
- [ ] Manifest generation
- [ ] Compression logic
- [ ] Checksum generation/verification
- [ ] Basic restore functionality
- [ ] Error handling
- [ ] Progress indicators

### Phase 2 - Polish

- [ ] Retention policy
- [ ] Auto-cleanup
- [ ] Selective restore
- [ ] List backups UI
- [ ] Verify backup command
- [ ] Performance optimization

### Phase 3 - Advanced

- [ ] Incremental backups
- [ ] Cloud sync
- [ ] Encryption
- [ ] Deduplication

---

## 🔗 Related Documents

- **Implementation**: `lib/backup.sh` (to be created)
- **Tests**: `test/backup_test.sh` (to be created)
- **User Guide**: `docs/backup-restore-guide.md` (to be created)
- **API**: See function signatures in implementation

---

## ✅ Architecture Approval

**Reviewed by:** [Pending]  
**Approved by:** [Pending]  
**Date:** [Pending]

**Sign-off indicates:**
- Architecture is sound and implementable
- Performance targets are reasonable
- Security considerations adequate
- Ready to proceed with implementation

---

**Status: Ready for Implementation** 🚀

Next: Create `lib/backup.sh` with core functions
