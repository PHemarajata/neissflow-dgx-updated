# DGX A100 Profile Container Fix

## Issue
The pipeline was failing with the error:
```
ERROR ~ Error executing process > 'NFCORE_NEISSFLOW:NEISSFLOW:SNIPPY (ERR9668844)'
Caused by:
  Process `NFCORE_NEISSFLOW:NEISSFLOW:SNIPPY (ERR9668844)` terminated with an error exit status (127)
Command error:
  .command.sh: line 9: snippy: command not found
```

## Root Cause
The `dgx_a100` profile was configured to use the `local` executor without any container engine specified. This meant:

1. Processes tried to run directly on the host system
2. Required bioinformatics tools (like `snippy`) were not installed on the host
3. The SNIPPY module expects to run in a container with the `snippy` tool installed
4. Result: "command not found" errors

## Solution Applied
Modified the `dgx_a100` profile in `nextflow.config` to include Singularity container support:

### Before:
```groovy
dgx_a100 {
  params { ... }
  process {
    executor = 'local'
    // ... resource configurations
  }
}
```

### After:
```groovy
dgx_a100 {
  params { ... }
  
  // Enable Singularity for containerized execution
  singularity {
    enabled    = true
    autoMounts = true
    cacheDir   = "${HOME}/.singularity/cache"
    runOptions = '--cleanenv --containall'
  }
  
  process {
    executor = 'local'
    // ... resource configurations
  }
}
```

## What This Fix Does
1. **Enables Singularity**: Allows the pipeline to use containerized execution
2. **Auto-mounts**: Automatically mounts necessary directories
3. **Cache Directory**: Stores containers in `${HOME}/.singularity/cache` for reuse
4. **Clean Environment**: Uses `--cleanenv --containall` for better isolation
5. **Maintains Local Execution**: Still uses the `local` executor for high performance on DGX A100

## Usage
Now you can run the pipeline with the `dgx_a100` profile and it will properly use containers:

```bash
nextflow run main.nf -profile dgx_a100 --input your_samplesheet.csv --outdir results --only_fastq
```

## Prerequisites
- Singularity must be installed on the DGX A100 system
- Internet access for downloading containers (first run)
- Sufficient disk space in `${HOME}/.singularity/cache` for container storage

## Benefits
- **Tool Availability**: All required bioinformatics tools are available in containers
- **Reproducibility**: Consistent software versions across runs
- **Performance**: Local executor provides maximum performance on DGX A100
- **Isolation**: Clean container environment prevents conflicts