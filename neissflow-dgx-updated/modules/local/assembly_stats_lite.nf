process ASSEMBLY_STATS_LITE {
    tag "$meta.id"
    label 'process_low'

    container "https://depot.galaxyproject.org/singularity/centos:7.9.2009"

    input:
    tuple val(meta), path(assembly)

    output:
    tuple val(meta), path("${prefix}_assembly_stats.tsv"), emit: stats
    path "versions.yml"                                  , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    # Calculate assembly statistics using basic Unix tools
    python3 << 'EOF'
import sys
from collections import defaultdict

def calculate_assembly_stats(fasta_file):
    sequences = []
    current_seq = ""
    
    with open(fasta_file, 'r') as f:
        for line in f:
            line = line.strip()
            if line.startswith('>'):
                if current_seq:
                    sequences.append(len(current_seq))
                current_seq = ""
            else:
                current_seq += line
        if current_seq:
            sequences.append(len(current_seq))
    
    if not sequences:
        return None
    
    # Basic stats
    num_contigs = len(sequences)
    total_length = sum(sequences)
    min_length = min(sequences)
    max_length = max(sequences)
    avg_length = total_length / num_contigs
    
    # Calculate N50
    sequences_sorted = sorted(sequences, reverse=True)
    cumsum = 0
    n50 = 0
    for length in sequences_sorted:
        cumsum += length
        if cumsum >= total_length / 2:
            n50 = length
            break
    
    # Calculate GC content
    gc_count = 0
    total_bases = 0
    with open(fasta_file, 'r') as f:
        for line in f:
            if not line.startswith('>'):
                seq = line.strip().upper()
                gc_count += seq.count('G') + seq.count('C')
                total_bases += len(seq)
    
    gc_percent = (gc_count / total_bases * 100) if total_bases > 0 else 0
    
    return {
        'sample': '${meta.id}',
        'num_contigs': num_contigs,
        'total_length': total_length,
        'min_length': min_length,
        'avg_length': int(avg_length),
        'max_length': max_length,
        'n50': n50,
        'gc_content': round(gc_percent, 2)
    }

# Calculate stats
stats = calculate_assembly_stats('$assembly')

if stats:
    # Write header and data
    with open('${prefix}_assembly_stats.tsv', 'w') as f:
        f.write("sample\\tnum_contigs\\ttotal_length\\tmin_length\\tavg_length\\tmax_length\\tn50\\tgc_content\\n")
        f.write(f"{stats['sample']}\\t{stats['num_contigs']}\\t{stats['total_length']}\\t{stats['min_length']}\\t{stats['avg_length']}\\t{stats['max_length']}\\t{stats['n50']}\\t{stats['gc_content']}\\n")
else:
    print("Error: Could not parse FASTA file")
    sys.exit(1)
EOF

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python3 --version 2>/dev/null | sed 's/Python //' || echo "unknown")
    END_VERSIONS
    """
}