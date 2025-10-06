#!/usr/bin/env bash

# ===============================================
# Mole Backup System - Core Library
# ===============================================
# Provides backup and restore functionality
# for safe cleanup operations
# ===============================================

# Source common utilities
# Use a local variable to avoid overriding the parent SCRIPT_DIR
_BACKUP_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$_BACKUP_LIB_DIR/common.sh"

# Backup configuration
BACKUP_DIR="${BACKUP_DIR:-${HOME}/.cache/mole/backups}"  # Allow override for testing
readonly BACKUP_VERSION="1.0"
# Note: RETENTION_CONFIG is set dynamically in functions to support BACKUP_DIR override

# Default retention settings
readonly DEFAULT_MAX_AGE_DAYS=7
readonly DEFAULT_MAX_SIZE_GB=10
readonly DEFAULT_MAX_COUNT=10
readonly DEFAULT_AUTO_CLEANUP=true

# ===============================================
# Initialization
# ===============================================

# Initialize backup system
init_backup_system() {
    local retention_config="${BACKUP_DIR}/.retention"
    
    log_debug "Initializing backup system"
    
    # Create backup directory if it doesn't exist
    if [[ ! -d "$BACKUP_DIR" ]]; then
        mkdir -p "$BACKUP_DIR" || {
            log_error "Failed to create backup directory: $BACKUP_DIR"
            return 1
        }
        chmod 700 "$BACKUP_DIR"
        log_debug "Created backup directory: $BACKUP_DIR"
    fi
    
    # Create retention config if it doesn't exist
    if [[ ! -f "$retention_config" ]]; then
        create_default_retention_config
    fi
    
    return 0
}

# Create default retention configuration
create_default_retention_config() {
    local retention_config="${BACKUP_DIR}/.retention"
    
    cat > "$retention_config" << EOF
# Mole Backup Retention Policy
# Last updated: $(date)

[retention]
max_age_days=$DEFAULT_MAX_AGE_DAYS
max_size_gb=$DEFAULT_MAX_SIZE_GB
max_count=$DEFAULT_MAX_COUNT
auto_cleanup=$DEFAULT_AUTO_CLEANUP

[cleanup_strategy]
# Keep newest when over limit
keep_strategy=newest
EOF
    
    chmod 600 "$retention_config"
    log_debug "Created default retention config"
}

# ===============================================
# Backup ID Generation
# ===============================================

# Generate unique backup ID from timestamp
generate_backup_id() {
    date +"%Y-%m-%d-%H%M%S"
}

# Get backup directory path for a given ID
get_backup_path() {
    local backup_id="$1"
    echo "${BACKUP_DIR}/${backup_id}"
}

# ===============================================
# Disk Space Checks
# ===============================================

# Check if sufficient disk space is available for backup
# Args: $1 - required bytes
check_sufficient_space() {
    local required_bytes="$1"
    local required_with_buffer=$((required_bytes * 2))  # 2x for safety
    
    local available_bytes
    available_bytes=$(get_free_space_bytes)
    
    if [[ $available_bytes -lt $required_with_buffer ]]; then
        log_error "Insufficient disk space for backup"
        log_error "Required: $(bytes_to_human $required_with_buffer) (2x cleanup size)"
        log_error "Available: $(bytes_to_human $available_bytes)"
        echo ""
        log_info "Solutions:"
        log_info "  - Free up space with: mo clean (without backup)"
        log_info "  - Clean old backups: mo backup-clean"
        return 1
    fi
    
    log_debug "Disk space check passed: $(bytes_to_human $available_bytes) available"
    return 0
}

# ===============================================
# Concurrent Backup Prevention
# ===============================================

# Check if another backup is in progress
is_backup_in_progress() {
    local lock_file="${BACKUP_DIR}/.backup.lock"
    
    if [[ -f "$lock_file" ]]; then
        local pid
        pid=$(cat "$lock_file" 2>/dev/null)
        
        # Check if process is still running
        if kill -0 "$pid" 2>/dev/null; then
            return 0  # Backup in progress
        else
            # Stale lock file, remove it
            rm -f "$lock_file"
            return 1
        fi
    fi
    
    return 1
}

