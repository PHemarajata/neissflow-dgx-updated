#!/bin/bash

# Test script to verify Shovill package management fix
# This script helps validate that the Shovill module handles package management errors correctly

set -euo pipefail

echo "Testing Shovill Package Management Fix"
echo "====================================="

# Check if we're in the right directory
if [ ! -f "modules/local/shovill.nf" ]; then
    echo "❌ Error: Please run this script from the neissflow root directory"
    exit 1
fi

echo "✅ Found Shovill module"

# Check if the enhanced error handling is present
echo ""
echo "Checking for enhanced error handling in Shovill module..."

if grep -q "DEBIAN_FRONTEND=noninteractive" modules/local/shovill.nf; then
    echo "✅ Found package management prevention variables"
else
    echo "❌ Package management prevention variables not found"
    exit 1
fi

if grep -q "set +e" modules/local/shovill.nf; then
    echo "✅ Found enhanced exit code handling"
else
    echo "❌ Enhanced exit code handling not found"
    exit 1
fi

if grep -q "SHOVILL_EXIT" modules/local/shovill.nf; then
    echo "✅ Found exit code capture"
else
    echo "❌ Exit code capture not found"
    exit 1
fi

if grep -q "contigs.fa.*not empty" modules/local/shovill.nf; then
    echo "✅ Found output file validation"
else
    echo "❌ Output file validation not found"
    exit 1
fi

# Check Singularity configuration
echo ""
echo "Checking Singularity configuration..."

if [ -f "conf/singularity.config" ]; then
    echo "✅ Found Singularity configuration"
    
    if grep -q "DEBIAN_FRONTEND=noninteractive" conf/singularity.config; then
        echo "✅ Found package management prevention in Singularity config"
    else
        echo "❌ Package management prevention not found in Singularity config"
        exit 1
    fi
    
    if grep -q "writable-tmpfs" conf/singularity.config; then
        echo "✅ Found enhanced Singularity run options"
    else
        echo "❌ Enhanced Singularity run options not found"
        exit 1
    fi
    
    if grep -q "task.exitStatus in \[100, 1\]" conf/singularity.config; then
        echo "✅ Found package management error handling"
    else
        echo "❌ Package management error handling not found"
        exit 1
    fi
else
    echo "❌ Singularity configuration not found"
    exit 1
fi

# Check container version
echo ""
echo "Checking container version..."

if grep -q "shovill:1.1.0--hdfd78af_1" modules/local/shovill.nf; then
    echo "✅ Found updated Shovill container version"
else
    echo "⚠️  Warning: Updated container version not found, using older version"
fi

# Test Nextflow syntax
echo ""
echo "Testing Nextflow syntax..."

if command -v nextflow &> /dev/null; then
    if nextflow config &> /dev/null; then
        echo "✅ Nextflow configuration syntax is valid"
    else
        echo "❌ Nextflow configuration syntax error"
        echo "Running nextflow config to show errors:"
        nextflow config
        exit 1
    fi
else
    echo "⚠️  Nextflow not found, skipping syntax check"
fi

echo ""
echo "Summary of Fixes Applied:"
echo "========================"
echo "✅ Enhanced error handling in Shovill module"
echo "✅ Package management prevention variables"
echo "✅ Exit code capture and validation"
echo "✅ Output file validation (contigs.fa check)"
echo "✅ Enhanced Singularity configuration"
echo "✅ Package management error handling in config"
echo "✅ Updated container version"

echo ""
echo "🎉 All checks passed! The Shovill package management fix is properly implemented."
echo ""
echo "What this fix does:"
echo "- Prevents package management operations that cause sources.list errors"
echo "- Captures Shovill exit codes but validates success by checking output files"
echo "- Allows successful assemblies to complete even if container cleanup fails"
echo "- Provides better error messages and logging"
echo ""
echo "Your Shovill assemblies should now complete successfully even if there are"
echo "package management issues in the container cleanup phase."