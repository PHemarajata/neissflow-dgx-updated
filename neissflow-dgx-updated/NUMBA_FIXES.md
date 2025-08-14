# GUBBINS Numba Caching Fixes

## Problem
The GUBBINS process was failing with the following error:
```
RuntimeError: cannot cache function 'seq_to_int': no locator available for file '/usr/local/lib/python3.9/site-packages/gubbins/pyjar.py'
```

This is a common issue with Numba (a Python JIT compiler) in containerized environments where the caching mechanism cannot locate the source files properly.

## Comprehensive Solution Applied

### 1. Global Environment Variables (nextflow.config)
Added global environment variables that apply to all processes:
```groovy
env {
    NUMBA_CACHE_DIR = '/tmp'
    NUMBA_DISABLE_JIT = '0'
    NUMBA_DISABLE_CACHING = '1'
    NUMBA_DISABLE_INTEL_SVML = '1'
    NUMBA_DISABLE_HSA = '1'
    NUMBA_DISABLE_CUDA = '1'
}
```

### 2. Process-Level Container Options (modules/local/gubbins.nf)
Added container-specific environment variables:
```groovy
containerOptions = workflow.containerEngine == 'singularity' ? 
    '--env NUMBA_DISABLE_CACHING=1 --env NUMBA_CACHE_DIR=/tmp --env NUMBA_DISABLE_INTEL_SVML=1' : 
    '-e NUMBA_DISABLE_CACHING=1 -e NUMBA_CACHE_DIR=/tmp -e NUMBA_DISABLE_INTEL_SVML=1'
```

### 3. Script-Level Environment Variables
Added comprehensive environment variable exports in the script section:
```bash
export NUMBA_CACHE_DIR=/tmp
export NUMBA_DISABLE_JIT=0
export NUMBA_DISABLE_CACHING=1
export NUMBA_DISABLE_INTEL_SVML=1
export NUMBA_DISABLE_HSA=1
export NUMBA_DISABLE_CUDA=1
export NUMBA_DISABLE_TBB=1
export NUMBA_THREADING_LAYER=workqueue
export NUMBA_DISABLE_PERFORMANCE_WARNINGS=1
```

### 4. Wrapper Script (bin/run_gubbins_wrapper.py)
Created a Python wrapper script that:
- Sets up the Numba environment programmatically
- Provides fallback mechanisms
- Handles errors gracefully
- Can be used as an alternative to direct GUBBINS calls

### 5. Additional Modules Fixed
Applied similar fixes to other Python-based modules that might encounter similar issues:
- `modules/local/outbreak_detection.nf`
- `modules/local/variant_analysis.nf`

## Environment Variables Explained

- `NUMBA_DISABLE_CACHING=1`: Completely disables Numba's caching mechanism
- `NUMBA_CACHE_DIR=/tmp`: Sets cache directory to a writable location
- `NUMBA_DISABLE_JIT=0`: Keeps JIT compilation enabled (for performance)
- `NUMBA_DISABLE_INTEL_SVML=1`: Disables Intel SVML which can cause issues
- `NUMBA_DISABLE_HSA=1`: Disables HSA (Heterogeneous System Architecture)
- `NUMBA_DISABLE_CUDA=1`: Disables CUDA support
- `NUMBA_DISABLE_TBB=1`: Disables Intel TBB threading
- `NUMBA_THREADING_LAYER=workqueue`: Sets a safe threading layer
- `NUMBA_DISABLE_PERFORMANCE_WARNINGS=1`: Suppresses performance warnings

## Result
The GUBBINS process should now run successfully without the Numba caching error. The fixes are applied at multiple levels to ensure maximum compatibility across different container engines and execution environments.

## Testing
The pipeline has been tested and parses correctly with all fixes in place. The GUBBINS process should now execute without the RuntimeError.