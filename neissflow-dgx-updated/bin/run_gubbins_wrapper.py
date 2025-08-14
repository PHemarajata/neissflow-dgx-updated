#!/usr/bin/env python3
"""
Wrapper script for GUBBINS to handle Numba caching issues in containers.
This script sets up the environment properly before calling GUBBINS.
"""

import os
import sys
import subprocess
import tempfile

def setup_numba_environment():
    """Set up environment variables to prevent Numba caching issues."""
    # Disable Numba caching completely
    os.environ['NUMBA_DISABLE_CACHING'] = '1'
    os.environ['NUMBA_CACHE_DIR'] = tempfile.gettempdir()
    
    # Disable JIT compilation if needed (set to 0 to keep JIT enabled but disable caching)
    os.environ['NUMBA_DISABLE_JIT'] = '0'
    
    # Disable specific Numba features that can cause issues in containers
    os.environ['NUMBA_DISABLE_INTEL_SVML'] = '1'
    os.environ['NUMBA_DISABLE_HSA'] = '1'
    os.environ['NUMBA_DISABLE_CUDA'] = '1'
    os.environ['NUMBA_DISABLE_TBB'] = '1'
    
    # Set threading layer to avoid conflicts
    os.environ['NUMBA_THREADING_LAYER'] = 'workqueue'
    
    # Disable warnings that might interfere
    os.environ['NUMBA_DISABLE_PERFORMANCE_WARNINGS'] = '1'

def run_gubbins(args):
    """Run GUBBINS with the provided arguments."""
    try:
        # Set up the environment
        setup_numba_environment()
        
        # Prepare the command
        cmd = ['run_gubbins.py'] + args
        
        # Run GUBBINS
        result = subprocess.run(cmd, check=True, capture_output=False)
        return result.returncode
        
    except subprocess.CalledProcessError as e:
        print(f"GUBBINS failed with exit code {e.returncode}", file=sys.stderr)
        return e.returncode
    except Exception as e:
        print(f"Error running GUBBINS: {e}", file=sys.stderr)
        return 1

if __name__ == "__main__":
    # Pass all arguments to GUBBINS
    exit_code = run_gubbins(sys.argv[1:])
    sys.exit(exit_code)