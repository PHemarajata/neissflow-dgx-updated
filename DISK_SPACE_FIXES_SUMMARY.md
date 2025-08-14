# Disk Space Issue Fixes Summary

## Problem Description
Shovill assembly was failing with the error:
```
[spades] ERROR General (kmer_splitters.hpp : 145) I/O error! Incomplete write! Reason: No space left on device. Error code: 28
```

This occurs when SPAdes (used by Shovill) runs out of disk space during assembly operations.

## Root Causes Identified
1. **Insufficient disk space** in work directory during assembly
2. **Temporary directory space exhaustion** (`/tmp` or `$TMPDIR`)
3. **Multiple concurrent assemblies** consuming all available space
4. **Large intermediate files** from SPAdes assembly process
5. **Lack of cleanup** of temporary files during/after assembly

## Solutions Implemented

### 1. Enhanced Shovill Module (`modules/local/shovill.nf`)
**Key Improvements:**
- **Pre-flight disk space check**: Verifies ≥20GB available before starting
- **Dedicated temporary directories**: Sample-specific temp dirs (`shovill_tmp_${sample_name}_$$`)
- **Real-time disk monitoring**: Background process monitors space during assembly
- **Automatic cleanup**: Removes temp files on completion/failure with trap handlers
- **Enhanced error handling**: Better error messages and exit codes
- **Space-aware intermediate cleanup**: Removes `.tmp` and `.temp` files when space is low

**Code Changes:**
```bash
# Pre-flight check
AVAILABLE_SPACE=$(df -BG . | awk 'NR==2 {print $4}' | sed 's/G//')
if [ "$AVAILABLE_SPACE" -lt 20 ]; then
    echo "ERROR: Insufficient disk space. Need at least 20GB, have ${AVAILABLE_SPACE}GB"
    exit 1
fi

# Dedicated temp directories
export TMPDIR="${TMPDIR:-$PWD/shovill_tmp_${sample_name}_$$}"
export SPADES_TMP_DIR="$TMPDIR/spades_tmp"

# Cleanup trap
cleanup() {
    echo "Cleaning up temporary files..."
    rm -rf "$TMPDIR" 2>/dev/null || true
}
trap cleanup EXIT
```

### 2. Enhanced Configuration Files

#### Base Configuration (`conf/base.config`)
- **Added exit code 28 handling**: Specific retry strategy for "No space left" errors
- **New assembly label**: `process_assembly` with enhanced resources
- **Increased resources**: 64GB memory, 12h time limit, 16 CPUs for assembly

#### Singularity Configuration (`conf/singularity.config`)
- **Enhanced Shovill settings**: Better temp directory management
- **Disk space monitoring**: Pre-run space checks in beforeScript
- **Cleanup on exit**: Automatic cleanup of work temp directories
- **Retry strategy**: Specific retry for exit code 28 (disk space errors)

#### Main Configuration (`nextflow.config`)
- **New parameter**: `min_disk_space = 20` (configurable minimum space requirement)

### 3. Disk Space Management Tools

#### Disk Space Checker (`bin/check_disk_space.sh`)
**Features:**
- Checks work directory, temp directory, and home directory space
- Configurable minimum space requirements
- Clear pass/fail reporting with recommendations
- Usage: `./bin/check_disk_space.sh [work_min] [output_min] [tmp_min]`

#### Cleanup Script (`bin/cleanup_work_dir.sh`)
**Features:**
- Safely removes temporary files from work directory
- Dry-run mode for preview
- Targets Shovill/SPAdes temp files specifically
- Usage: `./bin/cleanup_work_dir.sh work [true|false]`

### 4. Comprehensive Documentation
- **Disk Space Management Guide** (`docs/DISK_SPACE_MANAGEMENT.md`)
- **Updated README** with disk space section
- **Troubleshooting procedures** and best practices

## Key Features of the Solution

### Proactive Space Management
```bash
# Check before assembly starts
AVAILABLE_SPACE=$(df -BG . | awk 'NR==2 {print $4}' | sed 's/G//')
if [ "$AVAILABLE_SPACE" -lt 20 ]; then
    exit 1
fi
```

### Real-time Monitoring
```bash
# Background monitoring during assembly
monitor_disk_space() {
    while true; do
        CURRENT_SPACE=$(df -BG . | awk 'NR==2 {print $4}' | sed 's/G//')
        if [ "$CURRENT_SPACE" -lt 5 ]; then
            echo "WARNING: Low disk space: ${CURRENT_SPACE}GB remaining"
            # Clean up intermediate files
            find "$TMPDIR" -name "*.tmp" -delete 2>/dev/null || true
        fi
        sleep 30
    done
}
```

### Automatic Cleanup
```bash
# Cleanup function with trap
cleanup() {
    echo "Cleaning up temporary files..."
    rm -rf "$TMPDIR" 2>/dev/null || true
}
trap cleanup EXIT
```

### Enhanced Error Handling
```groovy
// Retry on disk space errors
errorStrategy = { task.exitStatus == 28 ? 'retry' : 'finish' }
maxRetries = 3
```

## Usage Instructions

### Before Running Pipeline
```bash
# Check disk space
./bin/check_disk_space.sh

# If insufficient space, clean up
./bin/cleanup_work_dir.sh work false
```

### Running with Enhanced Settings
```bash
# Use enhanced singularity profile (recommended)
nextflow run main.nf -profile singularity --input samplesheet.csv --outdir results

# With custom minimum space requirement
nextflow run main.nf --min_disk_space 50 --input samplesheet.csv --outdir results

# With custom work directory
nextflow run main.nf -w /path/to/large/work/dir --input samplesheet.csv --outdir results
```

### During Pipeline Execution
```bash
# Monitor disk space
watch -n 30 'df -h .'

# Emergency cleanup if needed
./bin/cleanup_work_dir.sh work false
```

## Expected Improvements
- ✅ **Eliminated "No space left" errors**: Pre-flight checks prevent starting with insufficient space
- ✅ **Better resource utilization**: Dedicated temp directories prevent conflicts
- ✅ **Automatic recovery**: Retry mechanism for transient space issues
- ✅ **Proactive monitoring**: Real-time space monitoring during assembly
- ✅ **Cleaner execution**: Automatic cleanup prevents space accumulation
- ✅ **Better diagnostics**: Clear error messages and space reporting

## Files Modified/Added

### Modified Files:
- `modules/local/shovill.nf` - Enhanced with disk space management
- `conf/base.config` - Added assembly label and error handling
- `conf/singularity.config` - Enhanced Shovill-specific settings
- `nextflow.config` - Added min_disk_space parameter
- `README.md` - Added disk space management section

### New Files:
- `bin/check_disk_space.sh` - Disk space checker tool
- `bin/cleanup_work_dir.sh` - Work directory cleanup tool
- `docs/DISK_SPACE_MANAGEMENT.md` - Comprehensive documentation
- `DISK_SPACE_FIXES_SUMMARY.md` - This summary

## Monitoring and Troubleshooting

### Check Pipeline Status
```bash
# Check for disk space errors in logs
grep -r "No space left" .nextflow.log*

# Monitor work directory size
du -sh work/

# Check for temporary directories
find work/ -name "shovill_tmp_*" -type d
```

### Emergency Procedures
```bash
# If pipeline fails with space error:
1. ./bin/cleanup_work_dir.sh work false
2. df -h .  # Check available space
3. nextflow run main.nf -resume  # Resume pipeline
```

These comprehensive changes should resolve the disk space issues with Shovill/SPAdes assembly while providing tools and monitoring to prevent future occurrences.