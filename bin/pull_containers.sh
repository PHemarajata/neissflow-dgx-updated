#!/bin/bash

# Container pre-pulling script for neissflow
# This script pulls all required containers before running the pipeline
# to avoid simultaneous pulling issues during workflow execution

set -euo pipefail

# Set up singularity cache directory
SINGULARITY_CACHEDIR="${HOME}/.singularity/cache"
mkdir -p "$SINGULARITY_CACHEDIR"
export SINGULARITY_CACHEDIR

echo "Pre-pulling containers for neissflow pipeline..."
echo "Cache directory: $SINGULARITY_CACHEDIR"

# Function to pull container with retry
pull_container() {
    local container_url="$1"
    local container_name="$2"
    local max_attempts=3
    local attempt=1
    
    echo "Pulling $container_name..."
    
    while [ $attempt -le $max_attempts ]; do
        echo "  Attempt $attempt/$max_attempts"
        
        if singularity pull --force "$container_url" 2>/dev/null; then
            echo "  ✓ Successfully pulled $container_name"
            return 0
        else
            echo "  ✗ Failed to pull $container_name (attempt $attempt)"
            if [ $attempt -eq $max_attempts ]; then
                echo "  ✗ Failed to pull $container_name after $max_attempts attempts"
                return 1
            fi
            sleep $((attempt * 10))  # Exponential backoff
        fi
        
        ((attempt++))
    done
}

# List of containers used in the pipeline
declare -A containers=(
    ["shovill"]="https://depot.galaxyproject.org/singularity/shovill:1.1.0--hdfd78af_1"
    ["snippy"]="https://depot.galaxyproject.org/singularity/snippy:4.6.0--hdfd78af_2"
    ["fastqc"]="https://depot.galaxyproject.org/singularity/fastqc:0.12.1--hdfd78af_0"
    ["multiqc"]="https://depot.galaxyproject.org/singularity/multiqc:1.19--pyhdfd78af_0"
    ["fastp"]="https://depot.galaxyproject.org/singularity/fastp:0.23.4--h5f740d0_0"
    ["quast"]="https://depot.galaxyproject.org/singularity/quast:5.2.0--py39pl5321h2add14b_1"
    ["mash"]="https://depot.galaxyproject.org/singularity/mash:2.3--he348c14_1"
    ["blast"]="https://depot.galaxyproject.org/singularity/blast:2.15.0--pl5321h6f7f691_1"
    ["mlst"]="https://depot.galaxyproject.org/singularity/mlst:2.23.0--hdfd78af_0"
    ["gubbins"]="https://depot.galaxyproject.org/singularity/gubbins:3.3.5--py39h4e691d4_0"
    ["iqtree"]="https://depot.galaxyproject.org/singularity/iqtree:2.2.2.6--h9f5acd7_0"
    ["snp-dists"]="https://depot.galaxyproject.org/singularity/snp-dists:0.8.2--h5bf99c6_0"
)

# Pull containers
failed_containers=()
successful_containers=()

for container_name in "${!containers[@]}"; do
    container_url="${containers[$container_name]}"
    
    if pull_container "$container_url" "$container_name"; then
        successful_containers+=("$container_name")
    else
        failed_containers+=("$container_name")
    fi
    
    # Small delay between pulls
    sleep 5
done

# Summary
echo ""
echo "Container pulling summary:"
echo "========================="
echo "Successfully pulled: ${#successful_containers[@]} containers"
for container in "${successful_containers[@]}"; do
    echo "  ✓ $container"
done

if [ ${#failed_containers[@]} -gt 0 ]; then
    echo ""
    echo "Failed to pull: ${#failed_containers[@]} containers"
    for container in "${failed_containers[@]}"; do
        echo "  ✗ $container"
    done
    echo ""
    echo "You may need to pull these containers manually or check your network connection."
    exit 1
else
    echo ""
    echo "All containers successfully pulled!"
    echo "You can now run the pipeline with -profile singularity"
fi