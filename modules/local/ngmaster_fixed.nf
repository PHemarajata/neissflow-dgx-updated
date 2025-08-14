nextflow.enable.dsl=2

process NGMASTER_FIXED {
    tag "$sample_name"
    label 'process_low'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/ngmaster:1.0.0--pyhdfd78af_0' :
        'staphb/ngmaster:1.0.0' }"

    input:
    tuple val(sample_name), path(assembly)

    output:
    tuple val(sample_name), path("${sample_name}/${sample_name}_ngmaster.tsv"), emit: ngmaster_report
    path "versions.yml"                                                       , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    if [ ! -d ${sample_name} ]; then
        mkdir ${sample_name}
    fi

    # Create a Python wrapper to handle KeyError gracefully
    cat > ngmaster_wrapper.py << 'EOF'
#!/usr/bin/env python3
import sys
import subprocess
import os

def run_ngmaster_safe(db_path, assembly_file):
    try:
        # Try to run ngmaster normally
        result = subprocess.run(['ngmaster', '--db', db_path, assembly_file], 
                              capture_output=True, text=True, check=True)
        return result.stdout, None
    except subprocess.CalledProcessError as e:
        if 'KeyError' in e.stderr:
            # Handle KeyError by creating fallback output
            print(f"KeyError detected in ngmaster: {e.stderr}", file=sys.stderr)
            print("Creating fallback output with unknown values", file=sys.stderr)
            
            # Create fallback output
            fallback_output = f"FILE\\tSCHEME\\tST\\tporB\\ttbpB\\tpenA\\tgyrA\\tparC\\t23S\\tmtrR\\n"
            fallback_output += f"{assembly_file}\\tngmast/ngstar\\t-/-\\t-\\t-\\t-\\t-\\t-\\t-\\t-\\n"
            return fallback_output, "KeyError handled"
        else:
            # Re-raise if it's not a KeyError
            raise e

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: ngmaster_wrapper.py <db_path> <assembly_file>", file=sys.stderr)
        sys.exit(1)
    
    db_path = sys.argv[1]
    assembly_file = sys.argv[2]
    
    output, error = run_ngmaster_safe(db_path, assembly_file)
    print(output, end='')
    
    if error:
        print(f"Warning: {error}", file=sys.stderr)
EOF

    chmod +x ngmaster_wrapper.py

    # Run the wrapper instead of ngmaster directly
    python3 ngmaster_wrapper.py ${params.ngmasterdb} $assembly > ngmaster.tsv

    # Post process ngmaster output to get around other bugs in their tool
    ngmaster_postprocess.sh ngmaster.tsv ${params.ngstar} ${params.ngmast}

    awk -v name=$sample_name 'OFS="\t" { if( NR==1 ){ s="Sample" }else{ s=name }; split(\$3,st,"/"); print s,\$2,st[1],st[2],\$4,\$5,\$6,\$7,\$8,\$9,\$10,\$11,\$12 }' ngmaster_postprocessed.tsv > ${sample_name}/${sample_name}_ngmaster.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        ngmaster: \$( echo \$(ngmaster --version 2>&1) | sed 's/^.*ngmaster //' )
    END_VERSIONS
    """
}