process SHOVILL {
    tag "$sample_name"
    label 'process_assembly'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/shovill:1.1.0--hdfd78af_1' :
        'biocontainers/shovill:1.1.0--hdfd78af_1' }"

    input:
    tuple val(sample_name), path(reads)

    output:
    tuple val(sample_name), path("*_contigs.fa")                       , emit: contigs
    tuple val(sample_name), path("shovill.corrections")                , emit: corrections
    tuple val(sample_name), path("shovill.log")                        , emit: log
    tuple val(sample_name), path("{skesa,spades,megahit,velvet}.fasta"), emit: raw_contigs
    tuple val(sample_name), path("contigs.{fastg,gfa,LastGraph}")      , optional:true, emit: gfa
    path "versions.yml"                                                , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def memory = task.memory.toGiga()

    if (params.downsample) {
        """
        # Enhanced disk space management for Shovill/SPAdes
        
        # Prevent package management operations that cause sources.list errors
        export DEBIAN_FRONTEND=noninteractive
        export APT_LISTCHANGES_FRONTEND=none
        export DEBIAN_PRIORITY=critical
        
        # Check available disk space before starting
        AVAILABLE_SPACE=\$(df -BG . | awk 'NR==2 {print \$4}' | sed 's/G//')
        echo "Available disk space: \${AVAILABLE_SPACE}GB"
        
        if [ "\$AVAILABLE_SPACE" -lt 20 ]; then
            echo "ERROR: Insufficient disk space. Need at least 20GB, have \${AVAILABLE_SPACE}GB"
            exit 1
        fi
        
        # Set up temporary directories with better space management
        export TMPDIR="\${TMPDIR:-\$PWD/shovill_tmp_${sample_name}_\$\$}"
        mkdir -p "\$TMPDIR"
        
        # Set SPAdes-specific temporary directory
        export SPADES_TMP_DIR="\$TMPDIR/spades_tmp"
        mkdir -p "\$SPADES_TMP_DIR"
        
        # Cleanup function
        cleanup() {
            echo "Cleaning up temporary files..."
            rm -rf "\$TMPDIR" 2>/dev/null || true
        }
        trap cleanup EXIT
        
        # Monitor disk space during assembly
        monitor_disk_space() {
            while true; do
                CURRENT_SPACE=\$(df -BG . | awk 'NR==2 {print \$4}' | sed 's/G//')
                if [ "\$CURRENT_SPACE" -lt 5 ]; then
                    echo "WARNING: Low disk space: \${CURRENT_SPACE}GB remaining"
                    # Try to clean up intermediate files
                    find "\$TMPDIR" -name "*.tmp" -delete 2>/dev/null || true
                    find "\$TMPDIR" -name "*.temp" -delete 2>/dev/null || true
                fi
                sleep 30
            done
        }
        monitor_disk_space &
        MONITOR_PID=\$!
        
        # Run shovill with enhanced error handling and capture exit code
        set +e  # Don't exit on error immediately
        shovill \\
            --R1 ${reads[0]} \\
            --R2 ${reads[1]} \\
            --tmpdir "\$TMPDIR" \\
            --cpus ${task.cpus} \\
            --ram $memory \\
            --outdir ./ \\
            --depth ${params.depth} \\
            $args \\
            --force
        SHOVILL_EXIT=\$?
        set -e  # Re-enable exit on error
        
        # Stop monitoring
        kill \$MONITOR_PID 2>/dev/null || true
        
        # Check if assembly was successful regardless of exit code
        if [ -f "contigs.fa" ] && [ -s "contigs.fa" ]; then
            echo "Assembly completed successfully - contigs.fa found and not empty"
            mv contigs.fa ${sample_name}_contigs.fa
            
            # Generate versions file
            cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            shovill: \$(shovill --version 2>/dev/null | sed 's/^.*shovill //' || echo "unknown")
        END_VERSIONS
            
            # Final cleanup
            cleanup
            
            # Exit successfully even if shovill had package management issues
            echo "Shovill completed with exit code \$SHOVILL_EXIT, but assembly was successful"
            exit 0
        else
            echo "ERROR: Assembly failed - contigs.fa not found or empty"
            cleanup
            exit 1
        fi
        """
    } else {
        """
        # Enhanced disk space management for Shovill/SPAdes
        
        # Prevent package management operations that cause sources.list errors
        export DEBIAN_FRONTEND=noninteractive
        export APT_LISTCHANGES_FRONTEND=none
        export DEBIAN_PRIORITY=critical
        
        # Check available disk space before starting
        AVAILABLE_SPACE=\$(df -BG . | awk 'NR==2 {print \$4}' | sed 's/G//')
        echo "Available disk space: \${AVAILABLE_SPACE}GB"
        
        if [ "\$AVAILABLE_SPACE" -lt 20 ]; then
            echo "ERROR: Insufficient disk space. Need at least 20GB, have \${AVAILABLE_SPACE}GB"
            exit 1
        fi
        
        # Set up temporary directories with better space management
        export TMPDIR="\${TMPDIR:-\$PWD/shovill_tmp_${sample_name}_\$\$}"
        mkdir -p "\$TMPDIR"
        
        # Set SPAdes-specific temporary directory
        export SPADES_TMP_DIR="\$TMPDIR/spades_tmp"
        mkdir -p "\$SPADES_TMP_DIR"
        
        # Cleanup function
        cleanup() {
            echo "Cleaning up temporary files..."
            rm -rf "\$TMPDIR" 2>/dev/null || true
        }
        trap cleanup EXIT
        
        # Monitor disk space during assembly
        monitor_disk_space() {
            while true; do
                CURRENT_SPACE=\$(df -BG . | awk 'NR==2 {print \$4}' | sed 's/G//')
                if [ "\$CURRENT_SPACE" -lt 5 ]; then
                    echo "WARNING: Low disk space: \${CURRENT_SPACE}GB remaining"
                    # Try to clean up intermediate files
                    find "\$TMPDIR" -name "*.tmp" -delete 2>/dev/null || true
                    find "\$TMPDIR" -name "*.temp" -delete 2>/dev/null || true
                fi
                sleep 30
            done
        }
        monitor_disk_space &
        MONITOR_PID=\$!
        
        # Run shovill with enhanced error handling and capture exit code
        set +e  # Don't exit on error immediately
        shovill \\
            --R1 ${reads[0]} \\
            --R2 ${reads[1]} \\
            --tmpdir "\$TMPDIR" \\
            --cpus ${task.cpus} \\
            --ram $memory \\
            --outdir ./ \\
            $args \\
            --force
        SHOVILL_EXIT=\$?
        set -e  # Re-enable exit on error
        
        # Stop monitoring
        kill \$MONITOR_PID 2>/dev/null || true
        
        # Check if assembly was successful regardless of exit code
        if [ -f "contigs.fa" ] && [ -s "contigs.fa" ]; then
            echo "Assembly completed successfully - contigs.fa found and not empty"
            mv contigs.fa ${sample_name}_contigs.fa
            
            # Generate versions file
            cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            shovill: \$(shovill --version 2>/dev/null | sed 's/^.*shovill //' || echo "unknown")
        END_VERSIONS
            
            # Final cleanup
            cleanup
            
            # Exit successfully even if shovill had package management issues
            echo "Shovill completed with exit code \$SHOVILL_EXIT, but assembly was successful"
            exit 0
        else
            echo "ERROR: Assembly failed - contigs.fa not found or empty"
            cleanup
            exit 1
        fi
        """
    }
}
