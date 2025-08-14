# YAML Formatting Fixes for neissflow-dgx-updated

## Issue
The pipeline was failing with a YAML parsing error:
```
ERROR ~ mapping values are not allowed here
 in 'reader', line 2, column 20:
        awk: 5.1.0, API: 3.0 (GNU MPFR 4.1.0, GNU MP 6.2.1)
                       ^
```

## Root Cause
The `awk --version` command outputs text like "5.1.0, API: 3.0 (GNU MPFR 4.1.0, GNU MP 6.2.1)" which contains colons and commas that break YAML parsing when used in version strings.

## Solution Applied
1. **Changed capitalized version keys to lowercase** (following standard conventions):
   - `Awk:` → `awk:`
   - `Python:` → `python:`
   - `Gotree:` → `gotree:`

2. **Improved version string extraction** to remove problematic characters:
   - Old: `$(awk --version 2>&1 | sed -n 1p | sed 's/GNU Awk //')`
   - New: `$(awk --version 2>&1 | sed -n 1p | sed 's/GNU Awk //' | sed 's/,.*//')`

The additional `sed 's/,.*//'` removes everything after the first comma, so "5.1.0, API: 3.0..." becomes just "5.1.0".

## Files Modified
### Awk version fixes:
1. `modules/local/check_fastqs.nf`
2. `modules/local/cluster_coloring.nf`
3. `modules/local/fastp/combine_reports.nf`
4. `modules/local/make_guide.nf`
5. `modules/local/mash/combine_mash_reports.nf`
6. `modules/local/merge/merge.nf`
7. `modules/local/merge_amr.nf`
8. `modules/local/merge_single_amr.nf`
9. `modules/local/phylogeny_qc.nf`
10. `modules/local/qc_check/qc_check.nf`
11. `modules/local/stats/coverage.nf`

### Python version fixes:
12. `modules/local/fastp/parse_fastp.nf`
13. `modules/local/outbreak_detection.nf`
14. `modules/local/spades/assembly_stats.nf`
15. `modules/local/variant_analysis.nf`

### Gotree version fixes:
16. `modules/local/gotree.nf`
17. `modules/local/reroot.nf`

## Result
- All version entries now use lowercase names
- Version strings are properly sanitized to avoid YAML parsing issues
- The pipeline should now run without YAML parsing errors
- Follows standard YAML and nf-core conventions