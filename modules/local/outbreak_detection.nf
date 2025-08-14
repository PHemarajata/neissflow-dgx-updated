process OUTBREAK_DETECTION {
    label 'process_single'

    container "https://depot.galaxyproject.org/singularity/numpy%3A2.2.2"

    input:
    path(snp_matrix)

    output:
    path("isolate_clusters.txt"), emit: outbreaks
    path "versions.yml"         , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: "-i ${snp_matrix} -d ${params.snp_dist}"

    """
    # Disable Numba caching to prevent container issues
    export NUMBA_CACHE_DIR=/tmp
    export NUMBA_DISABLE_JIT=0
    export NUMBA_DISABLE_CACHING=1
    export NUMBA_DISABLE_INTEL_SVML=1
    export NUMBA_DISABLE_HSA=1
    export NUMBA_DISABLE_CUDA=1

    outbreak_detection.py \\
        $args > isolate_clusters.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        Python: \$(python --version 2>/dev/null | sed 's/Python //;' || echo "unknown")
    END_VERSIONS

    """
}