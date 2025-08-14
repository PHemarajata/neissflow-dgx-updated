# SNIPPY Troubleshooting Guide

## Common SNIPPY Errors and Solutions

### 1. snpEff Database Build Failure (Exit Status 2)

**Error Symptoms:**
```
ERROR: Database check failed.
ERROR: CDS check file not found.
ERROR: Protein check file not found.
WARNING_FRAMES_ZERO: All frames are zero!
```

**Solution:** 
The `--noref` flag has been added to SNIPPY commands to skip the problematic snpEff annotation step.

**If you still encounter this error:**
1. Ensure you're using the updated modules with `--noref` flag
2. Check that your reference file (FA19.gb) is accessible and properly formatted
3. Verify sufficient disk space in the work directory

### 2. Container Issues (Exit Status 127)

**Error Symptoms:**
```
snippy: command not found
```

**Solution:**
Ensure you're using a profile that enables containers (like `dgx_a100` or `singularity`).

### 3. Memory/Resource Issues

**Error Symptoms:**
- Process killed unexpectedly
- Out of memory errors
- Disk space errors

**Solutions:**
1. **Memory**: Increase memory allocation in your profile
2. **Disk Space**: Ensure sufficient space in work directory (at least 10GB per sample)
3. **CPU**: Adjust CPU allocation if needed

### 4. Reference File Issues

**Error Symptoms:**
```
Can't locate reference file
Invalid reference format
```

**Solutions:**
1. Check that `assets_dir` parameter points to correct location
2. Verify FA19.gb file exists and is readable
3. Ensure file permissions are correct

### 5. Input File Issues

**Error Symptoms:**
```
Can't locate input files
Invalid FASTQ format
```

**Solutions:**
1. Verify FASTQ files exist and are properly named
2. Check file permissions
3. Ensure FASTQ files are gzipped (.fastq.gz or .fq.gz)

## Debugging Steps

### 1. Check Work Directory
```bash
# Navigate to the failed task work directory
cd /path/to/work/directory/from/error

# Check what files are present
ls -la

# Check the command that was run
cat .command.sh

# Check the full log
cat .command.log
```

### 2. Test SNIPPY Manually
```bash
# Enter the work directory
cd /path/to/work/directory

# Run the command manually to see detailed output
bash .command.run
```

### 3. Check Container
```bash
# Test if container works
singularity exec docker://staphb/snippy:4.6.0 snippy --version

# Or with Docker
docker run --rm staphb/snippy:4.6.0 snippy --version
```

### 4. Check Resources
```bash
# Check available disk space
df -h

# Check memory usage
free -h

# Check CPU usage
top
```

## Recovery Options

### 1. Resume Pipeline
If you've fixed the issue, you can resume the pipeline:
```bash
nextflow run main.nf -profile dgx_a100 --input samplesheet.csv --outdir results --only_fastq -resume
```

### 2. Skip Failed Samples
If specific samples are problematic, you can create a new samplesheet excluding them.

### 3. Adjust Resources
Modify the profile configuration to allocate more resources if needed.

## Prevention

### 1. Pre-flight Checks
- Verify all input files exist and are readable
- Check available disk space (recommend 50GB+ free)
- Test container access
- Validate samplesheet format

### 2. Resource Planning
- Plan for ~5-10GB disk space per sample
- Allocate sufficient memory (8GB+ per process)
- Ensure adequate CPU resources

### 3. File Management
- Use absolute paths for input files
- Ensure consistent file naming
- Verify file permissions

## Getting Help

If you continue to experience issues:

1. **Check the error logs** in the work directory
2. **Review the troubleshooting steps** above
3. **Check disk space and resources**
4. **Verify input file formats and paths**
5. **Test container functionality**

The `--noref` fix should resolve the most common SNIPPY failure mode related to snpEff database building.