# Create backup lock file
create_backup_lock() {
    local lock_file="${BACKUP_DIR}/.backup.lock"
    echo $$ > "$lock_file"
    log_debug "Created backup lock: $$"
}

# Remove backup lock file
remove_backup_lock() {
    local lock_file="${BACKUP_DIR}/.backup.lock"
    rm -f "$lock_file"
    log_debug "Removed backup lock"
}

# ===============================================
# Manifest Generation
# ===============================================

# Create backup manifest JSON
# Args: $1 - backup_id, $2 - backup_path, remaining args - files
create_manifest() {
    local backup_id="$1"
    local backup_path="$2"
    shift 2
    local -a files=("$@")
    local manifest_file="${backup_path}/manifest.json"
    
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    local hostname
    hostname=$(hostname)
    
    local os_version
    os_version="$(sw_vers -productName) $(sw_vers -productVersion)"
    
    # Calculate stats
    local total_size=0
    local file_count=${#files[@]}
    
    for file in "${files[@]}"; do
        if [[ -e "$file" ]]; then
            local size
            size=$(get_directory_size_bytes "$file")
            total_size=$((total_size + size))
        fi
    done
    
    # Start manifest JSON
    cat > "$manifest_file" << EOF
{
  "version": "$BACKUP_VERSION",
  "timestamp": "$timestamp",
  "backup_id": "$backup_id",
  "trigger": "manual",
  "command": "$0 ${ORIGINAL_ARGS:-}",
  "system": {
    "os": "$os_version",
    "hostname": "$hostname",
    "user": "$USER"
  },
  "stats": {
    "total_size_bytes": $total_size,
    "compressed_size_bytes": 0,
    "compression_ratio": 0,
    "file_count": $file_count,
    "duration_seconds": 0
  },
  "categories": [
EOF

    # TODO: Add categorized items
    # For now, just close the JSON
    
    cat >> "$manifest_file" << EOF
  ],
  "metadata": {
    "created_at": "$timestamp",
    "expires_at": "$(date -u -v +${DEFAULT_MAX_AGE_DAYS}d +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -u -d "+${DEFAULT_MAX_AGE_DAYS} days" +"%Y-%m-%dT%H:%M:%SZ")",
    "retention_days": $DEFAULT_MAX_AGE_DAYS,
    "auto_cleanup": $DEFAULT_AUTO_CLEANUP
  }
}
EOF
    
    chmod 600 "$manifest_file"
    log_debug "Created manifest: $manifest_file"
}

# Update manifest with compression stats
# Args: $1 - backup_path, $2 - compressed_size, $3 - duration
update_manifest_stats() {
    local backup_path="$1"
    local compressed_size="$2"
    local duration="$3"
    local manifest_file="${backup_path}/manifest.json"
    
    if [[ ! -f "$manifest_file" ]]; then
        log_error "Manifest not found: $manifest_file"
        return 1
    fi
    
    # Read total size from manifest
    local total_size
    total_size=$(grep -o '"total_size_bytes": [0-9]*' "$manifest_file" | awk '{print $2}')
    
    # Calculate compression ratio
    local ratio=0
    if [[ $total_size -gt 0 ]]; then
        ratio=$(echo "scale=2; 1 - ($compressed_size / $total_size)" | bc 2>/dev/null || echo "0")
    fi
    
    # Use sed to update the stats section (macOS compatible)
    sed -i '' "s/\"compressed_size_bytes\": 0/\"compressed_size_bytes\": $compressed_size/" "$manifest_file"
    sed -i '' "s/\"compression_ratio\": 0/\"compression_ratio\": $ratio/" "$manifest_file"
    sed -i '' "s/\"duration_seconds\": 0/\"duration_seconds\": $duration/" "$manifest_file"
    
    log_debug "Updated manifest stats: compressed=$compressed_size ratio=$ratio duration=${duration}s"
}

# ===============================================
# Compression & Archiving
# ===============================================

# Create compressed archive from file list
# Args: $1 - backup_path, remaining args - files
create_archive() {
    local backup_path="$1"
    shift
    local -a files=("$@")
    local archive_file="${backup_path}/backup.tar.gz"
    local file_list="${backup_path}/.file_list.txt"
    
    # Create file list
    printf "%s\n" "${files[@]}" > "$file_list"
    
    log_info "Creating compressed archive..."
    local start_time
    start_time=$(date +%s)
    
    # Check if pigz (parallel gzip) is available
    local compress_cmd="gzip"
    if command -v pigz &>/dev/null; then
        compress_cmd="pigz"
        log_debug "Using pigz for parallel compression"
    fi
    
    # Create archive with progress
    # Note: We're using -czf for simplicity, but could optimize with pigz
    if tar -czf "$archive_file" -T "$file_list" 2>/dev/null; then
        local end_time
        end_time=$(date +%s)
        local duration=$((end_time - start_time))
        
        local archive_size
        archive_size=$(stat -f%z "$archive_file" 2>/dev/null || stat -c%s "$archive_file")
        
        log_success "Archive created: $(bytes_to_human $archive_size)"
        
        # Clean up temp file list
        rm -f "$file_list"
        
        # Update manifest with stats
        update_manifest_stats "$backup_path" "$archive_size" "$duration"
        
        chmod 600 "$archive_file"
        return 0
    else
        log_error "Failed to create archive"
        rm -f "$file_list"
        return 1
    fi
}

# ===============================================
# Checksum & Verification
# ===============================================

# Generate checksum for archive
# Args: $1 - backup_path
generate_checksum() {
    local backup_path="$1"
    local archive_file="${backup_path}/backup.tar.gz"
    local checksum_file="${backup_path}/checksum.sha256"
    
    if [[ ! -f "$archive_file" ]]; then
        log_error "Archive not found: $archive_file"
        return 1
    fi
    
    log_info "Generating checksum..."
    
    if command -v sha256sum &>/dev/null; then
        (cd "$backup_path" && sha256sum backup.tar.gz > checksum.sha256)
    elif command -v shasum &>/dev/null; then
        (cd "$backup_path" && shasum -a 256 backup.tar.gz > checksum.sha256)
    else
        log_warninging "No checksum tool available, skipping checksum generation"
        return 1
    fi
    
    chmod 600 "$checksum_file"
    log_debug "Checksum generated: $checksum_file"
    return 0
}

# Verify archive checksum
# Args: $1 - backup_path
verify_checksum() {
    local backup_path="$1"
    local checksum_file="${backup_path}/checksum.sha256"
    
    if [[ ! -f "$checksum_file" ]]; then
        log_warning "No checksum file found"
        return 1
    fi
    
    log_info "Verifying archive integrity..."
    
    if command -v sha256sum &>/dev/null; then
        (cd "$backup_path" && sha256sum -c checksum.sha256 &>/dev/null)
    elif command -v shasum &>/dev/null; then
        (cd "$backup_path" && shasum -a 256 -c checksum.sha256 &>/dev/null)
    else
        log_warning "No checksum tool available, skipping verification"
        return 1
    fi
    
    local result=$?
    
    if [[ $result -eq 0 ]]; then
        log_success "Checksum verification passed"
        return 0
    else
        log_error "Checksum verification failed"
        log_warning "Backup may be corrupted"
        return 1
    fi
}

# ===============================================
# Main Backup Function
# ===============================================

# Create a backup of files
# Args: remaining args - files to backup
create_backup() {
    local -a files_to_backup=("$@")
    
    # Initialize backup system
    init_backup_system || return 1
    
    # Check for concurrent backup
    if is_backup_in_progress; then
        log_error "Another backup is already in progress"
        log_info "Please wait for it to complete or cancel it"
        return 1
    fi
    
    # Create lock
    create_backup_lock
    trap remove_backup_lock EXIT
    
    # Check if there are files to backup
    if [[ ${#files_to_backup[@]} -eq 0 ]]; then
        log_warning "No files to backup"
        remove_backup_lock
        return 0
    fi
    
    # Calculate total size
    log_info "Analyzing files to backup..."
    local total_size=0
    for file in "${files_to_backup[@]}"; do
        if [[ -e "$file" ]]; then
            local size
            size=$(get_directory_size_bytes "$file")
            total_size=$((total_size + size))
        fi
    done
    
    log_info "Total size to backup: $(bytes_to_human $total_size)"
    
    # Check disk space
    check_sufficient_space "$total_size" || {
        remove_backup_lock
        return 1
    }
    
    # Generate backup ID
    local backup_id
    backup_id=$(generate_backup_id)
    local backup_path
    backup_path=$(get_backup_path "$backup_id")
    
    # Create backup directory
    mkdir -p "$backup_path" || {
        log_error "Failed to create backup directory: $backup_path"
        remove_backup_lock
        return 1
    }
    chmod 700 "$backup_path"
    
    log_info "Creating backup: $backup_id"
    
    # Create manifest
    create_manifest "$backup_id" "$backup_path" "${files_to_backup[@]}" || {
        log_error "Failed to create manifest"
        rm -rf "$backup_path"
        remove_backup_lock
        return 1
    }
    
    # Create archive
    create_archive "$backup_path" "${files_to_backup[@]}" || {
        log_error "Failed to create archive"
        rm -rf "$backup_path"
        remove_backup_lock
        return 1
    }
    
    # Generate checksum
    generate_checksum "$backup_path" || {
        log_warning "Checksum generation failed, but backup is complete"
    }
    
    # Verify backup
    verify_checksum "$backup_path" || {
        log_warning "Backup verification failed"
        echo ""
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Backup cancelled"
            rm -rf "$backup_path"
            remove_backup_lock
            return 1
        fi
    }
    
    # Success
    log_success "Backup created successfully: $backup_id"
    log_info "Backup location: $backup_path"
    
    # Auto-cleanup old backups if enabled
    if [[ "$DEFAULT_AUTO_CLEANUP" == true ]]; then
        log_debug "Running auto-cleanup..."
        auto_cleanup_backups
    fi
    
    remove_backup_lock
    return 0
}

# ===============================================
# Listing Backups
# ===============================================

# List all available backups
list_backups() {
    init_backup_system || return 1
    
    local backups=()
    
    # Find all backup directories
    if [[ -d "$BACKUP_DIR" ]]; then
        while IFS= read -r -d '' backup_path; do
            local backup_id
            backup_id=$(basename "$backup_path")
            backups+=("$backup_id")
        done < <(find "$BACKUP_DIR" -mindepth 1 -maxdepth 1 -type d -print0 | sort -z -r)
    fi
    
    if [[ ${#backups[@]} -eq 0 ]]; then
        log_info "No backups found"
        return 0
    fi
    
    echo ""
    log_info "Available backups:"
    echo ""
    
    for backup_id in "${backups[@]}"; do
        local backup_path
        backup_path=$(get_backup_path "$backup_id")
        local manifest_file="${backup_path}/manifest.json"
        
        if [[ -f "$manifest_file" ]]; then
            # Parse manifest (simplified)
            local created_at
            created_at=$(grep -o '"created_at": "[^"]*"' "$manifest_file" | cut -d'"' -f4)
            
            local total_size
            total_size=$(grep -o '"total_size_bytes": [0-9]*' "$manifest_file" | awk '{print $2}')
            
            local file_count
            file_count=$(grep -o '"file_count": [0-9]*' "$manifest_file" | awk '{print $2}')
            
            echo "  ${CYAN}${backup_id}${NC}"
            echo "    Created: ${created_at}"
            echo "    Size: $(bytes_to_human ${total_size:-0})"
            echo "    Files: ${file_count:-0}"
            echo ""
        else
            echo "  ${YELLOW}${backup_id}${NC} (no manifest)"
            echo ""
        fi
    done
    
    return 0
}

# ===============================================
# Restore Functions
# ===============================================

# Restore from backup
# Args: $1 - backup_id
restore_backup() {
    local backup_id="$1"
    
    if [[ -z "$backup_id" ]]; then
        log_error "Backup ID required"
        return 1
    fi
    
    local backup_path
    backup_path=$(get_backup_path "$backup_id")
    
    if [[ ! -d "$backup_path" ]]; then
        log_error "Backup not found: $backup_id"
        return 1
    fi
    
    local archive_file="${backup_path}/backup.tar.gz"
    
    if [[ ! -f "$archive_file" ]]; then
        log_error "Archive not found: $archive_file"
        return 1
    fi
    
    # Verify checksum
    if ! verify_checksum "$backup_path"; then
        echo ""
        read -p "Backup may be corrupted. Continue restore? (y/N): " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Restore cancelled"
            return 1
        fi
    fi
    
    # Confirm restore
    echo ""
    log_warning "This will restore files from backup: $backup_id"
    log_warning "Existing files may be overwritten"
    echo ""
    read -p "Continue with restore? (y/N): " -n 1 -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Restore cancelled"
        return 0
    fi
    
    # Extract archive
    log_info "Restoring from backup..."
    
    if tar -xzf "$archive_file" -C / 2>/dev/null; then
        log_success "Restore completed successfully"
        
        # Ask to delete backup
        echo ""
        read -p "Delete this backup? (y/N): " -n 1 -r
        echo ""
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf "$backup_path"
            log_success "Backup deleted"
        fi
        
        return 0
    else
        log_error "Failed to restore from backup"
        return 1
    fi
}

# ===============================================
# Auto-Cleanup Functions
# ===============================================

# Auto-cleanup old backups based on retention policy
auto_cleanup_backups() {
    local backups=()
    
    # Find all backup directories
    if [[ -d "$BACKUP_DIR" ]]; then
        while IFS= read -r -d '' backup_path; do
            backups+=("$backup_path")
        done < <(find "$BACKUP_DIR" -mindepth 1 -maxdepth 1 -type d -print0)
    fi
    
    if [[ ${#backups[@]} -eq 0 ]]; then
        return 0
    fi
    
    # Age-based cleanup
    local now
    now=$(date +%s)
    local max_age_seconds=$((DEFAULT_MAX_AGE_DAYS * 86400))
    
    for backup_path in "${backups[@]}"; do
        local manifest_file="${backup_path}/manifest.json"
        
        if [[ -f "$manifest_file" ]]; then
            local created_at
            created_at=$(grep -o '"created_at": "[^"]*"' "$manifest_file" | cut -d'"' -f4)
            
            local created_timestamp
            created_timestamp=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$created_at" +%s 2>/dev/null || echo "0")
            
            local age=$((now - created_timestamp))
            
            if [[ $age -gt $max_age_seconds ]]; then
                local backup_id
                backup_id=$(basename "$backup_path")
                log_debug "Removing expired backup: $backup_id (age: $((age / 86400)) days)"
                rm -rf "$backup_path"
            fi
        fi
    done
    
    # Count-based cleanup (keep only newest N backups)
    local remaining_backups=()
    if [[ -d "$BACKUP_DIR" ]]; then
        while IFS= read -r -d '' backup_path; do
            remaining_backups+=("$backup_path")
        done < <(find "$BACKUP_DIR" -mindepth 1 -maxdepth 1 -type d -print0 | sort -z -r)
    fi
    
    local count=${#remaining_backups[@]}
    if [[ $count -gt $DEFAULT_MAX_COUNT ]]; then
        local excess=$((count - DEFAULT_MAX_COUNT))
        log_debug "Removing $excess excess backups (keeping newest $DEFAULT_MAX_COUNT)"
        
        for ((i=DEFAULT_MAX_COUNT; i<count; i++)); do
            rm -rf "${remaining_backups[$i]}"
        done
    fi
}

# Manual cleanup command
cleanup_backups() {
    init_backup_system || return 1
    
    log_info "Cleaning up old backups..."
    auto_cleanup_backups
    log_success "Backup cleanup complete"
}

# ===============================================
# Exports
# ===============================================

# Export main functions
export -f init_backup_system
export -f create_backup
export -f list_backups
export -f restore_backup
export -f cleanup_backups
