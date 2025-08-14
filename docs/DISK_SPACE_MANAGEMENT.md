# Disk Space Management for neissflow

This document addresses disk space issues that can occur during neissflow execution, particularly with assembly processes like Shovill/SPAdes.

## Common Disk Space Error

### Error Message:
```
[spades] ERROR General (kmer_splitters.hpp : 145) I/O error! Incomplete write! Reason: No space left on device. Error code: 28
```

### Root Cause:
SPAdes (used by Shovill for assembly) requires significant temporary disk space during assembly. The error occurs when:
- Work directory runs out of space
- Temporary directory (`/tmp` or `$TMPDIR`) is full
- Multiple concurrent assemblies consume all available space
- Large input files require more space than available

## Solutions Implemented

### 1. Enhanced Shovill Module
The Shovill module now includes:
- **Pre-flight disk space checks**: Verifies at least 20GB available before starting
- **Dedicated temporary directories**: Uses sample-specific temp dirs to avoid conflicts
- **Real-time monitoring**: Monitors disk space during assembly
- **Automatic cleanup**: Removes temporary files on completion or failure
- **Better error handling**: Specific handling for "No space left" errors

### 2. Improved Configuration
- **Assembly-specific label**: `process_assembly` with enhanced resources
- **Retry strategy**: Automatic retry on disk space errors (exit code 28)
- **Increased resources**: More memory and time for assembly processes
- **Staggered execution**: Prevents multiple assemblies from running simultaneously

### 3. Disk Space Monitoring Tools

#### Check Available Space
```bash
# Check if you have sufficient disk space before running
./bin/check_disk_space.sh

# Check with custom requirements (work_space, output_space, tmp_space in GB)
./bin/check_disk_space.sh 100 50 50
```

#### Clean Up Work Directory
```bash
# Preview what would be cleaned (dry run)
./bin/cleanup_work_dir.sh work true

# Actually clean up temporary files
./bin/cleanup_work_dir.sh work false
```

## Disk Space Requirements

### Minimum Requirements:
- **Work directory**: 50GB (recommended 100GB for multiple samples)
- **Temporary directory**: 30GB
- **Output directory**: 20GB
- **Home directory**: 10GB (for container cache)

### Per-Sample Requirements:
- **Small genomes (2-5MB)**: ~5-10GB temporary space
- **Large genomes or high coverage**: ~20-50GB temporary space
- **Multiple samples**: Multiply by number of concurrent assemblies

## Best Practices

### 1. Pre-Run Checks
```bash
# Always check disk space before running
./bin/check_disk_space.sh

# Check current space usage
df -h .
du -sh work/
```

### 2. Configure Appropriate Temporary Directories
```bash
# Use a directory with plenty of space for temporary files
export TMPDIR=/path/to/large/tmp/directory

# Or specify when running Nextflow
nextflow run main.nf -w /path/to/large/work/dir
```

### 3. Monitor During Execution
```bash
# Monitor disk space in real-time
watch -n 30 'df -h .'

# Monitor work directory size
watch -n 60 'du -sh work/'
```

### 4. Cleanup Strategies
```bash
# Clean up during long runs if space gets low
./bin/cleanup_work_dir.sh work false

# Use Nextflow's built-in cleanup (removes intermediate files)
nextflow run main.nf -resume -with-dag flowchart.html
```

## Configuration Options

### New Parameters:
- `--min_disk_space`: Minimum disk space required (default: 20GB)

### Usage:
```bash
nextflow run main.nf \
  --min_disk_space 50 \
  --input samplesheet.csv \
  --outdir results
```

## Troubleshooting

### If Assembly Fails with Disk Space Error:

1. **Check available space**:
   ```bash
   df -h .
   ./bin/check_disk_space.sh
   ```

2. **Clean up temporary files**:
   ```bash
   ./bin/cleanup_work_dir.sh work false
   ```

3. **Use a different work directory**:
   ```bash
   nextflow run main.nf -w /path/to/larger/work/dir
   ```

4. **Set a larger temporary directory**:
   ```bash
   export TMPDIR=/path/to/large/tmp
   nextflow run main.nf
   ```

5. **Resume with cleanup**:
   ```bash
   # Clean up and resume
   ./bin/cleanup_work_dir.sh work false
   nextflow run main.nf -resume
   ```

### If Multiple Samples Fail:

1. **Reduce concurrent assemblies**:
   ```bash
   # Limit concurrent processes
   nextflow run main.nf -process.executor.queueSize=2
   ```

2. **Use process-specific work directories**:
   ```bash
   # The enhanced configuration automatically handles this
   nextflow run main.nf -profile singularity
   ```

3. **Stagger sample processing**:
   ```bash
   # Process samples in smaller batches
   # Split your samplesheet into smaller files
   ```

## Monitoring Commands

### Real-time Monitoring:
```bash
# Monitor overall disk usage
watch -n 30 'df -h'

# Monitor work directory
watch -n 60 'du -sh work/ && find work/ -name "shovill_tmp_*" | wc -l'

# Monitor temporary directories
watch -n 30 'du -sh /tmp /var/tmp'
```

### Log Analysis:
```bash
# Check for disk space errors in logs
grep -r "No space left" .nextflow.log* work/

# Check Shovill logs for space issues
find work/ -name "shovill.log" -exec grep -l "space\|error" {} \;
```

## Prevention Strategies

1. **Always run disk space check before starting**
2. **Use dedicated work directories on large filesystems**
3. **Monitor disk usage during long runs**
4. **Clean up temporary files regularly**
5. **Consider processing samples in smaller batches**
6. **Use the enhanced singularity profile for better resource management**

## Emergency Cleanup

If you run out of space during a run:

```bash
# Emergency cleanup (be careful!)
find work/ -name "*.tmp" -delete
find work/ -name "*.temp" -delete
find work/ -name "shovill_tmp_*" -type d -exec rm -rf {} +

# Clean up failed assembly directories
find work/ -name "spades_tmp" -type d -exec rm -rf {} +
```

Remember: The enhanced Shovill module now handles most of these issues automatically, but understanding disk space management is crucial for successful pipeline execution.