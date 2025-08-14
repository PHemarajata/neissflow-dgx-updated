//
// shovill assembly & assembly QC
//

//include { SPADES                 } from '../../modules/local/spades/spades'
include { SHOVILL                } from '../../modules/local/shovill'
include { ASSEMBLY_STATS         } from '../../modules/local/spades/assembly_stats'
include { QUAST                  } from '../../modules/nf-core/quast/main'
include { ASSEMBLY_STATS_LITE   } from '../../modules/local/assembly_stats_lite'

workflow ASSEMBLY {
    take:
    reads             // channel: [ val(sample_name), [ reads ] ]
    ch_contigs        // channel: [ val(sample_name), contigs ]
    prefix            // val(prefix)

    main:

    ch_versions = Channel.empty()

    //
    // shovill assembly
    //
    ch_assembly = Channel.empty()
    if (params.only_fastq){
        SHOVILL (
            reads
        )
        ch_assembly = SHOVILL.out.contigs
        ch_versions = ch_versions.mix(SHOVILL.out.versions)
    } else {
        ch_assembly = ch_contigs
    }

    //
    // Get assembly metrics for QC 
    //
    ch_assemblies = ch_assembly
                    .map {
                        meta, contigs ->
                        contigs
                    }
    if (params.only_fastq){
        ch_quast_in = ch_assembly
                        .map {
                            sample_id, contigs ->
                            def meta = [:]
                            meta.id = sample_id
                            [ meta, [ contigs ] ]
                        }
    } else {
        ch_quast_in = ch_assembly
                        .map {
                            sample_id, contigs ->
                            def meta = [:]
                            meta.id = sample_id
                            [ meta, contigs ]
                        }
    }
    
    ch_qc_stats_report = Channel.empty()
    if (!params.skip_assembly_qc) {
        ASSEMBLY_STATS (
            ch_assemblies.collect(),
            prefix
        )
        ch_qc_stats_report = ASSEMBLY_STATS.out.qc_stats_report
        ch_versions = ch_versions.mix(ASSEMBLY_STATS.out.versions)
    }

    // Choose between QUAST (full featured) or ASSEMBLY_STATS_LITE (fast)
    if (params.use_lite_assembly_stats) {
        ASSEMBLY_STATS_LITE(
            ch_quast_in
        )
        ch_quast_results = ASSEMBLY_STATS_LITE.out.stats.map { meta, stats -> [meta, [stats]] }
        ch_versions = ch_versions.mix(ASSEMBLY_STATS_LITE.out.versions)
    } else {
        QUAST(
            ch_quast_in,
            [[],params.FA19cg],
            [[],[]]
        )
        ch_quast_results = QUAST.out.results
        ch_versions = ch_versions.mix(QUAST.out.versions)
    }

    emit:

    contigs             = ch_assembly                                // channel:  [ val(sample_name), [ spades_contigs ] ] 

    qc_stats_report     = ch_qc_stats_report                         // channel: qc_stats_report

    quast_results       = ch_quast_results                          // channel: [ val(sample_name), [ results ] ]

    versions            = ch_versions                                // channel: [ versions.yml ]

}