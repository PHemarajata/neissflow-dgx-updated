# YAML Formatting Fixes

## Issue
The pipeline was failing with a YAML parsing error:
```
ERROR ~ mapping values are not allowed here
 in 'reader', line 2, column 20:
        Awk: 5.1.0, API: 3.0 (GNU MPFR 4.1.0, GNU MP 6.2.1)
                       ^
```

## Root Cause
The `awk --version` command outputs text containing colons and commas that break YAML parsing when used as version strings in the versions.yml files. The format was:
```yaml
"${task.process}":
    Awk: $(awk --version 2>&1 | sed -n 1p | sed 's/GNU Awk //')
```

## Solution
Changed all version entries to use lowercase names following standard conventions:

### Files Modified:
1. `modules/local/check_fastqs.nf` - Changed "Awk:" to "awk:"
2. `modules/local/cluster_coloring.nf` - Changed "Awk:" to "awk:"
3. `modules/local/make_guide.nf` - Changed "Awk:" to "awk:"
4. `modules/local/fastp/combine_reports.nf` - Changed "Awk:" to "awk:"
5. `modules/local/mash/combine_mash_reports.nf` - Changed "Awk:" to "awk:"
6. `modules/local/merge/merge.nf` - Changed "Awk:" to "awk:"
7. `modules/local/merge_amr.nf` - Changed "Awk:" to "awk:"
8. `modules/local/merge_single_amr.nf` - Changed "Awk:" to "awk:"
9. `modules/local/phylogeny_qc.nf` - Changed "Awk:" to "awk:"
10. `modules/local/qc_check/qc_check.nf` - Changed "Awk:" to "awk:"
11. `modules/local/stats/coverage.nf` - Changed "Awk:" to "awk:"
12. `modules/local/fastp/parse_fastp.nf` - Changed "Python:" to "python:"
13. `modules/local/outbreak_detection.nf` - Changed "Python:" to "python:"
14. `modules/local/spades/assembly_stats.nf` - Changed "Python:" to "python:"
15. `modules/local/variant_analysis.nf` - Changed "Python:" to "python:"
16. `modules/local/gotree.nf` - Changed "Gotree:" to "gotree:"
17. `modules/local/reroot.nf` - Changed "Gotree:" to "gotree:"

### Result
All version entries now use lowercase names, which:
1. Follows standard YAML conventions
2. Prevents parsing errors from tool output containing special characters
3. Maintains consistency across all modules

The pipeline should now run without YAML parsing errors.