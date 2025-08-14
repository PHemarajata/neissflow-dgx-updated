# Testing the DGX A100 Container Fix

## Before Running the Pipeline

1. **Verify Singularity is installed:**
   ```bash
   singularity --version
   ```
   If not installed, install Singularity on your DGX A100 system.

2. **Check available disk space:**
   ```bash
   df -h $HOME/.singularity/cache
   ```
   Ensure you have at least 10-20GB free space for container caching.

3. **Test container pulling (optional):**
   ```bash
   singularity pull docker://staphb/snippy:4.6.0
   ```

## Running the Fixed Pipeline

```bash
# Navigate to the pipeline directory
cd neissflow-dgx-updated

# Run with the fixed dgx_a100 profile
nextflow run main.nf \
  -profile dgx_a100 \
  --input /path/to/your/samplesheet.csv \
  --outdir /path/to/results \
  --only_fastq
```

## What Should Happen Now

1. **Container Download**: On first run, Singularity will download required containers
2. **Successful Execution**: The SNIPPY process should now find the `snippy` command
3. **Performance**: Local executor will provide maximum performance on DGX A100
4. **Caching**: Subsequent runs will be faster as containers are cached

## Troubleshooting

If you still encounter issues:

1. **Check Singularity permissions:**
   ```bash
   singularity exec docker://hello-world echo "Singularity works!"
   ```

2. **Clear container cache if needed:**
   ```bash
   rm -rf $HOME/.singularity/cache/*
   ```

3. **Check disk space:**
   ```bash
   df -h $HOME/.singularity/cache
   ```

4. **Verify network access for container downloads:**
   ```bash
   ping docker.io
   ```

## Expected Output

You should see output like:
```
executor >  local (N)
[xx/xxxxxx] NFCORE_NEISSFLOW:NEISSFLOW:SNIPPY (sample_name) | 1 of 1 ✔
```

Instead of the previous error:
```
.command.sh: line 9: snippy: command not found
```