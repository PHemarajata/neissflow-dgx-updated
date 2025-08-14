# Container Management for neissflow

This document describes how to manage containers effectively when running neissflow with Singularity.

## Common Container Issues

### Problem: Repeated Container Pulling
If you notice that the workflow keeps pulling the same Singularity images (like shovill and snippy) repeatedly without starting jobs, this is typically caused by:

1. **Simultaneous container pulls**: Multiple processes trying to pull the same container at once
2. **Cache conflicts**: Singularity cache directory conflicts
3. **Network timeouts**: Container pulling timing out without proper retry mechanisms

## Solutions

### 1. Use the Enhanced Singularity Profile

The pipeline now includes an enhanced singularity configuration that addresses these issues:

```bash
nextflow run main.nf -profile singularity [other options]
```

The enhanced profile includes:
- **Staggered container pulls**: Random delays to prevent simultaneous pulls
- **Dedicated cache directories**: Process-specific cache locations
- **Enhanced retry logic**: Better error handling for container issues
- **Timeout settings**: Proper timeouts for container operations

### 2. Pre-pull Containers (Recommended)

Before running the pipeline, pre-pull all required containers:

```bash
# Pre-pull all containers
./bin/pull_containers.sh

# Then run the pipeline
nextflow run main.nf -profile singularity [other options]
```

This approach:
- Downloads all containers before workflow execution
- Prevents simultaneous pulling during the workflow
- Provides better error reporting for container issues
- Reduces workflow startup time

### 3. Manual Container Management

If you prefer manual control, you can pull specific problematic containers:

```bash
# Create cache directory
mkdir -p ~/.singularity/cache
export SINGULARITY_CACHEDIR=~/.singularity/cache

# Pull problematic containers manually
singularity pull https://depot.galaxyproject.org/singularity/shovill:1.1.0--hdfd78af_1
singularity pull https://depot.galaxyproject.org/singularity/snippy:4.6.0--hdfd78af_2
```

### 4. Troubleshooting Container Issues

If you continue to experience container pulling issues:

1. **Check disk space**: Ensure sufficient space in your home directory and temp directories
2. **Check network connectivity**: Verify access to depot.galaxyproject.org
3. **Clear cache**: Remove and recreate the singularity cache directory
4. **Use resume**: If the workflow fails, use `-resume` to continue from where it stopped

```bash
# Clear cache and restart
rm -rf ~/.singularity/cache
mkdir -p ~/.singularity/cache

# Resume failed workflow
nextflow run main.nf -profile singularity -resume [other options]
```

## Configuration Details

### Enhanced Singularity Settings

The enhanced singularity profile (`conf/singularity.config`) includes:

```groovy
singularity {
    enabled     = true
    autoMounts  = true
    cacheDir    = "${HOME}/.singularity/cache"
    pullTimeout = '30 min'
    runOptions  = '--cleanenv --containall'
}

process {
    // Staggered container operations
    beforeScript = '''
        sleep $((RANDOM % 60 + 10))
        export SINGULARITY_CACHEDIR="${HOME}/.singularity/cache"
        mkdir -p "$SINGULARITY_CACHEDIR"
    '''
    
    // Enhanced error handling
    errorStrategy = { 
        if (task.exitStatus in [125,126,127]) {
            return 'retry'  // Container errors
        } else if (task.exitStatus in [143,137,104,134,139,140,71,255]) {
            return 'retry'  // System errors
        } else {
            return 'finish'
        }
    }
    maxRetries = 3
}
```

### Process-Specific Settings

Special handling for problematic processes:

- **SHOVILL**: Extended delays and dedicated cache directory
- **SNIPPY**: Extended delays and dedicated cache directory
- **Reduced concurrency**: Limited concurrent jobs to prevent conflicts

## Best Practices

1. **Always pre-pull containers** before running large workflows
2. **Use dedicated cache directories** for different workflows
3. **Monitor disk space** in cache and temp directories
4. **Use resume functionality** when workflows fail
5. **Check logs** for specific container error messages

## Environment Variables

Key environment variables for container management:

```bash
export SINGULARITY_CACHEDIR="${HOME}/.singularity/cache"
export TMPDIR="/tmp"
export NXF_SINGULARITY_CACHEDIR="${HOME}/.singularity/cache"
```

## Support

If you continue to experience container issues after following these guidelines, please:

1. Check the `.nextflow.log` file for specific error messages
2. Verify your Singularity installation and version
3. Test container pulling manually outside of Nextflow
4. Consider using Docker instead of Singularity if available