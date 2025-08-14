#!/bin/bash

# Cleanup script for neissflow work directory
# This script helps free up disk space by cleaning temporary files

set -euo pipefail

WORK_DIR="${1:-work}"
DRY_RUN="${2:-false}"

echo "Neissflow Work Directory Cleanup"
echo "================================"
echo "Work directory: $WORK_DIR"
echo "Dry run: $DRY_RUN"
echo ""

if [ ! -d "$WORK_DIR" ]; then
    echo "❌ Work directory $WORK_DIR does not exist"
    exit 1
fi

# Function to safely remove files/directories
safe_remove() {
    local target="$1"
    local description="$2"
    
    if [ -e "$target" ]; then
        local size=$(du -sh "$target" 2>/dev/null | cut -f1 || echo "unknown")
        echo "🗑️  $description: $size"
        
        if [ "$DRY_RUN" = "false" ]; then
            rm -rf "$target"
            echo "   ✅ Removed"
        else
            echo "   🔍 Would remove (dry run)"
        fi
    fi
}

echo "Scanning for temporary files to clean up..."
echo ""

# Clean up Shovill temporary directories
echo "Cleaning Shovill temporary files:"
find "$WORK_DIR" -name "shovill_tmp_*" -type d 2>/dev/null | while read -r dir; do
    safe_remove "$dir" "Shovill temp dir: $(basename "$dir")"
done

# Clean up SPAdes temporary files
echo ""
echo "Cleaning SPAdes temporary files:"
find "$WORK_DIR" -name "spades_tmp" -type d 2>/dev/null | while read -r dir; do
    safe_remove "$dir" "SPAdes temp dir: $(basename "$dir")"
done

# Clean up general temporary files
echo ""
echo "Cleaning general temporary files:"
find "$WORK_DIR" -name "*.tmp" -type f 2>/dev/null | while read -r file; do
    safe_remove "$file" "Temp file: $(basename "$file")"
done

find "$WORK_DIR" -name "*.temp" -type f 2>/dev/null | while read -r file; do
    safe_remove "$file" "Temp file: $(basename "$file")"
done

echo ""
echo "✅ Cleanup completed!"