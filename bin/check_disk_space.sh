#!/bin/bash

# Disk space checker for neissflow
# This script checks if there's sufficient disk space for running the pipeline

set -euo pipefail

# Default minimum space requirements (in GB)
MIN_WORK_SPACE=${1:-50}    # Minimum space in work directory
MIN_OUTPUT_SPACE=${2:-20}  # Minimum space in output directory
MIN_TMP_SPACE=${3:-30}     # Minimum space in temp directory

echo "Checking disk space requirements for neissflow..."
echo "================================================="

# Function to check disk space
check_space() {
    local dir="$1"
    local min_space="$2"
    local description="$3"
    
    if [ ! -d "$dir" ]; then
        echo "⚠️  Directory $dir does not exist"
        return 1
    fi
    
    local available_space=$(df -BG "$dir" | awk 'NR==2 {print $4}' | sed 's/G//')
    echo -n "📁 $description ($dir): ${available_space}GB available"
    
    if [ "$available_space" -ge "$min_space" ]; then
        echo " ✅ (>= ${min_space}GB required)"
        return 0
    else
        echo " ❌ (< ${min_space}GB required)"
        return 1
    fi
}

# Check current working directory
echo ""
echo "Checking current working directory..."
if ! check_space "$(pwd)" "$MIN_WORK_SPACE" "Current directory"; then
    WORK_FAIL=1
else
    WORK_FAIL=0
fi

# Check temp directory
echo ""
echo "Checking temporary directory..."
TMPDIR="${TMPDIR:-/tmp}"
if ! check_space "$TMPDIR" "$MIN_TMP_SPACE" "Temp directory"; then
    TMP_FAIL=1
else
    TMP_FAIL=0
fi

# Check home directory (for singularity cache)
echo ""
echo "Checking home directory (for container cache)..."
if ! check_space "$HOME" "10" "Home directory"; then
    HOME_FAIL=1
else
    HOME_FAIL=0
fi

# Summary
echo ""
echo "Summary:"
echo "========"

if [ $WORK_FAIL -eq 0 ] && [ $TMP_FAIL -eq 0 ] && [ $HOME_FAIL -eq 0 ]; then
    echo "✅ All disk space checks passed!"
    echo ""
    echo "You can proceed with running the pipeline."
    exit 0
else
    echo "❌ Some disk space checks failed!"
    echo ""
    echo "Recommendations:"
    
    if [ $WORK_FAIL -eq 1 ]; then
        echo "• Free up space in your working directory or run from a location with more space"
        echo "• Consider using a different work directory with: nextflow run -w /path/to/work/dir"
    fi
    
    if [ $TMP_FAIL -eq 1 ]; then
        echo "• Free up space in $TMPDIR"
        echo "• Set TMPDIR to a location with more space: export TMPDIR=/path/to/tmp"
    fi
    
    if [ $HOME_FAIL -eq 1 ]; then
        echo "• Free up space in your home directory"
        echo "• Consider setting a different singularity cache: export SINGULARITY_CACHEDIR=/path/to/cache"
    fi
    
    echo ""
    echo "Assembly processes (like Shovill) require significant temporary disk space."
    echo "SPAdes can use 2-3x the size of your input data in temporary files."
    exit 1
fi