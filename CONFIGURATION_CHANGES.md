# Configuration Changes

## New Configurable Assets Directory Parameter

### Overview
The pipeline now supports a configurable assets directory parameter (`--assets_dir`) instead of hardcoded paths.

### Usage
You can now specify the assets directory when running the pipeline:

```bash
nextflow run main.nf --assets_dir /path/to/your/assets --input samplesheet.csv --outdir results
```

### Default Value
If not specified, the default assets directory is: `/home/phemarajata/neissflow/assets`

### What Changed
- Added `assets_dir` parameter to `nextflow.config`
- Updated all hardcoded asset paths to use the configurable parameter
- Added parameter to the schema for proper documentation

## Snippy/snpEff Compatibility Fix

### Issue
The snippy container had an incompatible snpEff version (0.025) which caused the pipeline to fail with:
```
Need snpEff -version >= 4.3 but you have 0.025 - please upgrade it.
```

### Solution
1. **Updated container versions**: Changed from `hdfd78af_4` to `hdfd78af_5` for all snippy modules
2. **Added --noeff flag**: Added the `--noeff` flag to all snippy commands to disable snpEff annotation when it's not compatible

### Modules Updated
- `modules/local/snippy.nf`
- `modules/local/snippy_core.nf`
- `modules/local/snippy_clean.nf`
- `modules/local/snippy_amr.nf`

### Impact
- Snippy will run without snpEff annotation, focusing on variant calling
- Pipeline should now complete successfully without snpEff version conflicts
- All other functionality remains intact