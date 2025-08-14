#!/bin/bash

# Container setup checker for neissflow
# This script checks if your system is properly configured for running neissflow with Singularity

set -euo pipefail

echo "Checking neissflow container setup..."
echo "====================================="

# Check if Singularity is installed
echo -n "Checking Singularity installation... "
if command -v singularity &> /dev/null; then
    SINGULARITY_VERSION=$(singularity --version)
    echo "✓ Found: $SINGULARITY_VERSION"
else
    echo "✗ Singularity not found"
    echo "Please install Singularity before running the pipeline with containers."
    exit 1
fi

# Check Singularity cache directory
CACHE_DIR="${HOME}/.singularity/cache"
echo -n "Checking Singularity cache directory... "
if [ -d "$CACHE_DIR" ]; then
    CACHE_SIZE=$(du -sh "$CACHE_DIR" 2>/dev/null | cut -f1 || echo "unknown")
    echo "✓ Found: $CACHE_DIR (size: $CACHE_SIZE)"
else
    echo "! Not found, will be created automatically"
    mkdir -p "$CACHE_DIR"
    echo "✓ Created: $CACHE_DIR"
fi

# Check available disk space
echo -n "Checking available disk space... "
AVAILABLE_SPACE=$(df -h "$HOME" | awk 'NR==2 {print $4}')
echo "✓ Available in home directory: $AVAILABLE_SPACE"

# Check if containers are already cached
echo ""
echo "Checking cached containers:"
echo "---------------------------"

declare -A containers=(
    ["shovill"]="shovill_1.1.0--hdfd78af_1.sif"
    ["snippy"]="snippy_4.6.0--hdfd78af_2.sif"
    ["fastqc"]="fastqc_0.12.1--hdfd78af_0.sif"
    ["multiqc"]="multiqc_1.19--pyhdfd78af_0.sif"
    ["fastp"]="fastp_0.23.4--h5f740d0_0.sif"
)

cached_count=0
total_count=${#containers[@]}

for container_name in "${!containers[@]}"; do
    container_file="${containers[$container_name]}"
    echo -n "  $container_name... "
    
    # Look for the container file in cache directory
    if find "$CACHE_DIR" -name "*${container_name}*" -type f | grep -q .; then
        echo "✓ Cached"
        ((cached_count++))
    else
        echo "✗ Not cached"
    fi
done

echo ""
echo "Container cache summary: $cached_count/$total_count containers cached"

# Check network connectivity
echo ""
echo -n "Checking network connectivity to container registry... "
if curl -s --head "https://depot.galaxyproject.org" > /dev/null; then
    echo "✓ Connected"
else
    echo "✗ Cannot connect to depot.galaxyproject.org"
    echo "  This may cause issues when pulling containers."
fi

# Check temporary directory
echo -n "Checking temporary directory... "
TMPDIR="${TMPDIR:-/tmp}"
if [ -d "$TMPDIR" ] && [ -w "$TMPDIR" ]; then
    TEMP_SPACE=$(df -h "$TMPDIR" | awk 'NR==2 {print $4}')
    echo "✓ $TMPDIR (available: $TEMP_SPACE)"
else
    echo "✗ $TMPDIR not accessible"
fi

# Recommendations
echo ""
echo "Recommendations:"
echo "================"

if [ $cached_count -eq 0 ]; then
    echo "📦 Run './bin/pull_containers.sh' to pre-pull all containers"
elif [ $cached_count -lt $total_count ]; then
    echo "📦 Consider running './bin/pull_containers.sh' to update container cache"
else
    echo "✅ All main containers are cached - you're ready to run!"
fi

echo "🔧 Use '-profile singularity' when running the pipeline"
echo "📚 See docs/CONTAINER_MANAGEMENT.md for detailed troubleshooting"

# Test a simple container pull
echo ""
echo -n "Testing container pull capability... "
TEST_CONTAINER="https://depot.galaxyproject.org/singularity/ubuntu:20.04"
if timeout 60 singularity pull --force /tmp/test_container.sif "$TEST_CONTAINER" &>/dev/null; then
    echo "✓ Container pull test successful"
    rm -f /tmp/test_container.sif
else
    echo "✗ Container pull test failed"
    echo "  This may indicate network issues or Singularity configuration problems."
fi

echo ""
echo "Setup check complete!"