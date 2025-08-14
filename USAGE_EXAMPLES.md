# Usage Examples with New Configuration

## Using Custom Assets Directory

### Example 1: Using a different assets directory
```bash
nextflow run main.nf \
  --assets_dir /data/neissflow/assets \
  --input samplesheet.csv \
  --outdir results \
  --name my_analysis \
  -profile singularity
```

### Example 2: Using the DGX A100 profile with custom assets
```bash
nextflow run main.nf \
  --assets_dir /shared/neissflow/assets \
  --input samplesheet.csv \
  --outdir /shared/results \
  --name dgx_analysis \
  -profile dgx_a100
```

### Example 3: Default behavior (no change needed)
```bash
# This will use the default assets directory: /home/phemarajata/neissflow/assets
nextflow run main.nf \
  --input samplesheet.csv \
  --outdir results \
  --name standard_analysis \
  -profile singularity
```

## Assets Directory Structure

Your assets directory should contain the following structure:
```
assets/
├── databases/
│   ├── RefSeqSketchesDefaults.msh
│   ├── pubmlst/
│   └── blastdb/
│       └── mlst.fa
├── blastdb/
│   ├── penAdb
│   └── porBdb
├── alleledb/
│   └── ngmaster/
│       └── pubmlst/
│           ├── ngstar/
│           │   └── ngstar.txt
│           └── ngmast/
│               └── ngmast.txt
├── gene_refs/
│   └── mosaic-mtrR.fasta
├── FA19.gb
├── FA19cg.fa
├── amr_genes.gbk
├── FA19_loci.tsv
├── AMR_defaults.tsv
└── amr_columns.txt
```

## Troubleshooting

### If you get path-related errors:
1. Ensure your assets directory exists and has the correct structure
2. Check that all required files are present in the assets directory
3. Verify that the path is accessible from your compute environment
4. Use absolute paths when specifying the assets directory