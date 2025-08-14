/*
 * GUBBINS process with Numba caching fixes
 * 
 * This process includes comprehensive fixes for the Numba caching issue:
 * RuntimeError: cannot cache function 'seq_to_int': no locator available for file
 * 
 * The fixes include:
 * 1. Global environment variables in nextflow.config
 * 2. Process-level container options
 * 3. Script-level environment variable exports
 * 4. Optional wrapper script for additional robustness
 */
process GUBBINS {
    label 'process_high'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/gubbins%3A3.3.5--py39pl5321he4a0461_0' :
        'quay.io/biocontainers/gubbins:3.3.5--py39pl5321he4a0461_0' }"
    
    // Additional environment variables for Numba in containers
    containerOptions = workflow.containerEngine == 'singularity' ? 
        '--env NUMBA_DISABLE_CACHING=1 --env NUMBA_CACHE_DIR=/tmp --env NUMBA_DISABLE_INTEL_SVML=1' : 
        '-e NUMBA_DISABLE_CACHING=1 -e NUMBA_CACHE_DIR=/tmp -e NUMBA_DISABLE_INTEL_SVML=1'

    input:
    path(clean_full_aln)

    output:
    path '*.filtered_polymorphic_sites.phylip', emit: phylip
    path '*.filtered_polymorphic_sites.fasta' , emit: fasta
    path '*.recombination_predictions.gff'    , emit: gff
    path '*.recombination_predictions.embl'   , emit: pred_embl
    path '*.branch_base_reconstruction.embl'  , emit: base_recon_embl
    path '*.summary_of_snp_distribution.vcf'  , emit: vcf 
    path '*.final_tree.tre'                   , emit: tre
    path '*.node_labelled.final_tree.tre'     , emit: node_tre
    //path '*.log'                              , emit: log
    path '*.per_branch_statistics.csv'        , emit: csv
    path "versions.yml"                       , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    # Disable Numba caching to prevent container issues
    export NUMBA_CACHE_DIR=/tmp
    export NUMBA_DISABLE_JIT=0
    export NUMBA_DISABLE_CACHING=1
    export NUMBA_DISABLE_INTEL_SVML=1
    export NUMBA_DISABLE_HSA=1
    export NUMBA_DISABLE_CUDA=1
    export NUMBA_DISABLE_TBB=1
    export NUMBA_THREADING_LAYER=workqueue
    export NUMBA_DISABLE_PERFORMANCE_WARNINGS=1
    
    file=$clean_full_aln
    name=\${file%%.clean.full.aln}
    
    # Try using the wrapper script first, fallback to direct call
    if command -v run_gubbins_wrapper.py >/dev/null 2>&1; then
        run_gubbins_wrapper.py -c ${task.cpus} -i ${params.max_itr} -u -p \$name -t raxml $clean_full_aln
    else
        run_gubbins.py -c ${task.cpus} -i ${params.max_itr} -u -p \$name -t raxml $clean_full_aln
    fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gubbins: \$(run_gubbins.py --version 2>/dev/null || echo "unknown")
    END_VERSIONS

    """
}