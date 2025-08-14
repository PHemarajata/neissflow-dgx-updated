# Container Management Fixes Summary

This document summarizes the fixes implemented to resolve the issue where the neissflow workflow keeps pulling Singularity images for shovill and snippy repeatedly without starting jobs.

## Problem Description
- Workflow repeatedly pulls the same Singularity containers (shovill, snippy, etc.)
- Jobs associated with those containers don't start unless workflow is aborted and resumed
- Multiple copies of images are downloaded unnecessarily
- Workflow gets stuck in container pulling phase

## Root Causes Identified
1. **Simultaneous container pulls**: Multiple processes trying to pull the same container at once
2. **Cache conflicts**: Singularity cache directory conflicts between processes
3. **Network timeouts**: Container pulling timing out without proper retry mechanisms
4. **Lack of proper error handling**: Container-related errors not properly handled

## Solutions Implemented

### 1. Enhanced Singularity Configuration (`conf/singularity.config`)
- **Dedicated cache directories**: Process-specific cache locations to prevent conflicts
- **Staggered container pulls**: Random delays (10-90 seconds) to prevent simultaneous pulls
- **Extended timeouts**: 30-minute timeout for container pulls
- **Enhanced retry logic**: Better error handling for container-related issues (exit codes 125, 126, 127)
- **Reduced concurrency**: Limited concurrent jobs to prevent container conflicts

### 2. Process-Specific Settings
- **SHOVILL process**: Extended delays (30-120 seconds) and dedicated cache directory
- **SNIPPY process**: Extended delays (45-135 seconds) and dedicated cache directory
- **Enhanced error handling**: Up to 5 retries for problematic processes

### 3. Container Pre-pulling Script (`bin/pull_containers.sh`)
- **Pre-download all containers**: Downloads all required containers before workflow execution
- **Retry mechanism**: Automatic retry with exponential backoff for failed pulls
- **Progress reporting**: Clear feedback on container pulling status
- **Error handling**: Detailed error reporting for failed container pulls

### 4. Container Setup Checker (`bin/check_container_setup.sh`)
- **System validation**: Checks Singularity installation and configuration
- **Cache inspection**: Verifies existing cached containers
- **Network connectivity**: Tests connection to container registry
- **Disk space monitoring**: Checks available space for containers
- **Recommendations**: Provides specific guidance based on system state

### 5. Updated Main Configuration (`nextflow.config`)
- **Improved singularity profile**: References the new enhanced configuration
- **Better error handling**: Enhanced error strategies in base configuration
- **Container-specific error codes**: Proper handling of container-related exit codes

### 6. Documentation
- **Container Management Guide** (`docs/CONTAINER_MANAGEMENT.md`): Comprehensive troubleshooting guide
- **Updated README**: Added container management section with quick start instructions
- **Best practices**: Detailed recommendations for container usage

## Key Features of the Solution

### Staggered Container Operations
```bash
# Random delays to prevent simultaneous pulls
sleep $((RANDOM % 60 + 10))

# Process-specific delays for problematic containers
# SHOVILL: 30-120 second delay
# SNIPPY: 45-135 second delay
```

### Dedicated Cache Directories
```bash
export SINGULARITY_CACHEDIR="${HOME}/.singularity/cache/shovill"
export SINGULARITY_CACHEDIR="${HOME}/.singularity/cache/snippy"
```

### Enhanced Error Handling
```groovy
errorStrategy = { 
    if (task.exitStatus in [125,126,127]) {
        return 'retry'  // Container errors
    } else if (task.exitStatus in [143,137,104,134,139,140,71,255]) {
        return 'retry'  // System errors
    } else {
        return 'finish'
    }
}
```

### Container Pre-pulling
```bash
# Pre-pull all containers before running pipeline
./bin/pull_containers.sh

# Then run pipeline without container pulling delays
nextflow run main.nf -profile singularity [options]
```

## Usage Instructions

### Recommended Workflow
1. **Check system setup**:
   ```bash
   ./bin/check_container_setup.sh
   ```

2. **Pre-pull containers** (recommended):
   ```bash
   ./bin/pull_containers.sh
   ```

3. **Run pipeline**:
   ```bash
   nextflow run main.nf -profile singularity [other options]
   ```

### Alternative: Direct Run with Enhanced Profile
```bash
nextflow run main.nf -profile singularity [other options]
```
The enhanced profile will automatically handle container management.

## Expected Improvements
- **Eliminated repeated container pulls**: Each container pulled only once
- **Faster workflow startup**: Pre-pulled containers start immediately
- **Better error recovery**: Automatic retry for container-related failures
- **Reduced resource usage**: No duplicate container downloads
- **More reliable execution**: Staggered operations prevent conflicts

## Monitoring and Troubleshooting
- **Check logs**: Look for container-related error messages in `.nextflow.log`
- **Monitor cache**: Check `~/.singularity/cache` for downloaded containers
- **Use resume**: If workflow fails, use `-resume` to continue from checkpoint
- **Clear cache**: If issues persist, clear and recreate singularity cache

## Files Modified/Added
- `conf/singularity.config` (new)
- `bin/pull_containers.sh` (new)
- `bin/check_container_setup.sh` (new)
- `docs/CONTAINER_MANAGEMENT.md` (new)
- `nextflow.config` (modified)
- `conf/base.config` (modified)
- `README.md` (modified)

These changes should resolve the container pulling issues and provide a much more reliable experience when running neissflow with Singularity containers.